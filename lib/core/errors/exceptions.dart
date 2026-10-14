class ServerException implements Exception {
  final String message;
  ServerException([this.message = 'Server Error Occurred']);
}

class AuthException implements Exception {
  final String message;
  AuthException([this.message = 'Authentication Error Occurred']);
}

class CacheException implements Exception {
  final String message;
  CacheException([this.message = 'Cache Error Occurred']);
}
