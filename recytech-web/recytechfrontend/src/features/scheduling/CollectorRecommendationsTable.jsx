import styles from '../../styles/Dashboard.module.css';

const countHighPriorityRequests = (requests = []) =>
    requests.filter((request) => ['Critical', 'High'].includes(request.priorityLevel)).length;

const CollectorRecommendationsTable = ({ recommendations, loading, error }) => (
    <div className={styles.chartCard} style={{ minHeight: '320px' }}>
        <h3 className={styles.cardTitle}>Collector Recommendations</h3>
        <span className={styles.chartSub}>Suggested assignments for pending approved requests</span>
        {loading ? (
            <p>Loading recommendations...</p>
        ) : error ? (
            <p style={{ color: '#dc2626' }}>{error}</p>
        ) : recommendations.length === 0 ? (
            <p>No pending requests available for recommendation.</p>
        ) : (
            <div style={{ overflowX: 'auto' }}>
                <table className={styles.activityTable} style={{ width: '100%', marginTop: '16px' }}>
                    <thead>
                        <tr>
                            <th>Collector</th>
                            <th>Vehicle</th>
                            <th>Capacity</th>
                            <th>Priority Load</th>
                            <th>Assigned Requests</th>
                        </tr>
                    </thead>
                    <tbody>
                        {recommendations.map((item) => (
                            <tr key={item.collectorId}>
                                <td>{item.collectorName}</td>
                                <td>{item.vehicleType}</td>
                                <td>{Math.round((item.loadAssigned / item.capacity) * 100)}% used</td>
                                <td>{countHighPriorityRequests(item.assignedRequests)} high</td>
                                <td>{item.assignedRequests.length}</td>
                            </tr>
                        ))}
                    </tbody>
                </table>
            </div>
        )}
    </div>
);

export default CollectorRecommendationsTable;
