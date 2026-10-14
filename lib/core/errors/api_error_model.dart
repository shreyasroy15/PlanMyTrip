import 'package:dio/dio.dart';

class ApiErrorModel implements Exception {
  final bool success;
  final String message;
  final String code;
  final List<dynamic> errors;
  final int? statusCode;

  ApiErrorModel({
    this.success = false,
    required this.message,
    this.code = 'UNKNOWN_ERROR',
    this.errors = const [],
    this.statusCode,
  });

  factory ApiErrorModel.fromJson(Map<String, dynamic> json, [int? statusCode]) {
    return ApiErrorModel(
      success: json['success'] ?? false,
      message: json['message'] ?? 'An unexpected error occurred.',
      code: json['code'] ?? 'UNKNOWN_ERROR',
      errors: json['errors'] is List ? json['errors'] : [],
      statusCode: statusCode,
    );
  }

  factory ApiErrorModel.fromDioException(DioException dioException) {
    if (dioException.type == DioExceptionType.connectionTimeout ||
        dioException.type == DioExceptionType.sendTimeout ||
        dioException.type == DioExceptionType.receiveTimeout) {
      return ApiErrorModel(
        message: 'Connection timed out. Please check your internet connection.',
        code: 'TIMEOUT',
        statusCode: 408,
      );
    }

    if (dioException.type == DioExceptionType.connectionError) {
      return ApiErrorModel(
        message: 'Unable to connect to PlanMyTrip. Please try again.',
        code: 'NETWORK_ERROR',
        statusCode: 503,
      );
    }

    if (dioException.response != null && dioException.response?.data is Map<String, dynamic>) {
      return ApiErrorModel.fromJson(
        dioException.response!.data as Map<String, dynamic>,
        dioException.response!.statusCode,
      );
    }

    return ApiErrorModel(
      message: 'Something went wrong on our server. Please try again later.',
      code: 'SERVER_ERROR',
      statusCode: dioException.response?.statusCode ?? 500,
    );
  }

  String get userFriendlyMessage {
    switch (code) {
      case 'EMAIL_EXISTS':
        return 'An account with this email address already exists. Please sign in.';
      case 'PHONE_EXISTS':
        return 'An account with this phone number already exists.';
      case 'INVALID_CREDENTIALS':
        return 'Invalid email or password.';
      case 'ACCOUNT_DISABLED':
        return 'Your account has been deactivated. Please contact support.';
      case 'RATE_LIMIT_EXCEEDED':
        return 'Too many requests. Please wait a few minutes and try again.';
      case 'VALIDATION_ERROR':
        if (message.isNotEmpty && !message.contains('Validation failed')) {
          return message;
        }
        return 'Please check the highlighted fields.';
      case 'NETWORK_ERROR':
        return 'Check your internet connection and try again.';
      case 'SERVER_ERROR':
        return 'Something went wrong on our server. Please try again later.';
      default:
        if (message.isNotEmpty && !message.startsWith('DioException') && !message.startsWith('Exception')) {
          return message;
        }
        return 'An unexpected error occurred. Please try again.';
    }
  }

  @override
  String toString() => userFriendlyMessage;
}
