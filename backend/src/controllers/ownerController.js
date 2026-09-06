const userRepository = require('../repositories/userRepository');
const turfRepository = require('../repositories/turfRepository');
const slotRepository = require('../repositories/slotRepository');
const bookingRepository = require('../repositories/bookingRepository');
const adminRepository = require('../repositories/adminRepository');
const { emitToTurf, emitGlobal } = require('../services/socket');
const { sendToUser } = require('../services/notificationService');
const { prisma } = require('../config/db');
const { serializeTurf, serializeSlot, serializeBooking, serializeUser, serializePayout, serializeAttendance, serializeAnnouncement, serializeMaintenance, serializeIncident } = require('../utils/serializer');
const bcrypt = require('bcryptjs');

const { deleteCache } = require('../services/redis');

const isPostgres = () => process.env.DB_PROVIDER === 'postgres';

// @desc    Get owner's turfs
// @route   GET /api/owner/turfs
// @access  Private/Owner
const getMyTurfs = async (req, res) => {
    try {
        const ownerId = req.user._id || req.user.id;
        const turfs = await turfRepository.findTurfsByOwner(ownerId);
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
    try {
        const ownerId = req.user._id || req.user.id;
        const turf = await turfRepository.createTurf({
            ownerId,
            name,
            location,
            sports,
            amenities,
            images,
            grounds,
            turfType,
            settings: { upiId, taxPercentage }
        });
        res.status(201).json(turf);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

// @desc    Create/Update slots for a turf
// @route   POST /api/owner/slots
// @access  Private/Owner
const manageSlots = async (req, res) => {
    const { turfId, slots } = req.body;
    try {
        const turf = await turfRepository.findTurfById(turfId);
        const ownerId = String(turf?.ownerId?._id || turf?.ownerId?.id || turf?.ownerId);
        const reqOwnerId = String(req.user._id || req.user.id);

        if (!turf || ownerId !== reqOwnerId) {
            return res.status(401).json({ message: 'Not authorized' });
        }

        const savedSlots = [];
        for (const slotData of slots) {
            const saved = await slotRepository.upsertSlot(turfId, slotData);
            savedSlots.push(saved);
        }

        await deleteCache(`slots:${turfId}:*`);
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
        const slots = await slotRepository.findSlots({ turfId: req.params.turfId });
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
        const existing = await userRepository.findByEmailOrPhone(email) || await userRepository.findByEmailOrPhone(phone);
        if (existing) {
            return res.status(400).json({ message: 'User already exists' });
        }

        const ownerId = req.user._id || req.user.id;
        const staff = await userRepository.createUser({
            name,
            email,
            phone,
            password,
            role: 'staff',
            ownerId
        });

        res.status(201).json({
            _id: staff._id || staff.id,
            name: staff.name,
            email: staff.email,
            role: staff.role
        });
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

// @desc    Get owner's staff
// @route   GET /api/owner/staff
// @access  Private/Owner
const getOwnerStaff = async (req, res) => {
    try {
        const ownerId = req.user._id || req.user.id;
        if (isPostgres()) {
            const staffList = await prisma.user.findMany({
                where: { ownerId: String(ownerId), role: 'staff' },
                include: { assignedTurf: { select: { id: true, name: true } } }
            });
            return res.json(staffList.map(serializeUser));
        }

        const UserMongo = require('../models/User');
        const staff = await UserMongo.find({ ownerId, role: 'staff' })
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
        const ownerId = req.user._id || req.user.id;
        if (isPostgres()) {
            const staff = await prisma.user.findFirst({
                where: { id: String(req.params.staffId), ownerId: String(ownerId) }
            });
            if (!staff) return res.status(404).json({ message: 'Staff not found' });

            const updated = await prisma.user.update({
                where: { id: staff.id },
                data: {
                    assignedTurfId: turfId || null,
                    assignedGround: groundName || ''
                }
            });
            return res.json(serializeUser(updated));
        }

        const UserMongo = require('../models/User');
        const staff = await UserMongo.findOne({ _id: req.params.staffId, ownerId });
        if (!staff) return res.status(404).json({ message: 'Staff not found' });

        staff.assignedTurfId = turfId;
        staff.assignedGround = groundName || '';
        await staff.save();
        res.json(staff);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

// @desc    Update a turf
// @route   PUT /api/owner/turf/:id
// @access  Private/Owner
const updateTurf = async (req, res) => {
    try {
        const turf = await turfRepository.findTurfById(req.params.id);
        const ownerId = String(turf?.ownerId?._id || turf?.ownerId?.id || turf?.ownerId);
        const reqOwnerId = String(req.user._id || req.user.id);

        if (!turf || ownerId !== reqOwnerId) {
            return res.status(401).json({ message: 'Not authorized' });
        }

        const updated = await turfRepository.updateTurf(req.params.id, {
            ...req.body,
            status: 'pending'
        });
        res.json(updated);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

// @desc    Get all bookings for an owner's turfs
// @route   GET /api/owner/bookings
// @access  Private/Owner
const getOwnerBookings = async (req, res) => {
    try {
        const ownerId = req.user._id || req.user.id;
        if (isPostgres()) {
            const turfs = await prisma.turf.findMany({
                where: { ownerId: String(ownerId) },
                select: { id: true }
            });
            const turfIds = turfs.map(t => t.id);

            const bookings = await prisma.booking.findMany({
                where: { turfId: { in: turfIds } },
                include: {
                    turf: true,
                    user: { select: { id: true, name: true, phone: true } },
                    slot: true
                },
                orderBy: { bookingDate: 'desc' }
            });
            return res.json(bookings.map(serializeBooking));
        }

        const TurfMongo = require('../models/Turf');
        const BookingMongo = require('../models/Booking');
        const turfs = await TurfMongo.find({ ownerId });
        const turfIds = turfs.map(t => t._id);

        const bookings = await BookingMongo.find({ turfId: { $in: turfIds } })
            .populate('turfId', 'name location')
            .populate('userId', 'name')
            .populate('slotId', 'startTime endTime sport')
            .sort({ bookingDate: -1 });

        res.json(bookings);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

// @desc    Get owner stats with advanced analytics
// @route   GET /api/owner/stats
// @access  Private/Owner
const getOwnerStats = async (req, res) => {
    try {
        const ownerId = req.user._id || req.user.id;
        if (isPostgres()) {
            const turfs = await prisma.turf.findMany({
                where: { ownerId: String(ownerId) },
                select: { id: true }
            });
            const turfIds = turfs.map(t => t.id);

            const totalBookings = await prisma.booking.count({ where: { turfId: { in: turfIds } } });
            const bookings = await prisma.booking.findMany({
                where: { turfId: { in: turfIds }, bookingStatus: { not: 'cancelled' } },
                select: { totalAmount: true }
            });
            const totalRevenue = bookings.reduce((sum, b) => sum + Number(b.totalAmount || 0), 0);

            return res.json({
                totalTurfs: turfs.length,
                totalBookings,
                totalRevenue,
                occupancyRate: '75%',
                recentTrend: []
            });
        }

        const TurfMongo = require('../models/Turf');
        const BookingMongo = require('../models/Booking');
        const turfs = await TurfMongo.find({ ownerId });
        const turfIds = turfs.map(t => t._id);

        const totalBookings = await BookingMongo.countDocuments({ turfId: { $in: turfIds } });
        res.json({
            totalTurfs: turfs.length,
            totalBookings,
            totalRevenue: 0,
            occupancyRate: '75%',
            recentTrend: []
        });
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

// @desc    Get staff attendance records
// @route   GET /api/owner/staff/attendance
// @access  Private/Owner
const getStaffAttendance = async (req, res) => {
    try {
        const ownerId = req.user._id || req.user.id;
        const { staffId, userId, turfId } = req.query;
        const targetStaffId = staffId || userId;

        if (isPostgres()) {
            const turfs = await prisma.turf.findMany({ where: { ownerId: String(ownerId) }, select: { id: true } });
            const turfIds = turfs.map(t => t.id);

            const whereClause = {
                turfId: turfId ? String(turfId) : { in: turfIds }
            };

            if (targetStaffId) {
                whereClause.userId = String(targetStaffId);
            }

            const attendance = await prisma.attendance.findMany({
                where: whereClause,
                include: { user: { select: { id: true, name: true, phone: true } }, turf: true },
                orderBy: { clockIn: 'desc' }
            });
            return res.json(attendance.map(serializeAttendance));
        }

        const AttendanceMongo = require('../models/Attendance');
        const TurfMongo = require('../models/Turf');
        const turfs = await TurfMongo.find({ ownerId });
        const turfIds = turfs.map(t => t._id);

        const query = {
            turfId: turfId || { $in: turfIds }
        };

        if (targetStaffId) {
            query.userId = targetStaffId;
        }

        const records = await AttendanceMongo.find(query)
            .populate('userId', 'name phone')
            .populate('turfId', 'name')
            .sort({ clockIn: -1 });

        res.json(records);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

// @desc    Update turf operating settings
// @route   PUT /api/owner/turf/:id/settings
// @access  Private/Owner
const updateTurfSettings = async (req, res) => {
    try {
        const turf = await turfRepository.findTurfById(req.params.id);
        const ownerId = String(turf?.ownerId?._id || turf?.ownerId?.id || turf?.ownerId);
        const reqOwnerId = String(req.user._id || req.user.id);

        if (!turf || ownerId !== reqOwnerId) {
            return res.status(401).json({ message: 'Not authorized' });
        }

        const settingsData = req.body?.settings || req.body;
        const updated = await turfRepository.updateTurf(req.params.id, {
            settings: settingsData
        });
        res.json(updated);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

// @desc    Request a payout
// @route   POST /api/owner/payout
// @access  Private/Owner
const requestPayout = async (req, res) => {
    const { amount, bankDetails } = req.body;
    try {
        const ownerId = req.user._id || req.user.id;
        const payout = await adminRepository.createPayoutRequest({
            ownerId,
            amount,
            bankDetails
        });
        res.status(201).json(payout);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

// @desc    Get owner's payout requests
// @route   GET /api/owner/payouts
// @access  Private/Owner
const getOwnerPayouts = async (req, res) => {
    try {
        const ownerId = req.user._id || req.user.id;
        const payouts = await adminRepository.findPayouts({ ownerId });
        res.json(payouts);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

// @desc    Get wallet overview
// @route   GET /api/owner/wallet
// @access  Private/Owner
const getWalletData = async (req, res) => {
    try {
        const ownerId = req.user._id || req.user.id;
        if (isPostgres()) {
            const turfs = await prisma.turf.findMany({ where: { ownerId: String(ownerId) }, select: { id: true } });
            const turfIds = turfs.map(t => t.id);

            const bookings = await prisma.booking.findMany({
                where: { turfId: { in: turfIds }, bookingStatus: { not: 'cancelled' } },
                select: { totalAmount: true }
            });
            const totalRevenue = bookings.reduce((sum, b) => sum + Number(b.totalAmount || 0), 0);

            const payouts = await prisma.payout.findMany({ where: { ownerId: String(ownerId) } });
            const totalPaid = payouts.filter(p => p.status === 'processed').reduce((sum, p) => sum + Number(p.amount || 0), 0);
            const pendingPayout = payouts.filter(p => p.status === 'pending').reduce((sum, p) => sum + Number(p.amount || 0), 0);
            const currentBalance = Math.max(0, totalRevenue - totalPaid - pendingPayout);

            return res.json({
                currentBalance,
                totalRevenue,
                totalPaid,
                pendingPayout,
                payouts: payouts.map(serializePayout)
            });
        }

        res.json({
            currentBalance: 0,
            totalRevenue: 0,
            totalPaid: 0,
            pendingPayout: 0,
            payouts: []
        });
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

// @desc    Block or unblock a slot
// @route   PUT /api/owner/slots/:slotId/toggle-block
// @access  Private/Owner
const toggleSlotBlock = async (req, res) => {
    try {
        const slot = await slotRepository.findSlotById(req.params.slotId);
        if (!slot) return res.status(404).json({ message: 'Slot not found' });

        if (isPostgres()) {
            const updated = await prisma.slot.update({
                where: { id: String(req.params.slotId) },
                data: { isBlocked: !slot.isBlocked }
            });
            return res.json(serializeSlot(updated));
        }

        const SlotMongo = require('../models/Slot');
        const s = await SlotMongo.findById(req.params.slotId);
        s.isBlocked = !s.isBlocked;
        await s.save();
        res.json(s);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

// @desc    Create a manual booking
// @route   POST /api/owner/manual-booking
// @access  Private/Owner
const createManualBooking = async (req, res) => {
    const { turfId, slotId, bookingDate, customerName, customerPhone, totalAmount, paymentMethod } = req.body;
    try {
        const [year, month, day] = bookingDate.split('-').map(Number);
        const utcDate = new Date(Date.UTC(year, month - 1, day));

        const booking = await bookingRepository.createBookingAtomic({
            turfId,
            slotId,
            bookingDate: utcDate,
            totalAmount: Number(totalAmount || 0),
            paymentMethod: paymentMethod || 'cash',
            paymentStatus: 'paid',
            bookingStatus: 'confirmed',
            staffNotes: `Manual booking by Owner. Customer: ${customerName} (${customerPhone})`
        });

        res.status(201).json(booking);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

// @desc    Create an announcement
// @route   POST /api/owner/announcement
// @access  Private/Owner
const createAnnouncement = async (req, res) => {
    const { turfId, title, message } = req.body;
    try {
        if (isPostgres()) {
            const ann = await prisma.announcement.create({
                data: {
                    turfId: String(turfId),
                    title,
                    message
                }
            });
            emitToTurf(turfId, 'newAnnouncement', { title, message, turfId });
            return res.status(201).json(serializeAnnouncement(ann));
        }

        const AnnouncementMongo = require('../models/Announcement');
        const announcement = await AnnouncementMongo.create({ turfId, title, message });
        emitToTurf(turfId, 'newAnnouncement', { title, message, turfId });
        res.status(201).json(announcement);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

// @desc    Get announcements for owner's turfs
// @route   GET /api/owner/announcements
// @access  Private/Owner
const getOwnerAnnouncements = async (req, res) => {
    try {
        const ownerId = req.user._id || req.user.id;
        if (isPostgres()) {
            const turfs = await prisma.turf.findMany({ where: { ownerId: String(ownerId) }, select: { id: true } });
            const turfIds = turfs.map(t => t.id);

            const announcements = await prisma.announcement.findMany({
                where: { turfId: { in: turfIds } },
                include: { turf: true },
                orderBy: { createdAt: 'desc' }
            });
            return res.json(announcements.map(serializeAnnouncement));
        }

        const AnnouncementMongo = require('../models/Announcement');
        const TurfMongo = require('../models/Turf');
        const turfs = await TurfMongo.find({ ownerId });
        const turfIds = turfs.map(t => t._id);

        const announcements = await AnnouncementMongo.find({ turfId: { $in: turfIds } })
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
        if (isPostgres()) {
            await prisma.announcement.delete({ where: { id: String(req.params.id) } });
            return res.json({ message: 'Announcement deleted successfully' });
        }

        const AnnouncementMongo = require('../models/Announcement');
        await AnnouncementMongo.findByIdAndDelete(req.params.id);
        res.json({ message: 'Announcement deleted successfully' });
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

// @desc    Get all staff reports (Maintenance & Incidents) for owner's turfs
// @route   GET /api/owner/reports
// @access  Private/Owner
const getOwnerReports = async (req, res) => {
    try {
        const ownerId = req.user._id || req.user.id;

        if (isPostgres()) {
            const turfs = await prisma.turf.findMany({
                where: { ownerId: String(ownerId) },
                select: { id: true, name: true }
            });
            const turfIds = turfs.map(t => t.id);

            const [maintenances, incidents] = await Promise.all([
                prisma.maintenance.findMany({
                    where: { turfId: { in: turfIds } },
                    include: {
                        turf: { select: { id: true, name: true } },
                        reporter: { select: { id: true, name: true, email: true, phone: true } }
                    },
                    orderBy: { createdAt: 'desc' }
                }),
                prisma.incident.findMany({
                    where: { turfId: { in: turfIds } },
                    include: {
                        turf: { select: { id: true, name: true } },
                        reporter: { select: { id: true, name: true, email: true, phone: true } }
                    },
                    orderBy: { createdAt: 'desc' }
                })
            ]);

            return res.json({
                maintenances: maintenances.map(serializeMaintenance),
                incidents: incidents.map(serializeIncident)
            });
        }

        const TurfMongo = require('../models/Turf');
        const MaintenanceMongo = require('../models/Maintenance');
        const IncidentMongo = require('../models/Incident');

        const turfs = await TurfMongo.find({ ownerId });
        const turfIds = turfs.map(t => t._id);

        const [maintenances, incidents] = await Promise.all([
            MaintenanceMongo.find({ turfId: { $in: turfIds } })
                .populate('turfId', 'name')
                .populate('reporterId', 'name email phone')
                .sort({ createdAt: -1 }),
            IncidentMongo.find({ turfId: { $in: turfIds } })
                .populate('turfId', 'name')
                .populate('reporterId', 'name email phone')
                .sort({ createdAt: -1 })
        ]);

        res.json({
            maintenances,
            incidents
        });
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

// @desc    Update maintenance report status
// @route   PUT /api/owner/maintenance/:id/status
// @access  Private/Owner
const updateMaintenanceStatus = async (req, res) => {
    try {
        const { id } = req.params;
        const { status } = req.body;

        if (!status) {
            return res.status(400).json({ message: 'Status is required' });
        }

        if (isPostgres()) {
            const prismaStatus = status === 'In Progress' ? 'In_Progress' : status;
            const updated = await prisma.maintenance.update({
                where: { id: String(id) },
                data: { status: prismaStatus },
                include: {
                    turf: { select: { id: true, name: true } },
                    reporter: { select: { id: true, name: true, email: true, phone: true } }
                }
            });

            const serialized = serializeMaintenance(updated);
            const turfIdStr = String(updated.turfId);
            emitToTurf(turfIdStr, 'maintenanceUpdated', serialized);

            return res.json({
                message: 'Maintenance status updated successfully',
                maintenance: serialized
            });
        }

        const MaintenanceMongo = require('../models/Maintenance');
        const mongoStatus = status === 'In_Progress' ? 'In Progress' : status;
        const updated = await MaintenanceMongo.findByIdAndUpdate(
            id,
            { status: mongoStatus },
            { new: true }
        )
            .populate('turfId', 'name')
            .populate('reporterId', 'name email phone');

        if (!updated) {
            return res.status(404).json({ message: 'Maintenance report not found' });
        }

        const turfIdStr = String(updated.turfId?._id || updated.turfId?.id || updated.turfId);
        emitToTurf(turfIdStr, 'maintenanceUpdated', updated);

        res.json({
            message: 'Maintenance status updated successfully',
            maintenance: updated
        });
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

// @desc    Update safety incident report status
// @route   PUT /api/owner/incident/:id/status
// @access  Private/Owner
const updateIncidentStatus = async (req, res) => {
    try {
        const { id } = req.params;
        const { status } = req.body;

        if (!status) {
            return res.status(400).json({ message: 'Status is required' });
        }

        if (isPostgres()) {
            const prismaStatus = status === 'Under Investigation' ? 'Under_Investigation' : status;
            const updated = await prisma.incident.update({
                where: { id: String(id) },
                data: { status: prismaStatus },
                include: {
                    turf: { select: { id: true, name: true } },
                    reporter: { select: { id: true, name: true, email: true, phone: true } }
                }
            });

            const serialized = serializeIncident(updated);
            const turfIdStr = String(updated.turfId);
            emitToTurf(turfIdStr, 'incidentUpdated', serialized);

            return res.json({
                message: 'Incident status updated successfully',
                incident: serialized
            });
        }

        const IncidentMongo = require('../models/Incident');
        const mongoStatus = status === 'Under_Investigation' ? 'Under Investigation' : status;
        const updated = await IncidentMongo.findByIdAndUpdate(
            id,
            { status: mongoStatus },
            { new: true }
        )
            .populate('turfId', 'name')
            .populate('reporterId', 'name email phone');

        if (!updated) {
            return res.status(404).json({ message: 'Incident report not found' });
        }

        const turfIdStr = String(updated.turfId?._id || updated.turfId?.id || updated.turfId);
        emitToTurf(turfIdStr, 'incidentUpdated', updated);

        res.json({
            message: 'Incident status updated successfully',
            incident: updated
        });
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
    deleteAnnouncement,
    getOwnerReports,
    updateMaintenanceStatus,
    updateIncidentStatus
};
