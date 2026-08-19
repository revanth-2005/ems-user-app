import 'package:dio/dio.dart';
import '../../constants/api_constants.dart';
import '../../services/secure_storage_service.dart';

/// Intercepts 401 responses, attempts a token refresh, and retries
/// the original request once. On second failure, clears tokens.
class RefreshTokenInterceptor extends Interceptor {
  final Dio _dio;
  final SecureStorageService _secureStorage;
  bool _isRefreshing = false;

  RefreshTokenInterceptor({
    required Dio dio,
    required SecureStorageService secureStorage,
  })  : _dio = dio,
        _secureStorage = secureStorage;

  @override
  Future<void> onResponse(
    Response response,
    ResponseInterceptorHandler handler,
  ) async {
    // If response status is 401 and not the refresh endpoint
    if (response.statusCode == 401 &&
        !response.requestOptions.path.contains(ApiConstants.refreshToken) &&
        !_isRefreshing) {
      _isRefreshing = true;
      try {
        final refreshToken = await _secureStorage.getRefreshToken();
        if (refreshToken != null && refreshToken.isNotEmpty) {
          final refreshDio = Dio(BaseOptions(baseUrl: ApiConstants.baseUrl));
          final refreshRes = await refreshDio.post(
            ApiConstants.refreshToken,
            data: {'refreshToken': refreshToken},
          );

          if (refreshRes.statusCode == 200) {
            final newAccessToken = refreshRes.data['accessToken'] as String?;
            final newRefreshToken = refreshRes.data['refreshToken'] as String?;

            if (newAccessToken != null) {
              await _secureStorage.saveTokens(
                accessToken: newAccessToken,
                refreshToken: newRefreshToken,
              );

              response.requestOptions.headers['Authorization'] =
                  'Bearer $newAccessToken';
              final retried = await _dio.fetch(response.requestOptions);
              return handler.resolve(retried);
            }
          }
        }
      } catch (_) {
        // Refresh token failed
      } finally {
        _isRefreshing = false;
      }
    }
    handler.next(response);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    // Only handle 401 Unauthorized on non-refresh endpoints
    if (err.response?.statusCode != 401 ||
        err.requestOptions.path.contains(ApiConstants.refreshToken) ||
        _isRefreshing) {
      return handler.next(err);
    }

    _isRefreshing = true;

    try {
      final refreshToken = await _secureStorage.getRefreshToken();
      if (refreshToken == null) {
        return handler.next(err);
      }

      // Attempt token refresh using a separate Dio to avoid interceptor loops
      final refreshDio = Dio(BaseOptions(baseUrl: ApiConstants.baseUrl));
      final response = await refreshDio.post(
        ApiConstants.refreshToken,
        data: {'refreshToken': refreshToken},
      );

      if (response.statusCode == 200) {
        final newAccessToken = response.data['accessToken'] as String?;
        final newRefreshToken = response.data['refreshToken'] as String?;

        if (newAccessToken != null) {
          await _secureStorage.saveTokens(
            accessToken: newAccessToken,
            refreshToken: newRefreshToken,
          );

          // Retry the original request with new token
          err.requestOptions.headers['Authorization'] =
              'Bearer $newAccessToken';
          final retried = await _dio.fetch(err.requestOptions);
          return handler.resolve(retried);
        }
      }

      handler.next(err);
    } catch (_) {
      handler.next(err);
    } finally {
      _isRefreshing = false;
    }
  }
}
