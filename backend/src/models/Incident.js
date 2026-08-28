const mongoose = require('mongoose');

const incidentSchema = new mongoose.Schema({
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
    type: {
        type: String,
        enum: ['Injury', 'Damage', 'Crowd Issue', 'Other'],
        required: true
    },
    severity: {
        type: String,
        enum: ['Low', 'Medium', 'High', 'Critical'],
        default: 'Low'
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
        enum: ['Reported', 'Under Investigation', 'Resolved'],
        default: 'Reported'
    }
}, {
    timestamps: true
});

const Incident = mongoose.model('Incident', incidentSchema);
module.exports = Incident;
