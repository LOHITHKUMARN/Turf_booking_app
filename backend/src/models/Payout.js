const mongoose = require('mongoose');

const payoutSchema = new mongoose.Schema({
    ownerId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User',
        required: true
    },
    amount: {
        type: Number,
        required: true
    },
    status: {
        type: String,
        enum: ['pending', 'processed', 'failed'],
        default: 'pending'
    },
    requestedAt: {
        type: Date,
        default: Date.now
    },
    processedAt: {
        type: Date
    },
    bankDetails: {
        accountNumber: String,
        ifscCode: String,
        accountHolderName: String
    },
    statementUrl: {
        type: String
    }
}, {
    timestamps: true
});

const Payout = mongoose.model('Payout', payoutSchema);
module.exports = Payout;
