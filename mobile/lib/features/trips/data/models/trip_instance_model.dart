import '../../../../core/network/api_datetime.dart';

class TripInstanceModel {
  final String id;
  final String offerId;
  final String routeId;
  final String driverId;
  final DateTime scheduledDeparture;
  final String status;

  TripInstanceModel({
    required this.id,
    required this.offerId,
    required this.routeId,
    required this.driverId,
    required this.scheduledDeparture,
    required this.status,
  });

  factory TripInstanceModel.fromJson(Map<String, dynamic> json) {
    return TripInstanceModel(
      id: json['id'],
      offerId: json['offerId'],
      routeId: json['routeId'],
      driverId: json['driverId'],
      scheduledDeparture: parseApiDateTime(json['scheduledDeparture']),
      status: json['status'],
    );
  }
}
