import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';

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
      await _dio.post(
        ApiConstants.signupEmail,
        data: {'email': email, 'password': password, 'name': name, 'city': city},
      );
    } on DioException catch (e) {
      throw NetworkException.fromDioError(e);
    }
  }

  Future<void> requestPhoneOtp(String phone) async {
    try {
      await _dio.post(ApiConstants.loginPhone, data: {'phone': phone});
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

  /// Google Sign-In / Sign-Up via OAuth 2.0.
  ///
  /// Opens a Chrome Custom Tab pointing at `GET /auth/google` (Passport redirect).
  /// Google redirects the browser back to `emsapp://auth/callback?accessToken=...`
  /// This method catches that deep link and parses the JWT token pair.
  Future<({UserDto user, String accessToken, String? refreshToken})>
      signInWithGoogle() async {
    try {
      final googleAuthUrl = '${ApiConstants.baseUrl}${ApiConstants.googleAuth}';

      // Opens Chrome Custom Tab. Resolves when `emsapp://auth` deep link is caught.
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
    final map = data as Map<String, dynamic>;
    return (
      user: UserDto.fromJson(map['user'] as Map<String, dynamic>),
      accessToken: map['accessToken'] as String,
      refreshToken: map['refreshToken'] as String?,
    );
  }
}
