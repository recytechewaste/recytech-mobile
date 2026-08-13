import '../../core/constants/app_constants.dart';

class NotificationModel {
  const NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.timestamp,
    required this.isRead,
    required this.role,
    required this.type,
    this.relatedEntityId,
    this.destination,
  });

  final String id;
  final String title;
  final String message;
  final DateTime timestamp;
  final bool isRead;
  final UserRole role;
  final String type;
  final String? relatedEntityId;
  final NotificationDestination? destination;

  NotificationModel copyWith({bool? isRead}) {
    return NotificationModel(
      id: id,
      title: title,
      message: message,
      timestamp: timestamp,
      isRead: isRead ?? this.isRead,
      role: role,
      type: type,
      relatedEntityId: relatedEntityId,
      destination: destination,
    );
  }
}

class NotificationDestination {
  const NotificationDestination({
    required this.kind,
    this.entityId,
  });

  final NotificationDestinationKind kind;
  final String? entityId;
}

enum NotificationDestinationKind {
  householdRequest,
  lguRequest,
  lguBin,
  collectorAssignment,
}
