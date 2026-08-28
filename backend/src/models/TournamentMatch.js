const mongoose = require('mongoose');

const tournamentMatchSchema = new mongoose.Schema({
    tournamentId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Tournament',
        required: true
    },
    team1Id: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'TournamentTeam'
    },
    team2Id: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'TournamentTeam'
    },
    winnerId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'TournamentTeam'
    },
    score1: {
        type: Number,
        default: 0
    },
    score2: {
        type: Number,
        default: 0
    },
    round: {
        type: Number,
        required: true
    },
    matchIndex: {
        type: Number,
        required: true
    },
    startTime: {
        type: Date
    },
    groundName: {
        type: String,
        default: ''
    },
    staffId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User'
    },
    isVerified: {
        type: Boolean,
        default: false
    },
    staffNotes: {
        type: String,
        default: ''
    },
    status: {
        type: String,
        enum: ['scheduled', 'live', 'completed', 'verified', 'cancelled'],
        default: 'scheduled'
    }
}, {
    timestamps: true
});

const TournamentMatch = mongoose.model('TournamentMatch', tournamentMatchSchema);
module.exports = TournamentMatch;
