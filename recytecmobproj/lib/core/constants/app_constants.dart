enum UserRole {
  household,
  partnerOrg,
  collector,
  unsupported,
}

enum AppShellTarget {
  household,
  partnerOrg,
  collector,
  accessDenied,
}

class AppRoles {
  static const household = 'household';
  static const partnerOrg = 'partner_org';
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
      case 'registered_user':
      case 'registered user':
      case 'user':
      case 'resident':
        return UserRole.household;
      case 'lgu':
      case 'partner_organization':
      case 'partner organization':
      case 'partner_org':
      case 'partner org':
      case 'partner':
      case 'organization':
        return UserRole.partnerOrg;
      case 'collector':
        return UserRole.collector;
      default:
        return UserRole.unsupported;
    }
  }

  static bool canUseHouseholdShell(UserRole role) {
    return role == UserRole.household;
  }

  static bool canUsePartnerShell(UserRole role) {
    return role == UserRole.partnerOrg;
  }

  static bool canUseLguShell(UserRole role) {
    return canUsePartnerShell(role);
  }

  static AppShellTarget shellTargetFor(String? value) {
    switch (normalize(value)) {
      case UserRole.household:
        return AppShellTarget.household;
      case UserRole.partnerOrg:
        return AppShellTarget.partnerOrg;
      case UserRole.collector:
        return AppShellTarget.collector;
      case UserRole.unsupported:
        return AppShellTarget.accessDenied;
    }
  }

  static String? canonicalApiRole(String? value) {
    switch (normalize(value)) {
      case UserRole.household:
        return household;
      case UserRole.partnerOrg:
        return partnerOrg;
      case UserRole.collector:
        return collector;
      case UserRole.unsupported:
        return null;
    }
  }

  static String displayName(UserRole role) {
    switch (role) {
      case UserRole.household:
        return 'Registered User';
      case UserRole.partnerOrg:
        return 'Partner Organization';
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
  static const online = 'active';
  static const offline = 'offline';
  static const delayedSync = 'delayed';
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
    if (normalized == 'online') return online;
    if (normalized == 'delayed_sync') return delayedSync;
    if (normalized.contains('delay')) return delayedSync;
    if (normalized.contains('active')) return online;
    if (normalized.contains('offline')) return offline;
    return unknown;
  }

  static String label(String? value) {
    switch (normalize(value)) {
      case online:
        return 'Active';
      case offline:
        return 'Offline';
      case delayedSync:
        return 'Delayed';
      case unknown:
      default:
        return 'Unknown';
    }
  }
}

class CollectionRequestStatuses {
  static const queued = 'queued';
  static const pending = queued;
  static const approved = queued;
  static const collectorAssigned = queued;
  static const inProgress = 'in_progress';
  static const completed = 'completed';
  static const cancelled = 'cancelled';
  static const rejected = cancelled;
  static const onTheWay = inProgress;
  static const arrived = inProgress;
  static const rescheduled = queued;

  static const activeValues = [
    queued,
    inProgress,
  ];

  static const values = [
    queued,
    inProgress,
    completed,
    cancelled,
  ];

  static String normalize(String? value) {
    final normalized = _normalizeKey(value);
    if (values.contains(normalized)) return normalized;
    if (normalized == 'pending' ||
        normalized == 'approved' ||
        normalized == 'assigned' ||
        normalized == 'collector_assigned' ||
        normalized == 'pending_review' ||
        normalized == 'rescheduled') {
      return queued;
    }
    if (normalized == 'started' ||
        normalized == 'collection_started' ||
        normalized == 'on_the_way' ||
        normalized == 'arrived' ||
        normalized == 'in_transit') {
      return inProgress;
    }
    if (normalized == 'rejected' || normalized == 'canceled') {
      return cancelled;
    }
    return queued;
  }

  static bool isActive(String? value) {
    return activeValues.contains(normalize(value));
  }

  static String label(String? value) {
    switch (normalize(value)) {
      case queued:
        return 'Queued';
      case inProgress:
        return 'In Progress';
      case completed:
        return 'Completed';
      case cancelled:
        return 'Cancelled';
      default:
        return 'Queued';
    }
  }
}

class CollectorJobStatuses {
  static const assigned = 'collector_assigned';
  static const queued = assigned;
  static const onTheWay = 'on_the_way';
  static const arrived = 'arrived';
  static const inProgress = 'in_progress';
  static const readyForCompletion = 'ready_for_completion';
  static const completed = 'completed';
  static const cancelled = 'cancelled';

  static const values = [
    assigned,
    inProgress,
    onTheWay,
    arrived,
    readyForCompletion,
    completed,
    cancelled,
  ];

  static String normalize(String? value) {
    final normalized = _normalizeKey(value);
    if (values.contains(normalized)) return normalized;
    if (normalized == 'approved' ||
        normalized == 'assigned' ||
        normalized == 'queued' ||
        normalized == 'collector_assigned' ||
        normalized == 'pending') {
      return assigned;
    }
    if (normalized == 'started' || normalized == 'collection_started') {
      return inProgress;
    }
    if (normalized == 'in_transit') {
      return onTheWay;
    }
    if (normalized == 'ready' ||
        normalized == 'ready_for_completion' ||
        normalized == 'collected') {
      return readyForCompletion;
    }
    if (normalized == 'canceled' || normalized == 'rejected') return cancelled;
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
        return 'Queued';
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
        return 'Queued';
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
