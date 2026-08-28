const Turf = require('../models/Turf');
const Slot = require('../models/Slot');
const User = require('../models/User');
const Booking = require('../models/Booking');
const Payout = require('../models/Payout');
const Attendance = require('../models/Attendance');
const { emitToTurf, emitGlobal } = require('../services/socket');
const Announcement = require('../models/Announcement');
const { sendToUser } = require('../services/notificationService');

// @desc    Get owner's turfs
// @route   GET /api/owner/turfs
// @access  Private/Owner
const getMyTurfs = async (req, res) => {
    try {
        const turfs = await Turf.find({ ownerId: req.user._id });
        res.json(turfs);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

// @desc    Create a new turf
// @route   POST /api/owner/turf
// @access  Private/Owner
const createTurf = async (req, res) => {
    const { name, location, sports, amenities, images, upiId, taxPercentage, grounds, turfType } = req.body;
    console.log('Create Turf request:', { name, location, sports, images, turfType });

    try {
        const turf = await Turf.create({
            ownerId: req.user._id,
            name,
            location,
            sports,
            amenities,
            images,
            turfType: turfType || 'both',
            grounds: grounds || [],
            status: 'pending',
            settings: {
                upiId: upiId || '',
                taxPercentage: taxPercentage || 0
            }
        });

        if (turf) {
            console.log('Turf created successfully:', turf._id);
            res.status(201).json(turf);
        } else {
            console.log('Failed to create turf: Invalid data');
            res.status(400).json({ message: 'Invalid turf data' });
        }
    } catch (error) {
        console.error('Error creating turf:', error.message);
        res.status(500).json({ message: error.message });
    }
};

// @desc    Create/Update slots for a turf
// @route   POST /api/owner/slots
// @access  Private/Owner
const manageSlots = async (req, res) => {
    const { turfId, slots } = req.body; // slots is an array of objects

    try {
        const turf = await Turf.findById(turfId);
        if (!turf || turf.ownerId.toString() !== req.user._id.toString()) {
            return res.status(401).json({ message: 'Not authorized' });
        }

        // Upsert slots
        const savedSlots = await Promise.all(slots.map(async (slotData) => {
            return await Slot.findOneAndUpdate(
                {
                    turfId,
                    groundName: slotData.groundName || '',
                    dayOfWeek: slotData.dayOfWeek,
                    startTime: slotData.startTime,
                    sport: slotData.sport
                },
                { ...slotData, turfId, groundName: slotData.groundName || '' },
                { upsert: true, new: true }
            );
        }));

        res.json(savedSlots);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

// @desc    Get slots for a turf
// @route   GET /api/owner/slots/:turfId
// @access  Private/Owner
const getTurfSlots = async (req, res) => {
    try {
        const slots = await Slot.find({ turfId: req.params.turfId });
        res.json(slots);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

// @desc    Create staff account
// @route   POST /api/owner/staff
// @access  Private/Owner
const createStaff = async (req, res) => {
    const { name, email, phone, password } = req.body;

    try {
        const userExists = await User.findOne({ $or: [{ email }, { phone }] });
        if (userExists) {
            return res.status(400).json({ message: 'User already exists' });
        }

        const bcrypt = require('bcryptjs');
        const hashedPassword = await bcrypt.hash(password, 10);

        const staff = await User.create({
            name,
            email,
            phone,
            password: hashedPassword,
            role: 'staff',
            ownerId: req.user._id // Link staff to owner
        });

        res.status(201).json({
            _id: staff._id,
            name: staff.name,
            email: staff.email,
            role: staff.role
        });
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

// @desc    Update a turf
// @route   PUT /api/owner/turf/:id
// @access  Private/Owner
const updateTurf = async (req, res) => {
    const { name, location, sports, amenities, images, upiId, taxPercentage, grounds, turfType } = req.body;
    console.log('Update Turf request:', { id: req.params.id, name, images, turfType });

    try {
        const turf = await Turf.findById(req.params.id);

        if (turf) {
            if (turf.ownerId.toString() !== req.user._id.toString()) {
                return res.status(401).json({ message: 'Not authorized' });
            }

            turf.name = name || turf.name;
            turf.location = location || turf.location;
            turf.sports = sports || turf.sports;
            turf.amenities = amenities || turf.amenities;
            turf.images = images || turf.images;
            turf.grounds = grounds || turf.grounds;
            turf.turfType = turfType || turf.turfType;
            turf.settings = {
                ...turf.settings,
                upiId: upiId !== undefined ? upiId : turf.settings.upiId,
                taxPercentage: taxPercentage !== undefined ? taxPercentage : turf.settings.taxPercentage
            };
            turf.status = 'pending'; // Reset to pending for re-approval

            const updatedTurf = await turf.save();
            console.log('Turf updated successfully:', updatedTurf._id);
            res.json(updatedTurf);
        } else {
            res.status(404).json({ message: 'Turf not found' });
        }
    } catch (error) {
        console.error('Error updating turf:', error.message);
        res.status(500).json({ message: error.message });
    }
};

// @desc    Get all bookings for an owner's turfs
// @route   GET /api/owner/bookings
// @access  Private/Owner
const getOwnerBookings = async (req, res) => {
    try {
        // Find all turfs owned by this user
        const turfs = await Turf.find({ ownerId: req.user._id });
        const turfIds = turfs.map(t => t._id);

        // Find bookings for these turfs
        const bookings = await Booking.find({ turfId: { $in: turfIds } })
            .populate('turfId', 'name location')
            .populate('userId', 'name')
            .populate('slotId', 'startTime endTime sport')
            .sort({ bookingDate: -1 });

        res.json(bookings);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

// @desc    Get owner's staff
// @route   GET /api/owner/staff
// @access  Private/Owner
const getOwnerStaff = async (req, res) => {
    try {
        const staff = await User.find({ ownerId: req.user._id, role: 'staff' })
            .select('-password')
            .populate('assignedTurfId', 'name');
        res.json(staff);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

// @desc    Assign turf to staff
// @route   PUT /api/owner/staff/:staffId/assign
// @access  Private/Owner
const assignTurfToStaff = async (req, res) => {
    const { turfId, groundName } = req.body;
    try {
        const staff = await User.findOne({ _id: req.params.staffId, ownerId: req.user._id });
        if (!staff) {
            return res.status(404).json({ message: 'Staff not found' });
        }

        staff.assignedTurfId = turfId;
        staff.assignedGround = groundName || '';
        await staff.save();
        res.json(staff);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

// @desc    Get owner stats with advanced analytics
// @route   GET /api/owner/stats
// @access  Private/Owner
const getOwnerStats = async (req, res) => {
    try {
        const turfs = await Turf.find({ ownerId: req.user._id });
        const turfIds = turfs.map(t => t._id);

        const totalBookings = await Booking.countDocuments({ turfId: { $in: turfIds } });

        const today = new Date();
        today.setHours(0, 0, 0, 0);

        const thirtyDaysAgo = new Date();
        thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);
        thirtyDaysAgo.setHours(0, 0, 0, 0);

        const allBookings = await Booking.find({
            turfId: { $in: turfIds },
            bookingStatus: { $in: ['completed', 'checked-in', 'confirmed'] }
        }).populate('slotId', 'startTime sport');

        // Total Revenue Calculation
        const totalRevenue = allBookings.reduce((acc, curr) => acc + curr.totalAmount, 0);

        // Today's Stats
        const todayBookings = allBookings.filter(b => new Date(b.bookingDate) >= today);
        const todayRevenue = todayBookings.reduce((acc, curr) => acc + curr.totalAmount, 0);

        // 1. Revenue by Month (Advanced Aggregation)
        const revenueByMonthAgg = await Booking.aggregate([
            {
                $match: {
                    turfId: { $in: turfIds },
                    bookingStatus: { $in: ['completed', 'checked-in', 'confirmed'] }
                }
            },
            {
                $group: {
                    _id: { $month: "$bookingDate" },
                    total: { $sum: "$totalAmount" }
                }
            },
            { $sort: { _id: 1 } }
        ]);

        const months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
        const revenueByMonth = months.map((month, index) => {
            const found = revenueByMonthAgg.find(item => item._id === index + 1);
            return { month, amount: found ? found.total : 0 };
        });

        // 2. Hour-wise revenue (0-23)
        const revenueByHour = Array(24).fill(0);
        allBookings.forEach(b => {
            if (b.slotId && b.slotId.startTime) {
                const hour = parseInt(b.slotId.startTime.split(':')[0]);
                revenueByHour[hour] += b.totalAmount;
            }
        });

        // 2.5 Occupancy Rate (Last 30 days)
        const totalSlotsQuery = await Slot.countDocuments({ turfId: { $in: turfIds } });
        const approximateMonthlySlots = totalSlotsQuery * 4.28;
        const last30DaysBookingsCount = allBookings.filter(b => new Date(b.bookingDate) >= thirtyDaysAgo).length;
        const occupancyRate = approximateMonthlySlots > 0 
            ? Math.round((last30DaysBookingsCount / approximateMonthlySlots) * 100) 
            : 0;

        // 3. Sport-wise revenue split
        const revenueBySport = {};
        allBookings.forEach(b => {
            if (b.slotId && b.slotId.sport) {
                revenueBySport[b.slotId.sport] = (revenueBySport[b.slotId.sport] || 0) + b.totalAmount;
            }
        });

        // 3. Day-wise revenue trend (Last 30 days)
        const revenueTrend = {};
        for (let i = 0; i < 30; i++) {
            const date = new Date();
            date.setDate(date.getDate() - i);
            const dateStr = date.toISOString().split('T')[0];
            revenueTrend[dateStr] = 0;
        }

        allBookings.forEach(b => {
            const dateStr = new Date(b.bookingDate).toISOString().split('T')[0];
            if (revenueTrend[dateStr] !== undefined) {
                revenueTrend[dateStr] += b.totalAmount;
            }
        });

        // 4. Peak vs Non-peak Utilization
        // Assume Peak: 17:00 - 22:00
        let peakBookings = 0;
        let nonPeakBookings = 0;
        allBookings.forEach(b => {
            if (b.slotId && b.slotId.startTime) {
                const hour = parseInt(b.slotId.startTime.split(':')[0]);
                if (hour >= 17 && hour <= 22) peakBookings++;
                else nonPeakBookings++;
            }
        });

        // 5. Performance Insights (Auto-generated)
        const topHour = revenueByHour.indexOf(Math.max(...revenueByHour));
        const insights = [
            `Your most profitable slot is ${topHour}:00 - ${topHour + 1}:00`,
            `Total revenue trend is ${totalRevenue > 0 ? 'stable' : 'pending bookings'}`,
        ];

        // 6. Payout History
        const payouts = await Payout.find({ ownerId: req.user._id }).sort({ createdAt: -1 }).limit(5);

        res.json({
            totalTurfs: turfs.length,
            totalBookings,
            todayBookings: todayBookings.length,
            totalRevenue,
            todayRevenue,
            payouts: payouts.map(p => ({
                date: p.createdAt.toLocaleDateString(),
                amount: p.amount,
                status: p.status
            })),
            advanced: {
                revenueByHour,
                revenueBySport,
                revenueByMonth,
                revenueTrend: Object.entries(revenueTrend).reverse().map(([date, amount]) => ({ date, amount })),
                utilization: {
                    peak: peakBookings,
                    nonPeak: nonPeakBookings,
                    occupancyRate
                },
                insights
            }
        });
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

// @desc    Update turf settings
// @route   PUT /api/owner/turf/:id/settings
// @access  Private/Owner
const updateTurfSettings = async (req, res) => {
    const { settings } = req.body;
    try {
        const turf = await Turf.findById(req.params.id);
        if (!turf || turf.ownerId.toString() !== req.user._id.toString()) {
            return res.status(401).json({ message: 'Not authorized' });
        }

        turf.settings = { ...turf.settings, ...settings };
        await turf.save();
        res.json(turf);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

// @desc    Request a payout
// @route   POST /api/owner/payout/request
// @access  Private/Owner
const requestPayout = async (req, res) => {
    const { amount, bankDetails } = req.body;
    
    if (!amount || amount <= 0) {
        return res.status(400).json({ message: 'Invalid payout amount' });
    }

    if (amount < 500) {
        return res.status(400).json({ message: 'Minimum payout amount is 500' });
    }

    try {
        const turfs = await Turf.find({ ownerId: req.user._id });
        const turfIds = turfs.map(t => t._id);

        const totalRevenueResult = await Booking.aggregate([
            { $match: { turfId: { $in: turfIds }, bookingStatus: { $in: ['completed', 'checked-in', 'confirmed'] } } },
            { $group: { _id: null, total: { $sum: '$totalAmount' } } }
        ]);
        const totalRevenue = totalRevenueResult[0]?.total || 0;

        const totalPaidResult = await Payout.aggregate([
            { $match: { ownerId: req.user._id, status: { $in: ['pending', 'processed'] } } },
            { $group: { _id: null, total: { $sum: '$amount' } } }
        ]);
        const totalPaid = totalPaidResult[0]?.total || 0;

        const availableBalance = totalRevenue - totalPaid;

        if (amount > availableBalance) {
            return res.status(400).json({ message: 'Insufficient balance for payout' });
        }

        const payout = await Payout.create({
            ownerId: req.user._id,
            amount,
            bankDetails
        });

        res.status(201).json(payout);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

// @desc    Get owner payout history
// @route   GET /api/owner/payouts
// @access  Private/Owner
const getOwnerPayouts = async (req, res) => {
    try {
        const payouts = await Payout.find({ ownerId: req.user._id }).sort({ requestedAt: -1 });
        res.json(payouts);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

// @desc    Get owner wallet data (balance)
// @route   GET /api/owner/wallet
// @access  Private/Owner
const getWalletData = async (req, res) => {
    try {
        const turfs = await Turf.find({ ownerId: req.user._id });
        const turfIds = turfs.map(t => t._id);

        const totalRevenueResult = await Booking.aggregate([
            { $match: { turfId: { $in: turfIds }, bookingStatus: { $in: ['completed', 'checked-in', 'confirmed'] } } },
            { $group: { _id: null, total: { $sum: '$totalAmount' } } }
        ]);
        const totalRevenue = totalRevenueResult[0]?.total || 0;

        const totalPaidResult = await Payout.aggregate([
            { $match: { ownerId: req.user._id, status: 'processed' } },
            { $group: { _id: null, total: { $sum: '$amount' } } }
        ]);
        const totalPaid = totalPaidResult[0]?.total || 0;

        const pendingPayoutResult = await Payout.aggregate([
            { $match: { ownerId: req.user._id, status: 'pending' } },
            { $group: { _id: null, total: { $sum: '$amount' } } }
        ]);
        const pendingPayouts = pendingPayoutResult[0]?.total || 0;

        const availableBalance = totalRevenue - totalPaid - pendingPayouts;

        res.json({
            totalRevenue,
            totalPaid,
            pendingPayouts,
            availableBalance
        });
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

// @desc    Toggle slot blocking
// @route   PUT /api/owner/slot/:slotId/block
// @access  Private/Owner
const toggleSlotBlock = async (req, res) => {
    try {
        const slot = await Slot.findById(req.params.slotId);
        if (!slot) {
            return res.status(404).json({ message: 'Slot not found' });
        }

        const turf = await Turf.findById(slot.turfId);
        if (!turf || turf.ownerId.toString() !== req.user._id.toString()) {
            return res.status(401).json({ message: 'Not authorized' });
        }

        slot.isBlocked = !slot.isBlocked;
        await slot.save();

        res.json({ message: `Slot ${slot.isBlocked ? 'blocked' : 'unblocked'} successfully`, slot });
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

// @desc    Create manual booking
// @route   POST /api/owner/manual-booking
// @access  Private/Owner
const createManualBooking = async (req, res) => {
    const { turfId, slotId, sport, totalAmount } = req.body;
    try {
        const turf = await Turf.findById(turfId);
        if (!turf || turf.ownerId.toString() !== req.user._id.toString()) {
            return res.status(401).json({ message: 'Not authorized' });
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

        // Standardize manual booking date to UTC midnight
        const now = new Date();
        const startOfUtcToday = new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), now.getUTCDate()));

        const booking = await Booking.create({
            userId: null,
            turfId,
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

// @desc    Get staff attendance for owner
// @route   GET /api/owner/staff/attendance
// @access  Private/Owner
const getStaffAttendance = async (req, res) => {
    try {
        const { staffId, turfId } = req.query;

        // Find all turfs owned by this user to verify authorization
        const turfs = await Turf.find({ ownerId: req.user._id });
        const turfIds = turfs.map(t => t._id.toString());

        let query = { turfId: { $in: turfIds } };

        if (staffId) {
            query.userId = staffId;
        }
        if (turfId) {
            if (!turfIds.includes(turfId)) {
                return res.status(401).json({ message: 'Not authorized for this turf' });
            }
            query.turfId = turfId;
        }

        const attendance = await Attendance.find(query)
            .populate('userId', 'name email phone')
            .populate('turfId', 'name')
            .sort({ clockIn: -1 });

        res.json(attendance);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

// @desc    Create an announcement
// @route   POST /api/owner/announcement
// @access  Private/Owner
const createAnnouncement = async (req, res) => {
    const { turfId, title, message, type, isPublic } = req.body;
    try {
        const turf = await Turf.findById(turfId);
        if (!turf || turf.ownerId.toString() !== req.user._id.toString()) {
            return res.status(401).json({ message: 'Not authorized for this turf' });
        }

        const announcement = await Announcement.create({
            turfId,
            title,
            message,
            type: type || 'General',
            isPublic: isPublic || false
        });

        // Real-time Event
        if (isPublic) {
            emitGlobal('newAnnouncement', { title, message, type });
        } else {
            emitToTurf(turfId, 'newAnnouncement', { title, message, type });
        }

        // Notify Staff assigned to this turf
        const assignedStaff = await User.find({ assignedTurfId: turfId, role: 'staff' });
        for (const staff of assignedStaff) {
            await sendToUser(staff, {
                title: `New Announcement: ${title}`,
                body: message,
                data: { turfId: turfId.toString(), type: 'announcement', announcementId: announcement._id.toString() }
            });
        }

        res.status(201).json(announcement);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

// @desc    Get all announcements for owner's turfs
// @route   GET /api/owner/announcements
// @access  Private/Owner
const getOwnerAnnouncements = async (req, res) => {
    try {
        const turfs = await Turf.find({ ownerId: req.user._id });
        const turfIds = turfs.map(t => t._id);

        const announcements = await Announcement.find({
            turfId: { $in: turfIds }
        })
            .populate('turfId', 'name')
            .sort({ createdAt: -1 });

        res.json(announcements);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

// @desc    Delete an announcement
// @route   DELETE /api/owner/announcement/:id
// @access  Private/Owner
const deleteAnnouncement = async (req, res) => {
    try {
        const announcement = await Announcement.findById(req.params.id);
        if (!announcement) {
            return res.status(404).json({ message: 'Announcement not found' });
        }

        const turf = await Turf.findById(announcement.turfId);
        if (!turf || turf.ownerId.toString() !== req.user._id.toString()) {
            return res.status(401).json({ message: 'Not authorized' });
        }

        await announcement.deleteOne();
        res.json({ message: 'Announcement deleted successfully' });
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

module.exports = {
    getMyTurfs,
    createTurf,
    manageSlots,
    getTurfSlots,
    createStaff,
    getOwnerStaff,
    assignTurfToStaff,
    updateTurf,
    getOwnerBookings,
    getOwnerStats,
    getStaffAttendance,
    updateTurfSettings,
    requestPayout,
    getOwnerPayouts,
    getWalletData,
    toggleSlotBlock,
    createManualBooking,
    createAnnouncement,
    getOwnerAnnouncements,
    deleteAnnouncement
};
