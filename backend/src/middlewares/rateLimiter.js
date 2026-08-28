const rateLimit = require('express-rate-limit');
const logger = require('../services/logger');

// General API rate limiter
const apiLimiter = rateLimit({
    windowMs: 15 * 60 * 1000, // 15 minutes
    max: 200, // 200 requests per window per IP
    standardHeaders: true,
    legacyHeaders: false,
    message: {
        message: 'Too many requests from this IP, please try again after 15 minutes.',
    },
    handler: (req, res, next, options) => {
        logger.warn(`Rate limit exceeded`, { ip: req.ip, path: req.path });
        res.status(429).json(options.message);
    },
});

// Strict limiter for auth endpoints (login/register)
const authLimiter = rateLimit({
    windowMs: 15 * 60 * 1000,
    max: 15, // Max 15 login attempts per 15 mins
    standardHeaders: true,
    legacyHeaders: false,
    message: {
        message: 'Too many login attempts. Please try again after 15 minutes.',
    },
    handler: (req, res, next, options) => {
        logger.warn(`Auth rate limit exceeded`, { ip: req.ip, path: req.path });
        res.status(429).json(options.message);
    },
});

module.exports = { apiLimiter, authLimiter };
