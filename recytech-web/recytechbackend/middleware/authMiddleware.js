const jwt = require('jsonwebtoken');
const User = require('../models/User');
const Resident = require('../models/Resident');

const protect = async (req, res, next) => {
    let token;

    if (
        req.headers.authorization &&
        req.headers.authorization.startsWith('Bearer')
    ) {
        try {
            // Get token from header
            token = req.headers.authorization.split(' ')[1];

            // Verify token
            const decoded = jwt.verify(token, process.env.JWT_SECRET);

            // Get account from the token. Admin/staff/collector accounts live in
            // User, while mobile resident accounts live in Resident.
            const user = await User.findById(decoded.id).select('-password');

            if (user) {
                req.user = user;
                return next();
            }

            const resident = await Resident.findById(decoded.id).select('-password');

            if (resident) {
                req.user = {
                    ...resident.toObject(),
                    role: 'resident'
                };
                req.resident = resident;
                return next();
            }

            return res.status(401).json({ message: 'Not authorized, account not found' });
        } catch (error) {
            console.error(error);
            return res.status(401).json({ message: 'Not authorized, token failed' });
        }
    }

    if (!token) {
        res.status(401).json({ message: 'Not authorized, no token' });
    }
};

const admin = (req, res, next) => {
    if (req.user && (req.user.role === 'Admin' || req.user.role === 'Super Admin')) {
        next();
    } else {
        res.status(403).json({ message: 'Not authorized as an admin' });
    }
};

const superAdmin = (req, res, next) => {
    if (req.user && req.user.role === 'Super Admin') {
        next();
    } else {
        res.status(403).json({ message: 'Not authorized as a super admin' });
    }
};

module.exports = { protect, admin, superAdmin };
