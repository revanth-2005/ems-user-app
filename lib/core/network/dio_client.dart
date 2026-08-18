import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import '../constants/api_constants.dart';
import '../errors/network_exception.dart';
import '../services/secure_storage_service.dart';
import 'interceptors/auth_interceptor.dart';
import 'interceptors/refresh_token_interceptor.dart';

/// Singleton Dio client. Use [DioClient.instance.dio] throughout the app.
/// Never create raw Dio instances in data sources.
class DioClient {
  DioClient._();
  static final DioClient instance = DioClient._();

  late final Dio _dio;
  Dio get dio => _dio;

  void init(SecureStorageService secureStorage) {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: const Duration(seconds: 2),
        receiveTimeout: const Duration(seconds: 3),
        sendTimeout: const Duration(seconds: 3),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        validateStatus: (status) => status != null && status < 500,
      ),
    );

    // Auth interceptor — injects Bearer token
    _dio.interceptors.add(AuthInterceptor(secureStorage));

    // Refresh token interceptor — retries 401 responses
    _dio.interceptors.add(RefreshTokenInterceptor(dio: _dio, secureStorage: secureStorage));

    // Logging — only in debug
    if (kDebugMode) {
      _dio.interceptors.add(
        PrettyDioLogger(
          requestHeader: false,
          requestBody: true,
          responseBody: true,
          responseHeader: false,
          error: true,
          compact: true,
        ),
      );
    }
  }

  /// Maps any error to [NetworkException] before propagating.
  static NetworkException handleError(Object error) {
    if (error is DioException) {
      return NetworkException.fromDioError(error);
    }
    if (error is NetworkException) return error;
    return NetworkException.fromDioError(
      DioException(
        requestOptions: RequestOptions(path: ''),
        error: error,
        type: DioExceptionType.unknown,
      ),
    );
  }
}
