const mongoose = require('mongoose');

const collectorSchema = mongoose.Schema({
    user: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User',
        required: true
    },
    firstName: { type: String, required: true },
    lastName: { type: String, required: true },
    phone: { type: String, required: true },
    vehiclePlate: { type: String, default: 'Not Assigned' },
    vehicleType: { 
        type: String, 
        enum: ['E-Trike', 'Truck', 'Bike'],
        required: [true, 'Vehicle type is required']
    },
    status: { type: String, default: 'Active' }
}, {
    timestamps: true
});

module.exports = mongoose.model('Collector', collectorSchema);
