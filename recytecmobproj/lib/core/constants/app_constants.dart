enum UserRole {
  household,
  lgu,
  collector,
  unsupported,
}

enum AppShellTarget {
  household,
  lgu,
  collector,
  accessDenied,
}

class AppRoles {
  static const household = 'household';
  static const lgu = 'lgu';
  static const collector = 'collector';
  static const staff = 'Staff';

  static UserRole normalize(String? value) {
    final normalized = (value ?? '').trim().toLowerCase();
    switch (normalized) {
      case 'staff':
      case 'household':
      case 'regular_user':
      case 'regular user':
      case 'user':
      case 'resident':
        // The current backend still uses Staff for self-registered
        // household/mobile users. Preserve the backend string for API payloads
        // and normalize it only inside the app routing layer.
        return UserRole.household;
      case 'lgu':
        return UserRole.lgu;
      case 'collector':
        return UserRole.collector;
      default:
        return UserRole.unsupported;
    }
  }

  static bool canUseHouseholdShell(UserRole role) {
    return role == UserRole.household;
  }

  static bool canUseLguShell(UserRole role) {
    return role == UserRole.lgu;
  }

  static AppShellTarget shellTargetFor(String? value) {
    switch (normalize(value)) {
      case UserRole.household:
        return AppShellTarget.household;
      case UserRole.lgu:
        return AppShellTarget.lgu;
      case UserRole.collector:
        return AppShellTarget.collector;
      case UserRole.unsupported:
        return AppShellTarget.accessDenied;
    }
  }

  static String displayName(UserRole role) {
    switch (role) {
      case UserRole.household:
        return 'Household';
      case UserRole.lgu:
        return 'LGU';
      case UserRole.collector:
        return 'Collector';
      case UserRole.unsupported:
        return 'Unsupported';
    }
  }
}

class FullnessStatuses {
  static const empty = 'empty';
  static const partiallyFilled = 'partially_filled';
  static const nearlyFull = 'nearly_full';
  static const full = 'full';
  static const sensorOffline = 'sensor_offline';
  static const requiresInspection = 'requires_inspection';

  static const values = [
    empty,
    partiallyFilled,
    nearlyFull,
    full,
    sensorOffline,
    requiresInspection,
  ];

  static String normalize(String? value) {
    final normalized = _normalizeKey(value);
    if (values.contains(normalized)) return normalized;
    if (normalized == 'partial' || normalized == 'partially_full') {
      return partiallyFilled;
    }
    if (normalized == 'offline') return sensorOffline;
    return requiresInspection;
  }

  static String label(String? value) {
    switch (normalize(value)) {
      case empty:
        return 'Empty';
      case partiallyFilled:
        return 'Partially Filled';
      case nearlyFull:
        return 'Nearly Full';
      case full:
        return 'Full';
      case sensorOffline:
        return 'Sensor Offline';
      case requiresInspection:
      default:
        return 'Requires Inspection';
    }
  }
}

class SensorStatuses {
  static const online = 'online';
  static const offline = 'offline';
  static const delayedSync = 'delayed_sync';
  static const unknown = 'unknown';

  static const values = [
    online,
    offline,
    delayedSync,
    unknown,
  ];

  static String normalize(String? value) {
    final normalized = _normalizeKey(value);
    if (values.contains(normalized)) return normalized;
    if (normalized.contains('delay')) return delayedSync;
    if (normalized.contains('online')) return online;
    if (normalized.contains('offline')) return offline;
    return unknown;
  }

  static String label(String? value) {
    switch (normalize(value)) {
      case online:
        return 'Online';
      case offline:
        return 'Offline';
      case delayedSync:
        return 'Delayed Sync';
      case unknown:
      default:
        return 'Unknown';
    }
  }
}

class CollectionRequestStatuses {
  static const pending = 'pending';
  static const approved = 'approved';
  static const rejected = 'rejected';
  static const collectorAssigned = 'collector_assigned';
  static const onTheWay = 'on_the_way';
  static const arrived = 'arrived';
  static const inProgress = 'in_progress';
  static const completed = 'completed';
  static const cancelled = 'cancelled';
  static const rescheduled = 'rescheduled';

  static const activeValues = [
    pending,
    approved,
    collectorAssigned,
    onTheWay,
    arrived,
    inProgress,
    rescheduled,
  ];

  static const values = [
    pending,
    approved,
    rejected,
    collectorAssigned,
    onTheWay,
    arrived,
    inProgress,
    completed,
    cancelled,
    rescheduled,
  ];

  static String normalize(String? value) {
    final normalized = _normalizeKey(value);
    if (values.contains(normalized)) return normalized;
    if (normalized == 'assigned') return collectorAssigned;
    if (normalized == 'pending_review') return pending;
    return pending;
  }

  static bool isActive(String? value) {
    return activeValues.contains(normalize(value));
  }

  static String label(String? value) {
    switch (normalize(value)) {
      case pending:
        return 'Pending';
      case approved:
        return 'Approved';
      case rejected:
        return 'Rejected';
      case collectorAssigned:
        return 'Collector Assigned';
      case onTheWay:
        return 'On The Way';
      case arrived:
        return 'Arrived';
      case inProgress:
        return 'In Progress';
      case completed:
        return 'Completed';
      case cancelled:
        return 'Cancelled';
      case rescheduled:
        return 'Rescheduled';
      default:
        return 'Pending';
    }
  }
}

class CollectorJobStatuses {
  static const assigned = 'collector_assigned';
  static const onTheWay = 'on_the_way';
  static const arrived = 'arrived';
  static const inProgress = 'in_progress';
  static const readyForCompletion = 'ready_for_completion';
  static const completed = 'completed';
  static const cancelled = 'cancelled';

  static const values = [
    assigned,
    onTheWay,
    arrived,
    inProgress,
    readyForCompletion,
    completed,
    cancelled,
  ];

  static String normalize(String? value) {
    final normalized = _normalizeKey(value);
    if (values.contains(normalized)) return normalized;
    if (normalized == 'approved' || normalized == 'assigned') return assigned;
    if (normalized == 'in_transit' || normalized == 'on_the_way') {
      return onTheWay;
    }
    if (normalized == 'started' || normalized == 'collection_started') {
      return inProgress;
    }
    if (normalized == 'collected' || normalized == 'ready') {
      return readyForCompletion;
    }
    return assigned;
  }

  static String backendValue(String status) {
    switch (normalize(status)) {
      case assigned:
        return 'Approved';
      case onTheWay:
        return 'In-Transit';
      case arrived:
        return 'Arrived';
      case inProgress:
        return 'In Progress';
      case readyForCompletion:
        return 'Collected';
      case completed:
        return 'Completed';
      case cancelled:
        return 'Cancelled';
      default:
        return status;
    }
  }

  static String label(String? value) {
    switch (normalize(value)) {
      case assigned:
        return 'Assigned';
      case onTheWay:
        return 'On The Way';
      case arrived:
        return 'Arrived';
      case inProgress:
        return 'In Progress';
      case readyForCompletion:
        return 'Ready for Completion';
      case completed:
        return 'Completed';
      case cancelled:
        return 'Cancelled';
      default:
        return 'Assigned';
    }
  }

  static String? next(String? current) {
    switch (normalize(current)) {
      case assigned:
        return onTheWay;
      case onTheWay:
        return arrived;
      case arrived:
        return inProgress;
      case inProgress:
        return readyForCompletion;
      case readyForCompletion:
        return completed;
      case completed:
      case cancelled:
        return null;
      default:
        return null;
    }
  }

  static bool canTransition(String? from, String to) {
    return next(from) == normalize(to);
  }
}

class CollectorCollectionConstants {
  static const beforeBinConditions = [
    'Full',
    'Overflowing',
    'Partially Filled',
    'Damaged',
    'Wet',
    'Contaminated',
    'Inaccessible',
    'Sensor Issue',
    'Other',
  ];

  static const itemConditions = [
    'Working',
    'Repairable',
    'Damaged',
    'Non-functional',
    'For Parts',
    'Unknown',
  ];

  static const finalBinStatuses = [
    'Empty',
    'Serviced',
    'Partially Cleared',
    'Requires Repair',
    'Requires Follow-Up',
    'Unable to Complete',
  ];
}

String _normalizeKey(String? value) {
  return (value ?? '')
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[\s-]+'), '_')
      .replaceAll(RegExp(r'_+'), '_');
}
