const reviewRepository = require('../repositories/reviewRepository');
const bookingRepository = require('../repositories/bookingRepository');
const turfRepository = require('../repositories/turfRepository');
const { prisma } = require('../config/db');
const logger = require('../services/logger');

// @desc    Create a new review
// @route   POST /api/reviews
// @access  Private
const createReview = async (req, res) => {
    try {
        const { turfId, bookingId, rating, comment } = req.body;
        const userId = req.user._id || req.user.id;

        // 1. Verify booking exists and belongs to user
        const booking = await bookingRepository.findBookingById(bookingId);
        if (!booking) {
            return res.status(404).json({ message: 'Booking not found' });
        }

        const bookingUserId = booking.userId?._id || booking.userId?.id || booking.userId;
        if (String(bookingUserId) !== String(userId)) {
            return res.status(403).json({ message: 'Not authorized to review this booking' });
        }

        // 2. Verify booking is completed
        if (booking.bookingStatus !== 'completed') {
            return res.status(400).json({ message: 'You can only review completed matches' });
        }

        // 3. Verify no existing review for this booking
        if (reviewRepository.isPostgres()) {
            const existingReview = await prisma.review.findUnique({
                where: { bookingId: String(bookingId) }
            });
            if (existingReview) {
                return res.status(400).json({ message: 'You have already reviewed this booking' });
            }

            const review = await reviewRepository.createReview({
                userId,
                turfId,
                bookingId,
                rating,
                comment
            });

            // Update Turf rating
            const stats = await reviewRepository.calculateTurfRatingStats(turfId);
            await turfRepository.updateRating(turfId, stats.avgRating, stats.numReviews);

            return res.status(201).json(review);
        }

        // Mongo fallback
        const ReviewMongo = require('../models/Review');
        const TurfMongo = require('../models/Turf');
        const BookingMongo = require('../models/Booking');

        const existingReview = await ReviewMongo.findOne({ bookingId });
        if (existingReview) {
            return res.status(400).json({ message: 'You have already reviewed this booking' });
        }

        const review = new ReviewMongo({
            userId,
            turfId,
            bookingId,
            rating,
            comment
        });
        await review.save();

        const mongoBooking = await BookingMongo.findById(bookingId);
        if (mongoBooking) {
            mongoBooking.reviewId = review._id;
            await mongoBooking.save();
        }

        const stats = await reviewRepository.calculateTurfRatingStats(turfId);
        await turfRepository.updateRating(turfId, stats.avgRating, stats.numReviews);

        res.status(201).json(review);
    } catch (error) {
        logger.error('createReview error:', error);
        res.status(500).json({ message: error.message });
    }
};

// @desc    Get reviews for a turf
// @route   GET /api/reviews/turf/:turfId
// @access  Public
const getTurfReviews = async (req, res) => {
    try {
        const reviews = await reviewRepository.findReviewsByTurf(req.params.turfId);
        res.json(reviews);
    } catch (error) {
        logger.error('getTurfReviews error:', error);
        res.status(500).json({ message: error.message });
    }
};

module.exports = {
    createReview,
    getTurfReviews
};
