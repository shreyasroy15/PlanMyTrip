import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planmytrip/core/repositories/auth_repository.dart';
import 'package:planmytrip/features/auth/login_screen.dart';
import 'package:planmytrip/features/auth/create_account_screen.dart';
import 'package:planmytrip/features/auth/forgot_password_screen.dart';
import 'package:planmytrip/features/auth/reset_password_screen.dart';
import 'package:planmytrip/features/auth/phone_auth_screen.dart';
import 'package:planmytrip/features/profile/profile_screen.dart';
import 'package:planmytrip/models/auth_response_model.dart';
import 'package:planmytrip/models/user_model.dart';
import 'package:planmytrip/providers/auth_provider.dart';
import 'package:planmytrip/core/widgets/custom_button.dart';

class MockAuthRepository implements IAuthRepository {
  UserModel? mockUser = UserModel(
    uid: 'mock_123',
    name: 'Test Traveler',
    email: 'traveler@test.com',
    role: 'user',
    createdAt: '2026-01-01',
    updatedAt: '2026-01-01',
    isEmailVerified: true,
  );

  @override
  Future<AuthResponse> signInWithEmail(String email, String password, {bool rememberMe = false}) async {
    if (email == 'valid@test.com' && password == 'Password123!') {
      return AuthResponse(
        user: mockUser!,
        accessToken: 'mock_access_token',
        refreshToken: 'mock_refresh_token',
      );
    }
    throw Exception('Invalid email or password.');
  }

  @override
  Future<AuthResponse> registerWithEmail({
    required String name,
    required String email,
    required String password,
    required String confirmPassword,
    String phone = '',
  }) async {
    return AuthResponse(
      user: mockUser!.copyWith(name: name, email: email),
      accessToken: 'mock_reg_token',
      refreshToken: 'mock_reg_refresh',
    );
  }

  @override
  Future<AuthResponse> signInWithGoogle({
    required String idToken,
    String? email,
    String? name,
    String? photoUrl,
  }) async {
    return AuthResponse(
      user: mockUser!.copyWith(isGoogleUser: true),
      accessToken: 'mock_google_token',
      refreshToken: 'mock_google_refresh',
    );
  }

  @override
  Future<AuthResponse> signInWithApple({
    required String identityToken,
    String? rawNonce,
    String? name,
  }) async {
    return AuthResponse(
      user: mockUser!.copyWith(isAppleUser: true),
      accessToken: 'mock_apple_token',
      refreshToken: 'mock_apple_refresh',
    );
  }

  @override
  Future<Map<String, dynamic>> sendEmailOtp(String email, {String purpose = 'login'}) async {
    return {'target': email, 'expiresMinutes': 5};
  }

  @override
  Future<AuthResponse> verifyEmailOtp(String email, String otp, {String purpose = 'login'}) async {
    return AuthResponse(
      user: mockUser!,
      accessToken: 'mock_token',
      refreshToken: 'mock_refresh',
    );
  }

  @override
  Future<Map<String, dynamic>> sendPhoneOtp(String phone) async {
    return {'target': phone, 'expiresMinutes': 5};
  }

  @override
  Future<AuthResponse> verifyPhoneOtp(String phone, String otp) async {
    return AuthResponse(
      user: mockUser!,
      accessToken: 'mock_token',
      refreshToken: 'mock_refresh',
    );
  }

  @override
  Future<void> sendForgotPasswordEmail(String email) async {}

  @override
  Future<void> resetPassword({
    required String token,
    required String password,
    required String confirmPassword,
  }) async {}

  @override
  Future<UserModel> updateDisplayName(String name) async {
    mockUser = mockUser!.copyWith(name: name);
    return mockUser!;
  }

  @override
  Future<AuthResponse> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    return AuthResponse(
      user: mockUser!,
      accessToken: 'new_token',
      refreshToken: 'new_refresh',
    );
  }

  @override
  Future<UserModel> verifyEmail(String token) async {
    mockUser = mockUser!.copyWith(isEmailVerified: true);
    return mockUser!;
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    return mockUser;
  }

  @override
  Future<void> signOut() async {}

  @override
  Future<void> signOutAll() async {}

  @override
  Future<UserModel> toggleAccountActivation(String userId, bool isActive) async {
    mockUser = mockUser!.copyWith(isActive: isActive);
    return mockUser!;
  }

  @override
  Future<String?> getSavedEmail() async => null;

  @override
  Future<bool> getRememberMe() async => false;
}

void main() {
  late MockAuthRepository mockRepo;

  setUp(() {
    mockRepo = MockAuthRepository();
  });

  Widget createTestWidget(Widget child) {
    return ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(mockRepo),
      ],
      child: MaterialApp(
        home: child,
      ),
    );
  }

  group('LoginScreen Widget Tests', () {
    testWidgets('LoginScreen displays all essential components', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(const LoginScreen()));
      await tester.pumpAndSettle();

      expect(find.text('PlanMyTrip AI'), findsOneWidget);
      expect(find.text('Welcome Back!'), findsOneWidget);
      expect(find.text('Email Address'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.text('Remember me'), findsOneWidget);
      expect(find.text('Forgot Password?'), findsOneWidget);
      expect(find.text('Sign In'), findsOneWidget);
      expect(find.text('Continue with Google'), findsOneWidget);
      expect(find.text('Continue with Apple'), findsOneWidget);
      expect(find.text('Sign In with One-Time Code (OTP)'), findsOneWidget);
      expect(find.text('Create Account'), findsOneWidget);
    });

    testWidgets('Login validation fires when fields are empty', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(const LoginScreen()));
      await tester.pumpAndSettle();

      final signInBtn = find.widgetWithText(ElevatedButton, 'Sign In');
      await tester.tap(signInBtn);
      await tester.pumpAndSettle();

      expect(find.text('Email is required'), findsOneWidget);
      expect(find.text('Password is required'), findsOneWidget);
    });

    testWidgets('Password visibility toggle updates text obscure state', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(const LoginScreen()));
      await tester.pumpAndSettle();

      // Find visibility icon
      final visibilityBtn = find.byIcon(Icons.visibility_off);
      expect(visibilityBtn, findsOneWidget);

      await tester.tap(visibilityBtn);
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.visibility), findsOneWidget);
    });
  });

  group('CreateAccountScreen Widget Tests', () {
    testWidgets('CreateAccountScreen validates required fields and terms agreement', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(const CreateAccountScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Join PlanMyTrip AI'), findsOneWidget);
      expect(find.text('Full Name'), findsOneWidget);
      expect(find.text('Email Address'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.text('Confirm Password'), findsOneWidget);

      // Submit without checking terms
      final createBtn = find.widgetWithText(CustomButton, 'Create Account');
      await tester.ensureVisible(createBtn);
      await tester.tap(createBtn);
      await tester.pumpAndSettle();

      expect(find.text('You must accept the terms and privacy policy to continue'), findsOneWidget);
      expect(find.text('Full name is required'), findsOneWidget);
    });
  });

  group('PhoneAuthScreen Widget Tests', () {
    testWidgets('PhoneAuthScreen switches between Email OTP and Phone OTP tabs', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(const PhoneAuthScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Email OTP'), findsOneWidget);
      expect(find.text('Phone SMS OTP'), findsOneWidget);
      expect(find.text('Email Address'), findsOneWidget);

      // Switch to Phone tab
      await tester.tap(find.text('Phone SMS OTP'));
      await tester.pumpAndSettle();

      expect(find.text('Mobile Phone Number'), findsOneWidget);
    });
  });

  group('ForgotPasswordScreen & ResetPasswordScreen Tests', () {
    testWidgets('ForgotPasswordScreen validates email input', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(const ForgotPasswordScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Forgot Password?'), findsOneWidget);
      final submitBtn = find.text('Send Recovery Instructions');
      await tester.ensureVisible(submitBtn);
      await tester.tap(submitBtn);
      await tester.pumpAndSettle();

      expect(find.text('Email is required'), findsOneWidget);
    });

    testWidgets('ResetPasswordScreen displays token and password fields', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(const ResetPasswordScreen(initialToken: 'test_token_123')));
      await tester.pumpAndSettle();

      expect(find.text('Create New Password'), findsOneWidget);
      expect(find.text('test_token_123'), findsOneWidget);
      expect(find.text('New Password'), findsOneWidget);
      expect(find.text('Confirm New Password'), findsOneWidget);
    });
  });

  group('ProfileScreen Widget Tests', () {
    testWidgets('ProfileScreen displays user info, edit name dialog, and logout options', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(const ProfileScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Test Traveler'), findsWidgets);
      expect(find.text('traveler@test.com'), findsOneWidget);
      expect(find.text('Change Password'), findsOneWidget);
      expect(find.text('Sign Out'), findsOneWidget);
      expect(find.text('Sign Out from All Devices'), findsOneWidget);

      // Tap edit name button
      await tester.tap(find.byIcon(Icons.edit_outlined));
      await tester.pumpAndSettle();

      expect(find.text('Edit Display Name'), findsOneWidget);
      expect(find.text('Save Changes'), findsOneWidget);
    });
  });
}
