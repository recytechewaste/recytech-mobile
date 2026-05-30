import { useEffect, useState } from 'react';
import api from '../api/client';
import Sidebar from '../components/Sidebar';
import styles from '../styles/Reports.module.css';
import { BarChart, Bar, XAxis, YAxis, Tooltip, ResponsiveContainer, PieChart, Pie, Cell } from 'recharts';
import { Download, Calendar, Filter } from 'lucide-react';

const Reports = () => {
    const [reportData, setReportData] = useState([]);
    const [filteredData, setFilteredData] = useState([]);
    const [chartData, setChartData] = useState([]);
    const [pieData, setPieData] = useState([]);
    const [wasteTypes, setWasteTypes] = useState([]);
    const [filters, setFilters] = useState({
        dateRange: 'Last 30 Days',
        wasteType: 'All Waste Types',
        status: 'All'
    });
    const [stats, setStats] = useState({
        total: 0,
        successRate: 0,
        topItem: 'N/A',
        totalPayout: 0,
        uniqueResidents: 0
    });

    const buildChartData = (data) => {
        const dates = {};
        data.forEach(item => {
            const date = new Date(item.updatedAt).toLocaleDateString('en-US', { month: 'short', day: 'numeric' });
            dates[date] = (dates[date] || 0) + 1;
        });
        return Object.keys(dates).map(key => ({ name: key, collections: dates[key] }));
    };

    const buildPieData = (data) => {
        const typeCounts = {};
        data.forEach(item => {
            typeCounts[item.wasteType] = (typeCounts[item.wasteType] || 0) + 1;
        });
        return Object.keys(typeCounts).map(key => ({ name: key, value: typeCounts[key] }));
    };

    const applyFilters = (data) => {
        let result = [...data];

        if (filters.status !== 'All') {
            result = result.filter(r => r.status === filters.status);
        }

        if (filters.wasteType !== 'All Waste Types') {
            result = result.filter(r => r.wasteType === filters.wasteType);
        }

        if (filters.dateRange !== 'All Time') {
            const days = filters.dateRange === 'Last 7 Days' ? 7 : filters.dateRange === 'Last 90 Days' ? 90 : 30;
            const fromDate = new Date();
            fromDate.setDate(fromDate.getDate() - days);
            result = result.filter(r => new Date(r.updatedAt) >= fromDate);
        }

        return result.sort((a, b) => new Date(b.updatedAt) - new Date(a.updatedAt));
    };

    const updateReportState = (archived) => {
        const filtered = applyFilters(archived);
        setFilteredData(filtered);

        const total = filtered.length;
        const completed = filtered.filter(r => r.status === 'Completed').length;
        const successRate = total > 0 ? Math.round((completed / total) * 100) : 0;

        const pieData = buildPieData(filtered);
        const barData = buildChartData(filtered);

        const residentsSet = new Set(filtered.map(item => item.residentEmail || item.residentName || item._id));
        const totalPayout = filtered.reduce((sum, item) => sum + (item.monetaryValue || 0), 0);
        const typeCounts = pieData.reduce((acc, item) => ({ ...acc, [item.name]: item.value }), {});
        const topItem = pieData.length > 0 ? pieData.reduce((a, b) => (a.value > b.value ? a : b)).name : 'N/A';

        setStats({ total, successRate, topItem, totalPayout, uniqueResidents: residentsSet.size });
        setChartData(barData);
        setPieData(pieData);
    };

    const fetchReports = async () => {
        try {
            const { data } = await api.get('/requests');
            const archived = data.filter(r => r.status === 'Completed' || r.status === 'Rejected');
            setReportData(archived);
            const uniqueWasteTypes = Array.from(new Set(archived.map(item => item.wasteType).filter(Boolean)));
            setWasteTypes(uniqueWasteTypes);
            updateReportState(archived);
        } catch (error) {
            console.error("Error fetching reports", error);
        }
    };

    useEffect(() => {
        Promise.resolve().then(fetchReports);
    }, []);

    useEffect(() => {
        if (reportData.length) {
            updateReportState(reportData);
        }
    }, [filters]);

    const handleClearFilters = () => {
        setFilters({
            dateRange: 'Last 30 Days',
            wasteType: 'All Waste Types',
            status: 'All'
        });
    };

    const COLORS = ['#111827', '#374151', '#6B7280', '#9CA3AF', '#D1D5DB'];

    return (
        <div className={styles.container}>
            <Sidebar activePage="Reports and Analytics" />

            <div className={styles.main}>
                {/* HEADER */}
                <div className={styles.header}>
                    <div className={styles.titleGroup}>
                        <h1 className={styles.pageTitle}>Reports & Analytics</h1>
                        <p className={styles.subTitle}>Performance metrics and collection history.</p>
                    </div>
                    <button onClick={() => window.print()} className={styles.exportBtn} style={{backgroundColor: '#2563EB', color: 'white', border: 'none'}}>
                        <Download size={16} /> Export Report
                    </button>
                </div>

                {/* FILTERS */}
                <div className={styles.filterBar}>
                    <div className={styles.filterGroup}>
                        <Calendar size={16} className={styles.icon} />
                        <select className={styles.select} value={filters.dateRange} onChange={(e) => setFilters({ ...filters, dateRange: e.target.value })}>
                            <option>Last 7 Days</option>
                            <option>Last 30 Days</option>
                            <option>Last 90 Days</option>
                            <option>All Time</option>
                        </select>
                    </div>
                    <div className={styles.filterGroup}>
                        <Filter size={16} className={styles.icon} />
                        <select className={styles.select} value={filters.wasteType} onChange={(e) => setFilters({ ...filters, wasteType: e.target.value })}>
                            <option>All Waste Types</option>
                            {wasteTypes.map((type) => (
                                <option key={type}>{type}</option>
                            ))}
                        </select>
                    </div>
                    <div className={styles.filterGroup}>
                        <Filter size={16} className={styles.icon} />
                        <select className={styles.select} value={filters.status} onChange={(e) => setFilters({ ...filters, status: e.target.value })}>
                            <option>All</option>
                            <option>Completed</option>
                            <option>Rejected</option>
                        </select>
                    </div>
                    <button className={styles.clearBtn} onClick={handleClearFilters}>Clear Filters</button>
                </div>
                
                {/* METRICS WIDGETS */}
                <div className={styles.metricsGrid}>
                    <div className={styles.metricCard}>
                        <span className={styles.metricLabel}>Total Processed</span>
                        <h3 className={styles.metricValue}>{stats.total}</h3>
                        <span className={styles.metricTrend}>Archived completed/rejected requests</span>
                    </div>
                    <div className={styles.metricCard}>
                        <span className={styles.metricLabel}>Collection Success Rate</span>
                        <h3 className={styles.metricValue}>{stats.successRate}%</h3>
                        <span className={styles.metricTrend}>Completed vs archived requests</span>
                    </div>
                    <div className={styles.metricCard}>
                        <span className={styles.metricLabel}>Total Payout</span>
                        <h3 className={styles.metricValue}>PHP {stats.totalPayout.toLocaleString()}</h3>
                        <span className={styles.metricTrend}>Amount based on request values</span>
                    </div>
                    <div className={styles.metricCard}>
                        <span className={styles.metricLabel}>Residents Served</span>
                        <h3 className={styles.metricValue}>{stats.uniqueResidents}</h3>
                        <span className={styles.metricTrend}>Unique resident profiles in filtered data</span>
                    </div>
                </div>

                {/* CHARTS SECTION */}
                <div className={styles.chartsGrid}>
                    {/* Bar Chart */}
                    <div className={styles.chartCard}>
                        <div className={styles.cardHeader}>
                            <h3>Weekly Collection Trends</h3>
                        </div>
                        <div style={{ height: '300px', width: '100%' }}>
                            <ResponsiveContainer width="100%" height="100%">
                                <BarChart data={chartData}>
                                    <XAxis dataKey="name" stroke="#9CA3AF" fontSize={12} tickLine={false} axisLine={false} />
                                    <YAxis stroke="#9CA3AF" fontSize={12} tickLine={false} axisLine={false} />
                                    <Tooltip cursor={{fill: '#f3f4f6'}} />
                                    <Bar dataKey="collections" fill="#111827" radius={[4, 4, 0, 0]} barSize={40} />
                                </BarChart>
                            </ResponsiveContainer>
                        </div>
                    </div>

                    {/* Pie Chart */}
                    <div className={styles.chartCard}>
                        <div className={styles.cardHeader}>
                            <h3>Waste Type Distribution</h3>
                        </div>
                        <div style={{ height: '300px', width: '100%' }}>
                            <ResponsiveContainer width="100%" height="100%">
                                <PieChart>
                                    <Pie
                                        data={pieData}
                                        cx="50%"
                                        cy="50%"
                                        innerRadius={60}
                                        outerRadius={80}
                                        paddingAngle={5}
                                        dataKey="value"
                                    >
                                        {pieData.map((entry, index) => (
                                            <Cell key={`cell-${index}`} fill={COLORS[index % COLORS.length]} />
                                        ))}
                                    </Pie>
                                    <Tooltip />
                                </PieChart>
                            </ResponsiveContainer>
                        </div>
                    </div>
                </div>

                {/* TABLE SECTION */}
                <div className={styles.tableCard}>
                    <div className={styles.cardHeader}>
                        <h3>Recent Transaction History</h3>
                    </div>
                    <table className={styles.table}>
                        <thead>
                            <tr>
                                <th className={styles.th}>Date Processed</th>
                                <th className={styles.th}>Resident</th>
                                <th className={styles.th}>Item Category</th>
                                <th className={styles.th}>Outcome</th>
                            </tr>
                        </thead>
                        <tbody>
                            {filteredData.slice(0, 5).map((req) => (
                                <tr key={req._id} className={styles.tr}>
                                    <td className={styles.td}>
                                        {new Date(req.updatedAt).toLocaleDateString()}
                                    </td>
                                    <td className={styles.td}>{req.residentName}</td>
                                    <td className={styles.td}>{req.wasteType}</td>
                                    <td className={styles.td}>
                                        <span className={req.status === 'Completed' ? styles.statusCompleted : styles.statusRejected}>
                                            {req.status}
                                        </span>
                                    </td>
                                </tr>
                            ))}
                        </tbody>
                    </table>
                </div>
            </div>
        </div>
    );
};

export default Reports;
