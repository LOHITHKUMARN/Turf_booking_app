const mongoose = require('mongoose');

const AdminAuditLogSchema = new mongoose.Schema({
    adminId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User',
        required: true
    },
    action: {
        type: String,
        required: true,
        // Using a more flexible list or removing enum if too restrictive, but adding required ones for now
        enum: [
            'approve_turf', 'reject_turf', 'block_user', 'unblock_user', 
            'change_commission', 'update_payout_processed', 'update_payout_failed',
            'update_payout_pending', 'delete_user'
        ]
    },
    targetId: {
        type: mongoose.Schema.Types.ObjectId,
        required: true
    },
    targetType: {
        type: String,
        required: true,
        enum: ['Turf', 'User', 'System', 'Payout']
    },
    details: {
        type: Object,
        default: {}
    },
    ipAddress: {
        type: String
    }
}, { timestamps: true });

AdminAuditLogSchema.index({ adminId: 1, createdAt: -1 });

module.exports = mongoose.model('AdminAuditLog', AdminAuditLogSchema);
