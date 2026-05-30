import { Bar, BarChart, ResponsiveContainer, Tooltip, XAxis, YAxis } from 'recharts';
import styles from '../../styles/Dashboard.module.css';

const EWasteMetrics = ({ stats, monthlyData }) => (
    <div className={styles.sectionContainer}>
        <h2 className={styles.sectionHeaderLeft}>E-Waste Metrics</h2>
        <p className={styles.sectionSubHeaderLeft}>Processing and collection stats.</p>

        <div className={styles.metricsLayout}>
            <div className={styles.statsColumn}>
                <div className={`${styles.metricCard} ${stats.pending >= 10 ? styles.dangerCard : stats.pending >= 5 ? styles.warningCard : ''}`}>
                    <span>Pending Review</span>
                    <h3>{stats.pending}</h3>
                </div>
                <div className={styles.metricCard}>
                    <span>Total E-Waste Items</span>
                    <h3>{stats.totalItems.toLocaleString()}</h3>
                </div>
                <div className={styles.metricCard}>
                    <span>Total Payout Released</span>
                    <h3>PHP {stats.totalPayout.toLocaleString()}</h3>
                </div>
                <div className={`${styles.metricCard} ${stats.completionRate >= 70 ? styles.successCard : ''}`}>
                    <span>Completion Rate</span>
                    <h3>{stats.completionRate}%</h3>
                </div>
            </div>

            <div className={styles.chartCard}>
                <h3 className={styles.cardTitle}>Monthly Collection Volume</h3>
                <ResponsiveContainer width="100%" height={300}>
                    <BarChart data={monthlyData}>
                        <XAxis dataKey="name" axisLine={false} tickLine={false} fontSize={12} />
                        <YAxis axisLine={false} tickLine={false} fontSize={12} />
                        <Tooltip cursor={{ fill: '#f3f4f6' }} />
                        <Bar dataKey="items" fill="#2563EB" radius={[4, 4, 0, 0]} barSize={30} />
                    </BarChart>
                </ResponsiveContainer>
            </div>
        </div>
    </div>
);

export default EWasteMetrics;
