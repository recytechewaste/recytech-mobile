const ExchangeRate = require('../models/ExchangeRate');
const { findActiveExchangeRateByWasteType, normalizeWasteType } = require('./categoryNormalization');

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

        // Payout release must use the request's stored wasteType only. The
        // request creation flow already resolves AI classes to an Exchange Rate
        // Manager category, so payout release should not remap or guess here.
        const exchangeRate = await findActiveExchangeRateByWasteType(ExchangeRate, wasteType);

        if (!exchangeRate) {
            return {
                amount: 0,
                success: false,
                message: 'No active exchange rate found for this waste type.'
            };
        }

        // Current backend request.quantity means item count. Use ratePerItem
        // first; ratePerKg remains supported for existing legacy rates.
        const rateField = Number.isFinite(exchangeRate.ratePerItem)
            ? 'ratePerItem'
            : 'ratePerKg';
        const rate = exchangeRate[rateField];

        if (!Number.isFinite(rate) || rate < 0) {
            return {
                amount: 0,
                success: false,
                message: 'No active exchange rate found for this waste type.'
            };
        }

        // Calculate payout from the live database rate: quantity x active rate.
        const payout = quantity * rate;

        // Round to 2 decimal places (cents)
        const roundedPayout = Math.round(payout * 100) / 100;

        return {
            amount: roundedPayout,
            success: true,
            message: `Payout calculated from Exchange Rate Manager: ${quantity} item(s) x PHP ${rate} = PHP ${roundedPayout}`,
            exchangeRate: rate,
            exchangeRateId: exchangeRate._id,
            rateField,
            wasteType: exchangeRate.wasteType
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
