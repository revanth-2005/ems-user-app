import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/api_constants.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;

  late final Dio dio;
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
          final prefs = await SharedPreferences.getInstance();
          final token = prefs.getString('accessToken');
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (DioException error, handler) async {
          if (error.response?.statusCode == 401) {
            final prefs = await SharedPreferences.getInstance();
            final refreshToken = prefs.getString('refreshToken');

            if (refreshToken != null && refreshToken.isNotEmpty) {
              try {
                // Attempt token rotation
                final refreshResponse = await Dio().post(
                  '$_currentBaseUrl${ApiConstants.refreshToken}',
                  data: {'refreshToken': refreshToken},
                );

                if (refreshResponse.statusCode == 200) {
                  final newAccessToken = refreshResponse.data['accessToken'];
                  final newRefreshToken = refreshResponse.data['refreshToken'];

                  await prefs.setString('accessToken', newAccessToken);
                  if (newRefreshToken != null) {
                    await prefs.setString('refreshToken', newRefreshToken);
                  }

                  // Retry the original request
                  final reqOptions = error.requestOptions;
                  reqOptions.headers['Authorization'] = 'Bearer $newAccessToken';
                  final cloneReq = await dio.fetch(reqOptions);
                  return handler.resolve(cloneReq);
                }
              } catch (_) {
                // Clear session on failed refresh
                await prefs.remove('accessToken');
                await prefs.remove('refreshToken');
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
