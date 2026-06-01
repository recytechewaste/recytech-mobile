const express = require('express');
const router = express.Router();
const Request = require('../models/Request');
const Resident = require('../models/Resident');
const Transaction = require('../models/Transaction');
const ExchangeRate = require('../models/ExchangeRate');
const { calculatePayoutAmount } = require('../utils/calculatePayout');
const { resolveSubmittedCategory } = require('../utils/categoryNormalization');
const { protect, admin } = require('../middleware/authMiddleware');

const splitResidentName = (name = '') => {
    const parts = name.trim().split(/\s+/).filter(Boolean);

    return {
        firstName: parts[0] || 'Temporary',
        lastName: parts.slice(1).join(' ') || 'Resident'
    };
};

const buildTemporaryEmail = ({ residentEmail, phone, residentName }) => {
    if (residentEmail) return residentEmail.trim().toLowerCase();

    const phoneDigits = String(phone || '').replace(/\D/g, '');
    if (phoneDigits) return `temp-${phoneDigits}@recytech.local`;

    const nameSlug = String(residentName || 'resident')
        .trim()
        .toLowerCase()
        .replace(/[^a-z0-9]+/g, '-')
        .replace(/^-|-$/g, '') || 'resident';

    return `temp-${nameSlug}-${Date.now()}@recytech.local`;
};

const findOrCreateTemporaryResident = async ({ residentName, residentEmail, phone, firstName, lastName, mobileUserId }) => {
    const email = buildTemporaryEmail({ residentEmail, phone, residentName });
    const parsedName = splitResidentName(residentName);

    let resident = await Resident.findOne({ email });

    if (!resident) {
        resident = await Resident.create({
            email,
            firstName: firstName || parsedName.firstName,
            lastName: lastName || parsedName.lastName,
            phone,
            mobileUserId,
            source: 'Mobile Simulation',
            isTemporary: true
        });
    } else {
        if (firstName && !resident.firstName) resident.firstName = firstName;
        if (lastName && !resident.lastName) resident.lastName = lastName;
        if (phone && !resident.phone) resident.phone = phone;
        if (mobileUserId && !resident.mobileUserId) resident.mobileUserId = mobileUserId;
    }

    resident.requestCount += 1;
    await resident.save();

    return resident;
};

const activePickupStatuses = ['Pending', 'Approved', 'Assigned', 'In-Transit'];
const payoutReadyStatuses = ['Drop-off Confirmed', 'Received'];

const populateRequest = (query) => query
    .populate('resident', 'email firstName lastName phone walletBalance totalEarned requestCount isTemporary source mobileUserId')
    .populate('assignedCollector', 'firstName lastName phone vehicleType vehiclePlate');

const residentDisplayName = (resident) => {
    if (!resident) return '';
    return [resident.firstName, resident.lastName]
        .filter((part) => String(part || '').trim())
        .join(' ')
        .trim();
};

const resolveResidentForRequest = async (request) => {
    let resident = request.resident
        ? await Resident.findById(request.resident)
        : null;

    if (!resident && request.residentEmail) {
        resident = await Resident.findOne({ email: request.residentEmail });
    }

    if (!resident) {
        const residentEmail = request.residentEmail || `temp-request-${request._id}@recytech.local`;
        const parsedName = splitResidentName(request.residentName);

        resident = await Resident.create({
            email: residentEmail,
            firstName: parsedName.firstName,
            lastName: parsedName.lastName,
            source: 'Mobile Simulation',
            isTemporary: true
        });
    }

    return resident;
};

const buildCurrentResidentRequestQuery = (account = {}) => {
    const clauses = [];
    const accountId = account._id?.toString();
    const email = String(account.email || '').trim().toLowerCase();
    const mobileUserId = String(account.mobileUserId || '').trim();

    if (accountId) {
        clauses.push({ resident: accountId });
        clauses.push({ mobileUserId: accountId });
    }

    if (email) {
        clauses.push({ residentEmail: email });
    }

    if (mobileUserId) {
        clauses.push({ mobileUserId });
    }

    return clauses.length ? { $or: clauses } : { _id: null };
};

const releasePayoutForRequest = async (request) => {
    if (request.paymentProcessed) {
        const existingTransaction = await Transaction.findOne({ requestId: request._id })
            .populate('resident', 'email firstName lastName walletBalance totalEarned');

        return {
            request,
            transaction: existingTransaction,
            alreadyReleased: true
        };
    }

    if (!payoutReadyStatuses.includes(request.status)) {
        const error = new Error('Drop-off must be confirmed before releasing payout.');
        error.statusCode = 400;
        throw error;
    }

    const quantity = request.quantity || 1;
    const payoutResult = await calculatePayoutAmount(request.wasteType, quantity);

    if (!payoutResult.success) {
        request.payoutStatus = 'Failed';
        await request.save();

        const error = new Error(payoutResult.message || 'Unable to calculate payout.');
        error.statusCode = 400;
        throw error;
    }

    const resident = await resolveResidentForRequest(request);
    const amount = payoutResult.amount;
    const releasedAt = new Date();

    resident.walletBalance += amount;
    resident.totalEarned += amount;
    await resident.save();

    const transaction = await Transaction.create({
        resident: resident._id,
        type: 'Payment',
        amount,
        requestId: request._id,
        description: `Monetary payout for ${quantity} ${request.wasteType} recycling item(s)`,
        status: 'Released',
        residentEmail: resident.email,
        residentName: residentDisplayName(resident) || request.residentName,
        wasteType: request.wasteType,
        quantity,
        releasedAt
    });

    request.monetaryValue = amount;
    request.paymentProcessed = true;
    request.payoutStatus = 'Released';
    request.payoutReleasedAt = releasedAt;
    request.status = 'Completed';
    request.resident = resident._id;
    request.residentEmail = resident.email;

    await request.save();

    return {
        request,
        transaction,
        payout: {
            amount,
            resident: resident.email,
            transactionId: transaction._id,
            message: payoutResult.message
        }
    };
};

// @desc    Get all requests (For the Dashboard Table)
// @route   GET /api/requests
router.get('/', protect, async (req, res) => {
    try {
        const requests = await populateRequest(Request.find())
            .sort({ createdAt: -1 }); // Newest first
        res.json(requests);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
});

// @desc    Create a pickup request
// @route   POST /api/requests
router.post('/', protect, async (req, res) => {
    const { residentName, wasteType, location, quantity, residentEmail, wasteImage, phone, firstName, lastName, mobileUserId } = req.body;
    try {
        const categoryResolution = await resolveSubmittedCategory(ExchangeRate, wasteType);

        if (!wasteType || typeof wasteType !== 'string' || categoryResolution.error === 'missing') {
            return res.status(400).json({ message: 'wasteType is required' });
        }

        if (categoryResolution.error === 'unsupported-class') {
            return res.status(400).json({
                message: `Unsupported e-waste class: ${categoryResolution.normalizedClass}. Please select a valid e-waste item.`
            });
        }

        if (categoryResolution.error === 'inactive-rate' || !categoryResolution.exchangeRate) {
            return res.status(400).json({
                message: `No active exchange rate found for waste type: ${categoryResolution.wasteType}. Please activate it in Exchange Rate Manager.`
            });
        }

        const exchangeRate = categoryResolution.exchangeRate;
        const resident = await findOrCreateTemporaryResident({
            residentName,
            residentEmail,
            phone,
            firstName,
            lastName,
            mobileUserId
        });
        const displayName = residentName || `${resident.firstName || ''} ${resident.lastName || ''}`.trim();

        const request = await Request.create({
            residentName: displayName,
            resident: resident._id,
            wasteType: exchangeRate.wasteType,
            itemCategory: categoryResolution.itemCategory,
            detectedClass: wasteType.trim(),
            ratePerItem: exchangeRate.ratePerItem,
            ratePerKg: exchangeRate.ratePerKg,
            location,
            quantity: quantity || 1,
            residentEmail: resident.email,
            mobileUserId,
            wasteImage
        });
        res.status(201).json(request);
    } catch (error) {
        res.status(400).json({ message: error.message });
    }
});

// @desc    Get requests for the logged-in mobile resident
// @route   GET /api/requests/me
router.get('/me', protect, async (req, res) => {
    try {
        const query = buildCurrentResidentRequestQuery(req.user);
        const requests = await populateRequest(Request.find(query))
            .sort({ createdAt: -1 });

        res.json(requests);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
});

// @desc    Update request status/assignment without releasing payout
// @route   PUT /api/requests/:id
// @access  Protected (Staff, Admin, Super Admin)
router.put('/:id', protect, async (req, res) => {
    try {
        const request = await Request.findById(req.params.id);

        if (request) {
            const newStatus = req.body.status || request.status;
            const newAssignedCollector = req.body.assignedCollector || request.assignedCollector;
            const newScheduledAt = req.body.scheduledAt ? new Date(req.body.scheduledAt) : request.scheduledAt;

            if (req.body.scheduledAt && isNaN(newScheduledAt.getTime())) {
                return res.status(400).json({ message: 'Invalid scheduled date/time provided.' });
            }

            if (newStatus === 'Approved' && newAssignedCollector && !newScheduledAt) {
                return res.status(400).json({ message: 'A scheduled date and time is required when approving a request and assigning a collector.' });
            }

            if (newAssignedCollector && newScheduledAt) {
                const conflictRequest = await Request.findOne({
                    _id: { $ne: request._id },
                    assignedCollector: newAssignedCollector,
                    scheduledAt: newScheduledAt,
                    status: { $in: activePickupStatuses }
                });

                if (conflictRequest) {
                    return res.status(400).json({ message: 'Schedule conflict detected: the selected collector already has another pickup at the same date and time.' });
                }
            }

            // Standard update (no payout processing)
            request.status = newStatus;
            request.assignedCollector = newAssignedCollector;
            request.scheduledAt = newScheduledAt;

            if (newStatus === 'Collected' && request.payoutStatus === 'Not Ready') {
                request.payoutStatus = 'Not Ready';
            }

            if (newStatus === 'Drop-off Confirmed' || newStatus === 'Received') {
                request.dropoffConfirmedAt = request.dropoffConfirmedAt || new Date();
                if (!request.paymentProcessed) request.payoutStatus = 'Pending';
            }
            
            const updatedRequest = await request.save();
            const populatedRequest = await populateRequest(Request.findById(updatedRequest._id));
            res.json(populatedRequest);
        } else {
            res.status(404).json({ message: 'Request not found' });
        }
    } catch (error) {
        res.status(400).json({ message: error.message });
    }
});

// @desc    Confirm that collected e-waste reached the drop-off/recycling point
// @route   PUT /api/requests/:id/dropoff-confirmed
// @access  Protected (Admin)
router.put('/:id/dropoff-confirmed', protect, admin, async (req, res) => {
    try {
        const request = await Request.findById(req.params.id);

        if (!request) {
            return res.status(404).json({ message: 'Request not found' });
        }

        if (request.paymentProcessed) {
            return res.status(400).json({ message: 'Payout has already been released for this request.' });
        }

        if (!['Collected', 'Drop-off Confirmed', 'Received'].includes(request.status)) {
            return res.status(400).json({ message: 'Only collected requests can be confirmed at drop-off.' });
        }

        request.status = 'Drop-off Confirmed';
        request.dropoffConfirmedAt = request.dropoffConfirmedAt || new Date();
        request.payoutStatus = 'Pending';

        const updatedRequest = await request.save();
        const populatedRequest = await populateRequest(Request.findById(updatedRequest._id));

        res.json(populatedRequest);
    } catch (error) {
        res.status(400).json({ message: error.message });
    }
});

// @desc    Release monetary payout after drop-off confirmation
// @route   PUT /api/requests/:id/release-payout
// @access  Protected (Admin)
router.put('/:id/release-payout', protect, admin, async (req, res) => {
    try {
        const request = await Request.findById(req.params.id);

        if (!request) {
            return res.status(404).json({ message: 'Request not found' });
        }

        const result = await releasePayoutForRequest(request);
        const populatedRequest = await populateRequest(Request.findById(result.request._id));
        const transaction = result.transaction
            ? await Transaction.findById(result.transaction._id)
                .populate('resident', 'email firstName lastName walletBalance totalEarned')
                .populate('requestId', 'wasteType quantity status monetaryValue paymentProcessed payoutStatus')
            : null;

        res.json({
            request: populatedRequest,
            transaction,
            payout: result.payout,
            alreadyReleased: result.alreadyReleased || false
        });
    } catch (error) {
        res.status(error.statusCode || 400).json({ message: error.message });
    }
});

// @desc    Delete a request
// @route   DELETE /api/requests/:id
// @access  Protected (Admin, Super Admin)
router.delete('/:id', protect, admin, async (req, res) => {
    try {
        const request = await Request.findByIdAndDelete(req.params.id);
        if (request) {
            res.json({ message: 'Request removed' });
        } else {
            res.status(404).json({ message: 'Request not found' });
        }
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
});

// @desc    Get payout info for a single request
// @route   GET /api/requests/:id/payout
// @access  Protected (Admin)
router.get('/:id/payout', protect, admin, async (req, res) => {
    try {
        const request = await populateRequest(Request.findById(req.params.id));
        
        if (!request) {
            return res.status(404).json({ message: 'Request not found' });
        }
        
        // Calculate estimated payout
        const quantity = request.quantity || 1;
        const payoutResult = await calculatePayoutAmount(request.wasteType, quantity);
        
        res.json({
            requestId: request._id,
            status: request.status,
            wasteType: request.wasteType,
            quantity,
            estimatedPayout: payoutResult.amount,
            actualPayout: request.monetaryValue,
            payoutStatus: request.payoutStatus,
            paymentProcessed: request.paymentProcessed,
            dropoffConfirmedAt: request.dropoffConfirmedAt,
            payoutReleasedAt: request.payoutReleasedAt,
            residentEmail: request.residentEmail,
            message: payoutResult.message
        });
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
});

// @desc    Get all drop-off confirmed requests awaiting payout
// @route   GET /api/requests/pending-payouts
// @access  Protected (Admin)
router.get('/pending-payouts', protect, admin, async (req, res) => {
    try {
        const pendingPayouts = await Request.find({
            status: { $in: payoutReadyStatuses },
            paymentProcessed: false
        })
        .populate('resident', 'email firstName lastName phone walletBalance totalEarned')
        .populate('assignedCollector', 'firstName lastName')
        .sort({ updatedAt: -1 });
        
        res.json(pendingPayouts);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
});

module.exports = router;
