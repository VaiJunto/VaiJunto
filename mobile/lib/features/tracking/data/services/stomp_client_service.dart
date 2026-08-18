import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stomp_dart_client/stomp.dart';
import 'package:stomp_dart_client/stomp_config.dart';
import 'package:stomp_dart_client/stomp_frame.dart';

import '../../../../core/models/location_model.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/storage/secure_storage.dart';

final stompClientProvider = Provider<StompClientService>((ref) {
  final service = StompClientService(ref.watch(secureStorageProvider));
  ref.onDispose(service.dispose);
  return service;
});

class TypingEvent {
  const TypingEvent(this.conversationId, this.typing);
  final String conversationId;
  final bool typing;
}

class LiveLocationEvent {
  const LiveLocationEvent(this.conversationId, this.latitude, this.longitude);
  final String conversationId;
  final double latitude;
  final double longitude;
}

class RealtimeEvent {
  const RealtimeEvent(
      {required this.eventId, required this.type, required this.payload});
  final String eventId;
  final String type;
  final Map<String, dynamic> payload;

  factory RealtimeEvent.fromJson(Map<String, dynamic> json) => RealtimeEvent(
        eventId: json['eventId']?.toString() ?? '',
        type: json['type']?.toString() ?? '',
        payload: Map<String, dynamic>.from(json['payload'] as Map? ?? const {}),
      );
}

class StompClientService {
  StompClientService(this._secureStorage);
  final SecureStorage _secureStorage;
  StompClient? _client;
  final _typing = StreamController<TypingEvent>.broadcast();
  final _liveLocations = StreamController<LiveLocationEvent>.broadcast();
  final _events = StreamController<RealtimeEvent>.broadcast();
  final _connection = StreamController<bool>.broadcast();
  final _tripLocations = StreamController<LocationModel>.broadcast();
  final _seenEventIds = <String>{};
  final _tripIds = <String>{};
  bool _subscribedPrivateQueues = false;

  Stream<TypingEvent> get typingEvents => _typing.stream;
  Stream<LiveLocationEvent> get liveLocationEvents => _liveLocations.stream;
  Stream<RealtimeEvent> get events => _events.stream;
  Stream<bool> get connectionChanges => _connection.stream;
  Stream<LocationModel> get tripLocations => _tripLocations.stream;
  bool get isConnected => _client?.connected ?? false;

  static String get wsUrl {
    final apiUri = Uri.parse(ApiClient.baseUrl);
    return apiUri
        .replace(
          scheme: apiUri.scheme == 'https' ? 'wss' : 'ws',
          path: '/ws-tracking',
        )
        .toString();
  }

  Future<void> connect([String? tripId]) async {
    if (tripId != null) _tripIds.add(tripId);
    if (_client?.isActive ?? false) {
      if (tripId != null && isConnected) _subscribeTrip(tripId);
      return;
    }
    final token = await _secureStorage.getToken();
    if (token == null) return;
    _client = StompClient(
      config: StompConfig.sockJS(
        url: wsUrl,
        reconnectDelay: const Duration(seconds: 3),
        heartbeatIncoming: const Duration(seconds: 15),
        heartbeatOutgoing: const Duration(seconds: 15),
        stompConnectHeaders: {'Authorization': 'Bearer $token'},
        webSocketConnectHeaders: {'Authorization': 'Bearer $token'},
        onConnect: _onConnect,
        onDisconnect: (_) {
          _subscribedPrivateQueues = false;
          _connection.add(false);
        },
        onWebSocketError: (error) {
          _connection.add(false);
          developer.log('WebSocket connection failed.',
              error: error, name: 'StompClientService');
        },
      ),
    )..activate();
  }

  Future<void> connectChat(String conversationId) => connect();

  void _onConnect(StompFrame _) {
    _connection.add(true);
    _subscribePrivateQueues();
    for (final tripId in _tripIds) {
      _subscribeTrip(tripId);
    }
  }

  void _subscribePrivateQueues() {
    if (_subscribedPrivateQueues) return;
    _subscribedPrivateQueues = true;
    _client?.subscribe(
        destination: '/user/queue/chat/typing',
        callback: (frame) {
          final value = _decode(frame);
          if (value != null) {
            _typing.add(TypingEvent(
                value['conversationId'].toString(), value['typing'] == true));
          }
        });
    _client?.subscribe(
        destination: '/user/queue/chat/location',
        callback: (frame) {
          final value = _decode(frame);
          if (value != null) {
            _liveLocations.add(LiveLocationEvent(
              value['conversationId'].toString(),
              (value['latitude'] as num).toDouble(),
              (value['longitude'] as num).toDouble(),
            ));
          }
        });
    _client?.subscribe(
        destination: '/user/queue/events',
        callback: (frame) {
          final value = _decode(frame);
          if (value == null) return;
          final event = RealtimeEvent.fromJson(value);
          if (event.eventId.isNotEmpty && !_seenEventIds.add(event.eventId)) {
            return;
          }
          if (_seenEventIds.length > 500) {
            _seenEventIds.remove(_seenEventIds.first);
          }
          _events.add(event);
        });
  }

  Map<String, dynamic>? _decode(StompFrame frame) {
    if (frame.body == null) return null;
    try {
      return Map<String, dynamic>.from(jsonDecode(frame.body!) as Map);
    } catch (error) {
      developer.log('Invalid STOMP payload.',
          error: error, name: 'StompClientService');
      return null;
    }
  }

  void sendTyping(String conversationId, bool typing) => _send(
      '/app/chat/typing', {'conversationId': conversationId, 'typing': typing});

  void sendLiveLocation(String conversationId, double latitude,
          double longitude, DateTime expiresAt) =>
      _send('/app/chat/location', {
        'conversationId': conversationId,
        'latitude': latitude,
        'longitude': longitude,
        'expiresAtEpochMs': expiresAt.millisecondsSinceEpoch,
      });

  void _subscribeTrip(String tripId) {
    _client?.subscribe(
        destination: '/topic/trips/$tripId/tracking',
        callback: (frame) {
          final value = _decode(frame);
          if (value != null) {
            _tripLocations.add(LocationModel(
              latitude: (value['latitude'] as num).toDouble(),
              longitude: (value['longitude'] as num).toDouble(),
            ));
          }
        });
  }

  void sendLocationUpdate(String tripId, double lat, double lon, double speed,
          double heading) =>
      _send('/app/tracking/update', {
        'tripInstanceId': tripId,
        'latitude': lat,
        'longitude': lon,
        'speed': speed,
        'heading': heading,
      });

  void _send(String destination, Map<String, Object> payload) {
    if (isConnected) {
      _client?.send(destination: destination, body: jsonEncode(payload));
    }
  }

  void disconnect() {
    _client?.deactivate();
    _client = null;
    _subscribedPrivateQueues = false;
  }

  void dispose() {
    disconnect();
    _typing.close();
    _liveLocations.close();
    _events.close();
    _connection.close();
    _tripLocations.close();
  }
}
