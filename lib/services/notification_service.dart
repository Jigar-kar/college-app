// ignore_for_file: deprecated_member_use

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

Future<void> backgroundhandler(RemoteMessage message) async {
  // Handle background messages
  print('Background message: ${message.notification?.title}');
}

class NotificationPriority {
  static const String high = 'high';
  static const String medium = 'medium';
  static const String low = 'low';
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();

  // Static initialization method
  static Future<void> initialize() async {
    final instance = NotificationService();
    await instance.initializeNotifications();
  }

  // Initialize notification services
  Future<void> initializeNotifications() async {
    // Firebase Messaging Setup
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      // Background message handler
      FirebaseMessaging.onBackgroundMessage(backgroundhandler);

      // Foreground message handler
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        _handleForegroundMessage(message);
      });

      // Local Notifications Setup
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

      await _notifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (details) {
          // Handle notification tap
          print('Notification tapped: ${details.payload}');
        },
      );
    }

    // Configure token refresh
    _firebaseMessaging.onTokenRefresh.listen((token) {
      _saveTokenToFirestore(token);
    });
  }

  // Handle foreground messages
  void _handleForegroundMessage(RemoteMessage message) {
    if (message.notification != null) {
      _showLocalNotification(
        title: message.notification!.title ?? 'Notification',
        body: message.notification!.body ?? '',
        payload: message.data['payload'] ?? '',
      );
    }
  }

  // Show local notification
  Future<void> _showLocalNotification({
    required String title, 
    required String body, 
    String payload = '',
  }) async {
    await showNotification(
      title: title,
      body: body,
      payload: payload,
    );
  }

  // Send notification
  Future<bool> sendNotification(
    String fcmToken, 
    String title, 
    String body, {
    Map<String, dynamic>? data,
  }) async {
    try {
      // Validate inputs
      if (fcmToken.isEmpty || title.isEmpty || body.isEmpty) {
        print('Invalid notification parameters');
        return false;
      }

      // Prepare notification payload
      final Map<String, dynamic> message = {
        'to': fcmToken,
        'notification': {
          'title': title,
          'body': body,
        },
        'data': data ?? {},
      };

      // Send the message using Firebase Messaging
      await _firebaseMessaging.sendMessage(
        to: fcmToken,
        data: {
          'title': title,
          'body': body,
          ...?data,
        },
      );

      return true;
    } catch (e) {
      print('Notification sending error: $e');
      return false;
    }
  }

  // Save FCM token to Firestore
  Future<void> _saveTokenToFirestore(String token) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({'fcmToken': token});
    } catch (e) {
      print('Error saving FCM token: $e');
    }
  }

  // Get current FCM token
  Future<String?> getFCMToken() async {
    try {
      return await _firebaseMessaging.getToken();
    } catch (e) {
      print('Error getting FCM token: $e');
      return null;
    }
  }

  // In-app notification storage
  Future<void> storeInAppNotification({
    required String userId,
    required String title,
    required String body,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      await FirebaseFirestore.instance
          .collection('in_app_notifications')
          .add({
        'userId': userId,
        'title': title,
        'body': body,
        'additionalData': additionalData,
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
      });
    } catch (e) {
      print('Error storing in-app notification: $e');
    }
  }

  // Retrieve in-app notifications for a user
  Stream<QuerySnapshot> getUserNotifications(String userId) {
    return FirebaseFirestore.instance
        .collection('in_app_notifications')
        .where('userId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  Future<void> showNotification({
    required String title,
    required String body,
    String? payload,
    String channelId = 'default_channel',
    String channelName = 'Default Channel',
    String channelDescription = 'Default notifications channel',
    Importance importance = Importance.high,
    bool playSound = true,
    bool enableVibration = true,
    String? soundFile,
  }) async {
    try {
      final androidDetails = AndroidNotificationDetails(
        channelId,
        channelName,
        channelDescription: channelDescription,
        importance: importance,
        playSound: playSound,
        enableVibration: enableVibration,
        sound: soundFile != null ? RawResourceAndroidNotificationSound(soundFile) : null,
        icon: '@mipmap/ic_launcher',
        largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
        color: const Color(0xFF1A237E), // Primary color
        category: AndroidNotificationCategory.message,
      );

      // Configure iOS specific settings
      final iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: playSound,
        sound: soundFile,
      );

      final notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      final id = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      await _notifications.show(
        id,
        title,
        body,
        notificationDetails,
        payload: payload,
      );
    } catch (e) {
      print('Error showing notification: $e');
      rethrow;
    }
  }

  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }

  Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
  }
}
