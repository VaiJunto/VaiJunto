import 'dart:developer' as developer;

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService(ref.watch(dioProvider));
});

class NotificationService {
  NotificationService(this._dio);
  final Dio _dio;
  late final FirebaseMessaging _messaging;

  Function(RemoteMessage)? onMessageReceived;

  Future<void> init() async {
    // Requer Firebase configurado via flutterfire configure no ambiente real
    try {
      await Firebase.initializeApp();
      _messaging = FirebaseMessaging.instance;

      NotificationSettings settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        String? token = await _messaging.getToken();
        if (token != null) {
          await _dio
              .post('/notifications/device-token', data: {'token': token});
        }

        FirebaseMessaging.onMessage.listen((RemoteMessage message) {
          if (onMessageReceived != null) {
            onMessageReceived!(message);
          }
        });
      }
    } catch (error, stackTrace) {
      developer.log(
        'Firebase Messaging initialization failed.',
        error: error,
        stackTrace: stackTrace,
        name: 'NotificationService',
      );
    }
  }
}
