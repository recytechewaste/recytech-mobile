const normalizeWasteType = (value = '') => {
    return String(value || '')
        .trim()
        .toLowerCase()
        .replace(/[_-]+/g, ' ')
        .replace(/\s+/g, ' ');
};

const cleanWasteType = (value = '') => {
    return String(value || '')
        .trim()
        .replace(/[_-]+/g, ' ')
        .replace(/\s+/g, ' ');
};

const formatWasteTypeLabel = (value = '') => {
    const cleaned = cleanWasteType(value);

    return cleaned
        .split(' ')
        .filter(Boolean)
        .map((word) => {
            if (word.toUpperCase() === 'PCB') return 'PCB';
            return word.charAt(0).toUpperCase() + word.slice(1).toLowerCase();
        })
        .join(' ');
};

const CLASS_TO_WASTE_TYPE = Object.freeze({
    monitor: 'Screen & Monitors',
    screen: 'Screen & Monitors',
    television: 'Screen & Monitors',
    tv: 'Screen & Monitors',
    smartphone: 'IT & Telecommunications',
    'mobile phone': 'IT & Telecommunications',
    phone: 'IT & Telecommunications',
    laptop: 'IT & Telecommunications',
    printer: 'Consumer Electronics',
    pcb: 'Consumer Electronics',
    'circuit board': 'Consumer Electronics',
    battery: 'Batteries & Power Cells',
    'light bulb': 'Lighting Equipment',
    lamp: 'Lighting Equipment',
    'led light': 'Lighting Equipment',
    keyboard: 'Cables & Accessories',
    mouse: 'Cables & Accessories',
    cable: 'Cables & Accessories',
    charger: 'Cables & Accessories',
    fan: 'Small Appliances',
    microwave: 'Small Appliances',
    oven: 'Small Appliances',
    'washing machine': 'Large Appliances',
    refrigerator: 'Large Appliances',
    'air conditioner': 'Large Appliances'
});

const getMappedWasteType = (value = '') => {
    return CLASS_TO_WASTE_TYPE[normalizeWasteType(value)] || null;
};

const getSupportedClassOptions = () => {
    return Object.entries(CLASS_TO_WASTE_TYPE).map(([itemClass, wasteType]) => ({
        value: itemClass,
        label: formatWasteTypeLabel(itemClass),
        normalized: itemClass,
        wasteType
    }));
};

const findExchangeRateByNormalizedWasteType = async (ExchangeRate, wasteType, query = {}) => {
    const normalizedWasteType = normalizeWasteType(wasteType);

    if (!normalizedWasteType) return null;

    const rates = await ExchangeRate.find(query);
    return rates.find((rate) => normalizeWasteType(rate.wasteType) === normalizedWasteType) || null;
};

const findActiveExchangeRateByWasteType = (ExchangeRate, wasteType) => {
    return findExchangeRateByNormalizedWasteType(ExchangeRate, wasteType, { isActive: true });
};

const resolveSubmittedCategory = async (ExchangeRate, submittedCategory) => {
    const normalizedClass = normalizeWasteType(submittedCategory);

    if (!normalizedClass) {
        return {
            normalizedClass,
            itemCategory: '',
            wasteType: null,
            exchangeRate: null,
            error: 'missing'
        };
    }

    const mappedWasteType = getMappedWasteType(normalizedClass);

    if (mappedWasteType) {
        const exchangeRate = await findActiveExchangeRateByWasteType(ExchangeRate, mappedWasteType);

        return {
            normalizedClass,
            itemCategory: normalizedClass,
            wasteType: mappedWasteType,
            exchangeRate,
            error: exchangeRate ? null : 'inactive-rate'
        };
    }

    const directExchangeRate = await findActiveExchangeRateByWasteType(ExchangeRate, normalizedClass);

    if (directExchangeRate) {
        return {
            normalizedClass,
            itemCategory: normalizedClass,
            wasteType: directExchangeRate.wasteType,
            exchangeRate: directExchangeRate,
            error: null
        };
    }

    return {
        normalizedClass,
        itemCategory: normalizedClass,
        wasteType: null,
        exchangeRate: null,
        error: 'unsupported-class'
    };
};

module.exports = {
    CLASS_TO_WASTE_TYPE,
    cleanWasteType,
    findActiveExchangeRateByWasteType,
    findExchangeRateByNormalizedWasteType,
    formatWasteTypeLabel,
    getMappedWasteType,
    getSupportedClassOptions,
    normalizeWasteType,
    resolveSubmittedCategory
};
