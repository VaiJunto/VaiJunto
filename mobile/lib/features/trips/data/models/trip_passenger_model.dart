class TripPassengerModel {
  final String id;
  final String tripInstanceId;
  final String passengerId;
  final String passengerName;
  final String status;
  final DateTime? checkedInAt;

  TripPassengerModel({
    required this.id,
    required this.tripInstanceId,
    required this.passengerId,
    required this.passengerName,
    required this.status,
    this.checkedInAt,
  });

  factory TripPassengerModel.fromJson(Map<String, dynamic> json) {
    return TripPassengerModel(
      id: json['id'],
      tripInstanceId: json['tripInstanceId'],
      passengerId: json['passengerId'],
      passengerName: json['passengerName'],
      status: json['status'],
      checkedInAt: json['checkedInAt'] != null ? DateTime.parse(json['checkedInAt']) : null,
    );
  }
}
