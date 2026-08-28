const mongoose = require('mongoose');

const tournamentSchema = new mongoose.Schema({
    ownerId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User',
        required: true
    },
    turfId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Turf',
        required: true
    },
    name: {
        type: String,
        required: true,
        trim: true
    },
    description: {
        type: String,
        required: true
    },
    sportsType: {
        type: String,
        required: true
    },
    teamSize: {
        type: Number,
        required: true
    },
    maxTeams: {
        type: Number,
        required: true
    },
    registrationFee: {
        type: Number,
        default: 0
    },
    prizePool: {
        type: String,
        default: ''
    },
    startDate: {
        type: Date,
        required: true
    },
    endDate: {
        type: Date,
        required: true
    },
    registrationDeadline: {
        type: Date,
        required: true
    },
    rules: [{
        type: String
    }],
    status: {
        type: String,
        enum: ['pending_approval', 'draft', 'open', 'ongoing', 'completed', 'cancelled', 'rejected'],
        default: 'pending_approval'
    },
    adminNotes: {
        type: String,
        default: ''
    },
    bannerImage: {
        type: String,
        default: ''
    }
}, {
    timestamps: true
});

const Tournament = mongoose.model('Tournament', tournamentSchema);
module.exports = Tournament;
