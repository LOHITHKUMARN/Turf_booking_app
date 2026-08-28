const mongoose = require('mongoose');

const maintenanceSchema = new mongoose.Schema({
    turfId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Turf',
        required: true
    },
    reporterId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User',
        required: true
    },
    category: {
        type: String,
        enum: ['Ground', 'Lights', 'Amenities', 'Other'],
        required: true
    },
    description: {
        type: String,
        required: true,
        trim: true
    },
    images: [{
        type: String
    }],
    status: {
        type: String,
        enum: ['Pending', 'In Progress', 'Resolved'],
        default: 'Pending'
    }
}, {
    timestamps: true
});

const Maintenance = mongoose.model('Maintenance', maintenanceSchema);
module.exports = Maintenance;
