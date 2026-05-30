import { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import api from '../api/client';
import { Recycle, Eye, EyeOff, CheckCircle, AlertCircle, X, Loader2, Check, Circle } from 'lucide-react';
import styles from '../styles/Register.module.css';

const Register = () => {
    const navigate = useNavigate();
    const [formData, setFormData] = useState({
        firstName: '', 
        lastName: '', 
        email: '', 
        password: '', 
        confirmPassword: '', 
        role: 'Staff'
    });
    const [showPassword, setShowPassword] = useState(false);
    const [showConfirmPassword, setShowConfirmPassword] = useState(false);
    const [showSuccessModal, setShowSuccessModal] = useState(false);
    const [errorMessage, setErrorMessage] = useState('');
    const [loading, setLoading] = useState(false);
    const [passwordStrength, setPasswordStrength] = useState(0);
    const [errors, setErrors] = useState({});

    const getPasswordRequirements = (password) => [
        { label: 'At least 8 characters', met: password.length >= 8 },
        { label: 'At least one uppercase letter', met: /[A-Z]/.test(password) },
        { label: 'At least one lowercase letter', met: /[a-z]/.test(password) },
        { label: 'At least one number', met: /[0-9]/.test(password) },
        { label: 'At least one special character', met: /[^A-Za-z0-9]/.test(password) },
    ];

    const calculateStrength = (password) => {
        if (!password) return 0;
        const requirements = getPasswordRequirements(password);
        const score = requirements.filter(req => req.met).length;
        return score;
    };

    const handleChange = (e) => {
        const { name, value } = e.target;
        setFormData({...formData, [name]: value});
        
        if (name === 'password') {
            setPasswordStrength(calculateStrength(value));
        }

        // Clear error when user types
        if (errors[name]) {
            setErrors({...errors, [name]: ''});
        }
    };

    const validate = () => {
        const newErrors = {};
        if (!formData.firstName.trim()) newErrors.firstName = 'First Name is required';
        if (!formData.lastName.trim()) newErrors.lastName = 'Last Name is required';
        
        const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
        if (!formData.email.trim()) {
            newErrors.email = 'Email is required';
        } else if (!emailRegex.test(formData.email)) {
            newErrors.email = 'Invalid email format';
        }

        if (!formData.password) {
            newErrors.password = 'Password is required';
        } else if (formData.password.length < 8) {
            newErrors.password = 'Password must be at least 8 characters';
        }

        if (formData.confirmPassword !== formData.password) {
            newErrors.confirmPassword = 'Passwords do not match';
        }

        setErrors(newErrors);
        return Object.keys(newErrors).length === 0;
    };

    const handleRegister = async (e) => {
        e.preventDefault();
        if (!validate()) return;

        setLoading(true);
        try {
            await api.post('/auth/register', formData);
            setShowSuccessModal(true);
        } catch (error) {
            setErrorMessage(error.response?.data?.message || "Registration failed. Email might be taken.");
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

            <div className={styles.contentContainer}>
                <div className={styles.card}>
                    <h1 className={styles.header}>Register</h1>
                    
                    <form onSubmit={handleRegister} className={styles.form}>
                        <div className={styles.gridRow}>
                            <div className={styles.inputGroup}>
                                <label className={styles.label}>First Name</label>
                                <input 
                                    name="firstName" 
                                    placeholder="Enter your first name" 
                                    className={`${styles.input} ${errors.firstName ? styles.inputError : ''}`} 
                                    value={formData.firstName}
                                    onChange={handleChange} 
                                />
                                {errors.firstName && <span className={styles.errorText}>{errors.firstName}</span>}
                            </div>
                            <div className={styles.inputGroup}>
                                <label className={styles.label}>Last Name</label>
                                <input 
                                    name="lastName" 
                                    placeholder="Enter your last name" 
                                    className={`${styles.input} ${errors.lastName ? styles.inputError : ''}`} 
                                    value={formData.lastName}
                                    onChange={handleChange} 
                                />
                                {errors.lastName && <span className={styles.errorText}>{errors.lastName}</span>}
                            </div>
                            <div className={styles.inputGroup}>
                                <label className={styles.label}>Email</label>
                                <input 
                                    name="email" 
                                    type="email" 
                                    placeholder="Enter your email address" 
                                    className={`${styles.input} ${errors.email ? styles.inputError : ''}`} 
                                    value={formData.email}
                                    onChange={handleChange} 
                                />
                                {errors.email && <span className={styles.errorText}>{errors.email}</span>}
                            </div>
                            <div className={styles.inputGroup}>
                                <label className={styles.label}>Account Role</label>
                                <select 
                                    name="role" 
                                    className={styles.input} 
                                    value={formData.role} 
                                    onChange={handleChange}
                                >
                                    <option value="Staff">Staff</option>
                                    <option value="Admin">Admin</option>
                                    <option value="Super Admin">Super Admin</option>
                                </select>
                            </div>
                            <div className={styles.inputGroup}>
                                <label className={styles.label}>Password</label>
                                <div className={styles.passwordWrapper}>
                                    <input 
                                        name="password" 
                                        type={showPassword ? "text" : "password"} 
                                        placeholder="Create a password" 
                                        className={`${styles.input} ${errors.password ? styles.inputError : ''}`} 
                                        value={formData.password}
                                        onChange={handleChange} 
                                    />
                                    <button type="button" className={styles.eyeBtn} onClick={() => setShowPassword(!showPassword)}>
                                        {showPassword ? <EyeOff size={16} /> : <Eye size={16} />}
                                    </button>
                                </div>
                                {formData.password && (
                                    <div className={styles.strengthMeter}>
                                        <div className={`${styles.strengthBar} ${styles[`strength-${passwordStrength}`]}`} />
                                        <span className={styles.strengthText}>
                                            {['Very Weak', 'Weak', 'Fair', 'Good', 'Strong', 'Very Strong'][passwordStrength]}
                                        </span>
                                    </div>
                                )}
                                {formData.password && (
                                    <div className={styles.requirementList}>
                                        {getPasswordRequirements(formData.password).map((req, index) => (
                                            <div key={index} className={`${styles.requirementItem} ${req.met ? styles.met : ''}`}>
                                                {req.met ? <Check size={12} strokeWidth={3} /> : <Circle size={12} />}
                                                <span>{req.label}</span>
                                            </div>
                                        ))}
                                    </div>
                                )}
                                {errors.password && <span className={styles.errorText}>{errors.password}</span>}
                            </div>
                            <div className={styles.inputGroup}>
                                <label className={styles.label}>Confirm Password</label>
                                <div className={styles.passwordWrapper}>
                                    <input 
                                        name="confirmPassword" 
                                        type={showConfirmPassword ? "text" : "password"} 
                                        placeholder="Re-enter your password" 
                                        className={`${styles.input} ${errors.confirmPassword ? styles.inputError : ''}`} 
                                        value={formData.confirmPassword}
                                        onChange={handleChange} 
                                    />
                                    <button type="button" className={styles.eyeBtn} onClick={() => setShowConfirmPassword(!showConfirmPassword)}>
                                        {showConfirmPassword ? <EyeOff size={16} /> : <Eye size={16} />}
                                    </button>
                                </div>
                                {errors.confirmPassword && <span className={styles.errorText}>{errors.confirmPassword}</span>}
                            </div>
                        </div>

                        {/* Button */}
                        <div className={styles.buttonContainer}>
                            <button 
                                type="submit" 
                                className={styles.registerBtn} 
                                style={{backgroundColor: '#2563EB'}}
                                disabled={loading}
                            >
                                {loading ? (
                                    <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
                                        <Loader2 size={18} className={styles.spinner} /> Processing...
                                    </div>
                                ) : 'Register'}
                            </button>
                        </div>
                    </form>
                    
                    <div className={styles.loginLinkContainer}>
                        <span className={styles.loginText}>Already have an account? </span>
                        <span 
                            onClick={() => navigate('/login')} 
                            className={styles.loginLink}
                        >
                            Log In
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
                            <h2 className={styles.modalTitle}>Success!</h2>
                            <p className={styles.modalText}>Your account has been successfully created. You can now proceed to login.</p>
                            <button 
                                className={styles.modalBtn} 
                                onClick={() => navigate('/login')}
                                style={{backgroundColor: '#2563EB'}}
                            >
                                Go to Login
                            </button>
                        </div>
                    </div>
                </div>
            )}

            {/* ERROR MODAL */}
            {errorMessage && (
                <div className={styles.modalOverlay}>
                    <div className={styles.modalContent}>
                        <button className={styles.closeModalBtn} onClick={() => setErrorMessage('')}><X size={20}/></button>
                        <div className={styles.modalBody}>
                            <AlertCircle size={60} color="#ef4444" className={styles.modalIcon} />
                            <h2 className={styles.modalTitle}>Registration Failed</h2>
                            <p className={styles.modalText}>{errorMessage}</p>
                            <button className={styles.modalBtn} onClick={() => setErrorMessage('')} style={{backgroundColor: '#111827'}}>
                                Try Again
                            </button>
                        </div>
                    </div>
                </div>
            )}
        </div>
    );
};

export default Register;
