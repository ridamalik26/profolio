import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/job_provider.dart';
import 'job_details_screen.dart';
import 'widgets/filter_sheet.dart';
import 'widgets/job_card.dart';

class JobsScreen extends ConsumerStatefulWidget {
  const JobsScreen({super.key});

  @override
  ConsumerState<JobsScreen> createState() => _JobsScreenState();
}

class _JobsScreenState extends ConsumerState<JobsScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filters = ref.watch(jobFiltersProvider);

    return DefaultTabController(
      length: JobTab.values.length,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          title: Text('Find Jobs', style: Theme.of(context).textTheme.titleLarge),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(120),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          onSubmitted: (v) =>
                              ref.read(jobFiltersProvider.notifier).setSearchQuery(v),
                          decoration: InputDecoration(
                            hintText: 'Job title, company, or location',
                            prefixIcon: const Icon(Icons.search, size: 20),
                            suffixIcon: _searchController.text.isEmpty
                                ? null
                                : IconButton(
                                    icon: const Icon(Icons.clear, size: 18),
                                    onPressed: () {
                                      _searchController.clear();
                                      ref
                                          .read(jobFiltersProvider.notifier)
                                          .setSearchQuery('');
                                    },
                                  ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      _FilterButton(hasActive: filters.hasActiveFilters),
                    ],
                  ),
                ),
                TabBar(
                  isScrollable: true,
                  labelColor: AppColors.bronze,
                  unselectedLabelColor: AppColors.textSecondary,
                  indicatorColor: AppColors.bronze,
                  labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  tabs: JobTab.values.map((t) => Tab(text: t.label)).toList(),
                ),
              ],
            ),
          ),
        ),
        body: TabBarView(
          children: JobTab.values.map((tab) => _JobsTabView(tab: tab)).toList(),
        ),
      ),
    );
  }
}

class _FilterButton extends ConsumerWidget {
  final bool hasActive;
  const _FilterButton({required this.hasActive});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Material(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () async {
              final filters = ref.read(jobFiltersProvider);
              final result = await showJobFilterSheet(
                context,
                initialExperienceLevel: filters.experienceLevel,
                initialCategory: filters.category,
                initialMinSalary: filters.minSalary,
                initialMaxSalary: filters.maxSalary,
              );
              if (result != null) {
                ref.read(jobFiltersProvider.notifier).applyFilters(
                      experienceLevel: result.experienceLevel,
                      category: result.category,
                      minSalary: result.minSalary,
                      maxSalary: result.maxSalary,
                    );
              }
            },
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.divider),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.tune, size: 20, color: AppColors.navy),
            ),
          ),
        ),
        if (hasActive)
          Positioned(
            top: -2,
            right: -2,
            child: Container(
              width: 10,
              height: 10,
              decoration: const BoxDecoration(
                color: AppColors.bronze,
                shape: BoxShape.circle,
              ),
            ),
          ),
      ],
    );
  }
}

class _JobsTabView extends ConsumerWidget {
  final JobTab tab;
  const _JobsTabView({required this.tab});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jobsAsync = ref.watch(jobsForTabProvider(tab));

    return jobsAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.bronze),
        ),
      ),
      error: (e, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: AppColors.error, size: 32),
              const SizedBox(height: 12),
              Text(
                e.toString(),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => ref.invalidate(jobsForTabProvider(tab)),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
      data: (jobs) {
        if (jobs.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.search_off, color: AppColors.textSecondary, size: 36),
                  const SizedBox(height: 12),
                  Text(
                    'No jobs found. Try adjusting your search or filters.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          );
        }
        return RefreshIndicator(
          color: AppColors.bronze,
          onRefresh: () async => ref.invalidate(jobsForTabProvider(tab)),
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: jobs.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (_, i) {
              final job = jobs[i];
              return JobCard(
                job: job,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => JobDetailsScreen(job: job)),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
