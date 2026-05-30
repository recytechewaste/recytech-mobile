const express = require('express');
const router = express.Router();
const Collector = require('../models/Collector');
const User = require('../models/User');
const bcrypt = require('bcryptjs');
const { protect, admin } = require('../middleware/authMiddleware');

// @desc    Get all collectors
// @route   GET /api/collectors
router.get('/', protect, admin, async (req, res) => {
    try {
        const collectors = await Collector.find();
        res.json(collectors);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
});

// @desc    Register a new Collector
// @route   POST /api/collectors
router.post('/', protect, admin, async (req, res) => {
    const { firstName, lastName, email, password, phone, vehiclePlate, vehicleType, status } = req.body;

    try {
        // 1. Check if user already exists
        const userExists = await User.findOne({ email });
        if (userExists) {
            return res.status(400).json({ message: 'User with this email already exists' });
        }

        // 2. Create the User account for the collector
        const salt = await bcrypt.genSalt(10);
        const hashedPassword = await bcrypt.hash(password, salt);

        const newUser = await User.create({
            firstName,
            lastName,
            email,
            password: hashedPassword,
            role: 'Collector',
            status: status || 'Active'
        });

        // 3. Create the Collector profile linked to the User
        const newCollector = await Collector.create({
            user: newUser._id,
            firstName,
            lastName,
            phone,
            vehiclePlate,
            vehicleType,
            status: status || 'Active'
        });
        res.status(201).json(newCollector);
    } catch (error) {
        res.status(400).json({ message: error.message });
    }
});

// @desc    Update a collector
// @route   PUT /api/collectors/:id
router.put('/:id', protect, admin, async (req, res) => {
    try {
        const { firstName, lastName, status } = req.body;

        // 1. Update the collector document
        const updatedCollector = await Collector.findByIdAndUpdate(
            req.params.id,
            req.body,
            { new: true }
        );

        if (updatedCollector) {
            // 2. Sync with the associated User document
            // Updates firstName, lastName, and status for the login account
            await User.findByIdAndUpdate(updatedCollector.user, {
                ...(firstName && { firstName }),
                ...(lastName && { lastName }),
                ...(status && { status })
            });

            res.json(updatedCollector);
        } else {
            res.status(404).json({ message: 'Collector not found' });
        }
    } catch (error) {
        res.status(400).json({ message: error.message });
    }
});

// @desc    Delete a collector
// @route   DELETE /api/collectors/:id
router.delete('/:id', protect, admin, async (req, res) => {
    try {
        // Find collector to get the associated user ID before deletion
        const collector = await Collector.findById(req.params.id);
        if (collector) {
            // Remove associated login account
            await User.findByIdAndDelete(collector.user);
            // Remove the collector profile
            await collector.deleteOne();
            res.json({ message: 'Collector removed' });
        } else {
            res.status(404).json({ message: 'Collector not found' });
        }
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
});

module.exports = router;
