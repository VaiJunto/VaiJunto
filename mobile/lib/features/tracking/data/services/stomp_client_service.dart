import 'dart:convert';
import 'dart:developer' as developer;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stomp_dart_client/stomp.dart';
import 'package:stomp_dart_client/stomp_config.dart';
import 'package:stomp_dart_client/stomp_frame.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/storage/secure_storage.dart';
import '../../../../core/models/location_model.dart';

final stompClientProvider = Provider<StompClientService>((ref) {
  final secureStorage = ref.watch(secureStorageProvider);
  return StompClientService(secureStorage);
});

class StompClientService {
  final SecureStorage _secureStorage;
  StompClient? _stompClient;
  final Set<String> _chatSubscriptions = <String>{};

  Function(LocationModel)? onLocationReceived;
  Function(String conversationId, bool typing)? onTypingReceived;
  Function(String conversationId, double latitude, double longitude)?
      onLiveLocationReceived;

  // Derivado do mesmo API_BASE_URL do ApiClient (dev: --dart-define=API_BASE_URL=
  // http://10.0.2.2:8080/api/v1 no emulador; prod: https://api.vaijunto.app.br/api/v1),
  // trocando o esquema http(s) -> ws(s) e o path /api/v1 -> /ws-tracking. Assim o
  // WebSocket segue o mesmo host de produção da API REST sem precisar de outra flag.
  static String get wsUrl {
    final apiUri = Uri.parse(ApiClient.baseUrl);
    final wsScheme = apiUri.scheme == 'https' ? 'wss' : 'ws';
    return apiUri.replace(scheme: wsScheme, path: '/ws-tracking').toString();
  }

  StompClientService(this._secureStorage);

  Future<void> connect(String tripId) async {
    final token = await _secureStorage.getToken();
    if (token == null) return;

    _stompClient = StompClient(
      config: StompConfig.sockJS(
        url: wsUrl,
        stompConnectHeaders: {'Authorization': 'Bearer $token'},
        webSocketConnectHeaders: {'Authorization': 'Bearer $token'},
        onConnect: (StompFrame frame) {
          _subscribeToTrip(tripId);
        },
        onWebSocketError: (dynamic error) => developer.log(
          'WebSocket connection failed.',
          error: error,
          name: 'StompClientService',
        ),
      ),
    );

    _stompClient?.activate();
  }

  Future<void> connectChat(String conversationId) async {
    final token = await _secureStorage.getToken();
    if (token == null) return;
    _stompClient ??= StompClient(
        config: StompConfig.sockJS(
            url: wsUrl,
            stompConnectHeaders: {'Authorization': 'Bearer $token'},
            webSocketConnectHeaders: {'Authorization': 'Bearer $token'},
            onConnect: (_) => _subscribeToChat(conversationId),
            onWebSocketError: (_) {}));
    if (_stompClient!.isActive) {
      _subscribeToChat(conversationId);
    } else {
      _stompClient!.activate();
    }
  }

  void _subscribeToChat(String conversationId) {
    if (!_chatSubscriptions.add(conversationId)) return;
    _stompClient?.subscribe(
        destination: '/user/queue/chat/typing',
        callback: (frame) {
          if (frame.body == null) return;
          final value = json.decode(frame.body!);
          if (onTypingReceived != null) {
            onTypingReceived!(
                value['conversationId'] as String, value['typing'] as bool);
          }
        });
    _stompClient?.subscribe(
        destination: '/user/queue/chat/location',
        callback: (frame) {
          if (frame.body == null) return;
          final value = json.decode(frame.body!) as Map<String, dynamic>;
          onLiveLocationReceived?.call(
              value['conversationId'] as String,
              (value['latitude'] as num).toDouble(),
              (value['longitude'] as num).toDouble());
        });
  }

  void sendTyping(String conversationId, bool typing) {
    if (_stompClient?.isActive ?? false) {
      _stompClient?.send(
          destination: '/app/chat/typing',
          body: json
              .encode({'conversationId': conversationId, 'typing': typing}));
    }
  }

  void sendLiveLocation(String conversationId, double latitude,
      double longitude, DateTime expiresAt) {
    if (_stompClient?.isActive ?? false) {
      _stompClient?.send(
          destination: '/app/chat/location',
          body: json.encode({
            'conversationId': conversationId,
            'latitude': latitude,
            'longitude': longitude,
            'expiresAtEpochMs': expiresAt.millisecondsSinceEpoch,
          }));
    }
  }

  void _subscribeToTrip(String tripId) {
    _stompClient?.subscribe(
      destination: '/topic/trips/$tripId/tracking',
      callback: (StompFrame frame) {
        if (frame.body != null) {
          final result = json.decode(frame.body!);
          final location = LocationModel(
            latitude: (result['latitude'] as num).toDouble(),
            longitude: (result['longitude'] as num).toDouble(),
          );
          if (onLocationReceived != null) {
            onLocationReceived!(location);
          }
        }
      },
    );
  }

  void sendLocationUpdate(
      String tripId, double lat, double lon, double speed, double heading) {
    if (_stompClient != null && _stompClient!.isActive) {
      final payload = json.encode({
        'tripInstanceId': tripId,
        'latitude': lat,
        'longitude': lon,
        'speed': speed,
        'heading': heading,
      });

      _stompClient?.send(
        destination: '/app/tracking/update',
        body: payload,
      );
    }
  }

  void disconnect() {
    _stompClient?.deactivate();
  }
}
