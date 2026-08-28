const logger = require('../services/logger');

// API request/response logging middleware
const requestLogger = (req, res, next) => {
    const start = Date.now();

    // Log after response is sent
    res.on('finish', () => {
        const duration = Date.now() - start;
        const logData = {
            method: req.method,
            url: req.originalUrl,
            status: res.statusCode,
            duration: `${duration}ms`,
            ip: req.ip,
            userAgent: req.get('user-agent'),
        };

        if (req.user) {
            logData.userId = req.user._id;
            logData.role = req.user.role;
        }

        if (res.statusCode >= 400) {
            logger.warn('Request failed', logData);
        } else {
            logger.info('Request completed', logData);
        }
    });

    next();
};

module.exports = requestLogger;
