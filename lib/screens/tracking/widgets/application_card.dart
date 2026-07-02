import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/application_model.dart';
import 'status_badge.dart';

class ApplicationCard extends StatelessWidget {
  final ApplicationModel application;
  final ValueChanged<ApplicationStatus> onStatusChanged;

  const ApplicationCard({
    super.key,
    required this.application,
    required this.onStatusChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(application.jobTitle, style: theme.textTheme.titleMedium),
                    const SizedBox(height: 2),
                    Text(application.companyName, style: theme.textTheme.bodySmall),
                  ],
                ),
              ),
              PopupMenuButton<ApplicationStatus>(
                icon: const Icon(Icons.more_vert, size: 18, color: AppColors.textSecondary),
                onSelected: onStatusChanged,
                itemBuilder: (_) => ApplicationStatus.values
                    .map((s) => PopupMenuItem(value: s, child: Text('Mark as ${s.name}')))
                    .toList(),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              StatusBadge(status: application.status),
              const Spacer(),
              if (application.matchScore != null)
                Text(
                  '${application.matchScore}% match',
                  style: theme.textTheme.bodySmall?.copyWith(color: AppColors.bronze),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Applied ${_formatDate(application.appliedAt)}',
            style: theme.textTheme.bodySmall,
          ),
        ],
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
