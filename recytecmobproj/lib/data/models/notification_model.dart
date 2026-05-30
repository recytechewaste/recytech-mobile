class NotificationModel {
  final String id;
  final String title;
  final String message;
  final String date;
  final bool isRead;

  NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.date,
    required this.isRead,
  });
}
