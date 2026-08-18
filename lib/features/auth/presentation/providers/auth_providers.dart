import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../app/app_providers.dart';
import '../../../../core/services/local_storage_service.dart';
import '../../data/datasources/auth_local_datasource.dart';
import '../../data/datasources/auth_remote_datasource.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';

// ── Infrastructure Providers ──────────────────────────────────────────────

final localStorageServiceProvider =
    FutureProvider<LocalStorageService>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  return LocalStorageService(prefs);
});

final authRemoteDataSourceProvider =
    Provider<AuthRemoteDataSource>((ref) {
  final dioClient = ref.watch(dioClientProvider);
  return AuthRemoteDataSource(dioClient.dio);
});

final authLocalDataSourceProvider =
    FutureProvider<AuthLocalDataSource>((ref) async {
  final secureStorage = ref.watch(secureStorageProvider);
  final localStorage = await ref.watch(localStorageServiceProvider.future);
  return AuthLocalDataSource(secureStorage, localStorage);
});

final authRepositoryProvider =
    FutureProvider<AuthRepository>((ref) async {
  final remote = ref.watch(authRemoteDataSourceProvider);
  final local = await ref.watch(authLocalDataSourceProvider.future);
  return AuthRepositoryImpl(remote: remote, local: local);
});

// ── Auth State Notifier ───────────────────────────────────────────────────

/// The canonical auth state. Watched by GoRouter redirect and all screens.
final authStateProvider =
    AsyncNotifierProvider<AuthNotifier, UserEntity?>(AuthNotifier.new);

/// AsyncNotifier managing the complete auth lifecycle.
class AuthNotifier extends AsyncNotifier<UserEntity?> {
  @override
  Future<UserEntity?> build() async {
    final repo = await ref.watch(authRepositoryProvider.future);
    return repo.getSession();
  }

  Future<void> loginWithEmail(String email, String password) async {
    state = const AsyncLoading();
    final repo = await ref.read(authRepositoryProvider.future);
    state = await AsyncValue.guard(
      () => repo.loginWithEmail(email: email, password: password),
    );
  }

  Future<void> signupWithEmail({
    required String email,
    required String password,
    required String name,
    required String city,
  }) async {
    state = const AsyncLoading();
    final repo = await ref.read(authRepositoryProvider.future);
    state = await AsyncValue.guard(
      () => repo.signupWithEmail(
          email: email, password: password, name: name, city: city),
    );
  }

  Future<bool> requestPhoneOtp(String phone) async {
    try {
      final repo = await ref.read(authRepositoryProvider.future);
      await repo.requestPhoneOtp(phone);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> verifyPhoneOtp(String phone, String otp) async {
    state = const AsyncLoading();
    final repo = await ref.read(authRepositoryProvider.future);
    state = await AsyncValue.guard(
      () => repo.verifyPhoneOtp(phone: phone, otp: otp),
    );
  }

  void switchPortal(ActivePortal portal) {
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncData(current.copyWith(activePortal: portal));
  }

  Future<void> logout() async {
    final repo = await ref.read(authRepositoryProvider.future);
    await repo.logout();
    state = const AsyncData(null);
  }

  Future<void> updateKycStatus(KycStatus status) async {
    final repo = await ref.read(authRepositoryProvider.future);
    final updated = await repo.updateKycStatus(status);
    state = AsyncData(updated);
  }
}
