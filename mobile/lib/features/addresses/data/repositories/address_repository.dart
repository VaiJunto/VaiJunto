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
  Future<void> clearRecents() => _dio.delete('/addresses/recents');
}
