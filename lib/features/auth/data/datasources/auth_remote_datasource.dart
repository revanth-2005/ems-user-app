import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/errors/network_exception.dart';
import '../models/user_dto.dart';

/// Handles all remote API calls for authentication.
class AuthRemoteDataSource {
  final Dio _dio;
  AuthRemoteDataSource(this._dio);

  Future<({UserDto user, String accessToken, String? refreshToken})>
      loginWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio.post(
        ApiConstants.loginEmail,
        data: {'email': email, 'password': password},
      );
      if (response.statusCode != null && response.statusCode! >= 400) {
        final msg = NetworkException.extractMessage(response.data) ??
            'Invalid email or password';
        throw NetworkException(msg, statusCode: response.statusCode);
      }
      return _parseAuthResponse(response.data);
    } on DioException catch (e) {
      throw NetworkException.fromDioError(e);
    }
  }

  Future<void> signupWithEmail({
    required String email,
    required String password,
    required String name,
    required String city,
  }) async {
    try {
      final response = await _dio.post(
        ApiConstants.signupEmail,
        data: {'email': email, 'password': password, 'name': name, 'city': city},
      );
      if (response.statusCode != null && response.statusCode! >= 400) {
        final msg = NetworkException.extractMessage(response.data) ??
            'Failed to create account';
        throw NetworkException(msg, statusCode: response.statusCode);
      }
    } on DioException catch (e) {
      throw NetworkException.fromDioError(e);
    }
  }

  Future<void> requestPhoneOtp(String phone) async {
    try {
      final response = await _dio.post(ApiConstants.loginPhone, data: {'phone': phone});
      if (response.statusCode != null && response.statusCode! >= 400) {
        final msg = NetworkException.extractMessage(response.data) ??
            'Failed to send OTP';
        throw NetworkException(msg, statusCode: response.statusCode);
      }
    } on DioException catch (e) {
      throw NetworkException.fromDioError(e);
    }
  }

  Future<({UserDto user, String accessToken, String? refreshToken})>
      verifyOtp({
    required String target,
    required String otp,
  }) async {
    try {
      final response = await _dio.post(
        ApiConstants.verifyOtp,
        data: {'target': target, 'otp': otp},
      );
      if (response.statusCode != null && response.statusCode! >= 400) {
        final msg = NetworkException.extractMessage(response.data) ??
            'Invalid or expired OTP';
        throw NetworkException(msg, statusCode: response.statusCode);
      }
      return _parseAuthResponse(response.data);
    } on DioException catch (e) {
      throw NetworkException.fromDioError(e);
    }
  }

  Future<({UserDto user, String accessToken, String? refreshToken})>
      verifyPhoneOtp({
    required String phone,
    required String otp,
  }) => verifyOtp(target: phone, otp: otp);

  /// Google Sign-In / Sign-Up (Native SDK + Backend verification).
  ///
  /// 1. Tries Native Google Sign-In on Android/iOS and sends `idToken` to `POST /auth/google/mobile`.
  /// 2. If Native Sign-In is unavailable or cancelled/fails, falls back to OAuth 2.0 via Chrome Custom Tab (`GET /auth/google`).
  Future<({UserDto user, String accessToken, String? refreshToken})>
      signInWithGoogle() async {
    // 1. Try Native Google Sign-In Flow
    try {
      final googleSignIn = GoogleSignIn(
        serverClientId: ApiConstants.googleWebClientId,
        scopes: ['email', 'profile'],
      );

      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        throw const NetworkException('Google sign-in was cancelled');
      }

      final googleAuth = await googleUser.authentication;
      final idToken = googleAuth.idToken;

      if (idToken != null && idToken.isNotEmpty) {
        final response = await _dio.post(
          ApiConstants.googleAuthMobile,
          data: {'idToken': idToken},
        );
        return _parseAuthResponse(response.data);
      }
    } on DioException catch (e) {
      throw NetworkException.fromDioError(e);
    } catch (e) {
      if (e is NetworkException) rethrow;
      // Fall through to OAuth deep link fallback
    }

    // 2. Fallback: Web/OAuth redirect via Chrome Custom Tab
    try {
      final googleAuthUrl = '${ApiConstants.baseUrl}${ApiConstants.googleAuth}';

      final resultUrl = await FlutterWebAuth2.authenticate(
        url: googleAuthUrl,
        callbackUrlScheme: 'emsapp',
        options: const FlutterWebAuth2Options(
          preferEphemeral: false,
        ),
      );

      final uri = Uri.parse(resultUrl);
      final accessToken = uri.queryParameters['accessToken'];
      final refreshToken = uri.queryParameters['refreshToken'];
      final userRaw = uri.queryParameters['user'];

      if (accessToken == null || accessToken.isEmpty) {
        throw const NetworkException('Google sign-in failed: no access token received');
      }

      final userMap = userRaw != null
          ? jsonDecode(Uri.decodeComponent(userRaw)) as Map<String, dynamic>
          : <String, dynamic>{};

      return (
        user: UserDto.fromJson(userMap),
        accessToken: accessToken,
        refreshToken: refreshToken,
      );
    } on PlatformException catch (e) {
      throw NetworkException('Google sign-in cancelled or failed: ${e.message}');
    } catch (e) {
      if (e is NetworkException) rethrow;
      throw NetworkException('Google sign-in error: $e');
    }
  }

  ({UserDto user, String accessToken, String? refreshToken}) _parseAuthResponse(
      dynamic data) {
    if (data is! Map<String, dynamic>) {
      throw const NetworkException('Invalid server response');
    }
    final userMap = data['user'] as Map<String, dynamic>?;
    final token = data['accessToken'] as String?;

    if (userMap == null || token == null) {
      final msg = NetworkException.extractMessage(data) ??
          'Invalid email or password';
      throw NetworkException(msg);
    }

    return (
      user: UserDto.fromJson(userMap),
      accessToken: token,
      refreshToken: data['refreshToken'] as String?,
    );
  }
}
