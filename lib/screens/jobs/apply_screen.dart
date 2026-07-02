import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_colors.dart';
import '../../models/job_model.dart';
import '../../providers/application_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/profile_provider.dart';
import '../../widgets/auth_text_field.dart';
import '../../widgets/error_banner.dart';
import '../../widgets/primary_button.dart';

class ApplyScreen extends ConsumerStatefulWidget {
  final JobModel job;
  const ApplyScreen({super.key, required this.job});

  @override
  ConsumerState<ApplyScreen> createState() => _ApplyScreenState();
}

class _ApplyScreenState extends ConsumerState<ApplyScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _prefilled = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _prefillFromProfile() {
    final profile = ref.read(profileProvider).value;
    final user = ref.read(currentUserProvider);
    _nameController.text = profile?.fullName.isNotEmpty == true
        ? profile!.fullName
        : (user?.displayName ?? '');
    _emailController.text = profile?.email.isNotEmpty == true
        ? profile!.email
        : (user?.email ?? '');
    _phoneController.text = profile?.phoneNumber ?? '';
    _prefilled = true;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final profile = ref.read(profileProvider).value;
    String? resumeUrl;
    if (profile?.resume != null) {
      try {
        resumeUrl = await ref.read(profileServiceProvider).createResumeSignedUrl(
              profile!.resume!.storagePath,
              expiresInSeconds: 60 * 60 * 24 * 7,
            );
      } catch (_) {
        // Non-fatal — application still submits without a resume link.
      }
    }

    final success = await ref.read(applyNotifierProvider.notifier).submit(
          job: widget.job,
          name: _nameController.text.trim(),
          email: _emailController.text.trim(),
          phone: _phoneController.text.trim(),
          resumeUrl: resumeUrl,
        );

    if (!success || !mounted) return;
  }

  Future<void> _openJobPosting() async {
    final url = widget.job.applyLink;
    if (url == null) return;
    final uri = Uri.tryParse(url);
    if (uri != null) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final applyState = ref.watch(applyNotifierProvider);
    final profileAsync = ref.watch(profileProvider);

    if (!_prefilled && !profileAsync.isLoading) {
      _prefillFromProfile();
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Text(
          applyState.isSubmitted ? 'Application Sent' : 'Apply',
          style: theme.textTheme.titleLarge,
        ),
      ),
      body: applyState.isSubmitted
          ? _ConfirmationView(job: widget.job, onOpenPosting: _openJobPosting)
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.job.title, style: theme.textTheme.headlineMedium),
                    const SizedBox(height: 4),
                    Text(widget.job.company, style: theme.textTheme.bodyLarge),
                    const SizedBox(height: 24),
                    if (applyState.error != null) ...[
                      ErrorBanner(message: applyState.error!),
                      const SizedBox(height: 16),
                    ],
                    Text('Your details', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 12),
                    AuthTextField(
                      controller: _nameController,
                      label: 'Full name',
                      prefixIcon: Icons.person_outline,
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Name is required' : null,
                    ),
                    const SizedBox(height: 14),
                    AuthTextField(
                      controller: _emailController,
                      label: 'Email',
                      keyboardType: TextInputType.emailAddress,
                      prefixIcon: Icons.email_outlined,
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Email is required' : null,
                    ),
                    const SizedBox(height: 14),
                    AuthTextField(
                      controller: _phoneController,
                      label: 'Phone number',
                      keyboardType: TextInputType.phone,
                      prefixIcon: Icons.phone_outlined,
                      textInputAction: TextInputAction.done,
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Phone is required' : null,
                    ),
                    const SizedBox(height: 20),
                    _ResumeStatusTile(hasResume: profileAsync.value?.resume != null),
                    const SizedBox(height: 32),
                    PrimaryButton(
                      label: 'Submit Application',
                      icon: Icons.send_outlined,
                      isLoading: applyState.isLoading,
                      onPressed: _submit,
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

class _ResumeStatusTile extends StatelessWidget {
  final bool hasResume;
  const _ResumeStatusTile({required this.hasResume});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          Icon(
            hasResume ? Icons.description : Icons.warning_amber_rounded,
            color: hasResume ? AppColors.success : AppColors.bronze,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              hasResume
                  ? 'Your resume will be attached to this application.'
                  : 'No resume on file — upload one from your profile for a stronger application.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}

class _ConfirmationView extends StatelessWidget {
  final JobModel job;
  final VoidCallback onOpenPosting;
  const _ConfirmationView({required this.job, required this.onOpenPosting});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                color: AppColors.success,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check, color: AppColors.white, size: 36),
            ),
            const SizedBox(height: 24),
            Text('Application submitted!', style: theme.textTheme.headlineMedium),
            const SizedBox(height: 8),
            Text(
              'Your application for ${job.title} at ${job.company} has been recorded and added to your tracker.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 32),
            if (job.applyLink != null)
              PrimaryButton(
                label: 'Open Job Posting',
                icon: Icons.open_in_new,
                onPressed: onOpenPosting,
              ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
              child: const Text('Back to Home'),
            ),
          ],
        ),
      ),
    );
  }
}
