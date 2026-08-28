const mongoose = require('mongoose');

const tournamentTeamSchema = new mongoose.Schema({
    tournamentId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Tournament',
        required: true
    },
    captainId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User',
        required: true
    },
    name: {
        type: String,
        required: true,
        trim: true
    },
    members: [{
        type: String,
        trim: true
    }],
    status: {
        type: String,
        enum: ['pending', 'approved', 'rejected'],
        default: 'pending'
    },
    paymentStatus: {
        type: String,
        enum: ['pending', 'paid'],
        default: 'pending'
    },
    transactionId: {
        type: String,
        default: ''
    }
}, {
    timestamps: true
});

const TournamentTeam = mongoose.model('TournamentTeam', tournamentTeamSchema);
module.exports = TournamentTeam;
