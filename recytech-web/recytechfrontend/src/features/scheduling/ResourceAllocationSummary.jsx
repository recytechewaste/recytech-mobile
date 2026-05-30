import styles from '../../styles/Dashboard.module.css';

const ResourceAllocationSummary = ({ summary }) => (
    <div className={styles.chartCard}>
        <h3 className={styles.cardTitle}>Resource Allocation Summary</h3>
        <span className={styles.chartSub}>Collector capacity and pending operational load</span>
        <table className={styles.activityTable}>
            <tbody>
                <tr>
                    <td>Active collectors</td>
                    <td>{summary.activeCollectors || 0}</td>
                </tr>
                <tr>
                    <td>Suggested collectors needed</td>
                    <td>{summary.suggestedCollectorsNeeded || 0}</td>
                </tr>
                <tr>
                    <td>Pending request load</td>
                    <td>{summary.totalLoad || 0} of {summary.totalCapacity || 0}</td>
                </tr>
                <tr>
                    <td>Capacity utilization</td>
                    <td>{summary.utilizationRate || 0}%</td>
                </tr>
                <tr>
                    <td>High-priority requests</td>
                    <td>{summary.highPriorityRequests || 0}</td>
                </tr>
                <tr>
                    <td>Estimated recyclable value</td>
                    <td>PHP {(summary.totalEstimatedValue || 0).toLocaleString()}</td>
                </tr>
            </tbody>
        </table>
    </div>
);

export default ResourceAllocationSummary;
