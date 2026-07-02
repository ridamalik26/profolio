import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/experience_model.dart';
import '../../../widgets/auth_text_field.dart';

Future<ExperienceModel?> showExperienceDialog(
  BuildContext context, {
  ExperienceModel? existing,
}) {
  return showDialog<ExperienceModel>(
    context: context,
    builder: (_) => _ExperienceDialog(existing: existing),
  );
}

class _ExperienceDialog extends StatefulWidget {
  final ExperienceModel? existing;
  const _ExperienceDialog({this.existing});

  @override
  State<_ExperienceDialog> createState() => _ExperienceDialogState();
}

class _ExperienceDialogState extends State<_ExperienceDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _roleController;
  late final TextEditingController _companyController;
  late final TextEditingController _durationController;
  late final TextEditingController _descriptionController;

  @override
  void initState() {
    super.initState();
    _roleController =
        TextEditingController(text: widget.existing?.role ?? '');
    _companyController =
        TextEditingController(text: widget.existing?.company ?? '');
    _durationController =
        TextEditingController(text: widget.existing?.duration ?? '');
    _descriptionController =
        TextEditingController(text: widget.existing?.description ?? '');
  }

  @override
  void dispose() {
    _roleController.dispose();
    _companyController.dispose();
    _durationController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final result = ExperienceModel(
      id: widget.existing?.id ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      role: _roleController.text.trim(),
      company: _companyController.text.trim(),
      duration: _durationController.text.trim(),
      description: _descriptionController.text.trim(),
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
        isEdit ? 'Edit Experience' : 'Add Experience',
        style: Theme.of(context).textTheme.titleLarge,
      ),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AuthTextField(
                controller: _roleController,
                label: 'Role / Title',
                hint: 'e.g. Senior Flutter Developer',
                prefixIcon: Icons.work_outline,
                textInputAction: TextInputAction.next,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Role is required.' : null,
              ),
              const SizedBox(height: 14),
              AuthTextField(
                controller: _companyController,
                label: 'Company',
                hint: 'e.g. Google',
                prefixIcon: Icons.business_outlined,
                textInputAction: TextInputAction.next,
                validator: (v) =>
                    (v == null || v.trim().isEmpty)
                        ? 'Company is required.'
                        : null,
              ),
              const SizedBox(height: 14),
              AuthTextField(
                controller: _durationController,
                label: 'Duration',
                hint: 'e.g. Jan 2022 – Present',
                prefixIcon: Icons.date_range_outlined,
                textInputAction: TextInputAction.next,
                validator: (v) =>
                    (v == null || v.trim().isEmpty)
                        ? 'Duration is required.'
                        : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _submit(),
                style: Theme.of(context).textTheme.bodyLarge,
                decoration: const InputDecoration(
                  labelText: 'Description (optional)',
                  hintText: 'Brief summary of your responsibilities…',
                  alignLabelWithHint: true,
                ),
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
