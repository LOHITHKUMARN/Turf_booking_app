const { prisma } = require('../config/db');
const PayoutMongo = require('../models/Payout');
const AdminAuditLogMongo = require('../models/AdminAuditLog');
const { serializePayout, serializeAuditLog } = require('../utils/serializer');

const isPostgres = () => process.env.DB_PROVIDER === 'postgres';

const findPayouts = async (query = {}) => {
    if (isPostgres()) {
        const where = {};
        if (query.ownerId) where.ownerId = String(query.ownerId);
        if (query.status) where.status = query.status;

        const payouts = await prisma.payout.findMany({
            where,
            include: { owner: true },
            orderBy: { requestedAt: 'desc' }
        });
        return payouts.map(serializePayout);
    }

    return await PayoutMongo.find(query).populate('ownerId', 'name email phone').sort({ requestedAt: -1 });
};

const createPayoutRequest = async ({ ownerId, amount, bankDetails }) => {
    if (isPostgres()) {
        const payout = await prisma.payout.create({
            data: {
                ownerId: String(ownerId),
                amount: Number(amount),
                status: 'pending',
                bankDetails: bankDetails || {}
            }
        });
        return serializePayout(payout);
    }

    return await PayoutMongo.create({ ownerId, amount, bankDetails });
};

const updatePayoutStatus = async (id, status, statementUrl) => {
    if (isPostgres()) {
        const data = {
            status,
            processedAt: status === 'processed' ? new Date() : undefined
        };
        if (statementUrl) data.statementUrl = statementUrl;

        const updated = await prisma.payout.update({
            where: { id: String(id) },
            data
        });
        return serializePayout(updated);
    }

    return await PayoutMongo.findByIdAndUpdate(
        id,
        {
            status,
            statementUrl,
            processedAt: status === 'processed' ? new Date() : undefined
        },
        { new: true }
    );
};

const logAdminAction = async ({ adminId, action, targetId, targetType, details, ipAddress }) => {
    if (isPostgres()) {
        const log = await prisma.adminAuditLog.create({
            data: {
                adminId: String(adminId),
                action,
                targetId: String(targetId),
                targetType,
                details: details || {},
                ipAddress: ipAddress || ''
            }
        });
        return serializeAuditLog(log);
    }

    return await AdminAuditLogMongo.create({
        adminId,
        action,
        targetId,
        targetType,
        details,
        ipAddress
    });
};

const findAuditLogs = async (limit = 100) => {
    if (isPostgres()) {
        const logs = await prisma.adminAuditLog.findMany({
            take: limit,
            include: { admin: { select: { id: true, name: true, email: true } } },
            orderBy: { createdAt: 'desc' }
        });
        return logs.map(serializeAuditLog);
    }

    return await AdminAuditLogMongo.find()
        .populate('adminId', 'name email')
        .sort({ createdAt: -1 })
        .limit(limit);
};

module.exports = {
    findPayouts,
    createPayoutRequest,
    updatePayoutStatus,
    logAdminAction,
    findAuditLogs,
    isPostgres
};
