import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/api_constants.dart';
import '../services/secure_storage_service.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;

  late final Dio dio;
  final SecureStorageService _secureStorage = SecureStorageService();
  String _currentBaseUrl = ApiConstants.baseUrl;

  ApiClient._internal() {
    dio = Dio(
      BaseOptions(
        baseUrl: _currentBaseUrl,
        connectTimeout: const Duration(seconds: 8),
        receiveTimeout: const Duration(seconds: 8),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          var token = await _secureStorage.getAccessToken();
          if (token == null || token.isEmpty) {
            final prefs = await SharedPreferences.getInstance();
            token = prefs.getString('accessToken');
          }
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (DioException error, handler) async {
          if (error.response?.statusCode == 401) {
            var refreshToken = await _secureStorage.getRefreshToken();
            if (refreshToken == null || refreshToken.isEmpty) {
              final prefs = await SharedPreferences.getInstance();
              refreshToken = prefs.getString('refreshToken');
            }

            if (refreshToken != null && refreshToken.isNotEmpty) {
              try {
                // Attempt token rotation
                final refreshResponse = await Dio().post(
                  '$_currentBaseUrl${ApiConstants.refreshToken}',
                  data: {'refreshToken': refreshToken},
                );

                if (refreshResponse.statusCode == 200) {
                  final newAccessToken = refreshResponse.data['accessToken'] as String;
                  final newRefreshToken = refreshResponse.data['refreshToken'] as String?;

                  await _secureStorage.saveTokens(
                    accessToken: newAccessToken,
                    refreshToken: newRefreshToken,
                  );

                  // Retry the original request
                  final reqOptions = error.requestOptions;
                  reqOptions.headers['Authorization'] = 'Bearer $newAccessToken';
                  final cloneReq = await dio.fetch(reqOptions);
                  return handler.resolve(cloneReq);
                }
              } catch (_) {
                // Clear session on failed refresh
                await _secureStorage.clearAll();
              }
            }
          }
          return handler.next(error);
        },
      ),
    );
  }

  void updateBaseUrl(String newUrl) {
    _currentBaseUrl = newUrl;
    dio.options.baseUrl = newUrl;
  }
}
