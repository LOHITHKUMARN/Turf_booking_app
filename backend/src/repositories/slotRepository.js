const { prisma } = require('../config/db');
const SlotMongo = require('../models/Slot');
const { serializeSlot } = require('../utils/serializer');

const isPostgres = () => process.env.DB_PROVIDER === 'postgres';

const findSlots = async ({ turfId, dayOfWeek, groundName }) => {
    if (isPostgres()) {
        const where = {
            turfId: String(turfId)
        };
        if (dayOfWeek) where.dayOfWeek = dayOfWeek;
        if (groundName) where.groundName = groundName;

        const slots = await prisma.slot.findMany({
            where,
            orderBy: { startTime: 'asc' }
        });

        return slots.map(s => serializeSlot(s));
    }

    const query = { turfId };
    if (dayOfWeek) query.dayOfWeek = dayOfWeek;
    if (groundName) query.groundName = groundName;

    return await SlotMongo.find(query);
};

const findSlotById = async (id) => {
    if (!id) return null;
    if (isPostgres()) {
        const slot = await prisma.slot.findUnique({
            where: { id: String(id) }
        });
        return slot ? serializeSlot(slot) : null;
    }

    return await SlotMongo.findById(id);
};

const upsertSlot = async (turfId, slotData) => {
    if (isPostgres()) {
        const slot = await prisma.slot.upsert({
            where: {
                turfId_groundName_sport_dayOfWeek_startTime: {
                    turfId: String(turfId),
                    groundName: slotData.groundName || '',
                    sport: slotData.sport,
                    dayOfWeek: slotData.dayOfWeek,
                    startTime: slotData.startTime
                }
            },
            update: {
                endTime: slotData.endTime,
                price: Number(slotData.price),
                isBlocked: Boolean(slotData.isBlocked)
            },
            create: {
                turfId: String(turfId),
                groundName: slotData.groundName || '',
                sport: slotData.sport,
                dayOfWeek: slotData.dayOfWeek,
                startTime: slotData.startTime,
                endTime: slotData.endTime,
                price: Number(slotData.price),
                isBlocked: Boolean(slotData.isBlocked)
            }
        });
        return serializeSlot(slot);
    }

    return await SlotMongo.findOneAndUpdate(
        {
            turfId,
            groundName: slotData.groundName || '',
            dayOfWeek: slotData.dayOfWeek,
            startTime: slotData.startTime,
            sport: slotData.sport
        },
        slotData,
        { upsert: true, new: true }
    );
};

module.exports = {
    findSlots,
    findSlotById,
    upsertSlot,
    isPostgres
};
