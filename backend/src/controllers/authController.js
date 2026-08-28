const User = require('../models/User');
const RefreshToken = require('../models/RefreshToken');
const jwt = require('jsonwebtoken');
const crypto = require('crypto');
const logger = require('../services/logger');

// Helper to generate access and refresh tokens
const generateTokens = async (user) => {
    const accessToken = jwt.sign(
        { userId: user._id, role: user.role },
        process.env.JWT_SECRET,
        { expiresIn: '15m' } // Short-lived access token
    );

    // Generate Refresh Token string
    const refreshTokenString = crypto.randomBytes(40).toString('hex');
    
    // Set expiry to 7 days
    const expiredAt = new Date();
    expiredAt.setDate(expiredAt.getDate() + 7);

    const refreshToken = new RefreshToken({
        token: refreshTokenString,
        user: user._id,
        expiryDate: expiredAt
    });

    await refreshToken.save();

    return { accessToken, refreshTokenString };
};

// @desc    Register a new user
// @route   POST /api/auth/signup
// @access  Public
const signup = async (req, res) => {
    const { name, email, phone, password, role } = req.body;

    try {
        const userExists = await User.findOne({ $or: [{ email }, { phone }] });

        if (userExists) {
            return res.status(400).json({ 
                success: false, 
                message: 'User already exists',
                error: { code: 'USER_EXISTS', message: 'User already exists' }
            });
        }

        const user = await User.create({
            name,
            email,
            phone,
            password,
            role: role || 'customer'
        });

        if (user) {
            const tokens = await generateTokens(user);
            res.status(201).json({
                _id: user._id,
                name: user.name,
                email: user.email,
                role: user.role,
                ownerId: user.ownerId,
                assignedTurfId: user.assignedTurfId,
                token: tokens.accessToken,
                refreshToken: tokens.refreshTokenString
            });
        } else {
            res.status(400).json({ 
                success: false, 
                message: 'Invalid user data',
                error: { code: 'INVALID_DATA', message: 'Invalid user data' }
            });
        }
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

// @desc    Auth user & get token
// @route   POST /api/auth/login
// @access  Public
const login = async (req, res) => {
    console.log('Login request received:', req.body);
    const { email, phone, identifier, password } = req.body;

    try {
        const id = identifier || email || phone;
        if (!id) {
            return res.status(400).json({ 
                success: false, 
                message: 'Please provide email or phone',
                error: { code: 'MISSING_ID', message: 'Please provide email or phone' }
            });
        }

        // Find user by email OR phone
        const user = await User.findOne({
            $or: [{ email: id.toLowerCase() }, { phone: id }]
        });

        if (!user) {
            logger.info(`Login failed: User not found for ID [${id}]`);
            return res.status(401).json({ message: 'Invalid credentials' });
        }

        const isMatch = await user.matchPassword(password);
        logger.info(`Login attempt for [${user.email}] | Role: [${user.role}] | Match: [${isMatch}]`);

        if (isMatch) {
            const tokens = await generateTokens(user);
            res.json({
                _id: user._id,
                name: user.name,
                email: user.email,
                phone: user.phone,
                role: user.role,
                ownerId: user.ownerId,
                assignedTurfId: user.assignedTurfId,
                token: tokens.accessToken,
                refreshToken: tokens.refreshTokenString
            });
        } else {
            res.status(401).json({ message: 'Invalid credentials' });
        }
    } catch (error) {
        logger.error('Error in login:', error);
        res.status(500).json({ message: error.message });
    }
};

// @desc    Update FCM token
// @route   POST /api/auth/fcm-token
// @access  Private
const updateFCMToken = async (req, res) => {
    const { token } = req.body;

    if (!token) {
        return res.status(400).json({ message: 'Token is required' });
    }

    try {
        const user = await User.findById(req.user._id);

        if (!user) {
            return res.status(404).json({ message: 'User not found' });
        }

        // Add token if it doesn't exist
        if (!user.fcmTokens.includes(token)) {
            user.fcmTokens.push(token);
            await user.save();
        }

        res.json({ message: 'FCM token updated successfully' });
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

// @desc    Refresh access token
// @route   POST /api/auth/refresh
// @access  Public
const refreshToken = async (req, res) => {
    const { requestToken } = req.body;

    if (!requestToken) {
        return res.status(403).json({ message: 'Refresh token is required!' });
    }

    try {
        const refreshTokenDoc = await RefreshToken.findOne({ token: requestToken }).populate('user');

        if (!refreshTokenDoc) {
            return res.status(403).json({ message: 'Refresh token is not in database!' });
        }

        if (refreshTokenDoc.isExpired()) {
            await RefreshToken.findByIdAndDelete(refreshTokenDoc._id);
            return res.status(403).json({
                message: 'Refresh token was expired. Please make a new signin request',
            });
        }

        // Generate new access token
        const newAccessToken = jwt.sign(
            { userId: refreshTokenDoc.user._id, role: refreshTokenDoc.user.role },
            process.env.JWT_SECRET,
            { expiresIn: '15m' }
        );

        res.status(200).json({
            accessToken: newAccessToken,
            refreshToken: refreshTokenDoc.token,
        });
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

module.exports = { signup, login, updateFCMToken, refreshToken };

