import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/vehicle_model.dart';
import '../../data/repositories/vehicle_repository.dart';

final vehiclesProvider = FutureProvider<List<VehicleModel>>(
    (ref) => ref.watch(vehicleRepositoryProvider).list());
