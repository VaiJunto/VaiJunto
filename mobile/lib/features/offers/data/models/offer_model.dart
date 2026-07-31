class OfferModel {
  final String id;
  final String routeId;
  final String driverId;
  final int availableSeats;
  final double price;
  final DateTime departureAt;
  final String status;

  OfferModel({
    required this.id,
    required this.routeId,
    required this.driverId,
    required this.availableSeats,
    required this.price,
    required this.departureAt,
    required this.status,
  });

  factory OfferModel.fromJson(Map<String, dynamic> json) {
    return OfferModel(
      id: json['id'],
      routeId: json['routeId'],
      driverId: json['driverId'],
      availableSeats: json['availableSeats'],
      price: (json['price'] as num).toDouble(),
      departureAt: DateTime.parse(json['departureAt']),
      status: json['status'],
    );
  }
}
