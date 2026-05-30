const mongoose = require('mongoose');

const educationSchema = mongoose.Schema({
    title: {
        type: String,
        required: [true, 'Please add a title']
    },
    category: {
        type: String,
        required: [true, 'Please select a category'],
        enum: ["Sustainability", "E-Waste Disposal", "Environmental Impact", "Regulations"]
    },
    type: {
        type: String,
        required: [true, 'Please select a type'],
        enum: ["Article", "Video", "PDF"]
    },
    description: {
        type: String,
        required: [true, 'Please add a description']
    },
    contentURL: {
        type: String,
        default: ''
    },
    thumbnail: {
        type: String, // Stores the Base64 string
        default: null
    },
    status: {
        type: String,
        enum: ['Draft', 'Published'],
        default: 'Published'
    }
}, {
    timestamps: true
});

module.exports = mongoose.model('Education', educationSchema);