const mongoose = require('mongoose');

const turfSchema = new mongoose.Schema({
    ownerId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User',
        required: true
    },
    name: {
        type: String,
        required: true,
        trim: true
    },
    turfType: {
        type: String,
        enum: ['indoor', 'outdoor', 'both'],
        default: 'both'
    },
    location: {
        city: { type: String, required: true },
        area: { type: String, required: true }
    },
    grounds: [{
        type: String // names of grounds like "Ground 1", "Court A"
    }],
    sports: [{
        type: String
    }],
    amenities: [{
        type: String
    }],
    images: [{
        type: String
    }],
    status: {
        type: String,
        enum: ['pending', 'approved', 'suspended'],
        default: 'pending'
    },
    operationalStatus: {
        type: String,
        enum: ['normal', 'wet', 'maintenance', 'power-issue', 'heavy-rain'],
        default: 'normal'
    },
    settings: {
        minBookingDuration: { type: Number, default: 1 }, // in hours
        advanceBookingLimit: { type: Number, default: 7 }, // in days
        bookingCutoffTime: { type: Number, default: 2 }, // hours before slot starts
        gracePeriod: { type: Number, default: 15 }, // minutes for late arrival check-in
        maxMembers: { type: Number, default: 10 },
        upiId: { type: String, default: '' },
        taxPercentage: { type: Number, default: 0 },
        avgRating: { type: Number, default: 0 },
        numReviews: { type: Number, default: 0 }
    }
}, {
    timestamps: true
});

const Turf = mongoose.model('Turf', turfSchema);
module.exports = Turf;
