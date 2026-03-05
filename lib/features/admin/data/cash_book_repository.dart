import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/providers/supabase_provider.dart';
import '../domain/cash_book_entry.dart';

final cashBookRepositoryProvider = Provider<CashBookRepository>((ref) {
  return CashBookRepository(ref.watch(supabaseClientProvider));
});

class CashBookRepository {
  final SupabaseClient _supabase;

  CashBookRepository(this._supabase);

  Future<void> addEntry(CashBookEntry entry) async {
    try {
      print('DEBUG REPO: About to insert cashbook entry: ${entry.toJson()}');
      await _supabase.from('cash_book').insert(entry.toJson());
      print('DEBUG REPO: Cashbook entry inserted successfully');
      if (entry.relatedId != null) {
        await updateAccountBalance(entry.relatedId!);
      }
    } catch (e) {
      print('DEBUG REPO: Error adding cashbook entry: $e');
      // Re-throw to be handled by the caller
      rethrow;
    }
  }

  Future<void> updateAccountBalance(String accountId) async {
    // The 'balance' column does not exist in the 'accounts' table, causing PGRST204 error.
    // We have moved to live calculation in the UI (AdminAccountsScreen), so we don't need to persist
    // the balance in the database anymore.
    // Leaving this method empty to prevent crashes while maintaining the interface.
    return;

    /* 
    // Previous implementation - Disabled due to missing schema column
    try {
      final response = await _supabase
          .from('cash_book')
          .select('amount, entry_type')
          .eq('related_id', accountId);
      
      double balance = 0;
      if (response != null && (response as List).isNotEmpty) {
        for (final item in response as List) {
          // Robust amount parsing (handles num, String, etc.)
          final amountVal = item['amount'];
          double amount = 0.0;
          if (amountVal is num) {
            amount = amountVal.toDouble();
          } else if (amountVal is String) {
            amount = double.tryParse(amountVal) ?? 0.0;
          }

          // Robust type parsing
          final typeVal = item['entry_type'];
          String type = '';
          if (typeVal is String) {
            type = typeVal.toLowerCase().trim();
          }

          if (type == 'payin' || type == 'pay in' || type == 'payment in') {
            balance += amount;
          } else if (type == 'payout' || type == 'pay out' || type == 'payment out') {
            balance -= amount;
          }
        }
      }

      // Update and check if successful
      final updateResponse = await _supabase
          .from('accounts')
          .update({'balance': balance})
          .eq('id', accountId)
          .select();
      
      if ((updateResponse as List).isEmpty) {
        print('Warning: Account balance update may have failed (Account not found or RLS blocked)');
      }
    } catch (e) {
      print('Failed to update account balance: $e');
      // Don't rethrow to avoid blocking the UI if this optional sync fails
      // rethrow; 
    }
    */
  }

  Future<List<CashBookEntry>> getEntries({
    DateTime? startDate,
    DateTime? endDate,
    CashBookEntryType? type,
    String? relatedId,
    int limit = 100,
  }) async {
    // Start building the query
    var query = _supabase.from('cash_book').select();

    // Apply filters
    if (startDate != null) {
      query = query.gte('transaction_date', startDate.toIso8601String());
    }
    if (endDate != null) {
      query = query.lte('transaction_date', endDate.toIso8601String());
    }
    if (type != null) {
      query = query.eq('entry_type', type.name);
    }
    if (relatedId != null) {
      query = query.eq('related_id', relatedId);
    }

    // Apply sorting and limit
    final response = await query
        .order('transaction_date', ascending: false)
        .order('created_at', ascending: false)
        .limit(limit);

    // Create a mutable copy of the response
    final entries =
        (response as List).map((e) => Map<String, dynamic>.from(e)).toList();

    // Collect IDs for enrichment
    final receiptIds = <String>{};
    final manufacturerIds = <String>{};

    for (var entry in entries) {
      final category = entry['category'] as String?;
      final relatedId = entry['related_id'] as String?;

      if (relatedId != null && category != null) {
        if (category == 'Order Payment' || category == 'Customer Refund') {
          receiptIds.add(relatedId);
        } else if (category == 'Manufacturer Payment') {
          manufacturerIds.add(relatedId);
        }
      }
    }

    // Fetch Customer Names for Order Payments
    if (receiptIds.isNotEmpty) {
      try {
        final receipts = await _supabase
            .from('payment_receipts')
            .select('id, profiles!customer_id(name)')
            .inFilter('id', receiptIds.toList());

        final receiptToName = <String, String>{};
        for (final r in receipts as List) {
          final id = r['id'] as String;
          final profile = r['profiles'];
          if (profile != null && profile['name'] != null) {
            receiptToName[id] = profile['name'] as String;
          }
        }

        // Update entries
        for (var entry in entries) {
          final relatedId = entry['related_id'] as String?;
          final category = entry['category'] as String?;
          if (relatedId != null &&
              (category == 'Order Payment' || category == 'Customer Refund') &&
              receiptToName.containsKey(relatedId)) {
            final name = receiptToName[relatedId]!;
            // If user wants specific name, we replace the category
            entry['category'] =
                category == 'Customer Refund'
                    ? '$name Refund'
                    : '$name Payment';
          }
        }
      } catch (e) {
        // Silently ignore enrichment errors
        print('Error enriching cash book entries with customer names: $e');
      }
    }

    // Fetch Manufacturer Names for Manufacturer Payments
    if (manufacturerIds.isNotEmpty) {
      try {
        final manufacturers = await _supabase
            .from('manufacturers')
            .select('id, name')
            .inFilter('id', manufacturerIds.toList());

        final manufacturerToName = <String, String>{};
        for (final m in manufacturers as List) {
          final id = m['id'] as String;
          if (m['name'] != null) {
            manufacturerToName[id] = m['name'] as String;
          }
        }

        // Update entries
        for (var entry in entries) {
          final relatedId = entry['related_id'] as String?;
          final category = entry['category'] as String?;
          if (relatedId != null &&
              category == 'Manufacturer Payment' &&
              manufacturerToName.containsKey(relatedId)) {
            entry['category'] = '${manufacturerToName[relatedId]!} Payment';
          }
        }
      } catch (e) {
        // Silently ignore enrichment errors
        print('Error enriching cash book entries with manufacturer names: $e');
      }
    }

    return entries.map((e) => CashBookEntry.fromJson(e)).toList();
  }

  Future<Map<String, double>> getTotals() async {
    try {
      print('DEBUG REPO: Calling get_cash_book_totals RPC');
      final response = await _supabase.rpc('get_cash_book_totals');
      print('DEBUG REPO: RPC response: $response');
      if (response == null) {
        return {'total_payin': 0.0, 'total_payout': 0.0, 'balance': 0.0};
      }
      // Handle both String and int/double from RPC
      final payinRaw = response['total_payin'];
      final payoutRaw = response['total_payout'];
      final balanceRaw = response['balance'];
      
      return {
        'total_payin': (payinRaw is String ? double.parse(payinRaw) : (payinRaw as num).toDouble()),
        'total_payout': (payoutRaw is String ? double.parse(payoutRaw) : (payoutRaw as num).toDouble()),
        'balance': (balanceRaw is String ? double.parse(balanceRaw) : (balanceRaw as num).toDouble()),
      };
    } catch (e) {
      print('DEBUG REPO: RPC failed, trying fallback: $e');
      // If RPC fails, fallback to manual calculation (less efficient but safe)
      try {
        final allEntries = await _supabase
            .from('cash_book')
            .select('amount, entry_type');
        print('DEBUG REPO: Fallback got ${(allEntries as List).length} entries');
        double payin = 0;
        double payout = 0;
        for (final entry in allEntries as List) {
          if (entry['entry_type'] == 'payin') {
            payin += (entry['amount'] as num).toDouble();
          } else {
            payout += (entry['amount'] as num).toDouble();
          }
        }
        return {
          'total_payin': payin,
          'total_payout': payout,
          'balance': payin - payout,
        };
      } catch (fallbackError) {
        print('DEBUG REPO: Fallback also failed: $fallbackError');
        return {'total_payin': 0.0, 'total_payout': 0.0, 'balance': 0.0};
      }
    }
  }

  Future<int> getTotalCount() async {
    final response = await _supabase
        .from('cash_book')
        .select('id')
        .count(CountOption.exact);
    return response.count;
  }

  Future<void> deleteEntry(String id, {String? relatedId}) async {
    try {
      // 1. Check if the entry exists and is accessible
      final check =
          await _supabase.from('cash_book').select().eq('id', id).maybeSingle();

      if (check == null) {
        throw Exception(
          'Transaction not found. It may have been already deleted.',
        );
      }

      // 2. Check ownership for debugging RLS
      final currentUserId = _supabase.auth.currentUser?.id;
      final ownerId = check['created_by'] as String?;

      // If ownerId exists and doesn't match current user, that's likely the cause
      if (currentUserId != null &&
          ownerId != null &&
          currentUserId != ownerId) {
        throw Exception(
          'Permission denied: You did not create this transaction (Created by: $ownerId).',
        );
      }

      // 3. Attempt to delete
      final response =
          await _supabase.from('cash_book').delete().eq('id', id).select();

      // 4. If response is empty but check passed, it implies the DELETE policy blocked it
      if (response.isEmpty) {
        // If we got here, IDs matched (or owner was null), but delete still failed.
        // This usually means the DELETE policy itself is missing or broken.
        throw Exception(
          'Database Error: DELETE failed. Please check your Supabase "Delete" policy for the cash_book table.',
        );
      }

      if (relatedId != null) {
        await updateAccountBalance(relatedId);
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateEntry(
    String id,
    Map<String, dynamic> updates, {
    String? relatedId,
  }) async {
    try {
      await _supabase.from('cash_book').update(updates).eq('id', id);
      if (relatedId != null) {
        await updateAccountBalance(relatedId);
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteEntryByRelatedId(String relatedId) async {
    try {
      await _supabase.from('cash_book').delete().eq('related_id', relatedId);
    } catch (e) {
      rethrow;
    }
  }

  Future<int> deleteEntryByReference(
    String referenceId,
    String? referenceType,
  ) async {
    try {
      print('DEBUG: Trying to delete cashbook entry with ID: $referenceId, type: $referenceType');
      int deletedCount = 0;
      
      // Try with reference_id
      var query = _supabase.from('cash_book').delete().eq('reference_id', referenceId);
      if (referenceType != null) {
        query = query.eq('reference_type', referenceType);
      }
      var result = await query.select();
      print('DEBUG: Deleted by reference_id, count: ${result.length}');
      deletedCount += result.length;
      
      // If nothing deleted, try with related_id
      if (deletedCount == 0) {
        print('DEBUG: No entry found by reference_id, trying related_id');
        var query2 = _supabase.from('cash_book').delete().eq('related_id', referenceId);
        result = await query2.select();
        print('DEBUG: Deleted by related_id, count: ${result.length}');
        deletedCount += result.length;
      }
      
      // Last resort - try with payment_id column if it exists
      if (deletedCount == 0) {
        print('DEBUG: Still nothing, trying payment_id');
        try {
          var query3 = _supabase.from('cash_book').delete().eq('payment_id', referenceId);
          result = await query3.select();
          print('DEBUG: Deleted by payment_id, count: ${result.length}');
          deletedCount += result.length;
        } catch (e) {
          print('DEBUG: payment_id column does not exist');
        }
      }

      return deletedCount;
    } catch (e) {
      print('DEBUG: Error deleting entry: $e');
      rethrow;
    }
  }

  /// Get cashbook entry by reference ID and type
  Future<CashBookEntry?> getEntryByReference(
    String referenceId,
    String referenceType,
  ) async {
    try {
      final response = await _supabase
          .from('cash_book')
          .select()
          .eq('reference_id', referenceId)
          .eq('reference_type', referenceType)
          .maybeSingle();

      if (response == null) return null;
      return CashBookEntry.fromJson(Map<String, dynamic>.from(response));
    } catch (e) {
      return null;
    }
  }

  /// Delete a cash book entry by matching relatedId, amount, and date.
  /// This is used as a fallback for deleting legacy entries created before
  /// the reference_id system was implemented.
  Future<void> deleteEntryByFuzzyMatch({
    required String relatedId,
    required double amount,
    required DateTime date,
  }) async {
    try {
      // Find matching entries
      // We check for related_id (manufacturer_id) and amount match.
      // Date matching is tricky due to timestamp precision, so we check the same day.
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final response = await _supabase
          .from('cash_book')
          .select('id')
          .eq('related_id', relatedId)
          .eq('amount', amount)
          .gte('transaction_date', startOfDay.toIso8601String())
          .lt('transaction_date', endOfDay.toIso8601String())
          .limit(1); // Delete one at a time to be safe

      if ((response as List).isNotEmpty) {
        final id = response[0]['id'] as String;
        await _supabase.from('cash_book').delete().eq('id', id);
        await updateAccountBalance(relatedId);
      }
    } catch (e) {
      // Log error but don't rethrow to avoid breaking the main flow
      print('Error in deleteEntryByFuzzyMatch: $e');
    }
  }

  Future<void> updateEntryByRelatedId(
    String relatedId,
    Map<String, dynamic> updates,
  ) async {
    try {
      await _supabase
          .from('cash_book')
          .update(updates)
          .eq('related_id', relatedId);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> clearAllEntries() async {
    try {
      // Try using the efficient RPC first
      await _supabase.rpc('clear_cash_book');
    } catch (e) {
      // Fallback: Delete using a condition that matches all rows
      // We use amount > -1 which should cover all positive amounts
      // Since amount is double precision, this is safe.
      // Note: This still requires the DELETE policy to be fixed.
      try {
        await _supabase.from('cash_book').delete().gte('amount', -1);
      } catch (e2) {
        throw Exception(
          'Failed to clear cash book. Please ensure the "clear_cash_book" RPC exists or DELETE policy is enabled. Error: $e2',
        );
      }
    }
  }
}
