import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Interceptor that prints API Requests in Cyan/Blue, Responses in Green, and Errors in Red.
class ColoredDioLogger extends Interceptor {
  // ANSI Escape Color Codes
  static const String _reset = '\x1B[0m';
  static const String _cyan = '\x1B[96m';
  static const String _green = '\x1B[92m';
  static const String _red = '\x1B[91m';
  static const String _bold = '\x1B[1m';

  final JsonEncoder _encoder = const JsonEncoder.withIndent('  ');

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (kDebugMode) {
      final uri = options.uri.toString();
      final method = options.method.toUpperCase();

      debugPrint('$_cyan╔══════════════════════════════════════════════════════════════════');
      debugPrint('║ $_bold🚀 [API REQUEST] ║ $method $uri$_reset$_cyan');
      if (options.queryParameters.isNotEmpty) {
        debugPrint('║ Query: ${_formatJson(options.queryParameters)}');
      }
      if (options.data != null) {
        debugPrint('║ Request Body:');
        debugPrint('║ ${_formatJson(options.data).replaceAll('\n', '\n║ ')}');
      }
      debugPrint('╚══════════════════════════════════════════════════════════════════$_reset');
    }
    super.onRequest(options, handler);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (kDebugMode) {
      final statusCode = response.statusCode;
      final uri = response.requestOptions.uri.toString();
      final method = response.requestOptions.method.toUpperCase();

      debugPrint('$_green╔══════════════════════════════════════════════════════════════════');
      debugPrint('║ $_bold✅ [API RESPONSE: $statusCode] ║ $method $uri$_reset$_green');
      if (response.data != null) {
        debugPrint('║ Response Body:');
        debugPrint('║ ${_formatJson(response.data).replaceAll('\n', '\n║ ')}');
      }
      debugPrint('╚══════════════════════════════════════════════════════════════════$_reset');
    }
    super.onResponse(response, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (kDebugMode) {
      final statusCode = err.response?.statusCode ?? 'NO_STATUS';
      final uri = err.requestOptions.uri.toString();
      final method = err.requestOptions.method.toUpperCase();

      debugPrint('$_red╔══════════════════════════════════════════════════════════════════');
      debugPrint('║ $_bold❌ [API ERROR: $statusCode] ║ $method $uri$_reset$_red');
      debugPrint('║ Type: ${err.type}');
      debugPrint('║ Message: ${err.message}');
      if (err.response?.data != null) {
        debugPrint('║ Error Body:');
        debugPrint('║ ${_formatJson(err.response?.data).replaceAll('\n', '\n║ ')}');
      }
      debugPrint('╚══════════════════════════════════════════════════════════════════$_reset');
    }
    super.onError(err, handler);
  }

  String _formatJson(dynamic data) {
    try {
      if (data is Map || data is List) {
        return _encoder.convert(data);
      }
      if (data is String) {
        try {
          final decoded = jsonDecode(data);
          return _encoder.convert(decoded);
        } catch (_) {
          return data;
        }
      }
      return data.toString();
    } catch (_) {
      return data.toString();
    }
  }
}
