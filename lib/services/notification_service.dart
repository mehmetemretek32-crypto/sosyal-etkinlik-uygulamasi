
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationService {
  static final NotificationService _instance =
  NotificationService._internal();

  factory NotificationService() => _instance;

  NotificationService._internal();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;

  final FlutterLocalNotificationsPlugin _localNotifications =
  FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    try {
      NotificationSettings fcmSettings = await _fcm.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (fcmSettings.authorizationStatus ==
          AuthorizationStatus.authorized) {
        debugPrint('Bildirim izni başarıyla alındı!');

        String? token = await _fcm.getToken();
        debugPrint('FCM Cihaz Token: $token');
      }

      const AndroidInitializationSettings androidInitSettings =
      AndroidInitializationSettings('@mipmap/ic_launcher');

      const InitializationSettings initSettings =
      InitializationSettings(android: androidInitSettings);

      await _localNotifications.initialize(
        settings: initSettings,
      );

      const AndroidNotificationChannel channel =
      AndroidNotificationChannel(
        'high_importance_channel',
        'Yüksek Öncelikli Bildirimler',
        description: 'Bu kanal etkinlik hatırlatmaları içindir.',
        importance: Importance.max,
      );

      await _localNotifications
          .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);

      FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
        try {
          final notification = message.notification;

          final String title =
              notification?.title ??
                  message.data['title']?.toString() ??
                  '';

          final String body =
              notification?.body ??
                  message.data['message']?.toString() ??
                  message.data['body']?.toString() ??
                  '';

          if (title.isEmpty && body.isEmpty) return;

          // Oturum açmış kullanıcının UID bilgisini al.
          final user = FirebaseAuth.instance.currentUser;

          if (user != null) {
            // Bildirimi Firestore'a kalıcı olarak kaydet.
            await FirebaseFirestore.instance
                .collection('notifications')
                .add({
              'toUserId': user.uid,
              'title': title,
              'message': body,
              'isRead': false,
              'createdAt': FieldValue.serverTimestamp(),
            });

            debugPrint('Bildirim Firestore veritabanına kaydedildi.');
          }

          // Bildirimi telefon ekranında göster.
          await _localNotifications.show(
            id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
            title: title,
            body: body,
            notificationDetails: NotificationDetails(
              android: AndroidNotificationDetails(
                channel.id,
                channel.name,
                channelDescription: channel.description,
                icon: '@mipmap/ic_launcher',
                importance: Importance.max,
                priority: Priority.high,
                color: const Color(0xFF6A1221),
              ),
            ),
          );
        } catch (e) {
          debugPrint('Bildirim işleme hatası: $e');
        }
      });
    } catch (e) {
      debugPrint('Bildirim servisi başlatma hatası: $e');
      _initialized = false;
    }
  }
}
