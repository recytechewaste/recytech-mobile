import { useState, useEffect } from 'react';
import api from '../api/client';
import { useNavigate } from 'react-router-dom';
import { Recycle, Eye, EyeOff, Loader2, CheckCircle, AlertCircle, X } from 'lucide-react'; 
import styles from '../styles/Login.module.css';

const Login = () => {
    const [email, setEmail] = useState('');
    const [password, setPassword] = useState('');
    const [showPassword, setShowPassword] = useState(false);
    const [error, setError] = useState('');
    const [role, setRole] = useState('Staff');
    const [loading, setLoading] = useState(false);
    const [rememberMe, setRememberMe] = useState(false);
    const [showSuccessModal, setShowSuccessModal] = useState(false);
    const navigate = useNavigate();

    useEffect(() => {
        const savedEmail = localStorage.getItem('rememberedEmail');
        if (savedEmail) {
            setEmail(savedEmail);
            setRememberMe(true);
        }
    }, []);

    const handleLogin = async (e) => {
        e.preventDefault();
        setLoading(true);
        setError('');
        try {
            if (rememberMe) {
                localStorage.setItem('rememberedEmail', email);
            } else {
                localStorage.removeItem('rememberedEmail');
            }
            const { data } = await api.post('/auth/login', { email, password, role });
            localStorage.setItem('userInfo', JSON.stringify(data));
            setShowSuccessModal(true);
        } catch (err) {
            setError(err.response?.data?.message || 'Invalid email or password');
        } finally {
            setLoading(false);
        }
    };

    return (
        <div className={styles.pageContainer}>
            {/* TOP HEADER BAR */}
            <div className={styles.topBar}>
                <div className={styles.logoContainer}>
                    <div className={styles.logoIcon}><Recycle size={20} color="white" /></div>
                    <span className={styles.logoText}>
                        RecyTech <span style={{ fontWeight: '400', opacity: '0.9' }}>Admin Portal</span>
                    </span>
                </div>
            </div>

            {/* LOGIN CARD */}
            <div className={styles.contentContainer}>
                <div className={styles.card}>
                    <h1 className={styles.header}>Login</h1>
                    
                    <form onSubmit={handleLogin} className={styles.form}>
                        <div className={styles.gridRow}>
                            <div className={styles.inputGroup}>
                                <label className={styles.label}>Email</label>
                                <input 
                                    type="email" 
                                    placeholder="Enter your email address" 
                                    className={styles.input}
                                    value={email}
                                    onChange={(e) => setEmail(e.target.value)}
                                />
                            </div>
                            <div className={styles.inputGroup}>
                                <label className={styles.label}>Account Role</label>
                                <select 
                                    className={styles.input} 
                                    value={role} 
                                    onChange={(e) => setRole(e.target.value)}
                                >
                                    <option value="Staff">Staff</option>
                                    <option value="Admin">Admin</option>
                                    <option value="Super Admin">Super Admin</option>
                                </select>
                            </div>
                            <div className={`${styles.inputGroup} ${styles.fullWidth}`}>
                                <label className={styles.label}>Password</label>
                                <div className={styles.passwordWrapper}>
                                    <input 
                                        type={showPassword ? "text" : "password"} 
                                        placeholder="Enter your password" 
                                        className={styles.input}
                                        value={password}
                                        onChange={(e) => setPassword(e.target.value)}
                                    />
                                    <button type="button" className={styles.eyeBtn} onClick={() => setShowPassword(!showPassword)}>
                                        {showPassword ? <EyeOff size={16} /> : <Eye size={16} />}
                                    </button>
                                </div>
                            </div>
                        </div>

                        <div className={styles.rememberMeContainer}>
                            <input 
                                type="checkbox" 
                                id="rememberMe"
                                className={styles.checkbox}
                                checked={rememberMe}
                                onChange={(e) => setRememberMe(e.target.checked)}
                            />
                            <label htmlFor="rememberMe" className={styles.checkboxLabel}>Remember Me</label>
                        </div>

                        <div className={styles.buttonGroup}>
                            <button 
                                type="button" 
                                onClick={() => navigate('/forgot-password')}
                                className={styles.forgotBtn}
                            >
                                Forgot Password?
                            </button>
                            <button 
                                type="submit" 
                                className={styles.loginBtn} 
                                style={{backgroundColor: '#2563EB'}}
                                disabled={loading}
                            >
                                {loading ? (
                                    <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
                                        <Loader2 size={18} className={styles.spinner} /> Processing...
                                    </div>
                                ) : 'Login'}
                            </button>
                        </div>
                    </form>
                    
                    {/* Added link to Register for easier navigation */}
                    <div className={styles.registerLinkContainer}>
                        <span className={styles.registerText}>Don't have an account? </span>
                        <span 
                            onClick={() => navigate('/register')} 
                            className={styles.registerLink}
                        >
                            Register
                        </span>
                    </div>
                </div>
            </div>

            {/* SUCCESS MODAL */}
            {showSuccessModal && (
                <div className={styles.modalOverlay}>
                    <div className={styles.modalContent}>
                        <div className={styles.modalBody}>
                            <CheckCircle size={60} color="#059669" className={styles.modalIcon} />
                            <h2 className={styles.modalTitle}>Login Successful!</h2>
                            <p className={styles.modalText}>Welcome back to the RecyTech Admin Portal.</p>
                            <button 
                                className={styles.modalBtn} 
                                onClick={() => navigate('/dashboard')}
                                style={{backgroundColor: '#2563EB'}}
                            >
                                Proceed to Dashboard
                            </button>
                        </div>
                    </div>
                </div>
            )}

            {/* ERROR MODAL */}
            {error && (
                <div className={styles.modalOverlay}>
                    <div className={styles.modalContent}>
                        <button className={styles.closeModalBtn} onClick={() => setError('')}><X size={20}/></button>
                        <div className={styles.modalBody}>
                            <AlertCircle size={60} color="#ef4444" className={styles.modalIcon} />
                            <h2 className={styles.modalTitle}>Login Failed</h2>
                            <p className={styles.modalText}>{error}</p>
                            <button className={styles.modalBtn} onClick={() => setError('')} style={{backgroundColor: '#111827'}}>
                                Try Again
                            </button>
                        </div>
                    </div>
                </div>
            )}
        </div>
    );
};

export default Login;
