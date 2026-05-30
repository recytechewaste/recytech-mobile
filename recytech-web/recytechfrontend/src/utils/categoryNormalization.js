export const normalizeCategory = (value = '') =>
    String(value || '')
        .trim()
        .toLowerCase()
        .replace(/[_-]+/g, ' ')
        .replace(/\s+/g, ' ');

export const cleanCategory = (value = '') =>
    String(value || '')
        .trim()
        .replace(/[_-]+/g, ' ')
        .replace(/\s+/g, ' ');

export const formatCategoryLabel = (value = '') =>
    cleanCategory(value)
        .split(' ')
        .filter(Boolean)
        .map((word) => {
            if (word.toUpperCase() === 'PCB') return 'PCB';
            return `${word.charAt(0).toUpperCase()}${word.slice(1).toLowerCase()}`;
        })
        .join(' ');
