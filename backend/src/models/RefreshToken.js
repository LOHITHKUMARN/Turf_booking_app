const mongoose = require('mongoose');

const refreshTokenSchema = new mongoose.Schema({
    token: {
        type: String,
        required: true,
        unique: true
    },
    user: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User',
        required: true
    },
    expiryDate: {
        type: Date,
        required: true
    }
}, { timestamps: true });

// Helper to check if token is expired
refreshTokenSchema.methods.isExpired = function() {
    return this.expiryDate.getTime() <= new Date().getTime();
};

const RefreshToken = mongoose.model('RefreshToken', refreshTokenSchema);

module.exports = RefreshToken;
