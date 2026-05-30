const express = require('express');
const router = express.Router();
const ExchangeRate = require('../models/ExchangeRate');
const {
    cleanWasteType,
    findExchangeRateByNormalizedWasteType,
    formatWasteTypeLabel,
    getSupportedClassOptions,
    normalizeWasteType
} = require('../utils/categoryNormalization');
const { protect, admin } = require('../middleware/authMiddleware');

// @desc    Get all exchange rates
// @route   GET /api/exchange-rates
// @access  Admin only
router.get('/', protect, admin, async (req, res) => {
    try {
        const includeInactive = req.query.includeInactive === 'true';

        let query = {};
        if (!includeInactive) {
            query.isActive = true;
        }

        const rates = await ExchangeRate.find(query).sort({ wasteType: 1 });

        res.json({
            rates,
            count: rates.length
        });
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
});

// @desc    Get active category options for request forms
// @route   GET /api/exchange-rates/active-categories
// @access  Protected users
router.get('/active-categories', protect, async (req, res) => {
    try {
        const rates = await ExchangeRate.find({ isActive: true }).sort({ wasteType: 1 });
        const activeWasteTypes = new Set(rates.map((rate) => normalizeWasteType(rate.wasteType)));
        const categories = getSupportedClassOptions()
            .filter((category) => activeWasteTypes.has(normalizeWasteType(category.wasteType)))
            .map((category) => ({
                ...category,
                wasteTypeLabel: formatWasteTypeLabel(category.wasteType)
            }));

        res.json({
            categories,
            count: categories.length
        });
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
});

// @desc    Get single exchange rate
// @route   GET /api/exchange-rates/:id
// @access  Admin only
router.get('/:id', protect, admin, async (req, res) => {
    try {
        const rate = await ExchangeRate.findById(req.params.id);

        if (!rate) {
            return res.status(404).json({ message: 'Exchange rate not found' });
        }

        res.json(rate);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
});

// @desc    Create new exchange rate
// @route   POST /api/exchange-rates
// @access  Admin only
router.post('/', protect, admin, async (req, res) => {
    const { wasteType, ratePerItem, ratePerKg, description, isActive } = req.body;
    const itemRate = ratePerItem ?? ratePerKg;
    const cleanedWasteType = cleanWasteType(wasteType);

    // Validation
    if (!cleanedWasteType || itemRate === undefined) {
        return res.status(400).json({
            message: 'wasteType and ratePerItem are required'
        });
    }

    if (typeof itemRate !== 'number' || itemRate < 0) {
        return res.status(400).json({
            message: 'ratePerItem must be a non-negative number'
        });
    }

    try {
        // Check if waste type already exists
        const existingRate = await findExchangeRateByNormalizedWasteType(ExchangeRate, cleanedWasteType);

        if (existingRate) {
            return res.status(409).json({
                message: `Exchange rate for "${cleanedWasteType}" already exists`
            });
        }

        const newRate = await ExchangeRate.create({
            wasteType: cleanedWasteType,
            ratePerItem: itemRate,
            description: description || '',
            isActive: isActive !== undefined ? isActive : true
        });

        res.status(201).json({
            message: 'Exchange rate created successfully',
            rate: newRate
        });
    } catch (error) {
        res.status(400).json({ message: error.message });
    }
});

// @desc    Update exchange rate
// @route   PUT /api/exchange-rates/:id
// @access  Admin only
router.put('/:id', protect, admin, async (req, res) => {
    try {
        const rate = await ExchangeRate.findById(req.params.id);

        if (!rate) {
            return res.status(404).json({ message: 'Exchange rate not found' });
        }

        // Update allowed fields
        if (req.body.wasteType !== undefined) {
            const wasteType = cleanWasteType(req.body.wasteType);

            if (!wasteType) {
                return res.status(400).json({
                    message: 'wasteType is required'
                });
            }

            const existingRate = await findExchangeRateByNormalizedWasteType(ExchangeRate, wasteType, {
                _id: { $ne: req.params.id }
            });

            if (existingRate) {
                return res.status(409).json({
                    message: `Exchange rate for "${wasteType}" already exists`
                });
            }

            rate.wasteType = wasteType;
        }

        const itemRate = req.body.ratePerItem ?? req.body.ratePerKg;

        if (itemRate !== undefined) {
            if (typeof itemRate !== 'number' || itemRate < 0) {
                return res.status(400).json({
                    message: 'ratePerItem must be a non-negative number'
                });
            }
            rate.ratePerItem = itemRate;
            rate.ratePerKg = undefined;
        }

        if (req.body.description !== undefined) {
            rate.description = req.body.description;
        }

        if (req.body.isActive !== undefined) {
            rate.isActive = req.body.isActive;
        }

        const updatedRate = await rate.save();

        res.json({
            message: 'Exchange rate updated successfully',
            rate: updatedRate
        });
    } catch (error) {
        res.status(400).json({ message: error.message });
    }
});

// @desc    Delete exchange rate
// @route   DELETE /api/exchange-rates/:id
// @access  Admin only
router.delete('/:id', protect, admin, async (req, res) => {
    try {
        const rate = await ExchangeRate.findByIdAndDelete(req.params.id);

        if (!rate) {
            return res.status(404).json({ message: 'Exchange rate not found' });
        }

        res.json({
            message: 'Exchange rate deleted',
            rate
        });
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
});

// @desc    Bulk create/update exchange rates
// @route   POST /api/exchange-rates/bulk
// @access  Admin only
router.post('/bulk/import', protect, admin, async (req, res) => {
    const { rates } = req.body;

    if (!Array.isArray(rates)) {
        return res.status(400).json({
            message: 'rates must be an array'
        });
    }

    try {
        const results = [];

        for (const rateData of rates) {
            const { wasteType, ratePerItem, ratePerKg, description } = rateData;
            const itemRate = ratePerItem ?? ratePerKg;
            const cleanedWasteType = cleanWasteType(wasteType);

            if (!cleanedWasteType || itemRate === undefined) {
                results.push({
                    wasteType: wasteType || 'unknown',
                    status: 'error',
                    message: 'wasteType and ratePerItem required'
                });
                continue;
            }

            if (typeof itemRate !== 'number' || itemRate < 0) {
                results.push({
                    wasteType,
                    status: 'error',
                    message: 'ratePerItem must be a non-negative number'
                });
                continue;
            }

            try {
                let rate = await findExchangeRateByNormalizedWasteType(ExchangeRate, cleanedWasteType);

                if (rate) {
                    // Update existing
                    rate.ratePerItem = itemRate;
                    rate.ratePerKg = undefined;
                    if (description) rate.description = description;
                    rate.isActive = true;
                    await rate.save();

                    results.push({
                        wasteType: cleanedWasteType,
                        status: 'updated',
                        rate
                    });
                } else {
                    // Create new
                    rate = await ExchangeRate.create({
                        wasteType: cleanedWasteType,
                        ratePerItem: itemRate,
                        description: description || '',
                        isActive: true
                    });

                    results.push({
                        wasteType: cleanedWasteType,
                        status: 'created',
                        rate
                    });
                }
            } catch (err) {
                results.push({
                    wasteType,
                    status: 'error',
                    message: err.message
                });
            }
        }

        res.status(201).json({
            message: 'Bulk import completed',
            results
        });
    } catch (error) {
        res.status(400).json({ message: error.message });
    }
});

module.exports = router;
