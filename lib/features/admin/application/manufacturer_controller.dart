import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/supabase_provider.dart';
import '../domain/manufacturer.dart';
import '../data/manufacturer_repository.dart';

class ManufacturerState {
  final List<Manufacturer> manufacturers;
  final List<Manufacturer> filteredManufacturers;
  final String searchQuery;
  final bool loading;
  final String? error;

  const ManufacturerState({
    this.manufacturers = const [],
    this.filteredManufacturers = const [],
    this.searchQuery = '',
    this.loading = false,
    this.error,
  });

  ManufacturerState copyWith({
    List<Manufacturer>? manufacturers,
    List<Manufacturer>? filteredManufacturers,
    String? searchQuery,
    bool? loading,
    String? error,
  }) {
    return ManufacturerState(
      manufacturers: manufacturers ?? this.manufacturers,
      filteredManufacturers:
          filteredManufacturers ?? this.filteredManufacturers,
      searchQuery: searchQuery ?? this.searchQuery,
      loading: loading ?? this.loading,
      error: error,
    );
  }
}

class ManufacturerController extends StateNotifier<ManufacturerState> {
  ManufacturerController(this._ref) : super(const ManufacturerState()) {
    // Initialize repository
    final supabaseClient = _ref.read(supabaseClientProvider);
    _repository = ManufacturerRepository(supabaseClient);
  }

  final Ref _ref;
  late final ManufacturerRepository _repository;

  Future<void> loadManufacturers() async {
    if (!mounted) return;
    state = state.copyWith(loading: true, error: null);

    try {
      final manufacturers = await _repository.getAllManufacturers();
      if (!mounted) return;
      state = state.copyWith(
        manufacturers: manufacturers,
        filteredManufacturers: manufacturers,
        loading: false,
      );
    } catch (e) {
      if (mounted) {
        state = state.copyWith(loading: false, error: e.toString());
      }
    }
  }

  void searchManufacturers(String query) {
    state = state.copyWith(searchQuery: query);
    _applyFilters();
  }

  void _applyFilters() {
    List<Manufacturer> filtered = state.manufacturers;

    // Apply search filter
    if (state.searchQuery.isNotEmpty) {
      final query = state.searchQuery.toLowerCase();
      filtered =
          filtered.where((manufacturer) {
            return manufacturer.name.toLowerCase().contains(query) ||
                manufacturer.businessName.toLowerCase().contains(query) ||
                manufacturer.gstNumber.toLowerCase().contains(query) ||
                manufacturer.city.toLowerCase().contains(query) ||
                manufacturer.state.toLowerCase().contains(query);
          }).toList();
    }

    // Sort strictly by created date descending
    filtered.sort((a, b) {
      final dateA = a.createdAt ?? DateTime(2000);
      final dateB = b.createdAt ?? DateTime(2000);
      return dateB.compareTo(dateA);
    });

    state = state.copyWith(filteredManufacturers: filtered);
  }

  Future<bool> createManufacturer(Manufacturer manufacturer) async {
    try {
      final created = await _repository.createManufacturer(manufacturer);
      if (!mounted) return false;
      final updatedList = [created, ...state.manufacturers];
      state = state.copyWith(
        manufacturers: updatedList,
        filteredManufacturers: updatedList,
      );
      _applyFilters();
      return true;
    } catch (e) {
      if (mounted) {
        state = state.copyWith(error: e.toString());
      }
      return false;
    }
  }

  Future<bool> updateManufacturer(Manufacturer manufacturer) async {
    try {
      final updated = await _repository.updateManufacturer(manufacturer);
      if (!mounted) return false;
      final updatedList =
          state.manufacturers.map((m) {
            return m.id == updated.id ? updated : m;
          }).toList();
      state = state.copyWith(
        manufacturers: updatedList,
        filteredManufacturers: updatedList,
      );
      _applyFilters();
      return true;
    } catch (e) {
      if (mounted) {
        state = state.copyWith(error: e.toString());
      }
      return false;
    }
  }

  Future<bool> deleteManufacturer(String id) async {
    try {
      await _repository.deleteManufacturer(id);
      if (!mounted) return false;
      final updatedList = state.manufacturers.where((m) => m.id != id).toList();
      state = state.copyWith(
        manufacturers: updatedList,
        filteredManufacturers: updatedList,
      );
      _applyFilters();
      return true;
    } catch (e) {
      if (mounted) {
        state = state.copyWith(error: e.toString());
      }
      return false;
    }
  }

  Future<List<Manufacturer>> getAllManufacturers() async {
    if (state.manufacturers.isEmpty) {
      await loadManufacturers();
    }
    return state.manufacturers;
  }

  Future<void> refresh() async {
    await loadManufacturers();
  }
}

final manufacturerControllerProvider =
    StateNotifierProvider<ManufacturerController, ManufacturerState>((ref) {
      return ManufacturerController(ref);
    });
