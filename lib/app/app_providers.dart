import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../core/network/dio_client.dart';
import '../core/services/connectivity_service.dart';
import '../core/services/secure_storage_service.dart';

// ── Core Service Providers ────────────────────────────────────────────────

/// Singleton SecureStorageService — available globally.
final secureStorageProvider = Provider<SecureStorageService>(
  (_) => SecureStorageService(),
  name: 'secureStorageProvider',
);

/// Singleton DioClient — initialised once with SecureStorage.
final dioClientProvider = Provider<DioClient>((ref) {
  final storage = ref.watch(secureStorageProvider);
  DioClient.instance.init(storage);
  return DioClient.instance;
}, name: 'dioClientProvider');

/// ConnectivityService — shared instance.
final connectivityServiceProvider = Provider<ConnectivityService>(
  (_) => ConnectivityService(),
  name: 'connectivityServiceProvider',
);

/// Stream provider — emits true/false as connectivity changes.
final connectivityStreamProvider = StreamProvider<bool>((ref) {
  return ref.watch(connectivityServiceProvider).onConnectivityChanged;
}, name: 'connectivityStreamProvider');
