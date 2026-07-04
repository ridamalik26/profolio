import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/job_model.dart';
import '../models/notification_model.dart';
import '../services/gemini_job_service.dart';
import 'auth_provider.dart';
import 'notification_provider.dart';
import 'profile_provider.dart';
import 'settings_provider.dart';

// ── Service ──────────────────────────────────────────────────────────────────

final geminiJobServiceProvider = Provider<GeminiJobService>((_) => GeminiJobService());

// ── Tabs ─────────────────────────────────────────────────────────────────────

enum JobTab { recommended, latest, remote, fullTime, partTime, internship }

extension JobTabLabel on JobTab {
  String get label {
    switch (this) {
      case JobTab.recommended:
        return 'Recommended';
      case JobTab.latest:
        return 'Latest';
      case JobTab.remote:
        return 'Remote';
      case JobTab.fullTime:
        return 'Full-Time';
      case JobTab.partTime:
        return 'Part-Time';
      case JobTab.internship:
        return 'Internship';
    }
  }
}

// ── Filters ──────────────────────────────────────────────────────────────────

class JobFilters {
  final String searchQuery;
  final String? experienceLevel;
  final String? category;
  final double? minSalary;
  final double? maxSalary;

  const JobFilters({
    this.searchQuery = '',
    this.experienceLevel,
    this.category,
    this.minSalary,
    this.maxSalary,
  });

  bool get hasActiveFilters =>
      experienceLevel != null || category != null || minSalary != null || maxSalary != null;

  JobFilters copyWith({
    String? searchQuery,
    String? experienceLevel,
    String? category,
    double? minSalary,
    double? maxSalary,
  }) {
    return JobFilters(
      searchQuery: searchQuery ?? this.searchQuery,
      experienceLevel: experienceLevel ?? this.experienceLevel,
      category: category ?? this.category,
      minSalary: minSalary ?? this.minSalary,
      maxSalary: maxSalary ?? this.maxSalary,
    );
  }
}

class JobFiltersNotifier extends StateNotifier<JobFilters> {
  JobFiltersNotifier() : super(const JobFilters());

  void setSearchQuery(String query) => state = state.copyWith(searchQuery: query);

  void applyFilters({
    String? experienceLevel,
    String? category,
    double? minSalary,
    double? maxSalary,
  }) {
    state = JobFilters(
      searchQuery: state.searchQuery,
      experienceLevel: experienceLevel,
      category: category,
      minSalary: minSalary,
      maxSalary: maxSalary,
    );
  }

  void clearFilters() => state = JobFilters(searchQuery: state.searchQuery);
}

final jobFiltersProvider =
    StateNotifierProvider<JobFiltersNotifier, JobFilters>((_) => JobFiltersNotifier());

// ── Raw job pool ─────────────────────────────────────────────────────────────
//
// Fetched once per session (not autoDispose, so it survives navigating away
// from and back to the jobs screen) and cached in memory. Tab switches never
// trigger a new Gemini call — they only filter/sort this list locally. A new
// Gemini call only happens when the search query or filter sheet changes
// (jobFiltersProvider), or when the user pulls to refresh
// (ref.invalidate(jobsRawProvider)).

final jobsRawProvider = FutureProvider<List<JobModel>>((ref) async {
  final filters = ref.watch(jobFiltersProvider);
  final service = ref.watch(geminiJobServiceProvider);
  final profile = await ref.watch(profileProvider.future);

  return service.generateJobs(
    profile: profile,
    tabContext: 'All Jobs',
    searchQuery: filters.searchQuery,
    category: filters.category,
    experienceLevel: filters.experienceLevel,
    minSalary: filters.minSalary,
    maxSalary: filters.maxSalary,
    count: 30,
  );
});

// ── Jobs for a given tab (local filter/sort over the cached raw pool) ────────

final jobsForTabProvider =
    Provider.family.autoDispose<AsyncValue<List<JobModel>>, JobTab>((ref, tab) {
  final rawAsync = ref.watch(jobsRawProvider);

  return rawAsync.whenData((rawJobs) {
    final jobs = rawJobs.where((job) => _matchesTab(job, tab)).toList();

    if (tab == JobTab.recommended) {
      jobs.sort((a, b) => (b.matchScore ?? 0).compareTo(a.matchScore ?? 0));
    } else {
      jobs.sort((a, b) => (b.postedAt ?? DateTime(0)).compareTo(a.postedAt ?? DateTime(0)));
    }
    return jobs;
  });
});

bool _matchesTab(JobModel job, JobTab tab) {
  switch (tab) {
    case JobTab.remote:
      return job.isRemote;
    case JobTab.fullTime:
    case JobTab.partTime:
    case JobTab.internship:
      return job.jobType == _employmentTypeFor(tab);
    case JobTab.recommended:
    case JobTab.latest:
      return true;
  }
}

String? _employmentTypeFor(JobTab tab) {
  switch (tab) {
    case JobTab.fullTime:
      return 'Full-Time';
    case JobTab.partTime:
      return 'Part-Time';
    case JobTab.internship:
      return 'Internship';
    default:
      return null;
  }
}

// ── Job alert / recommendation notifications ────────────────────────────────
//
// Fires at most one "job_alert" (skill match) and one "recommendation"
// (high match score) notification per jobsRawProvider fetch — i.e. once per
// search/refresh, not per tab switch. Watch this provider once near app start
// (HomeScreen) so the listener is registered for the whole session.

final jobAlertWatcherProvider = Provider.autoDispose<void>((ref) {
  ref.listen<AsyncValue<List<JobModel>>>(jobsRawProvider, (_, next) async {
    final jobs = next.value;
    if (jobs == null || jobs.isEmpty) return;

    final uid = ref.read(authStateChangesProvider).value?.id;
    if (uid == null) return;

    final prefs = ref.read(accountSettingsProvider).value?.notificationPrefs;
    final skills = ref
            .read(profileProvider)
            .value
            ?.skills
            .map((s) => s.toLowerCase())
            .toSet() ??
        {};
    final notificationService = ref.read(notificationServiceProvider);

    if ((prefs?.jobAlerts ?? true) && skills.isNotEmpty) {
      for (final job in jobs) {
        final matchesSkill = job.requiredSkills
            .any((s) => skills.contains(s.toLowerCase()));
        if (matchesSkill) {
          await notificationService.notify(
            uid: uid,
            title: 'New job alert matching your skills',
            body: '${job.title} at ${job.company} looks like a fit for you.',
            type: NotificationType.jobAlert,
          );
          break;
        }
      }
    }

    if (prefs?.recommendations ?? true) {
      JobModel? best;
      for (final job in jobs) {
        if (job.matchScore == null) continue;
        if (best == null || job.matchScore! > (best.matchScore ?? 0)) best = job;
      }
      if (best != null && (best.matchScore ?? 0) >= 85) {
        await notificationService.notify(
          uid: uid,
          title: 'Recommended for you',
          body: '${best.title} at ${best.company} is a ${best.matchScore}% match.',
          type: NotificationType.recommendation,
        );
      }
    }

    ref.invalidate(notificationsProvider);
  });
});
