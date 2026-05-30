import '../models/notification_model.dart';

class NotificationRepository {
  Future<List<NotificationModel>> fetchNotifications() async {
    return [
      NotificationModel(
        id: 'notif-1',
        title: 'Pickup Assigned',
        message: 'You have a new pickup assignment.',
        date: 'Feb 2, 2026',
        isRead: false,
      ),
    ];
  }

  Future<void> markAsRead(String notificationId) async {
    // mock only
  }
}
