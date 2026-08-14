import '../../../../core/models/location_model.dart';
import '../../../../core/network/api_datetime.dart';

class DemandModel {
  final String id;
  final String passengerId;
  final String passengerName;
  final String originName;
  final LocationModel originLocation;
  final String destinationName;
  final LocationModel destinationLocation;
  final DateTime desiredTime;
  final String status;

  DemandModel({
    required this.id,
    required this.passengerId,
    required this.passengerName,
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
      passengerName: json['passengerName'] as String? ?? 'Passageiro',
      originName: json['originName'],
      originLocation: json['originLocation'] == null
          ? LocationModel(latitude: 0, longitude: 0)
          : LocationModel.fromJson(json['originLocation']),
      destinationName: json['destinationName'],
      destinationLocation: json['destinationLocation'] == null
          ? LocationModel(latitude: 0, longitude: 0)
          : LocationModel.fromJson(json['destinationLocation']),
      desiredTime: parseApiDateTime(json['desiredTime']),
      status: json['status'],
    );
  }
}
