import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../geocoding/geocoding_result_model.dart';
import 'neo_button.dart';
import 'neo_card.dart';

/// Manual search stays available without permission; this is the optional precise-location flow.
class LocationPinPicker extends StatefulWidget {
  const LocationPinPicker({super.key});
  @override
  State<LocationPinPicker> createState() => _LocationPinPickerState();
}

class _LocationPinPickerState extends State<LocationPinPicker> {
  LatLng _pin = const LatLng(-23.1623356, -45.7954102);
  bool _locating = true;
  @override
  void initState() {
    super.initState();
    _loadLocation();
  }

  Future<void> _loadLocation() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        return;
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return;
      }
      final position = await Geolocator.getCurrentPosition();
      if (mounted) {
        setState(() => _pin = LatLng(position.latitude, position.longitude));
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('AJUSTE O PINO')),
        body: Column(children: [
          Expanded(
              child: Stack(children: [
            GoogleMap(
                initialCameraPosition: CameraPosition(target: _pin, zoom: 16),
                markers: {
                  Marker(
                      markerId: const MarkerId('selected'),
                      position: _pin,
                      draggable: true,
                      onDragEnd: (value) => setState(() => _pin = value))
                },
                onTap: (value) => setState(() => _pin = value),
                myLocationEnabled: true),
            if (_locating)
              const Align(
                  alignment: Alignment.topCenter,
                  child: Padding(
                      padding: EdgeInsets.all(12),
                      child: NeoCard(child: Text('BUSCANDO SUA LOCALIZAÇÃO')))),
          ])),
          SafeArea(
              top: false,
              child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: NeoButton(
                      onPressed: () => Navigator.pop(
                          context,
                          GeocodingResult(
                              displayName: 'Localização selecionada',
                              primaryText: 'Localização selecionada',
                              secondaryText: 'Pino ajustado no mapa',
                              latitude: _pin.latitude,
                              longitude: _pin.longitude,
                              distanceKm: null)),
                      child: const Text('USAR ESTE PINO')))),
        ]),
      );
}
