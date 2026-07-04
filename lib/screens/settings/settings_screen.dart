import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/page_transitions.dart';
import '../../core/utils/validators.dart';
import '../../models/settings_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/auth_text_field.dart';
import '../../widgets/error_banner.dart';
import '../../widgets/primary_button.dart';
import '../profile/profile_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final settingsAsync = ref.watch(accountSettingsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Text('Settings', style: theme.textTheme.titleLarge),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _SectionLabel('Account'),
          _SettingsTile(
            icon: Icons.person_outline,
            title: 'Edit Profile',
            subtitle: 'Update your personal & professional details',
            onTap: () => pushSlideFade(context, const ProfileScreen()),
          ),
          const SizedBox(height: 10),
          _SettingsTile(
            icon: Icons.lock_outline,
            title: 'Change Password',
            subtitle: 'Update your account password',
            onTap: () => _showChangePasswordSheet(context),
          ),
          const SizedBox(height: 24),
          _SectionLabel('Notification Preferences'),
          settingsAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.bronze),
                ),
              ),
            ),
            error: (e, _) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: ErrorBanner(message: 'Could not load preferences: $e'),
            ),
            data: (settings) => _NotificationPrefsCard(prefs: settings.notificationPrefs),
          ),
          const SizedBox(height: 24),
          _SectionLabel('Privacy'),
          settingsAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (_, _) => const SizedBox.shrink(),
            data: (settings) => _PrivacyCard(isPublic: settings.isPublic),
          ),
          const SizedBox(height: 24),
          _SectionLabel('Session'),
          _SettingsTile(
            icon: Icons.logout,
            title: 'Log out',
            subtitle: 'Sign out of your ProFolio account',
            iconColor: AppColors.error,
            onTap: () async {
              final confirmed = await _confirmLogout(context);
              if (confirmed && context.mounted) {
                await ref.read(authNotifierProvider.notifier).signOut();
              }
            },
          ),
        ],
      ),
    );
  }

  Future<bool> _confirmLogout(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Sign out', style: Theme.of(ctx).textTheme.titleLarge),
        content: Text(
          'Are you sure you want to sign out?',
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
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  void _showChangePasswordSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _ChangePasswordSheet(),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, left: 4),
      child: Text(
        label,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppColors.bronze),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Color? iconColor;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.divider),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Icon(icon, color: iconColor ?? AppColors.bronze, size: 22),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: theme.textTheme.titleMedium),
                    const SizedBox(height: 2),
                    Text(subtitle, style: theme.textTheme.bodySmall),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.textSecondary, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _NotificationPrefsCard extends ConsumerWidget {
  final NotificationPrefs prefs;
  const _NotificationPrefsCard({required this.prefs});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: [
          _PrefSwitch(
            label: 'Job alerts',
            subtitle: 'New jobs matching your skills',
            value: prefs.jobAlerts,
            onChanged: (v) => ref
                .read(settingsActionsProvider.notifier)
                .updateNotificationPrefs(prefs.copyWith(jobAlerts: v)),
          ),
          const Divider(height: 1),
          _PrefSwitch(
            label: 'Application status updates',
            subtitle: 'Progress on jobs you\'ve applied to',
            value: prefs.statusUpdates,
            onChanged: (v) => ref
                .read(settingsActionsProvider.notifier)
                .updateNotificationPrefs(prefs.copyWith(statusUpdates: v)),
          ),
          const Divider(height: 1),
          _PrefSwitch(
            label: 'Recommendations',
            subtitle: 'High-match job suggestions',
            value: prefs.recommendations,
            onChanged: (v) => ref
                .read(settingsActionsProvider.notifier)
                .updateNotificationPrefs(prefs.copyWith(recommendations: v)),
          ),
        ],
      ),
    );
  }
}

class _PrivacyCard extends ConsumerWidget {
  final bool isPublic;
  const _PrivacyCard({required this.isPublic});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: _PrefSwitch(
        label: 'Public profile',
        subtitle: 'Allow recruiters to discover your profile',
        value: isPublic,
        onChanged: (v) =>
            ref.read(settingsActionsProvider.notifier).updateAccountVisibility(v),
      ),
    );
  }
}

class _PrefSwitch extends StatelessWidget {
  final String label;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _PrefSwitch({
    required this.label,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: theme.textTheme.bodyLarge),
                Text(subtitle, style: theme.textTheme.bodySmall),
              ],
            ),
          ),
          Switch(
            value: value,
            activeThumbColor: AppColors.bronze,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _ChangePasswordSheet extends ConsumerStatefulWidget {
  const _ChangePasswordSheet();

  @override
  ConsumerState<_ChangePasswordSheet> createState() => _ChangePasswordSheetState();
}

class _ChangePasswordSheetState extends ConsumerState<_ChangePasswordSheet> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final success = await ref
        .read(settingsActionsProvider.notifier)
        .changePassword(_passwordController.text);
    if (success && mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(settingsActionsProvider);
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
        decoration: const BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Change Password', style: theme.textTheme.headlineMedium),
              const SizedBox(height: 20),
              if (state.error != null) ...[
                ErrorBanner(message: state.error!),
                const SizedBox(height: 16),
              ],
              AuthTextField(
                controller: _passwordController,
                label: 'New password',
                isPassword: true,
                prefixIcon: Icons.lock_outline,
                validator: Validators.password,
              ),
              const SizedBox(height: 14),
              AuthTextField(
                controller: _confirmController,
                label: 'Confirm new password',
                isPassword: true,
                prefixIcon: Icons.lock_outline,
                textInputAction: TextInputAction.done,
                validator: (v) =>
                    Validators.confirmPassword(v, _passwordController.text),
                onSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: 24),
              PrimaryButton(
                label: 'Update Password',
                isLoading: state.isLoading,
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
