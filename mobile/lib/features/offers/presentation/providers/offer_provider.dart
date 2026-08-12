import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/models/location_model.dart';
import '../../data/models/offer_model.dart';
import '../../data/repositories/offer_repository.dart';

final nearbyOffersProvider = FutureProvider.family<List<OfferModel>, LocationModel>((ref, location) async {
  final repository = ref.watch(offerRepositoryProvider);
  return repository.getNearbyOffers(location.latitude, location.longitude);
});
