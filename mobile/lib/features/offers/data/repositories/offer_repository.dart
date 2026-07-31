import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../models/offer_model.dart';

final offerRepositoryProvider = Provider<OfferRepository>((ref) {
  return OfferRepository(ref.watch(dioProvider));
});

class OfferRepository {
  final Dio _dio;

  OfferRepository(this._dio);

  Future<List<OfferModel>> getNearbyOffers(double lat, double lon, {double distance = 5000}) async {
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
}
