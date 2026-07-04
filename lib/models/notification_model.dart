enum NotificationType { jobAlert, statusUpdate, recommendation }

extension NotificationTypeMapping on NotificationType {
  String get value {
    switch (this) {
      case NotificationType.jobAlert:
        return 'job_alert';
      case NotificationType.statusUpdate:
        return 'status_update';
      case NotificationType.recommendation:
        return 'recommendation';
    }
  }
}

NotificationType _typeFromString(String raw) {
  switch (raw) {
    case 'status_update':
      return NotificationType.statusUpdate;
    case 'recommendation':
      return NotificationType.recommendation;
    default:
      return NotificationType.jobAlert;
  }
}

class AppNotification {
  final String id;
  final String title;
  final String body;
  final NotificationType type;
  final bool isRead;
  final DateTime createdAt;

  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.isRead,
    required this.createdAt,
  });

  factory AppNotification.fromMap(Map<String, dynamic> map) {
    return AppNotification(
      id: map['id'] as String,
      title: map['title'] as String? ?? '',
      body: map['body'] as String? ?? '',
      type: _typeFromString(map['type'] as String? ?? 'job_alert'),
      isRead: map['is_read'] as bool? ?? false,
      createdAt: DateTime.parse(map['created_at'] as String).toLocal(),
    );
  }

  Map<String, dynamic> toInsertMap({required String userId}) => {
        'user_id': userId,
        'title': title,
        'body': body,
        'type': type.value,
      };

  AppNotification copyWith({bool? isRead}) => AppNotification(
        id: id,
        title: title,
        body: body,
        type: type,
        isRead: isRead ?? this.isRead,
        createdAt: createdAt,
      );
}
