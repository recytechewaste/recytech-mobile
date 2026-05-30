import styles from '../../styles/RequestManagement.module.css';

const getCollectorName = (collectors, selectedCollector) => {
    const collector = collectors.find((item) => item._id === selectedCollector);
    return collector ? `${collector.firstName} ${collector.lastName}` : 'this collector';
};

const ConfirmAssignmentModal = ({ collectors, selectedCollector, onCancel, onConfirm }) => (
    <div className={styles.modalOverlay}>
        <div className={styles.modalContent}>
            <div className={styles.modalHeader}>
                <h2 className={styles.modalTitle}>Confirm Assignment</h2>
            </div>
            <p>
                Are you sure you want to assign <strong>{getCollectorName(collectors, selectedCollector)}</strong> to this request?
            </p>
            <div style={{ marginTop: '20px', display: 'flex', justifyContent: 'flex-end', gap: '10px' }}>
                <button onClick={onCancel} className={styles.viewBtn}>Cancel</button>
                <button onClick={onConfirm} className={styles.approveBtn}>Confirm</button>
            </div>
        </div>
    </div>
);

export default ConfirmAssignmentModal;
