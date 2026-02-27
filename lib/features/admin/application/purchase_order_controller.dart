import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/supabase_provider.dart';
import '../domain/purchase_order.dart';
import '../data/purchase_order_repository_supabase.dart';
import '../../orders/data/order_model.dart';
import '../data/credit_transaction_repository.dart';
import '../domain/credit_transaction.dart';
import 'admin_customer_controller.dart';
import 'admin_auth_controller.dart';

class PurchaseOrderState {
  final List<PurchaseOrder> purchaseOrders;
  final List<PurchaseOrder> filteredPurchaseOrders;
  final String searchQuery;
  final PurchaseOrderStatus? selectedStatus;
  final String? selectedManufacturerId;
  final String? selectedCustomerId;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool loading;
  final String? error;
  final bool onlyManufacturers;
  final bool onlyCustomers;

  const PurchaseOrderState({
    this.purchaseOrders = const [],
    this.filteredPurchaseOrders = const [],
    this.searchQuery = '',
    this.selectedStatus,
    this.selectedManufacturerId,
    this.selectedCustomerId,
    this.startDate,
    this.endDate,
    this.loading = false,
    this.error,
    this.onlyManufacturers = false,
    this.onlyCustomers = false,
  });

  PurchaseOrderState copyWith({
    List<PurchaseOrder>? purchaseOrders,
    List<PurchaseOrder>? filteredPurchaseOrders,
    String? searchQuery,
    PurchaseOrderStatus? selectedStatus,
    bool? resetSelectedStatus,
    String? selectedManufacturerId,
    bool? resetSelectedManufacturerId,
    String? selectedCustomerId,
    bool? resetSelectedCustomerId,
    DateTime? startDate,
    bool? resetStartDate,
    DateTime? endDate,
    bool? resetEndDate,
    bool? loading,
    String? error,
    bool? onlyManufacturers,
    bool? onlyCustomers,
  }) {
    return PurchaseOrderState(
      purchaseOrders: purchaseOrders ?? this.purchaseOrders,
      filteredPurchaseOrders:
          filteredPurchaseOrders ?? this.filteredPurchaseOrders,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedStatus:
          resetSelectedStatus == true
              ? null
              : (selectedStatus ?? this.selectedStatus),
      selectedManufacturerId:
          resetSelectedManufacturerId == true
              ? null
              : (selectedManufacturerId ?? this.selectedManufacturerId),
      selectedCustomerId:
          resetSelectedCustomerId == true
              ? null
              : (selectedCustomerId ?? this.selectedCustomerId),
      startDate: resetStartDate == true ? null : (startDate ?? this.startDate),
      endDate: resetEndDate == true ? null : (endDate ?? this.endDate),
      loading: loading ?? this.loading,
      error: error,
      onlyManufacturers: onlyManufacturers ?? this.onlyManufacturers,
      onlyCustomers: onlyCustomers ?? this.onlyCustomers,
    );
  }
}

class PurchaseOrderController extends StateNotifier<PurchaseOrderState> {
  PurchaseOrderController(this._ref) : super(const PurchaseOrderState()) {
    // Initialize repository
    final supabaseClient = _ref.read(supabaseClientProvider);
    _repository = PurchaseOrderRepositorySupabase(supabaseClient);
  }

  final Ref _ref;
  late final PurchaseOrderRepositorySupabase _repository;

  /// Cache for getPurchaseOrderByNumber to avoid repeated network calls for share/print.
  final Map<String, PurchaseOrder> _poByNumberCache = {};
  static const int _poByNumberCacheMaxSize = 20;

  CreditTransactionRepository get _creditRepo {
    final supabaseClient = _ref.read(supabaseClientProvider);
    return CreditTransactionRepository(supabaseClient);
  }

  String get _createdBy {
    final admin = _ref.read(currentAdminProvider);
    if (admin != null) return admin.id;

    final user = _ref.read(supabaseClientProvider).auth.currentUser;
    return user?.id ?? 'Admin';
  }

  Future<void> loadPurchaseOrders() async {
    _poByNumberCache.clear();
    if (mounted) {
      state = state.copyWith(loading: true, error: null);
    }

    try {
      final purchaseOrders = await _repository.getPurchaseOrders(
        manufacturerId: state.selectedManufacturerId,
        customerId: state.selectedCustomerId,
        status: state.selectedStatus,
        startDate: state.startDate,
        endDate: state.endDate,
        onlyManufacturers: state.onlyManufacturers,
        onlyCustomers: state.onlyCustomers,
      );
      if (mounted) {
        state = state.copyWith(
          purchaseOrders: purchaseOrders,
          filteredPurchaseOrders: purchaseOrders,
          loading: false,
        );
        _applyFilters();
      }
    } catch (e) {
      if (mounted) {
        state = state.copyWith(loading: false, error: e.toString());
      }
    }
  }

  void searchPurchaseOrders(String query) {
    state = state.copyWith(searchQuery: query);
    _applyFilters();
  }

  void filterByStatus(PurchaseOrderStatus? status) {
    if (status == null) {
      state = state.copyWith(resetSelectedStatus: true);
    } else {
      state = state.copyWith(selectedStatus: status);
    }
    loadPurchaseOrders();
  }

  void filterByManufacturer(String? manufacturerId) {
    if (manufacturerId == null) {
      state = state.copyWith(resetSelectedManufacturerId: true);
    } else {
      state = state.copyWith(selectedManufacturerId: manufacturerId);
    }
    loadPurchaseOrders();
  }

  void setEntityFilter({String? manufacturerId, String? customerId}) {
    state = state.copyWith(
      selectedManufacturerId: manufacturerId,
      resetSelectedManufacturerId: manufacturerId == null,
      selectedCustomerId: customerId,
      resetSelectedCustomerId: customerId == null,
    );
    loadPurchaseOrders();
  }

  void filterByCustomer(String? customerId) {
    if (customerId == null) {
      state = state.copyWith(resetSelectedCustomerId: true);
    } else {
      state = state.copyWith(selectedCustomerId: customerId);
    }
    loadPurchaseOrders();
  }

  void filterByDateRange(DateTime? start, DateTime? end) {
    state = state.copyWith(
      startDate: start,
      endDate: end,
      resetStartDate: start == null,
      resetEndDate: end == null,
    );
    loadPurchaseOrders();
  }

  void setOnlyManufacturers(bool value) {
    state = state.copyWith(onlyManufacturers: value);
    loadPurchaseOrders();
  }

  void setOnlyCustomers(bool value) {
    state = state.copyWith(onlyCustomers: value);
    loadPurchaseOrders();
  }

  void _applyFilters() {
    List<PurchaseOrder> filtered = state.purchaseOrders;

    // Apply search filter
    if (state.searchQuery.isNotEmpty) {
      final query = state.searchQuery.toLowerCase();
      filtered =
          filtered.where((po) {
            return po.purchaseNumber.toLowerCase().contains(query) ||
                (po.notes != null && po.notes!.toLowerCase().contains(query));
          }).toList();
    }

    // Sort purchase orders: by date (newest first), then by numeric portion (higher numbers first)
    filtered.sort((a, b) {
      // Use createdAt time if purchaseDate is midnight to ensure correct time sorting
      DateTime dateA = a.purchaseDate;
      if (dateA.hour == 0 && dateA.minute == 0 && dateA.second == 0) {
        final createdAtLocal = a.createdAt.toLocal();
        dateA = DateTime(
          dateA.year,
          dateA.month,
          dateA.day,
          createdAtLocal.hour,
          createdAtLocal.minute,
          createdAtLocal.second,
        );
      }

      DateTime dateB = b.purchaseDate;
      if (dateB.hour == 0 && dateB.minute == 0 && dateB.second == 0) {
        final createdAtLocal = b.createdAt.toLocal();
        dateB = DateTime(
          dateB.year,
          dateB.month,
          dateB.day,
          createdAtLocal.hour,
          createdAtLocal.minute,
          createdAtLocal.second,
        );
      }

      // First, sort by purchase date descending
      final dateCompare = dateB.compareTo(dateA);

      // If dates are the same or very close, use numeric purchase number as tiebreaker
      if (dateCompare == 0) {
        final numA = _extractNumericPortion(a.purchaseNumber);
        final numB = _extractNumericPortion(b.purchaseNumber);
        if (numA != null && numB != null) {
          return numB.compareTo(numA); // Higher numbers first
        }
      }

      return dateCompare;
    });

    state = state.copyWith(filteredPurchaseOrders: filtered);
  }

  /// Extract numeric portion from purchase numbers for proper numeric sorting
  int? _extractNumericPortion(String purchaseNumber) {
    final numericPart = purchaseNumber.replaceAll(RegExp(r'[^0-9]'), '');
    return numericPart.isNotEmpty ? int.tryParse(numericPart) : null;
  }

  Future<PurchaseOrder?> createPurchaseOrderFromOrder({
    required Order order,
    String? manufacturerId,
    String? customerId,
    required DateTime purchaseDate,
    DateTime? expectedDeliveryDate,
    double? tax,
    double? shipping,
    String? notes,
    String? deliveryLocation,
    String? transportationName,
    String? transportationPhone,
    List<PurchaseOrderItem>? customItems,
    double? paidAmount,
  }) async {
    try {
      final purchaseOrder = await _repository.createPurchaseOrderFromOrder(
        order: order,
        manufacturerId: manufacturerId,
        customerId: customerId,
        purchaseDate: purchaseDate,
        expectedDeliveryDate: expectedDeliveryDate,
        tax: tax,
        shipping: shipping,
        notes: notes,
        deliveryLocation: deliveryLocation,
        transportationName: transportationName,
        transportationPhone: transportationPhone,
        customItems: customItems,
        paidAmount: paidAmount,
      );

      if (!mounted) return null;

      // If manufacturer ID is present, create a credit transaction
      if (manufacturerId != null) {
        _creditRepo
            .createCreditTransaction(
              manufacturerId: manufacturerId,
              transactionType: CreditTransactionType.purchase,
              amount: purchaseOrder.total,
              createdBy: _createdBy,
              description: 'Purchase Order #${purchaseOrder.purchaseNumber}',
              referenceNumber: purchaseOrder.purchaseNumber,
              transactionDate: purchaseDate,
            )
            .then((_) {
              if (!mounted) return;
              // Refresh customer list to update balance in background
              _ref
                  .read(adminCustomerControllerProvider.notifier)
                  .refresh()
                  .catchError((_) {});
            })
            .catchError((_) {});
      }

      loadPurchaseOrders();
      return purchaseOrder;
    } catch (e) {
      if (mounted) {
        state = state.copyWith(error: e.toString());
      }
      return null;
    }
  }

  Future<PurchaseOrder?> createPurchaseOrder({
    String? manufacturerId,
    String? customerId,
    required DateTime purchaseDate,
    required List<PurchaseOrderItem> items,
    DateTime? expectedDeliveryDate,
    double? tax,
    double? shipping,
    String? notes,
    String? deliveryLocation,
    String? transportationName,
    String? transportationPhone,
    String? orderId,
    PurchaseOrderStatus? status,
    double? paidAmount,
  }) async {
    try {
      final purchaseOrder = await _repository.createPurchaseOrder(
        manufacturerId: manufacturerId,
        customerId: customerId,
        purchaseDate: purchaseDate,
        items: items,
        expectedDeliveryDate: expectedDeliveryDate,
        tax: tax,
        shipping: shipping,
        notes: notes,
        deliveryLocation: deliveryLocation,
        transportationName: transportationName,
        transportationPhone: transportationPhone,
        orderId: orderId,
        status: status,
        paidAmount: paidAmount,
      );

      if (!mounted) return null;

      // If manufacturer ID is present, create a credit transaction
      if (manufacturerId != null) {
        await _creditRepo.createCreditTransaction(
          manufacturerId: manufacturerId,
          transactionType: CreditTransactionType.purchase,
          amount: purchaseOrder.total,
          createdBy: _createdBy,
          description: 'Purchase Order #${purchaseOrder.purchaseNumber}',
          referenceNumber: purchaseOrder.purchaseNumber,
          transactionDate: purchaseDate,
        );

        if (!mounted) return null;

        // Refresh customer list to update balance
        await _ref.read(adminCustomerControllerProvider.notifier).refresh();
      }

      if (!mounted) return null;

      await loadPurchaseOrders();
      return purchaseOrder;
    } catch (e) {
      if (mounted) {
        state = state.copyWith(error: e.toString());
      }
      return null;
    }
  }

  Future<PurchaseOrder?> updatePurchaseOrder(
    PurchaseOrder purchaseOrder, {
    bool skipSyncCredit = false,
  }) async {
    try {
      // Get old order to calculate differences
      final oldOrder = await _repository.getPurchaseOrderById(purchaseOrder.id);
      final double oldTotal = oldOrder?.total ?? 0.0;
      final double oldPaidAmount = oldOrder?.paidAmount ?? 0.0;

      final updated = await _repository.updatePurchaseOrder(purchaseOrder);

      if (!mounted) return null;

      // If manufacturer ID is present, sync credit transactions
      if (purchaseOrder.manufacturerId != null && !skipSyncCredit) {
        // Handle total change (Purchase Adjustment)
        final double totalDiff = purchaseOrder.total - oldTotal;
        if (totalDiff != 0) {
          _creditRepo
              .createCreditTransaction(
                manufacturerId: purchaseOrder.manufacturerId,
                transactionType: CreditTransactionType.purchase,
                amount: totalDiff,
                createdBy: _createdBy,
                description:
                    'Adjustment: Purchase Order #${purchaseOrder.purchaseNumber} (Quantity Updated)',
                referenceNumber: purchaseOrder.purchaseNumber,
                transactionDate: DateTime.now(),
              )
              .catchError((_) {});
        }

        // Handle paid amount change (Payment Adjustment)
        final double paidDiff = purchaseOrder.paidAmount - oldPaidAmount;
        if (paidDiff != 0) {
          _creditRepo
              .createCreditTransaction(
                manufacturerId: purchaseOrder.manufacturerId,
                transactionType: CreditTransactionType.payin,
                amount: paidDiff,
                createdBy: _createdBy,
                description:
                    'Payment Adjustment: Purchase Order #${purchaseOrder.purchaseNumber}',
                referenceNumber: purchaseOrder.purchaseNumber,
                transactionDate: DateTime.now(),
              )
              .catchError((_) {});
        }

        // Refresh customer list to update balance in background
        _ref
            .read(adminCustomerControllerProvider.notifier)
            .refresh()
            .catchError((_) {});
      }

      loadPurchaseOrders();
      return updated;
    } catch (e) {
      if (mounted) {
        state = state.copyWith(error: e.toString());
      }
      return null;
    }
  }

  Future<bool> deletePurchaseOrder(String id) async {
    try {
      await _repository.deletePurchaseOrder(id);
      if (!mounted) return true;
      await loadPurchaseOrders();
      return true;
    } catch (e) {
      if (mounted) {
        state = state.copyWith(error: e.toString());
      }
      return false;
    }
  }

  Future<PurchaseOrder?> getPurchaseOrderById(String id) async {
    try {
      return await _repository.getPurchaseOrderById(id);
    } catch (e) {
      if (mounted) {
        state = state.copyWith(error: e.toString());
      }
      return null;
    }
  }

  Future<PurchaseOrder?> getPurchaseOrderByNumber(String purchaseNumber) async {
    if (_poByNumberCache.containsKey(purchaseNumber)) {
      return _poByNumberCache[purchaseNumber];
    }
    try {
      final po = await _repository.getPurchaseOrderByNumber(purchaseNumber);
      if (po != null) {
        _poByNumberCache[purchaseNumber] = po;
        if (_poByNumberCache.length > _poByNumberCacheMaxSize) {
          _poByNumberCache.remove(_poByNumberCache.keys.first);
        }
      }
      return po;
    } catch (e) {
      if (mounted) {
        state = state.copyWith(error: e.toString());
      }
      return null;
    }
  }

  /// Prefetch multiple purchase orders by number to populate cache
  Future<void> prefetchPurchaseOrders(List<String> purchaseNumbers) async {
    final toFetch =
        purchaseNumbers
            .where((no) => !_poByNumberCache.containsKey(no))
            .toSet()
            .toList();

    if (toFetch.isEmpty) return;

    try {
      final pos = await _repository.getPurchaseOrdersByNumbers(toFetch);
      for (final po in pos) {
        _poByNumberCache[po.purchaseNumber] = po;
      }

      // Trim cache if needed
      while (_poByNumberCache.length > _poByNumberCacheMaxSize) {
        _poByNumberCache.remove(_poByNumberCache.keys.first);
      }
    } catch (e) {
      // Just log error, don't update state as this is a background optimization
      print('Error prefetching purchase orders: $e');
    }
  }

  void resetFilters() {
    state = state.copyWith(
      searchQuery: '',
      resetSelectedStatus: true,
      resetSelectedManufacturerId: true,
      resetStartDate: true,
      resetEndDate: true,
    );
    _applyFilters();
  }

  Future<void> refresh() async {
    await loadPurchaseOrders();
  }
}

final purchaseOrderControllerProvider =
    StateNotifierProvider<PurchaseOrderController, PurchaseOrderState>((ref) {
      return PurchaseOrderController(ref);
    });
