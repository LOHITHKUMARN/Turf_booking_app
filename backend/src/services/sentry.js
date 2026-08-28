const Sentry = require('@sentry/node');
const logger = require('./logger');

const initSentry = (app) => {
    const dsn = process.env.SENTRY_DSN;

    if (!dsn) {
        logger.warn('Sentry DSN not configured — error tracking disabled. Set SENTRY_DSN in .env to enable.');
        return;
    }

    Sentry.init({
        dsn,
        environment: process.env.NODE_ENV || 'development',
        tracesSampleRate: process.env.NODE_ENV === 'production' ? 0.2 : 1.0,
    });

    // Sentry error handler (must be added AFTER routes)
    app.use(Sentry.setupExpressErrorHandler());

    logger.info('Sentry error tracking initialized');
};

const captureError = (error, context = {}) => {
    logger.error(error.message, { stack: error.stack, ...context });
    if (process.env.SENTRY_DSN) {
        Sentry.captureException(error, { extra: context });
    }
};

module.exports = { initSentry, captureError };
