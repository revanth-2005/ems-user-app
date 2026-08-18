import '../../../../core/services/secure_storage_service.dart';
import '../../../../core/services/local_storage_service.dart';
import '../../domain/entities/user_entity.dart';
import '../models/user_dto.dart';

/// Handles local session persistence — caches the user profile in
/// SharedPreferences and tokens in SecureStorage.
class AuthLocalDataSource {
  final SecureStorageService _secureStorage;
  final LocalStorageService _localStorage;

  static const _nameKey = 'cached_user_name';
  static const _emailKey = 'cached_user_email';
  static const _idKey = 'cached_user_id';
  static const _isOrgKey = 'cached_is_organizer';
  static const _kycKey = 'cached_kyc_status';

  AuthLocalDataSource(this._secureStorage, this._localStorage);

  Future<void> saveSession({
    required UserDto userDto,
    required String accessToken,
    String? refreshToken,
  }) async {
    await Future.wait([
      _secureStorage.saveTokens(
          accessToken: accessToken, refreshToken: refreshToken),
      _secureStorage.saveUserId(userDto.id),
      _localStorage.setString(_nameKey, userDto.name),
      _localStorage.setString(_emailKey, userDto.email),
      _localStorage.setString(_idKey, userDto.id),
      _localStorage.setBool(_isOrgKey, userDto.isOrganizer),
      _localStorage.setString(_kycKey, userDto.kycStatus),
    ]);
  }

  Future<UserEntity?> getSession() async {
    final id = await _secureStorage.getUserId();
    if (id == null) return null;

    final name = _localStorage.getString(_nameKey) ?? 'Guest';
    final email = _localStorage.getString(_emailKey) ?? '';
    final isOrg = _localStorage.getBool(_isOrgKey);
    final kycRaw = _localStorage.getString(_kycKey) ?? 'PENDING';

    return UserEntity(
      id: id,
      email: email,
      name: name,
      isOrganizer: isOrg,
      kycStatus: KycStatus.values.firstWhere(
        (e) => e.name == kycRaw,
        orElse: () => KycStatus.PENDING,
      ),
    );
  }

  Future<void> clearSession() async {
    await Future.wait([
      _secureStorage.clearAll(),
      _localStorage.remove(_nameKey),
      _localStorage.remove(_emailKey),
      _localStorage.remove(_idKey),
      _localStorage.remove(_isOrgKey),
      _localStorage.remove(_kycKey),
    ]);
  }

  /// Demo mode fallback — creates a seeded user when backend is unavailable.
  UserEntity demoUser({String email = 'rohith.kumar@example.com'}) {
    return UserEntity(
      id: 'usr_demo_001',
      email: email,
      name: 'Rohith Kumar',
      phone: '+919876543210',
      city: 'Mumbai',
      isOrganizer: true,
      canHostEvents: true,
      kycStatus: KycStatus.APPROVED,
    );
  }
}
