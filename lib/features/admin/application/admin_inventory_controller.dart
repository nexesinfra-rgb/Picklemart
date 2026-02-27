import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/inventory_models.dart';

class AdminInventoryState {
  final bool loading;
  final String? error;
  final List<InventoryItem> inventoryItems;
  final List<StockAlert> stockAlerts;
  final String searchQuery;
  final InventoryItem? selectedItem;

  const AdminInventoryState({
    this.loading = false,
    this.error,
    this.inventoryItems = const [],
    this.stockAlerts = const [],
    this.searchQuery = '',
    this.selectedItem,
  });

  AdminInventoryState copyWith({
    bool? loading,
    String? error,
    List<InventoryItem>? inventoryItems,
    List<StockAlert>? stockAlerts,
    String? searchQuery,
    InventoryItem? selectedItem,
  }) {
    return AdminInventoryState(
      loading: loading ?? this.loading,
      error: error ?? this.error,
      inventoryItems: inventoryItems ?? this.inventoryItems,
      stockAlerts: stockAlerts ?? this.stockAlerts,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedItem: selectedItem ?? this.selectedItem,
    );
  }

  List<InventoryItem> get filteredInventoryItems {
    if (searchQuery.isEmpty) {
      return inventoryItems;
    }
    return inventoryItems
        .where(
          (item) =>
              item.productName.toLowerCase().contains(
                searchQuery.toLowerCase(),
              ) ||
              item.productId.toLowerCase().contains(searchQuery.toLowerCase()),
        )
        .toList();
  }
}

class AdminInventoryController extends StateNotifier<AdminInventoryState> {
  AdminInventoryController(this._ref) : super(const AdminInventoryState()) {
    loadInventoryItems();
    loadStockAlerts();
  }

  final Ref _ref;

  Future<void> loadInventoryItems() async {
    state = state.copyWith(loading: true, error: null);
    try {
      await Future.delayed(
        const Duration(seconds: 1),
      ); // Simulate network delay

      if (!mounted) return;

      final mockInventory = [
        InventoryItem(
          productId: 'prod1',
          productName: 'Laptop Pro',
          currentStock: 50,
          minStockThreshold: 20,
          lastUpdated: DateTime.now().subtract(const Duration(days: 5)),
          suppliers: ['Supplier A', 'Supplier B'],
        ),
        InventoryItem(
          productId: 'prod2',
          productName: 'Wireless Earbuds',
          currentStock: 15,
          minStockThreshold: 30,
          lastUpdated: DateTime.now().subtract(const Duration(days: 1)),
          suppliers: ['Supplier C'],
        ),
        InventoryItem(
          productId: 'prod3',
          productName: 'Smartwatch X',
          currentStock: 120,
          minStockThreshold: 50,
          lastUpdated: DateTime.now().subtract(const Duration(hours: 10)),
          suppliers: ['Supplier A'],
        ),
      ];

      state = state.copyWith(inventoryItems: mockInventory, loading: false);
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }

  Future<void> loadStockAlerts() async {
    state = state.copyWith(loading: true, error: null);
    try {
      await Future.delayed(
        const Duration(milliseconds: 500),
      ); // Simulate network delay

      final mockAlerts = [
        StockAlert(
          id: 'alert1',
          productId: 'prod2',
          productName: 'Wireless Earbuds',
          currentStock: 15,
          threshold: 30,
          createdAt: DateTime.now().subtract(const Duration(days: 2)),
        ),
        StockAlert(
          id: 'alert2',
          productId: 'prod4',
          productName: 'Gaming Mouse',
          currentStock: 5,
          threshold: 10,
          createdAt: DateTime.now().subtract(const Duration(hours: 8)),
        ),
      ];

      state = state.copyWith(stockAlerts: mockAlerts, loading: false);
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }

  void searchInventory(String query) {
    state = state.copyWith(searchQuery: query);
  }

  Future<bool> updateStock(String productId, int newStock) async {
    state = state.copyWith(loading: true, error: null);
    try {
      await Future.delayed(
        const Duration(milliseconds: 500),
      ); // Simulate network delay

      if (!mounted) return false;

      final updatedItems =
          state.inventoryItems.map((item) {
            if (item.productId == productId) {
              return item.copyWith(
                currentStock: newStock,
                lastUpdated: DateTime.now(),
              );
            }
            return item;
          }).toList();

      state = state.copyWith(inventoryItems: updatedItems, loading: false);
      return true;
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> addInventoryItem(InventoryItem newItem) async {
    state = state.copyWith(loading: true, error: null);
    try {
      await Future.delayed(
        const Duration(milliseconds: 500),
      ); // Simulate network delay

      final updatedItems = [...state.inventoryItems, newItem];
      state = state.copyWith(inventoryItems: updatedItems, loading: false);
      return true;
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> deleteInventoryItem(String productId) async {
    state = state.copyWith(loading: true, error: null);
    try {
      await Future.delayed(
        const Duration(milliseconds: 500),
      ); // Simulate network delay

      if (!mounted) return false;

      final updatedItems =
          state.inventoryItems
              .where((item) => item.productId != productId)
              .toList();
      state = state.copyWith(inventoryItems: updatedItems, loading: false);
      return true;
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
      return false;
    }
  }

  void selectItem(InventoryItem? item) {
    state = state.copyWith(selectedItem: item);
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  Future<void> refresh() async {
    await loadInventoryItems();
    await loadStockAlerts();
  }
}

final adminInventoryControllerProvider =
    StateNotifierProvider<AdminInventoryController, AdminInventoryState>(
      (ref) => AdminInventoryController(ref),
    );
