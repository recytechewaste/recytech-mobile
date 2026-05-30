import { useEffect, useState } from 'react';
import api from '../api/client';
import Sidebar from '../components/Sidebar';
import styles from '../styles/RequestsSummary.module.css';
import { FileText, Clock, CheckCircle, Truck, TrendingUp, AlertCircle } from 'lucide-react';

const getShortRequestId = (id) => {
    if (!id) return '---';
    return id.substring(id.length - 6).toUpperCase();
};

const formatDate = (date) => {
    if (!date) return 'No date';

    const parsedDate = new Date(date);
    if (Number.isNaN(parsedDate.getTime())) return 'No date';

    return parsedDate.toLocaleDateString();
};

const getTopWasteType = (requests) => {
    const counts = requests.reduce((acc, req) => {
        if (!req.wasteType) return acc;
        acc[req.wasteType] = (acc[req.wasteType] || 0) + 1;
        return acc;
    }, {});

    return Object.keys(counts).reduce((top, type) => (
        !top || counts[type] > counts[top] ? type : top
    ), '');
};

const buildRecommendations = (requests, stats) => {
    const topWasteType = getTopWasteType(requests);
    const approvedUnassigned = requests.filter(req => (
        req.status === 'Approved' && !req.assignedCollector
    )).length;
    const completionRate = stats.total > 0 ? Math.round((stats.completed / stats.total) * 100) : 0;

    const recommendations = [];

    if (stats.pending > 0) {
        recommendations.push({
            icon: AlertCircle,
            title: 'Review pending requests',
            text: `${stats.pending} request${stats.pending === 1 ? '' : 's'} still need approval before collectors can be assigned.`
        });
    }

    if (approvedUnassigned > 0) {
        recommendations.push({
            icon: Truck,
            title: 'Assign collectors',
            text: `${approvedUnassigned} approved request${approvedUnassigned === 1 ? '' : 's'} can move faster once a collector is assigned.`
        });
    }

    if (topWasteType) {
        recommendations.push({
            icon: TrendingUp,
            title: 'Prioritize common waste',
            text: `${topWasteType} is currently the most requested category, so collector capacity should account for it.`
        });
    }

    recommendations.push({
        icon: completionRate >= 50 ? CheckCircle : Clock,
        title: 'Track completion rate',
        text: `${completionRate}% of all requests are completed. Use this as a quick indicator of collection throughput.`
    });

    return recommendations.slice(0, 3);
};

const RequestsSummary = () => {
    const [stats, setStats] = useState({ total: 0, pending: 0, active: 0, completed: 0 });
    const [recentRequests, setRecentRequests] = useState([]);
    const [recommendations, setRecommendations] = useState([]);

    useEffect(() => {
        const fetchData = async () => {
            try {
                const { data } = await api.get('/requests');
                
                // 1. Calculate Stats
                const total = data.length;
                const pending = data.filter(r => r.status === 'Pending').length;
                const active = data.filter(r => r.status === 'Approved').length;
                const completed = data.filter(r => r.status === 'Completed').length;
                
                const nextStats = { total, pending, active, completed };
                setStats(nextStats);

                // 2. Get Recent 3 Requests (sorted by newest)
                const sorted = [...data].sort((a, b) => new Date(b.createdAt) - new Date(a.createdAt));
                setRecentRequests(sorted.slice(0, 3));
                setRecommendations(buildRecommendations(data, nextStats));

            } catch (error) {
                console.error("Error loading summary", error);
            }
        };
        fetchData();
    }, []);

    return (
        <div className={styles.container}>
            <Sidebar activePage="Requests Summary" />

            <div className={styles.main}>
                <div className={styles.headerContainer}>
                    <h1 className={styles.pageTitle}>Summary of Requests</h1>
                </div>

                {/* 1. METRICS CARDS */}
                <div className={styles.metricsGrid}>
                    <div className={styles.card}>
                        <div className={styles.cardLabel}>Total Requests</div>
                        <div className={styles.cardValue}>{stats.total}</div>
                    </div>
                    <div className={styles.card}>
                        <div className={styles.cardLabel}>Requests Awaiting Approval</div>
                        <div className={styles.cardValue}>{stats.pending}</div>
                    </div>
                    <div className={styles.card}>
                        <div className={styles.cardLabel}>Requests in Progress</div>
                        <div className={styles.cardValue}>{stats.active}</div>
                    </div>
                    <div className={styles.card}>
                        <div className={styles.cardLabel}>Completed Collections</div>
                        <div className={styles.cardValue}>{stats.completed}</div>
                    </div>
                </div>

                {/* 2. RECENT REQUESTS SECTION */}
                <div className={styles.section}>
                    <h2 className={styles.sectionTitle}>Recent E-Waste Requests</h2>
                    <div className={styles.recentGrid}>
                        {recentRequests.length === 0 ? (
                            <div className={styles.emptyState}>No recent requests available.</div>
                        ) : (
                            recentRequests.map((req, index) => (
                                <div key={req._id || index} className={styles.recentCard}>
                                    <div className={styles.iconWrapper}>
                                        <FileText size={24} />
                                    </div>
                                    <div className={styles.reqInfo}>
                                        <div className={styles.reqTitle}>
                                            Request ID #{getShortRequestId(req._id)}
                                        </div>
                                        <div className={styles.reqResident}>
                                            {req.residentName || 'Unnamed Requester'}
                                        </div>
                                        <div className={styles.reqStatus}>
                                            {req.status || 'Unknown Status'}
                                        </div>
                                    </div>
                                    <div className={styles.reqDate}>
                                        Requested on:<br/>
                                        <strong>{formatDate(req.createdAt)}</strong>
                                    </div>
                                </div>
                            ))
                        )}
                    </div>
                </div>

                {/* 3. RECOMMENDATIONS SECTION */}
                <div className={styles.section}>
                    <h2 className={styles.sectionTitle}>Operational Recommendations</h2>
                    <p className={styles.subTitle}>Suggested next actions based on current request activity.</p>
                    <div className={styles.recommendationGrid}>
                        {recommendations.length === 0 ? (
                            <div className={styles.emptyState}>Recommendations will appear once request data is available.</div>
                        ) : (
                            recommendations.map((recommendation) => {
                                const RecommendationIcon = recommendation.icon;

                                return (
                                    <div key={recommendation.title} className={styles.recCard}>
                                        <div className={styles.recIcon}>
                                            <RecommendationIcon size={24} />
                                        </div>
                                        <div>
                                            <h3 className={styles.recTitle}>{recommendation.title}</h3>
                                            <p className={styles.recText}>{recommendation.text}</p>
                                        </div>
                                    </div>
                                );
                            })
                        )}
                    </div>
                </div>
            </div>
        </div>
    );
};

export default RequestsSummary;
