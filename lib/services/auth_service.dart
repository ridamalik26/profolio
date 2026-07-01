import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthException;
import '../core/exceptions/auth_exception.dart';
import '../models/user_model.dart';

class AuthService {
  final SupabaseClient _client;

  AuthService({SupabaseClient? client}) : _client = client ?? Supabase.instance.client;

  // Without a timeout, a stalled connection (VPN/proxy/firewall/DNS issue
  // reaching the Supabase host) leaves signIn/signUp hanging forever with no
  // error and no navigation — indistinguishable from the UI "doing nothing".
  static const _networkTimeout = Duration(seconds: 15);

  Future<T> _withTimeout<T>(Future<T> future) {
    return future.timeout(
      _networkTimeout,
      onTimeout: () => throw const AuthException(
          'The request timed out. Check your internet connection and try again.'),
    );
  }

  Stream<User?> get authStateChanges =>
      _client.auth.onAuthStateChange.map((event) => event.session?.user);

  User? get currentSupabaseUser => _client.auth.currentUser;

  UserModel? get currentUser {
    final user = _client.auth.currentUser;
    return user != null ? UserModel.fromSupabaseUser(user) : null;
  }

  Future<UserModel> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _withTimeout(_client.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      ));
      if (response.user == null) {
        throw const AuthException('Incorrect email or password. Please try again.');
      }
      return UserModel.fromSupabaseUser(response.user!);
    } on AuthException {
      rethrow;
    } on AuthApiException catch (e) {
      throw AuthException(_mapSupabaseError(e), code: e.code);
    } catch (_) {
      throw const AuthException('An unexpected error occurred. Please try again.');
    }
  }

  Future<UserModel> createUserWithEmailAndPassword({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      final response = await _withTimeout(_client.auth.signUp(
        email: email.trim(),
        password: password,
        data: {'display_name': displayName.trim()},
      ));
      if (response.user == null) {
        throw const AuthException('Could not create account. Please try again.');
      }
      return UserModel.fromSupabaseUser(response.user!);
    } on AuthException {
      rethrow;
    } on AuthApiException catch (e) {
      throw AuthException(_mapSupabaseError(e), code: e.code);
    } catch (_) {
      throw const AuthException('An unexpected error occurred. Please try again.');
    }
  }

  Future<void> sendPasswordResetEmail({required String email}) async {
    try {
      await _withTimeout(_client.auth.resetPasswordForEmail(email.trim()));
    } on AuthApiException catch (e) {
      throw AuthException(_mapSupabaseError(e), code: e.code);
    } catch (_) {
      throw const AuthException('Failed to send reset email. Please try again.');
    }
  }

  Future<void> signOut() async {
    try {
      await _withTimeout(_client.auth.signOut());
    } on AuthException {
      rethrow;
    } catch (_) {
      throw const AuthException('Failed to sign out. Please try again.');
    }
  }

  String _mapSupabaseError(AuthApiException e) {
    switch (e.code) {
      case 'email_provider_disabled':
        return 'Email sign-up is currently disabled for this app. Please contact support.';
      case 'signup_disabled':
        return 'New sign-ups are currently disabled. Please contact support.';
      case 'user_already_exists':
      case 'email_exists':
        return 'An account with this email already exists.';
      case 'weak_password':
        return 'Password is too weak. Use at least 8 characters with letters and numbers.';
      case 'email_not_confirmed':
        return 'Please confirm your email before signing in.';
      case 'invalid_credentials':
        return 'Incorrect email or password. Please try again.';
      case 'over_request_rate_limit':
      case 'over_email_send_rate_limit':
        return 'Too many attempts. Please try again later.';
      case 'validation_failed':
        return 'Please enter a valid email address.';
    }

    final message = e.message.toLowerCase();
    if (message.contains('invalid login credentials')) {
      return 'Incorrect email or password. Please try again.';
    }
    if (message.contains('email not confirmed')) {
      return 'Please confirm your email before signing in.';
    }
    if (message.contains('user already registered') ||
        message.contains('already registered')) {
      return 'An account with this email already exists.';
    }
    if (message.contains('password should be at least') ||
        message.contains('weak password')) {
      return 'Password is too weak. Use at least 8 characters with letters and numbers.';
    }
    if (message.contains('invalid email')) {
      return 'Please enter a valid email address.';
    }
    if (message.contains('rate limit') || message.contains('too many requests')) {
      return 'Too many attempts. Please try again later.';
    }
    if (message.contains('network')) {
      return 'Network error. Please check your connection.';
    }

    // Unrecognized error: surface the real message in debug builds instead of
    // hiding it behind a generic message, so misconfigurations (like a
    // disabled auth provider) aren't mistaken for app bugs.
    if (kDebugMode) {
      return 'Something went wrong (${e.code ?? e.statusCode}): ${e.message}';
    }
    return 'Something went wrong. Please try again.';
  }
}
