const { PrismaClient } = require('@prisma/client');
const logger = require('../services/logger');

let prisma;

if (process.env.NODE_ENV === 'production') {
    prisma = new PrismaClient({
        log: ['error', 'warn']
    });
} else {
    if (!global.prisma) {
        global.prisma = new PrismaClient({
            log: ['query', 'error', 'warn']
        });
    }
    prisma = global.prisma;
}

const connectDB = async () => {
    try {
        await prisma.$connect();
        logger.info('Connected to PostgreSQL (Supabase) via Prisma');
    } catch (error) {
        logger.error('Failed to connect to PostgreSQL (Supabase)', { error: error.message });
        throw error;
    }
};

module.exports = { prisma, connectDB };
