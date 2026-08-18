import 'dart:developer' as developer;
import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../../../core/config/firebase_options.dart';
import '../../../../core/network/api_client.dart';

final notificationServiceProvider = Provider<NotificationService>((ref) {
  final service = NotificationService(ref.watch(dioProvider));
  ref.onDispose(service.dispose);
  return service;
});

enum NotificationPermissionState {
  enabled,
  notDetermined,
  denied,
  unavailable,
}

class NotificationService {
  NotificationService(this._dio);
  final Dio _dio;
  FirebaseMessaging? _messaging;
  final _openedMessages = StreamController<Map<String, dynamic>>.broadcast();
  final _foregroundMessages =
      StreamController<Map<String, dynamic>>.broadcast();
  StreamSubscription<RemoteMessage>? _openedSubscription;
  StreamSubscription<RemoteMessage>? _foregroundSubscription;
  StreamSubscription<String>? _tokenSubscription;
  bool _initialized = false;

  static const _webVapidKey =
      'BJYH70kEsZqIGj5KsN94BoKEXu5TlAytHi_ol5H9bdx9SsNHHXzHcl5mHh58cV2C3iW3moD_22wmjWnW8490Jgk';

  Stream<Map<String, dynamic>> get openedMessages => _openedMessages.stream;
  Stream<Map<String, dynamic>> get foregroundMessages =>
      _foregroundMessages.stream;

  Function(RemoteMessage)? onMessageReceived;

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
    try {
      await Firebase.initializeApp(
        options: kIsWeb ? VaiJuntoFirebaseOptions.web : null,
      );
      final messaging = FirebaseMessaging.instance;
      _messaging = messaging;

      _foregroundSubscription =
          FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        _foregroundMessages.add(message.data);
        if (onMessageReceived != null) onMessageReceived!(message);
      });
      _openedSubscription = FirebaseMessaging.onMessageOpenedApp
          .listen((message) => _openedMessages.add(message.data));
      _tokenSubscription = messaging.onTokenRefresh.listen(_registerToken);

      final settings = await messaging.getNotificationSettings();
      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        await _registerCurrentToken();
      }

      final initialMessage = await messaging.getInitialMessage();
      if (initialMessage != null) {
        Future<void>.delayed(
            Duration.zero, () => _openedMessages.add(initialMessage.data));
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

  Future<bool> enablePushNotifications() async {
    await init();
    final messaging = _messaging;
    if (messaging == null) return false;
    final settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    if (settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional) {
      await _registerCurrentToken();
    }
    return settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;
  }

  Future<NotificationPermissionState> permissionState() async {
    await init();
    final messaging = _messaging;
    if (messaging == null) return NotificationPermissionState.unavailable;
    final status =
        (await messaging.getNotificationSettings()).authorizationStatus;
    return switch (status) {
      AuthorizationStatus.authorized ||
      AuthorizationStatus.provisional =>
        NotificationPermissionState.enabled,
      AuthorizationStatus.denied => NotificationPermissionState.denied,
      AuthorizationStatus.notDetermined =>
        NotificationPermissionState.notDetermined,
    };
  }

  Future<void> _registerCurrentToken() async {
    final token = await _messaging?.getToken(
      vapidKey: kIsWeb ? _webVapidKey : null,
    );
    if (token != null) await _registerToken(token);
  }

  Future<void> _registerToken(String token) =>
      _dio.post('/notifications/device-token', data: {'token': token});

  void dispose() {
    _openedSubscription?.cancel();
    _foregroundSubscription?.cancel();
    _tokenSubscription?.cancel();
    _openedMessages.close();
    _foregroundMessages.close();
  }
}
