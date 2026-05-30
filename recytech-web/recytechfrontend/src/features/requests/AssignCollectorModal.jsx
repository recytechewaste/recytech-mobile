import styles from '../../styles/RequestManagement.module.css';

const AssignCollectorModal = ({
    request,
    collectors,
    selectedCollector,
    selectedScheduleDate,
    selectedScheduleTime,
    scheduleConflict,
    onCollectorChange,
    onDateChange,
    onTimeChange,
    onCancel,
    onAssign
}) => {
    if (!request) return null;

    return (
        <div className={styles.modalOverlay}>
            <div className={styles.modalContent}>
                <div className={styles.modalHeader}>
                    <h2 className={styles.modalTitle}>Assign Collector</h2>
                    <button onClick={onCancel} className={styles.closeBtn}>&times;</button>
                </div>
                <p style={{ marginBottom: '10px' }}>Select a driver for <strong>{request.wasteType}</strong>:</p>
                <select
                    className={styles.select}
                    style={{ marginBottom: '20px' }}
                    onChange={(event) => onCollectorChange(event.target.value)}
                    value={selectedCollector}
                >
                    <option value="">-- Select Driver --</option>
                    {collectors.filter((collector) => collector.status === 'Active').map((collector) => (
                        <option key={collector._id} value={collector._id}>
                            {`${collector.firstName} ${collector.lastName}`} ({collector.vehiclePlate})
                        </option>
                    ))}
                </select>
                <div className={styles.filterGroup} style={{ marginBottom: '18px' }}>
                    <label className={styles.label}>Scheduled Date</label>
                    <input
                        type="date"
                        className={styles.input}
                        value={selectedScheduleDate}
                        onChange={(event) => onDateChange(event.target.value)}
                    />
                </div>
                <div className={styles.filterGroup} style={{ marginBottom: '18px' }}>
                    <label className={styles.label}>Scheduled Time</label>
                    <input
                        type="time"
                        className={styles.input}
                        value={selectedScheduleTime}
                        onChange={(event) => onTimeChange(event.target.value)}
                    />
                </div>
                {scheduleConflict && (
                    <div style={{ color: '#b91c1c', marginBottom: '16px' }}>{scheduleConflict}</div>
                )}
                <div style={{ display: 'flex', justifyContent: 'flex-end', gap: '10px' }}>
                    <button onClick={onCancel} className={styles.viewBtn}>Cancel</button>
                    <button onClick={onAssign} className={styles.approveBtn}>Assign</button>
                </div>
            </div>
        </div>
    );
};

export default AssignCollectorModal;
