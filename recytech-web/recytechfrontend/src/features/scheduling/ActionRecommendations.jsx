import styles from '../../styles/Dashboard.module.css';

const getSeverityBorder = (severity) => {
    if (severity === 'High') return '4px solid #dc2626';
    if (severity === 'Medium') return '4px solid #d97706';
    return '4px solid #16a34a';
};

const ActionRecommendations = ({ actions, loading }) => (
    <div className={styles.chartCard}>
        <h3 className={styles.cardTitle}>AI Action Recommendations</h3>
        <span className={styles.chartSub}>Prescriptive actions generated from priority, value, age, and capacity signals</span>
        {loading ? (
            <p>Loading recommendations...</p>
        ) : actions.length === 0 ? (
            <p>No action recommendations available.</p>
        ) : (
            <div style={{ display: 'grid', gap: '12px' }}>
                {actions.map((action) => (
                    <div
                        key={action.type}
                        style={{
                            border: '1px solid #e5e7eb',
                            borderLeft: getSeverityBorder(action.severity),
                            borderRadius: '6px',
                            padding: '12px',
                            backgroundColor: '#ffffff'
                        }}
                    >
                        <div style={{ display: 'flex', justifyContent: 'space-between', gap: '12px', alignItems: 'flex-start' }}>
                            <div>
                                <div style={{ fontWeight: 700, color: '#111827', fontSize: '14px' }}>{action.type}</div>
                                <p style={{ margin: '6px 0 0 0', color: '#4b5563', fontSize: '13px', lineHeight: 1.5 }}>{action.message}</p>
                            </div>
                            <span
                                style={{
                                    padding: '3px 8px',
                                    borderRadius: '999px',
                                    backgroundColor: '#f3f4f6',
                                    color: '#374151',
                                    fontSize: '11px',
                                    fontWeight: 700,
                                    whiteSpace: 'nowrap'
                                }}
                            >
                                {action.metric}
                            </span>
                        </div>
                    </div>
                ))}
            </div>
        )}
    </div>
);

export default ActionRecommendations;
