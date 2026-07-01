import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_colors.dart';
import '../../models/certification_model.dart';
import '../../models/education_model.dart';
import '../../models/experience_model.dart';
import '../../models/profile_model.dart';
import '../../models/resume_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/profile_provider.dart';
import '../resume/resume_screen.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileProvider);

    return profileAsync.when(
      loading: () => const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.bronze),
          ),
        ),
      ),
      error: (e, _) => Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Text('Error loading profile: $e'),
        ),
      ),
      data: (profile) => _ProfileView(profile: profile),
    );
  }
}

class _ProfileView extends ConsumerWidget {
  final ProfileModel? profile;
  const _ProfileView({required this.profile});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final user = ref.watch(currentUserProvider);

    void goToEdit() async {
      final saved = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (_) => EditProfileScreen(initialProfile: profile),
        ),
      );
      if (saved == true) {
        ref.invalidate(profileProvider);
      }
    }

    if (profile == null || profile!.fullName.isEmpty) {
      return _EmptyProfile(
        email: user?.email ?? '',
        onSetup: goToEdit,
      );
    }

    final p = profile!;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // ── App bar with gradient ──────────────────────────────────────
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: AppColors.navy,
            surfaceTintColor: Colors.transparent,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new,
                  color: AppColors.white, size: 20),
              onPressed: () => Navigator.maybePop(context),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_outlined, color: AppColors.white),
                onPressed: goToEdit,
              ),
              const SizedBox(width: 8),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppColors.navy, AppColors.navyLight],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                  ),
                  // subtle pattern overlay
                  Opacity(
                    opacity: 0.04,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.bronze,
                        borderRadius: BorderRadius.circular(0),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Profile header (photo + name) ──────────────────────────────
          SliverToBoxAdapter(
            child: Transform.translate(
              offset: const Offset(0, -48),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    _buildAvatar(p),
                    const SizedBox(height: 12),
                    Text(p.fullName, style: theme.textTheme.headlineMedium),
                    const SizedBox(height: 4),
                    Text(
                      p.email,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    if (p.address != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.location_on_outlined,
                              size: 14, color: AppColors.textSecondary),
                          const SizedBox(width: 4),
                          Text(
                            p.address!,
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 16),
                    // Link buttons
                    if (p.portfolioURL != null || p.linkedinURL != null)
                      _buildLinkChips(p, theme),
                  ],
                ),
              ),
            ),
          ),

          // ── Content sections ───────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Personal Info
                if (p.phoneNumber != null || p.dateOfBirth != null)
                  _InfoCard(
                    icon: Icons.person_outline,
                    title: 'Personal Information',
                    child: Column(
                      children: [
                        if (p.phoneNumber != null)
                          _InfoRow(Icons.phone_outlined, 'Phone', p.phoneNumber!),
                        if (p.formattedDateOfBirth != null)
                          _InfoRow(Icons.cake_outlined, 'Date of Birth',
                              p.formattedDateOfBirth!),
                      ],
                    ),
                  ),

                // Education
                if (p.education.isNotEmpty)
                  _InfoCard(
                    icon: Icons.school_outlined,
                    title: 'Education',
                    child: Column(
                      children: p.education
                          .map((e) => _EducationTile(e))
                          .toList(),
                    ),
                  ),

                // Experience
                if (p.experience.isNotEmpty)
                  _InfoCard(
                    icon: Icons.work_outline,
                    title: 'Work Experience',
                    child: Column(
                      children: p.experience
                          .map((e) => _ExperienceTile(e))
                          .toList(),
                    ),
                  ),

                // Skills
                if (p.skills.isNotEmpty)
                  _InfoCard(
                    icon: Icons.psychology_outlined,
                    title: 'Skills',
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: p.skills
                          .map((s) => _SkillChip(s))
                          .toList(),
                    ),
                  ),

                // Languages
                if (p.languages.isNotEmpty)
                  _InfoCard(
                    icon: Icons.translate,
                    title: 'Languages',
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: p.languages
                          .map((l) => _SkillChip(l, isLanguage: true))
                          .toList(),
                    ),
                  ),

                // Certifications
                if (p.certifications.isNotEmpty)
                  _InfoCard(
                    icon: Icons.verified_outlined,
                    title: 'Certifications',
                    child: Column(
                      children: p.certifications
                          .map((c) => _CertificationTile(c))
                          .toList(),
                    ),
                  ),

                // Resume
                _InfoCard(
                  icon: Icons.description_outlined,
                  title: 'Resume',
                  child: p.resume != null
                      ? _ResumeTile(
                          resume: p.resume!,
                          onManage: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ResumeScreen(),
                            ),
                          ),
                        )
                      : _ResumeEmptyTile(
                          onUpload: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ResumeScreen(),
                            ),
                          ),
                        ),
                ),
              ]),
            ),
          ),
        ],
      ),

      // FAB to edit
      floatingActionButton: FloatingActionButton.extended(
        onPressed: goToEdit,
        backgroundColor: AppColors.bronze,
        foregroundColor: AppColors.white,
        icon: const Icon(Icons.edit_outlined),
        label: const Text('Edit Profile',
            style: TextStyle(fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _buildAvatar(ProfileModel p) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.background, width: 4),
      ),
      child: CircleAvatar(
        radius: 52,
        backgroundColor: AppColors.bronze.withValues(alpha: 0.15),
        backgroundImage: p.photoURL != null
            ? CachedNetworkImageProvider(p.photoURL!)
            : null,
        child: p.photoURL == null
            ? Text(
                p.fullName.isNotEmpty ? p.fullName[0].toUpperCase() : 'P',
                style: const TextStyle(
                  color: AppColors.bronze,
                  fontSize: 36,
                  fontWeight: FontWeight.w700,
                ),
              )
            : null,
      ),
    );
  }

  Widget _buildLinkChips(ProfileModel p, ThemeData theme) {
    return Wrap(
      spacing: 10,
      children: [
        if (p.portfolioURL != null)
          _LinkChip(
              icon: Icons.language, label: 'Portfolio', url: p.portfolioURL!),
        if (p.linkedinURL != null)
          _LinkChip(
              icon: Icons.people_outline, label: 'LinkedIn', url: p.linkedinURL!),
      ],
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyProfile extends StatelessWidget {
  final String email;
  final VoidCallback onSetup;

  const _EmptyProfile({required this.email, required this.onSetup});

  @override
  Widget build(BuildContext context) {
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
        title: Text('My Profile', style: theme.textTheme.titleLarge),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  color: AppColors.bronze.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.person_add_outlined,
                    color: AppColors.bronze, size: 44),
              ),
              const SizedBox(height: 24),
              Text('Set up your profile',
                  style: theme.textTheme.headlineMedium),
              const SizedBox(height: 12),
              Text(
                'Complete your profile to showcase your skills, education, and experience.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: onSetup,
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Create Profile'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Reusable view widgets ─────────────────────────────────────────────────────

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget child;

  const _InfoCard({
    required this.icon,
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.bronze, size: 18),
              const SizedBox(width: 8),
              Text(title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  )),
            ],
          ),
          const Divider(height: 20),
          child,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow(this.icon, this.label, this.value);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.textSecondary),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: theme.textTheme.bodySmall),
              Text(value,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  )),
            ],
          ),
        ],
      ),
    );
  }
}

class _EducationTile extends StatelessWidget {
  final EducationModel edu;
  const _EducationTile(this.edu);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.bronze.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.school_outlined,
                color: AppColors.bronze, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(edu.degree,
                    style: theme.textTheme.titleMedium?.copyWith(fontSize: 14)),
                Text(edu.institution,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    )),
                Text(edu.year,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.bronze,
                      fontWeight: FontWeight.w500,
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ExperienceTile extends StatelessWidget {
  final ExperienceModel exp;
  const _ExperienceTile(this.exp);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.navy.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.business_outlined,
                color: AppColors.navy, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(exp.role,
                    style: theme.textTheme.titleMedium?.copyWith(fontSize: 14)),
                Text(exp.company,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    )),
                Text(exp.duration,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.bronze,
                      fontWeight: FontWeight.w500,
                    )),
                if (exp.description.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    exp.description,
                    style: theme.textTheme.bodySmall,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CertificationTile extends StatelessWidget {
  final CertificationModel cert;
  const _CertificationTile(this.cert);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          const Icon(Icons.verified, color: AppColors.bronze, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(cert.name,
                    style: theme.textTheme.titleMedium?.copyWith(fontSize: 14)),
                Text('${cert.issuer} · ${cert.year}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SkillChip extends StatelessWidget {
  final String label;
  final bool isLanguage;

  const _SkillChip(this.label, {this.isLanguage = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isLanguage
            ? AppColors.navy.withValues(alpha: 0.08)
            : AppColors.bronze.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isLanguage
              ? AppColors.navy.withValues(alpha: 0.2)
              : AppColors.bronze.withValues(alpha: 0.3),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isLanguage ? AppColors.navy : AppColors.bronze,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _LinkChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String url;

  const _LinkChip({required this.icon, required this.label, required this.url});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final uri = Uri.tryParse(url);
        if (uri != null) {
          try {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          } catch (_) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text(url),
                    duration: const Duration(seconds: 2)),
              );
            }
          }
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.navy,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppColors.white, size: 14),
            const SizedBox(width: 6),
            Text(label,
                style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}

// ── Resume tiles ──────────────────────────────────────────────────────────────

class _ResumeTile extends StatelessWidget {
  final ResumeModel resume;
  final VoidCallback onManage;

  const _ResumeTile({required this.resume, required this.onManage});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: resume.isPDF
                ? const Color(0xFFE53935).withValues(alpha: 0.1)
                : const Color(0xFF1565C0).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            resume.isPDF
                ? Icons.picture_as_pdf_outlined
                : Icons.article_outlined,
            color: resume.isPDF
                ? const Color(0xFFE53935)
                : const Color(0xFF1565C0),
            size: 22,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                resume.fileName,
                style: theme.textTheme.titleMedium?.copyWith(fontSize: 14),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                '${resume.formattedDate}  ·  ${resume.formattedSize}',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
        TextButton(
          onPressed: onManage,
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            minimumSize: Size.zero,
          ),
          child: const Text('Manage'),
        ),
      ],
    );
  }
}

class _ResumeEmptyTile extends StatelessWidget {
  final VoidCallback onUpload;
  const _ResumeEmptyTile({required this.onUpload});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.bronze.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.upload_file_outlined,
              color: AppColors.bronze, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('No resume uploaded',
                  style: theme.textTheme.titleMedium?.copyWith(fontSize: 14)),
              Text('PDF or DOCX  ·  Max 5 MB',
                  style: theme.textTheme.bodySmall),
            ],
          ),
        ),
        ElevatedButton(
          onPressed: onUpload,
          style: ElevatedButton.styleFrom(
            minimumSize: Size.zero,
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          ),
          child: const Text('Upload'),
        ),
      ],
    );
  }
}
