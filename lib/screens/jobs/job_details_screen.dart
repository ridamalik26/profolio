import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../models/job_model.dart';
import '../../core/utils/page_transitions.dart';
import '../../providers/application_provider.dart';
import '../../widgets/primary_button.dart';
import 'apply_screen.dart';

class JobDetailsScreen extends ConsumerWidget {
  final JobModel job;
  const JobDetailsScreen({super.key, required this.job});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final savedJobsAsync = ref.watch(savedJobsProvider);
    final isSaved =
        savedJobsAsync.value?.any((s) => s.jobId == job.id) ?? false;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Text('Job Details', style: theme.textTheme.titleLarge),
        actions: [
          IconButton(
            icon: Icon(
              isSaved ? Icons.bookmark : Icons.bookmark_border,
              color: AppColors.bronze,
            ),
            onPressed: () => ref.read(saveJobNotifierProvider.notifier).toggle(job),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppColors.navy.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.business_outlined,
                      color: AppColors.navy, size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(job.title, style: theme.textTheme.headlineMedium),
                      const SizedBox(height: 4),
                      Text(job.company, style: theme.textTheme.bodyLarge),
                    ],
                  ),
                ),
                if (job.matchScore != null) _MatchScoreCircle(score: job.matchScore!),
              ],
            ),
            if (job.matchReason != null) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.bronze.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.auto_awesome, size: 16, color: AppColors.bronze),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        job.matchReason!,
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: AppColors.bronzeDark),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 20),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _InfoChip(icon: Icons.location_on_outlined, label: job.location),
                _InfoChip(icon: Icons.work_outline, label: job.employmentTypeLabel),
                _InfoChip(icon: Icons.payments_outlined, label: job.salaryLabel),
                if (job.deadline != null)
                  _InfoChip(
                    icon: Icons.event_outlined,
                    label: 'Apply by ${_formatDate(job.deadline!)}',
                  ),
              ],
            ),
            const SizedBox(height: 28),
            if (job.requiredSkills.isNotEmpty) ...[
              Text('Required Skills', style: theme.textTheme.titleLarge),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: job.requiredSkills
                    .map((s) => Chip(
                          label: Text(s),
                          backgroundColor: AppColors.surface,
                          side: const BorderSide(color: AppColors.divider),
                          labelStyle: const TextStyle(fontSize: 13, color: AppColors.navy),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 28),
            ],
            Text('Job Description', style: theme.textTheme.titleLarge),
            const SizedBox(height: 12),
            Text(
              job.description.isEmpty ? 'No description provided.' : job.description,
              style: theme.textTheme.bodyMedium,
            ),
            if (job.qualifications.isNotEmpty) ...[
              const SizedBox(height: 28),
              Text('Qualifications', style: theme.textTheme.titleLarge),
              const SizedBox(height: 12),
              ...job.qualifications.map(
                (q) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(top: 6),
                        child: Icon(Icons.circle, size: 5, color: AppColors.bronze),
                      ),
                      const SizedBox(width: 10),
                      Expanded(child: Text(q, style: theme.textTheme.bodyMedium)),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 100),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
          child: PrimaryButton(
            label: 'Apply Now',
            icon: Icons.send_outlined,
            onPressed: () => pushSlideFade(context, ApplyScreen(job: job)),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }
}

class _MatchScoreCircle extends StatelessWidget {
  final int score;
  const _MatchScoreCircle({required this.score});

  Color get _color {
    if (score >= 75) return AppColors.success;
    if (score >= 50) return AppColors.bronze;
    return AppColors.error;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _color.withValues(alpha: 0.12),
        border: Border.all(color: _color, width: 2),
      ),
      child: Center(
        child: Text(
          '$score%',
          style: TextStyle(color: _color, fontWeight: FontWeight.w700, fontSize: 13),
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: AppColors.bronze),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontSize: 13, color: AppColors.navy)),
        ],
      ),
    );
  }
}
