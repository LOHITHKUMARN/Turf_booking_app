const Review = require('../models/Review');
const Turf = require('../models/Turf');
const Booking = require('../models/Booking');

// @desc    Create a new review
// @route   POST /api/reviews
// @access  Private
const createReview = async (req, res) => {
    try {
        const { turfId, bookingId, rating, comment } = req.body;
        const userId = req.user._id;

        // 1. Verify booking exists and belongs to user
        const booking = await Booking.findOne({ _id: bookingId, userId });
        if (!booking) {
            return res.status(404).json({ message: 'Booking not found' });
        }

        // 2. Verify booking is completed
        if (booking.bookingStatus !== 'completed') {
            return res.status(400).json({ message: 'You can only review completed matches' });
        }

        // 3. Verify no existing review for this booking
        const existingReview = await Review.findOne({ bookingId });
        if (existingReview) {
            return res.status(400).json({ message: 'You have already reviewed this booking' });
        }

        // 4. Create review
        const review = new Review({
            userId,
            turfId,
            bookingId,
            rating,
            comment
        });

        await review.save();

        // 5. Link review to booking
        booking.reviewId = review._id;
        await booking.save();

        // 6. Update Turf rating
        const turf = await Turf.findById(turfId);
        if (turf) {
            const reviews = await Review.find({ turfId });
            const totalRating = reviews.reduce((acc, item) => item.rating + acc, 0);
            turf.settings.avgRating = totalRating / reviews.length;
            turf.settings.numReviews = reviews.length;
            await turf.save();
        }

        res.status(201).json(review);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

// @desc    Get reviews for a turf
// @route   GET /api/reviews/turf/:turfId
// @access  Public
const getTurfReviews = async (req, res) => {
    try {
        const reviews = await Review.find({ turfId: req.params.turfId })
            .populate('userId', 'name profileImage')
            .sort({ createdAt: -1 });
        res.json(reviews);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

module.exports = {
    createReview,
    getTurfReviews
};
