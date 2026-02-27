import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'customer_repository.dart';
import 'customer_repository_supabase.dart';
import '../../../core/providers/supabase_provider.dart';

/// Provider for CustomerRepository instance
final customerRepositoryProvider = Provider<CustomerRepository>((ref) {
  final supabaseClient = ref.watch(supabaseClientProvider);
  return CustomerRepositorySupabase(supabaseClient);
});

