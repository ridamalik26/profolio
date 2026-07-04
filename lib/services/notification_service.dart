import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthException;
import '../core/exceptions/auth_exception.dart';
import '../models/notification_model.dart';

/// Persists notification history to Supabase and mirrors it as a local
/// (system tray) notification. Local notifications are a device-side echo of
/// the persisted row — they are not a delivery mechanism, so a failure to
/// show one never blocks persistence.
class NotificationService {
  final SupabaseClient _client;
  final FlutterLocalNotificationsPlugin _localPlugin;

  NotificationService({SupabaseClient? client, FlutterLocalNotificationsPlugin? localPlugin})
      : _client = client ?? Supabase.instance.client,
        _localPlugin = localPlugin ?? FlutterLocalNotificationsPlugin();

  static const String _table = 'notifications';
  static int _localIdCounter = 0;

  Future<void> initLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    await _localPlugin.initialize(
      const InitializationSettings(android: androidSettings, iOS: iosSettings),
    );
    await _localPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    await _localPlugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);
  }

  Future<void> _showLocal(String title, String body) async {
    const androidDetails = AndroidNotificationDetails(
      'profolio_general',
      'ProFolio Notifications',
      channelDescription: 'Job alerts, recommendations, and application status updates',
      importance: Importance.high,
      priority: Priority.high,
    );
    const details = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );
    try {
      await _localPlugin.show(_localIdCounter++, title, body, details);
    } catch (_) {
      // Non-fatal — the notification is still recorded in Supabase.
    }
  }

  Future<List<AppNotification>> getNotifications(String uid) async {
    final rows = await _client
        .from(_table)
        .select()
        .eq('user_id', uid)
        .order('created_at', ascending: false)
        .limit(50);
    return (rows as List<dynamic>)
        .map((r) => AppNotification.fromMap(r as Map<String, dynamic>))
        .toList();
  }

  /// Inserts a notification row and mirrors it as a local system notification.
  Future<void> notify({
    required String uid,
    required String title,
    required String body,
    required NotificationType type,
  }) async {
    try {
      await _client.from(_table).insert(
            AppNotification(
              id: '',
              title: title,
              body: body,
              type: type,
              isRead: false,
              createdAt: DateTime.now(),
            ).toInsertMap(userId: uid),
          );
    } catch (_) {
      // Non-fatal — job/status flows shouldn't fail because notification
      // logging failed.
      return;
    }
    await _showLocal(title, body);
  }

  Future<void> markAsRead(String notificationId) async {
    try {
      await _client.from(_table).update({'is_read': true}).eq('id', notificationId);
    } catch (e) {
      throw AuthException('Failed to update notification: $e');
    }
  }

  Future<void> markAllAsRead(String uid) async {
    try {
      await _client
          .from(_table)
          .update({'is_read': true})
          .eq('user_id', uid)
          .eq('is_read', false);
    } catch (e) {
      throw AuthException('Failed to update notifications: $e');
    }
  }
}
