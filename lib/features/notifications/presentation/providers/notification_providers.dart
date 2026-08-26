import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../data/datasources/notification_remote_datasource.dart';
import '../../domain/entities/notification_entity.dart';

final notificationRemoteDataSourceProvider =
    Provider<NotificationRemoteDataSource>((ref) {
  return NotificationRemoteDataSource(ApiClient().dio);
});

class NotificationState {
  final List<AppNotificationEntity> notifications;
  final int unreadCount;
  final bool isLoading;
  final String? error;

  const NotificationState({
    this.notifications = const [],
    this.unreadCount = 0,
    this.isLoading = false,
    this.error,
  });

  NotificationState copyWith({
    List<AppNotificationEntity>? notifications,
    int? unreadCount,
    bool? isLoading,
    String? error,
  }) {
    return NotificationState(
      notifications: notifications ?? this.notifications,
      unreadCount: unreadCount ?? this.unreadCount,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class NotificationNotifier extends StateNotifier<NotificationState> {
  final NotificationRemoteDataSource _dataSource;

  NotificationNotifier(this._dataSource) : super(const NotificationState()) {
    fetchNotifications();
  }

  Future<void> fetchNotifications({bool refresh = false}) async {
    if (!refresh && state.notifications.isNotEmpty) {
      // Background re-fetch without full loading spinner
    } else {
      state = state.copyWith(isLoading: true, error: null);
    }

    try {
      final res = await _dataSource.getNotifications(page: 1, limit: 50);
      state = state.copyWith(
        notifications: res.notifications,
        unreadCount: res.unreadCount,
        isLoading: false,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> markAsRead(String id) async {
    try {
      await _dataSource.markAsRead(id);
      final updated = state.notifications.map((n) {
        if (n.id == id) {
          return n.copyWith(readAt: DateTime.now());
        }
        return n;
      }).toList();

      final newUnread = (state.unreadCount - 1) > 0 ? state.unreadCount - 1 : 0;
      state = state.copyWith(
        notifications: updated,
        unreadCount: newUnread,
      );
    } catch (_) {}
  }

  Future<void> markAllAsRead() async {
    try {
      await _dataSource.markAllAsRead();
      final updated = state.notifications.map((n) {
        return n.copyWith(readAt: DateTime.now());
      }).toList();

      state = state.copyWith(
        notifications: updated,
        unreadCount: 0,
      );
    } catch (_) {}
  }
}

final notificationNotifierProvider =
    StateNotifierProvider<NotificationNotifier, NotificationState>((ref) {
  final ds = ref.watch(notificationRemoteDataSourceProvider);
  return NotificationNotifier(ds);
});

final unreadNotificationsCountProvider = Provider<int>((ref) {
  return ref.watch(notificationNotifierProvider).unreadCount;
});
