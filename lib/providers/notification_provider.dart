import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/notification_model.dart';
import '../services/notification_service.dart';
import 'auth_provider.dart';

final notificationServiceProvider =
    Provider<NotificationService>((_) => NotificationService());

// Kept alive for the app session so the bell badge and notification center
// share one fetch — same caching approach as jobsRawProvider.
final notificationsProvider = FutureProvider<List<AppNotification>>((ref) async {
  final uid = ref.watch(authStateChangesProvider).value?.id;
  if (uid == null) return [];
  return ref.watch(notificationServiceProvider).getNotifications(uid);
});

final unreadNotificationCountProvider = Provider<int>((ref) {
  return ref.watch(notificationsProvider).value?.where((n) => !n.isRead).length ?? 0;
});

class NotificationActions {
  NotificationActions(this._ref);
  final Ref _ref;

  Future<void> markAsRead(String notificationId) async {
    await _ref.read(notificationServiceProvider).markAsRead(notificationId);
    _ref.invalidate(notificationsProvider);
  }

  Future<void> markAllAsRead() async {
    final uid = _ref.read(authStateChangesProvider).value?.id;
    if (uid == null) return;
    await _ref.read(notificationServiceProvider).markAllAsRead(uid);
    _ref.invalidate(notificationsProvider);
  }
}

final notificationActionsProvider = Provider((ref) => NotificationActions(ref));
