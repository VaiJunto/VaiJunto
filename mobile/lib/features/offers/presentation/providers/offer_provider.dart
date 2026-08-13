import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/models/location_model.dart';
import '../../../../core/network/api_exception.dart';
import '../../data/models/offer_model.dart';
import '../../data/repositories/offer_repository.dart';

final nearbyOffersProvider =
    FutureProvider.family<List<OfferModel>, LocationModel>(
        (ref, location) async {
  final repository = ref.watch(offerRepositoryProvider);
  return repository.getNearbyOffers(location.latitude, location.longitude,
      distance: 50000);
});

final createOfferProvider = StateNotifierProvider.autoDispose<
    CreateOfferNotifier, AsyncValue<OfferModel?>>((ref) {
  return CreateOfferNotifier(ref.watch(offerRepositoryProvider));
});

class CreateOfferNotifier extends StateNotifier<AsyncValue<OfferModel?>> {
  final OfferRepository _repository;

  CreateOfferNotifier(this._repository) : super(const AsyncValue.data(null));

  Future<void> create({
    required String routeName,
    required String originName,
    required LocationModel originLocation,
    required String destinationName,
    required LocationModel destinationLocation,
    required int availableSeats,
    required double price,
    required DateTime departureAt,
    required bool isFixed,
  }) async {
    state = const AsyncValue.loading();
    try {
      final offer = await _repository.createOffer(
        routeName: routeName,
        originName: originName,
        originLocation: originLocation,
        destinationName: destinationName,
        destinationLocation: destinationLocation,
        availableSeats: availableSeats,
        price: price,
        departureAt: departureAt,
        isFixed: isFixed,
      );
      state = AsyncValue.data(offer);
    } on DioException catch (e, st) {
      state = AsyncValue.error(ApiException.fromDio(e), st);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}
