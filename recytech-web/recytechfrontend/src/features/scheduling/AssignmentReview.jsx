import { CheckCircle } from 'lucide-react';
import styles from '../../styles/Dashboard.module.css';
import RequestPriorityTags from './RequestPriorityTags';

const AssignmentReview = ({
    recommendations,
    selectedAssignments,
    scheduledTimes,
    onSelectAssignment,
    onTimeChange,
    onOpenConfirmModal
}) => {
    if (recommendations.length === 0) return null;

    const selectedCount = Object.keys(selectedAssignments).length;

    return (
        <div className={styles.chartCard} style={{ marginTop: '24px' }}>
            <h3 className={styles.cardTitle}>Review & Confirm Assignments</h3>
            <span className={styles.chartSub}>Select assignments and set scheduled times before confirming</span>

            <div style={{ marginTop: '16px' }}>
                {recommendations.map((collector) => (
                    <div key={collector.collectorId} style={{ marginBottom: '24px', paddingBottom: '16px', borderBottom: '1px solid #e5e7eb' }}>
                        <h4 style={{ margin: '0 0 12px 0', color: '#111827', fontWeight: '600' }}>
                            {collector.collectorName} ({collector.vehicleType})
                        </h4>
                        <div style={{ display: 'grid', gap: '8px' }}>
                            {collector.assignedRequests.map((request) => {
                                const key = `${request.requestId}-${collector.collectorId}`;
                                const isSelected = selectedAssignments[key];

                                return (
                                    <div
                                        key={request.requestId}
                                        style={{
                                            padding: '12px',
                                            border: isSelected ? '2px solid #2563EB' : '1px solid #e5e7eb',
                                            borderRadius: '6px',
                                            backgroundColor: isSelected ? '#f0f9ff' : '#f9fafb',
                                            cursor: 'pointer',
                                            transition: 'all 0.2s'
                                        }}
                                        onClick={() => onSelectAssignment(request.requestId, collector.collectorId)}
                                    >
                                        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', gap: '12px' }}>
                                            <div style={{ flex: 1 }}>
                                                <div style={{ fontWeight: '500', color: '#111827' }}>
                                                    {request.residentName} - {request.wasteType}
                                                </div>
                                                <div style={{ fontSize: '12px', color: '#6b7280', marginTop: '4px' }}>
                                                    {request.location}
                                                </div>
                                                <RequestPriorityTags request={request} />
                                                {(request.reasons || []).length > 0 && (
                                                    <ul style={{ margin: '8px 0 0 0', paddingLeft: '18px', color: '#4b5563', fontSize: '12px', lineHeight: 1.5 }}>
                                                        {request.reasons.map((reason) => (
                                                            <li key={reason}>{reason}</li>
                                                        ))}
                                                    </ul>
                                                )}
                                            </div>
                                            <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                                                <input
                                                    type="datetime-local"
                                                    value={scheduledTimes[request.requestId] || ''}
                                                    onChange={(event) => {
                                                        event.stopPropagation();
                                                        onTimeChange(request.requestId, event.target.value);
                                                    }}
                                                    style={{
                                                        padding: '6px 8px',
                                                        fontSize: '12px',
                                                        border: '1px solid #d1d5db',
                                                        borderRadius: '4px'
                                                    }}
                                                />
                                                {isSelected ? (
                                                    <CheckCircle size={20} color="#10b981" />
                                                ) : (
                                                    <div style={{ width: '20px', height: '20px', border: '2px solid #d1d5db', borderRadius: '50%' }} />
                                                )}
                                            </div>
                                        </div>
                                    </div>
                                );
                            })}
                        </div>
                    </div>
                ))}
            </div>

            <button
                onClick={onOpenConfirmModal}
                disabled={selectedCount === 0}
                style={{
                    marginTop: '16px',
                    padding: '10px 20px',
                    backgroundColor: selectedCount === 0 ? '#d1d5db' : '#2563EB',
                    color: 'white',
                    border: 'none',
                    borderRadius: '6px',
                    cursor: selectedCount === 0 ? 'not-allowed' : 'pointer',
                    fontWeight: '600',
                    fontSize: '14px'
                }}
            >
                Confirm {selectedCount} Assignment(s)
            </button>
        </div>
    );
};

export default AssignmentReview;
