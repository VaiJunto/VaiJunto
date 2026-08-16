import '../../../../core/network/api_datetime.dart';

class TripInstanceModel {
  final String id;
  final String? offerId;
  final String? routeId;
  final String driverId;
  final DateTime scheduledDeparture;
  final String status;
  final DateTime? actualStart;
  final DateTime? actualEnd;
  final String? finishReason;

  TripInstanceModel({
    required this.id,
    required this.offerId,
    required this.routeId,
    required this.driverId,
    required this.scheduledDeparture,
    required this.status,
    this.actualStart,
    this.actualEnd,
    this.finishReason,
  });

  factory TripInstanceModel.fromJson(Map<String, dynamic> json) {
    return TripInstanceModel(
      id: json['id'],
      offerId: json['offerId'] as String?,
      routeId: json['routeId'] as String?,
      driverId: json['driverId'],
      scheduledDeparture: parseApiDateTime(json['scheduledDeparture']),
      status: json['status'],
      actualStart: json['actualStart'] == null
          ? null
          : parseApiDateTime(json['actualStart']),
      actualEnd: json['actualEnd'] == null
          ? null
          : parseApiDateTime(json['actualEnd']),
      finishReason: json['finishReason'] as String?,
    );
  }
}
