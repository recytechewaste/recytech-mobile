import { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { ShieldAlert, ArrowLeft } from 'lucide-react';
import styles from '../styles/Unauthorized.module.css';

const Unauthorized = () => {
    const navigate = useNavigate();
    const [countdown, setCountdown] = useState(5);

    useEffect(() => {
        const timer = setInterval(() => {
            setCountdown((prev) => prev - 1);
        }, 1000);

        if (countdown === 0) {
            navigate('/dashboard');
        }

        return () => clearInterval(timer);
    }, [countdown, navigate]);

    return (
        <div className={styles.container}>
            <div className={styles.card}>
                <ShieldAlert size={80} className={styles.icon} />
                <h1 className={styles.title}>Access Denied</h1>
                <p className={styles.message}>
                    You do not have the required permissions to access this page. 
                    This incident may be logged for security purposes.
                </p>
                <div className={styles.timer}>
                    Redirecting you to the dashboard in <span>{countdown}</span> seconds...
                </div>
                <button onClick={() => navigate('/dashboard')} className={styles.backBtn}>
                    <ArrowLeft size={18} /> Go Back Now
                </button>
            </div>
        </div>
    );
};

export default Unauthorized;