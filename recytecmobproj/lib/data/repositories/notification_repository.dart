import '../../core/constants/app_constants.dart';
import '../models/notification_model.dart';

class NotificationRepository {
  static final List<NotificationModel> _notifications = [
    NotificationModel(
      id: 'household-1',
      title: 'Drop-off recorded',
      message: 'Your designated-bin drop-off submission was recorded.',
      timestamp: DateTime(2026, 8, 12, 9, 15),
      isRead: false,
      role: UserRole.household,
      type: 'drop_off_recorded',
      relatedEntityId: 'DROP-DEMO-001',
      destination: const NotificationDestination(
        kind: NotificationDestinationKind.householdDropOff,
        entityId: 'DROP-DEMO-001',
      ),
    ),
    NotificationModel(
      id: 'household-2',
      title: 'Points pending',
      message:
          'Drop-off points processing will be available in a later update.',
      timestamp: DateTime(2026, 8, 12, 9, 18),
      isRead: true,
      role: UserRole.household,
      type: 'points_pending',
      relatedEntityId: 'REWARD-DROP-DEMO-001',
      destination: const NotificationDestination(
        kind: NotificationDestinationKind.householdDropOff,
        entityId: 'DROP-DEMO-001',
      ),
    ),
    NotificationModel(
      id: 'lgu-1',
      title: 'Bin alert',
      message: 'Municipal Hall Bin is full and ready for collection review.',
      timestamp: DateTime(2026, 8, 12, 8, 40),
      isRead: false,
      role: UserRole.partnerOrg,
      type: 'sensor_bin_alert',
      relatedEntityId: 'BIN-LGU-001',
      destination: const NotificationDestination(
        kind: NotificationDestinationKind.lguBin,
        entityId: 'BIN-LGU-001',
      ),
    ),
    NotificationModel(
      id: 'collector-1',
      title: 'Collection Assigned',
      message: 'You have a new assigned bin collection.',
      timestamp: DateTime(2026, 8, 12, 10, 5),
      isRead: false,
      role: UserRole.collector,
      type: 'new_assignment',
      relatedEntityId: 'REQ-DEMO-001',
      destination: const NotificationDestination(
        kind: NotificationDestinationKind.collectorAssignment,
        entityId: 'REQ-DEMO-001',
      ),
    ),
  ];

  /// Temporary mock notifications.
  ///
  /// Backend contract still needed:
  /// GET /api/notifications?role=:role
  /// PATCH /api/notifications/:id/read
  /// PATCH /api/notifications/read-all?role=:role
  Future<List<NotificationModel>> fetchNotifications(UserRole role) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    return _notifications
        .where((notification) => notification.role == role)
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  Future<int> unreadCount(UserRole role) async {
    final notifications = await fetchNotifications(role);
    return notifications.where((notification) => !notification.isRead).length;
  }

  Future<void> markAsRead(String notificationId) async {
    await Future<void>.delayed(const Duration(milliseconds: 120));
    for (var i = 0; i < _notifications.length; i++) {
      if (_notifications[i].id == notificationId) {
        _notifications[i] = _notifications[i].copyWith(isRead: true);
      }
    }
  }

  Future<void> markAllAsRead(UserRole role) async {
    await Future<void>.delayed(const Duration(milliseconds: 140));
    for (var i = 0; i < _notifications.length; i++) {
      if (_notifications[i].role == role) {
        _notifications[i] = _notifications[i].copyWith(isRead: true);
      }
    }
  }
}
