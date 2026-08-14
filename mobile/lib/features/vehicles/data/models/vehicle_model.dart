class VehicleModel {
  const VehicleModel(
      {required this.id,
      required this.licensePlate,
      required this.model,
      required this.capacity,
      required this.isDefault,
      required this.vehicleType});
  final String id, licensePlate, model, vehicleType;
  final int capacity;
  final bool isDefault;
  factory VehicleModel.fromJson(Map<String, dynamic> json) => VehicleModel(
      id: json['id'] as String,
      licensePlate: json['licensePlate'] as String,
      model: (json['model'] as String?) ?? '',
      capacity: json['capacity'] as int,
      isDefault: json['isDefault'] as bool? ?? false,
      vehicleType: json['vehicleType'] as String? ?? 'CAR');
}
