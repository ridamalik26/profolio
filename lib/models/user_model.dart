import 'package:supabase_flutter/supabase_flutter.dart';

class UserModel {
  final String uid;
  final String email;
  final String? displayName;
  final String? photoURL;
  final bool emailVerified;

  const UserModel({
    required this.uid,
    required this.email,
    this.displayName,
    this.photoURL,
    this.emailVerified = false,
  });

  factory UserModel.fromSupabaseUser(User user) {
    final metadata = user.userMetadata ?? {};
    return UserModel(
      uid: user.id,
      email: user.email ?? '',
      displayName: metadata['display_name'] as String?,
      photoURL: metadata['avatar_url'] as String?,
      emailVerified: user.emailConfirmedAt != null,
    );
  }

  String get firstName {
    if (displayName == null || displayName!.isEmpty) return '';
    return displayName!.split(' ').first;
  }

  UserModel copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? photoURL,
    bool? emailVerified,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoURL: photoURL ?? this.photoURL,
      emailVerified: emailVerified ?? this.emailVerified,
    );
  }
}
