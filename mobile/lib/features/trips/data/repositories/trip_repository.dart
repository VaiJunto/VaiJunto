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

  Future<void> performCheckIn(String tripId, String passengerId, bool isAttending) async {
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
}
