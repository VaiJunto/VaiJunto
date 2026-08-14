import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../models/vehicle_model.dart';

final vehicleRepositoryProvider =
    Provider((ref) => VehicleRepository(ref.watch(dioProvider)));

class VehicleRepository {
  VehicleRepository(this._dio);
  final Dio _dio;
  Future<List<VehicleModel>> list() async {
    final r = await _dio.get('/vehicles');
    return (r.data as List)
        .map((e) => VehicleModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<VehicleModel> create(
      {required String plate,
      required String model,
      required int capacity}) async {
    final r = await _dio.post('/vehicles', data: {
      'licensePlate': plate,
      'model': model,
      'capacity': capacity,
      'vehicleType': 'CAR'
    });
    return VehicleModel.fromJson(r.data as Map<String, dynamic>);
  }

  Future<void> archive(String id) => _dio.delete('/vehicles/$id');
  Future<void> makeDefault(String id) => _dio.post('/vehicles/$id/default');
}
