import React, { useState } from 'react';
import Sidebar from '../components/Sidebar';

const Settings = () => {
    const [profilePic, setProfilePic] = useState(null);

    const handleImageUpload = (e) => {
        const file = e.target.files[0];
        if (file) {
            const reader = new FileReader();
            reader.onloadend = () => {
                setProfilePic(reader.result);
            };
            reader.readAsDataURL(file);
        }
    };

    return (
        <div style={styles.container}>
            <Sidebar activePage="Settings" />

            <div style={styles.main}>
                <div style={styles.headerContainer}>
                    <h1 style={styles.pageTitle}>Settings</h1>
                </div>

                <div style={styles.card}>
                    <h3 style={styles.sectionTitle}>Account Preferences</h3>
                    
                    <div style={styles.profileSection}>
                        <div style={styles.avatarContainer}>
                            {profilePic ? (
                                <img src={profilePic} alt="Profile" style={styles.avatar} />
                            ) : (
                                <span style={styles.avatarPlaceholder}>AU</span>
                            )}
                        </div>
                        <div>
                            <label htmlFor="file-upload" style={styles.uploadBtn}>Change Photo</label>
                            <input id="file-upload" type="file" accept="image/*" onChange={handleImageUpload} style={{display: 'none'}} />
                            <div style={styles.hintText}>JPG, GIF or PNG. 1MB max.</div>
                        </div>
                    </div>

                    <div style={styles.formGroup}>
                        <label style={styles.label}>Admin Name</label>
                        <input type="text" defaultValue="Admin User" style={styles.input} />
                    </div>
                    <div style={styles.formGroup}>
                        <label style={styles.label}>Email Address</label>
                        <input type="email" defaultValue="admin@recytech.com" style={styles.input} />
                    </div>
                    <button style={styles.saveBtn}>Save Changes</button>
                </div>

                <div style={{...styles.card, marginTop: '24px'}}>
                    <h3 style={styles.sectionTitle}>Notifications</h3>
                    <div style={styles.checkboxGroup}>
                        <input type="checkbox" id="emailNotif" defaultChecked />
                        <label htmlFor="emailNotif" style={{marginLeft: '8px'}}>Email Notifications for New Requests</label>
                    </div>
                </div>
            </div>
        </div>
    );
};

const styles = {
    container: {
        display: 'flex',
        minHeight: '100vh',
        fontFamily: "'Inter', 'Segoe UI', Roboto, sans-serif",
        backgroundColor: '#f3f4f6'
    },
    main: {
        flex: 1,
        padding: '32px',
        overflowY: 'auto'
    },
    headerContainer: {
        marginBottom: '32px'
    },
    pageTitle: {
        fontSize: '24px',
        fontWeight: '600',
        color: '#111827',
        margin: 0
    },
    card: {
        backgroundColor: 'white',
        borderRadius: '12px',
        boxShadow: '0 1px 3px 0 rgba(0, 0, 0, 0.1), 0 1px 2px 0 rgba(0, 0, 0, 0.06)',
        border: '1px solid #e5e7eb',
        padding: '24px'
    },
    sectionTitle: {
        fontSize: '18px',
        fontWeight: '600',
        color: '#111827',
        marginTop: 0,
        marginBottom: '20px'
    },
    profileSection: {
        display: 'flex',
        alignItems: 'center',
        gap: '20px',
        marginBottom: '24px'
    },
    avatarContainer: {
        width: '80px',
        height: '80px',
        borderRadius: '50%',
        backgroundColor: '#e5e7eb',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        overflow: 'hidden',
        border: '1px solid #d1d5db'
    },
    avatar: {
        width: '100%',
        height: '100%',
        objectFit: 'cover'
    },
    avatarPlaceholder: {
        fontSize: '24px',
        fontWeight: '600',
        color: '#6b7280'
    },
    uploadBtn: {
        display: 'inline-block',
        padding: '8px 16px',
        backgroundColor: 'white',
        border: '1px solid #d1d5db',
        borderRadius: '6px',
        cursor: 'pointer',
        fontSize: '14px',
        fontWeight: '500',
        color: '#374151',
        marginBottom: '4px'
    },
    hintText: {
        fontSize: '12px',
        color: '#6b7280'
    },
    formGroup: {
        marginBottom: '16px',
        maxWidth: '400px'
    },
    label: {
        display: 'block',
        marginBottom: '8px',
        fontSize: '14px',
        fontWeight: '500',
        color: '#374151'
    },
    input: {
        width: '100%',
        padding: '10px',
        borderRadius: '6px',
        border: '1px solid #d1d5db',
        fontSize: '14px',
        outline: 'none'
    },
    saveBtn: {
        padding: '10px 20px',
        backgroundColor: '#2563EB',
        color: 'white',
        border: 'none',
        borderRadius: '6px',
        cursor: 'pointer',
        fontSize: '14px',
        fontWeight: '500',
        marginTop: '8px'
    },
    checkboxGroup: {
        display: 'flex',
        alignItems: 'center',
        fontSize: '14px',
        color: '#374151'
    }
};

export default Settings;