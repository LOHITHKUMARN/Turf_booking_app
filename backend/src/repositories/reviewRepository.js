const { prisma } = require('../config/db');
const ReviewMongo = require('../models/Review');
const { serializeReview } = require('../utils/serializer');

const isPostgres = () => process.env.DB_PROVIDER === 'postgres';

const createReview = async ({ userId, turfId, bookingId, rating, comment }) => {
    if (isPostgres()) {
        const review = await prisma.review.create({
            data: {
                userId: String(userId),
                turfId: String(turfId),
                bookingId: String(bookingId),
                rating: Number(rating),
                comment: comment || ''
            },
            include: {
                user: { select: { id: true, name: true, profileImage: true } }
            }
        });
        return serializeReview(review);
    }

    return await ReviewMongo.create({
        userId,
        turfId,
        bookingId,
        rating,
        comment
    });
};

const findReviewsByTurf = async (turfId) => {
    if (isPostgres()) {
        const reviews = await prisma.review.findMany({
            where: { turfId: String(turfId) },
            include: {
                user: { select: { id: true, name: true, profileImage: true } }
            },
            orderBy: { createdAt: 'desc' }
        });
        return reviews.map(serializeReview);
    }

    return await ReviewMongo.find({ turfId }).populate('userId', 'name profileImage').sort({ createdAt: -1 });
};

const calculateTurfRatingStats = async (turfId) => {
    if (isPostgres()) {
        const aggregations = await prisma.review.aggregate({
            where: { turfId: String(turfId) },
            _avg: { rating: true },
            _count: { rating: true }
        });
        return {
            avgRating: Math.round((aggregations._avg.rating || 0) * 10) / 10,
            numReviews: aggregations._count.rating || 0
        };
    }

    const reviews = await ReviewMongo.find({ turfId });
    const numReviews = reviews.length;
    const avgRating = numReviews > 0 
        ? Math.round((reviews.reduce((acc, r) => acc + r.rating, 0) / numReviews) * 10) / 10
        : 0;
    return { avgRating, numReviews };
};

module.exports = {
    createReview,
    findReviewsByTurf,
    calculateTurfRatingStats,
    isPostgres
};
