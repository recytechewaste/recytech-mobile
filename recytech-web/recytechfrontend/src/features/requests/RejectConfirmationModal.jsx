import { X } from 'lucide-react';
import styles from '../../styles/RequestManagement.module.css';

const RejectConfirmationModal = ({ onCancel, onConfirm }) => (
    <div className={styles.modalOverlay}>
        <div className={styles.modalContent} style={{ maxWidth: '400px' }}>
            <div className={styles.modalHeader}>
                <h2 className={styles.modalTitle}>Confirm Rejection</h2>
                <button onClick={onCancel} className={styles.closeBtn}><X size={20} /></button>
            </div>
            <p style={{ color: '#666', marginBottom: '24px', fontSize: '14px', lineHeight: '1.5' }}>
                Are you sure you want to reject this pickup request? This action will mark the request as Rejected and cannot be undone.
            </p>
            <div style={{ display: 'flex', justifyContent: 'flex-end', gap: '10px' }}>
                <button onClick={onCancel} className={styles.viewBtn}>Cancel</button>
                <button onClick={onConfirm} className={styles.rejectBtn} style={{ marginRight: 0 }}>Reject Request</button>
            </div>
        </div>
    </div>
);

export default RejectConfirmationModal;
