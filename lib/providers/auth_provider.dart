import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/services/api_client.dart';
import '../core/services/auth_service.dart';
import '../core/repositories/auth_repository.dart';
import '../core/errors/api_error_model.dart';
import '../models/user_model.dart';

final apiClientProvider = Provider<ApiClient>((ref) => ApiClient());

final authServiceProvider = Provider<AuthService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return AuthService(apiClient: apiClient);
});

final authRepositoryProvider = Provider<IAuthRepository>((ref) {
  final authService = ref.watch(authServiceProvider);
  return AuthRepository(authService);
});

class AuthState {
  final bool isLoading;
  final bool isInitialized;
  final UserModel? userModel;
  final String? errorMessage;
  final String? phone;
  final bool otpSent;

  AuthState({
    this.isLoading = false,
    this.isInitialized = false,
    this.userModel,
    this.errorMessage,
    this.phone,
    this.otpSent = false,
  });

  bool get isAuthenticated => userModel != null;

  AuthState copyWith({
    bool? isLoading,
    bool? isInitialized,
    UserModel? userModel,
    String? errorMessage,
    String? phone,
    bool? otpSent,
    bool clearUser = false,
    bool clearError = false,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      isInitialized: isInitialized ?? this.isInitialized,
      userModel: clearUser ? null : (userModel ?? this.userModel),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      phone: phone ?? this.phone,
      otpSent: otpSent ?? this.otpSent,
    );
  }
}

class AuthNotifier extends Notifier<AuthState> {
  late final IAuthRepository _authRepository;

  @override
  AuthState build() {
    _authRepository = ref.watch(authRepositoryProvider);
    restoreSession();
    return AuthState();
  }

  // Restore authenticated session on app boot
  Future<void> restoreSession() async {
    state = state.copyWith(isLoading: true);
    try {
      final user = await _authRepository.getCurrentUser();
      if (user != null) {
        state = state.copyWith(
          isLoading: false,
          isInitialized: true,
          userModel: user,
          clearError: true,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          isInitialized: true,
          clearUser: true,
          clearError: true,
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        isInitialized: true,
        clearUser: true,
        clearError: true,
      );
    }
  }

  void clearError() {
    if (state.errorMessage != null) {
      state = state.copyWith(clearError: true);
    }
  }

  // Email & Password Login
  Future<bool> loginWithEmail(String email, String password) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final response = await _authRepository.signInWithEmail(email, password);
      state = state.copyWith(
        isLoading: false,
        userModel: response.user,
        clearError: true,
      );
      return true;
    } on ApiErrorModel catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.userFriendlyMessage,
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Unable to sign in. Please try again.',
      );
      return false;
    }
  }

  // Register / Create Account
  Future<bool> createAccount({
    required String name,
    required String email,
    required String password,
    required String confirmPassword,
    String phone = '',
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final response = await _authRepository.registerWithEmail(
        name: name,
        email: email,
        password: password,
        confirmPassword: confirmPassword,
        phone: phone,
      );
      state = state.copyWith(
        isLoading: false,
        userModel: response.user,
        clearError: true,
      );
      return true;
    } on ApiErrorModel catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.userFriendlyMessage,
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Account creation failed. Please try again.',
      );
      return false;
    }
  }

  // Google Sign-In
  Future<bool> loginWithGoogle({
    required String idToken,
    String? email,
    String? name,
    String? photoUrl,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final response = await _authRepository.signInWithGoogle(
        idToken: idToken,
        email: email,
        name: name,
        photoUrl: photoUrl,
      );
      state = state.copyWith(
        isLoading: false,
        userModel: response.user,
        clearError: true,
      );
      return true;
    } on ApiErrorModel catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.userFriendlyMessage,
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Google authentication failed. Please try again.',
      );
      return false;
    }
  }

  // Send Phone OTP
  Future<bool> sendPhoneOtp(String phone) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _authRepository.sendPhoneOtp(phone);
      state = state.copyWith(
        isLoading: false,
        phone: phone,
        otpSent: true,
        clearError: true,
      );
      return true;
    } on ApiErrorModel catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.userFriendlyMessage,
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to send OTP code. Please try again.',
      );
      return false;
    }
  }

  // Verify Phone OTP
  Future<bool> verifyPhoneOtp(String phone, String otp) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final response = await _authRepository.verifyPhoneOtp(phone, otp);
      state = state.copyWith(
        isLoading: false,
        userModel: response.user,
        clearError: true,
      );
      return true;
    } on ApiErrorModel catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.userFriendlyMessage,
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Invalid OTP code. Please try again.',
      );
      return false;
    }
  }

  // Send Forgot Password Request
  Future<bool> sendForgotPasswordEmail(String email) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _authRepository.sendForgotPasswordEmail(email);
      state = state.copyWith(isLoading: false, clearError: true);
      return true;
    } on ApiErrorModel catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.userFriendlyMessage,
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to send password reset request.',
      );
      return false;
    }
  }

  // Reset Password
  Future<bool> resetPassword({
    required String token,
    required String password,
    required String confirmPassword,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _authRepository.resetPassword(
        token: token,
        password: password,
        confirmPassword: confirmPassword,
      );
      state = state.copyWith(isLoading: false, clearError: true);
      return true;
    } on ApiErrorModel catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.userFriendlyMessage,
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Password reset failed. Please try again.',
      );
      return false;
    }
  }

  // Toggle Account Activation Status (Admin function)
  Future<void> toggleAccountActivation(String userId, bool isActive) async {
    try {
      final updatedUser = await _authRepository.toggleAccountActivation(userId, isActive);
      if (state.userModel?.uid == userId) {
        state = state.copyWith(userModel: updatedUser);
      }
    } catch (e) {
      debugPrint('Error updating activation status: $e');
    }
  }

  // Logout
  Future<void> logout() async {
    state = state.copyWith(isLoading: true);
    try {
      await _authRepository.signOut();
    } catch (e) {
      debugPrint('Logout warning: $e');
    } finally {
      state = AuthState(
        isInitialized: true,
        isLoading: false,
      );
    }
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);
