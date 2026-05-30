const express = require('express');
const router = express.Router();
const User = require('../models/User');
const jwt = require('jsonwebtoken');
const bcrypt = require('bcryptjs');
const axios = require('axios');
const { protect } = require('../middleware/authMiddleware');

// Generate JWT
const generateToken = (id) => {
    return jwt.sign({ id }, process.env.JWT_SECRET, {
        expiresIn: '30d',
    });
};

// Generate 6-digit PIN
const generatePin = () => {
    return Math.floor(100000 + Math.random() * 900000).toString();
};

// Send PIN via Email using MailerSend HTTP API
const sendPinEmail = async (email, firstName, pin) => {
    try {
        const payload = {
            from: {
                email: process.env.MAILERSEND_FROM_EMAIL || 'noreply@trial-k6nxvgwjd98z5q7e.mlsender.net',
                name: 'RecyTech',
            },
            to: [{ email: email }],
            subject: 'RecyTech - Password Reset PIN',
            html: `
                <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
                    <div style="background-color: #10b981; padding: 20px; text-align: center; color: white; border-radius: 8px 8px 0 0;">
                        <h2 style="margin: 0;">RecyTech Password Reset</h2>
                    </div>
                    <div style="padding: 20px; background-color: #f9fafb; border: 1px solid #e5e7eb;">
                        <p>Hi ${firstName},</p>
                        <p>We received a request to reset your password. Use the PIN below to verify your identity:</p>
                        <div style="background-color: #dbeafe; padding: 15px; border-radius: 6px; text-align: center; margin: 20px 0;">
                            <p style="margin: 0; font-size: 24px; font-weight: bold; color: #1e40af; letter-spacing: 2px;">${pin}</p>
                        </div>
                        <p style="color: #6b7280; font-size: 14px;">This PIN will expire in 15 minutes.</p>
                        <p style="color: #6b7280; font-size: 14px;">If you did not request a password reset, please ignore this email.</p>
                    </div>
                    <div style="padding: 15px; background-color: #111827; color: #9ca3af; text-align: center; font-size: 12px; border-radius: 0 0 8px 8px;">
                        <p>© 2025 RecyTech. All rights reserved.</p>
                    </div>
                </div>
            `,
        };

        await axios.post('https://api.mailersend.com/v1/email', payload, {
            headers: {
                Authorization: `Bearer ${process.env.MAILERSEND_API_KEY}`,
                'Content-Type': 'application/json',
            },
        });
        return true;
    } catch (error) {
        console.error('MailerSend Error:', error.response?.data || error.message);
        return false;
    }
};

// @desc    Authenticate a user
// @route   POST /api/auth/login
router.post('/login', async (req, res) => {
    const { email, password, role } = req.body;

    try {
        const user = await User.findOne({ email });

        if (user && (await bcrypt.compare(password, user.password))) {
            // Verify that the selected role matches the user's role in the DB
            if (user.role !== role) {
                return res.status(403).json({ 
                    message: `Access denied. Your account is registered as ${user.role}, not ${role}.` 
                });
            }

            // Check if account is active
            if (user.status === 'Inactive') {
                return res.status(403).json({ 
                    message: 'Account is deactivated. Please contact your Super Admin.' 
                });
            }

            // Update last login timestamp
            user.lastLogin = new Date();
            await user.save();

            res.json({
                _id: user._id,
                firstName: user.firstName,
                lastName: user.lastName,
                email: user.email,
                role: user.role,
                token: generateToken(user._id),
            });
        } else {
            res.status(401).json({ message: 'Invalid email or password' });
        }
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
});

// @desc    Register user (Public)
// @route   POST /api/auth/register
router.post('/register', async (req, res) => {
    const { firstName, lastName, email, password, role } = req.body;

    try {
        if (!firstName || !lastName || !email || !password) {
             return res.status(400).json({ message: 'Please add all fields' });
        }

        const userExists = await User.findOne({ email });

        if (userExists) {
            return res.status(400).json({ message: 'User already exists' });
        }

        // Hash password
        const salt = await bcrypt.genSalt(10);
        const hashedPassword = await bcrypt.hash(password, salt);

        // Create user
        const user = await User.create({
            firstName,
            lastName,
            email,
            password: hashedPassword,
            role: role || 'Staff',
            status: 'Active'
        });

        if (user) {
            res.status(201).json({
                _id: user._id,
                firstName: user.firstName,
                lastName: user.lastName,
                email: user.email,
                role: user.role,
                token: generateToken(user._id),
            });
        } else {
            res.status(400).json({ message: 'Invalid user data' });
        }
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
});

// @desc    Request password reset (sends PIN via email)
// @route   POST /api/auth/forgot-password
router.post('/forgot-password', async (req, res) => {
    const { email } = req.body;

    try {
        if (!email) {
            return res.status(400).json({ message: 'Please provide an email address' });
        }

        const user = await User.findOne({ email });

        if (!user) {
            // Don't reveal if email exists for security
            return res.status(200).json({ message: 'If email exists, a PIN has been sent.' });
        }

        // Generate 6-digit PIN
        const pin = generatePin();
        const pinExpiry = new Date(Date.now() + 15 * 60 * 1000); // 15 minutes

        // Save PIN to database
        user.resetPin = pin;
        user.resetPinExpiry = pinExpiry;
        await user.save();

        // Send email
        const emailSent = await sendPinEmail(email, user.firstName, pin);

        if (!emailSent) {
            return res.status(500).json({ message: 'Failed to send email. Please try again.' });
        }

        res.json({ 
            message: 'Password reset PIN has been sent to your email. Valid for 15 minutes.',
            email: email // Return masked email for display
        });
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
});

// @desc    Verify PIN
// @route   POST /api/auth/verify-pin
router.post('/verify-pin', async (req, res) => {
    const { email, pin } = req.body;

    try {
        if (!email || !pin) {
            return res.status(400).json({ message: 'Please provide email and PIN' });
        }

        const user = await User.findOne({ email });

        if (!user) {
            return res.status(404).json({ message: 'User not found' });
        }

        // Check if PIN matches and not expired
        if (user.resetPin !== pin) {
            return res.status(400).json({ message: 'Invalid PIN' });
        }

        if (new Date() > user.resetPinExpiry) {
            return res.status(400).json({ message: 'PIN has expired. Please request a new one.' });
        }

        // Generate temporary reset token valid for 1 hour
        const resetToken = jwt.sign({ email }, process.env.JWT_SECRET, { expiresIn: '1h' });

        res.json({ 
            message: 'PIN verified successfully',
            resetToken: resetToken,
            email: email
        });
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
});

// @desc    Reset password with token
// @route   POST /api/auth/reset-password
router.post('/reset-password', async (req, res) => {
    const { email, newPassword, confirmPassword, resetToken } = req.body;

    try {
        if (!email || !newPassword || !confirmPassword) {
            return res.status(400).json({ message: 'Please provide all fields' });
        }

        if (newPassword !== confirmPassword) {
            return res.status(400).json({ message: 'Passwords do not match' });
        }

        if (newPassword.length < 6) {
            return res.status(400).json({ message: 'Password must be at least 6 characters' });
        }

        if (!resetToken) {
            return res.status(400).json({ message: 'Reset token is required' });
        }

        let decoded;
        try {
            decoded = jwt.verify(resetToken, process.env.JWT_SECRET);
        } catch (error) {
            return res.status(401).json({ message: 'Invalid or expired reset token' });
        }

        if (decoded.email !== email) {
            return res.status(401).json({ message: 'Reset token does not match the provided email' });
        }

        const user = await User.findOne({ email });

        if (!user) {
            return res.status(404).json({ message: 'User not found' });
        }

        // Hash new password
        const salt = await bcrypt.genSalt(10);
        const hashedPassword = await bcrypt.hash(newPassword, salt);

        // Update password and clear reset fields
        user.password = hashedPassword;
        user.resetPin = null;
        user.resetPinExpiry = null;
        await user.save();

        res.json({ message: 'Password has been reset successfully. You can now login with your new password.' });
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
});

module.exports = router;