import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenStorage {
  static const _accessTokenKey = 'planmytrip_access_token';
  static const _refreshTokenKey = 'planmytrip_refresh_token';
  static const _rememberMeKey = 'planmytrip_remember_me';
  static const _savedEmailKey = 'planmytrip_saved_email';

  final FlutterSecureStorage _storage;

  TokenStorage([FlutterSecureStorage? storage])
      : _storage = storage ?? const FlutterSecureStorage();

  Future<void> saveAccessToken(String token) async {
    await _storage.write(key: _accessTokenKey, value: token);
  }

  Future<String?> getAccessToken() async {
    return await _storage.read(key: _accessTokenKey);
  }

  Future<void> saveRefreshToken(String token) async {
    await _storage.write(key: _refreshTokenKey, value: token);
  }

  Future<String?> getRefreshToken() async {
    return await _storage.read(key: _refreshTokenKey);
  }

  Future<void> saveTokens({required String accessToken, required String refreshToken}) async {
    await saveAccessToken(accessToken);
    await saveRefreshToken(refreshToken);
  }

  Future<void> saveRememberMe({required bool rememberMe, String? email}) async {
    await _storage.write(key: _rememberMeKey, value: rememberMe.toString());
    if (rememberMe && email != null) {
      await _storage.write(key: _savedEmailKey, value: email);
    } else {
      await _storage.delete(key: _savedEmailKey);
    }
  }

  Future<bool> getRememberMe() async {
    final val = await _storage.read(key: _rememberMeKey);
    return val == 'true';
  }

  Future<String?> getSavedEmail() async {
    return await _storage.read(key: _savedEmailKey);
  }

  Future<void> clearTokens() async {
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _refreshTokenKey);
  }
}
