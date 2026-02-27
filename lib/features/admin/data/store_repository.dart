import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/providers/supabase_provider.dart';
import '../domain/store_details.dart';

final storeRepositoryProvider = Provider<StoreRepository>((ref) {
  return StoreRepository(ref.watch(supabaseClientProvider));
});

class StoreRepository {
  final SupabaseClient _supabase;

  StoreRepository(this._supabase);

  Future<StoreDetails?> getStoreDetails() async {
    try {
      final response =
          await _supabase
              .from('store_settings')
              .select()
              .limit(1)
              .maybeSingle();
      if (response == null) return null;
      return StoreDetails.fromJson(response);
    } catch (e) {
      throw Exception('Failed to fetch store details: $e');
    }
  }

  Future<void> updateStoreDetails(StoreDetails store) async {
    try {
      final updates = {
        'name': store.name,
        'address': store.address,
        'phone': store.phone,
        'email': store.email,
        'gst_number': store.gstNumber,
        'updated_at': DateTime.now().toIso8601String(),
      };

      // If id is empty or we are creating a new one (should exist from migration though)
      if (store.id.isEmpty) {
        // This case might happen if migration didn't run and table is empty
        await _supabase.from('store_settings').insert(updates);
      } else {
        await _supabase
            .from('store_settings')
            .update(updates)
            .eq('id', store.id);
      }
    } catch (e) {
      throw Exception('Failed to update store details: $e');
    }
  }
}
