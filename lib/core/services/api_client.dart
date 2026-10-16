import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../errors/api_error_model.dart';
import 'token_storage.dart';

class ApiClient {
  static final String defaultBaseUrl = const String.fromEnvironment('API_URL', defaultValue: '')
          .isNotEmpty
      ? const String.fromEnvironment('API_URL')
      : (kIsWeb
          ? 'http://localhost:5000/api'
          : (defaultTargetPlatform == TargetPlatform.android
              ? 'http://10.0.2.2:5000/api'
              : 'http://localhost:5000/api'));

  final Dio _dio;
  final TokenStorage _tokenStorage;
  bool _isRefreshing = false;
  Completer<bool>? _refreshCompleter;

  ApiClient({String? baseUrl, TokenStorage? tokenStorage, Dio? dio})
      : _tokenStorage = tokenStorage ?? TokenStorage(),
        _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: baseUrl ?? defaultBaseUrl,
                connectTimeout: const Duration(seconds: 15),
                receiveTimeout: const Duration(seconds: 15),
                headers: {
                  'Content-Type': 'application/json',
                  'Accept': 'application/json',
                },
              ),
            ) {
    _setupInterceptors();
  }

  Dio get dio => _dio;
  TokenStorage get tokenStorage => _tokenStorage;

  void _setupInterceptors() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final accessToken = await _tokenStorage.getAccessToken();
          if (accessToken != null && accessToken.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $accessToken';
          }
          return handler.next(options);
        },
        onError: (DioException error, handler) async {
          if (error.response?.statusCode == 401) {
            final requestPath = error.requestOptions.path;
            final isAuthEndpoint = requestPath.contains('/auth/login') ||
                requestPath.contains('/auth/register') ||
                requestPath.contains('/auth/refresh');

            if (!isAuthEndpoint) {
              bool refreshed = false;

              if (_isRefreshing && _refreshCompleter != null) {
                // Wait for existing refresh in progress to avoid race conditions
                refreshed = await _refreshCompleter!.future;
              } else {
                _isRefreshing = true;
                _refreshCompleter = Completer<bool>();
                refreshed = await _attemptTokenRefresh();
                _refreshCompleter!.complete(refreshed);
                _isRefreshing = false;
                _refreshCompleter = null;
              }

              if (refreshed) {
                try {
                  final accessToken = await _tokenStorage.getAccessToken();
                  final options = error.requestOptions;
                  options.headers['Authorization'] = 'Bearer $accessToken';
                  final clonedRequest = await _dio.fetch(options);
                  return handler.resolve(clonedRequest);
                } catch (e) {
                  return handler.next(error);
                }
              }
            }
          }
          return handler.next(error);
        },
      ),
    );
  }

  Future<bool> _attemptTokenRefresh() async {
    try {
      final refreshToken = await _tokenStorage.getRefreshToken();
      if (refreshToken == null || refreshToken.isEmpty) return false;

      // Use a clean dio instance without interceptors to avoid looping
      final refreshDio = Dio(
        BaseOptions(
          baseUrl: _dio.options.baseUrl,
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
          headers: {'Content-Type': 'application/json'},
        ),
      );

      final response = await refreshDio.post(
        '/auth/refresh',
        data: {'refreshToken': refreshToken},
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        final data = response.data['data'];
        final newAccessToken = data['accessToken'];
        final newRefreshToken = data['refreshToken'];

        if (newAccessToken != null && newRefreshToken != null) {
          await _tokenStorage.saveTokens(
            accessToken: newAccessToken,
            refreshToken: newRefreshToken,
          );
          return true;
        }
      }
      await _tokenStorage.clearTokens();
      return false;
    } catch (e) {
      await _tokenStorage.clearTokens();
      return false;
    }
  }

  Future<Response> get(String path, {Map<String, dynamic>? queryParameters, Options? options}) async {
    try {
      return await _dio.get(path, queryParameters: queryParameters, options: options);
    } on DioException catch (e) {
      throw ApiErrorModel.fromDioException(e);
    } catch (e) {
      throw ApiErrorModel(message: e.toString());
    }
  }

  Future<Response> post(String path, {dynamic data, Map<String, dynamic>? queryParameters, Options? options}) async {
    try {
      return await _dio.post(path, data: data, queryParameters: queryParameters, options: options);
    } on DioException catch (e) {
      throw ApiErrorModel.fromDioException(e);
    } catch (e) {
      throw ApiErrorModel(message: e.toString());
    }
  }

  Future<Response> patch(String path, {dynamic data, Map<String, dynamic>? queryParameters, Options? options}) async {
    try {
      return await _dio.patch(path, data: data, queryParameters: queryParameters, options: options);
    } on DioException catch (e) {
      throw ApiErrorModel.fromDioException(e);
    } catch (e) {
      throw ApiErrorModel(message: e.toString());
    }
  }
}
