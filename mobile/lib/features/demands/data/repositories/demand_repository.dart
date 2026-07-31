import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../models/demand_model.dart';

final demandRepositoryProvider = Provider<DemandRepository>((ref) {
  return DemandRepository(ref.watch(dioProvider));
});

class DemandRepository {
  final Dio _dio;

  DemandRepository(this._dio);

  Future<List<DemandModel>> getNearbyDemands(double lat, double lon, {double distance = 5000}) async {
    try {
      final response = await _dio.get(
        '/demands/nearby',
        queryParameters: {
          'lat': lat,
          'lon': lon,
          'distanceMeters': distance,
        },
      );

      final data = response.data as List;
      return data.map((json) => DemandModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Erro ao buscar demandas próximas: $e');
    }
  }
}
