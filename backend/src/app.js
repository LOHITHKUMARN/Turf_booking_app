require('dotenv').config();
const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');
const helmet = require('helmet');
const http = require('http');
const path = require('path');

// Services
const logger = require('./services/logger');
const { initSentry, captureError } = require('./services/sentry');
const { connectRedis } = require('./services/redis');
const { initSocket } = require('./services/socket');
const { initFirebase } = require('./services/notificationService');

// Middleware
const requestLogger = require('./middlewares/requestLogger');
const { apiLimiter, authLimiter } = require('./middlewares/rateLimiter');
const errorHandler = require('./middlewares/errorHandler');

const app = express();
const server = http.createServer(app);

// ──────────── Core Middleware ────────────
app.use(express.json());
const corsOptions = {
    origin: process.env.ALLOWED_ORIGINS ? process.env.ALLOWED_ORIGINS.split(',') : '*',
    methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
    allowedHeaders: ['Content-Type', 'Authorization', 'bypass-tunnel-reminder'],
    credentials: true
};

app.use(cors(corsOptions));
app.use(helmet({
    crossOriginResourcePolicy: false // Allow loading images from CDN / local
}));
app.use(requestLogger);

// ──────────── Health Check (For Render / Load Balancer) ────────────
app.get('/health', (req, res) => {
    res.status(200).json({ status: 'ok', timestamp: new Date().toISOString(), service: 'turf-api' });
});

// ──────────── Rate Limiting ────────────
app.use('/api/', apiLimiter);
app.use('/api/auth', authLimiter);

// ──────────── Static Files ────────────
app.use('/uploads', express.static(path.join(__dirname, '../uploads')));

// ──────────── Routes ────────────
app.use('/api/auth', require('./routes/auth.routes.js'));
app.use('/api/admin', require('./routes/admin.routes.js'));
app.use('/api/owner', require('./routes/owner.routes.js'));
app.use('/api/staff', require('./routes/staff.routes.js'));
app.use('/api/customer', require('./routes/customer.routes.js'));
app.use('/api/upload', require('./routes/upload.routes.js'));
app.use('/api/reviews', require('./routes/review.routes.js'));
app.use('/api/tournaments', require('./routes/tournament.routes.js'));

app.get('/', (req, res) => {
    res.json({ message: 'Turf Booking System API', version: '2.0.0' });
});

// ──────────── Sentry (after routes) ────────────
initSentry(app);

// ──────────── Error Handling ────────────
app.use(errorHandler);

// ──────────── Startup ────────────
const MONGODB_URI = process.env.MONGODB_URI;
const PORT = process.env.PORT || 5005;
const DB_PROVIDER = process.env.DB_PROVIDER || 'mongo';

const startServer = async () => {
    try {
        if (DB_PROVIDER === 'postgres') {
            const { connectDB } = require('./config/db');
            await connectDB();
            logger.info('Running with Database: Supabase PostgreSQL (Prisma)');
        } else {
            await mongoose.connect(MONGODB_URI);
            logger.info(`Running with Database: MongoDB Atlas (${mongoose.connection.db.databaseName})`);
        }

        // Initialize Redis (non-blocking)
        connectRedis();

        // Initialize Socket.IO
        initSocket(server);

        // Initialize Firebase Admin (FCM)
        initFirebase();

        server.listen(PORT, '0.0.0.0', () => {
            logger.info(`Server running on port ${PORT}`);
            logger.info(`Environment: ${process.env.NODE_ENV || 'development'}`);
            logger.info(`Active DB Provider: ${DB_PROVIDER}`);
        });
    } catch (err) {
        logger.error('Database connection error', { error: err.message });
        process.exit(1);
    }
};

if (require.main === module) {
    startServer();
}

// Graceful shutdown
process.on('SIGTERM', () => {
    logger.info('SIGTERM received — shutting down gracefully');
    server.close(() => {
        if (DB_PROVIDER === 'postgres') {
            const { prisma } = require('./config/db');
            prisma.$disconnect();
        } else {
            mongoose.connection.close();
        }
        process.exit(0);
    });
});

module.exports = app;
