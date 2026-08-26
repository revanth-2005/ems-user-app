import 'dart:developer';
import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../network/api_client.dart';

/// Top-level background message handler for FCM
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();
  } catch (_) {}
  log('[FCM Background] Message received: ${message.messageId}, data: ${message.data}');
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  FirebaseMessaging get _fcm => FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  String? _fcmToken;
  String? get fcmToken => _fcmToken;

  /// Fetches or retrieves cached FCM token safely
  Future<String?> getOrFetchToken() async {
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp();
      }
      _fcmToken ??= await _fcm.getToken();
      if (_fcmToken != null) {
        syncDeviceToken(_fcmToken!);
      }
      return _fcmToken;
    } catch (e) {
      log('[FCM] Error in getOrFetchToken: $e');
      return null;
    }
  }

  static const String channelId = 'eventsphere_high_importance';
  static const String channelName = 'High Importance Notifications';

  /// Initialize Firebase, FCM, and Local Notifications
  Future<void> initialize({
    Function(Map<String, dynamic> data)? onNotificationClick,
  }) async {
    try {
      await Firebase.initializeApp();
    } catch (e) {
      log('[FCM] Firebase.initializeApp warning/error: $e');
    }

    // 1. Set background handler
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // 2. Request Permissions (iOS & Android 13+)
    try {
      final settings = await _fcm.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );
      log('[FCM] Permission status: ${settings.authorizationStatus}');

      // Enable Foreground Presentation for iOS / Android
      await _fcm.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );
    } catch (e) {
      log('[FCM] Permission request error: $e');
    }

    // 3. Initialize Local Notifications (For Foreground Popups)
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        if (response.payload != null && onNotificationClick != null) {
          // Payload parsed from foreground click
        }
      },
    );

    // 4. Create High Importance Android Notification Channel
    const androidChannel = AndroidNotificationChannel(
      channelId,
      channelName,
      description: 'Used for important booking, ticket, and event updates',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
    );

    final androidPlugin = _localNotifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      await androidPlugin.createNotificationChannel(androidChannel);
    }

    // 5. Get Initial Device Token & Listen to Token Refreshes
    try {
      _fcmToken = await _fcm.getToken();
      if (_fcmToken != null) {
        log('╔══════════════════════════════════════════════════════════════════');
        log('║ 🔔 [FIREBASE FCM TOKEN] ║ $_fcmToken');
        log('╚══════════════════════════════════════════════════════════════════');
        syncDeviceToken(_fcmToken!);
      }
    } catch (e) {
      log('[FCM] Error getting token: $e');
    }

    _fcm.onTokenRefresh.listen((newToken) {
      _fcmToken = newToken;
      log('╔══════════════════════════════════════════════════════════════════');
      log('║ 🔔 [FIREBASE FCM TOKEN REFRESHED] ║ $newToken');
      log('╚══════════════════════════════════════════════════════════════════');
      syncDeviceToken(newToken);
    });

    // 6. Handle Foreground Notifications
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      log('[FCM Foreground] Title: ${message.notification?.title}, Body: ${message.notification?.body}');
      final notification = message.notification;
      final android = message.notification?.android;

      if (notification != null) {
        _localNotifications.show(
          notification.hashCode,
          notification.title ?? 'EventSphere Update',
          notification.body ?? '',
          NotificationDetails(
            android: AndroidNotificationDetails(
              channelId,
              channelName,
              channelDescription: 'Event updates and alerts',
              importance: Importance.max,
              priority: Priority.high,
              icon: android?.smallIcon ?? '@mipmap/ic_launcher',
              playSound: true,
              enableVibration: true,
            ),
            iOS: const DarwinNotificationDetails(
              presentAlert: true,
              presentBadge: true,
              presentSound: true,
            ),
          ),
          payload: message.data.toString(),
        );
      }
    });

    // 7. Handle Notification Click (App opened from Background or Terminated)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      log('[FCM OpenedApp] User clicked notification: ${message.data}');
      if (onNotificationClick != null) {
        onNotificationClick(message.data);
      }
    });

    final initialMessage = await _fcm.getInitialMessage();
    if (initialMessage != null && onNotificationClick != null) {
      log('[FCM InitialMessage] App launched from terminated state: ${initialMessage.data}');
      onNotificationClick(initialMessage.data);
    }
  }

  /// Syncs FCM Token with Backend
  Future<void> syncDeviceToken(String token) async {
    try {
      final deviceType = Platform.isAndroid ? 'ANDROID' : (Platform.isIOS ? 'IOS' : 'OTHER');
      await ApiClient().dio.post(
        '/notifications/device-token',
        data: {
          'fcmToken': token,
          'deviceType': deviceType,
        },
      );
      log('[FCM] Device token registered with backend successfully.');
    } catch (e) {
      // Gracefully ignore if endpoint is not implemented yet on backend
      log('[FCM] Note: Backend endpoint /notifications/device-token not active yet ($e)');
    }
  }

  /// Unregisters FCM token on user logout
  Future<void> unregisterDeviceToken() async {
    if (_fcmToken == null) return;
    try {
      await ApiClient().dio.delete(
        '/notifications/device-token',
        data: {'fcmToken': _fcmToken},
      );
      log('[FCM] Device token unregistered from backend.');
    } catch (_) {}
  }

  /// Triggers a test local notification to verify device channel setup
  Future<void> showTestNotification() async {
    await _localNotifications.show(
      999,
      '🎉 EventSphere Notification Test',
      'Firebase Cloud Messaging & local notifications are working perfectly!',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          channelName,
          channelDescription: 'Event updates and alerts',
          importance: Importance.max,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          playSound: true,
          enableVibration: true,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
    );
  }
}
