import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/certification_model.dart';
import '../../../widgets/auth_text_field.dart';

Future<CertificationModel?> showCertificationDialog(
  BuildContext context, {
  CertificationModel? existing,
}) {
  return showDialog<CertificationModel>(
    context: context,
    builder: (_) => _CertificationDialog(existing: existing),
  );
}

class _CertificationDialog extends StatefulWidget {
  final CertificationModel? existing;
  const _CertificationDialog({this.existing});

  @override
  State<_CertificationDialog> createState() => _CertificationDialogState();
}

class _CertificationDialogState extends State<_CertificationDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _issuerController;
  late final TextEditingController _yearController;

  @override
  void initState() {
    super.initState();
    _nameController =
        TextEditingController(text: widget.existing?.name ?? '');
    _issuerController =
        TextEditingController(text: widget.existing?.issuer ?? '');
    _yearController =
        TextEditingController(text: widget.existing?.year ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _issuerController.dispose();
    _yearController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final result = CertificationModel(
      id: widget.existing?.id ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameController.text.trim(),
      issuer: _issuerController.text.trim(),
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
        isEdit ? 'Edit Certification' : 'Add Certification',
        style: Theme.of(context).textTheme.titleLarge,
      ),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AuthTextField(
                controller: _nameController,
                label: 'Certification Name',
                hint: 'e.g. AWS Solutions Architect',
                prefixIcon: Icons.verified_outlined,
                textInputAction: TextInputAction.next,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Name is required.' : null,
              ),
              const SizedBox(height: 14),
              AuthTextField(
                controller: _issuerController,
                label: 'Issuing Organization',
                hint: 'e.g. Amazon Web Services',
                prefixIcon: Icons.business_outlined,
                textInputAction: TextInputAction.next,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Issuer is required.' : null,
              ),
              const SizedBox(height: 14),
              AuthTextField(
                controller: _yearController,
                label: 'Year',
                hint: 'e.g. 2024',
                prefixIcon: Icons.calendar_today_outlined,
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
