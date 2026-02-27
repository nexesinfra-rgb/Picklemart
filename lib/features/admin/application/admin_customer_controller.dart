import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/customer_repository_provider.dart';
import '../data/manufacturer_repository.dart';
import '../data/credit_transaction_repository.dart';
import '../../../core/providers/supabase_provider.dart';

class Customer {
  final String id;
  final String name;
  final String? alias;
  final String email;
  final String phone;
  final String? gstNumber;
  final String? address;
  final DateTime createdAt;
  final DateTime? lastOrderDate;
  final DateTime? lastPaymentDate;
  final int totalOrders;
  final double totalSpent;
  final double totalBalance;
  final bool isActive;
  final bool priceVisibilityEnabled;
  final bool isManufacturer;

  const Customer({
    required this.id,
    required this.name,
    this.alias,
    required this.email,
    required this.phone,
    this.gstNumber,
    this.address,
    required this.createdAt,
    this.lastOrderDate,
    this.lastPaymentDate,
    this.totalOrders = 0,
    this.totalSpent = 0.0,
    this.totalBalance = 0.0,
    this.isActive = true,
    this.priceVisibilityEnabled = false,
    this.isManufacturer = false,
  });

  Customer copyWith({
    String? id,
    String? name,
    String? alias,
    String? email,
    String? phone,
    String? gstNumber,
    String? address,
    DateTime? createdAt,
    DateTime? lastOrderDate,
    DateTime? lastPaymentDate,
    int? totalOrders,
    double? totalSpent,
    double? totalBalance,
    bool? isActive,
    bool? priceVisibilityEnabled,
    bool? isManufacturer,
  }) => Customer(
    id: id ?? this.id,
    name: name ?? this.name,
    alias: alias ?? this.alias,
    email: email ?? this.email,
    phone: phone ?? this.phone,
    gstNumber: gstNumber ?? this.gstNumber,
    address: address ?? this.address,
    createdAt: createdAt ?? this.createdAt,
    lastOrderDate: lastOrderDate ?? this.lastOrderDate,
    lastPaymentDate: lastPaymentDate ?? this.lastPaymentDate,
    totalOrders: totalOrders ?? this.totalOrders,
    totalSpent: totalSpent ?? this.totalSpent,
    totalBalance: totalBalance ?? this.totalBalance,
    isActive: isActive ?? this.isActive,
    priceVisibilityEnabled:
        priceVisibilityEnabled ?? this.priceVisibilityEnabled,
    isManufacturer: isManufacturer ?? this.isManufacturer,
  );

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Customer && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

class PaginatedCustomersResult {
  final List<Customer> customers;
  final int totalCount;
  final int page;
  final int pageSize;
  final bool hasMore;

  const PaginatedCustomersResult({
    required this.customers,
    required this.totalCount,
    required this.page,
    required this.pageSize,
    required this.hasMore,
  });

  int get totalPages => (totalCount / pageSize).ceil();
}

enum CustomerStatusFilter { all, active, inactive }

enum CustomerSortBy { name, totalSpent, lastOrderDate, createdAt }

class AdminCustomerState {
  final List<Customer> customers;
  final List<Customer> filteredCustomers;
  final String searchQuery;
  final bool loading;
  final String? error;
  final Customer? selectedCustomer;
  final int currentPage;
  final bool hasMore;
  final bool isLoadingMore;
  final CustomerStatusFilter statusFilter;
  final DateTime? createdDateStart;
  final DateTime? createdDateEnd;
  final DateTime? lastOrderDateStart;
  final DateTime? lastOrderDateEnd;
  final double? minAmountSpent;
  final double? maxAmountSpent;
  final CustomerSortBy sortBy;
  final bool sortAscending;

  const AdminCustomerState({
    this.customers = const [],
    this.filteredCustomers = const [],
    this.searchQuery = '',
    this.loading = false,
    this.error,
    this.selectedCustomer,
    this.currentPage = 1,
    this.hasMore = true,
    this.isLoadingMore = false,
    this.statusFilter = CustomerStatusFilter.all,
    this.createdDateStart,
    this.createdDateEnd,
    this.lastOrderDateStart,
    this.lastOrderDateEnd,
    this.minAmountSpent,
    this.maxAmountSpent,
    this.sortBy = CustomerSortBy.name,
    this.sortAscending = true,
  });

  AdminCustomerState copyWith({
    List<Customer>? customers,
    List<Customer>? filteredCustomers,
    String? searchQuery,
    bool? loading,
    String? error,
    Customer? selectedCustomer,
    int? currentPage,
    bool? hasMore,
    bool? isLoadingMore,
    CustomerStatusFilter? statusFilter,
    DateTime? createdDateStart,
    DateTime? createdDateEnd,
    DateTime? lastOrderDateStart,
    DateTime? lastOrderDateEnd,
    double? minAmountSpent,
    double? maxAmountSpent,
    CustomerSortBy? sortBy,
    bool? sortAscending,
    bool resetCreatedDateStart = false,
    bool resetCreatedDateEnd = false,
    bool resetLastOrderDateStart = false,
    bool resetLastOrderDateEnd = false,
    bool resetMinAmountSpent = false,
    bool resetMaxAmountSpent = false,
  }) => AdminCustomerState(
    customers: customers ?? this.customers,
    filteredCustomers: filteredCustomers ?? this.filteredCustomers,
    searchQuery: searchQuery ?? this.searchQuery,
    loading: loading ?? this.loading,
    error: error,
    selectedCustomer: selectedCustomer ?? this.selectedCustomer,
    currentPage: currentPage ?? this.currentPage,
    hasMore: hasMore ?? this.hasMore,
    isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    statusFilter: statusFilter ?? this.statusFilter,
    createdDateStart:
        resetCreatedDateStart
            ? null
            : (createdDateStart ?? this.createdDateStart),
    createdDateEnd:
        resetCreatedDateEnd ? null : (createdDateEnd ?? this.createdDateEnd),
    lastOrderDateStart:
        resetLastOrderDateStart
            ? null
            : (lastOrderDateStart ?? this.lastOrderDateStart),
    lastOrderDateEnd:
        resetLastOrderDateEnd
            ? null
            : (lastOrderDateEnd ?? this.lastOrderDateEnd),
    minAmountSpent:
        resetMinAmountSpent ? null : (minAmountSpent ?? this.minAmountSpent),
    maxAmountSpent:
        resetMaxAmountSpent ? null : (maxAmountSpent ?? this.maxAmountSpent),
    sortBy: sortBy ?? this.sortBy,
    sortAscending: sortAscending ?? this.sortAscending,
  );
}

class AdminCustomerController extends StateNotifier<AdminCustomerState> {
  AdminCustomerController(this._ref) : super(const AdminCustomerState()) {
    _loadCustomers();
  }

  final Ref _ref;

  Future<void> _loadCustomers({bool silent = false}) async {
    if (!silent) {
      state = state.copyWith(loading: true, error: null, currentPage: 1);
    }

    try {
      final repository = _ref.read(customerRepositoryProvider);
      if (kDebugMode) {
        print(
          '🔍 AdminCustomerController: Fetching customers via repository (paginated)...',
        );
      }
      final result = await repository.getAllCustomersPaginated(
        page: 1,
        pageSize: 50,
      );

      var allCustomers = List<Customer>.from(result.customers);

      // Fetch manufacturers and add them to the list
      try {
        final supabaseClient = _ref.read(supabaseClientProvider);
        final manufacturerRepo = ManufacturerRepository(supabaseClient);
        final creditRepo = CreditTransactionRepository(supabaseClient);

        final manufacturers = await manufacturerRepo.getAllManufacturers();
        if (kDebugMode) {
          print(
            '🔍 AdminCustomerController: Found ${manufacturers.length} manufacturers, fetching balances...',
          );
        }

        final manufacturerFutures = manufacturers.map((m) async {
          double balance = 0.0;
          DateTime? lastTransactionDate;
          try {
            final creditBalance = await creditRepo.getManufacturerBalance(m.id);
            balance = creditBalance.currentBalance;
            lastTransactionDate = creditBalance.lastTransactionDate;
            if (kDebugMode && balance != 0) {
              print(
                '💰 AdminCustomerController: Manufacturer ${m.name} balance: $balance',
              );
            }
          } catch (e) {
            if (kDebugMode) {
              print(
                '⚠️ AdminCustomerController: Error fetching balance for ${m.name}: $e',
              );
            }
          }

          return Customer(
            id: m.id,
            name: m.name,
            alias: m.businessName,
            email: m.email ?? '',
            phone: m.phone ?? '',
            createdAt: m.createdAt ?? DateTime.now(),
            lastPaymentDate: lastTransactionDate,
            totalBalance: balance,
            isManufacturer: true,
            isActive: m.isActive,
          );
        });

        final manufacturerCustomers = await Future.wait(manufacturerFutures);
        allCustomers.addAll(manufacturerCustomers);
      } catch (e) {
        if (kDebugMode) {
          print(
            '⚠️ AdminCustomerController: Error fetching manufacturers - $e',
          );
        }
      }

      if (kDebugMode) {
        print(
          '✅ AdminCustomerController: Received ${result.customers.length} customers + manufacturers (total: ${allCustomers.length})',
        );
      }

      if (!mounted) return;
      state = state.copyWith(
        customers: allCustomers,
        loading: false,
        error: null,
        currentPage: 1,
        hasMore: result.hasMore,
      );
      _applyFilters();
    } catch (error, stack) {
      if (kDebugMode) {
        print(
          '❌ AdminCustomerController: ERROR while fetching customers - $error',
        );
        print('Stack trace: $stack');
      }
      if (mounted) {
        if (!silent) {
          state = state.copyWith(loading: false, error: error.toString());
        } else {
          state = state.copyWith(loading: false);
        }
      }
    }
  }

  Future<void> loadMoreCustomers() async {
    if (state.isLoadingMore || !state.hasMore) return;

    state = state.copyWith(isLoadingMore: true);

    try {
      final repository = _ref.read(customerRepositoryProvider);
      final nextPage = state.currentPage + 1;
      final result = await repository.getAllCustomersPaginated(
        page: nextPage,
        pageSize: 50,
      );

      final allCustomers = [...state.customers, ...result.customers];

      if (!mounted) return;
      state = state.copyWith(
        customers: allCustomers,
        filteredCustomers: allCustomers,
        currentPage: nextPage,
        hasMore: result.hasMore,
        isLoadingMore: false,
      );
      _applyFilters();
    } catch (error, stack) {
      if (kDebugMode) {
        print(
          '❌ AdminCustomerController: ERROR while loading more customers - $error',
        );
        print('Stack trace: $stack');
      }
      if (mounted) {
        state = state.copyWith(isLoadingMore: false, error: error.toString());
      }
    }
  }

  Future<void> loadCustomers() async {
    await _loadCustomers();
  }

  /// Refresh customers list - reloads from the first page
  /// This is useful after order updates to show the updated customer at the top
  Future<void> refresh({bool silent = false}) async {
    await _loadCustomers(silent: silent);
  }

  void searchCustomers(String query) {
    state = state.copyWith(searchQuery: query);
    _applyFilters();
  }

  void filterByStatus(CustomerStatusFilter status) {
    state = state.copyWith(statusFilter: status);
    _applyFilters();
  }

  void filterByDateRange({
    DateTime? createdStart,
    DateTime? createdEnd,
    DateTime? lastOrderStart,
    DateTime? lastOrderEnd,
  }) {
    state = state.copyWith(
      createdDateStart: createdStart,
      createdDateEnd: createdEnd,
      lastOrderDateStart: lastOrderStart,
      lastOrderDateEnd: lastOrderEnd,
      resetCreatedDateStart: createdStart == null,
      resetCreatedDateEnd: createdEnd == null,
      resetLastOrderDateStart: lastOrderStart == null,
      resetLastOrderDateEnd: lastOrderEnd == null,
    );
    _applyFilters();
  }

  void filterByAmountRange(double? min, double? max) {
    state = state.copyWith(
      minAmountSpent: min,
      maxAmountSpent: max,
      resetMinAmountSpent: min == null,
      resetMaxAmountSpent: max == null,
    );
    _applyFilters();
  }

  void sortBy(CustomerSortBy sortBy, {bool? ascending}) {
    state = state.copyWith(
      sortBy: sortBy,
      sortAscending: ascending ?? !state.sortAscending,
    );
    _applyFilters();
  }

  void resetFilters() {
    state = state.copyWith(
      searchQuery: '',
      statusFilter: CustomerStatusFilter.all,
      resetCreatedDateStart: true,
      resetCreatedDateEnd: true,
      resetLastOrderDateStart: true,
      resetLastOrderDateEnd: true,
      resetMinAmountSpent: true,
      resetMaxAmountSpent: true,
      sortBy: CustomerSortBy.name,
      sortAscending: true,
    );
    _applyFilters();
  }

  void _applyFilters() {
    List<Customer> filtered = List<Customer>.from(state.customers);

    // Apply search filter
    if (state.searchQuery.isNotEmpty) {
      filtered =
          filtered.where((customer) {
            return customer.name.toLowerCase().contains(
                  state.searchQuery.toLowerCase(),
                ) ||
                (customer.alias != null &&
                    customer.alias!.toLowerCase().contains(
                      state.searchQuery.toLowerCase(),
                    )) ||
                customer.email.toLowerCase().contains(
                  state.searchQuery.toLowerCase(),
                ) ||
                customer.phone.contains(state.searchQuery);
          }).toList();
    }

    // Apply status filter
    if (state.statusFilter != CustomerStatusFilter.all) {
      filtered =
          filtered.where((customer) {
            if (state.statusFilter == CustomerStatusFilter.active) {
              return customer.isActive;
            } else {
              return !customer.isActive;
            }
          }).toList();
    }

    // Apply created date range filter
    if (state.createdDateStart != null) {
      filtered =
          filtered.where((customer) {
            return customer.createdAt.isAfter(state.createdDateStart!) ||
                customer.createdAt.isAtSameMomentAs(state.createdDateStart!);
          }).toList();
    }
    if (state.createdDateEnd != null) {
      filtered =
          filtered.where((customer) {
            final endDate = DateTime(
              state.createdDateEnd!.year,
              state.createdDateEnd!.month,
              state.createdDateEnd!.day,
              23,
              59,
              59,
            );
            return customer.createdAt.isBefore(endDate) ||
                customer.createdAt.isAtSameMomentAs(endDate);
          }).toList();
    }

    // Apply last order date range filter
    if (state.lastOrderDateStart != null) {
      filtered =
          filtered.where((customer) {
            if (customer.lastOrderDate == null) return false;
            return customer.lastOrderDate!.isAfter(state.lastOrderDateStart!) ||
                customer.lastOrderDate!.isAtSameMomentAs(
                  state.lastOrderDateStart!,
                );
          }).toList();
    }
    if (state.lastOrderDateEnd != null) {
      filtered =
          filtered.where((customer) {
            if (customer.lastOrderDate == null) return false;
            final endDate = DateTime(
              state.lastOrderDateEnd!.year,
              state.lastOrderDateEnd!.month,
              state.lastOrderDateEnd!.day,
              23,
              59,
              59,
            );
            return customer.lastOrderDate!.isBefore(endDate) ||
                customer.lastOrderDate!.isAtSameMomentAs(endDate);
          }).toList();
    }

    // Apply amount range filter
    if (state.minAmountSpent != null) {
      filtered =
          filtered.where((customer) {
            return customer.totalSpent >= state.minAmountSpent!;
          }).toList();
    }
    if (state.maxAmountSpent != null) {
      filtered =
          filtered.where((customer) {
            return customer.totalSpent <= state.maxAmountSpent!;
          }).toList();
    }

    // Apply sorting
    // Sort by most recent activity (Order, Payment, or Creation)
    // This ensures the "Stores" list shows the most recently active stores first
    filtered.sort((a, b) {
      DateTime getLatestDate(Customer c) {
        final dates =
            [
              c.lastOrderDate,
              c.lastPaymentDate,
              c.createdAt,
            ].where((d) => d != null).map((d) => d!).toList();

        if (dates.isEmpty) return c.createdAt;

        return dates.reduce((curr, next) => curr.isAfter(next) ? curr : next);
      }

      final dateA = getLatestDate(a);
      final dateB = getLatestDate(b);

      // Descending order (newest first)
      return dateB.compareTo(dateA);
    });

    if (mounted) {
      state = state.copyWith(filteredCustomers: filtered);
    }
  }

  void selectCustomer(Customer customer) {
    state = state.copyWith(selectedCustomer: customer);
  }

  void clearSelection() {
    state = state.copyWith(selectedCustomer: null);
  }

  Future<bool> updateCustomerStatus(String customerId, bool isActive) async {
    state = state.copyWith(loading: true, error: null);

    try {
      final repository = _ref.read(customerRepositoryProvider);
      await repository.updateCustomerStatus(customerId, isActive);

      // Update local state
      final updatedCustomers =
          state.customers.map((customer) {
            if (customer.id == customerId) {
              return customer.copyWith(isActive: isActive);
            }
            return customer;
          }).toList();

      if (mounted) {
        state = state.copyWith(
          customers: updatedCustomers,
          filteredCustomers: updatedCustomers,
          loading: false,
        );
        _applyFilters();
      }
      return true;
    } catch (e) {
      if (mounted) {
        state = state.copyWith(loading: false, error: e.toString());
      }
      return false;
    }
  }

  Future<bool> updateCustomerPriceVisibility(
    String customerId,
    bool enabled,
  ) async {
    state = state.copyWith(loading: true, error: null);

    try {
      final repository = _ref.read(customerRepositoryProvider);
      await repository.updateCustomerPriceVisibility(customerId, enabled);

      // Update local state
      final updatedCustomers =
          state.customers.map((customer) {
            if (customer.id == customerId) {
              return customer.copyWith(priceVisibilityEnabled: enabled);
            }
            return customer;
          }).toList();

      if (mounted) {
        state = state.copyWith(
          customers: updatedCustomers,
          filteredCustomers: updatedCustomers,
          loading: false,
        );
        _applyFilters();
      }
      return true;
    } catch (e) {
      if (mounted) {
        state = state.copyWith(loading: false, error: e.toString());
      }
      return false;
    }
  }

  /// Create a new customer account
  /// Returns the created user information including credentials for manual sharing
  Future<Map<String, dynamic>?> createCustomerAccount({
    required String name,
    required String mobile,
    required String password,
    String? gstNumber,
  }) async {
    state = state.copyWith(loading: true, error: null);

    try {
      final repository = _ref.read(customerRepositoryProvider);
      final result = await repository.createCustomerAccount(
        name: name,
        mobile: mobile,
        password: password,
        gstNumber: gstNumber,
      );

      // Reload customers to include the newly created one
      if (!mounted) return result;
      await _loadCustomers();

      return result;
    } catch (e) {
      if (kDebugMode) {
        print('Error creating customer account: $e');
      }
      if (mounted) {
        state = state.copyWith(loading: false, error: e.toString());
      }
      return null;
    }
  }

  Future<bool> updateCustomer({
    required String id,
    String? name,
    String? alias,
    String? phone,
    String? email,
    String? gstNumber,
    String? address,
    bool? isActive,
    String? password,
  }) async {
    state = state.copyWith(loading: true, error: null);

    try {
      final repository = _ref.read(customerRepositoryProvider);
      await repository.updateCustomer(
        id: id,
        name: name,
        alias: alias,
        phone: phone,
        email: email,
        gstNumber: gstNumber,
        address: address,
        isActive: isActive,
        password: password,
      );

      if (!mounted) return false;

      // Update local state
      final updatedCustomers =
          state.customers.map((customer) {
            if (customer.id == id) {
              return customer.copyWith(
                name: name ?? customer.name,
                alias: alias ?? customer.alias,
                phone: phone ?? customer.phone,
                email: email ?? customer.email,
                gstNumber: gstNumber ?? customer.gstNumber,
                address: address ?? customer.address,
                isActive: isActive ?? customer.isActive,
              );
            }
            return customer;
          }).toList();

      if (mounted) {
        state = state.copyWith(
          customers: updatedCustomers,
          filteredCustomers: updatedCustomers,
          loading: false,
        );
        _applyFilters();
      }
      return true;
    } catch (e) {
      if (mounted) {
        state = state.copyWith(loading: false, error: e.toString());
      }
      return false;
    }
  }

  Future<bool> deleteCustomer(String id) async {
    state = state.copyWith(loading: true, error: null);

    try {
      // Find the customer to determine if it is a manufacturer
      final customer = state.customers.firstWhere(
        (c) => c.id == id,
        orElse: () => throw Exception('Customer not found'),
      );

      // Determine if we are deleting a Manufacturer or a Customer Profile
      final supabaseClient = _ref.read(supabaseClientProvider);
      final manufacturerRepo = ManufacturerRepository(supabaseClient);
      final customerRepo = _ref.read(customerRepositoryProvider);

      // Clean phone number for matching (remove +91, spaces, etc if needed)
      // Assuming phone is stored consistently, but simple strip is safer
      final cleanPhone = customer.phone.replaceAll(RegExp(r'\D'), '');
      // Take last 10 digits if longer (e.g. 91xxxxxxxxxx)
      final searchPhone =
          cleanPhone.length > 10
              ? cleanPhone.substring(cleanPhone.length - 10)
              : cleanPhone;

      if (customer.isManufacturer) {
        // CASE 1: Deleting a Manufacturer (ID is Manufacturer UUID)

        // Step A: Delete Manufacturer Record
        await manufacturerRepo.deleteManufacturer(id);

        // Step B: Find and Delete associated Customer Profile (by Phone)
        if (searchPhone.isNotEmpty) {
          try {
            // Find profile with this phone
            final response =
                await supabaseClient
                    .from('profiles')
                    .select('id')
                    .or('mobile.eq.$searchPhone,display_mobile.eq.$searchPhone')
                    .maybeSingle();

            if (response != null) {
              final profileId = response['id'] as String;
              if (kDebugMode) {
                print(
                  'Found linked profile for manufacturer: $profileId. Deleting...',
                );
              }
              await customerRepo.deleteCustomer(profileId);
            }
          } catch (e) {
            if (kDebugMode) print('Error finding/deleting linked profile: $e');
          }
        }
      } else {
        // CASE 2: Deleting a Customer (ID is Auth/Profile UUID)

        // Step A: Delete Customer Profile (and Auth User via Edge Function)
        await customerRepo.deleteCustomer(id);

        // Step B: Find and Delete associated Manufacturer Record (by Phone)
        if (searchPhone.isNotEmpty) {
          try {
            // Find manufacturer with this phone
            final response =
                await supabaseClient
                    .from('manufacturers')
                    .select('id')
                    .or(
                      'phone.eq.$searchPhone,phone.eq.+91$searchPhone',
                    ) // Try both formats
                    .maybeSingle();

            if (response != null) {
              final manufacturerId = response['id'] as String;
              if (kDebugMode) {
                print(
                  'Found linked manufacturer for customer: $manufacturerId. Deleting...',
                );
              }
              await manufacturerRepo.deleteManufacturer(manufacturerId);
            }
          } catch (e) {
            if (kDebugMode) {
              print('Error finding/deleting linked manufacturer: $e');
            }
          }
        }
      }

      // Update local state
      final updatedCustomers =
          state.customers.where((customer) => customer.id != id).toList();

      if (mounted) {
        state = state.copyWith(
          customers: updatedCustomers,
          filteredCustomers: updatedCustomers,
          loading: false,
        );
        _applyFilters();
      }
      return true;
    } catch (e) {
      if (mounted) {
        state = state.copyWith(loading: false, error: e.toString());
      }
      return false;
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  @override
  void dispose() {
    // No need to cancel subscriptions - shared provider handles cleanup
    super.dispose();
  }
}

final adminCustomerControllerProvider =
    StateNotifierProvider<AdminCustomerController, AdminCustomerState>(
      (ref) => AdminCustomerController(ref),
    );
