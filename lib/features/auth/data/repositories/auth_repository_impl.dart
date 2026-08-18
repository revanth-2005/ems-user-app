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
    try {
      final result = await _remote.loginWithEmail(
          email: email, password: password);
      await _local.saveSession(
        userDto: result.user,
        accessToken: result.accessToken,
        refreshToken: result.refreshToken,
      );
      return result.user.toEntity();
    } catch (_) {
      // Demo mode fallback
      final demoUser = _local.demoUser(email: email);
      await _local.saveSession(
        userDto: _entityToDto(demoUser),
        accessToken: 'demo_token',
      );
      return demoUser;
    }
  }

  @override
  Future<UserEntity> signupWithEmail({
    required String email,
    required String password,
    required String name,
    required String city,
  }) async {
    try {
      await _remote.signupWithEmail(
          email: email, password: password, name: name, city: city);
    } catch (_) {
      // Demo mode — treat as success
    }
    return loginWithEmail(email: email, password: password);
  }

  @override
  Future<void> requestPhoneOtp(String phone) async {
    try {
      await _remote.requestPhoneOtp(phone);
    } catch (_) {
      // Demo mode — silently succeed
    }
  }

  @override
  Future<UserEntity> verifyPhoneOtp({
    required String phone,
    required String otp,
  }) async {
    try {
      final result = await _remote.verifyPhoneOtp(phone: phone, otp: otp);
      await _local.saveSession(
        userDto: result.user,
        accessToken: result.accessToken,
        refreshToken: result.refreshToken,
      );
      return result.user.toEntity();
    } catch (_) {
      final demoUser = _local.demoUser();
      await _local.saveSession(
        userDto: _entityToDto(demoUser),
        accessToken: 'demo_token',
      );
      return demoUser;
    }
  }

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
