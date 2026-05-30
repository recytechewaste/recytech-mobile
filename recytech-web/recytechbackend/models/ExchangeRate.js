const mongoose = require('mongoose');

const exchangeRateSchema = mongoose.Schema({
    wasteType: {
        type: String,
        required: true,
        unique: true, // One rate per waste type
        trim: true,
        example: "Electronics, Plastics, Battery, Metal, Paper"
    },
    ratePerItem: {
        type: Number,
        min: 0,
        description: "Price in PHP per item/unit"
    },
    ratePerKg: {
        type: Number,
        min: 0,
        description: "Legacy price in PHP per kilogram"
    },
    description: {
        type: String,
        required: false,
        example: "Payment per recycled electronic item"
    },
    isActive: {
        type: Boolean,
        default: true, // Rates can be deactivated without deleting
        description: "If false, this rate won't be used for payouts"
    }
}, {
    timestamps: true
});

module.exports = mongoose.model('ExchangeRate', exchangeRateSchema);
