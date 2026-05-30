import { useEffect, useState } from 'react';
import api from '../api/client';
import Sidebar from '../components/Sidebar';
import styles from '../styles/UserManagement.module.css';
import { RefreshCw, ArrowUpRight, ArrowDownLeft, ChevronLeft, ChevronRight } from 'lucide-react';

const PayoutHistory = () => {
    const [transactions, setTransactions] = useState([]);
    const [loading, setLoading] = useState(true);
    const [searchTerm, setSearchTerm] = useState('');
    const [pagination, setPagination] = useState({ page: 1, pages: 1 });

    const fetchTransactions = async (page = 1) => {
        setLoading(true);
        try {
            const res = await api.get(`/transactions?page=${page}&limit=10`);
            setTransactions(res.data.transactions || res.data || []);
            if (res.data.pagination) setPagination(res.data.pagination);
        } catch (error) {
            console.error("Error fetching transactions:", error);
        } finally {
            setLoading(false);
        }
    };

    useEffect(() => { fetchTransactions(pagination.page); }, [pagination.page]);

    const filteredTransactions = transactions.filter(t => 
        t.resident?.email?.toLowerCase().includes(searchTerm.toLowerCase()) ||
        t._id?.toLowerCase().includes(searchTerm.toLowerCase()) ||
        t.description?.toLowerCase().includes(searchTerm.toLowerCase())
    );

    return (
        <div className={styles.container}>
            <Sidebar activePage="Payout History" />
            <div className={styles.main}>
                <div className={styles.header}>
                    <div className={styles.titleGroup}>
                        <h1>Payout History</h1>
                        <p>Complete audit trail of automated recycling payouts and manual adjustments.</p>
                    </div>
                </div>

                <div className={styles.filterBar}>
                    <div className={styles.searchGroup}>
                        <input 
                            type="text" 
                            placeholder="Search by email, ID, or description..." 
                            className={styles.searchInput} 
                            value={searchTerm}
                            onChange={(e) => setSearchTerm(e.target.value)}
                        />
                    </div>
                    <span className={styles.totalUsers}>Total: {filteredTransactions.length} records</span>
                </div>

                <div className={styles.card}>
                    <table className={styles.table}>
                        <thead>
                            <tr>
                                <th className={styles.th}>Date & Time</th>
                                <th className={styles.th}>Resident</th>
                                <th className={styles.th}>Type</th>
                                <th className={styles.th}>Amount</th>
                                <th className={styles.th}>Description</th>
                                <th className={styles.th}>Reference ID</th>
                            </tr>
                        </thead>
                        <tbody>
                            {loading ? (
                                <tr><td colSpan="6" style={{textAlign:'center', padding:'40px'}}><RefreshCw className={styles.spinner} /> Loading history...</td></tr>
                            ) : filteredTransactions.length === 0 ? (
                                <tr><td colSpan="6" style={{textAlign:'center', padding:'40px'}}>No transaction history found.</td></tr>
                            ) : (
                                filteredTransactions.map((tx) => (
                                    <tr key={tx._id}>
                                        <td className={styles.td}>
                                            <div style={{display:'flex', flexDirection:'column'}}>
                                                <span>{new Date(tx.createdAt).toLocaleDateString()}</span>
                                                <span style={{fontSize:'11px', color:'#6b7280'}}>{new Date(tx.createdAt).toLocaleTimeString()}</span>
                                            </div>
                                        </td>
                                        <td className={styles.td}>
                                            <div style={{fontWeight:'500'}}>{tx.resident?.firstName} {tx.resident?.lastName}</div>
                                            <div style={{fontSize:'12px', color:'#6b7280'}}>{tx.resident?.email}</div>
                                        </td>
                                        <td className={styles.td}>
                                            <span style={{color: tx.type === 'Payment' ? '#059669' : '#d97706', fontWeight: '600', display: 'flex', alignItems: 'center', gap: '4px'}}>
                                                {tx.type === 'Payment' ? <ArrowUpRight size={14}/> : <ArrowDownLeft size={14}/>} {tx.type}
                                            </span>
                                        </td>
                                        <td className={styles.td} style={{fontWeight: '700'}}>PHP {tx.amount?.toFixed(2)}</td>
                                        <td className={styles.td} style={{maxWidth: '250px', fontSize: '13px'}}>{tx.description}</td>
                                        <td className={styles.td}><code style={{fontSize: '11px', background: '#f3f4f6', padding: '2px 4px', borderRadius: '4px'}}>{tx.requestId?._id || tx.requestId || tx._id}</code></td>
                                    </tr>
                                ))
                            )}
                        </tbody>
                    </table>
                </div>

                {/* Pagination Controls */}
                <div className={styles.filterBar} style={{ marginTop: '20px', justifyContent: 'center' }}>
                    <button 
                        disabled={pagination.page <= 1} 
                        onClick={() => setPagination(prev => ({ ...prev, page: prev.page - 1 }))}
                        className={styles.iconBtn}
                    >
                        <ChevronLeft size={20} />
                    </button>
                    <span style={{ padding: '0 20px' }}>Page {pagination.page} of {pagination.pages}</span>
                    <button 
                        disabled={pagination.page >= pagination.pages} 
                        onClick={() => setPagination(prev => ({ ...prev, page: prev.page + 1 }))}
                        className={styles.iconBtn}
                    >
                        <ChevronRight size={20} />
                    </button>
                </div>
            </div>
        </div>
    );
};

export default PayoutHistory;
