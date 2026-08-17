import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../models/saved_address_model.dart';

final addressRepositoryProvider =
    Provider((ref) => AddressRepository(ref.watch(dioProvider)));

class AddressRepository {
  AddressRepository(this._dio);
  final Dio _dio;
  Future<List<SavedAddressModel>> list() async {
    final response = await _dio.get('/addresses');
    return (response.data as List)
        .map((item) => SavedAddressModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<void> delete(String id) => _dio.delete('/addresses/$id');

  Future<void> create({
    required String label,
    required String addressName,
    required double latitude,
    required double longitude,
  }) =>
      _dio.post('/addresses',
          data: _payload(label, addressName, latitude, longitude));

  Future<void> update({
    required String id,
    required String label,
    required String addressName,
    required double latitude,
    required double longitude,
  }) =>
      _dio.put('/addresses/$id',
          data: _payload(label, addressName, latitude, longitude));

  Map<String, dynamic> _payload(
    String label,
    String addressName,
    double latitude,
    double longitude,
  ) =>
      {
        'label': label,
        'addressName': addressName,
        'latitude': latitude,
        'longitude': longitude,
      };

  Future<void> clearRecents() => _dio.delete('/addresses/recents');
}
