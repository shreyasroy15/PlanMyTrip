import '../services/api_client.dart';
import '../../models/user_model.dart';
import '../../models/auth_response_model.dart';

class AuthService {
  final ApiClient _apiClient;

  AuthService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  ApiClient get apiClient => _apiClient;

  Future<AuthResponse> register({
    required String name,
    required String email,
    required String password,
    required String confirmPassword,
    String phone = '',
  }) async {
    final response = await _apiClient.post(
      '/auth/register',
      data: {
        'name': name,
        'email': email,
        'password': password,
        'confirmPassword': confirmPassword,
        'phone': phone,
      },
    );
    return AuthResponse.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<AuthResponse> login({
    required String email,
    required String password,
    bool rememberMe = false,
  }) async {
    final response = await _apiClient.post(
      '/auth/login',
      data: {
        'email': email,
        'password': password,
        'rememberMe': rememberMe,
      },
    );
    return AuthResponse.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<UserModel> getMe() async {
    final response = await _apiClient.get('/auth/me');
    final userData = response.data['data']['user'] as Map<String, dynamic>;
    return UserModel.fromMap(userData);
  }

  Future<UserModel> updateProfile(String name) async {
    final response = await _apiClient.patch(
      '/auth/profile',
      data: {'name': name},
    );
    final userData = response.data['data']['user'] as Map<String, dynamic>;
    return UserModel.fromMap(userData);
  }

  Future<AuthResponse> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    final response = await _apiClient.post(
      '/auth/change-password',
      data: {
        'currentPassword': currentPassword,
        'newPassword': newPassword,
        'confirmPassword': confirmPassword,
      },
    );
    return AuthResponse.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<AuthResponse> refreshToken(String refreshToken) async {
    final response = await _apiClient.post(
      '/auth/refresh',
      data: {'refreshToken': refreshToken},
    );
    return AuthResponse.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<void> logout(String? refreshToken) async {
    try {
      await _apiClient.post(
        '/auth/logout',
        data: {'refreshToken': refreshToken ?? ''},
      );
    } catch (_) {
      // Ignore network errors on logout to ensure local wipe always proceeds
    } finally {
      await _apiClient.tokenStorage.clearTokens();
    }
  }

  Future<void> logoutAll() async {
    try {
      await _apiClient.post('/auth/logout-all');
    } catch (_) {
    } finally {
      await _apiClient.tokenStorage.clearTokens();
    }
  }

  Future<void> sendForgotPassword(String email) async {
    await _apiClient.post(
      '/auth/forgot-password',
      data: {'email': email},
    );
  }

  Future<void> resetPassword({
    required String token,
    required String password,
    required String confirmPassword,
  }) async {
    await _apiClient.post(
      '/auth/reset-password',
      data: {
        'token': token,
        'password': password,
        'confirmPassword': confirmPassword,
      },
    );
  }

  Future<UserModel> verifyEmail(String token) async {
    final response = await _apiClient.post(
      '/auth/verify-email',
      data: {'token': token},
    );
    final userData = response.data['data']['user'] as Map<String, dynamic>;
    return UserModel.fromMap(userData);
  }

  // Email OTP
  Future<Map<String, dynamic>> sendEmailOtp(String email, {String purpose = 'login'}) async {
    final response = await _apiClient.post(
      '/auth/send-email-otp',
      data: {'email': email, 'purpose': purpose},
    );
    return response.data['data'] as Map<String, dynamic>;
  }

  Future<AuthResponse> verifyEmailOtp(String email, String otp, {String purpose = 'login'}) async {
    final response = await _apiClient.post(
      '/auth/verify-email-otp',
      data: {'email': email, 'otp': otp, 'purpose': purpose},
    );
    return AuthResponse.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  // Phone OTP
  Future<Map<String, dynamic>> sendOtp(String phone) async {
    final response = await _apiClient.post(
      '/auth/send-otp',
      data: {'phone': phone},
    );
    return response.data['data'] as Map<String, dynamic>;
  }

  Future<AuthResponse> verifyOtp(String phone, String otp) async {
    final response = await _apiClient.post(
      '/auth/verify-otp',
      data: {
        'phone': phone,
        'otp': otp,
      },
    );
    return AuthResponse.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  // Social Authentication
  Future<AuthResponse> googleLogin({
    required String idToken,
    String? email,
    String? name,
    String? photoUrl,
  }) async {
    final response = await _apiClient.post(
      '/auth/google',
      data: {
        'idToken': idToken,
        'email': email,
        'name': name,
        'photoUrl': photoUrl,
      },
    );
    return AuthResponse.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<AuthResponse> appleLogin({
    required String identityToken,
    String? rawNonce,
    String? name,
  }) async {
    final response = await _apiClient.post(
      '/auth/apple',
      data: {
        'identityToken': identityToken,
        'rawNonce': rawNonce,
        'name': name,
      },
    );
    return AuthResponse.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  // Admin User Status Toggle
  Future<UserModel> toggleUserStatus(String userId, bool isActive) async {
    final response = await _apiClient.patch(
      '/admin/users/$userId/status',
      data: {'isActive': isActive},
    );
    final userData = response.data['data']['user'] as Map<String, dynamic>;
    return UserModel.fromMap(userData);
  }
}
