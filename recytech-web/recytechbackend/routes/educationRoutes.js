const express = require('express');
const router = express.Router();
const Education = require('../models/Education');
const { protect } = require('../middleware/authMiddleware');

// @desc    Get all materials
// @route   GET /api/education
router.get('/', protect, async (req, res) => {
    try {
        const materials = await Education.find({}).sort({ createdAt: -1 });
        res.json(materials);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
});

// @desc    Create new material
// @route   POST /api/education
router.post('/', protect, async (req, res) => {
    try {
        const material = await Education.create(req.body);
        res.status(201).json(material);
    } catch (error) {
        res.status(400).json({ message: error.message });
    }
});

// @desc    Update material
// @route   PUT /api/education/:id
router.put('/:id', protect, async (req, res) => {
    try {
        const material = await Education.findById(req.params.id);

        if (material) {
            material.title = req.body.title || material.title;
            material.category = req.body.category || material.category;
            material.type = req.body.type || material.type;
            material.description = req.body.description || material.description;
            material.contentURL = req.body.contentURL || material.contentURL;
            material.thumbnail = req.body.thumbnail || material.thumbnail;
            material.status = req.body.status || material.status;

            const updated = await material.save();
            res.json(updated);
        } else {
            res.status(404).json({ message: 'Material not found' });
        }
    } catch (error) {
        res.status(400).json({ message: error.message });
    }
});

// @desc    Delete material
// @route   DELETE /api/education/:id
router.delete('/:id', protect, async (req, res) => {
    try {
        const material = await Education.findById(req.params.id);
        if (material) {
            await material.deleteOne();
            res.json({ message: 'Material removed' });
        } else {
            res.status(404).json({ message: 'Material not found' });
        }
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
});

module.exports = router;