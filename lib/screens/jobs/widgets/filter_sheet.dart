import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../widgets/primary_button.dart';

class JobFilterResult {
  final String? experienceLevel;
  final String? category;
  final double? minSalary;
  final double? maxSalary;

  const JobFilterResult({
    this.experienceLevel,
    this.category,
    this.minSalary,
    this.maxSalary,
  });
}

const _experienceLevels = {
  'no_experience': 'No experience',
  'under_3_years_experience': 'Under 3 years',
  'more_than_3_years_experience': '3+ years',
};

const _categories = [
  'Software Engineering',
  'Data & Analytics',
  'Design',
  'Marketing',
  'Sales',
  'Customer Support',
  'Product Management',
  'Finance',
];

Future<JobFilterResult?> showJobFilterSheet(
  BuildContext context, {
  String? initialExperienceLevel,
  String? initialCategory,
  double? initialMinSalary,
  double? initialMaxSalary,
}) {
  return showModalBottomSheet<JobFilterResult>(
    context: context,
    backgroundColor: AppColors.background,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => _FilterSheetContent(
      initialExperienceLevel: initialExperienceLevel,
      initialCategory: initialCategory,
      initialMinSalary: initialMinSalary,
      initialMaxSalary: initialMaxSalary,
    ),
  );
}

class _FilterSheetContent extends StatefulWidget {
  final String? initialExperienceLevel;
  final String? initialCategory;
  final double? initialMinSalary;
  final double? initialMaxSalary;

  const _FilterSheetContent({
    this.initialExperienceLevel,
    this.initialCategory,
    this.initialMinSalary,
    this.initialMaxSalary,
  });

  @override
  State<_FilterSheetContent> createState() => _FilterSheetContentState();
}

class _FilterSheetContentState extends State<_FilterSheetContent> {
  String? _experienceLevel;
  String? _category;
  late RangeValues _salaryRange;

  static const double _maxSalaryBound = 250000;

  @override
  void initState() {
    super.initState();
    _experienceLevel = widget.initialExperienceLevel;
    _category = widget.initialCategory;
    _salaryRange = RangeValues(
      widget.initialMinSalary ?? 0,
      widget.initialMaxSalary ?? _maxSalaryBound,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text('Filters', style: theme.textTheme.headlineMedium),
          const SizedBox(height: 20),

          Text('Experience level', style: theme.textTheme.titleMedium),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            children: _experienceLevels.entries.map((entry) {
              final selected = _experienceLevel == entry.key;
              return ChoiceChip(
                label: Text(entry.value),
                selected: selected,
                onSelected: (_) => setState(
                  () => _experienceLevel = selected ? null : entry.key,
                ),
                selectedColor: AppColors.bronze.withValues(alpha: 0.2),
                labelStyle: TextStyle(
                  color: selected ? AppColors.bronzeDark : AppColors.navy,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                ),
                backgroundColor: AppColors.surface,
                side: BorderSide(
                  color: selected ? AppColors.bronze : AppColors.divider,
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 20),
          Text('Job category', style: theme.textTheme.titleMedium),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _categories.map((cat) {
              final selected = _category == cat;
              return ChoiceChip(
                label: Text(cat),
                selected: selected,
                onSelected: (_) => setState(() => _category = selected ? null : cat),
                selectedColor: AppColors.bronze.withValues(alpha: 0.2),
                labelStyle: TextStyle(
                  color: selected ? AppColors.bronzeDark : AppColors.navy,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                ),
                backgroundColor: AppColors.surface,
                side: BorderSide(
                  color: selected ? AppColors.bronze : AppColors.divider,
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 20),
          Text('Salary range (yearly)', style: theme.textTheme.titleMedium),
          Text(
            '\$${_salaryRange.start.round()} - \$${_salaryRange.end.round()}',
            style: theme.textTheme.bodySmall,
          ),
          RangeSlider(
            values: _salaryRange,
            min: 0,
            max: _maxSalaryBound,
            divisions: 25,
            activeColor: AppColors.bronze,
            inactiveColor: AppColors.divider,
            onChanged: (values) => setState(() => _salaryRange = values),
          ),

          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.pop(context,
                      const JobFilterResult()),
                  child: const Text('Clear all'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: PrimaryButton(
                  label: 'Apply filters',
                  onPressed: () => Navigator.pop(
                    context,
                    JobFilterResult(
                      experienceLevel: _experienceLevel,
                      category: _category,
                      minSalary: _salaryRange.start == 0 ? null : _salaryRange.start,
                      maxSalary:
                          _salaryRange.end == _maxSalaryBound ? null : _salaryRange.end,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
