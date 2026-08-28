const express = require('express');
const router = express.Router();
const {
    getAssignedBookings,
    verifyBooking,
    updateStatus,
    reportIssue,
    getTurfSlots,
    toggleSlotBlock,
    createWalkInBooking,
    updateOperationalStatus,
    updateBookingNotes,
    clockIn,
    clockOut,
    getProductivityStats,
    reportIncident,
    getAnnouncements,
    addExtraCharge,
    getActiveAttendance
} = require('../controllers/staffController');
const { protect } = require('../middlewares/authMiddleware');
const roleGuard = require('../middlewares/roleGuard');
const { validate, reportIncidentSchema } = require('../middlewares/validation');

// All routes are protected and restricted to staff
router.use(protect);
router.use(roleGuard('staff', 'admin'));

router.get('/bookings', getAssignedBookings);
router.get('/slots', getTurfSlots);
router.get('/stats', getProductivityStats);
router.get('/announcements', getAnnouncements);
router.post('/verify/:bookingId', verifyBooking);
router.put('/booking/:bookingId/status', updateStatus);
router.put('/slot/:slotId/block', toggleSlotBlock);
router.post('/report-issue', reportIssue);
router.post('/report-incident', validate(reportIncidentSchema), reportIncident);
router.post('/walk-in', createWalkInBooking);
router.put('/turf/status', updateOperationalStatus);
router.put('/booking/:bookingId/notes', updateBookingNotes);
router.put('/booking/:bookingId/extra-charges', addExtraCharge);
router.post('/attendance/clock-in', clockIn);
router.post('/attendance/clock-out', clockOut);
router.get('/attendance/active', getActiveAttendance);

module.exports = router;
