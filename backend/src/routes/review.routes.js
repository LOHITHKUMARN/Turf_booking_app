const express = require('express');
const router = express.Router();
const { createReview, getTurfReviews } = require('../controllers/reviewController');
const { protect } = require('../middlewares/authMiddleware');
const { validate, createReviewSchema } = require('../middlewares/validation');

router.post('/', protect, validate(createReviewSchema), createReview);
router.get('/turf/:turfId', getTurfReviews);

module.exports = router;
