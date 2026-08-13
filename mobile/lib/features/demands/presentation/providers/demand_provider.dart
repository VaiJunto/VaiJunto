import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/models/location_model.dart';
import '../../../../core/network/api_exception.dart';
import '../../data/models/demand_model.dart';
import '../../data/repositories/demand_repository.dart';

final nearbyDemandsProvider =
    FutureProvider.family<List<DemandModel>, LocationModel>(
        (ref, location) async {
  final repository = ref.watch(demandRepositoryProvider);
  return repository.getNearbyDemands(location.latitude, location.longitude,
      distance: 50000);
});

final createDemandProvider = StateNotifierProvider.autoDispose<
    CreateDemandNotifier, AsyncValue<DemandModel?>>((ref) {
  return CreateDemandNotifier(ref.watch(demandRepositoryProvider));
});

class CreateDemandNotifier extends StateNotifier<AsyncValue<DemandModel?>> {
  final DemandRepository _repository;

  CreateDemandNotifier(this._repository) : super(const AsyncValue.data(null));

  Future<void> create({
    required String originName,
    required LocationModel originLocation,
    required String destinationName,
    required LocationModel destinationLocation,
    required DateTime desiredTime,
  }) async {
    state = const AsyncValue.loading();
    try {
      final demand = await _repository.createDemand(
        originName: originName,
        originLocation: originLocation,
        destinationName: destinationName,
        destinationLocation: destinationLocation,
        desiredTime: desiredTime,
      );
      state = AsyncValue.data(demand);
    } on DioException catch (e, st) {
      state = AsyncValue.error(ApiException.fromDio(e), st);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}
