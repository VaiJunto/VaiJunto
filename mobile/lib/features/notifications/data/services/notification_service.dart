import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

class NotificationService {
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
        print('FCM Token do Dispositivo: $token');
        // TODO: Enviar esse token para o backend associado ao UserModel.id

        FirebaseMessaging.onMessage.listen((RemoteMessage message) {
          if (onMessageReceived != null) {
            onMessageReceived!(message);
          }
        });
      }
    } catch (e) {
      print('Erro ao inicializar Firebase Messaging no ambiente local: $e');
    }
  }
}
