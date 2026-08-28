const express = require('express');
const router = express.Router();
const { getMyTurfs, createTurf, updateTurf, manageSlots, getTurfSlots, createStaff, getOwnerStaff, assignTurfToStaff, getOwnerBookings, getOwnerStats, getStaffAttendance, updateTurfSettings, requestPayout, getOwnerPayouts, getWalletData, toggleSlotBlock, createManualBooking, createAnnouncement, getOwnerAnnouncements, deleteAnnouncement } = require('../controllers/ownerController');
const { protect } = require('../middlewares/authMiddleware');
const roleGuard = require('../middlewares/roleGuard');
const { validate, createTurfSchema, manageSlotsSchema, createStaffSchema, createAnnouncementSchema, requestPayoutSchema } = require('../middlewares/validation');

// All routes are protected and restricted to owners (or admins)
router.use(protect);
router.use(roleGuard('owner', 'admin'));

router.get('/turfs', getMyTurfs);
router.post('/turf', validate(createTurfSchema), createTurf);
router.put('/turf/:id', updateTurf);
router.post('/slots', validate(manageSlotsSchema), manageSlots);
router.get('/slots/:turfId', getTurfSlots);
router.post('/staff', validate(createStaffSchema), createStaff);
router.get('/staff', getOwnerStaff);
router.get('/staff/attendance', getStaffAttendance);
router.put('/staff/:staffId/assign', assignTurfToStaff);
router.get('/bookings', getOwnerBookings);
router.get('/stats', getOwnerStats);
router.put('/turf/:id/settings', updateTurfSettings);
router.post('/payout/request', validate(requestPayoutSchema), requestPayout);
router.get('/payouts', getOwnerPayouts);
router.put('/slot/:slotId/block', toggleSlotBlock);
router.post('/manual-booking', createManualBooking);
router.get('/announcements', getOwnerAnnouncements);
router.post('/announcement', validate(createAnnouncementSchema), createAnnouncement);
router.delete('/announcement/:id', deleteAnnouncement);

module.exports = router;
