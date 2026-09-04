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
        if (groundName && groundName !== 'all') where.groundName = groundName;

        let slots = await prisma.slot.findMany({
            where,
            orderBy: { startTime: 'asc' }
        });

        // Fallback: If groundName was filtered but returned no slots, check with groundName: ''
        if (slots.length === 0 && groundName && groundName !== 'all') {
            const fallbackSlots = await prisma.slot.findMany({
                where: {
                    turfId: String(turfId),
                    ...(dayOfWeek ? { dayOfWeek } : {}),
                    groundName: ''
                },
                orderBy: { startTime: 'asc' }
            });
            if (fallbackSlots.length > 0) {
                slots = fallbackSlots;
            }
        }

        return slots.map(s => serializeSlot(s));
    }

    const query = { turfId };
    if (dayOfWeek) query.dayOfWeek = dayOfWeek;
    if (groundName && groundName !== 'all') query.groundName = groundName;

    let slots = await SlotMongo.find(query);
    if (slots.length === 0 && groundName && groundName !== 'all') {
        const fallback = await SlotMongo.find({ turfId, ...(dayOfWeek ? { dayOfWeek } : {}), groundName: '' });
        if (fallback.length > 0) slots = fallback;
    }
    return slots;
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

const upsertSlot = async (turfIdOrData, maybeSlotData) => {
    let turfId;
    let slotData;

    if (maybeSlotData) {
        turfId = String(turfIdOrData);
        slotData = maybeSlotData;
    } else if (typeof turfIdOrData === 'object' && turfIdOrData !== null) {
        turfId = String(turfIdOrData.turfId);
        slotData = turfIdOrData;
    } else {
        throw new Error('Invalid arguments to upsertSlot');
    }

    const groundName = (slotData.groundName !== undefined && slotData.groundName !== null) ? String(slotData.groundName).trim() : '';
    const sport = slotData.sport ? String(slotData.sport).trim() : 'General';
    const dayOfWeek = slotData.dayOfWeek;
    const startTime = String(slotData.startTime);
    const endTime = String(slotData.endTime);
    const price = Number(slotData.price || 0);
    const isBlocked = Boolean(slotData.isBlocked);

    if (isPostgres()) {
        const slot = await prisma.slot.upsert({
            where: {
                turfId_groundName_sport_dayOfWeek_startTime: {
                    turfId,
                    groundName,
                    sport,
                    dayOfWeek,
                    startTime
                }
            },
            update: {
                endTime,
                price,
                isBlocked
            },
            create: {
                turfId,
                groundName,
                sport,
                dayOfWeek,
                startTime,
                endTime,
                price,
                isBlocked
            }
        });
        return serializeSlot(slot);
    }

    return await SlotMongo.findOneAndUpdate(
        {
            turfId,
            groundName,
            dayOfWeek,
            startTime,
            sport
        },
        {
            turfId,
            groundName,
            sport,
            dayOfWeek,
            startTime,
            endTime,
            price,
            isBlocked
        },
        { upsert: true, new: true }
    );
};

module.exports = {
    findSlots,
    findSlotById,
    upsertSlot,
    isPostgres
};
