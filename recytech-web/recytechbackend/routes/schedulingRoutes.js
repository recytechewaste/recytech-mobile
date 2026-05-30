const express = require('express');
const router = express.Router();
const { protect, admin } = require('../middleware/authMiddleware');
const {
    getForecast,
    getRecommendations,
    confirmAssignments
} = require('../controllers/schedulingController');

// @desc    Forecast upcoming collection demand using ARIMA
// @route   GET /api/scheduling/forecast
// @access  Admin only
router.get('/forecast', protect, admin, getForecast);

// @desc    Recommend collector assignments for pending approved requests
// @route   GET /api/scheduling/recommendations
// @access  Admin only
router.get('/recommendations', protect, admin, getRecommendations);

// @desc    Confirm and apply collector assignments
// @route   POST /api/scheduling/confirm-assignments
// @access  Admin only
router.post('/confirm-assignments', protect, admin, confirmAssignments);

module.exports = router;
