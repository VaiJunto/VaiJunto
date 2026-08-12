import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/models/location_model.dart';
import '../../data/models/demand_model.dart';
import '../../data/repositories/demand_repository.dart';

final nearbyDemandsProvider = FutureProvider.family<List<DemandModel>, LocationModel>((ref, location) async {
  final repository = ref.watch(demandRepositoryProvider);
  return repository.getNearbyDemands(location.latitude, location.longitude);
});
