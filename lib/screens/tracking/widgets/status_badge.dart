import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/application_model.dart';

class StatusBadge extends StatelessWidget {
  final ApplicationStatus status;
  const StatusBadge({super.key, required this.status});

  Color get _color {
    switch (status) {
      case ApplicationStatus.applied:
        return AppColors.navy;
      case ApplicationStatus.pending:
        return AppColors.bronze;
      case ApplicationStatus.accepted:
        return AppColors.success;
      case ApplicationStatus.rejected:
        return AppColors.error;
    }
  }

  String get _label {
    switch (status) {
      case ApplicationStatus.applied:
        return 'Applied';
      case ApplicationStatus.pending:
        return 'Pending';
      case ApplicationStatus.accepted:
        return 'Accepted';
      case ApplicationStatus.rejected:
        return 'Rejected';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        _label,
        style: TextStyle(color: _color, fontWeight: FontWeight.w700, fontSize: 12),
      ),
    );
  }
}
