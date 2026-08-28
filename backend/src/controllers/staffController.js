const User = require('../models/User');
const Booking = require('../models/Booking');
const Turf = require('../models/Turf');
const Slot = require('../models/Slot');
const Maintenance = require('../models/Maintenance');
const Attendance = require('../models/Attendance');
const Incident = require('../models/Incident');
const { emitToTurf } = require('../services/socket');
const Announcement = require('../models/Announcement');
const { sendToUser } = require('../services/notificationService');

// @desc    Get bookings for assigned turf
// @route   GET /api/staff/bookings
// @access  Private/Staff
const getAssignedBookings = async (req, res) => {
    try {
        const staff = await User.findById(req.user._id);
        if (!staff) {
            console.log('Staff user not found:', req.user._id);
            return res.status(404).json({ message: 'Staff user not found' });
        }

        if (!staff.assignedTurfId) {
            console.log('Staff user has no assigned turf:', staff.email);
            return res.json([]);
        }

        console.log(`Fetching bookings for staff: ${staff.email}, TurfID: ${staff.assignedTurfId}`);

        // Fetch bookings for the assigned turf
        const bookings = await Booking.find({
            turfId: staff.assignedTurfId,
            bookingStatus: { $ne: 'cancelled' }
        })
            .populate('userId', 'name phone')
            .populate('slotId')
            .sort({ bookingDate: 1 });

        console.log(`[STAFF] Found ${bookings.length} bookings for turf ${staff.assignedTurfId}`);
        if (bookings.length > 0) {
            console.log(`[STAFF] Latest booking date: ${bookings[0].bookingDate.toISOString()}`);
        }

        res.json(bookings);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

// @desc    Verify booking (Manual/QR)
// @route   POST /api/staff/verify/:bookingId
// @access  Private/Staff
const verifyBooking = async (req, res) => {
    try {
        const booking = await Booking.findById(req.params.bookingId).populate('turfId');
        if (!booking) {
            return res.status(404).json({ message: 'Booking not found' });
        }

        // Mark as arrived/verified and record timestamp
        booking.bookingStatus = 'checked-in';
        booking.checkInTime = new Date();
        await booking.save();

        // Real-time Event
        emitToTurf(booking.turfId._id.toString(), 'bookingUpdated', {
            bookingId: booking._id,
            status: 'checked-in'
        });

        // Notify Customer
        const customer = await User.findById(booking.userId);
        if (customer) {
            await sendToUser(customer, {
                title: 'Check-in Successful!',
                body: `You have successfully checked in at ${booking.turfId.name}. Enjoy your game!`,
                data: { bookingId: booking._id.toString(), type: 'check_in' }
            });
        }

        res.json({ message: 'Booking verified successfully', booking });
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

// @desc    Update booking status (no-show, completed)
// @route   PUT /api/staff/booking/:bookingId/status
// @access  Private/Staff
const updateStatus = async (req, res) => {
    const { status } = req.body;
    try {
        const booking = await Booking.findById(req.params.bookingId);
        if (!booking) {
            return res.status(404).json({ message: 'Booking not found' });
        }

        booking.bookingStatus = status; // 'completed', 'no-show'
        await booking.save();

        // Real-time Event
        emitToTurf(booking.turfId.toString(), 'bookingUpdated', {
            bookingId: booking._id,
            status: status
        });

        // Notify Customer if completed
        if (status === 'completed') {
            const customer = await User.findById(booking.userId);
            if (customer) {
                await sendToUser(customer, {
                    title: 'Game Completed!',
                    body: `Hope you had a great time! Don't forget to leave a review.`,
                    data: { bookingId: booking._id.toString(), type: 'booking_completed' }
                });
            }
        }

        res.json({ message: `Booking status updated to ${status}`, booking });
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

// @desc    Report ground issue
// @route   POST /api/staff/report-issue
// @access  Private/Staff
const reportIssue = async (req, res) => {
    const { turfId, category, description, images } = req.body;
    try {
        const maintenance = await Maintenance.create({
            turfId,
            reporterId: req.user._id,
            category,
            description,
            images: images || []
        });

        // Notify Owner
        const turf = await Turf.findById(turfId);
        if (turf) {
            const owner = await User.findById(turf.ownerId);
            if (owner) {
                await sendToUser(owner, {
                    title: 'New Maintenance Issue!',
                    body: `A new ${category} issue has been reported for ${turf.name}.`,
                    data: { turfId: turfId.toString(), type: 'maintenance_report' }
                });
            }
        }

        res.status(201).json({
            message: 'Issue reported to owner',
            maintenance
        });
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

// @desc    Get slots for assigned turf
// @route   GET /api/staff/slots
// @access  Private/Staff
const getTurfSlots = async (req, res) => {
    try {
        const staff = await User.findById(req.user._id);
        if (!staff.assignedTurfId) {
            return res.status(400).json({ message: 'No turf assigned' });
        }

        const slots = await Slot.find({ turfId: staff.assignedTurfId });
        res.json(slots);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

// @desc    Toggle slot blocking
// @route   PUT /api/staff/slot/:slotId/block
// @access  Private/Staff
const toggleSlotBlock = async (req, res) => {
    try {
        const slot = await Slot.findById(req.params.slotId);
        if (!slot) {
            return res.status(404).json({ message: 'Slot not found' });
        }

        slot.isBlocked = !slot.isBlocked;
        await slot.save();

        res.json({ message: `Slot ${slot.isBlocked ? 'blocked' : 'unblocked'} successfully`, slot });
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

// @desc    Create walk-in booking
// @route   POST /api/staff/walk-in
// @access  Private/Staff
const createWalkInBooking = async (req, res) => {
    const { slotId, sport, totalAmount } = req.body;
    try {
        const staff = await User.findById(req.user._id);
        if (!staff.assignedTurfId) {
            return res.status(400).json({ message: 'No turf assigned' });
        }

        const slot = await Slot.findById(slotId);
        if (!slot || slot.isBlocked) {
            return res.status(400).json({ message: 'Slot is not available' });
        }

        // Check if already booked for today
        const today = new Date();
        today.setHours(0, 0, 0, 0);

        const existingBooking = await Booking.findOne({
            slotId,
            bookingDate: { $gte: today },
            bookingStatus: { $ne: 'cancelled' }
        });

        if (existingBooking) {
            return res.status(400).json({ message: 'Slot already booked for today' });
        }

        // Standardize walk-in date to UTC midnight
        const now = new Date();
        const startOfUtcToday = new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), now.getUTCDate()));

        const booking = await Booking.create({
            userId: null,
            turfId: staff.assignedTurfId,
            slotId,
            bookingDate: startOfUtcToday,
            totalAmount,
            paymentStatus: 'paid',
            bookingStatus: 'checked-in',
            paymentMethod: 'cash'
        });

        res.status(201).json(booking);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

// @desc    Update turf operational status
// @route   PUT /api/staff/turf/status
// @access  Private/Staff
const updateOperationalStatus = async (req, res) => {
    const { status } = req.body;
    try {
        const staff = await User.findById(req.user._id);
        if (!staff.assignedTurfId) {
            return res.status(400).json({ message: 'No turf assigned' });
        }

        const turf = await Turf.findById(staff.assignedTurfId);
        turf.operationalStatus = status;
        await turf.save();

        // Notify Owner
        const owner = await User.findById(turf.ownerId);
        if (owner) {
            await sendToUser(owner, {
                title: 'Turf Status Change',
                body: `${turf.name} status updated to: ${status}`,
                data: { turfId: turf._id.toString(), type: 'operational_status' }
            });
        }

        res.json({ message: `Turf status updated to ${status}`, operationalStatus: status });
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

// @desc    Add staff notes to booking
// @route   PUT /api/staff/booking/:bookingId/notes
// @access  Private/Staff
const updateBookingNotes = async (req, res) => {
    const { notes } = req.body;
    try {
        const booking = await Booking.findById(req.params.bookingId);
        if (!booking) {
            return res.status(404).json({ message: 'Booking not found' });
        }

        booking.staffNotes = notes;
        await booking.save();

        res.json({ message: 'Notes updated', booking });
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

// @desc    Staff Clock-in
// @route   POST /api/staff/attendance/clock-in
// @access  Private/Staff
const clockIn = async (req, res) => {
    try {
        console.log(`Clock-in attempt for user: ${req.user._id}`);
        const staff = await User.findById(req.user._id);
        if (!staff || !staff.assignedTurfId) {
            console.log('Clock-in failed: No turf assigned');
            return res.status(400).json({ message: 'No turf assigned' });
        }

        const today = new Date();
        today.setHours(0, 0, 0, 0);

        // Count shifts for today
        const shiftCount = await Attendance.countDocuments({
            userId: req.user._id,
            clockIn: { $gte: today }
        });

        if (shiftCount >= 3) {
            console.log('Clock-in failed: Max shifts reached');
            return res.status(400).json({ message: 'Max 3 shifts per day allowed' });
        }

        // Only block if there's an ACTIVE clock-in (not yet clocked out)
        const activeAttendance = await Attendance.findOne({
            userId: req.user._id,
            clockOut: null
        }).sort({ clockIn: -1 });

        if (activeAttendance) {
            console.log('Clock-in failed: Already active');
            return res.status(400).json({ message: 'Already clocked in' });
        }

        const attendance = await Attendance.create({
            userId: req.user._id,
            turfId: staff.assignedTurfId,
            groundName: staff.assignedGround || '',
            clockIn: new Date()
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
        console.log(`Clock-out attempt for user: ${req.user._id}`);
        // Find the most recent active clock-in (regardless of date)
        const attendance = await Attendance.findOne({
            userId: req.user._id,
            clockOut: null
        }).sort({ clockIn: -1 });

        if (!attendance) {
            console.log('Clock-out failed: No active session');
            return res.status(400).json({ message: 'No active clock-in found' });
        }

        attendance.clockOut = new Date();

        // Calculate work hours
        const diff = attendance.clockOut - attendance.clockIn;
        attendance.workHours = (diff / (1000 * 60 * 60)).toFixed(2);

        await attendance.save();

        console.log('Clock-out successful');
        res.json(attendance);
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
        // Find most recent session that hasn't been clocked out
        const attendance = await Attendance.findOne({
            userId: req.user._id,
            clockOut: null
        }).sort({ clockIn: -1 });

        if (attendance) {
            console.log(`Active session found for user ${req.user._id}`);
        }
        res.json(attendance);
    } catch (error) {
        console.error('Error fetching active attendance:', error.message);
        res.status(500).json({ message: error.message });
    }
};

// @desc    Get staff productivity stats
// @route   GET /api/staff/stats
// @access  Private/Staff
const getProductivityStats = async (req, res) => {
    try {
        const staff = await User.findById(req.user._id);
        const turfId = staff.assignedTurfId;

        const handledBookings = await Booking.countDocuments({
            turfId,
            bookingStatus: { $in: ['checked-in', 'completed'] }
        });

        const resolvedIssues = await Maintenance.countDocuments({
            turfId,
            status: 'Resolved'
        });

        // Mock feedback score for now
        const feedbackScore = 4.8;

        res.json({
            handledBookings,
            resolvedIssues,
            feedbackScore
        });
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

// @desc    Report safety incident
// @route   POST /api/staff/report-incident
// @access  Private/Staff
const reportIncident = async (req, res) => {
    const { turfId, type, severity, description, images } = req.body;
    try {
        const incident = await Incident.create({
            turfId,
            reporterId: req.user._id,
            type,
            severity,
            description,
            images: images || []
        });

        // Notify Owner
        const turf = await Turf.findById(turfId);
        if (turf) {
            const owner = await User.findById(turf.ownerId);
            if (owner) {
                await sendToUser(owner, {
                    title: 'EMERGENCY: Safety Incident!',
                    body: `A ${severity} severity incident (${type}) was reported at ${turf.name}.`,
                    data: { turfId: turfId.toString(), type: 'safety_incident' }
                });
            }
        }

        res.status(201).json({ message: 'Incident reported successfully', incident });
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

// @desc    Get staff announcements
// @route   GET /api/staff/announcements
// @access  Private/Staff
const getAnnouncements = async (req, res) => {
    try {
        const staff = await User.findById(req.user._id);
        const announcements = await Announcement.find({
            turfId: staff.assignedTurfId
        }).sort({ createdAt: -1 });

        res.json(announcements);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

// @desc    Add extra charges to a booking
// @route   PUT /api/staff/booking/:bookingId/extra-charges
// @access  Private/Staff
const addExtraCharge = async (req, res) => {
    const { type, amount, isPaid } = req.body;
    try {
        const booking = await Booking.findById(req.params.bookingId);
        if (!booking) {
            return res.status(404).json({ message: 'Booking not found' });
        }

        booking.extraCharges.push({ type, amount, isPaid: isPaid || false });
        await booking.save();

        res.json({ message: 'Extra charge added', booking });
    } catch (error) {
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
    getActiveAttendance
};
