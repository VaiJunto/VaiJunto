class GeocodingResult {
  final String displayName;
  final double latitude;
  final double longitude;

  GeocodingResult({
    required this.displayName,
    required this.latitude,
    required this.longitude,
  });

  factory GeocodingResult.fromJson(Map<String, dynamic> json) {
    return GeocodingResult(
      displayName: json['displayName'],
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
    );
  }
}
