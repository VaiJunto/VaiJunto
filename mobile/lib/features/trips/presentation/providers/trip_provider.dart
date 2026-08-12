import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/trip_passenger_model.dart';
import '../../data/repositories/trip_repository.dart';

final tripPassengersProvider = FutureProvider.family<List<TripPassengerModel>, String>((ref, tripId) async {
  final repository = ref.watch(tripRepositoryProvider);
  return repository.getTripPassengers(tripId);
});

final checkInProvider = Provider<CheckInNotifier>((ref) {
  return CheckInNotifier(ref.watch(tripRepositoryProvider));
});

class CheckInNotifier {
  final TripRepository _repository;

  CheckInNotifier(this._repository);

  Future<void> performCheckIn(String tripId, String passengerId, bool isAttending) async {
    await _repository.performCheckIn(tripId, passengerId, isAttending);
  }
}
