import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/supabase_provider.dart';
import 'address_repository.dart';
import 'address_repository_supabase.dart';

/// Address repository provider
final addressRepositoryProvider = Provider<AddressRepository>((ref) {
  final supabaseClient = ref.watch(supabaseClientProvider);
  return AddressRepositorySupabase(supabaseClient);
});

/// Saved addresses provider (deprecated - use addressControllerProvider instead)
@Deprecated('Use addressControllerProvider instead')
final savedAddressesProvider = Provider<List<Address>>((ref) {
  return [];
});







