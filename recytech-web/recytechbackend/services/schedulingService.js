const Request = require('../models/Request');
const Collector = require('../models/Collector');
const ExchangeRate = require('../models/ExchangeRate');
const {
    buildDailySeries,
    buildForecast,
    buildCollectionRecommendations,
    buildActionRecommendations,
    buildResourceAllocationSummary
} = require('../utils/schedulingUtils');

async function getCollectionForecast(days = 7) {
    const end = new Date();
    const start = new Date(end);
    start.setDate(end.getDate() - 90);

    const dailyCounts = await Request.aggregate([
        {
            $match: {
                createdAt: { $gte: start, $lt: end },
                status: { $ne: 'Rejected' }
            }
        },
        {
            $group: {
                _id: {
                    year: { $year: '$createdAt' },
                    month: { $month: '$createdAt' },
                    day: { $dayOfMonth: '$createdAt' }
                },
                count: { $sum: 1 }
            }
        },
        { $sort: { '_id.year': 1, '_id.month': 1, '_id.day': 1 } }
    ]);

    const { series, labels } = buildDailySeries(dailyCounts, start, end);
    const predictions = buildForecast(series, days);
    const forecast = predictions.map((value, index) => {
        const date = new Date(end);
        date.setDate(end.getDate() + index + 1);

        return {
            date: date.toISOString().split('T')[0],
            predictedRequests: value
        };
    });

    return {
        model: 'ARIMA',
        trainingDays: series.length,
        forecastDays: days,
        history: labels.map((date, index) => ({ date, count: series[index] })),
        forecast
    };
}

async function getSchedulingRecommendations() {
    const pendingRequests = await Request.find({
        status: 'Approved',
        assignedCollector: { $exists: false }
    }).lean();

    const [collectors, exchangeRates] = await Promise.all([
        Collector.find({ status: 'Active' }).lean(),
        ExchangeRate.find({ isActive: true }).lean()
    ]);

    const recommendations = buildCollectionRecommendations(pendingRequests, collectors, exchangeRates);

    return {
        totalPendingRequests: pendingRequests.length,
        totalCollectors: collectors.length,
        resourceSummary: buildResourceAllocationSummary(recommendations),
        actionRecommendations: buildActionRecommendations(recommendations),
        recommendations,
        note: 'These are suggested collector assignments based on priority score, estimated recyclable value, request age, load, and vehicle capacity. Review and confirm before scheduling.'
    };
}

async function confirmCollectorAssignments(assignments = []) {
    const results = [];
    const errors = [];

    for (const assignment of assignments) {
        const { requestId, collectorId, scheduledAt } = assignment;

        if (!requestId || !collectorId || !scheduledAt) {
            errors.push({ requestId, error: 'Missing requestId, collectorId, or scheduledAt' });
            continue;
        }

        try {
            const request = await Request.findById(requestId);
            if (!request) {
                errors.push({ requestId, error: 'Request not found' });
                continue;
            }

            if (request.status !== 'Approved') {
                errors.push({ requestId, error: `Request status is ${request.status}, not Approved` });
                continue;
            }

            const collector = await Collector.findById(collectorId);
            if (!collector) {
                errors.push({ requestId, error: 'Collector not found' });
                continue;
            }

            if (collector.status !== 'Active') {
                errors.push({ requestId, error: 'Collector is not active' });
                continue;
            }

            const scheduledDate = new Date(scheduledAt);
            if (Number.isNaN(scheduledDate.getTime())) {
                errors.push({ requestId, error: 'Invalid scheduled date/time' });
                continue;
            }

            const conflictRequest = await Request.findOne({
                _id: { $ne: requestId },
                assignedCollector: collectorId,
                scheduledAt: scheduledDate,
                status: { $in: ['Approved', 'In-Transit'] }
            });

            if (conflictRequest) {
                errors.push({ requestId, error: 'Schedule conflict detected for collector' });
                continue;
            }

            request.assignedCollector = collectorId;
            request.scheduledAt = scheduledDate;
            const updatedRequest = await request.save();

            results.push({
                requestId,
                success: true,
                message: 'Assignment confirmed',
                request: updatedRequest
            });
        } catch (error) {
            errors.push({ requestId, error: error.message });
        }
    }

    return {
        totalProcessed: assignments.length,
        successful: results.length,
        failed: errors.length,
        results,
        errors: errors.length > 0 ? errors : undefined
    };
}

module.exports = {
    getCollectionForecast,
    getSchedulingRecommendations,
    confirmCollectorAssignments
};
