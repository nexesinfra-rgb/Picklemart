import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/supabase_provider.dart';
import '../domain/credit_transaction.dart';
import '../data/credit_transaction_repository.dart';
import 'admin_customer_controller.dart';
import 'cash_book_controller.dart';

class CreditSystemState {
  final List<CreditTransaction> transactions;
  final List<ManufacturerCreditBalance> balances;
  final bool isLoading;
  final String? error;
  final String? selectedManufacturerId;
  final String? selectedEntityName;

  const CreditSystemState({
    this.transactions = const [],
    this.balances = const [],
    this.isLoading = false,
    this.error,
    this.selectedManufacturerId,
    this.selectedEntityName,
  });

  CreditSystemState copyWith({
    List<CreditTransaction>? transactions,
    List<ManufacturerCreditBalance>? balances,
    bool? isLoading,
    String? error,
    String? selectedManufacturerId,
    String? selectedEntityName,
  }) {
    return CreditSystemState(
      transactions: transactions ?? this.transactions,
      balances: balances ?? this.balances,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      selectedManufacturerId:
          selectedManufacturerId ?? this.selectedManufacturerId,
      selectedEntityName: selectedEntityName ?? this.selectedEntityName,
    );
  }
}

class CreditSystemController extends StateNotifier<CreditSystemState> {
  CreditSystemController(this._ref) : super(const CreditSystemState()) {
    _repository = _ref.read(creditTransactionRepositoryProvider);
  }

  final Ref _ref;
  late final CreditTransactionRepository _repository;

  /// Load all credit transactions
  Future<void> loadTransactions({
    String? manufacturerId,
    String? entityName,
    CreditTransactionType? transactionType,
  }) async {
    if (mounted) {
      state = state.copyWith(isLoading: true, error: null);
    }

    try {
      final transactions = await _repository.getCreditTransactions(
        manufacturerId: manufacturerId,
        entityName: entityName,
        transactionType: transactionType,
      );

      if (mounted) {
        state = state.copyWith(transactions: transactions, isLoading: false);
      }
    } catch (e) {
      if (mounted) {
        state = state.copyWith(isLoading: false, error: e.toString());
      }
    }
  }

  /// Load all entity balances
  Future<void> loadBalances() async {
    if (mounted) {
      state = state.copyWith(isLoading: true, error: null);
    }

    try {
      final balances = await _repository.getAllEntityBalances();

      if (mounted) {
        state = state.copyWith(balances: balances, isLoading: false);
      }
    } catch (e) {
      if (mounted) {
        state = state.copyWith(isLoading: false, error: e.toString());
      }
    }
  }

  /// Load balance for a specific manufacturer
  Future<ManufacturerCreditBalance?> loadManufacturerBalance(
    String manufacturerId,
  ) async {
    try {
      return await _repository.getManufacturerBalance(manufacturerId);
    } catch (e) {
      if (mounted) {
        state = state.copyWith(error: e.toString());
      }
      return null;
    }
  }

  /// Create a new credit transaction
  Future<CreditTransaction?> createTransaction({
    String? manufacturerId,
    String? entityName,
    required CreditTransactionType transactionType,
    required double amount,
    required String createdBy,
    String? description,
    String? referenceNumber,
    PaymentMethod? paymentMethod,
    DateTime? transactionDate,
  }) async {
    if (mounted) {
      state = state.copyWith(isLoading: true, error: null);
    }

    try {
      final transaction = await _repository.createCreditTransaction(
        manufacturerId: manufacturerId,
        entityName: entityName,
        transactionType: transactionType,
        amount: amount,
        createdBy: createdBy,
        description: description,
        referenceNumber: referenceNumber,
        paymentMethod: paymentMethod,
        transactionDate: transactionDate,
      );

      // Reload transactions and balances in the background
      // We don't await them to allow the UI to close the dialog faster
      loadTransactions(
        manufacturerId: manufacturerId,
        entityName: entityName,
      );
      loadBalances();

      // Refresh customer list if manufacturer transaction involved
      if (manufacturerId != null) {
        _ref.read(adminCustomerControllerProvider.notifier).refresh().catchError((_) {});
      }

      if (mounted) {
        state = state.copyWith(isLoading: false);
      }
      return transaction;
    } catch (e) {
      if (mounted) {
        state = state.copyWith(isLoading: false, error: e.toString());
      }
      return null;
    }
  }

  /// Delete a credit transaction
  Future<bool> deleteTransaction(
    String transactionId, {
    String? manufacturerId,
    String? entityName,
  }) async {
    if (mounted) {
      state = state.copyWith(isLoading: true, error: null);
    }

    try {
      await _repository.deleteCreditTransaction(transactionId);

      // Reload transactions and balances
      await loadTransactions(
        manufacturerId: manufacturerId,
        entityName: entityName,
      );
      await loadBalances();

      // Refresh cashbook totals
      _ref.read(cashBookControllerProvider.notifier).refresh();

      // Refresh customer list if manufacturer transaction involved
      if (manufacturerId != null) {
        try {
          await _ref.read(adminCustomerControllerProvider.notifier).refresh();
        } catch (e) {
          // Ignore error
        }
      }

      if (mounted) {
        state = state.copyWith(isLoading: false);
      }
      return true;
    } catch (e) {
      if (mounted) {
        state = state.copyWith(isLoading: false, error: e.toString());
      }
      return false;
    }
  }

  /// Select a manufacturer to view their transactions (backward compatibility)
  void selectManufacturer(String? manufacturerId) {
    state = state.copyWith(
      selectedManufacturerId: manufacturerId,
      selectedEntityName: null,
    );
    if (manufacturerId != null) {
      loadTransactions(manufacturerId: manufacturerId);
    } else {
      loadTransactions();
    }
  }

  /// Select an entity to view their transactions
  void selectEntity({String? manufacturerId, String? entityName}) {
    state = state.copyWith(
      selectedManufacturerId: manufacturerId,
      selectedEntityName: entityName,
    );
    if (manufacturerId != null || entityName != null) {
      loadTransactions(manufacturerId: manufacturerId, entityName: entityName);
    } else {
      loadTransactions();
    }
  }

  /// Refresh all data
  Future<void> refresh() async {
    await Future.wait([loadTransactions(), loadBalances()]);
  }
}

final creditSystemControllerProvider =
    StateNotifierProvider<CreditSystemController, CreditSystemState>((ref) {
      return CreditSystemController(ref);
    });
