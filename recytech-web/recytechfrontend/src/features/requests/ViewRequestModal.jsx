import styles from '../../styles/RequestManagement.module.css';

const getCollectorName = (collector) => collector?.firstName ? `${collector.firstName} ${collector.lastName}` : 'Unassigned';
const isDropoffReady = (request) => request.status === 'Collected' && !request.paymentProcessed;
const isPayoutReady = (request) =>
    ['Drop-off Confirmed', 'Received'].includes(request.status) && !request.paymentProcessed;
const formatMoney = (value) => Number(value || 0) > 0 ? `PHP ${Number(value).toFixed(2)}` : 'Not released';

const ViewRequestModal = ({ request, onClose, onApprove, onConfirmDropoff, onReleasePayout }) => {
    if (!request) return null;
    const image = request.wasteImage || request.imageUrl || '';
    const canRenderImage = image.startsWith('data:image/') || image.startsWith('http://') || image.startsWith('https://');

    return (
        <div className={styles.modalOverlay}>
            <div className={styles.modalContent}>
                <div className={styles.modalHeader}>
                    <h2 className={styles.modalTitle}>Request Details</h2>
                    <button onClick={onClose} className={styles.closeBtn}>&times;</button>
                </div>

                <div className={styles.modalBody}>
                    <div className={styles.detailsSection}>
                        {canRenderImage ? (
                            <img src={image} className={styles.evidenceImage} alt="Submitted e-waste" />
                        ) : (
                            <div className={styles.imageFallback}>No image provided.</div>
                        )}
                        <div className={styles.detailRow}><strong>Resident:</strong> {request.residentName}</div>
                        <div className={styles.detailRow}><strong>Detected Item:</strong> {request.itemCategory || request.detectedClass || 'N/A'}</div>
                        <div className={styles.detailRow}><strong>Waste Type:</strong> {request.wasteType}</div>
                        <div className={styles.detailRow}><strong>Rate / kg:</strong> {request.ratePerKg ? `PHP ${Number(request.ratePerKg).toFixed(2)}` : 'N/A'}</div>
                        <div className={styles.detailRow}><strong>Resident Email:</strong> {request.resident?.email || request.residentEmail || 'N/A'}</div>
                        <div className={styles.detailRow}><strong>Quantity:</strong> {request.quantity || 1} item(s)</div>
                        <div className={styles.detailRow}><strong>Location:</strong> {request.location?.address}</div>
                        <div className={styles.detailRow}><strong>Assigned To:</strong> {getCollectorName(request.assignedCollector)}</div>
                        {request.assignedCollector?.firstName && (
                            <>
                                <div className={styles.detailRow}><strong>Collector Phone:</strong> {request.assignedCollector.phone}</div>
                                <div className={styles.detailRow}><strong>Vehicle Type:</strong> {request.assignedCollector.vehicleType}</div>
                                <div className={styles.detailRow}><strong>Plate Number:</strong> {request.assignedCollector.vehiclePlate}</div>
                            </>
                        )}
                        <div className={styles.detailRow}><strong>Status:</strong> {request.status}</div>
                        <div className={styles.detailRow}><strong>Payout Status:</strong> {request.paymentProcessed ? 'Released' : (request.payoutStatus || 'Not Ready')}</div>
                        <div className={styles.detailRow}><strong>Payout Amount:</strong> {formatMoney(request.monetaryValue)}</div>
                        <div className={styles.detailRow}>
                            <strong>Drop-off Confirmed:</strong> {request.dropoffConfirmedAt ? new Date(request.dropoffConfirmedAt).toLocaleString() : 'Not confirmed'}
                        </div>
                        <div className={styles.detailRow}>
                            <strong>Payout Released:</strong> {request.payoutReleasedAt ? new Date(request.payoutReleasedAt).toLocaleString() : 'Not released'}
                        </div>
                        <div className={styles.detailRow}>
                            <strong>Pickup Schedule:</strong> {request.scheduledAt ? new Date(request.scheduledAt).toLocaleString() : 'Not scheduled'}
                        </div>
                    </div>
                    <div className={styles.mapSection}>
                        <iframe
                            width="100%"
                            height="100%"
                            frameBorder="0"
                            style={{ border: 0 }}
                            src={`https://maps.google.com/maps?q=${encodeURIComponent(request.location?.address || 'Philippines')}&t=&z=15&ie=UTF8&iwloc=&output=embed`}
                            allowFullScreen
                        />
                    </div>
                </div>

                <div style={{ marginTop: '20px', display: 'flex', justifyContent: 'flex-end', gap: '10px' }}>
                    {request.status === 'Pending' && (
                        <button onClick={() => onApprove(request)} className={styles.approveBtn}>Proceed to Approve</button>
                    )}
                    {isDropoffReady(request) && (
                        <button onClick={() => onConfirmDropoff(request)} className={styles.approveBtn}>Confirm Drop-off</button>
                    )}
                    {isPayoutReady(request) && (
                        <button onClick={() => onReleasePayout(request)} className={styles.approveBtn}>Release Payout</button>
                    )}
                    <button onClick={onClose} className={styles.viewBtn}>Close</button>
                </div>
            </div>
        </div>
    );
};

export default ViewRequestModal;
