import '../entities/user_entity.dart';

/// Contract for all authentication operations.
/// Implemented in the data layer. ViewModels depend only on this interface.
abstract class AuthRepository {
  /// Returns the currently cached user, or null if not authenticated.
  Future<UserEntity?> getSession();

  Future<UserEntity> loginWithEmail({
    required String email,
    required String password,
  });

  Future<void> signupWithEmail({
    required String email,
    required String password,
    required String name,
    required String city,
  });

  Future<void> requestPhoneOtp(String phone);

  Future<UserEntity> verifyOtp({
    required String target,
    required String otp,
  });

  Future<UserEntity> verifyPhoneOtp({
    required String phone,
    required String otp,
  });

  Future<void> logout();

  Future<UserEntity> updateKycStatus(KycStatus status);
}
