import { useState, useEffect } from 'react';
import { useNavigate, useLocation } from 'react-router-dom';
import { Recycle, Loader2, ArrowLeft } from 'lucide-react';
import api from '../api/client';
import styles from '../styles/ForgotPassword.module.css';

const ResetPinVerification = () => {
    const navigate = useNavigate();
    const location = useLocation();
    const [pin, setPin] = useState('');
    const [loading, setLoading] = useState(false);
    const [message, setMessage] = useState('');
    const [error, setError] = useState('');
    const [email, setEmail] = useState('');
    const [timer, setTimer] = useState(900); // 15 minutes

    useEffect(() => {
        // Get email from location state or redirect
        if (location.state?.email) {
            setEmail(location.state.email);
        } else {
            navigate('/forgot-password');
        }
    }, [location, navigate]);

    useEffect(() => {
        if (timer > 0) {
            const interval = setInterval(() => setTimer(t => t - 1), 1000);
            return () => clearInterval(interval);
        } else if (timer === 0) {
            setError('PIN has expired. Please request a new one.');
        }
    }, [timer]);

    const handleVerifyPin = async (e) => {
        e.preventDefault();
        if (!pin) return setError('Please enter the PIN');
        if (pin.length !== 6) return setError('PIN must be 6 digits');

        setLoading(true);
        setError('');
        setMessage('');

        try {
            const response = await api.post('/auth/verify-pin', { email, pin });
            setMessage('PIN verified successfully! Redirecting...');
            
            setTimeout(() => {
                navigate('/reset-password', { 
                    state: { 
                        email, 
                        resetToken: response.data.resetToken 
                    } 
                });
            }, 1500);
        } catch (err) {
            setError(err.response?.data?.message || 'Failed to verify PIN');
        } finally {
            setLoading(false);
        }
    };

    const formatTime = (seconds) => {
        const mins = Math.floor(seconds / 60);
        const secs = seconds % 60;
        return `${mins}:${secs.toString().padStart(2, '0')}`;
    };

    return (
        <div className={styles.pageContainer}>
            <div className={styles.topBar}>
                <div className={styles.logoContainer}>
                    <div className={styles.logoIcon}><Recycle size={20} color="white" /></div>
                    <span className={styles.logoText}>
                        RecyTech <span style={{ fontWeight: '400', opacity: '0.9' }}>Admin Portal</span>
                    </span>
                </div>
            </div>

            <div className={styles.contentContainer}>
                <div className={styles.card}>
                    <h1 className={styles.header}>Verify PIN</h1>
                    <p className={styles.subtext}>Enter the 6-digit PIN sent to your email address</p>
                    
                    <div style={{ 
                        padding: '12px', 
                        backgroundColor: timer < 300 ? '#fef2f2' : '#f0fdf4',
                        border: `1px solid ${timer < 300 ? '#fca5a5' : '#86efac'}`,
                        borderRadius: '6px',
                        marginBottom: '16px',
                        textAlign: 'center',
                        fontSize: '14px',
                        color: timer < 300 ? '#991b1b' : '#15803d'
                    }}>
                        Time remaining: <strong>{formatTime(timer)}</strong>
                    </div>

                    {message && <p className={styles.successMessage}>{message}</p>}
                    {error && <p className={styles.errorMessage}>{error}</p>}

                    <form onSubmit={handleVerifyPin}>
                        <div className={styles.inputGroup}>
                            <label className={styles.label}>Enter PIN</label>
                            <input 
                                type="text" 
                                inputMode="numeric"
                                maxLength="6"
                                placeholder="000000" 
                                className={styles.input}
                                value={pin}
                                onChange={(e) => setPin(e.target.value.replace(/\D/g, ''))}
                                style={{ fontSize: '24px', letterSpacing: '8px', textAlign: 'center' }}
                            />
                        </div>

                        <button 
                            type="submit" 
                            className={styles.resetBtn} 
                            disabled={loading || timer === 0}
                        >
                            {loading ? (
                                <div style={{ display: 'flex', alignItems: 'center', gap: '10px', justifyContent: 'center' }}>
                                    <Loader2 size={18} className={styles.spinner} /> Verifying...
                                </div>
                            ) : 'Verify PIN'}
                        </button>
                    </form>
                    
                    <div className={styles.backLinkContainer}>
                        <span onClick={() => navigate('/forgot-password')} className={styles.backLink}>
                            <ArrowLeft size={16} style={{ marginRight: '8px' }} /> Try different email
                        </span>
                    </div>
                </div>
                
                <p className={styles.footerText}>Didn't receive the PIN? Check your spam folder or request a new one.</p>
                <div className={styles.footerLinks}>
                    <span>© 2025 RecyTech Admin Portal. All rights reserved.</span>
                </div>
            </div>
        </div>
    );
};

export default ResetPinVerification;
