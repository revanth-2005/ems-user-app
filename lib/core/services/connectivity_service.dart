import 'package:connectivity_plus/connectivity_plus.dart';

/// Watches network connectivity and provides a stream + one-shot check.
class ConnectivityService {
  final Connectivity _connectivity = Connectivity();

  /// Stream of boolean values — true means connected.
  Stream<bool> get onConnectivityChanged {
    return _connectivity.onConnectivityChanged.map(
      (results) => _isConnected(results),
    );
  }

  /// Synchronous-style check (async under the hood).
  Future<bool> get isConnected async {
    final result = await _connectivity.checkConnectivity();
    return _isConnected(result);
  }

  bool _isConnected(List<ConnectivityResult> results) {
    return results.isNotEmpty &&
        results.any((r) => r != ConnectivityResult.none);
  }
}
