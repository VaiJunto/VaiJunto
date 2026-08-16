import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/trip_passenger_model.dart';
import '../../data/models/trip_instance_model.dart';
import '../../data/repositories/trip_repository.dart';

final tripPassengersProvider =
    FutureProvider.family<List<TripPassengerModel>, String>(
        (ref, tripId) async {
  final repository = ref.watch(tripRepositoryProvider);
  return repository.getTripPassengers(tripId);
});

final myTripsProvider = FutureProvider<List<TripInstanceModel>>(
    (ref) => ref.watch(tripRepositoryProvider).mine());

final checkInProvider = Provider<CheckInNotifier>((ref) {
  return CheckInNotifier(ref.watch(tripRepositoryProvider));
});

class CheckInNotifier {
  final TripRepository _repository;

  CheckInNotifier(this._repository);

  Future<void> performCheckIn(
      String tripId, String passengerId, bool isAttending) async {
    await _repository.performCheckIn(tripId, passengerId, isAttending);
  }
}

final rideActionProvider = Provider<RideActionNotifier>(
    (ref) => RideActionNotifier(ref.watch(tripRepositoryProvider)));

class RideActionNotifier {
  RideActionNotifier(this._repository);
  final TripRepository _repository;
  Future<TripPassengerModel> requestSeat(String offerId) =>
      _repository.requestSeat(offerId);
  Future<TripPassengerModel> propose(String demandId) =>
      _repository.propose(demandId);
  Future<TripPassengerModel> accept(String participantId) =>
      _repository.accept(participantId);
  Future<TripPassengerModel> decline(String participantId) =>
      _repository.decline(participantId);
  Future<TripPassengerModel> withdraw(String participantId) =>
      _repository.withdraw(participantId);
  Future<TripPassengerModel> cancel(String participantId,
          {String? reason, String? note}) =>
      _repository.cancel(participantId, reason: reason, note: note);
  Future<TripInstanceModel> start(String tripId,
          {DateTime? expectedDeparture}) =>
      _repository.start(tripId, expectedDeparture: expectedDeparture);
  Future<TripInstanceModel> finish(String tripId,
          {double? latitude,
          double? longitude,
          String? reason,
          String? note}) =>
      _repository.finish(tripId,
          latitude: latitude, longitude: longitude, reason: reason, note: note);
}
