import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/providers/supabase_provider.dart';

final paymentCashbookLinkRepositoryProvider =
    Provider<PaymentCashbookLinkRepository>((ref) {
  return PaymentCashbookLinkRepository(ref.watch(supabaseClientProvider));
});

class PaymentCashbookLinkRepository {
  final SupabaseClient _supabase;

  PaymentCashbookLinkRepository(this._supabase);

  /// Create a link between a payment and a cashbook entry
  Future<String> createLink({
    required String paymentId,
    required String paymentType,
    required String cashBookEntryId,
  }) async {
    final response = await _supabase.from('payment_cashbook_links').insert({
      'payment_id': paymentId,
      'payment_type': paymentType,
      'cash_book_entry_id': cashBookEntryId,
    }).select('id').single();

    return response['id'] as String;
  }

  /// Get link by payment ID and type
  Future<Map<String, dynamic>?> getLinkByPaymentId(
    String paymentId,
    String paymentType,
  ) async {
    final response = await _supabase
        .from('payment_cashbook_links')
        .select()
        .eq('payment_id', paymentId)
        .eq('payment_type', paymentType)
        .maybeSingle();

    return response;
  }

  /// Get link by cashbook entry ID
  Future<Map<String, dynamic>?> getLinkByCashBookEntryId(
    String cashBookEntryId,
  ) async {
    final response = await _supabase
        .from('payment_cashbook_links')
        .select()
        .eq('cash_book_entry_id', cashBookEntryId)
        .maybeSingle();

    return response;
  }

  /// Delete link and associated cashbook entry by payment ID and type
  /// This performs cascade deletion: first deletes the cashbook entry, then the link
  Future<void> deleteByPaymentId(
    String paymentId,
    String paymentType,
  ) async {
    // First, get the cashbook entry ID
    final link = await getLinkByPaymentId(paymentId, paymentType);
    if (link == null) return;

    final cashBookEntryId = link['cash_book_entry_id'] as String;

    // Delete the cashbook entry first (this will update account balance)
    try {
      await _supabase.from('cash_book').delete().eq('id', cashBookEntryId);
    } catch (e) {
      // If cashbook entry is already deleted, continue with link deletion
      print('Cashbook entry deletion error (may already be deleted): $e');
    }

    // Then delete the link
    await _supabase.from('payment_cashbook_links').delete().eq('id', link['id']);
  }

  /// Delete link by cashbook entry ID
  Future<void> deleteByCashBookEntryId(String cashBookEntryId) async {
    // Get the link first
    final link = await getLinkByCashBookEntryId(cashBookEntryId);
    if (link == null) return;

    // Delete the link
    await _supabase.from('payment_cashbook_links').delete().eq('id', link['id']);
  }

  /// Get all links for a payment type
  Future<List<Map<String, dynamic>>> getLinksByPaymentType(
    String paymentType,
  ) async {
    final response = await _supabase
        .from('payment_cashbook_links')
        .select()
        .eq('payment_type', paymentType);

    return List<Map<String, dynamic>>.from(response);
  }

  /// Update the cashbook entry ID in a link (for edit scenarios)
  Future<void> updateCashBookEntryId(
    String linkId,
    String newCashBookEntryId,
  ) async {
    await _supabase
        .from('payment_cashbook_links')
        .update({'cash_book_entry_id': newCashBookEntryId})
        .eq('id', linkId);
  }
}
