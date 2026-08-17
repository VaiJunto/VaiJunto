import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../geocoding/geocoding_result_model.dart';
import '../theme/neo_brutal_theme.dart';
import 'neo_button.dart';
import 'neo_card.dart';
import 'neo_street_backdrop.dart';

/// Manual search stays available without permission; this is the optional
/// precise-location flow.
class LocationPinPicker extends StatefulWidget {
  const LocationPinPicker({super.key});

  @override
  State<LocationPinPicker> createState() => _LocationPinPickerState();
}

class _LocationPinPickerState extends State<LocationPinPicker> {
  LatLng _pin = const LatLng(-23.1623356, -45.7954102);
  bool _locating = true;
  GoogleMapController? _mapController;

  @override
  void initState() {
    super.initState();
    _loadLocation();
  }

  void _focusPin() {
    _mapController?.animateCamera(
      CameraUpdate.newCameraPosition(CameraPosition(target: _pin, zoom: 16)),
    );
  }

  Future<void> _loadLocation() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return;
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
        _focusPin();
      }
    } catch (_) {
      // The user can still choose a point on the map when device location fails.
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  void _confirm() {
    Navigator.pop(
      context,
      GeocodingResult(
        displayName: 'Localização selecionada',
        primaryText: 'Localização selecionada',
        secondaryText: 'Pino ajustado no mapa',
        latitude: _pin.latitude,
        longitude: _pin.longitude,
        distanceKm: null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(title: const Text('AJUSTE O PINO')),
      body: Stack(
        fit: StackFit.expand,
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(target: _pin, zoom: 16),
            onMapCreated: (controller) {
              _mapController = controller;
              _focusPin();
            },
            markers: {
              Marker(
                markerId: const MarkerId('selected'),
                position: _pin,
                draggable: true,
                onDragEnd: (value) => setState(() => _pin = value),
              ),
            },
            onTap: (value) => setState(() => _pin = value),
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
          ),
          const IgnorePointer(child: NeoStreetBackdrop(animate: false)),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Align(
                    alignment: Alignment.topLeft,
                    child: NeoCard(
                      color: scheme.surface,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      offset: NeoBrutal.shadowOffsetSmall,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _locating
                                ? Icons.gps_fixed_rounded
                                : Icons.location_on_rounded,
                            color: scheme.primary,
                            size: 19,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _locating
                                ? 'LOCALIZANDO VOCÊ'
                                : 'PINO PRONTO PARA AJUSTE',
                            style: theme.textTheme.labelMedium,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Spacer(),
                  NeoCard(
                    color: scheme.surface,
                    padding: const EdgeInsets.all(12),
                    offset: NeoBrutal.shadowOffsetSmall,
                    child: Row(
                      children: [
                        Container(
                          width: 34,
                          height: 34,
                          color: scheme.secondary,
                          alignment: Alignment.center,
                          child: const Icon(
                            Icons.open_with_rounded,
                            color: Colors.white,
                            size: 19,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Toque no mapa ou arraste o pino para marcar seu ponto de encontro.',
                            style: theme.textTheme.bodySmall,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  NeoButton(
                    onPressed: _confirm,
                    icon: const Icon(Icons.place_rounded),
                    child: const Text('USAR ESTE PINO'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
