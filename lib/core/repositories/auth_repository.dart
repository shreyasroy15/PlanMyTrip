import '../services/auth_service.dart';
import '../../models/user_model.dart';
import '../../models/auth_response_model.dart';

abstract class IAuthRepository {
  Future<AuthResponse> signInWithEmail(String email, String password, {bool rememberMe = false});
  Future<AuthResponse> registerWithEmail({
    required String name,
    required String email,
    required String password,
    required String confirmPassword,
    String phone = '',
  });
  Future<AuthResponse> signInWithGoogle({
    required String idToken,
    String? email,
    String? name,
    String? photoUrl,
  });
  Future<AuthResponse> signInWithApple({
    required String identityToken,
    String? rawNonce,
    String? name,
  });
  Future<Map<String, dynamic>> sendEmailOtp(String email, {String purpose = 'login'});
  Future<AuthResponse> verifyEmailOtp(String email, String otp, {String purpose = 'login'});
  Future<Map<String, dynamic>> sendPhoneOtp(String phone);
  Future<AuthResponse> verifyPhoneOtp(String phone, String otp);
  Future<void> sendForgotPasswordEmail(String email);
  Future<void> resetPassword({
    required String token,
    required String password,
    required String confirmPassword,
  });
  Future<UserModel> updateDisplayName(String name);
  Future<AuthResponse> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  });
  Future<UserModel> verifyEmail(String token);
  Future<UserModel?> getCurrentUser();
  Future<void> signOut();
  Future<void> signOutAll();
  Future<UserModel> toggleAccountActivation(String userId, bool isActive);
  Future<String?> getSavedEmail();
  Future<bool> getRememberMe();
}

class AuthRepository implements IAuthRepository {
  final AuthService _authService;

  AuthRepository(this._authService);

  AuthService get authService => _authService;

  @override
  Future<AuthResponse> signInWithEmail(String email, String password, {bool rememberMe = false}) async {
    final response = await _authService.login(email: email, password: password, rememberMe: rememberMe);
    await _authService.apiClient.tokenStorage.saveTokens(
      accessToken: response.accessToken,
      refreshToken: response.refreshToken,
    );
    await _authService.apiClient.tokenStorage.saveRememberMe(rememberMe: rememberMe, email: email);
    return response;
  }

  @override
  Future<AuthResponse> registerWithEmail({
    required String name,
    required String email,
    required String password,
    required String confirmPassword,
    String phone = '',
  }) async {
    final response = await _authService.register(
      name: name,
      email: email,
      password: password,
      confirmPassword: confirmPassword,
      phone: phone,
    );
    await _authService.apiClient.tokenStorage.saveTokens(
      accessToken: response.accessToken,
      refreshToken: response.refreshToken,
    );
    return response;
  }

  @override
  Future<AuthResponse> signInWithGoogle({
    required String idToken,
    String? email,
    String? name,
    String? photoUrl,
  }) async {
    final response = await _authService.googleLogin(
      idToken: idToken,
      email: email,
      name: name,
      photoUrl: photoUrl,
    );
    await _authService.apiClient.tokenStorage.saveTokens(
      accessToken: response.accessToken,
      refreshToken: response.refreshToken,
    );
    return response;
  }

  @override
  Future<AuthResponse> signInWithApple({
    required String identityToken,
    String? rawNonce,
    String? name,
  }) async {
    final response = await _authService.appleLogin(
      identityToken: identityToken,
      rawNonce: rawNonce,
      name: name,
    );
    await _authService.apiClient.tokenStorage.saveTokens(
      accessToken: response.accessToken,
      refreshToken: response.refreshToken,
    );
    return response;
  }

  @override
  Future<Map<String, dynamic>> sendEmailOtp(String email, {String purpose = 'login'}) {
    return _authService.sendEmailOtp(email, purpose: purpose);
  }

  @override
  Future<AuthResponse> verifyEmailOtp(String email, String otp, {String purpose = 'login'}) async {
    final response = await _authService.verifyEmailOtp(email, otp, purpose: purpose);
    await _authService.apiClient.tokenStorage.saveTokens(
      accessToken: response.accessToken,
      refreshToken: response.refreshToken,
    );
    return response;
  }

  @override
  Future<Map<String, dynamic>> sendPhoneOtp(String phone) {
    return _authService.sendOtp(phone);
  }

  @override
  Future<AuthResponse> verifyPhoneOtp(String phone, String otp) async {
    final response = await _authService.verifyOtp(phone, otp);
    await _authService.apiClient.tokenStorage.saveTokens(
      accessToken: response.accessToken,
      refreshToken: response.refreshToken,
    );
    return response;
  }

  @override
  Future<void> sendForgotPasswordEmail(String email) {
    return _authService.sendForgotPassword(email);
  }

  @override
  Future<void> resetPassword({
    required String token,
    required String password,
    required String confirmPassword,
  }) {
    return _authService.resetPassword(
      token: token,
      password: password,
      confirmPassword: confirmPassword,
    );
  }

  @override
  Future<UserModel> updateDisplayName(String name) {
    return _authService.updateProfile(name);
  }

  @override
  Future<AuthResponse> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    final response = await _authService.changePassword(
      currentPassword: currentPassword,
      newPassword: newPassword,
      confirmPassword: confirmPassword,
    );
    await _authService.apiClient.tokenStorage.saveTokens(
      accessToken: response.accessToken,
      refreshToken: response.refreshToken,
    );
    return response;
  }

  @override
  Future<UserModel> verifyEmail(String token) {
    return _authService.verifyEmail(token);
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    try {
      final token = await _authService.apiClient.tokenStorage.getAccessToken();
      if (token == null || token.isEmpty) return null;
      return await _authService.getMe();
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> signOut() async {
    final refreshToken = await _authService.apiClient.tokenStorage.getRefreshToken();
    await _authService.logout(refreshToken);
  }

  @override
  Future<void> signOutAll() async {
    await _authService.logoutAll();
  }

  @override
  Future<UserModel> toggleAccountActivation(String userId, bool isActive) {
    return _authService.toggleUserStatus(userId, isActive);
  }

  @override
  Future<String?> getSavedEmail() {
    return _authService.apiClient.tokenStorage.getSavedEmail();
  }

  @override
  Future<bool> getRememberMe() {
    return _authService.apiClient.tokenStorage.getRememberMe();
  }
}
