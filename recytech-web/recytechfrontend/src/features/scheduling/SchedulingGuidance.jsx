import styles from '../../styles/Dashboard.module.css';

const SchedulingGuidance = () => (
    <div className={styles.chartCard} style={{ marginTop: '24px' }}>
        <h3 className={styles.cardTitle}>Scheduling Guidance</h3>
        <p className={styles.chartSub}>How to use the smart scheduling assistant</p>
        <ul style={{ marginTop: '12px', paddingLeft: '20px', color: '#374151', lineHeight: '1.6' }}>
            <li>Review the 7-day demand forecast to understand expected volume.</li>
            <li>Check recommended collector assignments based on vehicle capacity.</li>
            <li>Select assignments and set the scheduled date/time for each request.</li>
            <li>Confirm the selected assignments to apply them to the system.</li>
            <li>The system checks for scheduling conflicts before confirming.</li>
        </ul>
    </div>
);

export default SchedulingGuidance;
