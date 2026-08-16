import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class LocationActions extends StatelessWidget {
  const LocationActions({super.key, required this.json, required this.color});
  final String json;
  final Color color;
  @override
  Widget build(BuildContext context) {
    try {
      final data = jsonDecode(json) as Map<String, dynamic>;
      final lat = data['latitude'];
      final lng = data['longitude'];
      final query = '$lat,$lng';
      return Wrap(spacing: 8, children: [
        TextButton(
            onPressed: () => launchUrl(
                Uri.parse(
                    'https://www.google.com/maps/search/?api=1&query=$query'),
                mode: LaunchMode.externalApplication),
            child: Text('GOOGLE MAPS', style: TextStyle(color: color))),
        TextButton(
            onPressed: () => launchUrl(
                Uri.parse('https://waze.com/ul?ll=$query&navigate=yes'),
                mode: LaunchMode.externalApplication),
            child: Text('WAZE', style: TextStyle(color: color)))
      ]);
    } catch (_) {
      return const SizedBox.shrink();
    }
  }
}
