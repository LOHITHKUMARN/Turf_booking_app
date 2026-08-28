const mongoose = require('mongoose');

const announcementSchema = new mongoose.Schema({
    turfId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Turf',
        required: true
    },
    title: {
        type: String,
        required: true,
        trim: true
    },
    message: {
        type: String,
        required: true,
        trim: true
    },
    type: {
        type: String,
        enum: ['General', 'Emergency', 'Shift Update'],
        default: 'General'
    },
    isPublic: {
        type: Boolean,
        default: false // Set to false to keep it staff-only
    }
}, {
    timestamps: true
});

const Announcement = mongoose.model('Announcement', announcementSchema);
module.exports = Announcement;
