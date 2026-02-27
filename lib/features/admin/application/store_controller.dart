import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/store_repository.dart';
import '../domain/store_details.dart';

final storeControllerProvider = StateNotifierProvider<StoreController, AsyncValue<StoreDetails?>>((ref) {
  return StoreController(ref.read(storeRepositoryProvider));
});

class StoreController extends StateNotifier<AsyncValue<StoreDetails?>> {
  final StoreRepository _repository;

  StoreController(this._repository) : super(const AsyncValue.loading()) {
    loadStoreDetails();
  }

  Future<void> loadStoreDetails() async {
    if (mounted) {
      state = const AsyncValue.loading();
    }
    try {
      final store = await _repository.getStoreDetails();
      if (mounted) {
        state = AsyncValue.data(store);
      }
    } catch (e, st) {
      if (mounted) {
        state = AsyncValue.error(e, st);
      }
    }
  }

  Future<void> updateStoreDetails(StoreDetails store) async {
    if (mounted) {
      state = const AsyncValue.loading();
    }
    try {
      await _repository.updateStoreDetails(store);
      // Reload to get fresh data
      await loadStoreDetails();
    } catch (e, st) {
      if (mounted) {
        state = AsyncValue.error(e, st);
      }
    }
  }
}
