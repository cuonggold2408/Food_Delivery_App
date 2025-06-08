import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:frontend/main.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class FirebaseService {
  static final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  static final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

  // Initialize local notifications
  static Future<void> initializeLocalNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );
    await _notificationsPlugin.initialize(initializationSettings);
  }

  // Get device token
  static Future<String?> getDeviceToken() async {
    try {
      NotificationSettings settings = await _firebaseMessaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        print('User granted permission');
      } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
        print('User granted provisional permission');
      } else {
        print('User declined or has not accepted permission');
        return null;
      }

      String? token = await _firebaseMessaging.getToken();
      print('Firebase Device Token: $token');
      return token;
    } catch (e) {
      print('Error getting device token: $e');
      return null;
    }
  }

  // Register device token with server
  static Future<void> registerDeviceToken(String userToken) async {
    try {
      String? deviceToken = await getDeviceToken();
      if (deviceToken != null) {
        await _registerTokenWithServer(deviceToken, userToken);
      }
    } catch (e) {
      print('Error registering device token: $e');
    }
  }

  // Call backend API to register token
  static Future<void> _registerTokenWithServer(String deviceToken, String userToken) async {
    try {
      final response = await http.post(
        Uri.parse('https://api.df.nguyenquangcuong.pro/firebase/notifications/register-device'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $userToken',
        },
        body: json.encode({
          'deviceToken': deviceToken,
          'deviceType': defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android',
        }),
      );

      if (response.statusCode == 200) {
        print('Device token registered successfully');
      } else {
        print('Failed to register device token: ${response.statusCode}');
      }
    } catch (e) {
      print('Error calling register API: $e');
    }
  }

  // Trigger custom notification
  static Future<void> triggerCustomNotification(String userToken, String username, String message, String profileImageUrl) async {
    try {
      final response = await http.post(
        Uri.parse('https://api.df.nguyenquangcuong.pro/firebase/notifications/send'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $userToken',
        },
        body: json.encode({
          'to': await getDeviceToken(),
          'notification': {
            'title': username,
            'body': message,
          },
          'data': {
            'profileImageUrl': profileImageUrl,
            'click_action': 'FLUTTER_NOTIFICATION_CLICK',
          },
        }),
      );

      if (response.statusCode == 200) {
        print('Custom notification triggered successfully');
      } else {
        print('Failed to trigger custom notification: ${response.statusCode}');
      }
    } catch (e) {
      print('Error triggering custom notification: $e');
    }
  }

  // Trigger payment success notification
  static Future<void> triggerPaymentSuccessNotification(String userToken, int orderId) async {
    try {
      final response = await http.put(
        Uri.parse('https://api.df.nguyenquangcuong.pro/firebase/notifications/$orderId/status'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $userToken',
        },
        body: json.encode({
          'title': 'Thanh toán thành công',
          'body': 'Đơn hàng #$orderId của bạn đã được thanh toán thành công!',
          'status': 'success',
          'type': 'order_status_update',
          'orderId': orderId.toString(),
          'data': {
            'profileImageUrl': 'https://via.placeholder.com/40',
            'click_action': 'FLUTTER_NOTIFICATION_CLICK',
          },
        }),
      );

      if (response.statusCode == 200) {
        await FirebaseMessaging.instance.subscribeToTopic('update_order_status');
        FirebaseMessaging.onBackgroundMessage((RemoteMessage message) async {
          print('Background message received: ${message.data}');
        });
        print('Payment success notification triggered successfully');
      } else {
        print('Failed to trigger payment success notification: ${response.statusCode}');
      }
    } catch (e) {
      print('Error triggering payment success notification: $e');
    }
  }

  // Show local notification (for immediate display)
  static Future<void> showLocalNotification({
    required String title,
    required String body,
    required String orderId,
    String profileImageUrl = 'https://via.placeholder.com/40',
  }) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'high_importance_channel',
      'High Importance Notifications',
      channelDescription: 'This channel is used for important notifications.',
      importance: Importance.max,
      priority: Priority.high,
    );
    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await _notificationsPlugin.show(
      0,
      title,
      body,
      platformChannelSpecifics,
      payload: json.encode({
        'type': 'order_status_update',
        'orderId': orderId,
        'profileImageUrl': profileImageUrl,
        'click_action': 'FLUTTER_NOTIFICATION_CLICK',
      }),
    );
  }

  // Handle foreground notifications with custom UI
 static void setupForegroundNotificationListener() {
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    print('Got a message whilst in the foreground!');
    print('Message data: ${message.data}');

    if (message.notification != null) {
      print('Message also contained a notification: ${message.notification}');
      showLocalNotification(
        title: message.notification?.title ?? 'Thông báo',
        body: message.notification?.body ?? '',
        orderId: message.data['orderId'] ?? '',
        profileImageUrl: message.data['profileImageUrl'] ?? 'https://via.placeholder.com/40',
      );
    }
  });
}

  // Handle notification taps
  static void setupNotificationTapListener() {
    FirebaseMessaging.instance.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        print('App opened from notification: ${message.data}');
        _handleNotificationTap(message);
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('App opened from background notification: ${message.data}');
      _handleNotificationTap(message);
    });
  }

  static void _handleNotificationTap(RemoteMessage message) {
    if (message.data['type'] == 'order_status_update') {
      String orderId = message.data['orderId'] ?? '';
      navigatorKey.currentState?.pushNamed('/order-detail', arguments: orderId);
    }
  }
  
  // Show in-app notification for payment success
  static void showPaymentSuccessInAppNotification(String orderId) {
    scaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            CircleAvatar(
              backgroundImage: NetworkImage('https://via.placeholder.com/40'),
              radius: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Thanh toán thành công',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  Text(
                    'Đơn hàng #$orderId của bạn đã được thanh toán thành công!',
                    style: const TextStyle(fontSize: 14),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        duration: const Duration(seconds: 4),
        backgroundColor: Colors.grey[900],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        action: SnackBarAction(
          label: 'XEM',
          textColor: Colors.white,
          onPressed: () {
            navigatorKey.currentState?.pushNamed('/order-detail', arguments: orderId);
          },
        ),
      ),
    );
  }
}