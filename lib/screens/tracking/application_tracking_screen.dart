import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../models/application_model.dart';
import '../../models/notification_model.dart';
import '../../providers/application_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/notification_provider.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/shimmer_box.dart';
import 'widgets/application_card.dart';

class ApplicationTrackingScreen extends StatelessWidget {
  const ApplicationTrackingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 5,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          title: Text('My Applications', style: Theme.of(context).textTheme.titleLarge),
          bottom: TabBar(
            isScrollable: true,
            labelColor: AppColors.bronze,
            unselectedLabelColor: AppColors.textSecondary,
            indicatorColor: AppColors.bronze,
            labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            tabs: const [
              Tab(text: 'Applied'),
              Tab(text: 'Pending'),
              Tab(text: 'Accepted'),
              Tab(text: 'Rejected'),
              Tab(text: 'Saved Jobs'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _ApplicationsList(status: ApplicationStatus.applied),
            _ApplicationsList(status: ApplicationStatus.pending),
            _ApplicationsList(status: ApplicationStatus.accepted),
            _ApplicationsList(status: ApplicationStatus.rejected),
            _SavedJobsList(),
          ],
        ),
      ),
    );
  }
}

class _ApplicationsList extends ConsumerWidget {
  final ApplicationStatus status;
  const _ApplicationsList({required this.status});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final applicationsAsync = ref.watch(applicationsProvider);

    return applicationsAsync.when(
      loading: () => const ShimmerCardList(itemCount: 4, itemHeight: 110),
      error: (e, _) => _ErrorState(
        message: 'Could not load applications. Please try again.',
        onRetry: () => ref.invalidate(applicationsProvider),
      ),
      data: (applications) {
        final filtered = applications.where((a) => a.status == status).toList();
        if (filtered.isEmpty) {
          return _EmptyState(message: 'No ${status.name} applications yet.');
        }
        return RefreshIndicator(
          color: AppColors.bronze,
          onRefresh: () async => ref.invalidate(applicationsProvider),
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: filtered.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (_, i) {
              final app = filtered[i];
              return ApplicationCard(
                application: app,
                onStatusChanged: (newStatus) async {
                  await ref
                      .read(applicationServiceProvider)
                      .updateStatus(app.id, newStatus);
                  ref.invalidate(applicationsProvider);

                  final uid = ref.read(authStateChangesProvider).value?.id;
                  final wantsStatusUpdates =
                      ref.read(accountSettingsProvider).value?.notificationPrefs.statusUpdates ??
                          true;
                  if (uid != null && wantsStatusUpdates) {
                    await ref.read(notificationServiceProvider).notify(
                          uid: uid,
                          title: 'Application status updated',
                          body:
                              'Your application for ${app.jobTitle} at ${app.companyName} is now ${newStatus.name}.',
                          type: NotificationType.statusUpdate,
                        );
                    ref.invalidate(notificationsProvider);
                  }
                },
              );
            },
          ),
        );
      },
    );
  }
}

class _SavedJobsList extends ConsumerWidget {
  const _SavedJobsList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final savedAsync = ref.watch(savedJobsProvider);

    return savedAsync.when(
      loading: () => const ShimmerCardList(itemCount: 4, itemHeight: 90),
      error: (e, _) => _ErrorState(
        message: 'Could not load saved jobs. Please try again.',
        onRetry: () => ref.invalidate(savedJobsProvider),
      ),
      data: (saved) {
        if (saved.isEmpty) {
          return const _EmptyState(message: 'No saved jobs yet.');
        }
        return RefreshIndicator(
          color: AppColors.bronze,
          onRefresh: () async => ref.invalidate(savedJobsProvider),
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: saved.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (_, i) {
              final job = saved[i];
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(job.jobTitle, style: Theme.of(context).textTheme.titleMedium),
                          const SizedBox(height: 2),
                          Text(job.companyName, style: Theme.of(context).textTheme.bodySmall),
                          if (job.matchScore != null) ...[
                            const SizedBox(height: 6),
                            Text(
                              '${job.matchScore}% match',
                              style: const TextStyle(color: AppColors.bronze, fontSize: 12),
                            ),
                          ],
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.bookmark_remove_outlined, color: AppColors.error),
                      onPressed: () async {
                        final uid = ref.read(authStateChangesProvider).value?.id;
                        if (uid == null) return;
                        await ref
                            .read(applicationServiceProvider)
                            .unsaveJob(uid, job.jobId);
                        ref.invalidate(savedJobsProvider);
                      },
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: AppColors.error, size: 32),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            TextButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String message;
  const _EmptyState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.inbox_outlined, color: AppColors.textSecondary, size: 36),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
