import 'dart:io';
import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthException;
import '../core/exceptions/auth_exception.dart';
import '../models/profile_model.dart';
import '../models/resume_model.dart';

class ProfileService {
  final SupabaseClient _client;

  ProfileService({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  static const String _table = 'users';
  static const String _avatarsBucket = 'avatars';
  static const String _resumesBucket = 'resumes';

  // ── Profile ───────────────────────────────────────────────────────────────

  Future<ProfileModel?> getProfile(String uid) async {
    final row = await _client
        .from(_table)
        .select()
        .eq('id', uid)
        .maybeSingle();
    if (row == null) return null;
    return ProfileModel.fromMap(row);
  }

  Future<void> saveProfile(ProfileModel profile) async {
    try {
      await _client.from(_table).upsert(profile.toMap());
    } catch (e) {
      throw const AuthException('Failed to save profile. Please try again.');
    }
  }

  // ── Profile photo ─────────────────────────────────────────────────────────

  Future<String> uploadProfilePhoto(String uid, File file) async {
    try {
      final path = '$uid/avatar.jpg';
      await _client.storage.from(_avatarsBucket).upload(
            path,
            file,
            fileOptions: const FileOptions(
              contentType: 'image/jpeg',
              upsert: true,
            ),
          );
      return _client.storage.from(_avatarsBucket).getPublicUrl(path);
    } catch (e) {
      throw const AuthException('Failed to upload photo. Please try again.');
    }
  }

  Future<void> deleteProfilePhoto(String uid) async {
    try {
      await _client.storage.from(_avatarsBucket).remove(['$uid/avatar.jpg']);
    } catch (_) {
      // Ignore — file may not exist
    }
  }

  // ── Resume ────────────────────────────────────────────────────────────────

  /// Uploads [bytes] to the private `resumes` bucket and returns the storage
  /// path (not a public URL — the bucket is private, see [createResumeSignedUrl]).
  /// Reports fractional progress (0.0–1.0) via [onProgress].
  Future<String> uploadResumeBytes({
    required String uid,
    required List<int> bytes,
    required String contentType,
    void Function(double)? onProgress,
  }) async {
    try {
      final ext = contentType == 'application/pdf' ? 'pdf' : 'docx';
      final path = '$uid/resume.$ext';

      onProgress?.call(0.0);
      await _client.storage.from(_resumesBucket).uploadBinary(
            path,
            Uint8List.fromList(bytes),
            fileOptions: FileOptions(contentType: contentType, upsert: true),
          );
      onProgress?.call(1.0);

      return path;
    } catch (e) {
      throw const AuthException('Failed to upload resume. Please try again.');
    }
  }

  /// Creates a time-limited signed URL for viewing/downloading the resume at
  /// [path] in the private `resumes` bucket.
  Future<String> createResumeSignedUrl(String path, {int expiresInSeconds = 120}) async {
    try {
      return await _client.storage
          .from(_resumesBucket)
          .createSignedUrl(path, expiresInSeconds);
    } catch (e) {
      throw const AuthException('Failed to open resume. Please try again.');
    }
  }

  /// Deletes the resume file from Storage. Tries both known extensions
  /// since the stored extension isn't known at delete time.
  Future<void> deleteResumeFile(String uid) async {
    try {
      await _client.storage
          .from(_resumesBucket)
          .remove(['$uid/resume.pdf', '$uid/resume.docx']);
    } catch (_) {
      // Ignore — file may not exist yet
    }
  }

  /// Persists resume metadata fields onto the user's row.
  Future<void> saveResumeMetadata(String uid, ResumeModel resume) async {
    try {
      await _client.from(_table).update(resume.toMap()).eq('id', uid);
    } catch (e) {
      throw const AuthException('Failed to save resume info. Please try again.');
    }
  }

  /// Removes all resume fields from the user's row.
  Future<void> clearResumeMetadata(String uid) async {
    try {
      await _client.from(_table).update({
        'resume_url': null,
        'resume_filename': null,
        'resume_uploaded_at': null,
        'resume_file_size_bytes': null,
        'resume_content_type': null,
      }).eq('id', uid);
    } catch (e) {
      throw const AuthException('Failed to remove resume. Please try again.');
    }
  }
}
