import styles from '../../styles/Dashboard.module.css';

const getStatusClass = (status = '') => status.toLowerCase().replace(/\s/g, '');

const formatLocation = (location) => {
    const address = location?.address || 'N/A';
    return address.length > 20 ? `${address.substring(0, 20)}...` : address;
};

const RecentRequestsTable = ({ requests }) => (
    <div className={styles.activityCard}>
        <h3 className={styles.cardTitle}>Recent Collection Requests</h3>
        <table className={styles.activityTable}>
            <thead>
                <tr>
                    <th>Resident</th>
                    <th>Waste Type</th>
                    <th>Location</th>
                    <th>Status</th>
                    <th>Date</th>
                </tr>
            </thead>
            <tbody>
                {requests.length === 0 ? (
                    <tr>
                        <td colSpan="5" className={styles.emptyActivityTd}>No recent activity.</td>
                    </tr>
                ) : (
                    requests.map((request) => (
                        <tr key={request._id}>
                            <td>{request.residentName}</td>
                            <td>{request.wasteType}</td>
                            <td>{formatLocation(request.location)}</td>
                            <td>
                                <span className={`${styles.statusBadge} ${styles[getStatusClass(request.status)]}`}>
                                    {request.status}
                                </span>
                            </td>
                            <td>{new Date(request.createdAt).toLocaleDateString()}</td>
                        </tr>
                    ))
                )}
            </tbody>
        </table>
    </div>
);

export default RecentRequestsTable;
