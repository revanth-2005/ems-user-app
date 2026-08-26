import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/errors/network_exception.dart';
import '../../domain/entities/notification_entity.dart';

class NotificationRemoteDataSource {
  final Dio _dio;
  NotificationRemoteDataSource(this._dio);

  Future<NotificationListResponse> getNotifications({
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await _dio.get(
        ApiConstants.notificationsMe,
        queryParameters: {
          'page': page,
          'limit': limit,
        },
      );
      if (response.statusCode == 200 && response.data is Map<String, dynamic>) {
        return NotificationListResponse.fromJson(
            response.data as Map<String, dynamic>);
      }
      return const NotificationListResponse(notifications: []);
    } on DioException catch (e) {
      throw NetworkException.fromDioError(e);
    }
  }

  Future<bool> markAsRead(String id) async {
    try {
      final endpoint = ApiConstants.markNotificationRead.replaceAll('{id}', id);
      final response = await _dio.patch(endpoint);
      return response.statusCode == 200;
    } on DioException catch (e) {
      throw NetworkException.fromDioError(e);
    }
  }

  Future<bool> markAllAsRead() async {
    try {
      final response = await _dio.patch(ApiConstants.markAllNotificationsRead);
      return response.statusCode == 200;
    } on DioException catch (e) {
      throw NetworkException.fromDioError(e);
    }
  }
}
