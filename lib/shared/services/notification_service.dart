import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Handles push notification setup and local notification display.
class NotificationService {
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final SupabaseClient _client = Supabase.instance.client;

  /// Initialize notifications.
  Future<void> initialize() async {
    // Request permission
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Android settings
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS settings
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
      settings: initSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    // Get FCM token
    final token = await _messaging.getToken();
    if (token != null) {
      await _saveToken(token);
    }

    // Listen for token refresh
    _messaging.onTokenRefresh.listen(_saveToken);

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle background messages
    FirebaseMessaging.onBackgroundMessage(
        _firebaseMessagingBackgroundHandler);

    // Handle notification tap (app terminated)
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);
  }

  void _onNotificationTap(NotificationResponse response) {
    final payload = response.payload;
    if (payload != null && payload.isNotEmpty) {
      debugPrint('Notification tapped: $payload');
    }
  }

  void _handleForegroundMessage(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;

    final title = notification.title ?? '';
    final body = notification.body ?? '';
    final conversationId = message.data['conversation_id'];

    showNotification(
      title: title,
      body: body,
      payload: conversationId,
    );
  }

  void _handleNotificationTap(RemoteMessage message) {
    final conversationId = message.data['conversation_id'];
    debugPrint('Notification opened: $conversationId');
  }

  /// Show a local notification.
  Future<void> showNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'gapshap_messages',
      'Messages',
      channelDescription: 'New message notifications',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final id = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    await _localNotifications.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: details,
      payload: payload,
    );
  }

  /// Remove FCM token on logout
  Future<void> removeToken() async {
    final token = await _messaging.getToken();
    if (token == null) return;

    try {
      await _client.from('push_tokens').delete().eq('token', token);
    } catch (_) {
      // Silently fail
    }
  }

  Future<void> _saveToken(String token) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return;

      await _client.from('push_tokens').upsert({
        'user_id': userId,
        'token': token,
        'platform': Theme.of(navigatorKey.currentContext!).platform ==
                TargetPlatform.iOS
            ? 'ios'
            : 'android',
      });
    } catch (e) {
      debugPrint('Failed to save push token: $e');
    }
  }

  /// Global navigator key for context access
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();
}

/// Background message handler (must be top-level function)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('Background message: ${message.messageId}');
}
