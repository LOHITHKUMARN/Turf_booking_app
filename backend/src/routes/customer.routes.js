const express = require('express');
const router = express.Router();
const { getTurfs, getTurfById, getTurfSlots, createBooking, getMyBookings, getProfile, updateProfile, cancelBooking } = require('../controllers/customerController');
const { protect } = require('../middlewares/authMiddleware');
const { validate, createBookingSchema } = require('../middlewares/validation');

router.get('/turfs', getTurfs);
router.get('/turfs/:id', getTurfById);
router.get('/turfs/:turfId/slots', getTurfSlots);
router.post('/bookings', protect, validate(createBookingSchema), createBooking);
router.get('/bookings', protect, getMyBookings);
router.put('/bookings/:id/cancel', protect, cancelBooking);
router.get('/profile', protect, getProfile);
router.put('/profile', protect, updateProfile);

module.exports = router;
