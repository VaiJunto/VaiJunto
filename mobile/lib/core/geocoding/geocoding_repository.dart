import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../network/api_client.dart';
import 'geocoding_result_model.dart';

final geocodingRepositoryProvider = Provider<GeocodingRepository>((ref) {
  return GeocodingRepository(ref.watch(dioProvider));
});

class GeocodingRepository {
  final Dio _dio;

  GeocodingRepository(this._dio);

  Future<List<GeocodingResult>> search(String query) async {
    final response = await _dio.get(
      '/geocoding/search',
      queryParameters: {'q': query},
    );

    final data = response.data as List;
    return data.map((json) => GeocodingResult.fromJson(json)).toList();
  }
}
