import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_local_datasource.dart';
import '../datasources/auth_remote_datasource.dart';
import '../models/user_dto.dart';

/// Concrete implementation of [AuthRepository].
/// Coordinates remote API calls + local caching + demo mode fallback.
class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _remote;
  final AuthLocalDataSource _local;

  AuthRepositoryImpl({
    required AuthRemoteDataSource remote,
    required AuthLocalDataSource local,
  })  : _remote = remote,
        _local = local;

  @override
  Future<UserEntity?> getSession() => _local.getSession();

  @override
  Future<UserEntity> loginWithEmail({
    required String email,
    required String password,
  }) async {
    final result = await _remote.loginWithEmail(
        email: email, password: password);
    await _local.saveSession(
      userDto: result.user,
      accessToken: result.accessToken,
      refreshToken: result.refreshToken,
    );
    return result.user.toEntity();
  }

  @override
  Future<void> signupWithEmail({
    required String email,
    required String password,
    required String name,
    required String city,
  }) async {
    await _remote.signupWithEmail(
        email: email, password: password, name: name, city: city);
  }

  @override
  Future<void> requestPhoneOtp(String phone) async {
    await _remote.requestPhoneOtp(phone);
  }

  @override
  Future<UserEntity> verifyOtp({
    required String target,
    required String otp,
  }) async {
    final result = await _remote.verifyOtp(target: target, otp: otp);
    await _local.saveSession(
      userDto: result.user,
      accessToken: result.accessToken,
      refreshToken: result.refreshToken,
    );
    return result.user.toEntity();
  }

  @override
  Future<UserEntity> verifyPhoneOtp({
    required String phone,
    required String otp,
  }) => verifyOtp(target: phone, otp: otp);

  @override
  Future<void> logout() => _local.clearSession();

  @override
  Future<UserEntity> updateKycStatus(KycStatus status) async {
    final current = await _local.getSession();
    if (current == null) throw Exception('Not authenticated');
    final updated = current.copyWith(
      kycStatus: status,
      isOrganizer: status == KycStatus.APPROVED,
    );
    await _local.saveSession(
      userDto: _entityToDto(updated),
      accessToken: 'demo_token',
    );
    return updated;
  }

  UserDto _entityToDto(UserEntity e) => UserDto(
        id: e.id,
        email: e.email,
        name: e.name,
        phone: e.phone,
        city: e.city,
        isOrganizer: e.isOrganizer,
        canHostEvents: e.canHostEvents,
        kycStatus: e.kycStatus.name,
      );
}
