import { useEffect, useState } from 'react';
import api from '../api/client';
import Sidebar from '../components/Sidebar';
import styles from '../styles/UserManagement.module.css';
import { Plus, Eye, Edit2, Trash2, X, Save, EyeOff, Copy, Check } from 'lucide-react';

const UserManagement = () => {
    const [users, setUsers] = useState([]);
    const [loading, setLoading] = useState(true);
    
    // Modal State
    const [showModal, setShowModal] = useState(false);
    const [isEditing, setIsEditing] = useState(false);
    const [currentUserId, setCurrentUserId] = useState(null);
    const [formData, setFormData] = useState({
        firstName: '',
        lastName: '',
        email: '',
        password: '',
        confirmPassword: '',
        role: 'Staff',
        status: 'Active'
    });
    const [showPassword, setShowPassword] = useState(false);
    const [showConfirmPassword, setShowConfirmPassword] = useState(false);
    const [errors, setErrors] = useState({});
    const [searchTerm, setSearchTerm] = useState('');
    const [roleFilter, setRoleFilter] = useState('');
    const [statusFilter, setStatusFilter] = useState('');
    const [deletingUserId, setDeletingUserId] = useState(null);
    const [copied, setCopied] = useState(false);

    const generateStrongPassword = () => {
        const charset = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%^&*()_+";
        let password = "";
        // Ensure at least one of each required type is included
        password += "ABCDEFGHIJKLMNOPQRSTUVWXYZ"[Math.floor(Math.random() * 26)];
        password += "0123456789"[Math.floor(Math.random() * 10)];
        password += "!@#$%^&*()_+"[Math.floor(Math.random() * 12)];
        
        for (let i = 0; i < 9; i++) {
            password += charset[Math.floor(Math.random() * charset.length)];
        }
        // Shuffle the result
        return password.split('').sort(() => 0.5 - Math.random()).join('');
    };

    const fetchUsers = async () => {
        try {
            const userInfo = localStorage.getItem('userInfo') ? JSON.parse(localStorage.getItem('userInfo')) : null;
            
            if (!userInfo || !userInfo.token) {
                // Handle unauthenticated state (e.g., redirect to login or show error)
                return; 
            }

            // Fetching from your backend. Adjust endpoint if needed (e.g., /api/users)
            // If you don't have a single /users endpoint yet, we can combine collectors + admins here
            const response = await api.get('/users'); 
            setUsers(response.data);
            setLoading(false);
        } catch (error) {
            console.error("Error fetching users:", error);
            setLoading(false);
        }
    };

    useEffect(() => {
        Promise.resolve().then(fetchUsers);
    }, []);

    const validate = () => {
        const newErrors = {};
        if (!formData.firstName?.trim()) newErrors.firstName = 'First Name is required';
        if (!formData.lastName?.trim()) newErrors.lastName = 'Last Name is required';
        
        const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
        if (!formData.email.trim()) {
            newErrors.email = 'Email is required';
        } else if (!emailRegex.test(formData.email)) {
            newErrors.email = 'Invalid email format';
        }

        if (!isEditing && !formData.password) {
            newErrors.password = 'Password is required';
        } else if (formData.password && formData.password.length < 8) {
            newErrors.password = 'Password must be at least 8 characters';
        }

        if (formData.password !== formData.confirmPassword) {
            newErrors.confirmPassword = 'Passwords do not match';
        }

        setErrors(newErrors);
        return Object.keys(newErrors).length === 0;
    };

    const handleInputChange = (e) => {
        setFormData({ ...formData, [e.target.name]: e.target.value });
        if (errors[e.target.name]) {
            setErrors({ ...errors, [e.target.name]: '' });
        }
    };

    const handleGeneratePassword = () => {
        const newPass = generateStrongPassword();
        setFormData({ ...formData, password: newPass, confirmPassword: newPass });
        setErrors({ ...errors, password: '', confirmPassword: '' });
    };

    const copyToClipboard = () => {
        if (!formData.password) return;
        navigator.clipboard.writeText(formData.password);
        setCopied(true);
        setTimeout(() => setCopied(false), 2000);
    };

    const openAddModal = () => {
        setFormData({ firstName: '', lastName: '', email: '', password: '', confirmPassword: '', role: 'Staff', status: 'Active' });
        setErrors({});
        setShowPassword(false);
        setShowConfirmPassword(false);
        setIsEditing(false);
        setShowModal(true);
    };

    const openEditModal = (user) => {
        setFormData({
            firstName: user.firstName || '',
            lastName: user.lastName || '',
            email: user.email,
            password: '', // Leave blank to keep current
            confirmPassword: '',
            role: user.role || 'Staff',
            status: user.status || 'Active'
        });
        setErrors({});
        setShowPassword(false);
        setShowConfirmPassword(false);
        setCurrentUserId(user._id);
        setIsEditing(true);
        setShowModal(true);
    };

    const handleSubmit = async (e) => {
        e.preventDefault();
        if (!validate()) return;

        try {
            if (isEditing) {
                await api.put(`/users/${currentUserId}`, formData);
            } else {
                await api.post('/users', formData);
            }
            setShowModal(false);
            fetchUsers();
        } catch (error) {
            alert(error.response?.data?.message || "Operation failed");
        }
    };

    const handleDelete = (id) => {
        setDeletingUserId(id);
    };

    const confirmDelete = async () => {
        try {
            const userInfo = localStorage.getItem('userInfo') ? JSON.parse(localStorage.getItem('userInfo')) : null;
            
            if (!userInfo || !userInfo.token) {
                return alert("You must be logged in.");
            }

            await api.delete(`/users/${deletingUserId}`);
            fetchUsers();
        } catch (error) {
            console.error("Error deleting user:", error);
            alert("Failed to delete user.");
        }
        setDeletingUserId(null);
    };

    const filteredUsers = users.filter(user => {
        const matchesSearch = user.firstName?.toLowerCase().includes(searchTerm.toLowerCase()) || 
                              user.lastName?.toLowerCase().includes(searchTerm.toLowerCase()) || 
                              user.email?.toLowerCase().includes(searchTerm.toLowerCase());
        const matchesRole = roleFilter ? user.role === roleFilter : true;
        const matchesStatus = statusFilter ? user.status === statusFilter : true;
        return matchesSearch && matchesRole && matchesStatus;
    });

    return (
        <div className={styles.container}>
            <Sidebar activePage="User Management" />
            <div className={styles.main}>
                
                {/* Header */}
                <div className={styles.header}>
                    <div className={styles.titleGroup}>
                        <h1>User Management</h1>
                        <p>Manage and monitor registered system users</p>
                    </div>
                    <div className={styles.actionButtons}>
                        <button className={styles.addBtn} onClick={openAddModal}><Plus size={16}/> Add User</button>
                    </div>
                </div>

                {/* Filters */}
                <div className={styles.filterBar}>
                    <div className={styles.searchGroup}>
                        <input 
                            type="text" 
                            placeholder="Search users..." 
                            className={styles.searchInput} 
                            value={searchTerm}
                            onChange={(e) => setSearchTerm(e.target.value)}
                        />
                        <select className={styles.selectInput} value={roleFilter} onChange={(e) => setRoleFilter(e.target.value)}>
                            <option value="">All Roles</option>
                            <option value="Staff">Staff</option>
                            <option value="Admin">Admin</option>
                            <option value="Super Admin">Super Admin</option>
                        </select>
                        <select className={styles.selectInput} value={statusFilter} onChange={(e) => setStatusFilter(e.target.value)}>
                            <option value="">All Status</option>
                            <option value="Active">Active</option>
                            <option value="Inactive">Inactive</option>
                        </select>
                    </div>
                    <span className={styles.totalUsers}>Total Users: {filteredUsers.length}</span>
                </div>

                {/* Table */}
                <div className={styles.card}>
                    <table className={styles.table}>
                        <thead>
                            <tr>
                                <th className={styles.th} style={{width:'50px'}}>#</th>
                                <th className={styles.th}>User</th>
                                <th className={styles.th}>Email</th>
                                <th className={styles.th}>Role</th>
                                <th className={styles.th}>Status</th>
                                <th className={styles.th}>Last Login</th>
                                <th className={styles.th}>Actions</th>
                            </tr>
                        </thead>
                        <tbody>
                            {loading ? (
                                <tr>
                                    <td colSpan="7" className={styles.td} style={{textAlign: 'center'}}>Loading users...</td>
                                </tr>
                            ) : filteredUsers.length === 0 ? (
                                <tr>
                                    <td colSpan="7" className={styles.td} style={{textAlign: 'center'}}>No users found.</td>
                                </tr>
                            ) : (
                                filteredUsers.map((user, index) => (
                                    <tr key={user._id || index}>
                                        <td className={styles.td}>{index + 1}</td>
                                        <td className={styles.td}>
                                            <div className={styles.userCell}>
                                                <div className={styles.avatar}>
                                                    {user.firstName ? user.firstName.charAt(0).toUpperCase() : '?'}
                                                </div>
                                                <div className={styles.userInfo}>
                                                    <span className={styles.userName}>{`${user.firstName} ${user.lastName}`.trim() || "Unknown"}</span>
                                                    <span className={styles.userId}>ID: {user._id ? `USR-${user._id.substring(user._id.length - 4)}` : 'N/A'}</span>
                                                </div>
                                            </div>
                                        </td>
                                        <td className={styles.td}>{user.email}</td>
                                        <td className={styles.td}>{user.role || 'Staff'}</td>
                                        <td className={styles.td}>
                                            <span className={user.status === 'Active' ? styles.statusActive : styles.statusInactive}>
                                                {user.status || 'Active'}
                                            </span>
                                        </td>
                                        <td className={styles.td}>
                            {user.lastLogin ? (
                                <div style={{display: 'flex', flexDirection: 'column'}}>
                                    <span>{new Date(user.lastLogin).toLocaleDateString()}</span>
                                    <span style={{fontSize: '11px', color: '#6b7280'}}>{new Date(user.lastLogin).toLocaleTimeString([], {hour: '2-digit', minute:'2-digit'})}</span>
                                </div>
                            ) : (
                                <span style={{color: '#9ca3af', fontStyle: 'italic'}}>Never</span>
                            )}
                                        </td>
                                        <td className={styles.td}>
                                            <div className={styles.actionIcons}>
                                                <button title="Edit user" className={styles.iconBtn} onClick={() => openEditModal(user)}><Edit2 size={16}/></button>
                                                <button title="Delete user" className={styles.iconBtnDanger} onClick={() => handleDelete(user._id)}><Trash2 size={16}/></button>
                                            </div>
                                        </td>
                                    </tr>
                                ))
                            )}
                        </tbody>
                    </table>
                </div>

                {/* ADD/EDIT MODAL */}
                {showModal && (
                    <div className={styles.modalOverlay}>
                        <div className={styles.modalContent}>
                            <div className={styles.modalHeader}>
                                <h2 className={styles.modalTitle}>{isEditing ? 'Edit User' : 'Add New User'}</h2>
                                <button onClick={() => setShowModal(false)} className={styles.closeBtn}><X size={20}/></button>
                            </div>
                            <form onSubmit={handleSubmit} className={styles.form}>
                                <div className={styles.formGroup}>
                                    <label>First Name</label>
                                    <input 
                                        name="firstName" 
                                        value={formData.firstName} 
                                        onChange={handleInputChange} 
                                        className={`${styles.input} ${errors.firstName ? styles.inputError : ''}`} 
                                    />
                                    {errors.firstName && <span className={styles.error}>{errors.firstName}</span>}
                                </div>
                                <div className={styles.formGroup}>
                                    <label>Last Name</label>
                                    <input 
                                        name="lastName" 
                                        value={formData.lastName} 
                                        onChange={handleInputChange} 
                                        className={`${styles.input} ${errors.lastName ? styles.inputError : ''}`} 
                                    />
                                    {errors.lastName && <span className={styles.error}>{errors.lastName}</span>}
                                </div>
                                <div className={styles.formGroup}>
                                    <label>Email Address</label>
                                    <input 
                                        name="email" 
                                        type="email" 
                                        value={formData.email} 
                                        onChange={handleInputChange} 
                                        className={`${styles.input} ${errors.email ? styles.inputError : ''}`} 
                                    />
                                    {errors.email && <span className={styles.error}>{errors.email}</span>}
                                </div>
                                <div className={styles.formGroup}>
                                    <label>Role</label>
                                    <select name="role" value={formData.role} onChange={handleInputChange} className={styles.selectInput} style={{width: '100%', border: '1px solid #d1d5db'}}>
                                        <option value="Staff">Staff</option>
                                        <option value="Admin">Admin</option>
                                        <option value="Super Admin">Super Admin</option>
                                    </select>
                                </div>
                                <div className={styles.formGroup}>
                                    <label>Status</label>
                                    <select name="status" value={formData.status} onChange={handleInputChange} className={styles.selectInput} style={{width: '100%', border: '1px solid #d1d5db'}}>
                                        <option value="Active">Active</option>
                                        <option value="Inactive">Inactive</option>
                                    </select>
                                </div>
                                <div className={styles.formGroup}>
                                    <div className={styles.passwordHeader}>
                                        <label>Password {isEditing && <span style={{fontSize:'10px', color:'#666'}}>(Leave blank to keep current)</span>}</label>
                                        {!isEditing && (
                                            <button 
                                                type="button" 
                                                className={styles.generateBtn} 
                                                onClick={handleGeneratePassword}
                                            >
                                                Generate Strong Password
                                            </button>
                                        )}
                                    </div>
                                    <div className={styles.passwordWrapper}>
                                        <input 
                                            name="password" 
                                            type={showPassword ? "text" : "password"} 
                                            value={formData.password} 
                                            onChange={handleInputChange} 
                                            className={`${styles.input} ${errors.password ? styles.inputError : ''}`} 
                                            style={{paddingRight: '35px'}}
                                        />
                                        {formData.password && !isEditing && (
                                            <button type="button" className={styles.copyBtn} onClick={copyToClipboard} title="Copy to clipboard">
                                                {copied ? <Check size={16} color="#059669" /> : <Copy size={16} />}
                                            </button>
                                        )}
                                        <button type="button" className={styles.eyeBtn} onClick={() => setShowPassword(!showPassword)}>
                                            {showPassword ? <EyeOff size={16} /> : <Eye size={16} />}
                                        </button>
                                    </div>
                                    {errors.password && <span className={styles.error}>{errors.password}</span>}
                                </div>
                                <div className={styles.formGroup}>
                                    <label>Confirm Password</label>
                                    <div className={styles.passwordWrapper}>
                                        <input 
                                            name="confirmPassword" 
                                            type={showConfirmPassword ? "text" : "password"} 
                                            value={formData.confirmPassword} 
                                            onChange={handleInputChange} 
                                            className={`${styles.input} ${errors.confirmPassword ? styles.inputError : ''}`} 
                                            style={{paddingRight: '35px'}}
                                        />
                                        <button type="button" className={styles.eyeBtn} onClick={() => setShowConfirmPassword(!showConfirmPassword)}>
                                            {showConfirmPassword ? <EyeOff size={16} /> : <Eye size={16} />}
                                        </button>
                                    </div>
                                    {errors.confirmPassword && <span className={styles.error}>{errors.confirmPassword}</span>}
                                </div>
                                
                                <div className={styles.modalFooter}>
                                    <button type="button" onClick={() => setShowModal(false)} className={styles.cancelBtn}>Cancel</button>
                                    <button type="submit" className={styles.submitBtn}><Save size={16} style={{marginRight:'6px'}}/> Save User</button>
                                </div>
                            </form>
                        </div>
                    </div>
                )}

                {/* DELETE CONFIRMATION MODAL */}
                {deletingUserId && (
                    <div className={styles.modalOverlay}>
                        <div className={styles.modalContent} style={{maxWidth: '400px'}}>
                            <div className={styles.modalHeader}>
                                <h2 className={styles.modalTitle}>Confirm Deletion</h2>
                                <button onClick={() => setDeletingUserId(null)} className={styles.closeBtn}><X size={20}/></button>
                            </div>
                            <p style={{color:'#666', marginBottom:'24px'}}>Are you sure you want to delete this user? This action cannot be undone.</p>
                            <div className={styles.modalFooter}>
                                <button onClick={() => setDeletingUserId(null)} className={styles.cancelBtn}>Cancel</button>
                                <button onClick={confirmDelete} className={styles.deleteBtn}>Delete</button>
                            </div>
                        </div>
                    </div>
                )}
            </div>
        </div>
    );
};

export default UserManagement;
