import 'package:dio/dio.dart';
import 'failures.dart';

class NetworkException implements Exception {
  final String message;
  final int? statusCode;
  final Failure failure;

  const NetworkException(
    this.message, {
    this.statusCode,
    this.failure = const UnknownFailure(),
  });

  const NetworkException._({
    required this.message,
    required this.failure,
    this.statusCode,
  });

  factory NetworkException.fromDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const NetworkException._(
          message: 'Request timed out. Check your connection.',
          failure: NetworkFailure('Request timed out.'),
        );

      case DioExceptionType.connectionError:
        return const NetworkException._(
          message: 'No internet connection.',
          failure: NetworkFailure(),
        );

      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        final serverMsg = extractMessage(error.response?.data) ?? 'Server error.';

        if (statusCode == 401) {
          return NetworkException._(
            message: serverMsg.isNotEmpty ? serverMsg : 'Invalid email or password',
            statusCode: statusCode,
            failure: const AuthFailure('Unauthorized. Please sign in again.'),
          );
        }
        if (statusCode == 403) {
          return NetworkException._(
            message: 'Access denied.',
            statusCode: statusCode,
            failure: const AuthFailure('Access denied.'),
          );
        }
        if (statusCode == 404) {
          return NetworkException._(
            message: 'Resource not found.',
            statusCode: statusCode,
            failure: ServerFailure(message: 'Resource not found.', statusCode: 404),
          );
        }
        if (statusCode != null && statusCode >= 500) {
          return NetworkException._(
            message: 'Server error. Please try again later.',
            statusCode: statusCode,
            failure: ServerFailure(statusCode: statusCode),
          );
        }
        return NetworkException._(
          message: serverMsg,
          statusCode: statusCode,
          failure: ServerFailure(message: serverMsg, statusCode: statusCode),
        );

      case DioExceptionType.cancel:
        return const NetworkException._(
          message: 'Request was cancelled.',
          failure: UnknownFailure('Request cancelled.'),
        );

      default:
        return const NetworkException._(
          message: 'An unexpected error occurred.',
          failure: UnknownFailure(),
        );
    }
  }

  static String? extractMessage(dynamic data) {
    if (data is Map<String, dynamic>) {
      final msg = data['message'] ?? data['error'] ?? data['detail'];
      if (msg is List) {
        return msg.join(', ');
      }
      return msg?.toString();
    }
    if (data is String) return data;
    return null;
  }

  @override
  String toString() => message;
}
