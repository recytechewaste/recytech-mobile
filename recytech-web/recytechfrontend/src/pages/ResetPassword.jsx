import { useState, useEffect } from 'react';
import { useNavigate, useLocation } from 'react-router-dom';
import { Recycle, Loader2, ArrowLeft, Eye, EyeOff } from 'lucide-react';
import api from '../api/client';
import styles from '../styles/ForgotPassword.module.css';

const ResetPassword = () => {
    const navigate = useNavigate();
    const location = useLocation();
    const [newPassword, setNewPassword] = useState('');
    const [confirmPassword, setConfirmPassword] = useState('');
    const [showPassword, setShowPassword] = useState(false);
    const [showConfirm, setShowConfirm] = useState(false);
    const [loading, setLoading] = useState(false);
    const [message, setMessage] = useState('');
    const [error, setError] = useState('');
    const [email, setEmail] = useState('');
    const [resetToken, setResetToken] = useState('');

    useEffect(() => {
        // Get email and token from location state or redirect
        if (location.state?.email && location.state?.resetToken) {
            setEmail(location.state.email);
            setResetToken(location.state.resetToken);
        } else {
            navigate('/forgot-password');
        }
    }, [location, navigate]);

    const handleResetPassword = async (e) => {
        e.preventDefault();
        
        if (!newPassword || !confirmPassword) {
            return setError('Please fill in all fields');
        }

        if (newPassword.length < 6) {
            return setError('Password must be at least 6 characters');
        }

        if (newPassword !== confirmPassword) {
            return setError('Passwords do not match');
        }

        setLoading(true);
        setError('');
        setMessage('');

        try {
            await api.post('/auth/reset-password', { 
                email, 
                newPassword, 
                confirmPassword,
                resetToken 
            });
            
            setMessage('✓ Password reset successfully! Redirecting to login...');
            
            setTimeout(() => {
                navigate('/login');
            }, 2000);
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
                    <h1 className={styles.header}>Create New Password</h1>
                    <p className={styles.subtext}>Enter a strong password for your account</p>

                    {message && <p className={styles.successMessage}>{message}</p>}
                    {error && <p className={styles.errorMessage}>{error}</p>}

                    <form onSubmit={handleResetPassword}>
                        <div className={styles.inputGroup}>
                            <label className={styles.label}>New Password</label>
                            <div style={{ position: 'relative' }}>
                                <input 
                                    type={showPassword ? "text" : "password"} 
                                    placeholder="Enter new password" 
                                    className={styles.input}
                                    value={newPassword}
                                    onChange={(e) => setNewPassword(e.target.value)}
                                />
                                <button 
                                    type="button"
                                    onClick={() => setShowPassword(!showPassword)}
                                    style={{
                                        position: 'absolute',
                                        right: '12px',
                                        top: '50%',
                                        transform: 'translateY(-50%)',
                                        background: 'none',
                                        border: 'none',
                                        cursor: 'pointer',
                                        color: '#6b7280'
                                    }}
                                >
                                    {showPassword ? <EyeOff size={16} /> : <Eye size={16} />}
                                </button>
                            </div>
                        </div>

                        <div className={styles.inputGroup}>
                            <label className={styles.label}>Confirm Password</label>
                            <div style={{ position: 'relative' }}>
                                <input 
                                    type={showConfirm ? "text" : "password"} 
                                    placeholder="Confirm new password" 
                                    className={styles.input}
                                    value={confirmPassword}
                                    onChange={(e) => setConfirmPassword(e.target.value)}
                                />
                                <button 
                                    type="button"
                                    onClick={() => setShowConfirm(!showConfirm)}
                                    style={{
                                        position: 'absolute',
                                        right: '12px',
                                        top: '50%',
                                        transform: 'translateY(-50%)',
                                        background: 'none',
                                        border: 'none',
                                        cursor: 'pointer',
                                        color: '#6b7280'
                                    }}
                                >
                                    {showConfirm ? <EyeOff size={16} /> : <Eye size={16} />}
                                </button>
                            </div>
                        </div>

                        <div style={{ padding: '12px', backgroundColor: '#f3f4f6', borderRadius: '6px', marginBottom: '16px', fontSize: '12px', color: '#374151' }}>
                            <p style={{ margin: '0 0 8px 0', fontWeight: '600' }}>Password requirements:</p>
                            <ul style={{ margin: '0', paddingLeft: '20px' }}>
                                <li>At least 6 characters long</li>
                                <li>Mix of uppercase and lowercase letters</li>
                                <li>Include numbers and special characters</li>
                            </ul>
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
                    
                    <div className={styles.backLinkContainer}>
                        <span onClick={() => navigate('/login')} className={styles.backLink}>
                            <ArrowLeft size={16} style={{ marginRight: '8px' }} /> Back to Login
                        </span>
                    </div>
                </div>
                
                <div className={styles.footerLinks}>
                    <span>© 2025 RecyTech Admin Portal. All rights reserved.</span>
                </div>
            </div>
        </div>
    );
};

export default ResetPassword;
