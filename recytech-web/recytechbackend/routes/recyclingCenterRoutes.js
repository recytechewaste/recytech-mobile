const express = require('express');
const router = express.Router();
const RecyclingCenter = require('../models/RecyclingCenter');
const { protect, admin } = require('../middleware/authMiddleware');

// @desc    Get all centers
// @route   GET /api/centers
router.get('/', protect, admin, async (req, res) => {
    try {
        const centers = await RecyclingCenter.find().sort({ createdAt: -1 });
        res.json(centers);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
});

// @desc    Create a center
// @route   POST /api/centers
router.post('/', protect, admin, async (req, res) => {
    const { name, location, address, items, status } = req.body;
    try {
        const center = await RecyclingCenter.create({
            name,
            location,
            address,
            items,
            status
        });
        res.status(201).json(center);
    } catch (error) {
        res.status(400).json({ message: error.message });
    }
});

// @desc    Update a center
// @route   PUT /api/centers/:id
router.put('/:id', protect, admin, async (req, res) => {
    try {
        const updatedCenter = await RecyclingCenter.findByIdAndUpdate(
            req.params.id,
            req.body,
            { new: true }
        );
        if (updatedCenter) {
            res.json(updatedCenter);
        } else {
            res.status(404).json({ message: 'Center not found' });
        }
    } catch (error) {
        res.status(400).json({ message: error.message });
    }
});

// @desc    Delete a center
// @route   DELETE /api/centers/:id
router.delete('/:id', protect, admin, async (req, res) => {
    try {
        const center = await RecyclingCenter.findByIdAndDelete(req.params.id);
        if (center) {
            res.json({ message: 'Center removed' });
        } else {
            res.status(404).json({ message: 'Center not found' });
        }
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
});

module.exports = router;
