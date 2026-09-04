const userRepository = require('../repositories/userRepository');
const turfRepository = require('../repositories/turfRepository');
const slotRepository = require('../repositories/slotRepository');
const bookingRepository = require('../repositories/bookingRepository');
const logger = require('../services/logger');
const { getCache, setCache, deleteCache } = require('../services/redis');
const { emitToTurf } = require('../services/socket');
const { sendToUser } = require('../services/notificationService');

// @desc    Get all approved turfs
// @route   GET /api/customer/turfs
// @access  Public
const getTurfs = async (req, res) => {
    try {
        const cached = await getCache('turfs:all');
        if (cached) return res.json(cached);

        const turfs = await turfRepository.findApprovedTurfs();
        await setCache('turfs:all', turfs, 120);
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
        const cacheKey = `turf:${turfId}`;
        const cached = await getCache(cacheKey);
        if (cached) return res.json(cached);

        const turf = await turfRepository.findTurfById(turfId);
        if (!turf) {
            return res.status(404).json({ message: 'Turf not found or is blocked' });
        }

        await setCache(cacheKey, turf, 120);
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

        const targetDate = date || new Date().toISOString().split('T')[0];
        const cacheKey = `slots:${turfId}:${targetDate}:${groundName || 'all'}`;
        const cached = await getCache(cacheKey);
        if (cached) return res.json(cached);

        const [year, month, day] = targetDate.split('-').map(Number);
        const startOfUtcDay = new Date(Date.UTC(year, month - 1, day));
        const endOfUtcDay = new Date(startOfUtcDay);
        endOfUtcDay.setUTCDate(endOfUtcDay.getUTCDate() + 1);

        const days = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
        const dayOfWeek = days[startOfUtcDay.getUTCDay()];

        const cleanGroundName = (groundName && groundName !== 'all') ? groundName : undefined;
        const slots = await slotRepository.findSlots({ turfId, dayOfWeek, groundName: cleanGroundName });

        const bookings = await bookingRepository.findBookingsForDateRange(turfId, startOfUtcDay, endOfUtcDay);
        const bookedSlotIds = bookings.map(b => String(b.slotId?._id || b.slotId?.id || b.slotId));

        const enrichedSlots = slots.map(slot => {
            const slotDoc = slot._doc || slot;
            const slotIdStr = String(slotDoc._id || slotDoc.id);
            return {
                ...slotDoc,
                isBooked: bookedSlotIds.includes(slotIdStr)
            };
        });

        await setCache(cacheKey, enrichedSlots, 60);
        res.json(enrichedSlots);
    } catch (error) {
        logger.error('getTurfSlots error', { error: error.message });
        res.status(500).json({ message: error.message });
    }
};

// @desc    Create a new booking
// @route   POST /api/customer/bookings
// @access  Private/Customer
const createBooking = async (req, res) => {
    try {
        const { turfId, slotId, bookingDate, totalAmount, paymentMethod } = req.body;
        const [year, month, day] = bookingDate.split('-').map(Number);
        const utcDate = new Date(Date.UTC(year, month - 1, day));

        const slot = await slotRepository.findSlotById(slotId);
        if (!slot) {
            return res.status(404).json({ message: 'Slot not found' });
        }

        const turf = await turfRepository.findTurfById(turfId);
        if (!turf) {
            return res.status(404).json({ message: 'Turf not found' });
        }

        const baseAmount = totalAmount || 0;
        const taxPercentage = turf.settings?.taxPercentage || turf.taxPercentage || 0;
        const taxAmount = baseAmount * (taxPercentage / 100);
        const finalAmount = baseAmount + taxAmount;

        const booking = await bookingRepository.createBookingAtomic({
            userId: req.user._id || req.user.id,
            turfId,
            slotId,
            groundName: slot.groundName || '',
            bookingDate: utcDate,
            totalAmount: finalAmount,
            taxAmount,
            paymentMethod: paymentMethod || 'cash',
            paymentStatus: 'pending',
            bookingStatus: 'confirmed'
        });

        // Invalidate slot cache & emit real-time event
        await deleteCache(`slots:${turfId}:*`);
        
        emitToTurf(turfId, 'slotBooked', {
            slotId,
            bookingDate: utcDate.toISOString(),
            bookedBy: req.user._id || req.user.id,
        });

        const ownerId = turf.ownerId?._id || turf.ownerId?.id || turf.ownerId;
        const owner = await userRepository.findById(ownerId);
        if (owner) {
            await sendToUser(owner, {
                title: 'New Booking!',
                body: `You have a new booking at ${turf.name} for ${slot.startTime}.`,
                data: { bookingId: String(booking._id || booking.id), type: 'new_booking' }
            });
        }

        res.status(201).json(booking);
    } catch (error) {
        logger.error('createBooking error', { error: error.message });
        res.status(error.status || 500).json({ message: error.message });
    }
};

// @desc    Get bookings for authenticated customer
// @route   GET /api/customer/bookings
// @access  Private/Customer
const getMyBookings = async (req, res) => {
    try {
        const userId = req.user._id || req.user.id;
        const bookings = await bookingRepository.findUserBookings(userId);
        res.json(bookings);
    } catch (error) {
        logger.error('getMyBookings error', { error: error.message });
        res.status(500).json({ message: error.message });
    }
};

// @desc    Get current user profile
// @route   GET /api/customer/profile
// @access  Private/Customer
const getProfile = async (req, res) => {
    try {
        const userId = req.user._id || req.user.id;
        const user = await userRepository.findById(userId);
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
        const userId = req.user._id || req.user.id;
        const user = await userRepository.findById(userId);
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

        if (typeof user.save === 'function') {
            const updatedUser = await user.save();
            return res.json({
                _id: updatedUser._id,
                name: updatedUser.name,
                email: updatedUser.email,
                phone: updatedUser.phone,
                profileImage: updatedUser.profileImage,
                role: updatedUser.role
            });
        } else {
            const { prisma } = require('../config/db');
            const bcrypt = require('bcryptjs');
            const data = {
                name: user.name,
                email: user.email,
                phone: user.phone,
                profileImage: user.profileImage
            };
            if (req.body.password) {
                data.password = await bcrypt.hash(req.body.password, 10);
            }
            const updated = await prisma.user.update({
                where: { id: String(userId) },
                data
            });
            return res.json({
                _id: updated.id,
                id: updated.id,
                name: updated.name,
                email: updated.email,
                phone: updated.phone,
                profileImage: updated.profileImage,
                role: updated.role
            });
        }
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

// @desc    Cancel a booking
// @route   PUT /api/customer/bookings/:id/cancel
// @access  Private/Customer
const cancelBooking = async (req, res) => {
    try {
        const booking = await bookingRepository.findBookingById(req.params.id);

        if (!booking) {
            return res.status(404).json({ message: 'Booking not found' });
        }

        const bookingUserId = String(booking.userId?._id || booking.userId?.id || booking.userId);
        const reqUserId = String(req.user._id || req.user.id);

        if (bookingUserId !== reqUserId) {
            return res.status(403).json({ message: 'Not authorized to cancel this booking' });
        }

        if (booking.bookingStatus === 'cancelled') {
            return res.status(400).json({ message: 'Booking is already cancelled' });
        }

        const updatedBooking = await bookingRepository.updateBooking(req.params.id, {
            bookingStatus: 'cancelled'
        });

        const turfId = String(booking.turfId?._id || booking.turfId?.id || booking.turfId);
        await deleteCache(`slots:${turfId}:*`);

        res.json({ message: 'Booking cancelled successfully', booking: updatedBooking });
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
