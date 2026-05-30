import { useEffect, useState } from 'react';
import api from '../api/client';
import Sidebar from '../components/Sidebar';
import styles from '../styles/EducationManager.module.css';
import { 
    Plus, Search, Edit2, Trash2, X, Filter, 
    ExternalLink, Save, Upload, AlertCircle, RefreshCw 
} from 'lucide-react';

const CATEGORIES = ["Sustainability", "E-Waste Disposal", "Environmental Impact", "Regulations"];

const EducationManager = () => {
    const [materials, setMaterials] = useState([]);
    const [loading, setLoading] = useState(true);
    const [fetchError, setFetchError] = useState(null);
    const [imagePreview, setImagePreview] = useState(null);
    const [showModal, setShowModal] = useState(false);
    const [editingId, setEditingId] = useState(null);
    const [searchTerm, setSearchTerm] = useState('');
    const [categoryFilter, setCategoryFilter] = useState('');
    
    const [formData, setFormData] = useState({
        title: '',
        category: 'Sustainability',
        type: 'Article',
        description: '',
        contentURL: '',
        status: 'Published'
    });

    const fetchMaterials = async () => {
        setLoading(true);
        setFetchError(null);
        try {
            const res = await api.get('/education');
            setMaterials(Array.isArray(res.data) ? res.data : []);
        } catch (error) {
            console.error("Error fetching materials", error);
            setFetchError("Unable to connect to the server. Please ensure the backend is running.");
        } finally {
            setLoading(false);
        }
    };

    useEffect(() => {
        Promise.resolve().then(fetchMaterials);
    }, []);

    const handleImageChange = (e) => {
        const file = e.target.files[0];
        if (file) {
            const reader = new FileReader();
            reader.onloadend = () => setImagePreview(reader.result);
            reader.readAsDataURL(file);
        }
    };

    const handleSubmit = async (e) => {
        e.preventDefault();
        
        if (!formData.title.trim()) return alert("Title is required");
        
        // Basic URL validation if provided
        if (formData.contentURL && !formData.contentURL.startsWith('http')) {
            return alert("Please enter a valid URL starting with http:// or https://");
        }

        const submissionData = { ...formData, thumbnail: imagePreview };

        try {
            if (editingId) {
                await api.put(`/education/${editingId}`, submissionData);
            } else {
                await api.post('/education', submissionData);
            }
            setShowModal(false);
            fetchMaterials();
        } catch { alert('Error saving material'); }
    };

    const handleDelete = async (id) => {
        if (window.confirm("Are you sure you want to delete this content?")) {
            try {
                await api.delete(`/education/${id}`);
                fetchMaterials();
            } catch (error) { console.error(error); }
        }
    };

    const filteredMaterials = materials.filter(m => 
        m?.title?.toLowerCase().includes(searchTerm.toLowerCase()) &&
        (categoryFilter === '' || m?.category === categoryFilter)
    );

    return (
        <div className={styles.container}>
            <Sidebar activePage="Educational Content" />
            <div className={styles.main}>
                <div className={styles.header}>
                    <div className={styles.titleGroup}>
                        <h1 className={styles.pageTitle}>Educational Content</h1>
                        <p className={styles.subTitle}>Curation of sustainability guides and e-waste awareness.</p>
                    </div>
                    <button onClick={() => { setEditingId(null); setImagePreview(null); setFormData({ title: '', category: 'Sustainability', type: 'Article', description: '', contentURL: '', status: 'Published' }); setShowModal(true); }} className={styles.addBtn}>
                        <Plus size={18} /> Add Content
                    </button>
                </div>

                <div className={styles.filterBar}>
                    <div className={styles.searchGroup}>
                        <Search size={18} className={styles.searchIcon} />
                        <input type="text" placeholder="Search materials..." className={styles.searchInput} value={searchTerm} onChange={(e) => setSearchTerm(e.target.value)} />
                    </div>
                    <span className={styles.totalCount}>Total: {filteredMaterials.length} materials</span>
                    <select className={styles.selectInput} value={categoryFilter} onChange={(e) => setCategoryFilter(e.target.value)}>
                        <option value="">All Categories</option>
                        {CATEGORIES.map(cat => <option key={cat} value={cat}>{cat}</option>)}
                    </select>
                </div>

                {fetchError ? (
                    <div className={styles.errorState}>
                        <AlertCircle size={48} color="#ef4444" />
                        <h3>Connection Error</h3>
                        <p>{fetchError}</p>
                        <button onClick={fetchMaterials} className={styles.retryBtn}>Retry Connection</button>
                    </div>
                ) : loading ? (
                    <div className={styles.loadingState}><RefreshCw className={styles.spinner} /> Loading...</div>
                ) : (
                    <div className={styles.grid}>
                        {filteredMaterials.map((item) => (
                            <div key={item._id} className={styles.contentCard}>
                                {item.thumbnail && <img src={item.thumbnail} className={styles.cardThumb} alt="Thumbnail" />}
                                <div className={styles.cardBody}>
                                    <div className={styles.cardHeader}>
                                        <span className={styles.categoryBadge}>{item.category}</span>
                                        <div className={styles.actions}>
                                            <button onClick={() => { setFormData(item); setEditingId(item._id); setImagePreview(item.thumbnail); setShowModal(true); }} className={styles.iconBtn}><Edit2 size={16}/></button>
                                            <button onClick={() => handleDelete(item._id)} className={styles.iconBtnDanger}><Trash2 size={16}/></button>
                                        </div>
                                    </div>
                                    <h3 className={styles.itemTitle}>{item.title}</h3>
                                    <p className={styles.itemDesc}>{item.description?.substring(0, 80) || "No description..."}...</p>
                                    <div className={styles.cardFooter}>
                                        <span className={styles.typeTag}>{item.type}</span>
                                        {item.contentURL && <a href={item.contentURL} target="_blank" rel="noreferrer" className={styles.link}><ExternalLink size={14} /> View</a>}
                                    </div>
                                </div>
                            </div>
                        ))}
                    </div>
                )}

                {showModal && (
                    <div className={styles.modalOverlay} onClick={() => setShowModal(false)}>
                        <div className={styles.modalContent} onClick={(e) => e.stopPropagation()}>
                            <div className={styles.modalHeader}>
                                <h2>{editingId ? 'Edit Content' : 'New Educational Material'}</h2>
                                <button onClick={() => setShowModal(false)} className={styles.closeBtn}><X size={20}/></button>
                            </div>
                            <form onSubmit={handleSubmit} className={styles.form}>
                                <div className={styles.formGroup}>
                                    <label>Title</label>
                                    <input required value={formData.title} onChange={(e) => setFormData({...formData, title: e.target.value})} className={styles.input} />
                                </div>
                                <div className={styles.formGroup}>
                                    <label>Thumbnail</label>
                                    <div className={styles.imageUploadArea}>
                                        {imagePreview ? (
                                            <div className={styles.previewContainer}>
                                                <img src={imagePreview} className={styles.imagePreview} alt="Preview" />
                                                <button type="button" onClick={() => setImagePreview(null)} className={styles.removeImgBtn}><X size={14} /></button>
                                            </div>
                                        ) : (
                                            <label className={styles.uploadPlaceholder}>
                                                <input type="file" accept="image/*" onChange={handleImageChange} hidden />
                                                <Upload size={24} /> <span>Click to upload image</span>
                                            </label>
                                        )}
                                    </div>
                                </div>
                                <div className={styles.formRow}>
                                    <div className={styles.formGroup}>
                                        <label>Category</label>
                                        <select value={formData.category} onChange={(e) => setFormData({...formData, category: e.target.value})} className={styles.input}>
                                            {CATEGORIES.map(cat => <option key={cat} value={cat}>{cat}</option>)}
                                        </select>
                                    </div>
                                    <div className={styles.formGroup}>
                                        <label>Format</label>
                                        <select value={formData.type} onChange={(e) => setFormData({...formData, type: e.target.value})} className={styles.input}>
                                            <option value="Article">Article</option>
                                            <option value="Video">Video</option>
                                            <option value="PDF">PDF</option>
                                        </select>
                                    </div>
                                </div>
                                <div className={styles.formGroup}>
                                    <label>Description</label>
                                    <textarea value={formData.description} onChange={(e) => setFormData({...formData, description: e.target.value})} className={styles.textarea} />
                                </div>
                                <div className={styles.formGroup}>
                                    <label>External URL</label>
                                    <input value={formData.contentURL} onChange={(e) => setFormData({...formData, contentURL: e.target.value})} className={styles.input} placeholder="https://..." />
                                </div>
                                <div className={styles.modalFooter}>
                                    <button type="button" onClick={() => setShowModal(false)} className={styles.cancelBtn}>Cancel</button>
                                    <button type="submit" className={styles.submitBtn}><Save size={16} /> Save Changes</button>
                                </div>
                            </form>
                        </div>
                    </div>
                )}
            </div>
        </div>
    );
};

export default EducationManager;
