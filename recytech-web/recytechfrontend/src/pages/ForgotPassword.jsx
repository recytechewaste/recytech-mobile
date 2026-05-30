import { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { Recycle, Loader2, ArrowLeft } from 'lucide-react';
import api from '../api/client';
import styles from '../styles/ForgotPassword.module.css';

const ForgotPassword = () => {
    const navigate = useNavigate();
    const [email, setEmail] = useState('');
    const [loading, setLoading] = useState(false);
    const [message, setMessage] = useState('');
    const [error, setError] = useState('');

    const handleResetRequest = async (e) => {
        e.preventDefault();
        if (!email) return setError('Please enter your email address');
        
        setLoading(true);
        setError('');
        setMessage('');

        try {
            await api.post('/auth/forgot-password', { email });
            setMessage('PIN has been sent to your email! Redirecting...');
            
            setTimeout(() => {
                navigate('/verify-pin', { state: { email } });
            }, 1500);
        } catch (err) {
            setError(err.response?.data?.message || 'Failed to send reset instructions.');
        } finally {
            setLoading(false);
        }
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
                    <h1 className={styles.header}>Reset Password</h1>
                    <p className={styles.subtext}>Enter your registered email address to receive password reset instructions.</p>
                    
                    {message && <p className={styles.successMessage}>{message}</p>}
                    {error && <p className={styles.errorMessage}>{error}</p>}

                    <form onSubmit={handleResetRequest}>
                        <div className={styles.inputGroup}>
                            <label className={styles.label}>Email Address</label>
                            <input 
                                type="email" 
                                placeholder="admin@example.com" 
                                className={styles.input} 
                                value={email}
                                onChange={(e) => setEmail(e.target.value)}
                            />
                        </div>

                        <button 
                            type="submit" 
                            className={styles.resetBtn} 
                            disabled={loading}
                        >
                            {loading ? (
                                <div style={{ display: 'flex', alignItems: 'center', gap: '10px', justifyContent: 'center' }}>
                                    <Loader2 size={18} className={styles.spinner} /> Processing...
                                </div>
                            ) : 'Send Reset Instructions'}
                        </button>
                    </form>
                    
                    <div className={styles.backLinkContainer}>
                        <span onClick={() => navigate('/login')} className={styles.backLink}>
                            <ArrowLeft size={16} style={{ marginRight: '8px' }} /> Back to Login
                        </span>
                    </div>
                </div>
                
                <p className={styles.footerText}>For security purposes, password reset is only available for registered staff, admins and super admins.</p>
                <div className={styles.footerLinks}>
                    <span>© 2025 RecyTech Admin Portal. All rights reserved.</span>
                    <div className={styles.footerLinksGroup}>
                        <span>Privacy Policy</span>
                        <span>Terms of Service</span>
                        <span>Support</span>
                    </div>
                </div>
            </div>
        </div>
    );
};

export default ForgotPassword;
