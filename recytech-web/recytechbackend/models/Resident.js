const mongoose = require('mongoose');

const residentSchema = mongoose.Schema({
    email: {
        type: String,
        required: true,
        unique: true,
        lowercase: true,
        trim: true,
        description: "Unique email identifier for resident"
    },
    firstName: {
        type: String,
        required: false
    },
    lastName: {
        type: String,
        required: false
    },
    phone: {
        type: String,
        required: false
    },
    source: {
        type: String,
        enum: ['Mobile Simulation', 'Mobile App', 'Web', 'Imported'],
        default: 'Mobile Simulation',
        description: "Where this resident profile came from"
    },
    isTemporary: {
        type: Boolean,
        default: true,
        description: "Temporary profile used until mobile accounts are integrated"
    },
    mobileUserId: {
        type: String,
        required: false,
        trim: true,
        description: "Future link to the mobile app account/user ID"
    },
    walletBalance: {
        type: Number,
        default: 0,
        min: 0,
        description: "Current available balance in PHP"
    },
    totalEarned: {
        type: Number,
        default: 0,
        min: 0,
        description: "Total amount earned from all completed requests in PHP"
    },
    requestCount: {
        type: Number,
        default: 0,
        min: 0,
        description: "Total number of requests submitted by resident"
    },
    status: {
        type: String,
        enum: ['Active', 'Inactive'],
        default: 'Active',
        description: "Account status - can be deactivated by admin"
    }
}, {
    timestamps: true
});

module.exports = mongoose.model('Resident', residentSchema);
