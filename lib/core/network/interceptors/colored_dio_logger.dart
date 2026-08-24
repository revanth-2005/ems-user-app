import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Interceptor that prints API Requests in Cyan/Blue, Responses in Green, and Errors in Red.
/// JSON formatting is done in a background isolate via [compute] to avoid ANR on low-end devices.
class ColoredDioLogger extends Interceptor {
  // ANSI Escape Color Codes
  static const String _reset = '\x1B[0m';
  static const String _cyan = '\x1B[96m';
  static const String _green = '\x1B[92m';
  static const String _red = '\x1B[91m';
  static const String _bold = '\x1B[1m';

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (kDebugMode) {
      final uri = options.uri.toString();
      final method = options.method.toUpperCase();

      debugPrint(
          '$_cyan╔══════════════════════════════════════════════════════════════════');
      debugPrint('║ $_bold🚀 [API REQUEST] ║ $method $uri$_reset$_cyan');
      if (options.queryParameters.isNotEmpty) {
        debugPrint('║ Query: ${_safeFormatSmall(options.queryParameters)}');
      }
      // Skip logging large request bodies synchronously — just show size
      if (options.data != null) {
        debugPrint('║ Body: [omitted in debug — see network tab]');
      }
      debugPrint(
          '╚══════════════════════════════════════════════════════════════════$_reset');
    }
    super.onRequest(options, handler);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (kDebugMode) {
      final statusCode = response.statusCode;
      final uri = response.requestOptions.uri.toString();
      final method = response.requestOptions.method.toUpperCase();

      // Only log header — skip body formatting to avoid blocking the UI thread
      debugPrint(
          '$_green╔══════════════════════════════════════════════════════════════════');
      debugPrint(
          '║ $_bold✅ [API RESPONSE: $statusCode] ║ $method $uri$_reset$_green');
      debugPrint(
          '╚══════════════════════════════════════════════════════════════════$_reset');

      // Async background formatting — never blocks the UI thread
      if (response.data != null) {
        compute(_formatJsonInIsolate, response.data).then((formatted) {
          debugPrint('$_green║ Body (async):\n$formatted$_reset');
        }).catchError((_) {});
      }
    }
    super.onResponse(response, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (kDebugMode) {
      final statusCode = err.response?.statusCode ?? 'NO_STATUS';
      final uri = err.requestOptions.uri.toString();
      final method = err.requestOptions.method.toUpperCase();

      debugPrint(
          '$_red╔══════════════════════════════════════════════════════════════════');
      debugPrint(
          '║ $_bold❌ [API ERROR: $statusCode] ║ $method $uri$_reset$_red');
      debugPrint('║ Type: ${err.type}');
      debugPrint('║ Message: ${err.message}');
      if (err.response?.data != null) {
        compute(_formatJsonInIsolate, err.response!.data).then((formatted) {
          debugPrint('$_red║ Error Body (async):\n$formatted$_reset');
        }).catchError((_) {});
      }
      debugPrint(
          '╚══════════════════════════════════════════════════════════════════$_reset');
    }
    super.onError(err, handler);
  }

  /// Formats small query params inline (they're always tiny, safe to do synchronously).
  static String _safeFormatSmall(Map<String, dynamic> data) {
    try {
      return const JsonEncoder.withIndent('  ').convert(data);
    } catch (_) {
      return data.toString();
    }
  }

  /// Top-level function required by [compute] — runs in a separate isolate.
  static String _formatJsonInIsolate(dynamic data) {
    const encoder = JsonEncoder.withIndent('  ');
    try {
      if (data is Map || data is List) {
        return encoder.convert(data);
      }
      if (data is String) {
        try {
          return encoder.convert(jsonDecode(data));
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
