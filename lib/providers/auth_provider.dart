import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show User;
import '../models/profile_model.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/profile_service.dart';

// ── Service providers ─────────────────────────────────────────────────────────

final authServiceProvider = Provider<AuthService>((ref) => AuthService());

// ── Reactive auth state (stream from Supabase) ────────────────────────────────

final authStateChangesProvider = StreamProvider<User?>((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});

final currentUserProvider = Provider<UserModel?>((ref) {
  return ref.watch(authServiceProvider).currentUser;
});

// ── Auth action state ─────────────────────────────────────────────────────────

class AuthState {
  final bool isLoading;
  final String? error;
  final String? successMessage;

  const AuthState({
    this.isLoading = false,
    this.error,
    this.successMessage,
  });

  AuthState copyWith({
    bool? isLoading,
    String? error,
    String? successMessage,
    bool clearError = false,
    bool clearSuccess = false,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      successMessage: clearSuccess ? null : (successMessage ?? this.successMessage),
    );
  }

  bool get hasError => error != null;
  bool get hasSuccess => successMessage != null;
}

// ── Auth notifier ─────────────────────────────────────────────────────────────

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier(this._authService, this._profileService)
      : super(const AuthState());

  final AuthService _authService;
  final ProfileService _profileService;

  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true, clearSuccess: true);
    try {
      await _authService.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      state = const AuthState();
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> register({
    required String email,
    required String password,
    required String displayName,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true, clearSuccess: true);
    try {
      final user = await _authService.createUserWithEmailAndPassword(
        email: email,
        password: password,
        displayName: displayName,
      );

      // Eagerly create a minimal Supabase profile row so the stream
      // never returns null for a freshly-registered user.
      try {
        await _profileService.saveProfile(
          ProfileModel(
            uid: user.uid,
            fullName: displayName.trim(),
            email: email.trim(),
          ),
        );
      } catch (_) {
        // Non-fatal: user is still registered; they can complete profile later.
      }

      state = const AuthState();
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> sendPasswordReset({required String email}) async {
    state = state.copyWith(isLoading: true, clearError: true, clearSuccess: true);
    try {
      await _authService.sendPasswordResetEmail(email: email);
      state = state.copyWith(
        isLoading: false,
        successMessage: 'Password reset email sent. Check your inbox.',
      );
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<void> signOut() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _authService.signOut();
      state = const AuthState();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void clearError() => state = state.copyWith(clearError: true);
  void clearSuccess() => state = state.copyWith(clearSuccess: true);
}

final authNotifierProvider =
    StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(
    ref.watch(authServiceProvider),
    ref.watch(_profileServiceForAuthProvider),
  );
});

// Separate provider so auth doesn't import the public profileServiceProvider
// (avoiding circular imports since profile_provider imports auth_provider).
final _profileServiceForAuthProvider =
    Provider<ProfileService>((_) => ProfileService());
