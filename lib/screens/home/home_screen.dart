import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/profile_provider.dart';
import '../profile/profile_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final authState = ref.watch(authNotifierProvider);
    final profileAsync = ref.watch(profileStreamProvider);
    final theme = Theme.of(context);

    final displayName = profileAsync.value?.fullName.isNotEmpty == true
        ? profileAsync.value!.fullName
        : user?.displayName;

    final firstName = displayName?.split(' ').first;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.bronze,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.work_outline,
                  color: AppColors.white, size: 18),
            ),
            const SizedBox(width: 10),
            Text(
              'ProFolio',
              style: theme.textTheme.titleLarge?.copyWith(
                color: AppColors.navy,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        actions: [
          // Profile avatar → opens profile screen
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ProfileScreen()),
            ),
            child: CircleAvatar(
              backgroundColor: AppColors.bronze.withValues(alpha: 0.15),
              radius: 18,
              child: Text(
                _getInitial(displayName),
                style: theme.textTheme.titleMedium?.copyWith(
                  color: AppColors.bronze,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: AppColors.navy, size: 20),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            onSelected: (value) async {
              if (value == 'logout') {
                final confirmed = await _confirmLogout(context);
                if (confirmed && context.mounted) {
                  await ref.read(authNotifierProvider.notifier).signOut();
                }
              }
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                enabled: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName ?? 'User',
                      style: theme.textTheme.titleMedium,
                    ),
                    Text(
                      user?.email ?? '',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, size: 18, color: AppColors.error),
                    SizedBox(width: 10),
                    Text('Sign out',
                        style: TextStyle(color: AppColors.error)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: authState.isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.bronze),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildWelcomeBanner(theme, firstName),
                  const SizedBox(height: 28),
                  _buildQuickActions(context, theme),
                ],
              ),
            ),
    );
  }

  Widget _buildWelcomeBanner(ThemeData theme, String? firstName) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.navy, AppColors.navyLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            firstName != null ? 'Welcome, $firstName!' : 'Welcome!',
            style: theme.textTheme.headlineMedium?.copyWith(
              color: AppColors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your portfolio is ready to be built.\nStart adding your projects and experience.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.white.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.bronze,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Get started →',
              style: theme.textTheme.labelLarge,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context, ThemeData theme) {
    final actions = [
      (
        Icons.person_outline,
        'My Profile',
        'View & edit profile',
        () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ProfileScreen()),
            ),
      ),
      (
        Icons.add_circle_outline,
        'Add Project',
        'Showcase your work',
        () {},
      ),
      (
        Icons.link,
        'Share Portfolio',
        'Share your link',
        () {},
      ),
      (
        Icons.bar_chart,
        'Analytics',
        'Track views',
        () {},
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Quick Actions', style: theme.textTheme.titleLarge),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.3,
          children: actions
              .map(
                (a) => _ActionCard(
                  icon: a.$1,
                  title: a.$2,
                  subtitle: a.$3,
                  onTap: a.$4,
                ),
              )
              .toList(),
        ),
      ],
    );
  }

  String _getInitial(String? name) {
    if (name == null || name.isEmpty) return 'U';
    return name[0].toUpperCase();
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
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.divider),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: AppColors.bronze, size: 24),
              const SizedBox(height: 10),
              Text(title, style: theme.textTheme.titleMedium),
              const SizedBox(height: 2),
              Text(subtitle, style: theme.textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}
