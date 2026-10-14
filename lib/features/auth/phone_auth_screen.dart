import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/custom_button.dart';
import '../../core/widgets/custom_text_field.dart';
import '../../providers/auth_provider.dart';

class PhoneAuthScreen extends ConsumerStatefulWidget {
  const PhoneAuthScreen({super.key});

  @override
  ConsumerState<PhoneAuthScreen> createState() => _PhoneAuthScreenState();
}

class _PhoneAuthScreenState extends ConsumerState<PhoneAuthScreen> {
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  bool _codeSent = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  void _handleSendOtp() async {
    final phone = _phoneController.text.trim();
    if (phone.isNotEmpty) {
      final success = await ref.read(authProvider.notifier).sendPhoneOtp(phone);
      if (mounted && success) {
        setState(() {
          _codeSent = true;
        });
      }
    }
  }

  void _handleVerifyOtp() async {
    final phone = _phoneController.text.trim();
    final code = _otpController.text.trim();
    if (code.isNotEmpty && phone.isNotEmpty) {
      final success = await ref.read(authProvider.notifier).verifyPhoneOtp(phone, code);
      if (mounted && success) {
        context.go('/home');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Phone Authentication'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _codeSent ? 'Enter OTP Code' : 'Phone Sign In',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _codeSent
                    ? 'Enter the 6-digit code sent to ${_phoneController.text}'
                    : 'Enter your mobile number with country code to receive OTP.',
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 32),
              if (authState.errorMessage != null && authState.errorMessage!.isNotEmpty) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    authState.errorMessage!,
                    style: const TextStyle(
                      color: AppColors.error,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
              if (!_codeSent) ...[
                CustomTextField(
                  label: 'Phone Number',
                  hint: '+919876543210',
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  prefixIcon: Icons.phone,
                  validator: Validators.validatePhone,
                  onChanged: (_) => ref.read(authProvider.notifier).clearError(),
                ),
                const SizedBox(height: 32),
                CustomButton(
                  text: authState.isLoading ? 'Sending OTP...' : 'Send Verification Code',
                  isLoading: authState.isLoading,
                  onPressed: authState.isLoading ? null : _handleSendOtp,
                ),
              ] else ...[
                CustomTextField(
                  label: 'SMS Code',
                  hint: '123456',
                  controller: _otpController,
                  keyboardType: TextInputType.number,
                  prefixIcon: Icons.pin,
                  onChanged: (_) => ref.read(authProvider.notifier).clearError(),
                ),
                const SizedBox(height: 32),
                CustomButton(
                  text: authState.isLoading ? 'Verifying...' : 'Verify & Sign In',
                  isLoading: authState.isLoading,
                  onPressed: authState.isLoading ? null : _handleVerifyOtp,
                ),
                const SizedBox(height: 16),
                Center(
                  child: TextButton(
                    onPressed: () {
                      ref.read(authProvider.notifier).clearError();
                      setState(() {
                        _codeSent = false;
                      });
                    },
                    child: const Text(
                      'Resend Code / Change Number',
                      style: TextStyle(color: AppColors.primary),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
