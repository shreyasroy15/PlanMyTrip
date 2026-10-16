import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/custom_button.dart';
import '../../core/widgets/custom_text_field.dart';
import '../../providers/auth_provider.dart';

class ResetPasswordScreen extends ConsumerStatefulWidget {
  final String? initialToken;
  final String? email;

  const ResetPasswordScreen({
    super.key,
    this.initialToken,
    this.email,
  });

  @override
  ConsumerState<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _tokenController;
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void initState() {
    super.initState();
    _tokenController = TextEditingController(text: widget.initialToken ?? '');
  }

  @override
  void dispose() {
    _tokenController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _handleReset() async {
    if (_formKey.currentState!.validate()) {
      final success = await ref.read(authProvider.notifier).resetPassword(
            token: _tokenController.text.trim(),
            password: _newPasswordController.text.trim(),
            confirmPassword: _confirmPasswordController.text.trim(),
          );
      if (mounted && success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password updated successfully! Please log in with your new password.'),
            backgroundColor: AppColors.success,
            duration: Duration(seconds: 4),
          ),
        );
        context.go('/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.textPrimary, size: 20),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Set New Password',
          style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w600),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Create New Password',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Your new password must be at least 6 characters long and different from previous passwords.',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 28),

                    if (authState.errorMessage != null && authState.errorMessage!.isNotEmpty) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.error.withValues(alpha: 0.35)),
                        ),
                        child: Text(
                          authState.errorMessage!,
                          style: const TextStyle(color: AppColors.error, fontSize: 13),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    CustomTextField(
                      label: 'Reset Security Token',
                      hint: 'Paste token from your email',
                      controller: _tokenController,
                      prefixIcon: Icons.vpn_key_outlined,
                      validator: (val) => Validators.validateRequired(val, 'Reset token'),
                      enabled: !authState.isLoading,
                      onChanged: (_) => ref.read(authProvider.notifier).clearError(),
                    ),
                    const SizedBox(height: 18),

                    CustomTextField(
                      label: 'New Password',
                      hint: '••••••••',
                      controller: _newPasswordController,
                      isPassword: _obscurePassword,
                      prefixIcon: Icons.lock_outline,
                      validator: Validators.validatePassword,
                      enabled: !authState.isLoading,
                      onChanged: (_) => ref.read(authProvider.notifier).clearError(),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility_off : Icons.visibility,
                          color: AppColors.textSecondary,
                          size: 20,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                    ),
                    const SizedBox(height: 18),

                    CustomTextField(
                      label: 'Confirm New Password',
                      hint: '••••••••',
                      controller: _confirmPasswordController,
                      isPassword: _obscureConfirmPassword,
                      prefixIcon: Icons.lock_clock_outlined,
                      validator: (val) {
                        if (val == null || val.isEmpty) return 'Please confirm your new password';
                        if (val != _newPasswordController.text) return 'Passwords do not match';
                        return null;
                      },
                      enabled: !authState.isLoading,
                      onChanged: (_) => ref.read(authProvider.notifier).clearError(),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                          color: AppColors.textSecondary,
                          size: 20,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscureConfirmPassword = !_obscureConfirmPassword;
                          });
                        },
                      ),
                    ),
                    const SizedBox(height: 32),

                    SizedBox(
                      width: double.infinity,
                      child: CustomButton(
                        text: authState.isLoading ? 'Updating Password...' : 'Update Password & Sign In',
                        isLoading: authState.isLoading,
                        onPressed: authState.isLoading ? null : _handleReset,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
