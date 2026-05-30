import { Check } from 'lucide-react';
import styles from '../../styles/RequestManagement.module.css';

const SuccessModal = ({ title, message, onContinue }) => (
    <div className={styles.modalOverlay}>
        <div className={`${styles.modalContent} ${styles.successModal}`}>
            <div className={styles.successIconWrapper}>
                <Check size={40} color="#059669" />
            </div>
            <h2 className={styles.successTitle}>{title || 'Action Successful'}</h2>
            <p className={styles.successText}>{message}</p>
            <div className={styles.modalFooter} style={{ borderTop: 'none', justifyContent: 'center', marginTop: '16px' }}>
                <button onClick={onContinue} className={styles.approveBtn} style={{ width: '100%', padding: '12px' }}>
                    Continue
                </button>
            </div>
        </div>
    </div>
);

export default SuccessModal;
