const mongoose = require('mongoose');

const bookingSchema = new mongoose.Schema({
    userId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User'
        // userId is optional for walk-in bookings
    },
    turfId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Turf',
        required: true
    },
    slotId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Slot',
        required: true
    },
    groundName: {
        type: String,
        default: ''
    },
    bookingDate: {
        type: Date,
        required: true
    },
    totalAmount: {
        type: Number,
        required: true
    },
    taxAmount: {
        type: Number,
        default: 0
    },
    paymentMethod: {
        type: String,
        enum: ['cash', 'upi'],
        default: 'cash'
    },
    isPaid: {
        type: Boolean,
        default: false
    },
    paymentStatus: {
        type: String,
        enum: ['pending', 'paid', 'failed', 'refunded'],
        default: 'pending'
    },
    paymentId: {
        type: String
    },
    bookingStatus: {
        type: String,
        enum: ['confirmed', 'cancelled', 'completed', 'checked-in', 'no-show'],
        default: 'confirmed'
    },
    transactionId: {
        type: String
    },
    checkInTime: {
        type: Date
    },
    checkOutTime: {
        type: Date
    },
    staffNotes: {
        type: String,
        default: ''
    },
    isOverstayed: {
        type: Boolean,
        default: false
    },
    extraCharges: [{
        type: {
            type: String,
            required: true
        },
        amount: {
            type: Number,
            required: true
        },
        isPaid: {
            type: Boolean,
            default: false
        }
    }],
    reviewId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Review'
    }
}, {
    timestamps: true
});

const Booking = mongoose.model('Booking', bookingSchema);
module.exports = Booking;
