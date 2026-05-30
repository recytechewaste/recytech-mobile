const express = require('express');
const router = express.Router();
const Resident = require('../models/Resident');
const Transaction = require('../models/Transaction');
const { protect, admin } = require('../middleware/authMiddleware');

// @desc    Get all residents with wallet balances
// @route   GET /api/residents
// @access  Admin only
router.get('/', protect, admin, async (req, res) => {
    try {
        const page = parseInt(req.query.page) || 1;
        const limit = parseInt(req.query.limit) || 10;
        const skip = (page - 1) * limit;

        const residents = await Resident.find()
            .skip(skip)
            .limit(limit)
            .sort({ totalEarned: -1 });

        const total = await Resident.countDocuments();

        res.json({
            residents,
            pagination: {
                page,
                limit,
                total,
                pages: Math.ceil(total / limit)
            }
        });
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
});

// @desc    Create or reuse a temporary resident profile for mobile simulation
// @route   POST /api/residents/temp
// @access  Admin only
router.post('/temp', protect, admin, async (req, res) => {
    const { firstName, lastName, email, phone, mobileUserId, status, source, isTemporary } = req.body || {};

    if (!firstName || !lastName) {
        return res.status(400).json({ message: 'firstName and lastName are required' });
    }

    try {
        const generatedEmail = email
            ? email.trim().toLowerCase()
            : `temp-${String(phone || `${firstName}-${lastName}-${Date.now()}`)
                .toLowerCase()
                .replace(/[^a-z0-9]+/g, '-')
                .replace(/^-|-$/g, '')}@recytech.local`;

        let resident = await Resident.findOne({ email: generatedEmail });
        let resultStatus = 'existing';

        if (!resident) {
            resident = await Resident.create({
                email: generatedEmail,
                firstName,
                lastName,
                phone,
                mobileUserId,
                status: status || 'Active',
                source: source || 'Mobile Simulation',
                isTemporary: isTemporary !== undefined ? isTemporary : true
            });
            resultStatus = 'created';
        } else {
            resident.firstName = firstName;
            resident.lastName = lastName;
            if (phone !== undefined) resident.phone = phone;
            if (mobileUserId !== undefined) resident.mobileUserId = mobileUserId;
            if (status !== undefined) resident.status = status;
            resident.source = source || resident.source || 'Mobile Simulation';
            resident.isTemporary = isTemporary !== undefined ? isTemporary : true;
            await resident.save();
            resultStatus = 'updated';
        }

        res.status(resultStatus === 'created' ? 201 : 200).json({
            message: `Temporary resident ${resultStatus}`,
            resident
        });
    } catch (error) {
        res.status(400).json({ message: error.message });
    }
});

// @desc    Get single resident with transaction history
// @route   GET /api/residents/:id
// @access  Admin only
router.get('/:id', protect, admin, async (req, res) => {
    try {
        const resident = await Resident.findById(req.params.id);

        if (!resident) {
            return res.status(404).json({ message: 'Resident not found' });
        }

        // Get transaction history
        const transactions = await Transaction.find({ resident: resident._id })
            .populate('requestId', 'wasteType quantity status')
            .sort({ createdAt: -1 });

        res.json({
            ...resident.toObject(),
            transactions
        });
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
});

// @desc    Update resident (status, info)
// @route   PUT /api/residents/:id
// @access  Admin only
router.put('/:id', protect, admin, async (req, res) => {
    try {
        const resident = await Resident.findById(req.params.id);

        if (!resident) {
            return res.status(404).json({ message: 'Resident not found' });
        }

        // Allow updates to these fields only
        if (req.body.email !== undefined) {
            const email = req.body.email.trim().toLowerCase();

            if (!email) {
                return res.status(400).json({ message: 'Email is required' });
            }

            const existingResident = await Resident.findOne({
                email,
                _id: { $ne: req.params.id }
            });

            if (existingResident) {
                return res.status(409).json({ message: 'Resident email already exists' });
            }

            resident.email = email;
        }

        if (req.body.status) resident.status = req.body.status;
        if (req.body.firstName) resident.firstName = req.body.firstName;
        if (req.body.lastName) resident.lastName = req.body.lastName;
        if (req.body.phone) resident.phone = req.body.phone;
        if (req.body.mobileUserId !== undefined) resident.mobileUserId = req.body.mobileUserId;
        if (req.body.isTemporary !== undefined) resident.isTemporary = req.body.isTemporary;
        if (req.body.source) resident.source = req.body.source;
        if (req.body.walletBalance !== undefined) resident.walletBalance = req.body.walletBalance;

        const updatedResident = await resident.save();
        res.json(updatedResident);
    } catch (error) {
        res.status(400).json({ message: error.message });
    }
});

// @desc    Delete resident (mark inactive or hard delete)
// @route   DELETE /api/residents/:id
// @access  Admin only
router.delete('/:id', protect, admin, async (req, res) => {
    try {
        const resident = await Resident.findById(req.params.id);

        if (!resident) {
            return res.status(404).json({ message: 'Resident not found' });
        }

        // Option: Mark as inactive (soft delete)
        const hardDelete = req.query.hardDelete === 'true';

        if (hardDelete) {
            // Hard delete: remove resident and all transactions
            await Transaction.deleteMany({ resident: resident._id });
            await Resident.findByIdAndDelete(req.params.id);
            res.json({ message: 'Resident and transactions permanently deleted' });
        } else {
            // Soft delete: just mark as inactive
            resident.status = 'Inactive';
            await resident.save();
            res.json({ message: 'Resident marked as inactive', resident });
        }
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
});

// @desc    Search residents by email or name
// @route   GET /api/residents/search
// @access  Admin only
router.get('/search/:query', protect, admin, async (req, res) => {
    try {
        const searchQuery = req.params.query;

        const residents = await Resident.find({
            $or: [
                { email: { $regex: searchQuery, $options: 'i' } },
                { firstName: { $regex: searchQuery, $options: 'i' } },
                { lastName: { $regex: searchQuery, $options: 'i' } }
            ]
        }).limit(20);

        res.json(residents);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
});

module.exports = router;
