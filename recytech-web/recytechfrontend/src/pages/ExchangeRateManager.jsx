import { useEffect, useState } from 'react';
import api from '../api/client';
import Sidebar from '../components/Sidebar';
import styles from '../styles/EducationManager.module.css'; // Reusing layout styles
import { Plus, Edit2, X, Save, RefreshCw, Trash2, ToggleLeft, ToggleRight } from 'lucide-react';
import { cleanCategory, formatCategoryLabel } from '../utils/categoryNormalization';

const ExchangeRateManager = () => {
    const [rates, setRates] = useState([]);
    const [loading, setLoading] = useState(true);
    const [showModal, setShowModal] = useState(false);
    const [editingId, setEditingId] = useState(null);
    const [formData, setFormData] = useState({ wasteType: '', ratePerItem: 0, description: '', isActive: true });

    const fetchRates = async () => {
        setLoading(true);
        try {
            const res = await api.get('/exchange-rates', { params: { includeInactive: true } });
            setRates(res.data.rates || []);
        } catch (error) { console.error(error); }
        finally { setLoading(false); }
    };

    useEffect(() => { Promise.resolve().then(fetchRates); }, []);

    const handleSubmit = async (e) => {
        e.preventDefault();
        
        // Frontend Validation
        const rateValue = formData.ratePerItem ?? formData.ratePerKg ?? 0;
        if (rateValue < 0) {
            return alert("Exchange rate cannot be negative.");
        }
        const cleanedWasteType = cleanCategory(formData.wasteType);
        if (!cleanedWasteType) {
            return alert("Waste type is required.");
        }

        try {
            const payload = {
                ...formData,
                wasteType: cleanedWasteType
            };

            if (editingId) {
                await api.put(`/exchange-rates/${editingId}`, payload);
            } else {
                await api.post('/exchange-rates', payload);
            }
            setShowModal(false);
            fetchRates();
        } catch (error) { alert(error.response?.data?.message || 'Error saving rate'); }
    };

    const handleDelete = async (rate) => {
        if (!window.confirm(`Delete the exchange rate for "${rate.wasteType}"?`)) return;

        try {
            await api.delete(`/exchange-rates/${rate._id}`);
            fetchRates();
        } catch (error) {
            alert(error.response?.data?.message || 'Error deleting rate');
        }
    };

    const toggleStatus = async (rate) => {
        try {
            await api.put(`/exchange-rates/${rate._id}`, { isActive: !rate.isActive });
            fetchRates();
        } catch (error) { console.error(error); }
    };

    return (
        <div className={styles.container}>
            <Sidebar activePage="Exchange Rates" />
            <div className={styles.main}>
                <div className={styles.header}>
                    <div className={styles.titleGroup}>
                        <h1>Exchange Rates</h1>
                        <p>Configure PHP payout rates per category.</p>
                    </div>
                    <button onClick={() => { setEditingId(null); setFormData({ wasteType: '', ratePerItem: 0, description: '', isActive: true }); setShowModal(true); }} className={styles.addBtn}>
                        <Plus size={18} /> Add New Rate
                    </button>
                </div>

                {loading ? (
                    <div className={styles.loadingState}><RefreshCw className={styles.spinner} /> Loading rates...</div>
                ) : (
                    <div className={styles.grid}>
                        {rates.map((rate) => (
                            <div key={rate._id} className={styles.contentCard} style={{ borderLeft: rate.isActive ? '4px solid #10b981' : '4px solid #ef4444' }}>
                                <div className={styles.cardBody}>
                                    <div className={styles.cardHeader}>
                                        <span className={styles.categoryBadge}>{rate.isActive ? 'Active' : 'Inactive'}</span>
                                        <div className={styles.actions}>
                                            <button title="Edit rate" onClick={() => { setFormData(rate); setEditingId(rate._id); setShowModal(true); }} className={styles.iconBtn}><Edit2 size={16}/></button>
                                            <button title={rate.isActive ? 'Deactivate rate' : 'Activate rate'} onClick={() => toggleStatus(rate)} className={styles.iconBtn}>
                                                {rate.isActive ? <ToggleRight size={18}/> : <ToggleLeft size={18}/>}
                                            </button>
                                            <button title="Delete rate" onClick={() => handleDelete(rate)} className={styles.iconBtnDanger}><Trash2 size={16}/></button>
                                        </div>
                                    </div>
                                    <h3 className={styles.itemTitle}>{formatCategoryLabel(rate.wasteType)}</h3>
                                    <p className={styles.itemDesc} style={{ fontSize: '24px', fontWeight: 'bold', color: '#059669' }}>
                                        PHP {(rate.ratePerItem ?? rate.ratePerKg ?? 0).toFixed(2)} / item
                                    </p>
                                    <p className={styles.itemDesc}>{rate.description || 'No description provided.'}</p>
                                </div>
                            </div>
                        ))}
                    </div>
                )}

                {showModal && (
                    <div className={styles.modalOverlay}>
                        <div className={styles.modalContent}>
                            <div className={styles.modalHeader}>
                                <h2>{editingId ? 'Edit Rate' : 'New Exchange Rate'}</h2>
                                <button onClick={() => setShowModal(false)} className={styles.closeBtn}><X size={20}/></button>
                            </div>
                            <form onSubmit={handleSubmit} className={styles.form}>
                                <div className={styles.formGroup}>
                                    <label>Waste Type</label>
                                    <input required value={formData.wasteType} onChange={(e) => setFormData({...formData, wasteType: e.target.value})} className={styles.input} placeholder="e.g. Washing Machine" />
                                </div>
                                <div className={styles.formGroup}>
                                    <label>Rate (PHP per item)</label>
                                    <input type="number" step="0.01" min="0" required value={formData.ratePerItem ?? formData.ratePerKg ?? 0} onChange={(e) => setFormData({...formData, ratePerItem: parseFloat(e.target.value)})} className={styles.input} />
                                </div>
                                <div className={styles.formGroup}>
                                    <label>Description</label>
                                    <textarea value={formData.description} onChange={(e) => setFormData({...formData, description: e.target.value})} className={styles.textarea} />
                                </div>
                                <div className={styles.modalFooter}>
                                    <button type="button" onClick={() => setShowModal(false)} className={styles.cancelBtn}>Cancel</button>
                                    <button type="submit" className={styles.submitBtn}><Save size={16} /> Save Rate</button>
                                </div>
                            </form>
                        </div>
                    </div>
                )}
            </div>
        </div>
    );
};

export default ExchangeRateManager;
