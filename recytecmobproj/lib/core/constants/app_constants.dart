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

  static const canonicalMobileRoles = {
    household,
    partnerOrg,
    collector,
  };

  static UserRole normalize(String? value) {
    final normalized = (value ?? '').trim().toLowerCase();
    switch (normalized) {
      case 'household':
      case 'registered_user':
      case 'user':
      case 'resident':
        return UserRole.household;
      case 'lgu':
      case 'partner organization':
      case 'partnerorganization':
      case 'partner_org':
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

  static String? canonicalRole(String? value) {
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

  // Kept as a compatibility name for existing registration callers.
  static String? canonicalApiRole(String? value) => canonicalRole(value);

  static bool isCanonical(String? value) =>
      canonicalMobileRoles.contains(value?.trim());

  static bool isHousehold(String? value) => canonicalRole(value) == household;

  static bool isPartnerOrg(String? value) => canonicalRole(value) == partnerOrg;

  static bool isCollector(String? value) => canonicalRole(value) == collector;

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

  static String displayNameFor(String? role) => displayName(normalize(role));
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

class PartnerBinStatuses {
  const PartnerBinStatuses._();

  static const empty = 'Empty';
  static const operational = 'Operational';
  static const full = 'Full';
  static const maintenance = 'Maintenance';
  static const active = 'Active';

  static const values = [empty, operational, full, maintenance, active];

  static bool isValid(String? value) => values.contains(value);
}

class RequestStatuses {
  static const pending = 'pending';
  static const scheduled = 'scheduled';
  static const assigned = 'assigned';
  static const inProgress = 'in_progress';
  static const inTransit = 'in_transit';
  static const arrived = 'arrived';
  static const completed = 'completed';
  static const cancelled = 'cancelled';

  static const values = [
    pending,
    scheduled,
    assigned,
    inProgress,
    inTransit,
    arrived,
    completed,
    cancelled,
  ];

  static const activeValues = [
    pending,
    scheduled,
    assigned,
    inProgress,
    inTransit,
    arrived,
  ];

  static String normalize(String? value) {
    final normalized = _normalizeKey(value);
    if (values.contains(normalized)) return normalized;

    switch (normalized) {
      case 'queued':
      case 'pending_review':
        return pending;
      case 'approved':
      case 'collector_assigned':
        return assigned;
      case 'rescheduled':
        return scheduled;
      case 'started':
      case 'collection_started':
        return inProgress;
      case 'on_the_way':
        return inTransit;
      case 'canceled':
      case 'rejected':
        return cancelled;
      default:
        throw FormatException('Unsupported request status: $value');
    }
  }

  static bool isActive(String? value) =>
      activeValues.contains(normalize(value));

  static String label(String? value) {
    switch (normalize(value)) {
      case pending:
        return 'Pending';
      case scheduled:
        return 'Scheduled';
      case assigned:
        return 'Assigned';
      case inProgress:
        return 'In Progress';
      case inTransit:
        return 'In Transit';
      case arrived:
        return 'Arrived';
      case completed:
        return 'Completed';
      case cancelled:
        return 'Cancelled';
    }

    throw StateError('Unreachable request status label');
  }
}

class CollectorJobStatuses {
  static const assigned = 'assigned';
  static const queued = assigned;
  static const inTransit = 'in_transit';
  static const onTheWay = inTransit;
  static const arrived = 'arrived';
  static const inProgress = 'in_progress';
  static const readyForCompletion = 'ready_for_completion';
  static const completed = 'completed';
  static const cancelled = 'cancelled';

  static const values = [
    assigned,
    inTransit,
    arrived,
    inProgress,
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
    if (normalized == 'on_the_way') {
      return inTransit;
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
        return assigned;
      case inTransit:
        return inTransit;
      case arrived:
        return arrived;
      case inProgress:
        return inProgress;
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
      case inTransit:
        return 'On the Way';
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
        return inTransit;
      case inTransit:
        return arrived;
      case arrived:
        return inProgress;
      case inProgress:
        return completed;
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

  static bool isOperationalUpdate(String? status) {
    final normalized = normalize(status);
    return normalized == inTransit ||
        normalized == arrived ||
        normalized == inProgress;
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
