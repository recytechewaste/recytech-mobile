import { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { FileQuestion, ArrowLeft } from 'lucide-react';
import styles from '../styles/NotFound.module.css';

const NotFound = () => {
    const navigate = useNavigate();
    const [countdown, setCountdown] = useState(10);

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
                <div className={styles.errorCode}>404</div>
                <FileQuestion size={80} className={styles.icon} />
                <h1 className={styles.title}>Page Not Found</h1>
                <p className={styles.message}>
                    Oops! The page you're looking for doesn't exist or has been moved. 
                    Please check the URL or return to the dashboard.
                </p>
                <div className={styles.timer}>
                    Redirecting you to the dashboard in <span>{countdown}</span> seconds...
                </div>
                <button onClick={() => navigate('/dashboard')} className={styles.backBtn}>
                    <ArrowLeft size={18} /> Return to Dashboard
                </button>
            </div>
        </div>
    );
};

export default NotFound;