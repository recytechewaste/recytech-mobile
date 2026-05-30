import { useState } from 'react';
import { useNavigate, useLocation } from 'react-router-dom';
import { Recycle, Loader2, ArrowLeft, CheckCircle } from 'lucide-react';
import api from '../api/client';
import styles from '../styles/ForgotPassword.module.css'; // Reuse styles

const VerifyPin = () => {
    const navigate = useNavigate();
    const location = useLocation();
    const { email } = location.state || {};
    const [pin, setPin] = useState('');
    const [newPassword, setNewPassword] = useState('');
    const [confirmPassword, setConfirmPassword] = useState('');
    const [loading, setLoading] = useState(false);
    const [message, setMessage] = useState('');
    const [error, setError] = useState('');
    const [resetToken, setResetToken] = useState('');

    const handleVerifyPin = async (e) => {
        e.preventDefault();
        if (!pin) return setError('Please enter the PIN');

        setLoading(true);
        setError('');
        setMessage('');

        try {
            const { data } = await api.post('/auth/verify-pin', { email, pin });
            setResetToken(data.resetToken);
            setMessage('PIN verified! Now set your new password.');
        } catch (err) {
            setError(err.response?.data?.message || 'Invalid PIN');
        } finally {
            setLoading(false);
        }
    };

    const handleResetPassword = async (e) => {
        e.preventDefault();
        if (!newPassword || !confirmPassword) return setError('Please fill all fields');
        if (newPassword !== confirmPassword) return setError('Passwords do not match');
        if (newPassword.length < 6) return setError('Password must be at least 6 characters');

        setLoading(true);
        setError('');
        setMessage('');

        try {
            await api.post('/auth/reset-password', { email, newPassword, confirmPassword, resetToken });
            setMessage('Password reset successful! Redirecting to login...');
            setTimeout(() => navigate('/login'), 2000);
        } catch (err) {
            setError(err.response?.data?.message || 'Failed to reset password');
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
                    <h1 className={styles.header}>Verify PIN & Reset Password</h1>
                    <p className={styles.subtext}>Enter the PIN sent to your email and set a new password.</p>

                    {message && <p className={styles.successMessage}>{message}</p>}
                    {error && <p className={styles.errorMessage}>{error}</p>}

                    {!resetToken ? (
                        <form onSubmit={handleVerifyPin}>
                            <div className={styles.inputGroup}>
                                <label className={styles.label}>PIN</label>
                                <input
                                    type="text"
                                    placeholder="Enter 6-digit PIN"
                                    className={styles.input}
                                    value={pin}
                                    onChange={(e) => setPin(e.target.value)}
                                    maxLength={6}
                                />
                            </div>

                            <button
                                type="submit"
                                className={styles.resetBtn}
                                disabled={loading}
                            >
                                {loading ? (
                                    <div style={{ display: 'flex', alignItems: 'center', gap: '10px', justifyContent: 'center' }}>
                                        <Loader2 size={18} className={styles.spinner} /> Verifying...
                                    </div>
                                ) : 'Verify PIN'}
                            </button>
                        </form>
                    ) : (
                        <form onSubmit={handleResetPassword}>
                            <div className={styles.inputGroup}>
                                <label className={styles.label}>New Password</label>
                                <input
                                    type="password"
                                    placeholder="Enter new password"
                                    className={styles.input}
                                    value={newPassword}
                                    onChange={(e) => setNewPassword(e.target.value)}
                                />
                            </div>
                            <div className={styles.inputGroup}>
                                <label className={styles.label}>Confirm New Password</label>
                                <input
                                    type="password"
                                    placeholder="Confirm new password"
                                    className={styles.input}
                                    value={confirmPassword}
                                    onChange={(e) => setConfirmPassword(e.target.value)}
                                />
                            </div>

                            <button
                                type="submit"
                                className={styles.resetBtn}
                                disabled={loading}
                            >
                                {loading ? (
                                    <div style={{ display: 'flex', alignItems: 'center', gap: '10px', justifyContent: 'center' }}>
                                        <Loader2 size={18} className={styles.spinner} /> Resetting...
                                    </div>
                                ) : 'Reset Password'}
                            </button>
                        </form>
                    )}

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

export default VerifyPin;