import '../../../../core/network/api_datetime.dart';

class OfferModel {
  final String id;
  final String routeId;
  final String driverId;
  final String driverName;
  final String routeName;
  final String originName;
  final String destinationName;
  final int availableSeats;
  final double price;
  final DateTime departureAt;
  final bool isFixed;
  final String status;

  OfferModel({
    required this.id,
    required this.routeId,
    required this.driverId,
    required this.driverName,
    required this.routeName,
    required this.originName,
    required this.destinationName,
    required this.availableSeats,
    required this.price,
    required this.departureAt,
    required this.isFixed,
    required this.status,
  });

  factory OfferModel.fromJson(Map<String, dynamic> json) {
    return OfferModel(
      id: json['id'],
      routeId: json['routeId'],
      driverId: json['driverId'],
      driverName: json['driverName'] as String? ?? 'Motorista',
      routeName: json['routeName'] as String? ?? 'Carona para a Fatec',
      originName: json['originName'] as String? ?? 'Origem não informada',
      destinationName:
          json['destinationName'] as String? ?? 'Destino não informado',
      availableSeats: json['availableSeats'],
      price: (json['price'] as num).toDouble(),
      departureAt: parseApiDateTime(json['departureAt']),
      isFixed: json['isRecurrent'] as bool? ?? false,
      status: json['status'],
    );
  }
}
