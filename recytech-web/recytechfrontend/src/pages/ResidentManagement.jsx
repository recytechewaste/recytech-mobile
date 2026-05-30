import { useEffect, useState } from 'react';
import api from '../api/client';
import Sidebar from '../components/Sidebar';
import styles from '../styles/UserManagement.module.css';
import { Edit2, Plus, RefreshCw, Save, Trash2, User, X } from 'lucide-react';

const emptyForm = {
    firstName: '',
    lastName: '',
    email: '',
    phone: '',
    mobileUserId: '',
    status: 'Active',
    source: 'Mobile Simulation',
    isTemporary: true
};

const ResidentManagement = () => {
    const [residents, setResidents] = useState([]);
    const [loading, setLoading] = useState(true);
    const [searchTerm, setSearchTerm] = useState('');
    const [statusFilter, setStatusFilter] = useState('');
    const [showModal, setShowModal] = useState(false);
    const [isEditing, setIsEditing] = useState(false);
    const [currentResidentId, setCurrentResidentId] = useState(null);
    const [deletingResident, setDeletingResident] = useState(null);
    const [formData, setFormData] = useState(emptyForm);
    const [errors, setErrors] = useState({});

    const fetchResidents = async () => {
        setLoading(true);
        try {
            const res = await api.get('/residents', { params: { limit: 1000 } });
            setResidents(res.data.residents || res.data || []);
        } catch (error) {
            console.error('Error fetching residents:', error);
        } finally {
            setLoading(false);
        }
    };

    useEffect(() => {
        Promise.resolve().then(fetchResidents);
    }, []);

    const validate = () => {
        const nextErrors = {};
        if (!formData.firstName.trim()) nextErrors.firstName = 'First name is required';
        if (!formData.lastName.trim()) nextErrors.lastName = 'Last name is required';
        if (!formData.email.trim()) {
            nextErrors.email = 'Email is required';
        } else if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(formData.email)) {
            nextErrors.email = 'Invalid email format';
        }

        setErrors(nextErrors);
        return Object.keys(nextErrors).length === 0;
    };

    const handleInputChange = (e) => {
        const { name, value, type, checked } = e.target;
        setFormData(prev => ({
            ...prev,
            [name]: type === 'checkbox' ? checked : value
        }));
        if (errors[name]) {
            setErrors(prev => ({ ...prev, [name]: '' }));
        }
    };

    const openAddModal = () => {
        setFormData(emptyForm);
        setErrors({});
        setCurrentResidentId(null);
        setIsEditing(false);
        setShowModal(true);
    };

    const openEditModal = (resident) => {
        setFormData({
            firstName: resident.firstName || '',
            lastName: resident.lastName || '',
            email: resident.email || '',
            phone: resident.phone || '',
            mobileUserId: resident.mobileUserId || '',
            status: resident.status || 'Active',
            source: resident.source || 'Mobile Simulation',
            isTemporary: resident.isTemporary !== false
        });
        setErrors({});
        setCurrentResidentId(resident._id);
        setIsEditing(true);
        setShowModal(true);
    };

    const handleSubmit = async (e) => {
        e.preventDefault();
        if (!validate()) return;

        try {
            if (isEditing) {
                await api.put(`/residents/${currentResidentId}`, formData);
            } else {
                await api.post('/residents/temp', formData);
            }

            setShowModal(false);
            fetchResidents();
        } catch (error) {
            alert(error.response?.data?.message || 'Unable to save mobile resident');
        }
    };

    const confirmDelete = async () => {
        try {
            await api.delete(`/residents/${deletingResident._id}`, { params: { hardDelete: true } });
            setDeletingResident(null);
            fetchResidents();
        } catch (error) {
            alert(error.response?.data?.message || 'Unable to delete mobile resident');
        }
    };

    const filteredResidents = residents.filter((resident) => {
        const search = searchTerm.toLowerCase();
        const matchesSearch = (
            resident.email?.toLowerCase().includes(search) ||
            resident.firstName?.toLowerCase().includes(search) ||
            resident.lastName?.toLowerCase().includes(search) ||
            resident.phone?.toLowerCase().includes(search) ||
            resident.mobileUserId?.toLowerCase().includes(search)
        );
        const matchesStatus = statusFilter ? resident.status === statusFilter : true;
        return matchesSearch && matchesStatus;
    });

    return (
        <div className={styles.container}>
            <Sidebar activePage="Mobile Residents" />
            <div className={styles.main}>
                <div className={styles.header}>
                    <div className={styles.titleGroup}>
                        <h1>Mobile Resident Management</h1>
                        <p>Manage simulated mobile app users, wallet balances, and recycling activity.</p>
                    </div>
                    <div className={styles.actionButtons}>
                        <button className={styles.addBtn} onClick={openAddModal}><Plus size={16}/> Add Mobile Resident</button>
                    </div>
                </div>

                <div className={styles.filterBar}>
                    <div className={styles.searchGroup}>
                        <input
                            type="text"
                            placeholder="Search by name, email, phone, or mobile ID..."
                            className={styles.searchInput}
                            value={searchTerm}
                            onChange={(e) => setSearchTerm(e.target.value)}
                        />
                        <select className={styles.selectInput} value={statusFilter} onChange={(e) => setStatusFilter(e.target.value)}>
                            <option value="">All Status</option>
                            <option value="Active">Active</option>
                            <option value="Inactive">Inactive</option>
                        </select>
                    </div>
                    <span className={styles.totalUsers}>Total Residents: {filteredResidents.length}</span>
                </div>

                <div className={styles.card}>
                    <table className={styles.table}>
                        <thead>
                            <tr>
                                <th className={styles.th}>Resident</th>
                                <th className={styles.th}>Contact</th>
                                <th className={styles.th}>Source</th>
                                <th className={styles.th}>Status</th>
                                <th className={styles.th}>Wallet Balance</th>
                                <th className={styles.th}>Total Earned</th>
                                <th className={styles.th}>Requests</th>
                                <th className={styles.th}>Actions</th>
                            </tr>
                        </thead>
                        <tbody>
                            {loading ? (
                                <tr><td colSpan="8" className={styles.td} style={{textAlign:'center', padding:'40px'}}><RefreshCw className={styles.spinner} /> Loading residents...</td></tr>
                            ) : filteredResidents.length === 0 ? (
                                <tr><td colSpan="8" className={styles.td} style={{textAlign:'center', padding:'40px'}}>No mobile residents found.</td></tr>
                            ) : (
                                filteredResidents.map((resident) => (
                                    <tr key={resident._id}>
                                        <td className={styles.td}>
                                            <div className={styles.userCell}>
                                                <div className={styles.avatar} style={{backgroundColor: '#eff6ff', color: '#2563EB'}}>
                                                    {resident.firstName?.[0] || <User size={14}/>}
                                                </div>
                                                <div className={styles.userInfo}>
                                                    <span className={styles.userName}>{resident.firstName} {resident.lastName}</span>
                                                    <span className={styles.userId}>ID: {resident.mobileUserId || resident._id.substring(resident._id.length - 4).toUpperCase()}</span>
                                                </div>
                                            </div>
                                        </td>
                                        <td className={styles.td}>
                                            <div>{resident.email}</div>
                                            <div style={{fontSize: '12px', color: '#6b7280'}}>{resident.phone || 'No phone'}</div>
                                        </td>
                                        <td className={styles.td}>
                                            <span style={{
                                                display: 'inline-flex',
                                                alignItems: 'center',
                                                padding: '4px 8px',
                                                borderRadius: '999px',
                                                fontSize: '12px',
                                                fontWeight: 600,
                                                background: resident.isTemporary ? '#fef3c7' : '#dcfce7',
                                                color: resident.isTemporary ? '#92400e' : '#166534'
                                            }}>
                                                {resident.isTemporary ? 'Temporary' : 'Linked'} · {resident.source || 'Mobile Simulation'}
                                            </span>
                                        </td>
                                        <td className={styles.td}>
                                            <span className={resident.status === 'Active' ? styles.statusActive : styles.statusInactive}>
                                                {resident.status || 'Active'}
                                            </span>
                                        </td>
                                        <td className={styles.td} style={{color: '#059669', fontWeight: 700}}>PHP {resident.walletBalance?.toFixed(2)}</td>
                                        <td className={styles.td}>PHP {resident.totalEarned?.toFixed(2)}</td>
                                        <td className={styles.td}>{resident.requestCount || 0}</td>
                                        <td className={styles.td}>
                                            <div className={styles.actionIcons}>
                                                <button title="Edit resident" className={styles.iconBtn} onClick={() => openEditModal(resident)}><Edit2 size={16}/></button>
                                                <button title="Delete resident" className={styles.iconBtnDanger} onClick={() => setDeletingResident(resident)}><Trash2 size={16}/></button>
                                            </div>
                                        </td>
                                    </tr>
                                ))
                            )}
                        </tbody>
                    </table>
                </div>

                {showModal && (
                    <div className={styles.modalOverlay}>
                        <div className={styles.modalContent}>
                            <div className={styles.modalHeader}>
                                <h2 className={styles.modalTitle}>{isEditing ? 'Edit Mobile Resident' : 'Add Mobile Resident'}</h2>
                                <button onClick={() => setShowModal(false)} className={styles.closeBtn}><X size={20}/></button>
                            </div>
                            <form onSubmit={handleSubmit} className={styles.form}>
                                <div className={styles.formGroup}>
                                    <label>First Name</label>
                                    <input name="firstName" value={formData.firstName} onChange={handleInputChange} className={`${styles.input} ${errors.firstName ? styles.inputError : ''}`} />
                                    {errors.firstName && <span className={styles.error}>{errors.firstName}</span>}
                                </div>
                                <div className={styles.formGroup}>
                                    <label>Last Name</label>
                                    <input name="lastName" value={formData.lastName} onChange={handleInputChange} className={`${styles.input} ${errors.lastName ? styles.inputError : ''}`} />
                                    {errors.lastName && <span className={styles.error}>{errors.lastName}</span>}
                                </div>
                                <div className={styles.formGroup}>
                                    <label>Email Address</label>
                                    <input name="email" type="email" value={formData.email} onChange={handleInputChange} className={`${styles.input} ${errors.email ? styles.inputError : ''}`} />
                                    {errors.email && <span className={styles.error}>{errors.email}</span>}
                                </div>
                                <div className={styles.formGroup}>
                                    <label>Phone Number</label>
                                    <input name="phone" value={formData.phone} onChange={handleInputChange} className={styles.input} />
                                </div>
                                <div className={styles.formGroup}>
                                    <label>Mobile User ID</label>
                                    <input name="mobileUserId" value={formData.mobileUserId} onChange={handleInputChange} className={styles.input} placeholder="e.g. mobile-demo-001" />
                                </div>
                                <div className={styles.formGroup}>
                                    <label>Status</label>
                                    <select name="status" value={formData.status} onChange={handleInputChange} className={styles.selectInput} style={{width: '100%', border: '1px solid #d1d5db'}}>
                                        <option value="Active">Active</option>
                                        <option value="Inactive">Inactive</option>
                                    </select>
                                </div>
                                <div className={styles.formGroup}>
                                    <label>Source</label>
                                    <select name="source" value={formData.source} onChange={handleInputChange} className={styles.selectInput} style={{width: '100%', border: '1px solid #d1d5db'}}>
                                        <option value="Mobile Simulation">Mobile Simulation</option>
                                        <option value="Mobile App">Mobile App</option>
                                        <option value="Web">Web</option>
                                        <option value="Imported">Imported</option>
                                    </select>
                                </div>
                                <label style={{display: 'flex', alignItems: 'center', gap: '8px', color: '#374151', fontSize: '14px'}}>
                                    <input type="checkbox" name="isTemporary" checked={formData.isTemporary} onChange={handleInputChange} />
                                    Temporary account
                                </label>
                                <div className={styles.modalFooter}>
                                    <button type="button" onClick={() => setShowModal(false)} className={styles.cancelBtn}>Cancel</button>
                                    <button type="submit" className={styles.submitBtn}><Save size={16} style={{marginRight:'6px'}}/> Save Resident</button>
                                </div>
                            </form>
                        </div>
                    </div>
                )}

                {deletingResident && (
                    <div className={styles.modalOverlay}>
                        <div className={styles.modalContent} style={{maxWidth: '400px'}}>
                            <div className={styles.modalHeader}>
                                <h2 className={styles.modalTitle}>Confirm Deletion</h2>
                                <button onClick={() => setDeletingResident(null)} className={styles.closeBtn}><X size={20}/></button>
                            </div>
                            <p style={{color:'#666', marginBottom:'24px'}}>
                                Delete {deletingResident.firstName} {deletingResident.lastName}? This also removes related payout transactions for this resident.
                            </p>
                            <div className={styles.modalFooter}>
                                <button onClick={() => setDeletingResident(null)} className={styles.cancelBtn}>Cancel</button>
                                <button onClick={confirmDelete} className={styles.deleteBtn}>Delete</button>
                            </div>
                        </div>
                    </div>
                )}
            </div>
        </div>
    );
};

export default ResidentManagement;
