const userRepository = require('../repositories/userRepository');
const staffRepository = require('../repositories/staffRepository');
const turfRepository = require('../repositories/turfRepository');
const slotRepository = require('../repositories/slotRepository');
const bookingRepository = require('../repositories/bookingRepository');
const { emitToTurf } = require('../services/socket');
const { sendToUser } = require('../services/notificationService');
const { prisma } = require('../config/db');
const { serializeBooking, serializeSlot } = require('../utils/serializer');
const logger = require('../services/logger');

// Helper to extract string Turf ID from user model
const getStaffTurfId = (staff) => {
    if (!staff || !staff.assignedTurfId) return null;
    if (typeof staff.assignedTurfId === 'object') {
        return staff.assignedTurfId._id || staff.assignedTurfId.id || null;
    }
    return String(staff.assignedTurfId);
};

// @desc    Get bookings for assigned turf
// @route   GET /api/staff/bookings
// @access  Private/Staff
const getAssignedBookings = async (req, res) => {
    try {
        const userId = req.user._id || req.user.id;
        const staff = await userRepository.findById(userId);
        if (!staff) {
            console.log('Staff user not found:', userId);
            return res.status(404).json({ message: 'Staff user not found' });
        }

        const turfId = getStaffTurfId(staff);
        if (!turfId) {
            console.log('Staff user has no assigned turf:', staff.email);
            return res.json([]);
        }

        console.log(`Fetching bookings for staff: ${staff.email}, TurfID: ${turfId}`);
        const bookings = await staffRepository.findAssignedBookings(turfId);

        console.log(`[STAFF] Found ${bookings.length} bookings for turf ${turfId}`);
        res.json(bookings);
    } catch (error) {
        logger.error('getAssignedBookings error:', error);
        res.status(500).json({ message: error.message });
    }
};

// @desc    Verify booking (Manual/QR)
// @route   POST /api/staff/verify/:bookingId
// @access  Private/Staff
const verifyBooking = async (req, res) => {
    try {
        const bookingId = req.params.bookingId;
        const booking = await bookingRepository.findBookingById(bookingId);
        if (!booking) {
            return res.status(404).json({ message: 'Booking not found' });
        }

        const updated = await bookingRepository.updateBooking(bookingId, {
            bookingStatus: 'checked-in',
            checkInTime: new Date()
        });

        const turfIdStr = String(booking.turfId?._id || booking.turfId?.id || booking.turfId);
        emitToTurf(turfIdStr, 'bookingUpdated', {
            bookingId: booking._id || booking.id,
            status: 'checked-in'
        });

        // Notify Customer
        const customerId = booking.userId?._id || booking.userId?.id || booking.userId;
        if (customerId) {
            const customer = await userRepository.findById(customerId);
            if (customer) {
                const turfName = booking.turfId?.name || 'the turf';
                await sendToUser(customer, {
                    title: 'Check-in Successful!',
                    body: `You have successfully checked in at ${turfName}. Enjoy your game!`,
                    data: { bookingId: String(booking._id || booking.id), type: 'check_in' }
                });
            }
        }

        res.json({ message: 'Booking verified successfully', booking: updated });
    } catch (error) {
        logger.error('verifyBooking error:', error);
        res.status(500).json({ message: error.message });
    }
};

// @desc    Update booking status (no-show, completed)
// @route   PUT /api/staff/booking/:bookingId/status
// @access  Private/Staff
const updateStatus = async (req, res) => {
    const { status } = req.body;
    const bookingId = req.params.bookingId;
    try {
        const booking = await bookingRepository.findBookingById(bookingId);
        if (!booking) {
            return res.status(404).json({ message: 'Booking not found' });
        }

        const updated = await bookingRepository.updateBooking(bookingId, {
            bookingStatus: status
        });

        const turfIdStr = String(booking.turfId?._id || booking.turfId?.id || booking.turfId);
        emitToTurf(turfIdStr, 'bookingUpdated', {
            bookingId: booking._id || booking.id,
            status: status
        });

        // Notify Customer if completed
        if (status === 'completed') {
            const customerId = booking.userId?._id || booking.userId?.id || booking.userId;
            if (customerId) {
                const customer = await userRepository.findById(customerId);
                if (customer) {
                    await sendToUser(customer, {
                        title: 'Game Completed!',
                        body: `Hope you had a great time! Don't forget to leave a review.`,
                        data: { bookingId: String(booking._id || booking.id), type: 'booking_completed' }
                    });
                }
            }
        }

        res.json({ message: `Booking status updated to ${status}`, booking: updated });
    } catch (error) {
        logger.error('updateStatus error:', error);
        res.status(500).json({ message: error.message });
    }
};

// @desc    Report ground issue
// @route   POST /api/staff/report-issue
// @access  Private/Staff
const reportIssue = async (req, res) => {
    const { turfId, category, description, images } = req.body;
    const reporterId = req.user._id || req.user.id;
    try {
        const maintenance = await staffRepository.reportMaintenance({
            turfId,
            reporterId,
            category,
            description,
            images: images || []
        });

        // Notify Owner
        const turf = await turfRepository.findTurfById(turfId);
        if (turf) {
            const ownerId = turf.ownerId?._id || turf.ownerId?.id || turf.ownerId;
            const owner = await userRepository.findById(ownerId);
            if (owner) {
                await sendToUser(owner, {
                    title: 'New Maintenance Issue!',
                    body: `A new ${category} issue has been reported for ${turf.name}.`,
                    data: { turfId: String(turfId), type: 'maintenance_report' }
                });
            }
        }

        res.status(201).json({
            message: 'Issue reported to owner',
            maintenance
        });
    } catch (error) {
        logger.error('reportIssue error:', error);
        res.status(500).json({ message: error.message });
    }
};

// @desc    Get slots for assigned turf
// @route   GET /api/staff/slots
// @access  Private/Staff
const getTurfSlots = async (req, res) => {
    try {
        const userId = req.user._id || req.user.id;
        const staff = await userRepository.findById(userId);
        const turfId = getStaffTurfId(staff);
        if (!turfId) {
            return res.status(400).json({ message: 'No turf assigned' });
        }

        const slots = await slotRepository.findSlots({ turfId });
        res.json(slots);
    } catch (error) {
        logger.error('getTurfSlots error:', error);
        res.status(500).json({ message: error.message });
    }
};

// @desc    Toggle slot blocking
// @route   PUT /api/staff/slot/:slotId/block
// @access  Private/Staff
const toggleSlotBlock = async (req, res) => {
    try {
        const slotId = req.params.slotId;
        if (staffRepository.isPostgres()) {
            const slot = await prisma.slot.findUnique({
                where: { id: String(slotId) }
            });
            if (!slot) {
                return res.status(404).json({ message: 'Slot not found' });
            }

            const updated = await prisma.slot.update({
                where: { id: String(slotId) },
                data: { isBlocked: !slot.isBlocked }
            });
            const serialized = serializeSlot(updated);
            return res.json({ message: `Slot ${serialized.isBlocked ? 'blocked' : 'unblocked'} successfully`, slot: serialized });
        }

        const SlotMongo = require('../models/Slot');
        const slot = await SlotMongo.findById(slotId);
        if (!slot) {
            return res.status(404).json({ message: 'Slot not found' });
        }

        slot.isBlocked = !slot.isBlocked;
        await slot.save();

        res.json({ message: `Slot ${slot.isBlocked ? 'blocked' : 'unblocked'} successfully`, slot });
    } catch (error) {
        logger.error('toggleSlotBlock error:', error);
        res.status(500).json({ message: error.message });
    }
};

// @desc    Create walk-in booking
// @route   POST /api/staff/walk-in
// @access  Private/Staff
const createWalkInBooking = async (req, res) => {
    const { slotId, sport, totalAmount } = req.body;
    try {
        const userId = req.user._id || req.user.id;
        const staff = await userRepository.findById(userId);
        const turfId = getStaffTurfId(staff);
        if (!turfId) {
            return res.status(400).json({ message: 'No turf assigned' });
        }

        const slot = await slotRepository.findSlotById(slotId);
        if (!slot || slot.isBlocked) {
            return res.status(400).json({ message: 'Slot is not available' });
        }

        // Standardize walk-in date to UTC midnight
        const now = new Date();
        const startOfUtcToday = new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), now.getUTCDate()));
        const endOfUtcToday = new Date(startOfUtcToday);
        endOfUtcToday.setUTCDate(endOfUtcToday.getUTCDate() + 1);

        if (staffRepository.isPostgres()) {
            const existingBooking = await prisma.booking.findFirst({
                where: {
                    slotId: String(slotId),
                    bookingDate: { gte: startOfUtcToday, lt: endOfUtcToday },
                    bookingStatus: { not: 'cancelled' }
                }
            });

            if (existingBooking) {
                return res.status(400).json({ message: 'Slot already booked for today' });
            }

            const booking = await prisma.booking.create({
                data: {
                    userId: null,
                    turfId: String(turfId),
                    slotId: String(slotId),
                    groundName: slot.groundName || staff.assignedGround || '',
                    bookingDate: startOfUtcToday,
                    totalAmount: Number(totalAmount),
                    paymentStatus: 'paid',
                    bookingStatus: 'checked_in',
                    paymentMethod: 'cash',
                    checkInTime: new Date()
                },
                include: { turf: true, slot: true }
            });

            return res.status(201).json(serializeBooking(booking));
        }

        const BookingMongo = require('../models/Booking');
        const existingBooking = await BookingMongo.findOne({
            slotId,
            bookingDate: { $gte: startOfUtcToday },
            bookingStatus: { $ne: 'cancelled' }
        });

        if (existingBooking) {
            return res.status(400).json({ message: 'Slot already booked for today' });
        }

        const booking = await BookingMongo.create({
            userId: null,
            turfId,
            slotId,
            bookingDate: startOfUtcToday,
            totalAmount,
            paymentStatus: 'paid',
            bookingStatus: 'checked-in',
            paymentMethod: 'cash',
            checkInTime: new Date()
        });

        res.status(201).json(booking);
    } catch (error) {
        logger.error('createWalkInBooking error:', error);
        res.status(500).json({ message: error.message });
    }
};

// @desc    Update turf operational status
// @route   PUT /api/staff/turf/status
// @access  Private/Staff
const updateOperationalStatus = async (req, res) => {
    const { status } = req.body;
    try {
        const userId = req.user._id || req.user.id;
        const staff = await userRepository.findById(userId);
        const turfId = getStaffTurfId(staff);
        if (!turfId) {
            return res.status(400).json({ message: 'No turf assigned' });
        }

        await turfRepository.updateTurf(turfId, { operationalStatus: status });

        // Notify Owner
        const turf = await turfRepository.findTurfById(turfId);
        if (turf) {
            const ownerId = turf.ownerId?._id || turf.ownerId?.id || turf.ownerId;
            const owner = await userRepository.findById(ownerId);
            if (owner) {
                await sendToUser(owner, {
                    title: 'Turf Status Change',
                    body: `${turf.name} status updated to: ${status}`,
                    data: { turfId: String(turfId), type: 'operational_status' }
                });
            }
        }

        res.json({ message: `Turf status updated to ${status}`, operationalStatus: status });
    } catch (error) {
        logger.error('updateOperationalStatus error:', error);
        res.status(500).json({ message: error.message });
    }
};

// @desc    Add staff notes to booking
// @route   PUT /api/staff/booking/:bookingId/notes
// @access  Private/Staff
const updateBookingNotes = async (req, res) => {
    const { notes } = req.body;
    try {
        const bookingId = req.params.bookingId;
        const booking = await bookingRepository.updateBooking(bookingId, { staffNotes: notes || '' });
        if (!booking) {
            return res.status(404).json({ message: 'Booking not found' });
        }

        res.json({ message: 'Notes updated', booking });
    } catch (error) {
        logger.error('updateBookingNotes error:', error);
        res.status(500).json({ message: error.message });
    }
};

// @desc    Staff Clock-in
// @route   POST /api/staff/attendance/clock-in
// @access  Private/Staff
const clockIn = async (req, res) => {
    try {
        const userId = req.user._id || req.user.id;
        console.log(`Clock-in attempt for user: ${userId}`);
        const staff = await userRepository.findById(userId);
        const turfId = getStaffTurfId(staff);
        if (!staff || !turfId) {
            console.log('Clock-in failed: No turf assigned');
            return res.status(400).json({ message: 'No turf assigned' });
        }

        // Count shifts for today
        const shiftCount = await staffRepository.getTodayShiftCount(userId);
        if (shiftCount >= 3) {
            console.log('Clock-in failed: Max shifts reached');
            return res.status(400).json({ message: 'Max 3 shifts per day allowed' });
        }

        // Only block if there's an ACTIVE clock-in (not yet clocked out)
        const activeAttendance = await staffRepository.findActiveAttendance(userId);
        if (activeAttendance) {
            console.log('Clock-in failed: Already active');
            return res.status(400).json({ message: 'Already clocked in' });
        }

        const attendance = await staffRepository.clockIn({
            userId,
            turfId,
            groundName: staff.assignedGround || ''
        });

        console.log('Clock-in successful');
        res.status(201).json(attendance);
    } catch (error) {
        console.error('Clock-in error:', error.message);
        res.status(500).json({ message: error.message });
    }
};

// @desc    Staff Clock-out
// @route   POST /api/staff/attendance/clock-out
// @access  Private/Staff
const clockOut = async (req, res) => {
    try {
        const userId = req.user._id || req.user.id;
        console.log(`Clock-out attempt for user: ${userId}`);

        const attendance = await staffRepository.findActiveAttendance(userId);
        if (!attendance) {
            console.log('Clock-out failed: No active session');
            return res.status(400).json({ message: 'No active clock-in found' });
        }

        const attendanceId = attendance._id || attendance.id;
        const updated = await staffRepository.clockOut(attendanceId);

        console.log('Clock-out successful');
        res.json(updated);
    } catch (error) {
        console.error('Clock-out error:', error.message);
        res.status(500).json({ message: error.message });
    }
};

// @desc    Get active attendance
// @route   GET /api/staff/attendance/active
// @access  Private/Staff
const getActiveAttendance = async (req, res) => {
    try {
        const userId = req.user._id || req.user.id;
        const attendance = await staffRepository.findActiveAttendance(userId);
        if (attendance) {
            console.log(`Active session found for user ${userId}`);
        }
        res.json(attendance);
    } catch (error) {
        console.error('Error fetching active attendance:', error.message);
        res.status(500).json({ message: error.message });
    }
};

// @desc    Get staff attendance history
// @route   GET /api/staff/attendance/history
// @access  Private/Staff
const getAttendanceHistory = async (req, res) => {
    try {
        const userId = req.user._id || req.user.id;
        const history = await staffRepository.findAttendanceHistory(userId);
        res.json(history);
    } catch (error) {
        logger.error('getAttendanceHistory error:', error);
        res.status(500).json({ message: error.message });
    }
};

// @desc    Get staff productivity stats
// @route   GET /api/staff/stats
// @access  Private/Staff
const getProductivityStats = async (req, res) => {
    try {
        const userId = req.user._id || req.user.id;
        const staff = await userRepository.findById(userId);
        const turfId = getStaffTurfId(staff);
        if (!turfId) {
            return res.json({
                handledBookings: 0,
                resolvedIssues: 0,
                feedbackScore: 4.8
            });
        }

        const stats = await staffRepository.getStaffStats(turfId);
        res.json(stats);
    } catch (error) {
        logger.error('getProductivityStats error:', error);
        res.status(500).json({ message: error.message });
    }
};

// @desc    Report safety incident
// @route   POST /api/staff/report-incident
// @access  Private/Staff
const reportIncident = async (req, res) => {
    const { turfId, type, severity, description, images } = req.body;
    const reporterId = req.user._id || req.user.id;
    try {
        const incident = await staffRepository.reportIncident({
            turfId,
            reporterId,
            type,
            severity,
            description,
            images: images || []
        });

        // Notify Owner
        const turf = await turfRepository.findTurfById(turfId);
        if (turf) {
            const ownerId = turf.ownerId?._id || turf.ownerId?.id || turf.ownerId;
            const owner = await userRepository.findById(ownerId);
            if (owner) {
                await sendToUser(owner, {
                    title: 'EMERGENCY: Safety Incident!',
                    body: `A ${severity || 'Low'} severity incident (${type}) was reported at ${turf.name}.`,
                    data: { turfId: String(turfId), type: 'safety_incident' }
                });
            }
        }

        res.status(201).json({ message: 'Incident reported successfully', incident });
    } catch (error) {
        logger.error('reportIncident error:', error);
        res.status(500).json({ message: error.message });
    }
};

// @desc    Get staff announcements
// @route   GET /api/staff/announcements
// @access  Private/Staff
const getAnnouncements = async (req, res) => {
    try {
        const userId = req.user._id || req.user.id;
        const staff = await userRepository.findById(userId);
        const turfId = getStaffTurfId(staff);
        if (!turfId) {
            return res.json([]);
        }

        const announcements = await staffRepository.findAnnouncementsByTurf(turfId);
        res.json(announcements);
    } catch (error) {
        logger.error('getAnnouncements error:', error);
        res.status(500).json({ message: error.message });
    }
};

// @desc    Add extra charges to a booking
// @route   PUT /api/staff/booking/:bookingId/extra-charges
// @access  Private/Staff
const addExtraCharge = async (req, res) => {
    const { type, amount, isPaid } = req.body;
    const bookingId = req.params.bookingId;
    try {
        if (staffRepository.isPostgres()) {
            const booking = await prisma.booking.findUnique({
                where: { id: String(bookingId) }
            });
            if (!booking) {
                return res.status(404).json({ message: 'Booking not found' });
            }

            const currentCharges = Array.isArray(booking.extraCharges) ? booking.extraCharges : [];
            const updatedCharges = [...currentCharges, { type, amount: Number(amount), isPaid: isPaid || false }];

            const updated = await prisma.booking.update({
                where: { id: String(bookingId) },
                data: { extraCharges: updatedCharges },
                include: { turf: true, slot: true, user: true }
            });

            return res.json({ message: 'Extra charge added', booking: serializeBooking(updated) });
        }

        const BookingMongo = require('../models/Booking');
        const booking = await BookingMongo.findById(bookingId);
        if (!booking) {
            return res.status(404).json({ message: 'Booking not found' });
        }

        booking.extraCharges.push({ type, amount, isPaid: isPaid || false });
        await booking.save();

        res.json({ message: 'Extra charge added', booking });
    } catch (error) {
        logger.error('addExtraCharge error:', error);
        res.status(500).json({ message: error.message });
    }
};

module.exports = {
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
    getActiveAttendance,
    getAttendanceHistory
};
