import 'dart:convert';
import 'package:edi/constants/error_handling.dart';
import 'package:edi/constants/global_variables.dart';
import 'package:edi/constants/utils.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class PushNotificationService {
  static final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  // Initialize push notifications
  static Future<void> initialize() async {
    // Request permission
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('Push notification permission granted');
    }

    // Initialize local notifications
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const settings = InitializationSettings(android: androidSettings, iOS: iosSettings);
    
    await _localNotifications.initialize(settings);

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Foreground message: ${message.notification?.title}');
      _showNotification(
        message.notification?.title ?? 'Notification',
        message.notification?.body ?? '',
      );
    });

    // Handle background messages
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }

  // Background message handler
  @pragma('vm:entry-point')
  static Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
    print('Background message: ${message.notification?.title}');
  }

  // Show local notification
  static Future<void> _showNotification(String title, String body) async {
    const androidDetails = AndroidNotificationDetails(
      'attendance_channel',
      'Attendance Notifications',
      importance: Importance.high,
      priority: Priority.high,
    );
    const iosDetails = DarwinNotificationDetails();
    const details = NotificationDetails(android: androidDetails, iOS: iosDetails);
    
    await _localNotifications.show(0, title, body, details);
  }

  // Get FCM token
  static Future<String?> getFCMToken() async {
    try {
      String? token = await _firebaseMessaging.getToken();
      return token;
    } catch (e) {
      print('Error getting FCM token: $e');
      return null;
    }
  }

  // Register device token with backend
  static Future<bool> registerDeviceToken(BuildContext context) async {
    try {
      String? token = await getFCMToken();
      
      if (token == null) {
        return false;
      }

      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? jwtToken = prefs.getString('jwt_token');
      
      if (jwtToken == null) {
        return false;
      }

      http.Response res = await http.post(
        Uri.parse('$uri/api/notifications/register/'),
        body: jsonEncode({'fcm_token': token}),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $jwtToken',
        },
      );

      if (res.statusCode == 200) {
        print('Device token registered successfully');
        return true;
      } else {
        print('Failed to register device token: ${res.statusCode}');
        return false;
      }
    } catch (e) {
      print('Error registering device token: $e');
      return false;
    }
  }

  // Subscribe to course notifications
  static Future<bool> subscribeToCourse(BuildContext context, int courseId) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? jwtToken = prefs.getString('jwt_token');
      
      if (jwtToken == null) {
        return false;
      }

      http.Response res = await http.post(
        Uri.parse('$uri/api/notifications/subscribe/$courseId/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $jwtToken',
        },
      );

      if (res.statusCode == 200) {
        showSnackBar(context, 'Subscribed to course notifications');
        return true;
      } else {
        return false;
      }
    } catch (e) {
      print('Error subscribing to course: $e');
      return false;
    }
  }

  // Unsubscribe from course notifications
  static Future<bool> unsubscribeFromCourse(BuildContext context, int courseId) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? jwtToken = prefs.getString('jwt_token');
      
      if (jwtToken == null) {
        return false;
      }

      http.Response res = await http.delete(
        Uri.parse('$uri/api/notifications/subscribe/$courseId/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $jwtToken',
        },
      );

      if (res.statusCode == 200) {
        showSnackBar(context, 'Unsubscribed from course notifications');
        return true;
      } else {
        return false;
      }
    } catch (e) {
      print('Error unsubscribing from course: $e');
      return false;
    }
  }
}
