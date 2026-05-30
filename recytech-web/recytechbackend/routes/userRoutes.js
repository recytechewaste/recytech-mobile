const express = require('express');
const router = express.Router();
const User = require('../models/User');
const Collector = require('../models/Collector');
const bcrypt = require('bcryptjs');
const { protect, superAdmin } = require('../middleware/authMiddleware');

// @desc    Get all users
// @route   GET /api/users
router.get('/', protect, superAdmin, async (req, res) => {
    try {
        const { includeCollectors } = req.query;
        let query = {};

        // If includeCollectors is not explicitly 'true', exclude Collector roles
        if (includeCollectors !== 'true') {
            query = { role: { $ne: 'Collector' } };
        }
        const users = await User.find(query)
            .select('-password')
            .sort({ createdAt: -1 });
        res.json(users);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
});

// @desc    Get single user
// @route   GET /api/users/:id
router.get('/:id', protect, superAdmin, async (req, res) => {
    try {
        const user = await User.findById(req.params.id).select('-password');
        if (user) {
            res.json(user);
        } else {
            res.status(404).json({ message: 'User not found' });
        }
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
});

// @desc    Create a new user
// @route   POST /api/users
router.post('/', protect, superAdmin, async (req, res) => {
    const { firstName, lastName, email, password, role, status } = req.body;

    try {
        if (!firstName || !lastName || !email || !password || !role) {
            return res.status(400).json({ message: 'Please enter all required fields: First Name, Last Name, Email, Password, Role' });
        }

        const userExists = await User.findOne({ email });
        if (userExists) {
            return res.status(400).json({ message: 'User with that email already exists' });
        }

        const salt = await bcrypt.genSalt(10);
        const hashedPassword = await bcrypt.hash(password, salt);

        const user = await User.create({ firstName, lastName, email, password: hashedPassword, role, status: status || 'Active' });

        if (user) {
            res.status(201).json({
                _id: user._id,
                firstName: user.firstName,
                lastName: user.lastName,
                email: user.email,
                role: user.role,
                status: user.status
            });
        } else {
            res.status(400).json({ message: 'Invalid user data' });
        }
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
});

// @desc    Update user
// @route   PUT /api/users/:id
router.put('/:id', protect, superAdmin, async (req, res) => {
    const { firstName, lastName, email, password, role, status } = req.body;

    try {
        const user = await User.findById(req.params.id);

        if (user) {
            // Check if the email is being changed to an existing email
            if (email && email !== user.email) {
                const emailExists = await User.findOne({ email });
                if (emailExists && emailExists._id.toString() !== req.params.id) {
                    return res.status(400).json({ message: 'Email already in use by another user' });
                }
            }

            user.firstName = firstName || user.firstName;
            user.lastName = lastName || user.lastName;
            user.email = email || user.email;
            user.role = role || user.role;
            user.status = status || user.status;

            // Remove mobile field if it exists in the request body, as it's being deprecated
            // if (req.body.mobile !== undefined) user.mobile = undefined; // Or handle explicitly

            if (req.body.password) {
                const salt = await bcrypt.genSalt(10);
                user.password = await bcrypt.hash(req.body.password, salt);
            }

            const updatedUser = await user.save();
            res.status(200).json({
                _id: updatedUser._id,
                firstName: updatedUser.firstName,
                lastName: updatedUser.lastName,
                email: updatedUser.email,
                role: updatedUser.role,
                status: updatedUser.status
            });
        } else {
            res.status(404).json({ message: 'User not found' });
        }
    } catch (error) {
        res.status(400).json({ message: error.message });
    }
});

// @desc    Delete a user
// @route   DELETE /api/users/:id
router.delete('/:id', protect, superAdmin, async (req, res) => {
    try {
        const user = await User.findById(req.params.id);
        if (!user) {
            return res.status(404).json({ message: 'User not found' });
        }
        
        await user.deleteOne();
        
        res.json({ message: 'User removed' });
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
});

module.exports = router;
