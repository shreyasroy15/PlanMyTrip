import 'dart:async';
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
  int _selectedTab = 0; // 0 for Email OTP, 1 for Phone OTP
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  bool _codeSent = false;
  int _resendCountdown = 0;
  Timer? _timer;

  @override
  void dispose() {
    _emailController.dispose();
    _phoneController.dispose();
    _otpController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _startCountdown() {
    _resendCountdown = 60;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendCountdown > 0) {
        setState(() {
          _resendCountdown--;
        });
      } else {
        timer.cancel();
      }
    });
  }

  void _handleSendOtp() async {
    ref.read(authProvider.notifier).clearError();

    if (_selectedTab == 0) {
      // Email OTP
      final email = _emailController.text.trim();
      final err = Validators.validateEmail(email);
      if (err != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
        return;
      }

      final success = await ref.read(authProvider.notifier).sendEmailOtp(email);
      if (mounted && success) {
        setState(() {
          _codeSent = true;
        });
        _startCountdown();
      }
    } else {
      // Phone OTP
      final phone = _phoneController.text.trim();
      if (phone.length < 6) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a valid phone number with country code')),
        );
        return;
      }

      final success = await ref.read(authProvider.notifier).sendPhoneOtp(phone);
      if (mounted && success) {
        setState(() {
          _codeSent = true;
        });
        _startCountdown();
      }
    }
  }

  void _handleVerifyOtp() async {
    final code = _otpController.text.trim();
    if (code.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter the complete 6-digit verification code')),
      );
      return;
    }

    bool success = false;
    if (_selectedTab == 0) {
      final email = _emailController.text.trim();
      success = await ref.read(authProvider.notifier).verifyEmailOtp(email, code);
    } else {
      final phone = _phoneController.text.trim();
      success = await ref.read(authProvider.notifier).verifyPhoneOtp(phone, code);
    }

    if (mounted && success) {
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final targetLabel = _selectedTab == 0 ? _emailController.text : _phoneController.text;

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
          'One-Time Code Sign In',
          style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w600),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tab Selector (Email vs Phone) if code not sent yet
                  if (!_codeSent) ...[
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.glassBorder),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                ref.read(authProvider.notifier).clearError();
                                setState(() => _selectedTab = 0);
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  color: _selectedTab == 0 ? AppColors.primary : Colors.transparent,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  'Email OTP',
                                  style: TextStyle(
                                    color: _selectedTab == 0 ? Colors.white : AppColors.textSecondary,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                ref.read(authProvider.notifier).clearError();
                                setState(() => _selectedTab = 1);
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  color: _selectedTab == 1 ? AppColors.primary : Colors.transparent,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  'Phone SMS OTP',
                                  style: TextStyle(
                                    color: _selectedTab == 1 ? Colors.white : AppColors.textSecondary,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  Text(
                    _codeSent ? 'Enter Verification Code' : (_selectedTab == 0 ? 'Email Sign In' : 'Phone Sign In'),
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _codeSent
                        ? 'We sent a 6-digit code to $targetLabel. Please enter it below.'
                        : (_selectedTab == 0
                            ? 'Enter your registered email address to receive an instant verification code.'
                            : 'Enter your phone number with country code to receive an SMS code.'),
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Error Message Banner
                  if (authState.errorMessage != null && authState.errorMessage!.isNotEmpty) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.error.withValues(alpha: 0.35)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, color: AppColors.error, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              authState.errorMessage!,
                              style: const TextStyle(
                                color: AppColors.error,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  if (!_codeSent) ...[
                    if (_selectedTab == 0) ...[
                      CustomTextField(
                        label: 'Email Address',
                        hint: 'name@example.com',
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        prefixIcon: Icons.email_outlined,
                        validator: Validators.validateEmail,
                        enabled: !authState.isLoading,
                        onChanged: (_) => ref.read(authProvider.notifier).clearError(),
                      ),
                    ] else ...[
                      CustomTextField(
                        label: 'Mobile Phone Number',
                        hint: '+1234567890',
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        prefixIcon: Icons.phone_outlined,
                        enabled: !authState.isLoading,
                        onChanged: (_) => ref.read(authProvider.notifier).clearError(),
                      ),
                    ],
                    const SizedBox(height: 28),
                    SizedBox(
                      width: double.infinity,
                      child: CustomButton(
                        text: authState.isLoading ? 'Sending Code...' : 'Send Verification Code',
                        isLoading: authState.isLoading,
                        onPressed: authState.isLoading ? null : _handleSendOtp,
                      ),
                    ),
                  ] else ...[
                    CustomTextField(
                      label: '6-Digit Verification Code',
                      hint: '123456',
                      controller: _otpController,
                      keyboardType: TextInputType.number,
                      prefixIcon: Icons.pin_outlined,
                      enabled: !authState.isLoading,
                      onChanged: (_) => ref.read(authProvider.notifier).clearError(),
                    ),
                    const SizedBox(height: 28),
                    SizedBox(
                      width: double.infinity,
                      child: CustomButton(
                        text: authState.isLoading ? 'Verifying...' : 'Verify & Continue',
                        isLoading: authState.isLoading,
                        onPressed: authState.isLoading ? null : _handleVerifyOtp,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton(
                          onPressed: _resendCountdown > 0 || authState.isLoading ? null : _handleSendOtp,
                          child: Text(
                            _resendCountdown > 0 ? 'Resend in ${_resendCountdown}s' : 'Resend Code',
                            style: TextStyle(
                              color: _resendCountdown > 0 ? AppColors.textMuted : AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            ref.read(authProvider.notifier).clearError();
                            setState(() {
                              _codeSent = false;
                              _otpController.clear();
                              _timer?.cancel();
                            });
                          },
                          child: const Text(
                            'Change Destination',
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
