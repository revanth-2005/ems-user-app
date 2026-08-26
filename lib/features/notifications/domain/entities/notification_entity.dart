class AppNotificationEntity {
  final String id;
  final String userId;
  final String? channel;
  final String title;
  final String body;
  final Map<String, dynamic> data;
  final DateTime? readAt;
  final DateTime createdAt;

  const AppNotificationEntity({
    required this.id,
    required this.userId,
    this.channel,
    required this.title,
    required this.body,
    this.data = const {},
    this.readAt,
    required this.createdAt,
  });

  bool get isRead => readAt != null;

  factory AppNotificationEntity.fromJson(Map<String, dynamic> json) {
    return AppNotificationEntity(
      id: json['id']?.toString() ?? '',
      userId: json['userId']?.toString() ?? json['user_id']?.toString() ?? '',
      channel: json['channel']?.toString(),
      title: json['title']?.toString() ?? 'Notification',
      body: json['body']?.toString() ?? '',
      data: json['data'] is Map<String, dynamic>
          ? json['data'] as Map<String, dynamic>
          : <String, dynamic>{},
      readAt: json['readAt'] != null
          ? DateTime.tryParse(json['readAt'].toString())
          : (json['read_at'] != null
              ? DateTime.tryParse(json['read_at'].toString())
              : null),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : (json['created_at'] != null
              ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
              : DateTime.now()),
    );
  }

  AppNotificationEntity copyWith({
    String? id,
    String? userId,
    String? channel,
    String? title,
    String? body,
    Map<String, dynamic>? data,
    DateTime? readAt,
    DateTime? createdAt,
  }) {
    return AppNotificationEntity(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      channel: channel ?? this.channel,
      title: title ?? this.title,
      body: body ?? this.body,
      data: data ?? this.data,
      readAt: readAt ?? this.readAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class NotificationListResponse {
  final List<AppNotificationEntity> notifications;
  final int unreadCount;
  final int total;
  final int page;
  final int totalPages;

  const NotificationListResponse({
    required this.notifications,
    this.unreadCount = 0,
    this.total = 0,
    this.page = 1,
    this.totalPages = 1,
  });

  factory NotificationListResponse.fromJson(Map<String, dynamic> json) {
    final list = (json['data'] as List<dynamic>?)
            ?.whereType<Map<String, dynamic>>()
            .map(AppNotificationEntity.fromJson)
            .toList() ??
        const [];

    final meta = json['meta'] is Map<String, dynamic>
        ? json['meta'] as Map<String, dynamic>
        : <String, dynamic>{};

    return NotificationListResponse(
      notifications: list,
      unreadCount: (json['unreadCount'] ?? json['unread_count'] ?? 0) as int,
      total: (meta['total'] ?? list.length) as int,
      page: (meta['page'] ?? 1) as int,
      totalPages: (meta['totalPages'] ?? 1) as int,
    );
  }
}
