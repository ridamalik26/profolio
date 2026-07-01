import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/validators.dart';
import '../../models/profile_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/profile_provider.dart';
import '../../widgets/auth_text_field.dart';
import '../../widgets/error_banner.dart';
import '../../widgets/primary_button.dart';
import 'widgets/certification_form_dialog.dart';
import 'widgets/education_form_dialog.dart';
import 'widgets/experience_form_dialog.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  final ProfileModel? initialProfile;

  const EditProfileScreen({super.key, this.initialProfile});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _dobController;
  late final TextEditingController _addressController;
  late final TextEditingController _portfolioController;
  late final TextEditingController _linkedinController;

  @override
  void initState() {
    super.initState();
    final p = widget.initialProfile;

    // Fall back to Supabase Auth data when profile hasn't been filled yet.
    final authUser = ref.read(currentUserProvider);
    final seedName = p?.fullName.isNotEmpty == true
        ? p!.fullName
        : (authUser?.displayName ?? '');

    _nameController = TextEditingController(text: seedName);
    _phoneController = TextEditingController(text: p?.phoneNumber ?? '');
    _dobController = TextEditingController(text: _isoToDisplayDate(p?.dateOfBirth));
    _addressController = TextEditingController(text: p?.address ?? '');
    _portfolioController = TextEditingController(text: p?.portfolioURL ?? '');
    _linkedinController = TextEditingController(text: p?.linkedinURL ?? '');

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final notifier = ref.read(profileEditProvider.notifier);
      if (p != null) notifier.initFromProfile(p);
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _dobController.dispose();
    _addressController.dispose();
    _portfolioController.dispose();
    _linkedinController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(now.year - 25),
      firstDate: DateTime(1940),
      lastDate: DateTime(now.year - 10),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppColors.bronze,
            onPrimary: AppColors.white,
            surface: AppColors.surface,
            onSurface: AppColors.navy,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      _dobController.text =
          '${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}';
    }
  }

  /// Converts a Postgres `date` column value ("yyyy-MM-dd") to the
  /// "dd/MM/yyyy" format shown in the date field.
  static String _isoToDisplayDate(String? iso) {
    if (iso == null || iso.isEmpty) return '';
    final parts = iso.split('-');
    if (parts.length != 3) return iso;
    return '${parts[2]}/${parts[1]}/${parts[0]}';
  }

  /// Converts the "dd/MM/yyyy" date field text to an ISO "yyyy-MM-dd" string
  /// for storage in the Postgres `date` column.
  static String? _displayToIsoDate(String display) {
    final trimmed = display.trim();
    if (trimmed.isEmpty) return null;
    final parts = trimmed.split('/');
    if (parts.length != 3) return null;
    final day = parts[0].padLeft(2, '0');
    final month = parts[1].padLeft(2, '0');
    final year = parts[2];
    return '$year-$month-$day';
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    final uid = ref.read(authStateChangesProvider).value?.id;
    if (uid == null) return;

    final email =
        widget.initialProfile?.email ?? ref.read(currentUserProvider)?.email ?? '';

    final success = await ref.read(profileEditProvider.notifier).save(
          uid: uid,
          fullName: _nameController.text.trim(),
          email: email,
          phoneNumber: _phoneController.text.trim().isEmpty
              ? null
              : _phoneController.text.trim(),
          dateOfBirth: _displayToIsoDate(_dobController.text),
          address: _addressController.text.trim().isEmpty
              ? null
              : _addressController.text.trim(),
          portfolioURL: _portfolioController.text.trim().isEmpty
              ? null
              : _portfolioController.text.trim(),
          linkedinURL: _linkedinController.text.trim().isEmpty
              ? null
              : _linkedinController.text.trim(),
        );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile saved successfully!')),
      );
      Navigator.pop(context, true);
    }
  }

  void _showPhotoOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppColors.inputBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined,
                    color: AppColors.bronze),
                title: const Text('Take a photo'),
                onTap: () {
                  Navigator.pop(context);
                  ref
                      .read(profileEditProvider.notifier)
                      .pickPhoto(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined,
                    color: AppColors.bronze),
                title: const Text('Choose from library'),
                onTap: () {
                  Navigator.pop(context);
                  ref
                      .read(profileEditProvider.notifier)
                      .pickPhoto(ImageSource.gallery);
                },
              ),
              if (ref.read(profileEditProvider).existingPhotoURL != null ||
                  ref.read(profileEditProvider).pendingPhoto != null)
                ListTile(
                  leading:
                      const Icon(Icons.delete_outline, color: AppColors.error),
                  title: const Text('Remove photo',
                      style: TextStyle(color: AppColors.error)),
                  onTap: () {
                    Navigator.pop(context);
                    ref.read(profileEditProvider.notifier).removePhoto();
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final editState = ref.watch(profileEditProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
          color: AppColors.navy,
        ),
        title: Text('Edit Profile', style: theme.textTheme.titleLarge),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: TextButton(
              onPressed: editState.isLoading ? null : _save,
              child: editState.isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(AppColors.bronze),
                      ),
                    )
                  : const Text('Save',
                      style: TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 16)),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            // Error banner
            if (editState.error != null) ...[
              ErrorBanner(
                message: editState.error!,
                onDismiss: ref.read(profileEditProvider.notifier).clearError,
              ),
              const SizedBox(height: 12),
            ],

            // ── Photo ──────────────────────────────────────────────────────
            _PhotoSection(
              pendingPhoto: editState.pendingPhoto,
              existingPhotoURL: editState.existingPhotoURL,
              onTap: _showPhotoOptions,
              displayName: _nameController.text,
            ),
            const SizedBox(height: 8),

            // ── Basic Info ─────────────────────────────────────────────────
            _SectionCard(
              icon: Icons.person_outline,
              title: 'Basic Information',
              child: Column(
                children: [
                  AuthTextField(
                    controller: _nameController,
                    label: 'Full Name',
                    hint: 'Your full name',
                    prefixIcon: Icons.badge_outlined,
                    textInputAction: TextInputAction.next,
                    validator: Validators.displayName,
                  ),
                  const SizedBox(height: 14),
                  // Read-only email (tied to the Supabase Auth account)
                  _ReadOnlyField(
                    label: 'Email',
                    value: widget.initialProfile?.email ??
                        ref.read(currentUserProvider)?.email ??
                        '',
                    icon: Icons.email_outlined,
                  ),
                  const SizedBox(height: 14),
                  AuthTextField(
                    controller: _phoneController,
                    label: 'Phone Number (optional)',
                    hint: '+1 234 567 8900',
                    prefixIcon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 14),
                  GestureDetector(
                    onTap: _pickDate,
                    child: AbsorbPointer(
                      child: AuthTextField(
                        controller: _dobController,
                        label: 'Date of Birth (optional)',
                        hint: 'DD/MM/YYYY',
                        prefixIcon: Icons.cake_outlined,
                        textInputAction: TextInputAction.next,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  AuthTextField(
                    controller: _addressController,
                    label: 'Address / Location (optional)',
                    hint: 'City, Country',
                    prefixIcon: Icons.location_on_outlined,
                    textInputAction: TextInputAction.next,
                  ),
                ],
              ),
            ),

            // ── Education ──────────────────────────────────────────────────
            _SectionCard(
              icon: Icons.school_outlined,
              title: 'Education',
              child: _EducationSection(editState: editState),
            ),

            // ── Experience ─────────────────────────────────────────────────
            _SectionCard(
              icon: Icons.work_outline,
              title: 'Work Experience',
              child: _ExperienceSection(editState: editState),
            ),

            // ── Skills & Languages ─────────────────────────────────────────
            _SectionCard(
              icon: Icons.psychology_outlined,
              title: 'Skills & Languages',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Skills',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: AppColors.navy,
                        fontSize: 14,
                      )),
                  const SizedBox(height: 10),
                  _ChipsEditor(
                    items: editState.skills,
                    hint: 'Add a skill (e.g. Flutter)',
                    onChanged: ref.read(profileEditProvider.notifier).setSkills,
                  ),
                  const SizedBox(height: 20),
                  Text('Languages',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: AppColors.navy,
                        fontSize: 14,
                      )),
                  const SizedBox(height: 10),
                  _ChipsEditor(
                    items: editState.languages,
                    hint: 'Add a language (e.g. English)',
                    onChanged:
                        ref.read(profileEditProvider.notifier).setLanguages,
                  ),
                ],
              ),
            ),

            // ── Certifications ─────────────────────────────────────────────
            _SectionCard(
              icon: Icons.verified_outlined,
              title: 'Certifications',
              child: _CertificationsSection(editState: editState),
            ),

            // ── Links ──────────────────────────────────────────────────────
            _SectionCard(
              icon: Icons.link,
              title: 'Portfolio & Links',
              child: Column(
                children: [
                  AuthTextField(
                    controller: _portfolioController,
                    label: 'Portfolio URL (optional)',
                    hint: 'https://yourportfolio.com',
                    prefixIcon: Icons.language,
                    keyboardType: TextInputType.url,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 14),
                  AuthTextField(
                    controller: _linkedinController,
                    label: 'LinkedIn URL (optional)',
                    hint: 'https://linkedin.com/in/yourname',
                    prefixIcon: Icons.people_outline,
                    keyboardType: TextInputType.url,
                    textInputAction: TextInputAction.done,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),
            PrimaryButton(
              onPressed: _save,
              label: 'Save Profile',
              isLoading: editState.isLoading,
              icon: Icons.check,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Photo section ─────────────────────────────────────────────────────────────

class _PhotoSection extends StatelessWidget {
  final XFile? pendingPhoto;
  final String? existingPhotoURL;
  final VoidCallback onTap;
  final String displayName;

  const _PhotoSection({
    required this.pendingPhoto,
    required this.existingPhotoURL,
    required this.onTap,
    required this.displayName,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Stack(
          children: [
            GestureDetector(
              onTap: onTap,
              child: CircleAvatar(
                radius: 56,
                backgroundColor: AppColors.bronze.withValues(alpha: 0.15),
                backgroundImage: _buildImage(),
                child: _buildPlaceholder(context),
              ),
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: GestureDetector(
                onTap: onTap,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: const BoxDecoration(
                    color: AppColors.bronze,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.camera_alt,
                      color: AppColors.white, size: 18),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  ImageProvider? _buildImage() {
    if (pendingPhoto != null) return FileImage(File(pendingPhoto!.path));
    if (existingPhotoURL != null) {
      return CachedNetworkImageProvider(existingPhotoURL!);
    }
    return null;
  }

  Widget? _buildPlaceholder(BuildContext context) {
    if (pendingPhoto != null || existingPhotoURL != null) return null;
    final initial = displayName.isNotEmpty ? displayName[0].toUpperCase() : 'P';
    return Text(
      initial,
      style: Theme.of(context).textTheme.headlineLarge?.copyWith(
            color: AppColors.bronze,
            fontWeight: FontWeight.w700,
          ),
    );
  }
}

// ── Education section ─────────────────────────────────────────────────────────

class _EducationSection extends ConsumerWidget {
  final ProfileEditState editState;
  const _EducationSection({required this.editState});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(profileEditProvider.notifier);
    return Column(
      children: [
        ...editState.education.map(
          (e) => _ListItemCard(
            title: e.degree,
            subtitle: e.institution,
            trailing: e.year,
            onEdit: () async {
              final result =
                  await showEducationDialog(context, existing: e);
              if (result != null) notifier.updateEducation(result);
            },
            onDelete: () => notifier.removeEducation(e.id),
          ),
        ),
        _AddButton(
          label: 'Add Education',
          onTap: () async {
            final result = await showEducationDialog(context);
            if (result != null) notifier.addEducation(result);
          },
        ),
      ],
    );
  }
}

// ── Experience section ────────────────────────────────────────────────────────

class _ExperienceSection extends ConsumerWidget {
  final ProfileEditState editState;
  const _ExperienceSection({required this.editState});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(profileEditProvider.notifier);
    return Column(
      children: [
        ...editState.experience.map(
          (e) => _ListItemCard(
            title: e.role,
            subtitle: e.company,
            trailing: e.duration,
            description: e.description.isNotEmpty ? e.description : null,
            onEdit: () async {
              final result =
                  await showExperienceDialog(context, existing: e);
              if (result != null) notifier.updateExperience(result);
            },
            onDelete: () => notifier.removeExperience(e.id),
          ),
        ),
        _AddButton(
          label: 'Add Experience',
          onTap: () async {
            final result = await showExperienceDialog(context);
            if (result != null) notifier.addExperience(result);
          },
        ),
      ],
    );
  }
}

// ── Certifications section ────────────────────────────────────────────────────

class _CertificationsSection extends ConsumerWidget {
  final ProfileEditState editState;
  const _CertificationsSection({required this.editState});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(profileEditProvider.notifier);
    return Column(
      children: [
        ...editState.certifications.map(
          (c) => _ListItemCard(
            title: c.name,
            subtitle: c.issuer,
            trailing: c.year,
            onEdit: () async {
              final result =
                  await showCertificationDialog(context, existing: c);
              if (result != null) notifier.updateCertification(result);
            },
            onDelete: () => notifier.removeCertification(c.id),
          ),
        ),
        _AddButton(
          label: 'Add Certification',
          onTap: () async {
            final result = await showCertificationDialog(context);
            if (result != null) notifier.addCertification(result);
          },
        ),
      ],
    );
  }
}

// ── Shared widgets ────────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget child;

  const _SectionCard({
    required this.icon,
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: AppColors.bronze, size: 20),
                const SizedBox(width: 10),
                Text(title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: AppColors.navy,
                      fontWeight: FontWeight.w600,
                    )),
              ],
            ),
            const Divider(height: 24),
            child,
          ],
        ),
      ),
    );
  }
}

class _ListItemCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? trailing;
  final String? description;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ListItemCard({
    required this.title,
    required this.subtitle,
    this.trailing,
    this.description,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.inputBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: theme.textTheme.titleMedium?.copyWith(fontSize: 14)),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    )),
                if (trailing != null) ...[
                  const SizedBox(height: 2),
                  Text(trailing!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.bronze,
                        fontWeight: FontWeight.w500,
                      )),
                ],
                if (description != null) ...[
                  const SizedBox(height: 4),
                  Text(description!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall),
                ],
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.edit_outlined,
                    size: 18, color: AppColors.bronze),
                onPressed: onEdit,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                visualDensity: VisualDensity.compact,
              ),
              const SizedBox(width: 4),
              IconButton(
                icon: const Icon(Icons.delete_outline,
                    size: 18, color: AppColors.error),
                onPressed: onDelete,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AddButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _AddButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(
            color: AppColors.bronze.withValues(alpha: 0.5),
            style: BorderStyle.solid,
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.add, color: AppColors.bronze, size: 18),
            const SizedBox(width: 6),
            Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.bronze,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Chips editor ──────────────────────────────────────────────────────────────

class _ChipsEditor extends StatefulWidget {
  final List<String> items;
  final String hint;
  final ValueChanged<List<String>> onChanged;

  const _ChipsEditor({
    required this.items,
    required this.hint,
    required this.onChanged,
  });

  @override
  State<_ChipsEditor> createState() => _ChipsEditorState();
}

class _ChipsEditorState extends State<_ChipsEditor> {
  final _controller = TextEditingController();
  late List<String> _items;

  @override
  void initState() {
    super.initState();
    _items = List.from(widget.items);
  }

  @override
  void didUpdateWidget(_ChipsEditor old) {
    super.didUpdateWidget(old);
    if (old.items != widget.items) {
      _items = List.from(widget.items);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _add() {
    final text = _controller.text.trim();
    if (text.isEmpty || _items.contains(text)) {
      _controller.clear();
      return;
    }
    setState(() {
      _items = [..._items, text];
      _controller.clear();
    });
    widget.onChanged(_items);
  }

  void _remove(String item) {
    setState(() => _items = _items.where((i) => i != item).toList());
    widget.onChanged(_items);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _add(),
                style: Theme.of(context).textTheme.bodyMedium,
                decoration: InputDecoration(
                  hintText: widget.hint,
                  hintStyle: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide:
                        const BorderSide(color: AppColors.inputBorder),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide:
                        const BorderSide(color: AppColors.inputBorder),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide:
                        const BorderSide(color: AppColors.bronze, width: 1.5),
                  ),
                  filled: true,
                  fillColor: AppColors.inputFill,
                ),
              ),
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: _add,
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.bronze,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.add, color: AppColors.white, size: 22),
              ),
            ),
          ],
        ),
        if (_items.isNotEmpty) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _items
                .map(
                  (item) => Chip(
                    label: Text(item,
                        style: const TextStyle(
                            color: AppColors.navy, fontSize: 13)),
                    backgroundColor:
                        AppColors.bronze.withValues(alpha: 0.1),
                    side: BorderSide(
                        color: AppColors.bronze.withValues(alpha: 0.3)),
                    deleteIconColor: AppColors.navy,
                    onDeleted: () => _remove(item),
                    materialTapTargetSize:
                        MaterialTapTargetSize.shrinkWrap,
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                  ),
                )
                .toList(),
          ),
        ],
      ],
    );
  }
}

// ── Read-only field ───────────────────────────────────────────────────────────

class _ReadOnlyField extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _ReadOnlyField({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.inputBorder),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.textSecondary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: AppColors.textSecondary)),
                const SizedBox(height: 2),
                Text(value,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: AppColors.navy.withValues(alpha: 0.6),
                    )),
              ],
            ),
          ),
          const Icon(Icons.lock_outline,
              size: 14, color: AppColors.textSecondary),
        ],
      ),
    );
  }
}
