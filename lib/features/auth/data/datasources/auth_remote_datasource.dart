import 'package:dio/dio.dart';
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
