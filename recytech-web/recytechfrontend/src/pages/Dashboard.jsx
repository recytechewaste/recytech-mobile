import { useEffect, useState } from 'react';
import api from '../api/client';
import Sidebar from '../components/Sidebar';
import DistributionCharts from '../features/dashboard/DistributionCharts';
import EWasteMetrics from '../features/dashboard/EWasteMetrics';
import PredictiveInsights from '../features/dashboard/PredictiveInsights';
import RecentRequestsTable from '../features/dashboard/RecentRequestsTable';
import SchedulingPanel from '../features/scheduling/SchedulingPanel';
import styles from '../styles/Dashboard.module.css';

const Dashboard = () => {
    const [stats, setStats] = useState({
        pending: 0,
        completed: 0,
        completionRate: 0,
        totalItems: 0,
        totalPayout: 0,
        totalResidents: 0
    });
    const [roleData, setRoleData] = useState([]);
    const [categoryData, setCategoryData] = useState([]);
    const [monthlyData, setMonthlyData] = useState([]);
    const [recentActivity, setRecentActivity] = useState([]);
    const [predictiveInsights, setPredictiveInsights] = useState({});

    useEffect(() => {
        const fetchStats = async () => {
            try {
                const { data } = await api.get('/analytics/dashboard');
                const requestStats = data.summary?.requests || {};
                const payoutStats = data.summary?.payouts || {};
                const residentStats = data.summary?.residents || {};

                setStats({
                    pending: requestStats.pendingRequests || 0,
                    completed: requestStats.completedRequests || 0,
                    completionRate: requestStats.completionRate || 0,
                    totalItems: requestStats.totalCompletedItems || 0,
                    totalPayout: payoutStats.totalPayout || 0,
                    totalResidents: residentStats.totalResidents || 0
                });
                setMonthlyData(data.monthlyTrends || []);
                setCategoryData(data.categoryDistribution || []);
                setRoleData(data.roleDistribution || []);
                setRecentActivity(data.recentRequests || []);
                setPredictiveInsights(data.predictiveAnalytics || {});
            } catch (error) {
                console.error('Error fetching stats', error);
            }
        };

        fetchStats();
    }, []);

    return (
        <div className={styles.container}>
            <Sidebar activePage="Dashboard" />

            <div className={styles.main}>
                <div className={styles.dashboardHeader}>
                    <h1 className={styles.pageTitle}>System Dashboard</h1>
                    <p className={styles.subTitle}>Welcome back, Super Admin. Here is your operational overview.</p>
                </div>

                <EWasteMetrics stats={stats} monthlyData={monthlyData} />
                <PredictiveInsights predictiveInsights={predictiveInsights} />
                <SchedulingPanel />
                <DistributionCharts categoryData={categoryData} roleData={roleData} />
                <RecentRequestsTable requests={recentActivity} />
            </div>
        </div>
    );
};

export default Dashboard;
