import 'package:supabase_flutter/supabase_flutter.dart' hide AuthException;
import '../core/exceptions/auth_exception.dart';
import '../models/settings_model.dart';

class SettingsService {
  final SupabaseClient _client;

  SettingsService({SupabaseClient? client}) : _client = client ?? Supabase.instance.client;

  static const String _table = 'users';

  Future<AccountSettings> getSettings(String uid) async {
    final row = await _client
        .from(_table)
        .select('notification_prefs, is_public')
        .eq('id', uid)
        .maybeSingle();
    if (row == null) {
      return const AccountSettings(
        notificationPrefs: NotificationPrefs(),
        isPublic: true,
      );
    }
    return AccountSettings.fromMap(row);
  }

  Future<void> updateNotificationPrefs(String uid, NotificationPrefs prefs) async {
    try {
      await _client
          .from(_table)
          .update({'notification_prefs': prefs.toMap()}).eq('id', uid);
    } catch (e) {
      throw AuthException('Failed to save notification preferences: $e');
    }
  }

  Future<void> updateAccountVisibility(String uid, bool isPublic) async {
    try {
      await _client.from(_table).update({'is_public': isPublic}).eq('id', uid);
    } catch (e) {
      throw AuthException('Failed to save privacy setting: $e');
    }
  }

  Future<void> updatePassword(String newPassword) async {
    try {
      await _client.auth.updateUser(UserAttributes(password: newPassword));
    } catch (e) {
      throw AuthException('Failed to change password: $e');
    }
  }
}
