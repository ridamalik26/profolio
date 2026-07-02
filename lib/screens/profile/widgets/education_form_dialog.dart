import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/education_model.dart';
import '../../../widgets/auth_text_field.dart';

Future<EducationModel?> showEducationDialog(
  BuildContext context, {
  EducationModel? existing,
}) {
  return showDialog<EducationModel>(
    context: context,
    builder: (_) => _EducationDialog(existing: existing),
  );
}

class _EducationDialog extends StatefulWidget {
  final EducationModel? existing;
  const _EducationDialog({this.existing});

  @override
  State<_EducationDialog> createState() => _EducationDialogState();
}

class _EducationDialogState extends State<_EducationDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _degreeController;
  late final TextEditingController _institutionController;
  late final TextEditingController _yearController;

  @override
  void initState() {
    super.initState();
    _degreeController =
        TextEditingController(text: widget.existing?.degree ?? '');
    _institutionController =
        TextEditingController(text: widget.existing?.institution ?? '');
    _yearController =
        TextEditingController(text: widget.existing?.year ?? '');
  }

  @override
  void dispose() {
    _degreeController.dispose();
    _institutionController.dispose();
    _yearController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final result = EducationModel(
      id: widget.existing?.id ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      degree: _degreeController.text.trim(),
      institution: _institutionController.text.trim(),
      year: _yearController.text.trim(),
    );
    Navigator.pop(context, result);
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    return AlertDialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        isEdit ? 'Edit Education' : 'Add Education',
        style: Theme.of(context).textTheme.titleLarge,
      ),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AuthTextField(
                controller: _degreeController,
                label: 'Degree / Qualification',
                hint: 'e.g. B.Sc. Computer Science',
                prefixIcon: Icons.school_outlined,
                textInputAction: TextInputAction.next,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Degree is required.' : null,
              ),
              const SizedBox(height: 14),
              AuthTextField(
                controller: _institutionController,
                label: 'Institution',
                hint: 'e.g. MIT',
                prefixIcon: Icons.account_balance_outlined,
                textInputAction: TextInputAction.next,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Institution is required.' : null,
              ),
              const SizedBox(height: 14),
              AuthTextField(
                controller: _yearController,
                label: 'Year',
                hint: 'e.g. 2022 or 2018 – 2022',
                prefixIcon: Icons.calendar_today_outlined,
                keyboardType: TextInputType.text,
                textInputAction: TextInputAction.done,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Year is required.' : null,
                onSubmitted: (_) => _submit(),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _submit,
          style: ElevatedButton.styleFrom(
            minimumSize: Size.zero,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          ),
          child: Text(isEdit ? 'Update' : 'Add'),
        ),
      ],
    );
  }
}
