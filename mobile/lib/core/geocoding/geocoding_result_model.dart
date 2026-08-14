class GeocodingResult {
  final String displayName;
  final String primaryText;
  final String secondaryText;
  final double latitude;
  final double longitude;
  final double? distanceKm;

  GeocodingResult({
    required this.displayName,
    required this.primaryText,
    required this.secondaryText,
    required this.latitude,
    required this.longitude,
    required this.distanceKm,
  });

  factory GeocodingResult.fromJson(Map<String, dynamic> json) {
    final displayName = json['displayName'] as String;
    return GeocodingResult(
      displayName: displayName,
      primaryText: json['primaryText'] as String? ?? displayName,
      secondaryText: json['secondaryText'] as String? ?? '',
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      distanceKm: (json['distanceKm'] as num?)?.toDouble(),
    );
  }

  String get distanceLabel {
    final distance = distanceKm;
    if (distance == null) return '';
    if (distance < 1) {
      final meters = (distance * 1000).round();
      return '$meters m da Fatec';
    }
    return '${distance.round()} km da Fatec';
  }
}
