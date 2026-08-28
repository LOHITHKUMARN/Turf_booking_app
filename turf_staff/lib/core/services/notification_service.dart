import 'dart:developer';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';
import '../constants/api_constants.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  FirebaseMessaging? get _fcm {
    try {
      return FirebaseMessaging.instance;
    } catch (_) {
      return null;
    }
  }
  
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  final ApiService _apiService = ApiService();

  Future<void> init() async {
    final fcm = _fcm;
    if (fcm == null) {
      log('Firebase Messaging not initialized (likely missing configuration)');
      return;
    }

    try {
      // 1. Request Permissions (iOS/Android 13+)
      NotificationSettings settings = await fcm.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        log('User granted notification permissions');
      }

      // 2. Initialize Local Notifications
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher'); // Standard icon
      const InitializationSettings initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid,
      );
      await _localNotifications.initialize(initializationSettings);

      // 3. Handle Foreground Messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        log('Foreground message received: ${message.notification?.title}');
        _showLocalNotification(message);
      });

      // 4. Handle Background/Terminated Click
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        log('Notification causing app to open: ${message.data}');
      });
    } catch (e) {
      log('Error initializing Firebase messaging: $e');
    }
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'turf_notifications',
      'Turf Notifications',
      importance: Importance.max,
      priority: Priority.high,
    );
    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await _localNotifications.show(
      0,
      message.notification?.title,
      message.notification?.body,
      platformChannelSpecifics,
      payload: message.data.toString(),
    );
  }

  Future<void> updateServerToken() async {
    try {
      final fcm = _fcm;
      if (fcm == null) return;

      String? token = await fcm.getToken();
      if (token == null) return;

      log('FCM Token: $token');
      
      final prefs = await SharedPreferences.getInstance();
      final lastToken = prefs.getString('fcmToken');

      // Only update if token changed
      if (token != lastToken) {
        final response = await _apiService.post(
          '${ApiConstants.baseUrl}/auth/fcm-token',
          {'token': token},
        );

        if (response.statusCode == 200) {
          await prefs.setString('fcmToken', token);
          log('FCM Token registered on server successfully');
        }
      }
    } catch (e) {
      log('Error updating FCM token: $e');
    }
  }
}
