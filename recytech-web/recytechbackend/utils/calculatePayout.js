const ExchangeRate = require('../models/ExchangeRate');
const { normalizeWasteType, resolveSubmittedCategory } = require('./categoryNormalization');

/**
 * Calculate payout amount based on waste type and quantity
 * @param {string} wasteType - Type of waste (e.g., "Electronics", "Battery")
 * @param {number} quantity - Number of items/units
 * @returns {object} { amount: number, success: boolean, message: string }
 */
async function calculatePayoutAmount(wasteType, quantity = 1) {
    try {
        // Validate inputs
        const normalizedWasteType = normalizeWasteType(wasteType);

        if (!wasteType || typeof wasteType !== 'string' || !normalizedWasteType) {
            return {
                amount: 0,
                success: false,
                message: 'Invalid waste type provided'
            };
        }

        if (!Number.isFinite(quantity) || quantity < 1) {
            return {
                amount: 0,
                success: false,
                message: 'Invalid quantity provided'
            };
        }

        // Find exchange rate for this waste type or mapped e-waste class.
        const categoryResolution = await resolveSubmittedCategory(ExchangeRate, wasteType);
        const exchangeRate = categoryResolution.exchangeRate;

        if (!exchangeRate) {
            const message = categoryResolution.error === 'unsupported-class'
                ? `Unsupported e-waste class: ${normalizedWasteType}. Please select a valid e-waste item.`
                : `No active exchange rate found for waste type: ${categoryResolution.wasteType || normalizedWasteType}. Please activate it in Exchange Rate Manager.`;

            return {
                amount: 0,
                success: false,
                message
            };
        }

        const rate = exchangeRate.ratePerItem ?? exchangeRate.ratePerKg;

        if (!Number.isFinite(rate) || rate < 0) {
            return {
                amount: 0,
                success: false,
                message: `No valid item rate found for waste type: ${wasteType}`
            };
        }

        // Calculate payout: quantity x rate per item
        const payout = quantity * rate;

        // Round to 2 decimal places (cents)
        const roundedPayout = Math.round(payout * 100) / 100;

        return {
            amount: roundedPayout,
            success: true,
            message: `Payout calculated: ${quantity} item(s) x PHP ${rate}/item = PHP ${roundedPayout}`,
            exchangeRate: rate
        };
    } catch (error) {
        console.error('Error calculating payout:', error);
        return {
            amount: 0,
            success: false,
            message: `Error calculating payout: ${error.message}`
        };
    }
}

module.exports = {
    calculatePayoutAmount
};
