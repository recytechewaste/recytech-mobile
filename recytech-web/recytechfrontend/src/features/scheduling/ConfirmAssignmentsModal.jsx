const ConfirmAssignmentsModal = ({
    selectedCount,
    confirmMessage,
    confirming,
    onClose,
    onConfirm
}) => (
    <div
        style={{
            position: 'fixed',
            top: 0,
            left: 0,
            right: 0,
            bottom: 0,
            backgroundColor: 'rgba(0,0,0,0.5)',
            display: 'flex',
            justifyContent: 'center',
            alignItems: 'center',
            zIndex: 1000
        }}
    >
        <div
            style={{
                backgroundColor: 'white',
                borderRadius: '8px',
                padding: '24px',
                maxWidth: '400px',
                width: '90%',
                boxShadow: '0 20px 25px -5px rgba(0,0,0,0.1)'
            }}
        >
            <h3 style={{ margin: '0 0 12px 0', color: '#111827' }}>Confirm Assignments</h3>
            <p style={{ margin: '0 0 16px 0', color: '#6b7280', fontSize: '14px' }}>
                You are about to confirm {selectedCount} collector assignment(s). This action cannot be easily undone.
            </p>

            {confirmMessage && (
                <div
                    style={{
                        padding: '12px',
                        marginBottom: '16px',
                        borderRadius: '6px',
                        backgroundColor: confirmMessage.includes('Error') ? '#fee2e2' : '#d4edda',
                        color: confirmMessage.includes('Error') ? '#991b1b' : '#155724',
                        fontSize: '14px'
                    }}
                >
                    {confirmMessage}
                </div>
            )}

            <div style={{ display: 'flex', gap: '12px', justifyContent: 'flex-end' }}>
                <button
                    onClick={onClose}
                    disabled={confirming}
                    style={{
                        padding: '8px 16px',
                        backgroundColor: '#e5e7eb',
                        color: '#111827',
                        border: 'none',
                        borderRadius: '6px',
                        cursor: confirming ? 'not-allowed' : 'pointer',
                        fontWeight: '500'
                    }}
                >
                    Cancel
                </button>
                <button
                    onClick={onConfirm}
                    disabled={confirming}
                    style={{
                        padding: '8px 16px',
                        backgroundColor: confirming ? '#d1d5db' : '#10b981',
                        color: 'white',
                        border: 'none',
                        borderRadius: '6px',
                        cursor: confirming ? 'not-allowed' : 'pointer',
                        fontWeight: '500'
                    }}
                >
                    {confirming ? 'Confirming...' : 'Confirm'}
                </button>
            </div>
        </div>
    </div>
);

export default ConfirmAssignmentsModal;
