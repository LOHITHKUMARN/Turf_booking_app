const Redis = require('ioredis');
const logger = require('./logger');

let redis = null;

const connectRedis = () => {
    const redisUrl = process.env.REDIS_URL || 'redis://127.0.0.1:6379';

    try {
        redis = new Redis(redisUrl, {
            maxRetriesPerRequest: 3,
            retryStrategy(times) {
                if (times > 3) {
                    logger.warn('Redis connection failed after 3 retries — running without cache');
                    return null; // stop retrying
                }
                return Math.min(times * 200, 2000);
            },
            lazyConnect: true,
        });

        redis.on('connect', () => {
            logger.info('Redis connected successfully');
        });

        redis.on('error', (err) => {
            logger.warn(`Redis error: ${err.message} — cache operations will be skipped`);
        });

        // Attempt connection but don't block startup
        redis.connect().catch(() => {
            logger.warn('Redis not available — running without cache');
            redis = null;
        });
    } catch (err) {
        logger.warn(`Redis init failed: ${err.message} — running without cache`);
        redis = null;
    }
};

const getCache = async (key) => {
    if (!redis) return null;
    try {
        const data = await redis.get(key);
        return data ? JSON.parse(data) : null;
    } catch {
        return null;
    }
};

const setCache = async (key, data, ttlSeconds = 300) => {
    if (!redis) return;
    try {
        await redis.set(key, JSON.stringify(data), 'EX', ttlSeconds);
    } catch {
        // silently fail — cache is optional
    }
};

const deleteCache = async (pattern) => {
    if (!redis) return;
    try {
        const keys = await redis.keys(pattern);
        if (keys.length > 0) {
            await redis.del(...keys);
        }
    } catch {
        // silently fail
    }
};

const clearAllCache = async () => {
    if (!redis) return;
    try {
        await redis.flushdb();
    } catch {
        // silently fail
    }
};

module.exports = { connectRedis, getCache, setCache, deleteCache, clearAllCache, getRedis: () => redis };
