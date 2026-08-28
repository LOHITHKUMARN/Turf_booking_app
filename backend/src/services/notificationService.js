const admin = require('firebase-admin');
const path = require('path');
const logger = require('./logger');

let isInitialized = false;

/**
 * Initialize Firebase Admin SDK
 * Expects serviceAccountKey.json in src/config/
 */
const initFirebase = () => {
    try {
        const serviceAccountPath = path.join(__dirname, '../config/serviceAccountKey.json');
        
        // Check if file exists (require will throw if not)
        const serviceAccount = require(serviceAccountPath);

        admin.initializeApp({
            credential: admin.credential.cert(serviceAccount)
        });

        isInitialized = true;
        logger.info('Firebase Admin initialized successfully');
    } catch (error) {
        logger.warn('Firebase Admin NOT initialized: serviceAccountKey.json missing or invalid. Push notifications will be disabled.', { error: error.message });
    }
};

/**
 * Send notification to a specific user
 * @param {Object} user - User document from MongoDB
 * @param {Object} notification - { title, body, data }
 */
const sendToUser = async (user, { title, body, data = {} }) => {
    if (!isInitialized) return;
    if (!user.fcmTokens || user.fcmTokens.length === 0) return;

    const message = {
        notification: { title, body },
        data,
        tokens: user.fcmTokens
    };

    try {
        const response = await admin.messaging().sendEachForMulticast(message);
        logger.info(`FCM: Successfully sent to user ${user._id} (${response.successCount} success, ${response.failureCount} fail)`);
        
        // Clean up invalid tokens if any
        if (response.failureCount > 0) {
            handleFcmFailures(user, response, message.tokens);
        }
    } catch (error) {
        logger.error(`FCM: Error sending to user ${user._id}`, { error: error.message });
    }
};

/**
 * Send notification to all users of a specific role
 * @param {String} role - 'admin', 'owner', 'staff'
 * @param {Object} notification - { title, body, data }
 */
const sendToRole = async (role, { title, body, data = {} }) => {
    if (!isInitialized) return;

    const User = require('../models/User');
    const users = await User.find({ role, 'fcmTokens.0': { $exists: true } });

    for (const user of users) {
        await sendToUser(user, { title, body, data });
    }
};

/**
 * Handle FCM failures and cleanup invalid tokens
 */
const handleFcmFailures = async (user, response, tokens) => {
    const tokensToRemove = [];
    response.responses.forEach((res, idx) => {
        if (!res.success && (res.error.code === 'messaging/invalid-registration-token' || res.error.code === 'messaging/registration-token-not-registered')) {
            tokensToRemove.push(tokens[idx]);
        }
    });

    if (tokensToRemove.length > 0) {
        const User = require('../models/User');
        await User.findByIdAndUpdate(user._id, {
            $pull: { fcmTokens: { $in: tokensToRemove } }
        });
        logger.info(`FCM: Cleaned up ${tokensToRemove.length} invalid tokens for user ${user._id}`);
    }
};

module.exports = {
    initFirebase,
    sendToUser,
    sendToRole
};
