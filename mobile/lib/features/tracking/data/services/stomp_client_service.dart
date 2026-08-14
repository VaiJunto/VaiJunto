import 'dart:convert';
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

  Function(LocationModel)? onLocationReceived;

  // Derivado do mesmo API_BASE_URL do ApiClient (dev: --dart-define=API_BASE_URL=
  // http://10.0.2.2:8080/api/v1 no emulador; prod: https://api.vaijunto.app.br/api/v1),
  // trocando o esquema http(s) -> ws(s) e o path /api/v1 -> /ws-tracking. Assim o
  // WebSocket segue o mesmo host de produção da API REST sem precisar de outra flag.
  static String get wsUrl {
    final apiUri = Uri.parse(ApiClient.baseUrl);
    final wsScheme = apiUri.scheme == 'https' ? 'wss' : 'ws';
    return apiUri
        .replace(scheme: wsScheme, path: '/ws-tracking')
        .toString();
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
        onWebSocketError: (dynamic error) => print(error.toString()),
      ),
    );

    _stompClient?.activate();
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
