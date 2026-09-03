const { prisma } = require('../config/db');
const TurfMongo = require('../models/Turf');
const { serializeTurf } = require('../utils/serializer');

const isPostgres = () => process.env.DB_PROVIDER === 'postgres';

const findApprovedTurfs = async (filters = {}) => {
    if (isPostgres()) {
        const where = {
            status: { not: 'blocked' }
        };
        if (filters.city) {
            where.city = { equals: filters.city, mode: 'insensitive' };
        }
        if (filters.sport) {
            where.sports = { has: filters.sport };
        }

        const turfs = await prisma.turf.findMany({
            where,
            include: {
                owner: {
                    select: { id: true, name: true, email: true, phone: true }
                }
            },
            orderBy: { createdAt: 'desc' }
        });

        return turfs.map(serializeTurf);
    }

    const query = { status: { $ne: 'blocked' } };
    if (filters.city) query['location.city'] = new RegExp(filters.city, 'i');
    if (filters.sport) query.sports = filters.sport;

    return await TurfMongo.find(query);
};

const findTurfById = async (id) => {
    if (!id) return null;
    if (isPostgres()) {
        const turf = await prisma.turf.findUnique({
            where: { id: String(id) },
            include: {
                owner: {
                    select: { id: true, name: true, email: true, phone: true }
                }
            }
        });
        return turf ? serializeTurf(turf) : null;
    }

    return await TurfMongo.findById(id).populate('ownerId', 'name email phone');
};

const findTurfsByOwner = async (ownerId) => {
    if (isPostgres()) {
        const turfs = await prisma.turf.findMany({
            where: { ownerId: String(ownerId) },
            orderBy: { createdAt: 'desc' }
        });
        return turfs.map(serializeTurf);
    }

    return await TurfMongo.find({ ownerId });
};

const createTurf = async (data) => {
    if (isPostgres()) {
        const turf = await prisma.turf.create({
            data: {
                ownerId: String(data.ownerId),
                name: data.name,
                turfType: data.turfType || 'both',
                city: data.location?.city || data.city || 'N/A',
                area: data.location?.area || data.area || 'N/A',
                grounds: data.grounds || [],
                sports: data.sports || [],
                amenities: data.amenities || [],
                images: data.images || [],
                status: 'pending',
                operationalStatus: 'normal',
                upiId: data.upiId || data.settings?.upiId || '',
                taxPercentage: Number(data.taxPercentage ?? data.settings?.taxPercentage ?? 0),
                minBookingDuration: Number(data.settings?.minBookingDuration ?? 1),
                advanceBookingLimit: Number(data.settings?.advanceBookingLimit ?? 7),
                bookingCutoffTime: Number(data.settings?.bookingCutoffTime ?? 2),
                gracePeriod: Number(data.settings?.gracePeriod ?? 15),
                maxMembers: Number(data.settings?.maxMembers ?? 10)
            }
        });
        return serializeTurf(turf);
    }

    return await TurfMongo.create(data);
};

const updateTurf = async (id, data) => {
    if (isPostgres()) {
        const updatePayload = {};
        if (data.name) updatePayload.name = data.name;
        if (data.turfType) updatePayload.turfType = data.turfType;
        if (data.location?.city || data.city) updatePayload.city = data.location?.city || data.city;
        if (data.location?.area || data.area) updatePayload.area = data.location?.area || data.area;
        if (data.grounds) updatePayload.grounds = data.grounds;
        if (data.sports) updatePayload.sports = data.sports;
        if (data.amenities) updatePayload.amenities = data.amenities;
        if (data.images) updatePayload.images = data.images;
        if (data.status) updatePayload.status = data.status;
        if (data.operationalStatus) {
            updatePayload.operationalStatus = data.operationalStatus === 'power-issue' 
                ? 'power_issue' 
                : data.operationalStatus === 'heavy-rain' 
                ? 'heavy_rain' 
                : data.operationalStatus;
        }
        if (data.upiId !== undefined) updatePayload.upiId = data.upiId;
        if (data.taxPercentage !== undefined) updatePayload.taxPercentage = Number(data.taxPercentage);
        if (data.settings) {
            if (data.settings.minBookingDuration) updatePayload.minBookingDuration = Number(data.settings.minBookingDuration);
            if (data.settings.advanceBookingLimit) updatePayload.advanceBookingLimit = Number(data.settings.advanceBookingLimit);
            if (data.settings.bookingCutoffTime) updatePayload.bookingCutoffTime = Number(data.settings.bookingCutoffTime);
            if (data.settings.gracePeriod) updatePayload.gracePeriod = Number(data.settings.gracePeriod);
            if (data.settings.maxMembers) updatePayload.maxMembers = Number(data.settings.maxMembers);
            if (data.settings.upiId !== undefined) updatePayload.upiId = data.settings.upiId;
            if (data.settings.taxPercentage !== undefined) updatePayload.taxPercentage = Number(data.settings.taxPercentage);
        }

        const updated = await prisma.turf.update({
            where: { id: String(id) },
            data: updatePayload
        });
        return serializeTurf(updated);
    }

    return await TurfMongo.findByIdAndUpdate(id, data, { new: true });
};

const updateRating = async (turfId, avgRating, numReviews) => {
    if (isPostgres()) {
        return await prisma.turf.update({
            where: { id: String(turfId) },
            data: {
                avgRating: Number(avgRating),
                numReviews: Number(numReviews)
            }
        });
    }

    return await TurfMongo.findByIdAndUpdate(turfId, {
        'settings.avgRating': avgRating,
        'settings.numReviews': numReviews
    });
};

const findAllTurfs = async () => {
    if (isPostgres()) {
        const turfs = await prisma.turf.findMany({
            include: {
                owner: {
                    select: { id: true, name: true, email: true, phone: true }
                }
            },
            orderBy: { createdAt: 'desc' }
        });
        return turfs.map(serializeTurf);
    }
    return await TurfMongo.find({}).populate('ownerId', 'name email phone');
};

const updateTurfStatus = async (id, status) => {
    if (isPostgres()) {
        const updated = await prisma.turf.update({
            where: { id: String(id) },
            data: { status }
        });
        return serializeTurf(updated);
    }
    const turf = await TurfMongo.findById(id);
    if (!turf) return null;
    turf.status = status;
    return await turf.save();
};

module.exports = {
    findApprovedTurfs,
    findAllTurfs,
    findTurfById,
    findTurfsByOwner,
    createTurf,
    updateTurf,
    updateTurfStatus,
    updateRating,
    isPostgres
};
