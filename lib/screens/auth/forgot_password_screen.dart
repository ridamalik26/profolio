import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/validators.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/auth_text_field.dart';
import '../../widgets/error_banner.dart';
import '../../widgets/primary_button.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    await ref.read(authNotifierProvider.notifier).sendPasswordReset(
          email: _emailController.text,
        );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),

              // Back button
              IconButton(
                onPressed: () => Navigator.maybePop(context),
                icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                style: IconButton.styleFrom(
                  foregroundColor: AppColors.navy,
                  padding: EdgeInsets.zero,
                ),
              ),

              const SizedBox(height: 24),

              // Header
              _buildHeader(theme),

              const SizedBox(height: 36),

              // Success state
              if (authState.hasSuccess)
                _buildSuccessCard(theme, authState.successMessage!)
              else ...[
                // Error banner
                if (authState.hasError) ...[
                  ErrorBanner(
                    message: authState.error!,
                    onDismiss: () =>
                        ref.read(authNotifierProvider.notifier).clearError(),
                  ),
                  const SizedBox(height: 20),
                ],

                // Form
                Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AuthTextField(
                        controller: _emailController,
                        label: 'Email',
                        hint: 'you@example.com',
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.done,
                        prefixIcon: Icons.email_outlined,
                        autofocus: true,
                        validator: Validators.email,
                        onSubmitted: (_) => _submit(),
                      ),
                      const SizedBox(height: 28),
                      PrimaryButton(
                        onPressed: _submit,
                        label: 'Send Reset Link',
                        isLoading: authState.isLoading,
                        icon: Icons.send_outlined,
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 32),

              // Back to login
              Center(
                child: TextButton.icon(
                  onPressed: () => Navigator.maybePop(context),
                  icon: const Icon(Icons.arrow_back, size: 16),
                  label: const Text('Back to sign in'),
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: AppColors.bronze.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(Icons.lock_reset, color: AppColors.bronze, size: 28),
        ),
        const SizedBox(height: 24),
        Text('Forgot password?', style: theme.textTheme.displayMedium),
        const SizedBox(height: 8),
        Text(
          "No worries — we'll send a reset link to your email.",
          style: theme.textTheme.bodyLarge?.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildSuccessCard(ThemeData theme, String message) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.mark_email_read_outlined,
                color: AppColors.success, size: 28),
          ),
          const SizedBox(height: 16),
          Text(
            'Email sent!',
            style: theme.textTheme.titleLarge?.copyWith(
              color: AppColors.success,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.navy,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            "Didn't receive it? Check your spam folder or try again.",
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () {
              ref.read(authNotifierProvider.notifier).clearSuccess();
              _emailController.clear();
            },
            child: const Text('Send again'),
          ),
        ],
      ),
    );
  }
}
