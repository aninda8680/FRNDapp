import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

import 'auth_service.dart';

final likesBadgeProvider = StateProvider<int>((ref) => 0);

class FcmTokenManager {
  static final _messaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> initNotifications(WidgetRef ref) async {
    // 1. Request Permission upfront (as per user preference)
    await requestNotificationPermissions();

    // 2. Register Token
    if (AuthService.userId != null) {
      await registerDeviceToken(AuthService.userId!);
      await _messaging.subscribeToTopic('global_announcements');
    }

    // Explicitly print token for testing purposes as requested
    final token = await _messaging.getToken();
    print("FCM TOKEN: $token");

    // 3. Local Notifications Setup (for Foreground)
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    // For iOS, you'd add DarwinInitializationSettings here.
    
    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);
        
    await _localNotificationsPlugin.initialize(settings: initializationSettings);

    // 4. Foreground Message Listener
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint("Foreground message received: ${message.data}");
      _handleForegroundMessage(message, ref);
    });
  }

  static Future<void> requestNotificationPermissions() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    debugPrint('User granted permission: ${settings.authorizationStatus}');
    if (settings.authorizationStatus == AuthorizationStatus.authorized || 
        settings.authorizationStatus == AuthorizationStatus.provisional) {
      if (AuthService.userId != null) {
        await registerDeviceToken(AuthService.userId!);
      }
    }
  }

  static Future<void> registerDeviceToken(String userId) async {
    try {
      String? token = await _messaging.getToken();
      if (token != null) {
        await _sendTokenToBackend(userId, token);
      }
      _messaging.onTokenRefresh.listen((newToken) {
        _sendTokenToBackend(userId, newToken);
      });
    } catch (e) {
      debugPrint("FCM Error generating token: $e");
    }
  }

  static Future<void> invalidateToken(String userId) async {
    try {
      final token = await _messaging.getToken();
      await _messaging.deleteToken();
      if (token != null) {
        final url = Uri.parse('${AuthService.baseUrl}/fcm-token');
        await http.delete(
          url,
          headers: {'Cookie': 'token=${AuthService.cookie ?? ""}', 'Content-Type': 'application/json'},
          body: json.encode({'token': token})
        );
      }
    } catch (e) {
      debugPrint("FCM Error deleting token: $e");
    }
  }

  static Future<void> _sendTokenToBackend(String userId, String token) async {
    debugPrint("Saving FCM Token for $userId: $token");
    try {
      final url = Uri.parse('${AuthService.baseUrl}/fcm-token');
      await http.post(
        url,
        headers: {'Cookie': 'token=${AuthService.cookie ?? ""}', 'Content-Type': 'application/json'},
        body: json.encode({'token': token})
      );
    } catch (e) {
      debugPrint("Error sending FCM token to backend: $e");
    }
  }

  static void _handleForegroundMessage(RemoteMessage message, WidgetRef ref) {
    final type = message.data['type'];

    if (type == 'like') {
      ref.read(likesBadgeProvider.notifier).update((state) => state + 1);
      // Suppress local push for likes when in foreground
    } else {
      // Chat or announcement -> show local notification
      _showLocalNotification(message);
    }
  }

  static void _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'campusmatch_channel_id',
      'CampusMatch Notifications',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
    );

    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await _localNotificationsPlugin.show(
      id: notification.hashCode,
      title: notification.title,
      body: notification.body,
      notificationDetails: platformChannelSpecifics,
    );
  }
}
