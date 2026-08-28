const User = require('../models/User');
const Turf = require('../models/Turf');
const Slot = require('../models/Slot');
const Booking = require('../models/Booking');
const logger = require('../services/logger');
const { getCache, setCache, deleteCache } = require('../services/redis');
const { emitToTurf } = require('../services/socket');
const { sendToUser } = require('../services/notificationService');

// @desc    Get all approved turfs
// @route   GET /api/customer/turfs
// @access  Public
const getTurfs = async (req, res) => {
    try {
        // Check cache first
        const cached = await getCache('turfs:all');
        if (cached) return res.json(cached);

        const turfs = await Turf.find({ status: { $ne: 'blocked' } });
        await setCache('turfs:all', turfs, 120); // cache for 2 minutes
        res.json(turfs);
    } catch (error) {
        logger.error('getTurfs error', { error: error.message });
        res.status(500).json({ message: error.message });
    }
};

// @desc    Get a specific turf by ID
// @route   GET /api/customer/turfs/:id
// @access  Public
const getTurfById = async (req, res) => {
    try {
        const turfId = req.params.id;
        
        // Check cache first
        const cacheKey = `turf:${turfId}`;
        const cached = await getCache(cacheKey);
        if (cached) return res.json(cached);

        const turf = await Turf.findOne({ _id: turfId, status: { $ne: 'blocked' } })
            .populate('ownerId', 'name email phone');
            
        if (!turf) {
            return res.status(404).json({ message: 'Turf not found or is blocked' });
        }

        await setCache(cacheKey, turf, 120); // cache for 2 minutes
        res.json(turf);
    } catch (error) {
        logger.error('getTurfById error', { error: error.message, turfId: req.params.id });
        res.status(500).json({ message: error.message });
    }
};

// @desc    Get slots for a specific turf and date
// @route   GET /api/customer/turfs/:turfId/slots
// @access  Public
const getTurfSlots = async (req, res) => {
    try {
        const { date, groundName } = req.query; // Expecting YYYY-MM-DD
        const turfId = req.params.turfId;

        // Check cache first
        const cacheKey = `slots:${turfId}:${date}:${groundName || 'all'}`;
        const cached = await getCache(cacheKey);
        if (cached) return res.json(cached);

        // Robust normalization using split to avoid timezone shifts
        const [year, month, day] = date.split('-').map(Number);
        const startOfUtcDay = new Date(Date.UTC(year, month - 1, day));
        const endOfUtcDay = new Date(startOfUtcDay);
        endOfUtcDay.setUTCDate(endOfUtcDay.getUTCDate() + 1);

        const days = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
        const dayOfWeek = days[startOfUtcDay.getUTCDay()];

        const query = { turfId, dayOfWeek };
        if (groundName) {
            query.groundName = groundName;
        }

        const slots = await Slot.find(query);

        // Fetch bookings for this UTC day to mark slots as booked
        const bookings = await Booking.find({
            turfId,
            bookingDate: {
                $gte: startOfUtcDay,
                $lt: endOfUtcDay
            },
            bookingStatus: { $ne: 'cancelled' }
        });

        const bookedSlotIds = bookings.map(b => b.slotId.toString());

        // Filter expired slots for today with 15 mins grace period
        const isToday = startOfUtcDay.toISOString().split('T')[0] === new Date().toISOString().split('T')[0];
        const currentTime = new Date();

        const enrichedSlots = slots.map(slot => ({
            ...slot._doc,
            isBooked: bookedSlotIds.includes(slot._id.toString())
        })).filter(slot => {
            if (!isToday) return true;

            const [hours, minutes] = slot.startTime.split(':').map(Number);
            const slotTime = new Date();
            slotTime.setHours(hours, minutes, 0, 0);

            // 15 minutes grace period: if slotTime + 15 mins > current time, it's still bookable
            const graceTime = new Date(slotTime.getTime() + 15 * 60000);
            return graceTime > currentTime;
        });

        await setCache(cacheKey, enrichedSlots, 60); // cache for 1 minute
        res.json(enrichedSlots);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

// @desc    Create a new booking
// @route   POST /api/customer/bookings
// @access  Private/Customer
const createBooking = async (req, res) => {
    try {
        const { turfId, slotId, bookingDate, totalAmount, paymentMethod } = req.body;
        console.log(`[BOOKING] Request for turf: ${turfId}, slot: ${slotId}, date: ${bookingDate}`);

        // Robust standardization to UTC midnight using string splitting
        const [year, month, day] = bookingDate.split('-').map(Number);
        const utcDate = new Date(Date.UTC(year, month - 1, day));

        const nextDayUtc = new Date(utcDate);
        nextDayUtc.setUTCDate(nextDayUtc.getUTCDate() + 1);

        console.log(`[BOOKING] Normalized range: ${utcDate.toISOString()} to ${nextDayUtc.toISOString()}`);

        // Verify slot is not already booked
        const existingBooking = await Booking.findOne({
            slotId,
            bookingDate: {
                $gte: utcDate,
                $lt: nextDayUtc
            },
            bookingStatus: { $ne: 'cancelled' }
        });

        if (existingBooking) {
            console.log(`Attempted double booking rejected for slot: ${slotId} on ${utcDate.toISOString()}`);
            return res.status(400).json({ message: 'Slot already booked for this date' });
        }

        const slot = await Slot.findById(slotId);
        if (!slot) {
            return res.status(404).json({ message: 'Slot not found' });
        }

        // Validate expiration for today
        const isToday = utcDate.toISOString().split('T')[0] === new Date().toISOString().split('T')[0];
        if (isToday) {
            const [hours, minutes] = slot.startTime.split(':').map(Number);
            const slotTime = new Date();
            slotTime.setHours(hours, minutes, 0, 0);
            const graceTime = new Date(slotTime.getTime() + 15 * 60000);
            if (graceTime <= new Date()) {
                return res.status(400).json({ message: 'Slot has expired' });
            }
        }

        const turf = await Turf.findById(turfId);
        if (!turf) {
            return res.status(404).json({ message: 'Turf not found' });
        }

        const baseAmount = totalAmount || 0;
        const taxPercentage = turf.settings?.taxPercentage || 0;
        const taxAmount = baseAmount * (taxPercentage / 100);
        const finalAmount = baseAmount + taxAmount;

        const booking = await Booking.create({
            userId: req.user._id,
            turfId,
            slotId,
            groundName: slot.groundName || '',
            bookingDate: utcDate,
            totalAmount: finalAmount,
            taxAmount,
            paymentStatus: paymentMethod === 'upi' ? 'pending' : 'pending',
            bookingStatus: 'confirmed',
            paymentMethod
        });

        // Invalidate slot cache & emit real-time event
        await deleteCache(`slots:${turfId}:*`);
        
        emitToTurf(turfId, 'slotBooked', {
            slotId,
            bookingDate: utcDate.toISOString(),
            bookedBy: req.user._id,
        });
        logger.info('Booking created', { bookingId: booking._id, turfId, slotId });

        // Push Notifications for Owner & Staff
        const owner = await User.findById(turf.ownerId);
        if (owner) {
            await sendToUser(owner, {
                title: 'New Booking!',
                body: `You have a new booking at ${turf.name} for ${slot.startTime}.`,
                data: { bookingId: booking._id.toString(), type: 'new_booking' }
            });
        }

        const assignedStaff = await User.find({ assignedTurfId: turfId, role: 'staff' });
        for (const staff of assignedStaff) {
            await sendToUser(staff, {
                title: 'New Assignment',
                body: `New booking at ${turf.name} (${slot.groundName}) for ${slot.startTime}.`,
                data: { bookingId: booking._id.toString(), type: 'new_booking' }
            });
        }

        res.status(201).json(booking);
    } catch (error) {
        logger.error('createBooking error', { error: error.message });
        res.status(500).json({ message: error.message });
    }
};

// @desc    Get bookings for authenticated customer
// @route   GET /api/customer/bookings
// @access  Private/Customer
const getMyBookings = async (req, res) => {
    try {
        const bookings = await Booking.find({ userId: req.user._id })
            .populate('turfId', 'name location images')
            .populate('slotId', 'startTime endTime sport price')
            .populate('reviewId', 'rating')
            .sort({ bookingDate: -1 });

        res.json(bookings);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

// @desc    Get current user profile
// @route   GET /api/customer/profile
// @access  Private/Customer
const getProfile = async (req, res) => {
    try {
        const user = await User.findById(req.user._id).select('-password');
        if (!user) {
            return res.status(404).json({ message: 'User not found' });
        }
        res.json(user);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

// @desc    Update user profile
// @route   PUT /api/customer/profile
// @access  Private/Customer
const updateProfile = async (req, res) => {
    try {
        const user = await User.findById(req.user._id);
        if (!user) {
            return res.status(404).json({ message: 'User not found' });
        }

        user.name = req.body.name || user.name;
        user.email = req.body.email || user.email;
        user.phone = req.body.phone || user.phone;
        user.profileImage = req.body.profileImage || user.profileImage;

        if (req.body.password) {
            user.password = req.body.password;
        }

        const updatedUser = await user.save();
        res.json({
            _id: updatedUser._id,
            name: updatedUser.name,
            email: updatedUser.email,
            phone: updatedUser.phone,
            profileImage: updatedUser.profileImage,
            role: updatedUser.role
        });
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

// @desc    Cancel a booking
// @route   PUT /api/customer/bookings/:id/cancel
// @access  Private/Customer
const cancelBooking = async (req, res) => {
    try {
        const booking = await Booking.findById(req.params.id);

        if (!booking) {
            return res.status(404).json({ message: 'Booking not found' });
        }

        // Ensure the booking belongs to the current user
        if (booking.userId.toString() !== req.user._id.toString()) {
            return res.status(401).json({ message: 'Not authorized to cancel this booking' });
        }

        if (booking.bookingStatus === 'cancelled') {
            return res.status(400).json({ message: 'Booking is already cancelled' });
        }

        booking.bookingStatus = 'cancelled';
        await booking.save();

        // Invalidate cache & emit real-time event
        await deleteCache(`slots:${booking.turfId}:*`);
        emitToTurf(booking.turfId.toString(), 'slotCancelled', {
            slotId: booking.slotId,
            bookingDate: booking.bookingDate,
        });
        logger.info('Booking cancelled', { bookingId: booking._id });

        // Push Notifications for Owner & Staff
        const turf = await Turf.findById(booking.turfId);
        if (turf) {
            const owner = await User.findById(turf.ownerId);
            if (owner) {
                await sendToUser(owner, {
                    title: 'Booking Cancelled',
                    body: `A booking for ${turf.name} on ${booking.bookingDate.toDateString()} has been cancelled.`,
                    data: { bookingId: booking._id.toString(), type: 'booking_cancelled' }
                });
            }

            const assignedStaff = await User.find({ assignedTurfId: booking.turfId, role: 'staff' });
            for (const staff of assignedStaff) {
                await sendToUser(staff, {
                    title: 'Booking Cancelled',
                    body: `The booking at ${turf.name} for ${booking.bookingDate.toDateString()} has been cancelled.`,
                    data: { bookingId: booking._id.toString(), type: 'booking_cancelled' }
                });
            }
        }

        res.json({ message: 'Booking cancelled successfully', booking });
    } catch (error) {
        logger.error('cancelBooking error', { error: error.message });
        res.status(500).json({ message: error.message });
    }
};

module.exports = {
    getTurfs,
    getTurfById,
    getTurfSlots,
    createBooking,
    getMyBookings,
    getProfile,
    updateProfile,
    cancelBooking
};
