const { prisma } = require('../config/db');
const AttendanceMongo = require('../models/Attendance');
const MaintenanceMongo = require('../models/Maintenance');
const IncidentMongo = require('../models/Incident');
const BookingMongo = require('../models/Booking');
const AnnouncementMongo = require('../models/Announcement');
const {
    serializeAttendance,
    serializeMaintenance,
    serializeIncident,
    serializeBooking,
    serializeAnnouncement
} = require('../utils/serializer');

const isPostgres = () => process.env.DB_PROVIDER === 'postgres';

const findActiveAttendance = async (userId) => {
    if (isPostgres()) {
        const att = await prisma.attendance.findFirst({
            where: {
                userId: String(userId),
                clockOut: null
            },
            orderBy: { clockIn: 'desc' }
        });
        return att ? serializeAttendance(att) : null;
    }

    return await AttendanceMongo.findOne({
        userId,
        clockOut: null
    }).sort({ clockIn: -1 });
};

const getTodayShiftCount = async (userId) => {
    const today = new Date();
    today.setHours(0, 0, 0, 0);

    if (isPostgres()) {
        return await prisma.attendance.count({
            where: {
                userId: String(userId),
                clockIn: { gte: today }
            }
        });
    }

    return await AttendanceMongo.countDocuments({
        userId,
        clockIn: { $gte: today }
    });
};

const clockIn = async ({ userId, turfId, groundName }) => {
    if (isPostgres()) {
        const attendance = await prisma.attendance.create({
            data: {
                userId: String(userId),
                turfId: String(turfId),
                groundName: groundName || '',
                clockIn: new Date(),
                status: 'Present'
            }
        });
        return serializeAttendance(attendance);
    }

    return await AttendanceMongo.create({
        userId,
        turfId,
        groundName,
        clockIn: new Date(),
        status: 'Present'
    });
};

const clockOut = async (attendanceId) => {
    if (isPostgres()) {
        const att = await prisma.attendance.findUnique({ where: { id: String(attendanceId) } });
        if (!att) return null;

        const clockOutTime = new Date();
        const diffMs = clockOutTime.getTime() - new Date(att.clockIn).getTime();
        const workHours = Math.round((diffMs / (1000 * 60 * 60)) * 100) / 100;

        const updated = await prisma.attendance.update({
            where: { id: String(attendanceId) },
            data: {
                clockOut: clockOutTime,
                workHours
            }
        });
        return serializeAttendance(updated);
    }

    const att = await AttendanceMongo.findById(attendanceId);
    if (!att) return null;
    att.clockOut = new Date();
    const diffMs = att.clockOut.getTime() - att.clockIn.getTime();
    att.workHours = Math.round((diffMs / (1000 * 60 * 60)) * 100) / 100;
    return await att.save();
};

const findAttendanceHistory = async (userId) => {
    if (isPostgres()) {
        const history = await prisma.attendance.findMany({
            where: { userId: String(userId) },
            include: { turf: { select: { id: true, name: true } } },
            orderBy: { clockIn: 'desc' },
            take: 10
        });
        return history.map(serializeAttendance);
    }

    return await AttendanceMongo.find({ userId })
        .populate('turfId', 'name')
        .sort({ clockIn: -1 })
        .limit(10);
};

const findAssignedBookings = async (turfId) => {
    if (isPostgres()) {
        const bookings = await prisma.booking.findMany({
            where: {
                turfId: String(turfId),
                bookingStatus: { not: 'cancelled' }
            },
            include: {
                user: { select: { id: true, name: true, phone: true, email: true } },
                slot: true,
                turf: true
            },
            orderBy: { bookingDate: 'asc' }
        });
        return bookings.map(serializeBooking);
    }

    return await BookingMongo.find({
        turfId,
        bookingStatus: { $ne: 'cancelled' }
    })
        .populate('userId', 'name phone')
        .populate('slotId')
        .sort({ bookingDate: 1 });
};

const getStaffStats = async (turfId) => {
    if (isPostgres()) {
        const handledBookings = await prisma.booking.count({
            where: {
                turfId: String(turfId),
                bookingStatus: { in: ['checked_in', 'completed'] }
            }
        });

        const resolvedIssues = await prisma.maintenance.count({
            where: {
                turfId: String(turfId),
                status: 'Resolved'
            }
        });

        return {
            handledBookings,
            resolvedIssues,
            feedbackScore: 4.8
        };
    }

    const handledBookings = await BookingMongo.countDocuments({
        turfId,
        bookingStatus: { $in: ['checked-in', 'completed'] }
    });

    const resolvedIssues = await MaintenanceMongo.countDocuments({
        turfId,
        status: 'Resolved'
    });

    return {
        handledBookings,
        resolvedIssues,
        feedbackScore: 4.8
    };
};

const findAnnouncementsByTurf = async (turfId) => {
    if (isPostgres()) {
        const announcements = await prisma.announcement.findMany({
            where: { turfId: String(turfId) },
            orderBy: { createdAt: 'desc' }
        });
        return announcements.map(serializeAnnouncement);
    }

    return await AnnouncementMongo.find({
        turfId
    }).sort({ createdAt: -1 });
};

const reportMaintenance = async (data) => {
    if (isPostgres()) {
        const maint = await prisma.maintenance.create({
            data: {
                turfId: String(data.turfId),
                reporterId: String(data.reporterId),
                category: data.category,
                description: data.description,
                images: data.images || [],
                status: 'Pending'
            }
        });
        return serializeMaintenance(maint);
    }

    return await MaintenanceMongo.create(data);
};

const reportIncident = async (data) => {
    if (isPostgres()) {
        const inc = await prisma.incident.create({
            data: {
                turfId: String(data.turfId),
                reporterId: String(data.reporterId),
                type: data.type === 'Crowd Issue' ? 'Crowd_Issue' : data.type,
                severity: data.severity || 'Low',
                description: data.description,
                images: data.images || [],
                status: 'Reported'
            }
        });
        return serializeIncident(inc);
    }

    return await IncidentMongo.create(data);
};

module.exports = {
    findActiveAttendance,
    findAttendanceHistory,
    getTodayShiftCount,
    clockIn,
    clockOut,
    findAssignedBookings,
    getStaffStats,
    findAnnouncementsByTurf,
    reportMaintenance,
    reportIncident,
    isPostgres
};
