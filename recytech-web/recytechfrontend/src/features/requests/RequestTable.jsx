import { Check, Eye, X } from 'lucide-react';
import styles from '../../styles/RequestManagement.module.css';

const mutedText = { color: '#9ca3af', fontStyle: 'italic' };

const RequestTable = ({ requests, onView, onApprove, onReject }) => (
    <div className={styles.card}>
        <table className={styles.table}>
            <thead>
                <tr>
                    <th className={styles.th}>Request ID</th>
                    <th className={styles.th}>E-Waste Type</th>
                    <th className={styles.th}>Quantity</th>
                    <th className={styles.th}>Area</th>
                    <th className={styles.th}>Assigned Collector</th>
                    <th className={styles.th}>Pickup Schedule</th>
                    <th className={styles.th}>Submission Date</th>
                    <th className={styles.th}>Status</th>
                    <th className={styles.th}>Actions</th>
                </tr>
            </thead>
            <tbody>
                {requests.map((request) => (
                    <tr key={request._id} className={styles.tr}>
                        <td className={styles.td}>REQ-{request._id.substring(0, 6).toUpperCase()}</td>
                        <td className={styles.td}>
                            {request.itemCategory || request.detectedClass || request.wasteType}
                            {request.itemCategory && (
                                <div style={{ ...mutedText, fontSize: '12px' }}>{request.wasteType}</div>
                            )}
                        </td>
                        <td className={styles.td}>{request.quantity || 1} item(s)</td>
                        <td className={styles.td}>{request.location?.address || 'Area 1'}</td>
                        <td className={styles.td}>
                            {request.assignedCollector
                                ? `${request.assignedCollector.firstName} ${request.assignedCollector.lastName}`
                                : <span style={mutedText}>Unassigned</span>}
                        </td>
                        <td className={styles.td}>
                            {request.scheduledAt
                                ? new Date(request.scheduledAt).toLocaleString()
                                : <span style={mutedText}>Not scheduled</span>}
                        </td>
                        <td className={styles.td}>{new Date(request.createdAt).toLocaleDateString()}</td>
                        <td className={styles.td}>{request.status}</td>
                        <td className={`${styles.td} ${styles.actionCell}`}>
                            <div className={styles.tableActions}>
                                <button
                                    type="button"
                                    title="View details"
                                    onClick={() => onView(request)}
                                    className={`${styles.actionBtn} ${styles.actionView}`}
                                >
                                    <Eye size={14} />
                                    <span>View</span>
                                </button>
                                {request.status === 'Pending' && (
                                    <>
                                        <button
                                            type="button"
                                            title="Approve request"
                                            onClick={() => onApprove(request)}
                                            className={`${styles.actionBtn} ${styles.actionApprove}`}
                                        >
                                            <Check size={14} />
                                            <span>Approve</span>
                                        </button>
                                        <button
                                            type="button"
                                            title="Reject request"
                                            onClick={() => onReject(request._id)}
                                            className={`${styles.actionBtn} ${styles.actionReject}`}
                                        >
                                            <X size={14} />
                                            <span>Reject</span>
                                        </button>
                                    </>
                                )}
                            </div>
                        </td>
                    </tr>
                ))}
            </tbody>
        </table>
    </div>
);

export default RequestTable;
