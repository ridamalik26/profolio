class NotificationPrefs {
  final bool jobAlerts;
  final bool statusUpdates;
  final bool recommendations;

  const NotificationPrefs({
    this.jobAlerts = true,
    this.statusUpdates = true,
    this.recommendations = true,
  });

  factory NotificationPrefs.fromMap(Map<String, dynamic>? map) {
    if (map == null) return const NotificationPrefs();
    return NotificationPrefs(
      jobAlerts: map['job_alerts'] as bool? ?? true,
      statusUpdates: map['status_updates'] as bool? ?? true,
      recommendations: map['recommendations'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toMap() => {
        'job_alerts': jobAlerts,
        'status_updates': statusUpdates,
        'recommendations': recommendations,
      };

  NotificationPrefs copyWith({
    bool? jobAlerts,
    bool? statusUpdates,
    bool? recommendations,
  }) {
    return NotificationPrefs(
      jobAlerts: jobAlerts ?? this.jobAlerts,
      statusUpdates: statusUpdates ?? this.statusUpdates,
      recommendations: recommendations ?? this.recommendations,
    );
  }
}

class AccountSettings {
  final NotificationPrefs notificationPrefs;
  final bool isPublic;

  const AccountSettings({
    required this.notificationPrefs,
    required this.isPublic,
  });

  factory AccountSettings.fromMap(Map<String, dynamic> map) {
    return AccountSettings(
      notificationPrefs: NotificationPrefs.fromMap(
        map['notification_prefs'] as Map<String, dynamic>?,
      ),
      isPublic: map['is_public'] as bool? ?? true,
    );
  }
}
