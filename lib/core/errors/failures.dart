abstract class Failure {
  final String message;
  const Failure(this.message);
}

class ServerFailure extends Failure {
  const ServerFailure([super.message = 'Server Error Occurred']);
}

class AuthFailure extends Failure {
  const AuthFailure([super.message = 'Authentication Failed']);
}

class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'Network Connection Error']);
}
