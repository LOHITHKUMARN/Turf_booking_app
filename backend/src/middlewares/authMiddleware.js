const jwt = require('jsonwebtoken');
const userRepository = require('../repositories/userRepository');
const { serializeUser } = require('../utils/serializer');

const protect = async (req, res, next) => {
    let token;

    if (req.headers.authorization && req.headers.authorization.startsWith('Bearer')) {
        try {
            token = req.headers.authorization.split(' ')[1];
            const decoded = jwt.verify(token, process.env.JWT_SECRET);

            const user = await userRepository.findById(decoded.userId);
            if (!user) {
                return res.status(401).json({ message: 'User not found' });
            }

            req.user = userRepository.isPostgres() ? serializeUser(user) : user;

            if (req.user.status === 'blocked') {
                return res.status(403).json({ message: 'User is blocked' });
            }

            next();
        } catch (error) {
            console.error(error);
            if (error.name === 'TokenExpiredError') {
                return res.status(401).json({ message: 'Token expired', expired: true });
            }
            res.status(401).json({ message: 'Not authorized, token failed' });
        }
    }

    if (!token) {
        return res.status(401).json({ message: 'Not authorized, no token' });
    }
};

const loadUser = async (req, res, next) => {
    let token;

    if (req.headers.authorization && req.headers.authorization.startsWith('Bearer')) {
        try {
            token = req.headers.authorization.split(' ')[1];
            const decoded = jwt.verify(token, process.env.JWT_SECRET);

            const user = await userRepository.findById(decoded.userId);
            req.user = user && userRepository.isPostgres() ? serializeUser(user) : user;
        } catch (error) {
            // Silence errors as this is optional auth
            console.warn('Optional auth failed:', error.message);
        }
    }
    next();
};

module.exports = { protect, loadUser };
