import { useState, useEffect, useRef } from 'react';
import { useNavigate } from 'react-router-dom';
import styles from '../styles/Sidebar.module.css';
import { 
    LayoutDashboard, 
    FileText, 
    Truck, 
    Users, 
    BarChart3, 
    Settings, 
    LogOut, 
    Recycle, 
    X,
    ClipboardList,
    BookOpen,
    Coins,
    Users2,
    History,
    ChevronLeft,
    ChevronRight
} from 'lucide-react';

const Sidebar = ({ activePage }) => {
    const navigate = useNavigate();
    const [showLogoutModal, setShowLogoutModal] = useState(false);
    const [isCollapsed, setIsCollapsed] = useState(() => localStorage.getItem('sidebarCollapsed') === 'true');
    const menuRef = useRef(null);

    // Restore scroll position on mount
    useEffect(() => {
        const savedScroll = localStorage.getItem('sidebarScrollPos');
        if (savedScroll && menuRef.current) {
            menuRef.current.scrollTop = parseInt(savedScroll, 10);
        }
    }, []);

    const handleScroll = (e) => {
        localStorage.setItem('sidebarScrollPos', e.target.scrollTop);
    };
    
    // Get user info and role from localStorage
    const userInfo = JSON.parse(localStorage.getItem('userInfo') || '{}');
    const userRole = userInfo.role;

    const handleLogout = () => {
        localStorage.removeItem('userInfo');
        navigate('/login');
    };

    const toggleSidebar = () => {
        const nextState = !isCollapsed;
        setIsCollapsed(nextState);
        localStorage.setItem('sidebarCollapsed', String(nextState));
    };

    const menuItems = [
        { name: 'Dashboard', icon: <LayoutDashboard size={20} />, path: '/dashboard' },
        { name: 'Request Management', icon: <FileText size={20} />, path: '/requests', roles: ['Admin', 'Super Admin'] },
        { name: 'User Management', icon: <Users size={20} />, path: '/users', roles: ['Super Admin'] },
        { name: 'Collector Management', icon: <Truck size={20} />, path: '/collectors', roles: ['Admin', 'Super Admin'] },
        { name: 'Requests Summary', icon: <ClipboardList size={20} />, path: '/requests-summary' },
        { name: 'Mobile Residents', icon: <Users2 size={20} />, path: '/residents', roles: ['Admin', 'Super Admin'] },
        { name: 'Exchange Rates', icon: <Coins size={20} />, path: '/exchange-rates', roles: ['Admin', 'Super Admin'] },
        { name: 'Payout History', icon: <History size={20} />, path: '/transactions', roles: ['Admin', 'Super Admin'] },
        { name: 'Educational Content', icon: <BookOpen size={20} />, path: '/education', roles: ['Staff', 'Admin', 'Super Admin'] },
        { name: 'Reports and Analytics', icon: <BarChart3 size={20} />, path: '/reports', roles: ['Admin', 'Super Admin'] },
        { name: 'Settings', icon: <Settings size={20} />, path: '/settings', roles: ['Admin', 'Super Admin'] },
    ];

    // Filter menu items based on user role
    const filteredItems = menuItems.filter(item => !item.roles || item.roles.includes(userRole));

    return (
        <>
            <div className={`${styles.sidebar} ${isCollapsed ? styles.collapsed : ''}`}>
                <button
                    type="button"
                    className={styles.collapseBtn}
                    onClick={toggleSidebar}
                    title={isCollapsed ? 'Expand sidebar' : 'Collapse sidebar'}
                    aria-label={isCollapsed ? 'Expand sidebar' : 'Collapse sidebar'}
                >
                    {isCollapsed ? <ChevronRight size={20} /> : <ChevronLeft size={20} />}
                </button>

                <div className={styles.logoContainer}>
                    <div className={styles.logoIcon}><Recycle size={20} /></div>
                    <span className={styles.logoText}>RecyTech</span>
                </div>

                <ul className={styles.menu} ref={menuRef} onScroll={handleScroll}>
                    {filteredItems.map((item) => (
                        <li 
                            key={item.name} 
                            className={activePage === item.name ? styles.menuItemActive : styles.menuItem}
                            onClick={() => navigate(item.path)}
                            title={isCollapsed ? item.name : undefined}
                        >
                            <div className={styles.iconWrapper}>{item.icon}</div>
                            <span className={styles.menuLabel}>{item.name}</span>
                        </li>
                    ))}
                </ul>

                <div className={styles.logoutContainer}>
                    <button
                        className={styles.logoutBtn}
                        onClick={() => setShowLogoutModal(true)}
                        title={isCollapsed ? 'Log Out' : undefined}
                    >
                        <LogOut size={18}/>
                        <span className={styles.logoutText}>Log Out</span>
                    </button>
                </div>
            </div>

            {/* Logout Confirmation Modal */}
            {showLogoutModal && (
                <div className={styles.modalOverlay}>
                    <div className={styles.modalContent}>
                        <div className={styles.modalHeader}>
                            <h2 className={styles.modalTitle}>Confirm Logout</h2>
                            <button onClick={() => setShowLogoutModal(false)} className={styles.closeBtn}><X size={20}/></button>
                        </div>
                        <p style={{color: '#666', marginBottom: '24px'}}>Are you sure you want to log out?</p>
                        <div className={styles.modalFooter}>
                            <button onClick={() => setShowLogoutModal(false)} className={styles.cancelBtn}>Cancel</button>
                            <button onClick={handleLogout} className={styles.confirmLogoutBtn}>Log Out</button>
                        </div>
                    </div>
                </div>
            )}
        </>
    );
};

export default Sidebar;
