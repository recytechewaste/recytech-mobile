import styles from '../../styles/RequestManagement.module.css';

const STAT_ITEMS = [
    { key: 'total', label: 'Total Requests' },
    { key: 'pending', label: 'Pending Review' },
    { key: 'approved', label: 'Approved' },
    { key: 'completed', label: 'Completed' }
];

const RequestStats = ({ stats }) => (
    <div className={styles.metricsGrid}>
        {STAT_ITEMS.map((item) => (
            <div key={item.key} className={styles.metricCard}>
                <span className={styles.metricLabel}>{item.label}</span>
                <h3 className={styles.metricValue}>{stats[item.key]}</h3>
            </div>
        ))}
    </div>
);

export default RequestStats;
