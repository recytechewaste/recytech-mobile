import { useEffect, useState } from 'react';
import api from '../api/client';
import Sidebar from '../components/Sidebar';
import styles from '../styles/Collectors.module.css';
import { Plus, Search, Truck, Phone, Edit2, Trash2, X, Filter, Copy, Check, Eye, EyeOff } from 'lucide-react';

const Collectors = () => {
    const [collectors, setCollectors] = useState([]);
    const [formData, setFormData] = useState({ firstName: '', lastName: '', phone: '', vehiclePlate: '', vehicleType: '', email: '', password: '', status: 'Active' });
    const [errors, setErrors] = useState({});
    
    // UI States
    const [showModal, setShowModal] = useState(false);
    const [editingId, setEditingId] = useState(null);
    const [deletingId, setDeletingId] = useState(null);
    const [searchTerm, setSearchTerm] = useState('');
    const [statusFilter, setStatusFilter] = useState('');
    const [vehicleTypeFilter, setVehicleTypeFilter] = useState('');
    const [showSuccessModal, setShowSuccessModal] = useState(false);
    const [successMessage, setSuccessMessage] = useState('');
    const [showPassword, setShowPassword] = useState(false);
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

    const fetchCollectors = async () => {
        try {
            const { data } = await api.get('/collectors');
            setCollectors(data);
        } catch (error) {
            console.error("Error fetching collectors", error);
        }
    };

    useEffect(() => {
        Promise.resolve().then(fetchCollectors);
    }, []);

    const validate = () => {
        const newErrors = {};
        if (!formData.firstName?.trim()) newErrors.firstName = 'First Name is required.';
        if (!formData.lastName?.trim()) newErrors.lastName = 'Last Name is required.';
        if (!formData.phone.trim()) {
            newErrors.phone = 'Phone number is required.';
        } else {
            const phoneDigits = formData.phone.replace(/\D/g, '');
            if (phoneDigits.length < 10 || phoneDigits.length > 15) {
                newErrors.phone = 'Enter valid phone (10-15 digits).';
            }
        }
        if (!formData.vehiclePlate.trim()) newErrors.vehiclePlate = 'Vehicle plate is required.';
        if (!formData.vehicleType) newErrors.vehicleType = 'Vehicle type is required.';
        
        // Only validate email/password if creating a NEW collector
        if (!editingId) {
            if (!formData.email?.trim()) newErrors.email = 'Email is required for login.';
            if (!formData.password?.trim()) {
                newErrors.password = 'Password is required for login.';
            } else if (formData.password.length < 8) {
                newErrors.password = 'Password must be at least 8 characters.';
            }
        }

        setErrors(newErrors);
        return Object.keys(newErrors).length === 0;
    };

    const handleGeneratePassword = () => {
        const newPass = generateStrongPassword();
        setFormData(prev => ({ ...prev, password: newPass }));
        setErrors(prev => ({ ...prev, password: '' }));
    };

    const copyToClipboard = () => {
        if (!formData.password) return;
        navigator.clipboard.writeText(formData.password);
        setCopied(true);
        setTimeout(() => setCopied(false), 2000);
    };

    const handleOpenAdd = () => {
        setFormData({ firstName: '', lastName: '', phone: '', vehiclePlate: '', vehicleType: '', email: '', password: '', status: 'Active' });
        setEditingId(null);
        setErrors({});
        setShowModal(true);
        setShowPassword(false);
        setCopied(false);
    };

    const handleEdit = (collector) => {
        // Don't load email/password for editing to avoid overwriting with blanks
        setFormData({ firstName: collector.firstName, lastName: collector.lastName, phone: collector.phone, vehiclePlate: collector.vehiclePlate, vehicleType: collector.vehicleType || '', email: '', password: '', status: collector.status || 'Active' });
        setEditingId(collector._id);
        setErrors({});
        setShowModal(true);
        setShowPassword(false);
        setCopied(false);
    };

    const handleSubmit = async (e) => {
        e.preventDefault();
        if (!validate()) return;

        try {
            if (editingId) {
                await api.put(`/collectors/${editingId}`, formData);
                setSuccessMessage('The collector profile has been updated successfully.');
            } else {
                await api.post('/collectors', formData);
                setSuccessMessage('New collector has been successfully registered and added to the system.');
            }
            setShowModal(false);
            setShowSuccessModal(true);
            fetchCollectors();
        } catch (error) {
            alert(error.response?.data?.message || 'Error saving collector');
        }
    };

    const handleDeleteClick = (id) => {
        setDeletingId(id);
    };

    const confirmDelete = async () => {
        try {
            await api.delete(`/collectors/${deletingId}`);
            fetchCollectors();
        } catch (error) {
            console.error(error);
        }
        setDeletingId(null);
    };

    const handleChange = (e) => {
        setFormData(prev => ({ ...prev, [e.target.name]: e.target.value }));
    };

    const handleClearFilters = () => {
        setSearchTerm('');
        setStatusFilter('');
        setVehicleTypeFilter('');
    };

    // Filter Logic
    const filteredCollectors = collectors.filter(c => {
        const matchesSearch = c.firstName?.toLowerCase().includes(searchTerm.toLowerCase()) ||
                             c.lastName?.toLowerCase().includes(searchTerm.toLowerCase()) ||
                             c.vehiclePlate.toLowerCase().includes(searchTerm.toLowerCase());
        const matchesStatus = statusFilter ? c.status === statusFilter : true;
        const matchesVehicleType = vehicleTypeFilter ? c.vehicleType === vehicleTypeFilter : true;
        return matchesSearch && matchesStatus && matchesVehicleType;
    });

    return (
        <div className={styles.container}>
            <Sidebar activePage="Collector Management" />

            <div className={styles.main}>
                
                {/* HEADER */}
                <div className={styles.header}>
                    <div className={styles.titleGroup}>
                        <h1 className={styles.pageTitle}>Collector Management</h1>
                        <p className={styles.subTitle}>Manage driver profiles and vehicle assignments.</p>
                    </div>
                    <button onClick={handleOpenAdd} className={styles.addBtn} style={{backgroundColor: '#2563EB'}}>
                        <Plus size={18} /> Add Collector
                    </button>
                </div>

                {/* FILTERS */}
                <div className={styles.filterBar}>
                    <div className={styles.searchGroup}>
                        <Search size={18} className={styles.searchIcon} />
                        <input 
                            type="text" 
                            placeholder="Search by name or plate number..." 
                            className={styles.searchInput} 
                            value={searchTerm}
                            onChange={(e) => setSearchTerm(e.target.value)}
                        />
                    </div>
                    <div className={styles.filterGroup}>
                        <Filter size={18} className={styles.filterIcon} />
                        <select 
                            className={styles.selectInput}
                            value={statusFilter}
                            onChange={(e) => setStatusFilter(e.target.value)}
                        >
                            <option value="">All Status</option>
                            <option value="Active">Active</option>
                            <option value="Inactive">Inactive</option>
                        </select>
                    </div>
                    <div className={styles.filterGroup}>
                        <Truck size={18} className={styles.filterIcon} />
                        <select 
                            className={styles.selectInput}
                            value={vehicleTypeFilter}
                            onChange={(e) => setVehicleTypeFilter(e.target.value)}
                        >
                            <option value="">All Vehicles</option>
                            <option value="E-Trike">E-Trike</option>
                            <option value="Truck">Truck</option>
                            <option value="Bike">Bike</option>
                        </select>
                    </div>
                    <button className={styles.clearBtn} onClick={handleClearFilters}>Clear All</button>
                </div>

                {/* TABLE */}
                <div className={styles.card}>
                    <table className={styles.table}>
                        <thead>
                            <tr>
                                <th className={styles.th} style={{width:'50px'}}>#</th>
                                <th className={styles.th}>Driver Name</th>
                                <th className={styles.th}>Contact Info</th>
                                <th className={styles.th}>Vehicle Plate</th>
                                <th className={styles.th}>Status</th>
                                <th className={styles.th}>Actions</th>
                            </tr>
                        </thead>
                        <tbody>
                            {filteredCollectors.length === 0 ? (
                                <tr>
                                    <td colSpan="6" className={styles.emptyTd}>No collectors found.</td>
                                </tr>
                            ) : (
                                filteredCollectors.map((c, index) => (
                                    <tr key={c._id} className={styles.tr}>
                                        <td className={styles.td}>{index + 1}</td>
                                        <td className={styles.td}>
                                            <div className={styles.driverCell}>
                                                <div className={styles.avatar}>{c.firstName ? c.firstName.charAt(0).toUpperCase() : '?'}</div>
                                                <div>
                                                    <div className={styles.driverName}>{`${c.firstName} ${c.lastName}`}</div>
                                                    <div className={styles.driverId}>ID: {c._id.substring(c._id.length - 4)}</div>
                                                </div>
                                            </div>
                                        </td>
                                        <td className={styles.td}>
                                            <div className={styles.iconText}><Phone size={14}/> {c.phone}</div>
                                        </td>
                                        <td className={styles.td}>
                                            <div className={styles.plateBadge}><Truck size={12}/> {c.vehiclePlate}</div>
                                        </td>
                                        <td className={styles.td}>
                                            <span className={`${styles.statusBadge} ${c.status === 'Inactive' ? styles.inactive : styles.active}`}>
                                                {c.status || 'Active'}
                                            </span>
                                        </td>
                                        <td className={styles.td}>
                                            <div className={styles.actions}>
                                                <button onClick={() => handleEdit(c)} className={styles.iconBtn}><Edit2 size={16}/></button>
                                                <button onClick={() => handleDeleteClick(c._id)} className={styles.iconBtnDanger}><Trash2 size={16}/></button>
                                            </div>
                                        </td>
                                    </tr>
                                ))
                            )}
                        </tbody>
                    </table>
                </div>

                {/* --- ADD/EDIT MODAL --- */}
                {showModal && (
                    <div className={styles.modalOverlay}>
                        <div className={styles.modalContent}>
                            <div className={styles.modalHeader}>
                                <h2>{editingId ? 'Edit Collector' : 'Add New Collector'}</h2>
                                <button onClick={() => setShowModal(false)} className={styles.closeBtn}><X size={20}/></button>
                            </div>
                            <form onSubmit={handleSubmit} className={styles.form}>
                                <div className={styles.formGroup}>
                                    <label>First Name</label>
                                    <input 
                                        name="firstName" 
                                        value={formData.firstName} 
                                        onChange={handleChange} 
                                        className={errors.firstName ? styles.inputError : styles.input}
                                        placeholder="e.g. Juan"
                                    />
                                    {errors.firstName && <span className={styles.error}>{errors.firstName}</span>}
                                </div>
                                <div className={styles.formGroup}>
                                    <label>Last Name</label>
                                    <input 
                                        name="lastName" 
                                        value={formData.lastName} 
                                        onChange={handleChange} 
                                        className={errors.lastName ? styles.inputError : styles.input}
                                        placeholder="e.g. Dela Cruz"
                                    />
                                    {errors.lastName && <span className={styles.error}>{errors.lastName}</span>}
                                </div>
                                <div className={styles.formGroup}>
                                    <label>Email Address {!editingId && <span style={{color:'red'}}>*</span>}</label>
                                    <input 
                                        name="email" 
                                        type="email"
                                        value={formData.email} 
                                        onChange={handleChange} 
                                        className={errors.email ? styles.inputError : styles.input}
                                        placeholder="e.g. driver@recytech.com"
                                        disabled={!!editingId} // Disable email edit here for simplicity
                                    />
                                    {errors.email && <span className={styles.error}>{errors.email}</span>}
                                </div>
                                {!editingId && (
                                <div className={styles.formGroup}>
                                    <div className={styles.passwordHeader}>
                                        <label>Password <span style={{color:'red'}}>*</span></label>
                                        <button 
                                            type="button" 
                                            className={styles.generateBtn} 
                                            onClick={handleGeneratePassword}
                                        >
                                            Generate Strong Password
                                        </button>
                                    </div>
                                    <div className={styles.passwordWrapper}>
                                        <input 
                                            name="password" 
                                            type={showPassword ? "text" : "password"}
                                            value={formData.password} 
                                            onChange={handleChange} 
                                            className={errors.password ? styles.inputError : styles.input}
                                            placeholder="Login password"
                                            style={{paddingRight: '65px'}}
                                        />
                                        {formData.password && (
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
                                )}
                                <div className={styles.formGroup}>
                                    <label>Phone Number</label>
                                    <input 
                                        name="phone" 
                                        value={formData.phone} 
                                        onChange={handleChange} 
                                        className={errors.phone ? styles.inputError : styles.input}
                                        placeholder="e.g. 09123456789"
                                    />
                                    {errors.phone && <span className={styles.error}>{errors.phone}</span>}
                                </div>
                                <div className={styles.formGroup}>
                                    <label>Vehicle Type</label>
                                    <select 
                                        name="vehicleType" 
                                        value={formData.vehicleType} 
                                        onChange={handleChange} 
                                        className={errors.vehicleType ? styles.inputError : styles.input}
                                    >
                                        <option value="">Select Type</option>
                                        <option value="E-Trike">E-Trike</option>
                                        <option value="Truck">Truck</option>
                                        <option value="Bike">Bike</option>
                                    </select>
                                    {errors.vehicleType && <span className={styles.error}>{errors.vehicleType}</span>}
                                </div>
                                <div className={styles.formGroup}>
                                    <label>Status</label>
                                    <select 
                                        name="status" 
                                        value={formData.status} 
                                        onChange={handleChange} 
                                        className={styles.input}
                                    >
                                        <option value="Active">Active</option>
                                        <option value="Inactive">Inactive</option>
                                    </select>
                                </div>
                                <div className={styles.formGroup}>
                                    <label>Vehicle Plate Number</label>
                                    <input 
                                        name="vehiclePlate" 
                                        value={formData.vehiclePlate} 
                                        onChange={handleChange} 
                                        className={errors.vehiclePlate ? styles.inputError : styles.input}
                                        placeholder="e.g. ABC 1234"
                                    />
                                    {errors.vehiclePlate && <span className={styles.error}>{errors.vehiclePlate}</span>}
                                </div>
                                <div className={styles.modalFooter}>
                                    <button type="button" onClick={() => setShowModal(false)} className={styles.cancelBtn}>Cancel</button>
                                    <button type="submit" className={styles.submitBtn} style={{backgroundColor: '#2563EB'}}>{editingId ? 'Save Changes' : 'Create Collector'}</button>
                                </div>
                            </form>
                        </div>
                    </div>
                )}

                {/* --- SUCCESS DIALOGUE --- */}
                {showSuccessModal && (
                    <div className={styles.modalOverlay}>
                        <div className={`${styles.modalContent} ${styles.successModal}`}>
                            <div className={styles.successIconWrapper}>
                                <Check size={40} color="#059669" />
                            </div>
                            <h2 className={styles.successTitle}>Action Successful</h2>
                            <p className={styles.successText}>{successMessage}</p>
                            <div className={styles.modalFooter} style={{borderTop: 'none', justifyContent: 'center', marginTop: '16px'}}>
                                <button onClick={() => setShowSuccessModal(false)} className={styles.submitBtn} style={{width: '100%', backgroundColor: '#059669'}}>
                                    Continue
                                </button>
                            </div>
                        </div>
                    </div>
                )}

                {/* --- DELETE CONFIRMATION MODAL --- */}
                {deletingId && (
                    <div className={styles.modalOverlay}>
                        <div className={styles.modalContent} style={{maxWidth: '400px'}}>
                            <div className={styles.modalHeader}>
                                <h2>Confirm Deletion</h2>
                                <button onClick={() => setDeletingId(null)} className={styles.closeBtn}><X size={20}/></button>
                            </div>
                            <p style={{color:'#666', marginBottom:'24px'}}>Are you sure you want to remove this collector? This action cannot be undone.</p>
                            <div className={styles.modalFooter}>
                                <button onClick={() => setDeletingId(null)} className={styles.cancelBtn}>Cancel</button>
                                <button onClick={confirmDelete} className={styles.deleteBtn} style={{backgroundColor: '#ef4444'}}>Delete</button>
                            </div>
                        </div>
                    </div>
                )}

            </div>
        </div>
    );
};

export default Collectors;
