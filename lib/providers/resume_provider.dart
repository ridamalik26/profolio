import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/resume_model.dart';
import '../services/profile_service.dart';
import 'profile_provider.dart';

// ── Constants ─────────────────────────────────────────────────────────────────

const int kMaxResumeSizeBytes = 5 * 1024 * 1024; // 5 MB

const Map<String, String> kAllowedMimeTypes = {
  'pdf': 'application/pdf',
  'docx': 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
};

// ── State ─────────────────────────────────────────────────────────────────────

class ResumeState {
  final bool isUploading;
  final bool isDeleting;
  final double uploadProgress; // 0.0 – 1.0
  final String? error;
  final String? successMessage;

  const ResumeState({
    this.isUploading = false,
    this.isDeleting = false,
    this.uploadProgress = 0.0,
    this.error,
    this.successMessage,
  });

  bool get isBusy => isUploading || isDeleting;

  ResumeState copyWith({
    bool? isUploading,
    bool? isDeleting,
    double? uploadProgress,
    String? error,
    String? successMessage,
    bool clearError = false,
    bool clearSuccess = false,
  }) {
    return ResumeState(
      isUploading: isUploading ?? this.isUploading,
      isDeleting: isDeleting ?? this.isDeleting,
      uploadProgress: uploadProgress ?? this.uploadProgress,
      error: clearError ? null : (error ?? this.error),
      successMessage: clearSuccess ? null : (successMessage ?? this.successMessage),
    );
  }
}

// ── Notifier ──────────────────────────────────────────────────────────────────

class ResumeNotifier extends StateNotifier<ResumeState> {
  ResumeNotifier(this._service, this._ref) : super(const ResumeState());

  final ProfileService _service;
  final Ref _ref;

  // ── Pick file ─────────────────────────────────────────────────────────────

  /// Returns a validated [PlatformFile] or sets an error and returns null.
  Future<PlatformFile?> pickResumeFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'docx'],
        withData: true, // load bytes — needed for cross-platform upload
      );
      if (result == null || result.files.isEmpty) return null;

      final file = result.files.first;
      return _validate(file);
    } catch (e) {
      state = state.copyWith(
        error: 'Could not open file picker. Please try again.',
      );
      return null;
    }
  }

  PlatformFile? _validate(PlatformFile file) {
    final ext = (file.extension ?? '').toLowerCase();

    if (!kAllowedMimeTypes.containsKey(ext)) {
      state = state.copyWith(
        error: 'Only PDF and DOCX files are supported.',
      );
      return null;
    }

    if (file.size > kMaxResumeSizeBytes) {
      state = state.copyWith(
        error: 'File is too large. Maximum allowed size is 5 MB.',
      );
      return null;
    }

    if (file.bytes == null) {
      state = state.copyWith(
        error: 'Could not read the file. Please try again.',
      );
      return null;
    }

    return file;
  }

  // ── Upload ────────────────────────────────────────────────────────────────

  Future<void> upload({
    required String uid,
    required PlatformFile file,
  }) async {
    final ext = (file.extension ?? 'pdf').toLowerCase();
    final contentType = kAllowedMimeTypes[ext] ?? 'application/pdf';

    state = state.copyWith(
      isUploading: true,
      uploadProgress: 0.0,
      clearError: true,
      clearSuccess: true,
    );

    try {
      final storagePath = await _service.uploadResumeBytes(
        uid: uid,
        bytes: file.bytes!,
        contentType: contentType,
        onProgress: (p) {
          if (mounted) state = state.copyWith(uploadProgress: p);
        },
      );

      final resume = ResumeModel(
        storagePath: storagePath,
        fileName: file.name,
        uploadDate: DateTime.now().toUtc().toIso8601String(),
        fileSizeBytes: file.size,
        contentType: contentType,
      );

      await _service.saveResumeMetadata(uid, resume);
      _ref.invalidate(profileProvider);

      state = state.copyWith(
        isUploading: false,
        uploadProgress: 1.0,
        successMessage: 'Resume uploaded successfully!',
      );
    } catch (e) {
      state = state.copyWith(
        isUploading: false,
        uploadProgress: 0.0,
        error: e.toString(),
      );
    }
  }

  /// Replace: delete old Storage file first, then upload new one.
  Future<void> replace({
    required String uid,
    required PlatformFile newFile,
  }) async {
    // Delete the existing Storage object (best-effort; don't block replace)
    try {
      await _service.deleteResumeFile(uid);
    } catch (_) {}

    await upload(uid: uid, file: newFile);
  }

  // ── Delete ────────────────────────────────────────────────────────────────

  Future<void> delete({required String uid}) async {
    state = state.copyWith(isDeleting: true, clearError: true, clearSuccess: true);
    try {
      await _service.deleteResumeFile(uid);
      await _service.clearResumeMetadata(uid);
      _ref.invalidate(profileProvider);
      state = state.copyWith(
        isDeleting: false,
        successMessage: 'Resume deleted.',
      );
    } catch (e) {
      state = state.copyWith(isDeleting: false, error: e.toString());
    }
  }

  // ── View ──────────────────────────────────────────────────────────────────

  /// Resolves a short-lived signed URL for viewing/downloading the resume,
  /// or sets an error and returns null.
  Future<String?> getViewUrl(String storagePath) async {
    try {
      return await _service.createResumeSignedUrl(storagePath);
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return null;
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  void clearError() => state = state.copyWith(clearError: true);
  void clearSuccess() => state = state.copyWith(clearSuccess: true);
}

final resumeProvider =
    StateNotifierProvider.autoDispose<ResumeNotifier, ResumeState>((ref) {
  return ResumeNotifier(ref.watch(profileServiceProvider), ref);
});
