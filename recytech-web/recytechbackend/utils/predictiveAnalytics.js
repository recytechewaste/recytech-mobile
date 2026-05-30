// Simple predictive analytics utilities
// No external dependencies required

/**
 * Calculate linear regression for trend forecasting
 * @param {Array} dataPoints - Array of {x, y} objects
 * @returns {Object} - slope, intercept, rSquared, predict function
 */
function linearRegression(dataPoints) {
    const n = dataPoints.length;
    if (n < 2) return { slope: 0, intercept: 0, rSquared: 0, predict: () => 0 };

    const sumX = dataPoints.reduce((sum, point) => sum + point.x, 0);
    const sumY = dataPoints.reduce((sum, point) => sum + point.y, 0);
    const sumXY = dataPoints.reduce((sum, point) => sum + point.x * point.y, 0);
    const sumXX = dataPoints.reduce((sum, point) => sum + point.x * point.x, 0);
    const sumYY = dataPoints.reduce((sum, point) => sum + point.y * point.y, 0);

    const slope = (n * sumXY - sumX * sumY) / (n * sumXX - sumX * sumX);
    const intercept = (sumY - slope * sumX) / n;

    // Calculate R-squared
    const yMean = sumY / n;
    const ssRes = dataPoints.reduce((sum, point) => {
        const predicted = slope * point.x + intercept;
        return sum + Math.pow(point.y - predicted, 2);
    }, 0);
    const ssTot = dataPoints.reduce((sum, point) => sum + Math.pow(point.y - yMean, 2), 0);
    const rSquared = ssTot === 0 ? 1 : 1 - (ssRes / ssTot);

    return {
        slope,
        intercept,
        rSquared,
        predict: (x) => slope * x + intercept
    };
}

/**
 * Calculate Pearson correlation coefficient
 * @param {Array} x - First dataset
 * @param {Array} y - Second dataset
 * @returns {number} - Correlation coefficient (-1 to 1)
 */
function pearsonCorrelation(x, y) {
    if (x.length !== y.length || x.length < 2) return 0;

    const n = x.length;
    const sumX = x.reduce((a, b) => a + b, 0);
    const sumY = y.reduce((a, b) => a + b, 0);
    const sumXY = x.reduce((sum, xi, i) => sum + xi * y[i], 0);
    const sumXX = x.reduce((sum, xi) => sum + xi * xi, 0);
    const sumYY = y.reduce((sum, yi) => sum + yi * yi, 0);

    const numerator = n * sumXY - sumX * sumY;
    const denominator = Math.sqrt((n * sumXX - sumX * sumX) * (n * sumYY - sumY * sumY));

    return denominator === 0 ? 0 : numerator / denominator;
}

/**
 * Calculate moving average for smoothing
 * @param {Array} data - Array of numbers
 * @param {number} window - Window size
 * @returns {Array} - Smoothed data
 */
function movingAverage(data, window = 3) {
    if (data.length < window) return data;

    const result = [];
    for (let i = 0; i < data.length; i++) {
        const start = Math.max(0, i - window + 1);
        const end = i + 1;
        const slice = data.slice(start, end);
        const avg = slice.reduce((a, b) => a + b, 0) / slice.length;
        result.push(avg);
    }
    return result;
}

/**
 * Detect seasonal patterns (simplified)
 * @param {Array} data - Time series data
 * @param {number} period - Seasonal period (e.g., 12 for monthly)
 * @returns {Object} - seasonal indices and trend
 */
function seasonalDecomposition(data, period = 12) {
    if (data.length < period * 2) return { seasonal: [], trend: data, remainder: [] };

    // Calculate trend using moving average
    const trend = movingAverage(data, period);

    // Calculate seasonal indices
    const seasonalIndices = new Array(period).fill(0);
    const counts = new Array(period).fill(0);

    for (let i = 0; i < data.length; i++) {
        const seasonalIndex = i % period;
        seasonalIndices[seasonalIndex] += data[i] - trend[Math.min(i, trend.length - 1)];
        counts[seasonalIndex]++;
    }

    // Average the seasonal indices
    for (let i = 0; i < period; i++) {
        seasonalIndices[i] = counts[i] > 0 ? seasonalIndices[i] / counts[i] : 0;
    }

    // Calculate remainder
    const remainder = data.map((value, i) => {
        const seasonalValue = seasonalIndices[i % period];
        const trendValue = trend[Math.min(i, trend.length - 1)];
        return value - trendValue - seasonalValue;
    });

    return { seasonal: seasonalIndices, trend, remainder };
}

/**
 * Calculate statistical indicators
 * @param {Array} data - Dataset
 * @returns {Object} - mean, stdDev, min, max, quartiles
 */
function statisticalSummary(data) {
    if (data.length === 0) return { mean: 0, stdDev: 0, min: 0, max: 0, q1: 0, q3: 0 };

    const sorted = [...data].sort((a, b) => a - b);
    const mean = data.reduce((a, b) => a + b, 0) / data.length;
    const variance = data.reduce((sum, value) => sum + Math.pow(value - mean, 2), 0) / data.length;
    const stdDev = Math.sqrt(variance);

    const q1Index = Math.floor(sorted.length * 0.25);
    const q3Index = Math.floor(sorted.length * 0.75);

    return {
        mean,
        stdDev,
        min: sorted[0],
        max: sorted[sorted.length - 1],
        q1: sorted[q1Index],
        q3: sorted[q3Index]
    };
}

/**
 * Detect outliers using IQR method
 * @param {Array} data - Dataset
 * @returns {Array} - Indices of outlier values
 */
function detectOutliers(data) {
    const stats = statisticalSummary(data);
    const iqr = stats.q3 - stats.q1;
    const lowerBound = stats.q1 - 1.5 * iqr;
    const upperBound = stats.q3 + 1.5 * iqr;

    const outliers = [];
    data.forEach((value, index) => {
        if (value < lowerBound || value > upperBound) {
            outliers.push(index);
        }
    });

    return outliers;
}

module.exports = {
    linearRegression,
    pearsonCorrelation,
    movingAverage,
    seasonalDecomposition,
    statisticalSummary,
    detectOutliers
};