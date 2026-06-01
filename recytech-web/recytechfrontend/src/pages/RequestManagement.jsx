import { useEffect, useState } from 'react';
import api from '../api/client';
import Sidebar from '../components/Sidebar';
import AssignCollectorModal from '../features/requests/AssignCollectorModal';
import ConfirmAssignmentModal from '../features/requests/ConfirmAssignmentModal';
import RejectConfirmationModal from '../features/requests/RejectConfirmationModal';
import RequestFilters from '../features/requests/RequestFilters';
import RequestStats from '../features/requests/RequestStats';
import RequestTable from '../features/requests/RequestTable';
import SuccessModal from '../features/requests/SuccessModal';
import ViewRequestModal from '../features/requests/ViewRequestModal';
import styles from '../styles/RequestManagement.module.css';
import { normalizeCategory } from '../utils/categoryNormalization';

const calculateStats = (requests) => ({
    total: requests.length,
    pending: requests.filter((request) => request.status === 'Pending').length,
    approved: requests.filter((request) => request.status === 'Approved').length,
    collected: requests.filter((request) => request.status === 'Collected').length,
    readyPayout: requests.filter((request) =>
        ['Drop-off Confirmed', 'Received'].includes(request.status) && !request.paymentProcessed
    ).length,
    completed: requests.filter((request) => request.status === 'Completed' || request.paymentProcessed).length
});

const filterRequests = (requests, filters) => {
    let result = [...requests];

    if (filters.status) {
        result = result.filter((request) => request.status === filters.status);
    }

    if (filters.wasteType) {
        result = result.filter((request) => normalizeCategory(request.wasteType) === normalizeCategory(filters.wasteType));
    }

    if (filters.assignment === 'assigned') {
        result = result.filter((request) => Boolean(request.assignedCollector));
    } else if (filters.assignment === 'unassigned') {
        result = result.filter((request) => !request.assignedCollector);
    } else if (filters.assignment === 'scheduled') {
        result = result.filter((request) => Boolean(request.scheduledAt));
    } else if (filters.assignment === 'unscheduled') {
        result = result.filter((request) => !request.scheduledAt);
    }

    return result;
};

const RequestManagement = () => {
    const [requests, setRequests] = useState([]);
    const [filteredRequests, setFilteredRequests] = useState([]);
    const [collectors, setCollectors] = useState([]);
    const [wasteCategories, setWasteCategories] = useState([]);
    const [stats, setStats] = useState({
        total: 0,
        pending: 0,
        approved: 0,
        collected: 0,
        readyPayout: 0,
        completed: 0
    });
    const [showSuccessModal, setShowSuccessModal] = useState(false);
    const [successMessage, setSuccessMessage] = useState('');
    const [successTitle, setSuccessTitle] = useState('');
    const [viewRequest, setViewRequest] = useState(null);
    const [selectedRequest, setSelectedRequest] = useState(null);
    const [selectedCollector, setSelectedCollector] = useState('');
    const [selectedScheduleDate, setSelectedScheduleDate] = useState('');
    const [selectedScheduleTime, setSelectedScheduleTime] = useState('');
    const [scheduleConflict, setScheduleConflict] = useState('');
    const [showAssignmentModal, setShowAssignmentModal] = useState(false);
    const [rejectingRequestId, setRejectingRequestId] = useState(null);
    const [filters, setFilters] = useState({
        status: '',
        wasteType: '',
        assignment: ''
    });

    const fetchData = async () => {
        try {
            const [reqData, colData, rateData] = await Promise.all([
                api.get('/requests'),
                api.get('/collectors'),
                api.get('/exchange-rates')
            ]);

            setRequests(reqData.data);
            setFilteredRequests(reqData.data);
            setCollectors(colData.data);
            setWasteCategories((rateData.data.rates || []).map((rate) => rate.wasteType));
            setStats(calculateStats(reqData.data));
        } catch (error) {
            console.error('Error', error);
        }
    };

    useEffect(() => {
        Promise.resolve().then(fetchData);
    }, []);

    useEffect(() => {
        setFilteredRequests(filterRequests(requests, filters));
    }, [filters, requests]);

    useEffect(() => {
        if (!selectedCollector || !selectedScheduleDate || !selectedScheduleTime || !selectedRequest) {
            setScheduleConflict('');
            return;
        }

        const scheduledAt = new Date(`${selectedScheduleDate}T${selectedScheduleTime}`);
        const hasConflict = requests.some((request) => {
            if (!request.assignedCollector || !request.scheduledAt || request._id === selectedRequest._id) return false;
            if (request.assignedCollector._id !== selectedCollector) return false;

            const otherTime = new Date(request.scheduledAt);
            return otherTime.getTime() === scheduledAt.getTime() && ['Pending', 'Approved', 'In-Transit'].includes(request.status);
        });

        setScheduleConflict(hasConflict ? 'Selected collector already has another request at the same scheduled date and time.' : '');
    }, [selectedCollector, selectedScheduleDate, selectedScheduleTime, requests, selectedRequest]);

    const handleClearFilters = () => {
        setFilters({
            status: '',
            wasteType: '',
            assignment: ''
        });
    };

    const resetAssignmentForm = () => {
        setSelectedCollector('');
        setSelectedScheduleDate('');
        setSelectedScheduleTime('');
        setScheduleConflict('');
    };

    const closeAssignmentModal = () => {
        setSelectedRequest(null);
        resetAssignmentForm();
    };

    const handleApproveClick = (request) => {
        setSelectedRequest(request);
        if (viewRequest) setViewRequest(null);

        if (request.scheduledAt) {
            const dateTime = new Date(request.scheduledAt);
            setSelectedScheduleDate(dateTime.toISOString().substring(0, 10));
            setSelectedScheduleTime(dateTime.toTimeString().substring(0, 5));
        } else {
            setSelectedScheduleDate('');
            setSelectedScheduleTime('');
        }

        setSelectedCollector(request.assignedCollector?._id || '');
        setScheduleConflict('');
    };

    const confirmAssignment = () => {
        if (!selectedCollector) return alert('Please select a collector');
        if (!selectedScheduleDate || !selectedScheduleTime) return alert('Please select a scheduled date and time.');
        if (scheduleConflict) return alert(scheduleConflict);
        setShowAssignmentModal(true);
    };

    const executeAssignment = async () => {
        try {
            const scheduledAt = `${selectedScheduleDate}T${selectedScheduleTime}`;
            await api.put(`/requests/${selectedRequest._id}`, {
                status: 'Approved',
                assignedCollector: selectedCollector,
                scheduledAt
            });

            setSuccessTitle('Request Approved');
            setSuccessMessage('The pickup request has been successfully approved, assigned, and scheduled.');
            setShowSuccessModal(true);
            setShowAssignmentModal(false);
            setSelectedRequest(null);
            resetAssignmentForm();
            fetchData();
        } catch (error) {
            console.error(error);
            alert(error.response?.data?.message || 'Unable to approve the request.');
        }
    };

    const confirmReject = async () => {
        try {
            await api.put(`/requests/${rejectingRequestId}`, { status: 'Rejected' });
            setSuccessTitle('Request Rejected');
            setSuccessMessage('The pickup request has been successfully marked as Rejected.');
            setShowSuccessModal(true);
            setRejectingRequestId(null);
            fetchData();
        } catch (error) {
            console.error(error);
        }
    };

    const confirmDropoff = async (request) => {
        try {
            await api.put(`/requests/${request._id}/dropoff-confirmed`);
            setSuccessTitle('Drop-off Confirmed');
            setSuccessMessage('The collected e-waste has been confirmed at the drop-off point. Payout can now be released.');
            setShowSuccessModal(true);
            setViewRequest(null);
            fetchData();
        } catch (error) {
            console.error(error);
            alert(error.response?.data?.message || 'Unable to confirm drop-off.');
        }
    };

    const releasePayout = async (request) => {
        try {
            const res = await api.put(`/requests/${request._id}/release-payout`);
            const amount = res.data?.payout?.amount ?? res.data?.request?.monetaryValue;
            setSuccessTitle('Payout Released');
            setSuccessMessage(`The resident payout${amount ? ` of PHP ${Number(amount).toFixed(2)}` : ''} has been released.`);
            setShowSuccessModal(true);
            setViewRequest(null);
            fetchData();
        } catch (error) {
            console.error(error);
            alert(error.response?.data?.message || 'Unable to release payout.');
        }
    };

    return (
        <div className={styles.container}>
            <Sidebar activePage="Request Management" />
            <div className={styles.main}>
                <div className={styles.headerContainer}>
                    <div className={styles.headerLeft}>
                        <h1 className={styles.pageTitle}>Request Management</h1>
                        <p className={styles.subTitle}>Monitor and verify e-waste pickup requests within your jurisdiction.</p>
                    </div>
                </div>

                <RequestFilters
                    filters={filters}
                    wasteCategories={wasteCategories}
                    onFilterChange={setFilters}
                    onClearFilters={handleClearFilters}
                />
                <RequestStats stats={stats} />
                <RequestTable
                    requests={filteredRequests}
                    onView={setViewRequest}
                    onApprove={handleApproveClick}
                    onReject={setRejectingRequestId}
                    onConfirmDropoff={confirmDropoff}
                    onReleasePayout={releasePayout}
                />

                <ViewRequestModal
                    request={viewRequest}
                    onClose={() => setViewRequest(null)}
                    onApprove={handleApproveClick}
                    onConfirmDropoff={confirmDropoff}
                    onReleasePayout={releasePayout}
                />

                {selectedRequest && !showAssignmentModal && (
                    <AssignCollectorModal
                        request={selectedRequest}
                        collectors={collectors}
                        selectedCollector={selectedCollector}
                        selectedScheduleDate={selectedScheduleDate}
                        selectedScheduleTime={selectedScheduleTime}
                        scheduleConflict={scheduleConflict}
                        onCollectorChange={setSelectedCollector}
                        onDateChange={setSelectedScheduleDate}
                        onTimeChange={setSelectedScheduleTime}
                        onCancel={closeAssignmentModal}
                        onAssign={confirmAssignment}
                    />
                )}

                {showAssignmentModal && (
                    <ConfirmAssignmentModal
                        collectors={collectors}
                        selectedCollector={selectedCollector}
                        onCancel={() => setShowAssignmentModal(false)}
                        onConfirm={executeAssignment}
                    />
                )}

                {showSuccessModal && (
                    <SuccessModal
                        title={successTitle}
                        message={successMessage}
                        onContinue={() => setShowSuccessModal(false)}
                    />
                )}

                {rejectingRequestId && (
                    <RejectConfirmationModal
                        onCancel={() => setRejectingRequestId(null)}
                        onConfirm={confirmReject}
                    />
                )}
            </div>
        </div>
    );
};

export default RequestManagement;
