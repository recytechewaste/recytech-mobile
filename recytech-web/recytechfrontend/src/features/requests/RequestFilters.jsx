import styles from '../../styles/RequestManagement.module.css';
import { formatCategoryLabel } from '../../utils/categoryNormalization';

const RequestFilters = ({ filters, wasteCategories, onFilterChange, onClearFilters }) => (
    <div className={styles.filterBar}>
        <div className={styles.filterGroup}>
            <label className={styles.label}>Status</label>
            <select
                className={styles.select}
                value={filters.status}
                onChange={(event) => onFilterChange({ ...filters, status: event.target.value })}
            >
                <option value="">All Statuses</option>
                <option value="Pending">Pending</option>
                <option value="Approved">Approved</option>
                <option value="In-Transit">In-Transit</option>
                <option value="Collected">Collected</option>
                <option value="Drop-off Confirmed">Drop-off Confirmed</option>
                <option value="Completed">Completed</option>
                <option value="Rejected">Rejected</option>
                <option value="Cancelled">Cancelled</option>
            </select>
        </div>
        <div className={styles.filterGroup}>
            <label className={styles.label}>Waste Category</label>
            <select
                className={styles.select}
                value={filters.wasteType}
                onChange={(event) => onFilterChange({ ...filters, wasteType: event.target.value })}
            >
                <option value="">All Categories</option>
                {wasteCategories.map((category) => (
                    <option key={category} value={category}>{formatCategoryLabel(category)}</option>
                ))}
            </select>
        </div>
        <div className={styles.filterGroup}>
            <label className={styles.label}>Assignment</label>
            <select
                className={styles.select}
                value={filters.assignment}
                onChange={(event) => onFilterChange({ ...filters, assignment: event.target.value })}
            >
                <option value="">All Assignments</option>
                <option value="assigned">Assigned</option>
                <option value="unassigned">Unassigned</option>
                <option value="scheduled">Scheduled</option>
                <option value="unscheduled">Unscheduled</option>
            </select>
        </div>
        <button className={styles.clearBtn} onClick={onClearFilters}>Clear All</button>
    </div>
);

export default RequestFilters;
