import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../models/trip_instance_model.dart';
import '../models/trip_passenger_model.dart';

final tripRepositoryProvider = Provider<TripRepository>((ref) {
  return TripRepository(ref.watch(dioProvider));
});

class TripRepository {
  final Dio _dio;

  TripRepository(this._dio);

  Future<TripInstanceModel> createTripFromOffer(String offerId) async {
    final response = await _dio.post('/trips/from-offer/$offerId');
    return TripInstanceModel.fromJson(response.data);
  }

  Future<TripPassengerModel> requestSeat(String offerId) async {
    final response = await _dio.post('/trips/offers/$offerId/requests');
    return TripPassengerModel.fromJson(response.data);
  }

  Future<TripPassengerModel> propose(String demandId) async {
    final response = await _dio.post('/trips/demands/$demandId/proposals');
    return TripPassengerModel.fromJson(response.data);
  }

  Future<TripPassengerModel> accept(String participantId) async {
    final response =
        await _dio.post('/trips/participants/$participantId/accept');
    return TripPassengerModel.fromJson(response.data);
  }

  Future<TripPassengerModel> decline(String participantId) async {
    final response =
        await _dio.post('/trips/participants/$participantId/decline');
    return TripPassengerModel.fromJson(response.data);
  }

  Future<TripPassengerModel> withdraw(String participantId) async {
    final response =
        await _dio.post('/trips/participants/$participantId/withdraw');
    return TripPassengerModel.fromJson(response.data);
  }

  Future<TripPassengerModel> cancel(String participantId,
      {String? reason, String? note}) async {
    final response = await _dio.post(
        '/trips/participants/$participantId/cancel',
        data: {'reason': reason, 'note': note});
    return TripPassengerModel.fromJson(response.data);
  }

  Future<void> performCheckIn(
      String tripId, String passengerId, bool isAttending) async {
    await _dio.post(
      '/trips/$tripId/checkin',
      queryParameters: {
        'passengerId': passengerId,
        'isAttending': isAttending,
      },
    );
  }

  Future<List<TripPassengerModel>> getTripPassengers(String tripId) async {
    final response = await _dio.get('/trips/$tripId/passengers');
    final data = response.data as List;
    return data.map((json) => TripPassengerModel.fromJson(json)).toList();
  }

  Future<List<TripInstanceModel>> mine() async {
    final response = await _dio.get('/trips/mine');
    return (response.data as List)
        .map((json) => TripInstanceModel.fromJson(json))
        .toList();
  }

  Future<TripInstanceModel> start(String tripId,
      {DateTime? expectedDeparture}) async {
    final response = await _dio.post('/trips/$tripId/start',
        data: expectedDeparture == null
            ? null
            : {'expectedDeparture': expectedDeparture.toIso8601String()});
    return TripInstanceModel.fromJson(response.data);
  }

  Future<TripInstanceModel> finish(String tripId,
      {double? latitude,
      double? longitude,
      String? reason,
      String? note}) async {
    final response = await _dio.post('/trips/$tripId/finish', data: {
      'latitude': latitude,
      'longitude': longitude,
      'reason': reason,
      'note': note
    });
    return TripInstanceModel.fromJson(response.data);
  }

  Future<void> review(String tripId, String revieweeId, int rating) =>
      _dio.post('/trips/$tripId/reviews',
          data: {'revieweeId': revieweeId, 'rating': rating});
}
