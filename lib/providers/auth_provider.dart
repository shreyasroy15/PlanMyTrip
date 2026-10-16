import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
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
  final String? emailForOtp;
  final bool otpSent;
  final bool rememberMe;
  final String? savedEmail;

  AuthState({
    this.isLoading = false,
    this.isInitialized = false,
    this.userModel,
    this.errorMessage,
    this.phone,
    this.emailForOtp,
    this.otpSent = false,
    this.rememberMe = false,
    this.savedEmail,
  });

  bool get isAuthenticated => userModel != null;

  AuthState copyWith({
    bool? isLoading,
    bool? isInitialized,
    UserModel? userModel,
    String? errorMessage,
    String? phone,
    String? emailForOtp,
    bool? otpSent,
    bool? rememberMe,
    String? savedEmail,
    bool clearUser = false,
    bool clearError = false,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      isInitialized: isInitialized ?? this.isInitialized,
      userModel: clearUser ? null : (userModel ?? this.userModel),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      phone: phone ?? this.phone,
      emailForOtp: emailForOtp ?? this.emailForOtp,
      otpSent: otpSent ?? this.otpSent,
      rememberMe: rememberMe ?? this.rememberMe,
      savedEmail: savedEmail ?? this.savedEmail,
    );
  }
}

class AuthNotifier extends Notifier<AuthState> {
  late final IAuthRepository _authRepository;
  bool _googleInitialized = false;

  Future<void> _ensureGoogleInitialized() async {
    if (!_googleInitialized) {
      try {
        await GoogleSignIn.instance.initialize();
        _googleInitialized = true;
      } catch (e) {
        debugPrint('Google Sign-In initialization notice: $e');
      }
    }
  }

  @override
  AuthState build() {
    _authRepository = ref.watch(authRepositoryProvider);
    Future.microtask(() => restoreSession());
    return AuthState();
  }

  // Restore authenticated session on app boot
  Future<void> restoreSession() async {
    state = state.copyWith(isLoading: true);
    try {
      final rememberMe = await _authRepository.getRememberMe();
      final savedEmail = await _authRepository.getSavedEmail();
      final user = await _authRepository.getCurrentUser();

      if (user != null) {
        state = state.copyWith(
          isLoading: false,
          isInitialized: true,
          userModel: user,
          rememberMe: rememberMe,
          savedEmail: savedEmail,
          clearError: true,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          isInitialized: true,
          rememberMe: rememberMe,
          savedEmail: savedEmail,
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
  Future<bool> loginWithEmail(String email, String password, {bool rememberMe = false}) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final response = await _authRepository.signInWithEmail(
        email,
        password,
        rememberMe: rememberMe,
      );
      state = state.copyWith(
        isLoading: false,
        userModel: response.user,
        rememberMe: rememberMe,
        savedEmail: rememberMe ? email : null,
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
        errorMessage: 'Unable to sign in. Please check your credentials.',
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

  // Real Google Sign-In Flow
  Future<bool> loginWithGoogle() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _ensureGoogleInitialized();
      final GoogleSignInAccount googleUser = await GoogleSignIn.instance.authenticate();
      final String? idToken = googleUser.authentication.idToken;

      if (idToken == null || idToken.isEmpty) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Could not obtain Google authentication token. Please verify OAuth client configuration.',
        );
        return false;
      }

      final response = await _authRepository.signInWithGoogle(
        idToken: idToken,
        email: googleUser.email,
        name: googleUser.displayName,
        photoUrl: googleUser.photoUrl,
      );

      state = state.copyWith(
        isLoading: false,
        userModel: response.user,
        clearError: true,
      );
      return true;
    } on GoogleSignInException catch (e) {
      state = state.copyWith(isLoading: false);
      if (e.code == GoogleSignInExceptionCode.canceled) {
        return false;
      }
      state = state.copyWith(
        errorMessage: 'Google Sign-In error: ${e.description ?? e.code.name}',
      );
      return false;
    } on ApiErrorModel catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.userFriendlyMessage,
      );
      return false;
    } catch (e) {
      debugPrint('Google Sign-In Error: $e');
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Google Sign-In failed or is not configured for this platform.',
      );
      return false;
    }
  }

  // Real Sign in with Apple Flow
  Future<bool> loginWithApple() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final rawNonce = generateRandomString(32);
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: rawNonce,
      );

      final identityToken = credential.identityToken;
      if (identityToken == null || identityToken.isEmpty) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Could not obtain Apple identity token.',
        );
        return false;
      }

      final name = [credential.givenName, credential.familyName]
          .where((s) => s != null && s.isNotEmpty)
          .join(' ');

      final response = await _authRepository.signInWithApple(
        identityToken: identityToken,
        rawNonce: rawNonce,
        name: name.isNotEmpty ? name : null,
      );

      state = state.copyWith(
        isLoading: false,
        userModel: response.user,
        clearError: true,
      );
      return true;
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) {
        state = state.copyWith(isLoading: false);
        return false;
      }
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Apple Sign-In authorization failed: ${e.message}',
      );
      return false;
    } on ApiErrorModel catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.userFriendlyMessage,
      );
      return false;
    } catch (e) {
      debugPrint('Apple Sign-In Error: $e');
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Sign in with Apple is only supported on configured Apple platforms.',
      );
      return false;
    }
  }

  // Send Email OTP
  Future<bool> sendEmailOtp(String email, {String purpose = 'login'}) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _authRepository.sendEmailOtp(email, purpose: purpose);
      state = state.copyWith(
        isLoading: false,
        emailForOtp: email,
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
        errorMessage: 'Failed to send email verification code.',
      );
      return false;
    }
  }

  // Verify Email OTP
  Future<bool> verifyEmailOtp(String email, String otp, {String purpose = 'login'}) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final response = await _authRepository.verifyEmailOtp(email, otp, purpose: purpose);
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
        errorMessage: 'Invalid verification code. Please try again.',
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
        errorMessage: 'Failed to send SMS code. Please try again.',
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

  // Change Password (Authenticated)
  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final response = await _authRepository.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
        confirmPassword: confirmPassword,
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
        errorMessage: 'Password change failed. Please verify your current password.',
      );
      return false;
    }
  }

  // Update Display Name
  Future<bool> updateDisplayName(String name) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final updatedUser = await _authRepository.updateDisplayName(name);
      state = state.copyWith(
        isLoading: false,
        userModel: updatedUser,
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
        errorMessage: 'Failed to update name. Please try again.',
      );
      return false;
    }
  }

  // Verify Email with Token Link
  Future<bool> verifyEmail(String token) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final updatedUser = await _authRepository.verifyEmail(token);
      state = state.copyWith(
        isLoading: false,
        userModel: updatedUser,
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
        errorMessage: 'Email verification failed. The link may have expired.',
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

  // Logout (Current Device)
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

  // Logout All Devices
  Future<void> logoutAll() async {
    state = state.copyWith(isLoading: true);
    try {
      await _authRepository.signOutAll();
    } catch (e) {
      debugPrint('Logout all warning: $e');
    } finally {
      state = AuthState(
        isInitialized: true,
        isLoading: false,
      );
    }
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);

// Helper for Apple Sign In nonce generation
String generateRandomString(int length) {
  const chars = '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
  final random = DateTime.now().microsecondsSinceEpoch;
  return List.generate(length, (index) => chars[(random + index * 7) % chars.length]).join();
}
