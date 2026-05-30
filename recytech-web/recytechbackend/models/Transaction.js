const mongoose = require('mongoose');

const transactionSchema = mongoose.Schema({
    resident: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Resident',
        required: true,
        description: "Reference to the resident who received the payment"
    },
    type: {
        type: String,
        enum: ['Payment', 'Refund', 'Adjustment'],
        required: true,
        description: "Type of transaction"
    },
    amount: {
        type: Number,
        required: true,
        min: 0,
        description: "Amount in PHP"
    },
    requestId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Request',
        required: false,
        description: "Reference to the request this transaction is related to (for Payment/Refund)"
    },
    description: {
        type: String,
        required: false,
        example: "Payment for 2 Battery recycling item(s)"
    }
}, {
    timestamps: true
});

module.exports = mongoose.model('Transaction', transactionSchema);
