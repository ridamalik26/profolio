import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/validators.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/auth_text_field.dart';
import '../../widgets/error_banner.dart';
import '../../widgets/primary_button.dart';
import 'login_screen.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  final _confirmPasswordFocusNode = FocusNode();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    _confirmPasswordFocusNode.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    await ref.read(authNotifierProvider.notifier).register(
          email: _emailController.text,
          password: _passwordController.text,
          displayName: _nameController.text,
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
                      controller: _nameController,
                      label: 'Full Name',
                      hint: 'John Doe',
                      keyboardType: TextInputType.name,
                      textInputAction: TextInputAction.next,
                      prefixIcon: Icons.person_outline,
                      autofocus: true,
                      validator: Validators.displayName,
                      onSubmitted: (_) =>
                          FocusScope.of(context).requestFocus(_emailFocusNode),
                    ),
                    const SizedBox(height: 16),
                    AuthTextField(
                      controller: _emailController,
                      label: 'Email',
                      hint: 'you@example.com',
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      prefixIcon: Icons.email_outlined,
                      focusNode: _emailFocusNode,
                      validator: Validators.email,
                      onSubmitted: (_) => FocusScope.of(context)
                          .requestFocus(_passwordFocusNode),
                    ),
                    const SizedBox(height: 16),
                    AuthTextField(
                      controller: _passwordController,
                      label: 'Password',
                      hint: 'Min. 8 chars with letters & numbers',
                      isPassword: true,
                      textInputAction: TextInputAction.next,
                      prefixIcon: Icons.lock_outline,
                      focusNode: _passwordFocusNode,
                      validator: Validators.password,
                      onSubmitted: (_) => FocusScope.of(context)
                          .requestFocus(_confirmPasswordFocusNode),
                    ),
                    const SizedBox(height: 16),
                    AuthTextField(
                      controller: _confirmPasswordController,
                      label: 'Confirm Password',
                      hint: 'Re-enter your password',
                      isPassword: true,
                      textInputAction: TextInputAction.done,
                      prefixIcon: Icons.lock_outline,
                      focusNode: _confirmPasswordFocusNode,
                      validator: (value) => Validators.confirmPassword(
                        value,
                        _passwordController.text,
                      ),
                      onSubmitted: (_) => _submit(),
                    ),
                    const SizedBox(height: 12),

                    // Password hint
                    _buildPasswordHint(theme),

                    const SizedBox(height: 28),

                    PrimaryButton(
                      onPressed: _submit,
                      label: 'Create Account',
                      isLoading: authState.isLoading,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Sign in link
              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Already have an account? ',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                      ),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text('Sign in'),
                    ),
                  ],
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
        Text('Create account', style: theme.textTheme.displayMedium),
        const SizedBox(height: 8),
        Text(
          'Start building your professional portfolio',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordHint(ThemeData theme) {
    return Row(
      children: [
        const Icon(Icons.info_outline, size: 14, color: AppColors.textSecondary),
        const SizedBox(width: 6),
        Text(
          'At least 8 characters with letters and numbers',
          style: theme.textTheme.bodySmall,
        ),
      ],
    );
  }
}
