import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/settings_model.dart';
import '../services/settings_service.dart';
import 'auth_provider.dart';

final settingsServiceProvider = Provider<SettingsService>((_) => SettingsService());

final accountSettingsProvider = FutureProvider.autoDispose<AccountSettings>((ref) async {
  final uid = ref.watch(authStateChangesProvider).value?.id;
  if (uid == null) {
    return const AccountSettings(notificationPrefs: NotificationPrefs(), isPublic: true);
  }
  return ref.watch(settingsServiceProvider).getSettings(uid);
});

class SettingsActionsState {
  final bool isLoading;
  final String? error;
  final String? successMessage;

  const SettingsActionsState({this.isLoading = false, this.error, this.successMessage});

  SettingsActionsState copyWith({
    bool? isLoading,
    String? error,
    String? successMessage,
    bool clearError = false,
    bool clearSuccess = false,
  }) {
    return SettingsActionsState(
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      successMessage: clearSuccess ? null : (successMessage ?? this.successMessage),
    );
  }
}

class SettingsActionsNotifier extends StateNotifier<SettingsActionsState> {
  SettingsActionsNotifier(this._ref) : super(const SettingsActionsState());

  final Ref _ref;

  Future<bool> updateNotificationPrefs(NotificationPrefs prefs) async {
    final uid = _ref.read(authStateChangesProvider).value?.id;
    if (uid == null) return false;
    try {
      await _ref.read(settingsServiceProvider).updateNotificationPrefs(uid, prefs);
      _ref.invalidate(accountSettingsProvider);
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<bool> updateAccountVisibility(bool isPublic) async {
    final uid = _ref.read(authStateChangesProvider).value?.id;
    if (uid == null) return false;
    try {
      await _ref.read(settingsServiceProvider).updateAccountVisibility(uid, isPublic);
      _ref.invalidate(accountSettingsProvider);
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<bool> changePassword(String newPassword) async {
    state = state.copyWith(isLoading: true, clearError: true, clearSuccess: true);
    try {
      await _ref.read(settingsServiceProvider).updatePassword(newPassword);
      state = state.copyWith(
        isLoading: false,
        successMessage: 'Password updated successfully.',
      );
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  void clearMessages() => state = state.copyWith(clearError: true, clearSuccess: true);
}

final settingsActionsProvider =
    StateNotifierProvider.autoDispose<SettingsActionsNotifier, SettingsActionsState>(
        (ref) => SettingsActionsNotifier(ref));
