import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/cash_book_repository.dart';
import '../domain/cash_book_entry.dart';

class CashBookState {
  final List<CashBookEntry> entries;
  final bool isLoading;
  final String? error;
  final double totalPayin;
  final double totalPayout;
  final double balance;
  final int totalCount;

  const CashBookState({
    this.entries = const [],
    this.isLoading = false,
    this.error,
    this.totalPayin = 0,
    this.totalPayout = 0,
    this.balance = 0,
    this.totalCount = 0,
  });

  CashBookState copyWith({
    List<CashBookEntry>? entries,
    bool? isLoading,
    String? error,
    double? totalPayin,
    double? totalPayout,
    double? balance,
    int? totalCount,
  }) {
    return CashBookState(
      entries: entries ?? this.entries,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      totalPayin: totalPayin ?? this.totalPayin,
      totalPayout: totalPayout ?? this.totalPayout,
      balance: balance ?? this.balance,
      totalCount: totalCount ?? this.totalCount,
    );
  }
}

class CashBookController extends StateNotifier<CashBookState> {
  final CashBookRepository _repository;

  CashBookController(this._repository) : super(const CashBookState()) {
    loadEntries();
  }

  Future<void> loadEntries({
    DateTime? startDate,
    DateTime? endDate,
    CashBookEntryType? type,
  }) async {
    if (mounted) {
      state = state.copyWith(isLoading: true, error: null);
    }

    try {
      final results = await Future.wait([
        _repository.getEntries(
          startDate: startDate,
          endDate: endDate,
          type: type,
        ),
        _repository.getTotals(),
        _repository.getTotalCount(),
      ]);

      final entries = results[0] as List<CashBookEntry>;
      final totals = results[1] as Map<String, double>;
      final count = results[2] as int;

      if (mounted) {
        state = state.copyWith(
          entries: entries,
          totalPayin: totals['total_payin'],
          totalPayout: totals['total_payout'],
          balance: totals['balance'],
          totalCount: count,
          isLoading: false,
        );
      }
    } catch (e) {
      if (mounted) {
        state = state.copyWith(isLoading: false, error: e.toString());
      }
    }
  }

  Future<void> addEntry(CashBookEntry entry) async {
    if (mounted) {
      state = state.copyWith(isLoading: true, error: null);
    }

    try {
      await _repository.addEntry(entry);
      // We don't await loadEntries() here to allow the UI to close the dialog faster.
      // The refresh happens in the background.
      loadEntries();
    } catch (e) {
      if (mounted) {
        state = state.copyWith(isLoading: false, error: e.toString());
      }
      rethrow;
    }
  }

  Future<void> updateEntry(String id, Map<String, dynamic> updates, {String? relatedId}) async {
    if (mounted) {
      state = state.copyWith(isLoading: true, error: null);
    }

    try {
      await _repository.updateEntry(id, updates, relatedId: relatedId);
      loadEntries();
    } catch (e) {
      if (mounted) {
        state = state.copyWith(isLoading: false, error: e.toString());
      }
      rethrow;
    }
  }

  Future<void> deleteEntry(String id, {String? relatedId}) async {
    if (mounted) {
      state = state.copyWith(isLoading: true, error: null);
    }

    try {
      await _repository.deleteEntry(id, relatedId: relatedId);
      loadEntries();
    } catch (e) {
      if (mounted) {
        state = state.copyWith(isLoading: false, error: e.toString());
      }
      rethrow;
    }
  }

  Future<void> refresh() async {
    await loadEntries();
  }
}

final cashBookControllerProvider =
    StateNotifierProvider<CashBookController, CashBookState>((ref) {
      return CashBookController(ref.watch(cashBookRepositoryProvider));
    });
