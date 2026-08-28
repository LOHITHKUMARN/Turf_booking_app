const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');

const userSchema = new mongoose.Schema({
    name: {
        type: String,
        required: true,
        trim: true
    },
    email: {
        type: String,
        required: true,
        unique: true,
        lowercase: true,
        trim: true
    },
    phone: {
        type: String,
        required: true,
        unique: true,
        trim: true
    },
    password: {
        type: String,
        required: true,
        minlength: 6
    },
    role: {
        type: String,
        enum: ['customer', 'staff', 'owner', 'admin'],
        default: 'customer'
    },
    status: {
        type: String,
        enum: ['active', 'blocked'],
        default: 'active'
    },
    ownerId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User'
    },
    assignedTurfId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Turf'
    },
    assignedGround: {
        type: String,
        default: ''
    },
    profileImage: {
        type: String,
        default: ''
    },
    fcmTokens: {
        type: [String],
        default: []
    }
}, {
    timestamps: true
});

// Hash password before saving
userSchema.pre('save', async function () {
    // Only hash if modified AND not already a hash (starts with $2)
    if (!this.isModified('password')) return;
    if (this.password.startsWith('$2')) return;

    console.log(`Hashing password for user: ${this.email}, Role: ${this.role}`);
    this.password = await bcrypt.hash(this.password, 10);
});

// Match password
userSchema.methods.matchPassword = async function (enteredPassword) {
    return await bcrypt.compare(enteredPassword, this.password);
};

const User = mongoose.model('User', userSchema);
module.exports = User;
