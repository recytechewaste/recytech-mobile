import styles from '../../styles/Dashboard.module.css';

const ForecastTable = ({ forecast, loading, error }) => (
    <div className={styles.chartCard} style={{ minHeight: '320px' }}>
        <h3 className={styles.cardTitle}>Forecasted Request Volume</h3>
        <span className={styles.chartSub}>ARIMA-based prediction for the next 7 days</span>
        {loading ? (
            <p>Loading forecast...</p>
        ) : error ? (
            <p style={{ color: '#dc2626' }}>{error}</p>
        ) : forecast.length === 0 ? (
            <p>No forecast data available.</p>
        ) : (
            <div style={{ overflowX: 'auto' }}>
                <table className={styles.activityTable} style={{ width: '100%', marginTop: '16px' }}>
                    <thead>
                        <tr>
                            <th>Date</th>
                            <th>Predicted Requests</th>
                        </tr>
                    </thead>
                    <tbody>
                        {forecast.map((item) => (
                            <tr key={item.date}>
                                <td>{item.date}</td>
                                <td>{item.predictedRequests}</td>
                            </tr>
                        ))}
                    </tbody>
                </table>
            </div>
        )}
    </div>
);

export default ForecastTable;
