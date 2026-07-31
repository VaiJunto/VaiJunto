import '../../../../core/models/location_model.dart';

class DemandModel {
  final String id;
  final String passengerId;
  final String originName;
  final LocationModel originLocation;
  final String destinationName;
  final LocationModel destinationLocation;
  final DateTime desiredTime;
  final String status;

  DemandModel({
    required this.id,
    required this.passengerId,
    required this.originName,
    required this.originLocation,
    required this.destinationName,
    required this.destinationLocation,
    required this.desiredTime,
    required this.status,
  });

  factory DemandModel.fromJson(Map<String, dynamic> json) {
    return DemandModel(
      id: json['id'],
      passengerId: json['passengerId'],
      originName: json['originName'],
      originLocation: LocationModel.fromJson(json['originLocation']),
      destinationName: json['destinationName'],
      destinationLocation: LocationModel.fromJson(json['destinationLocation']),
      desiredTime: DateTime.parse(json['desiredTime']),
      status: json['status'],
    );
  }
}
