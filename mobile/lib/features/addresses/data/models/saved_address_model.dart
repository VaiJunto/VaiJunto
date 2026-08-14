class SavedAddressModel {
  const SavedAddressModel(
      {required this.id,
      required this.label,
      required this.addressName,
      required this.latitude,
      required this.longitude,
      required this.recent});
  final String id, label, addressName;
  final double latitude, longitude;
  final bool recent;
  factory SavedAddressModel.fromJson(Map<String, dynamic> json) =>
      SavedAddressModel(
        id: json['id'] as String,
        label: json['label'] as String,
        addressName: json['addressName'] as String,
        latitude: (json['latitude'] as num).toDouble(),
        longitude: (json['longitude'] as num).toDouble(),
        recent: json['recent'] as bool? ?? false,
      );
}
