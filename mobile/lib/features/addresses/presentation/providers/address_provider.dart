import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/saved_address_model.dart';
import '../../data/repositories/address_repository.dart';

final savedAddressesProvider = FutureProvider<List<SavedAddressModel>>(
    (ref) => ref.watch(addressRepositoryProvider).list());
