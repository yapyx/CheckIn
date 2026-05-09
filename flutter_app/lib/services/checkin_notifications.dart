import 'dart:async';
import 'dart:typed_data';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'checkin_api.dart';
import 'firebase_options.dart';

const _emergencyChannelId = 'Emergency';
const _updatesChannelId = 'CaregiverUpdates';
final _emergencyVibration = Int64List.fromList([0, 800, 250, 800, 250, 1200]);

@pragma('vm:entry-point')
Future<void> checkInFirebaseMessagingBackgroundHandler(
    RemoteMessage message) async {
  if (Firebase.apps.isEmpty && CheckInFirebaseOptions.isConfigured) {
    await Firebase.initializeApp(
      options: CheckInFirebaseOptions.currentPlatform,
    );
  }
}

class CheckInNotifications {
  CheckInNotifications._();

  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  static StreamSubscription<String>? _tokenRefreshSubscription;
  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized || Firebase.apps.isEmpty) return;
    _initialized = true;

    FirebaseMessaging.onBackgroundMessage(
        checkInFirebaseMessagingBackgroundHandler);

    const initializationSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    );
    await _localNotifications.initialize(settings: initializationSettings);
    await _createAndroidChannels();

    FirebaseMessaging.onMessage.listen(_showForegroundNotification);
  }

  static Future<void> registerCaregiverToken({
    required String caregiverId,
    required CheckInApi api,
  }) async {
    if (Firebase.apps.isEmpty) return;

    await _messaging.requestPermission(alert: true, badge: true, sound: true);
    final token = await _messaging.getToken();
    if (token != null && token.isNotEmpty) {
      await api.registerFcmToken(userId: caregiverId, token: token);
    }

    await _tokenRefreshSubscription?.cancel();
    _tokenRefreshSubscription = _messaging.onTokenRefresh.listen((newToken) {
      api.registerFcmToken(userId: caregiverId, token: newToken);
    });
  }

  static Future<void> _createAndroidChannels() async {
    final android = _localNotifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android == null) return;

    await android.createNotificationChannel(
      AndroidNotificationChannel(
        _emergencyChannelId,
        'Emergency alerts',
        description: 'Urgent care alerts that repeat until resolved.',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
        vibrationPattern: _emergencyVibration,
      ),
    );
    await android.createNotificationChannel(
      const AndroidNotificationChannel(
        _updatesChannelId,
        'Caregiver updates',
        description: 'Routine care updates from CheckIn.',
        importance: Importance.defaultImportance,
        playSound: true,
        enableVibration: true,
      ),
    );
  }

  static Future<void> _showForegroundNotification(RemoteMessage message) async {
    final notification = message.notification;
    final isEmergency = message.data['priority'] == 'Emergency';
    await _localNotifications.show(
      id: message.messageId.hashCode,
      title: notification?.title ??
          (isEmergency ? 'Emergency CheckIn' : 'CheckIn update'),
      body: notification?.body ?? 'New care message received.',
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          isEmergency ? _emergencyChannelId : _updatesChannelId,
          isEmergency ? 'Emergency alerts' : 'Caregiver updates',
          channelDescription: isEmergency
              ? 'Urgent care alerts that repeat until resolved.'
              : 'Routine care updates from CheckIn.',
          importance:
              isEmergency ? Importance.max : Importance.defaultImportance,
          priority: isEmergency ? Priority.max : Priority.defaultPriority,
          enableVibration: true,
          vibrationPattern: isEmergency ? _emergencyVibration : null,
        ),
      ),
      payload: message.data['message_id'],
    );
  }
}
