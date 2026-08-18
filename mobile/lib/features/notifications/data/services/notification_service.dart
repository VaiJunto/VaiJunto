import 'dart:developer' as developer;
import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';

final notificationServiceProvider = Provider<NotificationService>((ref) {
  final service = NotificationService(ref.watch(dioProvider));
  ref.onDispose(service.dispose);
  return service;
});

class NotificationService {
  NotificationService(this._dio);
  final Dio _dio;
  late final FirebaseMessaging _messaging;
  final _openedMessages = StreamController<Map<String, dynamic>>.broadcast();
  final _foregroundMessages =
      StreamController<Map<String, dynamic>>.broadcast();
  StreamSubscription<RemoteMessage>? _openedSubscription;
  StreamSubscription<RemoteMessage>? _foregroundSubscription;
  bool _initialized = false;

  Stream<Map<String, dynamic>> get openedMessages => _openedMessages.stream;
  Stream<Map<String, dynamic>> get foregroundMessages =>
      _foregroundMessages.stream;

  Function(RemoteMessage)? onMessageReceived;

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
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

        _foregroundSubscription =
            FirebaseMessaging.onMessage.listen((RemoteMessage message) {
          _foregroundMessages.add(message.data);
          if (onMessageReceived != null) {
            onMessageReceived!(message);
          }
        });
        _openedSubscription = FirebaseMessaging.onMessageOpenedApp
            .listen((message) => _openedMessages.add(message.data));
        final initialMessage = await _messaging.getInitialMessage();
        if (initialMessage != null) {
          Future<void>.delayed(
              Duration.zero, () => _openedMessages.add(initialMessage.data));
        }
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

  void dispose() {
    _openedSubscription?.cancel();
    _foregroundSubscription?.cancel();
    _openedMessages.close();
    _foregroundMessages.close();
  }
}
