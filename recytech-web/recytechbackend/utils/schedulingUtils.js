const ARIMA = require('arima');
const { normalizeWasteType } = require('./categoryNormalization');

const VEHICLE_CAPACITY = {
    'Truck': 30,
    'E-Trike': 12,
    'Bike': 6
};

const HIGH_VALUE_THRESHOLD = 500;
const MEDIUM_VALUE_THRESHOLD = 200;

function buildRateLookup(exchangeRates = []) {
    return exchangeRates.reduce((lookup, rate) => {
        if (!rate?.wasteType) return lookup;

        lookup[normalizeWasteType(rate.wasteType)] = rate.ratePerItem ?? rate.ratePerKg ?? 0;
        return lookup;
    }, {});
}

function getVehicleCapacity(vehicleType) {
    return VEHICLE_CAPACITY[vehicleType] || 8;
}

function getRequestLoad(request) {
    return request.weight || request.quantity || 1;
}

function getRequestAgeDays(request, now = new Date()) {
    const createdAt = request.createdAt ? new Date(request.createdAt) : now;
    const ageMs = now.getTime() - createdAt.getTime();
    return Math.max(0, Math.floor(ageMs / (1000 * 60 * 60 * 24)));
}

function estimateRequestValue(request, rateLookup) {
    const rate = rateLookup[normalizeWasteType(request.wasteType)] || 0;
    return Math.round(rate * (request.quantity || 1) * 100) / 100;
}

function getPriorityLevel(score) {
    if (score >= 80) return 'Critical';
    if (score >= 60) return 'High';
    if (score >= 35) return 'Medium';
    return 'Standard';
}

function buildPriorityTags({ estimatedValue, ageDays, load }) {
    const tags = [];

    if (estimatedValue >= HIGH_VALUE_THRESHOLD) {
        tags.push('High Value');
    } else if (estimatedValue >= MEDIUM_VALUE_THRESHOLD) {
        tags.push('Valuable');
    }

    if (ageDays >= 3) tags.push('Aging Request');
    if (load >= 10) tags.push('Large Load');

    return tags;
}

function scoreRequestPriority(request, rateLookup, now = new Date()) {
    const load = getRequestLoad(request);
    const estimatedValue = estimateRequestValue(request, rateLookup);
    const ageDays = getRequestAgeDays(request, now);

    const valueScore = Math.min(45, estimatedValue / 20);
    const ageScore = Math.min(30, ageDays * 7);
    const loadScore = Math.min(20, load * 2);
    const pendingBonus = request.status === 'Approved' ? 5 : 0;
    const score = Math.round(valueScore + ageScore + loadScore + pendingBonus);

    return {
        priorityScore: Math.min(100, score),
        priorityLevel: getPriorityLevel(score),
        estimatedValue,
        ageDays,
        load,
        tags: buildPriorityTags({ estimatedValue, ageDays, load })
    };
}

function enrichRequestsWithPriority(requests, exchangeRates = []) {
    const rateLookup = buildRateLookup(exchangeRates);
    const now = new Date();

    return requests
        .map((request) => ({
            ...request,
            priority: scoreRequestPriority(request, rateLookup, now)
        }))
        .sort((a, b) => {
            if (b.priority.priorityScore !== a.priority.priorityScore) {
                return b.priority.priorityScore - a.priority.priorityScore;
            }

            if (b.priority.estimatedValue !== a.priority.estimatedValue) {
                return b.priority.estimatedValue - a.priority.estimatedValue;
            }

            return b.priority.ageDays - a.priority.ageDays;
        });
}

function buildAssignmentReasons(request, collector, requestWeight) {
    const reasons = [];
    const remainingCapacity = Math.max(0, collector.capacity - collector.loadAssigned);
    const projectedUtilization = Math.round(((collector.loadAssigned + requestWeight) / collector.capacity) * 100);

    if (request.priority.estimatedValue >= HIGH_VALUE_THRESHOLD) {
        reasons.push(`High recyclable value estimated at PHP ${request.priority.estimatedValue.toLocaleString()}.`);
    } else if (request.priority.estimatedValue >= MEDIUM_VALUE_THRESHOLD) {
        reasons.push(`Valuable recyclable material estimated at PHP ${request.priority.estimatedValue.toLocaleString()}.`);
    }

    if (request.priority.ageDays >= 3) {
        reasons.push(`Request has been waiting for ${request.priority.ageDays} days.`);
    }

    if (requestWeight <= remainingCapacity) {
        reasons.push(`${collector.collectorName} has enough remaining capacity for this load.`);
    } else {
        reasons.push(`Assigned as overflow because all active collectors are near capacity.`);
    }

    if (projectedUtilization <= 85) {
        reasons.push(`Keeps projected collector utilization at ${projectedUtilization}%.`);
    } else {
        reasons.push(`Uses ${projectedUtilization}% of collector capacity; review before confirming.`);
    }

    return reasons;
}

function flattenAssignedRequests(recommendations) {
    return recommendations.flatMap((collector) =>
        collector.assignedRequests.map((request) => ({
            ...request,
            collectorId: collector.collectorId,
            collectorName: collector.collectorName,
            vehicleType: collector.vehicleType
        }))
    );
}

function buildResourceAllocationSummary(recommendations) {
    const assignedRequests = flattenAssignedRequests(recommendations);
    const totalLoad = recommendations.reduce((sum, item) => sum + item.loadAssigned, 0);
    const totalCapacity = recommendations.reduce((sum, item) => sum + item.capacity, 0);
    const activeCollectors = recommendations.length;
    const highPriorityRequests = assignedRequests.filter((request) =>
        ['Critical', 'High'].includes(request.priorityLevel)
    ).length;
    const totalEstimatedValue = assignedRequests.reduce((sum, request) => sum + (request.estimatedValue || 0), 0);
    const utilizationRate = totalCapacity > 0 ? Math.round((totalLoad / totalCapacity) * 100) : 0;
    const averageCapacity = activeCollectors > 0 ? totalCapacity / activeCollectors : 0;

    return {
        activeCollectors,
        pendingRequests: assignedRequests.length,
        totalLoad,
        totalCapacity,
        utilizationRate,
        highPriorityRequests,
        totalEstimatedValue: Math.round(totalEstimatedValue * 100) / 100,
        suggestedCollectorsNeeded: averageCapacity > 0 ? Math.max(1, Math.ceil(totalLoad / averageCapacity)) : 0
    };
}

function buildActionRecommendations(recommendations) {
    const assignedRequests = flattenAssignedRequests(recommendations);
    const actions = [];
    const highPriority = assignedRequests.filter((request) => ['Critical', 'High'].includes(request.priorityLevel));
    const highValue = [...assignedRequests]
        .filter((request) => request.estimatedValue >= MEDIUM_VALUE_THRESHOLD)
        .sort((a, b) => b.estimatedValue - a.estimatedValue);
    const aging = assignedRequests.filter((request) => request.ageDays >= 3);
    const nearCapacityCollectors = recommendations.filter((collector) =>
        collector.capacity > 0 && collector.loadAssigned / collector.capacity >= 0.85
    );

    if (highPriority.length > 0) {
        actions.push({
            type: 'Schedule Priority Pickups',
            severity: 'High',
            message: `Confirm ${highPriority.length} high-priority pickup(s) first to reduce operational backlog.`,
            metric: `${highPriority.length} urgent`
        });
    }

    if (highValue.length > 0) {
        actions.push({
            type: 'Prioritize Recyclable Value',
            severity: 'Medium',
            message: `Prioritize ${highValue[0].wasteType} from ${highValue[0].residentName}; estimated recyclable value is PHP ${highValue[0].estimatedValue.toLocaleString()}.`,
            metric: `PHP ${highValue[0].estimatedValue.toLocaleString()}`
        });
    }

    if (aging.length > 0) {
        actions.push({
            type: 'Reduce Waiting Time',
            severity: 'Medium',
            message: `${aging.length} request(s) have waited at least 3 days and should be scheduled before newer low-value requests.`,
            metric: `${aging.length} aging`
        });
    }

    if (nearCapacityCollectors.length > 0) {
        actions.push({
            type: 'Review Collector Load',
            severity: 'Medium',
            message: `${nearCapacityCollectors.length} collector(s) are projected above 85% capacity; review before confirming all assignments.`,
            metric: `${nearCapacityCollectors.length} near full`
        });
    }

    if (actions.length === 0) {
        actions.push({
            type: 'Maintain Current Allocation',
            severity: 'Low',
            message: 'No urgent scheduling risks detected. Current collector allocation is balanced for the pending requests.',
            metric: 'Balanced'
        });
    }

    return actions;
}

function buildDailySeries(dailyCounts, startDate, endDate) {
    const series = [];
    const labels = [];
    const countsByDate = dailyCounts.reduce((acc, item) => {
        const dateKey = `${item._id.year}-${String(item._id.month).padStart(2, '0')}-${String(item._id.day).padStart(2, '0')}`;
        acc[dateKey] = item.count;
        return acc;
    }, {});

    const cursor = new Date(startDate);
    while (cursor <= endDate) {
        const dateKey = `${cursor.getFullYear()}-${String(cursor.getMonth() + 1).padStart(2, '0')}-${String(cursor.getDate()).padStart(2, '0')}`;
        labels.push(dateKey);
        series.push(countsByDate[dateKey] || 0);
        cursor.setDate(cursor.getDate() + 1);
    }

    return { series, labels };
}

function normalizePrediction(value) {
    return Math.max(0, Math.round(value));
}

function buildForecast(series, days = 7) {
    if (!Array.isArray(series) || series.length < 10) {
        const average = series.length > 0 ? series.reduce((sum, value) => sum + value, 0) / series.length : 0;
        return Array.from({ length: days }, () => normalizePrediction(average));
    }

    const arima = new ARIMA({ p: 2, d: 1, q: 2, P: 1, D: 1, Q: 1, s: 7, verbose: false }).train(series);
    const [predictions] = arima.predict(days);

    return predictions.map(normalizePrediction);
}

function buildCollectionRecommendations(pendingRequests, collectors, exchangeRates = []) {
    const sortedRequests = enrichRequestsWithPriority(pendingRequests, exchangeRates);

    const recommendations = collectors.map((collector) => ({
        collectorId: collector._id,
        collectorName: `${collector.firstName} ${collector.lastName}`,
        vehicleType: collector.vehicleType,
        capacity: getVehicleCapacity(collector.vehicleType),
        assignedRequests: [],
        loadAssigned: 0
    }));

    if (recommendations.length === 0) {
        return [];
    }

    for (const request of sortedRequests) {
        const requestWeight = request.priority.load;
        recommendations.sort((a, b) => a.loadAssigned / a.capacity - b.loadAssigned / b.capacity);
        const target = recommendations.find((item) => item.loadAssigned + requestWeight <= item.capacity) || recommendations[0];
        const reasons = buildAssignmentReasons(request, target, requestWeight);

        target.assignedRequests.push({
            requestId: request._id,
            residentName: request.residentName,
            wasteType: request.wasteType,
            load: requestWeight,
            priorityScore: request.priority.priorityScore,
            priorityLevel: request.priority.priorityLevel,
            estimatedValue: request.priority.estimatedValue,
            ageDays: request.priority.ageDays,
            tags: request.priority.tags,
            reasons,
            location: request.location?.address || 'Unknown location',
            scheduledAt: request.scheduledAt || null
        });
        target.loadAssigned += requestWeight;
    }

    return recommendations;
}

module.exports = {
    buildDailySeries,
    buildForecast,
    getVehicleCapacity,
    enrichRequestsWithPriority,
    scoreRequestPriority,
    buildActionRecommendations,
    buildResourceAllocationSummary,
    buildCollectionRecommendations
};
