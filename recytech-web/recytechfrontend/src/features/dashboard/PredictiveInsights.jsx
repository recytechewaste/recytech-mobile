import { BarChart3 } from 'lucide-react';
import styles from '../../styles/Dashboard.module.css';

const getCorrelationColor = (value) => {
    const absoluteValue = Math.abs(value || 0);

    if (absoluteValue > 0.7) return '#10B981';
    if (absoluteValue > 0.3) return '#F59E0B';
    return '#EF4444';
};

const getCorrelationDescription = (value) => {
    const absoluteValue = Math.abs(value || 0);

    if (absoluteValue > 0.7) return 'Strong relationship between requests and completions';
    if (absoluteValue > 0.3) return 'Moderate relationship detected';
    return 'Weak or no relationship found';
};

const PredictiveInsights = ({ predictiveInsights }) => {
    const insights = predictiveInsights.insights || {};
    const correlationValue = predictiveInsights.correlation?.requestCompletionCorrelation || 0;

    return (
        <div className={styles.sectionContainer}>
            <h2 className={styles.sectionHeaderLeft}>Predictive Insights</h2>
            <p className={styles.sectionSubHeaderLeft}>Predictive analytics and forecasting.</p>

            <div className={styles.metricsLayout}>
                <div className={styles.statsColumn}>
                    <div className={`${styles.metricCard} ${insights.trendDirection === 'Increasing' ? styles.successCard : insights.trendDirection === 'Decreasing' ? styles.dangerCard : ''}`}>
                        <span>Trend Direction</span>
                        <h3>{insights.trendDirection || 'N/A'}</h3>
                    </div>
                    <div className={styles.metricCard}>
                        <span>Prediction Confidence</span>
                        <h3>{insights.predictionConfidence || 0}%</h3>
                    </div>
                    <div className={`${styles.metricCard} ${insights.seasonalityDetected ? styles.warningCard : ''}`}>
                        <span>Seasonal Patterns</span>
                        <h3>{insights.seasonalityDetected ? 'Detected' : 'None'}</h3>
                    </div>
                    <div className={`${styles.metricCard} ${insights.outlierCount > 0 ? styles.dangerCard : styles.successCard}`}>
                        <span>Outlier Months</span>
                        <h3>{insights.outlierCount || 0}</h3>
                    </div>
                </div>

                <div className={styles.chartCard}>
                    <h3 className={styles.cardTitle}>Correlation Analysis</h3>
                    <div style={{ padding: '20px', textAlign: 'center' }}>
                        <BarChart3 size={44} color="#2563EB" style={{ marginBottom: '10px' }} />
                        <p style={{ margin: '10px 0', fontSize: '14px', color: '#6B7280' }}>
                            Request-Completion Correlation
                        </p>
                        <h3
                            style={{
                                fontSize: '24px',
                                margin: '10px 0',
                                color: getCorrelationColor(correlationValue)
                            }}
                        >
                            {predictiveInsights.correlation?.strength || 'N/A'} ({correlationValue.toFixed(2)})
                        </h3>
                        <p style={{ fontSize: '12px', color: '#9CA3AF' }}>
                            {getCorrelationDescription(correlationValue)}
                        </p>
                    </div>
                </div>
            </div>
        </div>
    );
};

export default PredictiveInsights;
