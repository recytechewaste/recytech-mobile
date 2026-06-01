const mongoose = require('mongoose');

const requestSchema = mongoose.Schema({
    residentName: {
        type: String,
        required: true
    },
    resident: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Resident',
        required: false
    },
    wasteType: {
        type: String, // Broad ExchangeRate type, e.g. "Large Appliances"
        required: true
    },
    itemCategory: {
        type: String, // Normalized submitted item class, e.g. "washing machine"
        required: false
    },
    detectedClass: {
        type: String, // Raw class/category submitted by mobile/web
        required: false
    },
    weight: {
        type: Number,
        default: 0
    },
    quantity: {
        type: Number,
        default: 1,
        min: 1
    },
    wasteImage: {
        type: String, // Data URL or hosted image URL submitted by mobile/web
        required: false // Optional for now
    },
    location: {
        address: { type: String, required: true },
        // We can add lat/long coordinates later for the map
    },
    status: {
        type: String,
        enum: [
            'Pending',
            'Approved',
            'Assigned',
            'For Pickup',
            'Rejected',
            'Cancelled',
            'Canceled',
            'In-Transit',
            'Collected',
            'Drop-off Confirmed',
            'Received',
            'Payout Processing',
            'Paid',
            'Reward Released',
            'Completed'
        ],
        default: 'Pending'
    },
    assignedCollector: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Collector', // Links this request to a specific Collector
        required: false
    },
    scheduledAt: {
        type: Date,
        required: false
    },
    residentEmail: {
        type: String, // Email to link request to resident account
        required: false // Optional for anonymous submissions
    },
    mobileUserId: {
        type: String,
        required: false,
        trim: true
    },
    monetaryValue: {
        type: Number, // Calculated payout in PHP
        default: 0
    },
    payoutStatus: {
        type: String,
        enum: ['Not Ready', 'Pending', 'Processing', 'Released', 'Failed'],
        default: 'Not Ready'
    },
    dropoffConfirmedAt: {
        type: Date,
        required: false
    },
    payoutReleasedAt: {
        type: Date,
        required: false
    },
    ratePerItem: {
        type: Number,
        required: false
    },
    ratePerKg: {
        type: Number,
        required: false
    },
    paymentProcessed: {
        type: Boolean, // Tracks if payment has been issued
        default: false
    }
}, {
    timestamps: true
});

module.exports = mongoose.model('Request', requestSchema);
