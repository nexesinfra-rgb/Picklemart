import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/gst_repository.dart';

class GstController extends StateNotifier<AsyncValue<List<GstDetails>>> {
  final GstRepository _repository;

  GstController(this._repository) : super(const AsyncValue.loading()) {
    loadGstDetails();
  }

  Future<void> loadGstDetails() async {
    state = const AsyncValue.loading();
    try {
      final details = await _repository.getGstDetails();
      state = AsyncValue.data(details);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addGstDetails(GstDetails gst) async {
    try {
      await _repository.addGstDetails(gst);
      await loadGstDetails();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateGstDetails(GstDetails gst) async {
    try {
      await _repository.updateGstDetails(gst);
      await loadGstDetails();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteGstDetails(String id) async {
    try {
      await _repository.deleteGstDetails(id);
      await loadGstDetails();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> setDefaultGst(String id) async {
    try {
      await _repository.setDefaultGst(id);
      await loadGstDetails();
    } catch (e) {
      rethrow;
    }
  }
}

final gstControllerProvider =
    StateNotifierProvider<GstController, AsyncValue<List<GstDetails>>>((ref) {
      final repository = ref.watch(gstRepositoryProvider);
      return GstController(repository);
    });
