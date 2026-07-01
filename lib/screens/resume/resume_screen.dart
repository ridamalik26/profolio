import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_colors.dart';
import '../../models/resume_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/profile_provider.dart';
import '../../providers/resume_provider.dart';
import '../../widgets/error_banner.dart';

class ResumeScreen extends ConsumerWidget {
  const ResumeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileProvider);
    final resumeState = ref.watch(resumeProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: AppColors.navy, size: 20),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: Text('My Resume', style: theme.textTheme.titleLarge),
      ),
      body: profileAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.bronze),
          ),
        ),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('Error: $e',
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: AppColors.error)),
          ),
        ),
        data: (profile) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Success banner
                if (resumeState.successMessage != null) ...[
                  _SuccessBanner(
                    message: resumeState.successMessage!,
                    onDismiss: ref.read(resumeProvider.notifier).clearSuccess,
                  ),
                  const SizedBox(height: 16),
                ],

                // Error banner
                if (resumeState.error != null) ...[
                  ErrorBanner(
                    message: resumeState.error!,
                    onDismiss: ref.read(resumeProvider.notifier).clearError,
                  ),
                  const SizedBox(height: 16),
                ],

                // Upload progress overlay card
                if (resumeState.isUploading) ...[
                  _UploadProgressCard(progress: resumeState.uploadProgress),
                  const SizedBox(height: 20),
                ],

                // Resume content
                if (profile?.resume != null && !resumeState.isUploading)
                  _ResumeCard(
                    resume: profile!.resume!,
                    isDeleting: resumeState.isDeleting,
                    onView: () => _viewResume(context, ref, profile.resume!.storagePath),
                    onReplace: () => _replaceResume(context, ref),
                    onDelete: () => _confirmDelete(context, ref),
                  )
                else if (!resumeState.isUploading)
                  _UploadZone(
                    onUpload: () => _uploadResume(context, ref),
                  ),

                const SizedBox(height: 32),
                _GuidelinesCard(theme: theme),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _uploadResume(BuildContext context, WidgetRef ref) async {
    final uid = ref.read(authStateChangesProvider).value?.id;
    if (uid == null) return;

    final file = await ref.read(resumeProvider.notifier).pickResumeFile();
    if (file == null) return; // validation error already set in state

    await ref.read(resumeProvider.notifier).upload(uid: uid, file: file);
  }

  Future<void> _replaceResume(BuildContext context, WidgetRef ref) async {
    final uid = ref.read(authStateChangesProvider).value?.id;
    if (uid == null) return;

    final file = await ref.read(resumeProvider.notifier).pickResumeFile();
    if (file == null) return;

    await ref.read(resumeProvider.notifier).replace(uid: uid, newFile: file);
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Delete Resume',
            style: Theme.of(ctx).textTheme.titleLarge),
        content: Text(
          'This will permanently delete your resume from storage. Are you sure?',
          style: Theme.of(ctx).textTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              minimumSize: Size.zero,
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final uid = ref.read(authStateChangesProvider).value?.id;
      if (uid == null) return;
      await ref.read(resumeProvider.notifier).delete(uid: uid);
    }
  }

  Future<void> _viewResume(
      BuildContext context, WidgetRef ref, String storagePath) async {
    final url = await ref.read(resumeProvider.notifier).getViewUrl(storagePath);
    if (url == null) return; // error already set in state
    if (context.mounted) await _openURL(context, url);
  }

  Future<void> _openURL(BuildContext context, String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open the resume. Try copying the link.'),
          ),
        );
      }
    }
  }
}

// ── Upload zone (no resume yet) ───────────────────────────────────────────────

class _UploadZone extends StatelessWidget {
  final VoidCallback onUpload;
  const _UploadZone({required this.onUpload});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onUpload,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.bronze.withValues(alpha: 0.4),
            width: 1.5,
            style: BorderStyle.solid,
          ),
        ),
        child: Column(
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.bronze.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.upload_file_outlined,
                  color: AppColors.bronze, size: 36),
            ),
            const SizedBox(height: 20),
            Text('Upload Your Resume',
                style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              'Tap to browse or select a PDF / DOCX file',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onUpload,
              icon: const Icon(Icons.folder_open_outlined, size: 18),
              label: const Text('Browse File'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(180, 48),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.info_outline,
                    size: 14, color: AppColors.textSecondary),
                const SizedBox(width: 6),
                Text(
                  'PDF or DOCX  ·  Max 5 MB',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Resume card (resume exists) ───────────────────────────────────────────────

class _ResumeCard extends StatelessWidget {
  final ResumeModel resume;
  final bool isDeleting;
  final VoidCallback onView;
  final VoidCallback onReplace;
  final VoidCallback onDelete;

  const _ResumeCard({
    required this.resume,
    required this.isDeleting,
    required this.onView,
    required this.onReplace,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.divider),
        boxShadow: [
          BoxShadow(
            color: AppColors.navy.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // File header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                _FileTypeIcon(isPDF: resume.isPDF),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        resume.fileName,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Uploaded ${resume.formattedDate}  ·  ${resume.formattedSize}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Action buttons
          Padding(
            padding: const EdgeInsets.all(16),
            child: isDeleting
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  AppColors.error),
                            ),
                          ),
                          SizedBox(width: 10),
                          Text('Deleting…',
                              style: TextStyle(color: AppColors.error)),
                        ],
                      ),
                    ),
                  )
                : Column(
                    children: [
                      // View / Download
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: onView,
                          icon: const Icon(Icons.open_in_new, size: 18),
                          label: const Text('View / Download'),
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 48),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          // Replace
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: onReplace,
                              icon: const Icon(Icons.swap_horiz, size: 16),
                              label: const Text('Replace'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.bronze,
                                side: const BorderSide(
                                    color: AppColors.bronze),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(
                                    vertical: 12),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          // Delete
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: onDelete,
                              icon: const Icon(Icons.delete_outline, size: 16),
                              label: const Text('Delete'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.error,
                                side: BorderSide(
                                    color:
                                        AppColors.error.withValues(alpha: 0.5)),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(
                                    vertical: 12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

// ── Upload progress card ──────────────────────────────────────────────────────

class _UploadProgressCard extends StatelessWidget {
  final double progress;
  const _UploadProgressCard({required this.progress});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pct = (progress * 100).toInt();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.bronze.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor:
                      AlwaysStoppedAnimation<Color>(AppColors.bronze),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                pct < 100 ? 'Uploading… $pct%' : 'Saving…',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: AppColors.bronze,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: AppColors.bronze.withValues(alpha: 0.15),
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppColors.bronze),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Please keep the app open until the upload finishes.',
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

// ── Guidelines card ───────────────────────────────────────────────────────────

class _GuidelinesCard extends StatelessWidget {
  final ThemeData theme;
  const _GuidelinesCard({required this.theme});

  @override
  Widget build(BuildContext context) {
    const items = [
      (Icons.picture_as_pdf_outlined, 'PDF or DOCX formats only'),
      (Icons.straighten_outlined, 'Maximum file size: 5 MB'),
      (Icons.lock_outlined, 'Stored securely — only you can access it'),
      (Icons.cached_outlined, 'Replace anytime with a newer version'),
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.navy.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.navy.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline,
                  color: AppColors.navy, size: 18),
              const SizedBox(width: 8),
              Text('Resume Guidelines',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: AppColors.navy,
                  )),
            ],
          ),
          const SizedBox(height: 14),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Icon(item.$1,
                      size: 16, color: AppColors.bronze),
                  const SizedBox(width: 10),
                  Text(item.$2,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.navy,
                      )),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── File type icon badge ──────────────────────────────────────────────────────

class _FileTypeIcon extends StatelessWidget {
  final bool isPDF;
  const _FileTypeIcon({required this.isPDF});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: isPDF
            ? const Color(0xFFE53935).withValues(alpha: 0.1)
            : const Color(0xFF1565C0).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isPDF ? Icons.picture_as_pdf_outlined : Icons.article_outlined,
            color: isPDF
                ? const Color(0xFFE53935)
                : const Color(0xFF1565C0),
            size: 24,
          ),
          const SizedBox(height: 2),
          Text(
            isPDF ? 'PDF' : 'DOCX',
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: isPDF
                  ? const Color(0xFFE53935)
                  : const Color(0xFF1565C0),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Success banner ────────────────────────────────────────────────────────────

class _SuccessBanner extends StatelessWidget {
  final String message;
  final VoidCallback? onDismiss;

  const _SuccessBanner({required this.message, this.onDismiss});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline,
              color: AppColors.success, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(message,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.success,
                      fontSize: 13,
                    )),
          ),
          if (onDismiss != null)
            GestureDetector(
              onTap: onDismiss,
              child: const Icon(Icons.close,
                  color: AppColors.success, size: 16),
            ),
        ],
      ),
    );
  }
}

// ── Primary button (loading) ──────────────────────────────────────────────────
// Re-exported here for convenience — the widget itself lives in widgets/
