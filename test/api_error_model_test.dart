import 'package:flutter_test/flutter_test.dart';
import 'package:planmytrip/core/errors/api_error_model.dart';
import 'package:planmytrip/models/user_model.dart';

void main() {
  group('ApiErrorModel Unit Tests', () {
    test('EMAIL_EXISTS maps to friendly user message', () {
      final error = ApiErrorModel(
        message: 'Email already registered',
        code: 'EMAIL_EXISTS',
      );
      expect(
        error.userFriendlyMessage,
        equals('An account with this email address already exists. Please sign in.'),
      );
    });

    test('INVALID_CREDENTIALS maps to friendly user message', () {
      final error = ApiErrorModel(
        message: 'Invalid email or password',
        code: 'INVALID_CREDENTIALS',
      );
      expect(error.userFriendlyMessage, equals('Invalid email or password.'));
    });

    test('ACCOUNT_DISABLED maps to friendly user message', () {
      final error = ApiErrorModel(
        message: 'Account disabled',
        code: 'ACCOUNT_DISABLED',
      );
      expect(
        error.userFriendlyMessage,
        equals('Your account has been deactivated. Please contact support.'),
      );
    });

    test('NETWORK_ERROR maps to friendly network message', () {
      final error = ApiErrorModel(
        message: 'Network issue',
        code: 'NETWORK_ERROR',
      );
      expect(
        error.userFriendlyMessage,
        equals('Check your internet connection and try again.'),
      );
    });
  });

  group('UserModel Unit Tests', () {
    test('UserModel parses REST API JSON correctly', () {
      final json = {
        'id': '65a1234567890abcdef12345',
        'name': 'Shreyas Roy',
        'email': 'shreyas@example.com',
        'phone': '+919876543210',
        'role': 'user',
        'isActive': true,
        'createdAt': '2026-09-08T10:00:00.000Z',
      };

      final user = UserModel.fromMap(json);
      expect(user.uid, equals('65a1234567890abcdef12345'));
      expect(user.name, equals('Shreyas Roy'));
      expect(user.email, equals('shreyas@example.com'));
      expect(user.phone, equals('+919876543210'));
      expect(user.role, equals('user'));
      expect(user.isActive, isTrue);
    });
  });
}
