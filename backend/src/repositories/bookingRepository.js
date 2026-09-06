const { prisma } = require('../config/db');
const BookingMongo = require('../models/Booking');
const { serializeBooking } = require('../utils/serializer');

const isPostgres = () => process.env.DB_PROVIDER === 'postgres';

const findBookingsForDateRange = async (turfId, startUtc, endUtc) => {
    if (isPostgres()) {
        const bookings = await prisma.booking.findMany({
            where: {
                turfId: String(turfId),
                bookingDate: {
                    gte: startUtc,
                    lt: endUtc
                },
                bookingStatus: { not: 'cancelled' }
            }
        });
        return bookings.map(serializeBooking);
    }

    return await BookingMongo.find({
        turfId,
        bookingDate: {
            $gte: startUtc,
            $lt: endUtc
        },
        bookingStatus: { $ne: 'cancelled' }
    });
};

const createBookingAtomic = async ({
    userId,
    turfId,
    slotId,
    groundName,
    bookingDate,
    totalAmount,
    taxAmount,
    paymentMethod,
    paymentStatus = 'pending',
    bookingStatus = 'confirmed'
}) => {
    if (isPostgres()) {
        const startOfDay = new Date(bookingDate);
        startOfDay.setUTCHours(0, 0, 0, 0);
        const endOfDay = new Date(startOfDay);
        endOfDay.setUTCDate(endOfDay.getUTCDate() + 1);

        return await prisma.$transaction(async (tx) => {
            // Check for existing booking on that day
            const existing = await tx.booking.findFirst({
                where: {
                    slotId: String(slotId),
                    bookingDate: {
                        gte: startOfDay,
                        lt: endOfDay
                    },
                    bookingStatus: { not: 'cancelled' }
                }
            });

            if (existing) {
                const error = new Error('Slot already booked for this date');
                error.status = 400;
                throw error;
            }

            const booking = await tx.booking.create({
                data: {
                    userId: userId ? String(userId) : null,
                    turfId: String(turfId),
                    slotId: String(slotId),
                    groundName: groundName || '',
                    bookingDate: new Date(bookingDate),
                    totalAmount: Number(totalAmount),
                    taxAmount: Number(taxAmount || 0),
                    paymentMethod: paymentMethod || 'cash',
                    paymentStatus: paymentStatus || 'pending',
                    bookingStatus: bookingStatus || 'confirmed'
                },
                include: {
                    turf: true,
                    slot: true,
                    user: true
                }
            });

            return serializeBooking(booking);
        });
    }

    const booking = await BookingMongo.create({
        userId,
        turfId,
        slotId,
        groundName,
        bookingDate,
        totalAmount,
        taxAmount,
        paymentStatus,
        bookingStatus,
        paymentMethod
    });
    return booking;
};

const findUserBookings = async (userId) => {
    if (isPostgres()) {
        const bookings = await prisma.booking.findMany({
            where: { userId: String(userId) },
            include: {
                turf: {
                    select: { id: true, name: true, city: true, area: true, images: true }
                },
                slot: {
                    select: { id: true, startTime: true, endTime: true, sport: true, groundName: true, price: true }
                },
                review: {
                    select: { id: true, rating: true, comment: true }
                }
            },
            orderBy: { bookingDate: 'desc' }
        });
        return bookings.map(serializeBooking);
    }

    return await BookingMongo.find({ userId })
        .populate('turfId', 'name location images')
        .populate('slotId')
        .populate('reviewId')
        .sort({ bookingDate: -1 });
};

const findBookingById = async (id) => {
    if (!id) return null;
    if (isPostgres()) {
        const booking = await prisma.booking.findUnique({
            where: { id: String(id) },
            include: {
                turf: true,
                slot: true,
                user: true,
                review: true
            }
        });
        return booking ? serializeBooking(booking) : null;
    }

    return await BookingMongo.findById(id).populate('turfId').populate('slotId').populate('userId').populate('reviewId');
};

const updateBooking = async (id, updateData) => {
    if (isPostgres()) {
        const data = {};
        if (updateData.bookingStatus) {
            data.bookingStatus = updateData.bookingStatus === 'checked-in'
                ? 'checked_in'
                : updateData.bookingStatus === 'no-show'
                ? 'no_show'
                : updateData.bookingStatus;
        }
        if (updateData.paymentStatus) data.paymentStatus = updateData.paymentStatus;
        if (updateData.isPaid !== undefined) data.isPaid = updateData.isPaid;
        if (updateData.checkInTime) data.checkInTime = new Date(updateData.checkInTime);
        if (updateData.checkOutTime) data.checkOutTime = new Date(updateData.checkOutTime);
        if (updateData.staffNotes !== undefined) data.staffNotes = updateData.staffNotes;
        if (updateData.transactionId) data.transactionId = updateData.transactionId;
        if (updateData.isOverstayed !== undefined) data.isOverstayed = updateData.isOverstayed;
        if (updateData.extraCharges) data.extraCharges = updateData.extraCharges;

        const updated = await prisma.booking.update({
            where: { id: String(id) },
            data,
            include: { turf: true, slot: true, user: true }
        });
        return serializeBooking(updated);
    }

    return await BookingMongo.findByIdAndUpdate(id, updateData, { new: true });
};

module.exports = {
    findBookingsForDateRange,
    createBookingAtomic,
    findUserBookings,
    findBookingById,
    updateBooking,
    isPostgres
};
