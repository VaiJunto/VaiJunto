import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/models/location_model.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_datetime.dart';
import '../models/offer_model.dart';

final offerRepositoryProvider = Provider<OfferRepository>((ref) {
  return OfferRepository(ref.watch(dioProvider));
});

class OfferRepository {
  final Dio _dio;

  OfferRepository(this._dio);

  Future<List<OfferModel>> getNearbyOffers(double lat, double lon,
      {double distance = 5000}) async {
    try {
      final response = await _dio.get(
        '/offers/nearby',
        queryParameters: {
          'lat': lat,
          'lon': lon,
          'distanceMeters': distance,
        },
      );

      final data = response.data as List;
      return data.map((json) => OfferModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Erro ao buscar ofertas próximas: $e');
    }
  }

  /// Cria a rota e a oferta juntas — ainda não existe um fluxo separado de
  /// cadastro de rotas no backend, então o motorista publica as duas de uma vez.
  Future<OfferModel> createOffer({
    required String routeName,
    required String originName,
    required LocationModel originLocation,
    required String destinationName,
    required LocationModel destinationLocation,
    required int availableSeats,
    required double price,
    required DateTime departureAt,
    required bool isFixed,
  }) async {
    final response = await _dio.post(
      '/offers',
      data: {
        'routeName': routeName,
        'originName': originName,
        'originLocation': originLocation.toJson(),
        'destinationName': destinationName,
        'destinationLocation': destinationLocation.toJson(),
        'departureTime': _formatTimeOfDay(departureAt),
        'isRecurrent': isFixed,
        'availableSeats': availableSeats,
        'price': price,
        'departureAt': formatApiDateTime(departureAt),
      },
    );

    return OfferModel.fromJson(response.data);
  }

  String _formatTimeOfDay(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute:00';
  }
}
