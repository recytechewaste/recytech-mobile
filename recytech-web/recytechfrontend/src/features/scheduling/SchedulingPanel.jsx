import { useEffect, useState } from 'react';
import api from '../../api/client';
import styles from '../../styles/Dashboard.module.css';
import ActionRecommendations from './ActionRecommendations';
import AssignmentReview from './AssignmentReview';
import CollectorRecommendationsTable from './CollectorRecommendationsTable';
import ConfirmAssignmentsModal from './ConfirmAssignmentsModal';
import ForecastTable from './ForecastTable';
import ResourceAllocationSummary from './ResourceAllocationSummary';
import SchedulingGuidance from './SchedulingGuidance';
import SchedulingHeader from './SchedulingHeader';

const getDefaultScheduleTime = () => {
    const tomorrow = new Date();
    tomorrow.setDate(tomorrow.getDate() + 1);
    tomorrow.setHours(9, 0, 0, 0);
    return tomorrow.toISOString().slice(0, 16);
};

const buildInitialScheduledTimes = (recommendations = []) => {
    const defaultTime = getDefaultScheduleTime();

    return recommendations.reduce((times, recommendation) => {
        recommendation.assignedRequests?.forEach((request) => {
            times[request.requestId] = defaultTime;
        });

        return times;
    }, {});
};

const SchedulingPanel = () => {
    const [forecast, setForecast] = useState([]);
    const [recommendations, setRecommendations] = useState([]);
    const [actionRecommendations, setActionRecommendations] = useState([]);
    const [resourceSummary, setResourceSummary] = useState({});
    const [loading, setLoading] = useState(true);
    const [error, setError] = useState('');
    const [showConfirmModal, setShowConfirmModal] = useState(false);
    const [confirming, setConfirming] = useState(false);
    const [confirmMessage, setConfirmMessage] = useState('');
    const [selectedAssignments, setSelectedAssignments] = useState({});
    const [scheduledTimes, setScheduledTimes] = useState({});

    useEffect(() => {
        const fetchScheduling = async () => {
            try {
                const [forecastRes, recommendationRes] = await Promise.all([
                    api.get('/scheduling/forecast?days=7'),
                    api.get('/scheduling/recommendations')
                ]);

                const recommendationData = recommendationRes.data.recommendations || [];

                setForecast(forecastRes.data.forecast || []);
                setRecommendations(recommendationData);
                setActionRecommendations(recommendationRes.data.actionRecommendations || []);
                setResourceSummary(recommendationRes.data.resourceSummary || {});
                setScheduledTimes(buildInitialScheduledTimes(recommendationData));
            } catch (err) {
                console.error('Scheduling API error', err);
                setError('Unable to load scheduling suggestions.');
            } finally {
                setLoading(false);
            }
        };

        fetchScheduling();
    }, []);

    const toggleAssignmentSelection = (requestId, collectorId) => {
        setSelectedAssignments((previousSelection) => {
            const key = `${requestId}-${collectorId}`;
            const nextSelection = { ...previousSelection };

            if (nextSelection[key]) {
                delete nextSelection[key];
            } else {
                nextSelection[key] = { requestId, collectorId };
            }

            return nextSelection;
        });
    };

    const handleTimeChange = (requestId, value) => {
        setScheduledTimes((previousTimes) => ({
            ...previousTimes,
            [requestId]: value
        }));
    };

    const closeConfirmModal = () => {
        setShowConfirmModal(false);
        setConfirmMessage('');
    };

    const handleConfirmAssignments = async () => {
        const assignments = Object.values(selectedAssignments).map(({ requestId, collectorId }) => ({
            requestId,
            collectorId,
            scheduledAt: scheduledTimes[requestId]
        }));

        if (assignments.length === 0) {
            setConfirmMessage('Please select at least one assignment to confirm.');
            return;
        }

        setConfirming(true);
        try {
            const response = await api.post('/scheduling/confirm-assignments', { assignments });

            if (response.data.successful > 0) {
                setConfirmMessage(`${response.data.successful} assignment(s) confirmed successfully.`);
                setSelectedAssignments({});
                setTimeout(() => {
                    window.location.reload();
                }, 2000);
            }

            if (response.data.failed > 0) {
                setConfirmMessage(`${response.data.failed} assignment(s) failed. Check details below.`);
            }
        } catch (err) {
            setConfirmMessage(`Error: ${err.response?.data?.message || err.message}`);
        } finally {
            setConfirming(false);
        }
    };

    const forecastTotal = forecast.reduce((sum, item) => sum + (item.predictedRequests || 0), 0);
    const recommendationCount = recommendations.reduce((count, recommendation) => count + recommendation.assignedRequests.length, 0);
    const selectedCount = Object.keys(selectedAssignments).length;

    return (
        <div className={styles.sectionContainer}>
            <SchedulingHeader forecastTotal={forecastTotal} recommendationCount={recommendationCount} />

            <div className={styles.chartsGrid} style={{ marginTop: '24px' }}>
                <ActionRecommendations actions={actionRecommendations} loading={loading} />
                <ResourceAllocationSummary summary={resourceSummary} />
            </div>

            <div className={styles.chartsGrid} style={{ marginTop: '24px' }}>
                <ForecastTable forecast={forecast} loading={loading} error={error} />
                <CollectorRecommendationsTable recommendations={recommendations} loading={loading} error={error} />
            </div>

            <AssignmentReview
                recommendations={recommendations}
                selectedAssignments={selectedAssignments}
                scheduledTimes={scheduledTimes}
                onSelectAssignment={toggleAssignmentSelection}
                onTimeChange={handleTimeChange}
                onOpenConfirmModal={() => setShowConfirmModal(true)}
            />

            {showConfirmModal && (
                <ConfirmAssignmentsModal
                    selectedCount={selectedCount}
                    confirmMessage={confirmMessage}
                    confirming={confirming}
                    onClose={closeConfirmModal}
                    onConfirm={handleConfirmAssignments}
                />
            )}

            <SchedulingGuidance />
        </div>
    );
};

export default SchedulingPanel;
