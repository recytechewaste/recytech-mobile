import styles from '../../styles/Dashboard.module.css';

const SchedulingHeader = ({ forecastTotal, recommendationCount }) => (
    <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', gap: '16px', flexWrap: 'wrap' }}>
        <div style={{ flex: '1 1 320px' }}>
            <h2 className={styles.sectionHeaderLeft}>Smart Scheduling</h2>
            <p className={styles.sectionSubHeaderLeft}>Forecast demand and review collector recommendations before confirming assignments.</p>
        </div>
        <div style={{ display: 'flex', gap: '12px', flexWrap: 'wrap' }}>
            <div className={`${styles.metricCard} ${styles.successCard}`} style={{ minWidth: '220px' }}>
                <span>Next 7-day forecast</span>
                <h3>{forecastTotal} requests</h3>
            </div>
            <div className={styles.metricCard} style={{ minWidth: '220px' }}>
                <span>Pending recommendations</span>
                <h3>{recommendationCount}</h3>
            </div>
        </div>
    </div>
);

export default SchedulingHeader;
