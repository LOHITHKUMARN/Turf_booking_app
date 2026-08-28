const mongoose = require('mongoose');

const slotSchema = new mongoose.Schema({
    turfId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Turf',
        required: true
    },
    sport: {
        type: String,
        required: true
    },
    groundName: {
        type: String,
        default: '' // Optional for turf with single ground
    },
    dayOfWeek: {
        type: String,
        enum: ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'],
        required: true
    },
    startTime: {
        type: String, // e.g., "06:00"
        required: true
    },
    endTime: {
        type: String, // e.g., "07:00"
        required: true
    },
    price: {
        type: Number,
        required: true
    },
    isBlocked: {
        type: Boolean,
        default: false
    }
}, {
    timestamps: true
});

// Compound index to prevent duplicate slots for the same turf, ground, sport, day, and time
slotSchema.index({ turfId: 1, groundName: 1, sport: 1, dayOfWeek: 1, startTime: 1 }, { unique: true });

const Slot = mongoose.model('Slot', slotSchema);
module.exports = Slot;
