import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/multi_device_repository.dart';
import '../domain/multi_device_tracking.dart';

/// State for multi-device tracking
/// Manages the state of the multi-device tracking feature
class MultiDeviceState {
  final bool loading;
  final String? error;
  final MultiDeviceSummary? summary;
  final String? searchPhoneNumber;

  MultiDeviceState({
    this.loading = false,
    this.error,
    this.summary,
    this.searchPhoneNumber,
  });

  MultiDeviceState copyWith({
    bool? loading,
    String? error,
    MultiDeviceSummary? summary,
    String? searchPhoneNumber,
  }) {
    return MultiDeviceState(
      loading: loading ?? this.loading,
      error: error,
      summary: summary ?? this.summary,
      searchPhoneNumber: searchPhoneNumber ?? this.searchPhoneNumber,
    );
  }
}

/// Controller for multi-device tracking
class MultiDeviceController extends StateNotifier<MultiDeviceState> {
  final MultiDeviceRepository _repository;

  MultiDeviceController(this._repository) : super(MultiDeviceState());

  /// Search devices by phone number
  Future<void> searchByPhoneNumber(String phoneNumber) async {
    if (phoneNumber.trim().isEmpty) {
      if (mounted) {
        state = state.copyWith(
          error: 'Please enter a phone number',
          summary: null,
        );
      }
      return;
    }

    if (mounted) {
      state = state.copyWith(
        loading: true,
        error: null,
        searchPhoneNumber: phoneNumber.trim(),
      );
    }

    try {
      final summary = await _repository.getMultiDeviceSummary(
        phoneNumber.trim(),
      );
      if (mounted) {
        state = state.copyWith(loading: false, summary: summary, error: null);
      }
    } catch (e) {
      if (mounted) {
        state = state.copyWith(
          loading: false,
          error: e.toString(),
          summary: null,
        );
      }
    }
  }

  /// Refresh current search
  Future<void> refresh() async {
    if (state.searchPhoneNumber != null) {
      await searchByPhoneNumber(state.searchPhoneNumber!);
    }
  }

  /// Load all users' device data
  Future<void> loadAllUsers() async {
    if (mounted) {
      state = state.copyWith(
        loading: true,
        error: null,
        searchPhoneNumber: null,
      );
    }

    try {
      final summary = await _repository.getAllUsersSummary();
      if (mounted) {
        state = state.copyWith(
          loading: false,
          summary: summary,
          error: null,
          searchPhoneNumber: null,
        );
      }
    } catch (e) {
      if (mounted) {
        state = state.copyWith(
          loading: false,
          error: e.toString(),
          summary: null,
          searchPhoneNumber: null,
        );
      }
    }
  }

  /// Clear search and return to all users view
  Future<void> clearSearch() async {
    await loadAllUsers();
  }
}

/// Provider for multi-device controller
final multiDeviceControllerProvider =
    StateNotifierProvider<MultiDeviceController, MultiDeviceState>((ref) {
      final repository = ref.watch(multiDeviceRepositoryProvider);
      return MultiDeviceController(repository);
    });
