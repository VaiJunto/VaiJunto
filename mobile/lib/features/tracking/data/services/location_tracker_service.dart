import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'stomp_client_service.dart';

final locationTrackerProvider = Provider<LocationTrackerService>((ref) {
  final stompService = ref.watch(stompClientProvider);
  return LocationTrackerService(stompService);
});

class LocationTrackerService {
  final StompClientService _stompService;
  StreamSubscription<Position>? _positionStreamSubscription;

  LocationTrackerService(this._stompService);

  Future<void> startTrackingDriver(String tripId) async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    if (permission == LocationPermission.deniedForever) return;

    // Configuração adaptativa de bateria (LocationSettings)
    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10, // Atualiza a cada 10 metros
    );

    _stompService.connect(tripId);

    _positionStreamSubscription =
        Geolocator.getPositionStream(locationSettings: locationSettings)
            .listen((Position position) {
      _stompService.sendLocationUpdate(
        tripId,
        position.latitude,
        position.longitude,
        position.speed,
        position.heading,
      );
    });
  }

  void stopTracking() {
    _positionStreamSubscription?.cancel();
    _positionStreamSubscription = null;
    _stompService.disconnect();
  }
}
