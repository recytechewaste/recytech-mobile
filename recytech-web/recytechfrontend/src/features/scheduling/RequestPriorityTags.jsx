const getPriorityStyles = (level) => {
    if (level === 'Critical' || level === 'High') {
        return { backgroundColor: '#fee2e2', color: '#991b1b' };
    }

    if (level === 'Medium') {
        return { backgroundColor: '#fef3c7', color: '#92400e' };
    }

    return { backgroundColor: '#e5e7eb', color: '#374151' };
};

const pillBaseStyle = {
    padding: '3px 8px',
    borderRadius: '999px',
    fontSize: '11px'
};

const RequestPriorityTags = ({ request }) => (
    <div style={{ display: 'flex', flexWrap: 'wrap', gap: '6px', marginTop: '8px' }}>
        <span
            style={{
                ...pillBaseStyle,
                fontWeight: 600,
                ...getPriorityStyles(request.priorityLevel)
            }}
        >
            {request.priorityLevel || 'Standard'} Priority
        </span>
        <span
            style={{
                ...pillBaseStyle,
                fontWeight: 600,
                backgroundColor: '#ecfdf5',
                color: '#166534'
            }}
        >
            PHP {(request.estimatedValue || 0).toLocaleString()}
        </span>
        <span
            style={{
                ...pillBaseStyle,
                fontWeight: 600,
                backgroundColor: '#eff6ff',
                color: '#1e40af'
            }}
        >
            Score {request.priorityScore || 0}
        </span>
        {(request.tags || []).map((tag) => (
            <span
                key={tag}
                style={{
                    ...pillBaseStyle,
                    backgroundColor: '#f3f4f6',
                    color: '#4b5563'
                }}
            >
                {tag}
            </span>
        ))}
    </div>
);

export default RequestPriorityTags;
