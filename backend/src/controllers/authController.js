const userRepository = require('../repositories/userRepository');
const jwt = require('jsonwebtoken');
const crypto = require('crypto');
const logger = require('../services/logger');

// Helper to generate access and refresh tokens
const generateTokens = async (user) => {
    const userId = String(user._id || user.id);
    const accessToken = jwt.sign(
        { userId, role: user.role },
        process.env.JWT_SECRET,
        { expiresIn: '15m' } // Short-lived access token
    );

    // Generate Refresh Token string
    const refreshTokenString = crypto.randomBytes(40).toString('hex');
    
    // Set expiry to 7 days
    const expiredAt = new Date();
    expiredAt.setDate(expiredAt.getDate() + 7);

    await userRepository.createRefreshToken({
        token: refreshTokenString,
        userId,
        expiryDate: expiredAt
    });

    return { accessToken, refreshTokenString };
};

// @desc    Register a new user
// @route   POST /api/auth/signup
// @access  Public
const signup = async (req, res) => {
    const { name, email, phone, password, role } = req.body;

    try {
        const userExists = await userRepository.findByEmailOrPhone(email) || await userRepository.findByEmailOrPhone(phone);

        if (userExists) {
            return res.status(400).json({ 
                success: false, 
                message: 'User already exists',
                error: { code: 'USER_EXISTS', message: 'User already exists' }
            });
        }

        const user = await userRepository.createUser({
            name,
            email,
            phone,
            password,
            role: role || 'customer'
        });

        if (user) {
            const tokens = await generateTokens(user);
            res.status(201).json({
                _id: user._id || user.id,
                id: user.id || user._id,
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
        logger.error('Signup error', { error: error.message });
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
        const user = await userRepository.findByEmailOrPhone(id);

        if (!user) {
            logger.info(`Login failed: User not found for ID [${id}]`);
            return res.status(401).json({ message: 'Invalid credentials' });
        }

        const isMatch = await userRepository.matchPassword(password, user.password);
        logger.info(`Login attempt for [${user.email}] | Role: [${user.role}] | Match: [${isMatch}]`);

        if (isMatch) {
            const tokens = await generateTokens(user);
            res.json({
                _id: user._id || user.id,
                id: user.id || user._id,
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
        const userId = req.user._id || req.user.id;
        const user = await userRepository.updateFCMToken(userId, token);

        if (!user) {
            return res.status(404).json({ message: 'User not found' });
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
        const refreshTokenDoc = await userRepository.findRefreshToken(requestToken);

        if (!refreshTokenDoc) {
            return res.status(403).json({ message: 'Refresh token is not in database!' });
        }

        if (typeof refreshTokenDoc.isExpired === 'function' ? refreshTokenDoc.isExpired() : (refreshTokenDoc.expiryDate.getTime() <= Date.now())) {
            await userRepository.deleteRefreshToken(refreshTokenDoc._id || refreshTokenDoc.id);
            return res.status(403).json({
                message: 'Refresh token was expired. Please make a new signin request',
            });
        }

        // Generate new access token
        const user = refreshTokenDoc.user;
        const newAccessToken = jwt.sign(
            { userId: String(user._id || user.id), role: user.role },
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
