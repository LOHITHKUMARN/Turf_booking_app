const { prisma } = require('../config/db');
const AttendanceMongo = require('../models/Attendance');
const MaintenanceMongo = require('../models/Maintenance');
const IncidentMongo = require('../models/Incident');
const { serializeAttendance, serializeMaintenance, serializeIncident } = require('../utils/serializer');

const isPostgres = () => process.env.DB_PROVIDER === 'postgres';

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
    clockIn,
    clockOut,
    reportMaintenance,
    reportIncident,
    isPostgres
};
