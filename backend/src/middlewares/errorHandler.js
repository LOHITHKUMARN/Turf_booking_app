const { captureError } = require('../services/sentry');
const logger = require('../services/logger');

const errorHandler = (err, req, res, next) => {
    // Log error internally
    logger.error(`${err.name}: ${err.message}`, { 
        stack: err.stack,
        path: req.originalUrl,
        method: req.method
    });
    
    // Capture to Sentry if initialized
    captureError(err, { method: req.method, url: req.originalUrl, ip: req.ip });

    // Ensure status code is not 200 for an error
    let statusCode = res.statusCode === 200 ? 500 : res.statusCode;
    
    // Mongoose Validation Error
    if (err.name === 'ValidationError') {
        statusCode = 400;
        return res.status(statusCode).json({
            success: false,
            error: {
                message: 'Validation Error',
                details: Object.values(err.errors).map(val => val.message)
            }
        });
    }

    // Mongoose Duplicate Key Error
    if (err.code === 11000) {
        statusCode = 400;
        return res.status(statusCode).json({
            success: false,
            error: {
                message: 'Duplicate Field Value Entered',
                details: err.keyValue
            }
        });
    }

    // JWT Errors
    if (err.name === 'JsonWebTokenError') {
        return res.status(401).json({
            success: false,
            error: {
                message: 'Invalid Token, please login again'
            }
        });
    }

    if (err.name === 'TokenExpiredError') {
        return res.status(401).json({
            success: false,
            error: {
                message: 'Token Expired, please login again',
                expired: true
            }
        });
    }

    // General fallback
    res.status(statusCode).json({
        success: false,
        error: {
            message: err.message || 'Internal Server Error',
            ...(process.env.NODE_ENV === 'development' && { stack: err.stack })
        }
    });
};

module.exports = errorHandler;
