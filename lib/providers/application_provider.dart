import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/application_model.dart';
import '../models/job_model.dart';
import '../models/saved_job_model.dart';
import '../services/application_service.dart';
import 'auth_provider.dart';

final applicationServiceProvider =
    Provider<ApplicationService>((_) => ApplicationService());

// ── Applications list ────────────────────────────────────────────────────────

final applicationsProvider =
    FutureProvider.autoDispose<List<ApplicationModel>>((ref) async {
  final uid = ref.watch(authStateChangesProvider).value?.id;
  if (uid == null) return [];
  return ref.watch(applicationServiceProvider).getApplications(uid);
});

// ── Saved jobs list ──────────────────────────────────────────────────────────

final savedJobsProvider =
    FutureProvider.autoDispose<List<SavedJobModel>>((ref) async {
  final uid = ref.watch(authStateChangesProvider).value?.id;
  if (uid == null) return [];
  return ref.watch(applicationServiceProvider).getSavedJobs(uid);
});

// ── Save / unsave toggle ─────────────────────────────────────────────────────

class SaveJobNotifier extends StateNotifier<Set<String>> {
  SaveJobNotifier(this._ref) : super({});

  final Ref _ref;

  Future<void> toggle(JobModel job) async {
    final uid = _ref.read(authStateChangesProvider).value?.id;
    if (uid == null) return;
    final service = _ref.read(applicationServiceProvider);

    final alreadySaved = await service.isSaved(uid, job.id);
    if (alreadySaved) {
      await service.unsaveJob(uid, job.id);
    } else {
      await service.saveJob(
        SavedJobModel(
          id: '',
          jobId: job.id,
          jobTitle: job.title,
          companyName: job.company,
          jobUrl: job.applyLink,
          location: job.location,
          jobType: job.employmentTypeLabel,
          salary: job.salaryLabel,
          matchScore: job.matchScore,
          savedAt: DateTime.now(),
        ),
        uid,
      );
    }
    _ref.invalidate(savedJobsProvider);
  }
}

final saveJobNotifierProvider =
    StateNotifierProvider<SaveJobNotifier, Set<String>>((ref) => SaveJobNotifier(ref));

// ── Apply flow ───────────────────────────────────────────────────────────────

class ApplyState {
  final bool isLoading;
  final bool isSubmitted;
  final String? error;

  const ApplyState({this.isLoading = false, this.isSubmitted = false, this.error});

  ApplyState copyWith({bool? isLoading, bool? isSubmitted, String? error, bool clearError = false}) {
    return ApplyState(
      isLoading: isLoading ?? this.isLoading,
      isSubmitted: isSubmitted ?? this.isSubmitted,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class ApplyNotifier extends StateNotifier<ApplyState> {
  ApplyNotifier(this._ref) : super(const ApplyState());

  final Ref _ref;

  Future<bool> submit({
    required JobModel job,
    required String name,
    required String email,
    required String phone,
    String? resumeUrl,
  }) async {
    final uid = _ref.read(authStateChangesProvider).value?.id;
    if (uid == null) return false;

    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final service = _ref.read(applicationServiceProvider);
      await service.submitApplication(
        ApplicationModel(
          id: '',
          jobId: job.id,
          jobTitle: job.title,
          companyName: job.company,
          jobUrl: job.applyLink,
          location: job.location,
          jobType: job.employmentTypeLabel,
          salary: job.salaryLabel,
          matchScore: job.matchScore,
          status: ApplicationStatus.applied,
          applicantName: name,
          applicantEmail: email,
          applicantPhone: phone,
          resumeUrl: resumeUrl,
          appliedAt: DateTime.now(),
        ),
        uid,
      );
      _ref.invalidate(applicationsProvider);
      state = state.copyWith(isLoading: false, isSubmitted: true);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }
}

final applyNotifierProvider =
    StateNotifierProvider.autoDispose<ApplyNotifier, ApplyState>((ref) => ApplyNotifier(ref));
