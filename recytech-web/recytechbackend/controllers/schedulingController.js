const {
    getCollectionForecast,
    getSchedulingRecommendations,
    confirmCollectorAssignments
} = require('../services/schedulingService');

const getForecast = async (req, res) => {
    try {
        const days = parseInt(req.query.days, 10) || 7;
        const forecast = await getCollectionForecast(days);
        res.json(forecast);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

const getRecommendations = async (req, res) => {
    try {
        const recommendations = await getSchedulingRecommendations();
        res.json(recommendations);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

const confirmAssignments = async (req, res) => {
    try {
        const { assignments } = req.body;

        if (!Array.isArray(assignments) || assignments.length === 0) {
            return res.status(400).json({ message: 'No assignments provided.' });
        }

        const confirmationResult = await confirmCollectorAssignments(assignments);
        return res.json(confirmationResult);
    } catch (error) {
        return res.status(500).json({ message: error.message });
    }
};

module.exports = {
    getForecast,
    getRecommendations,
    confirmAssignments
};
