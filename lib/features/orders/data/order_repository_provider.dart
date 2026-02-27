import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/supabase_provider.dart';
import 'order_repository.dart';
import 'order_repository_supabase.dart';

/// Order repository provider
final orderRepositoryProvider = Provider<OrderRepository>((ref) {
  final supabaseClient = ref.watch(supabaseClientProvider);
  return OrderRepositorySupabase(supabaseClient, ref);
});







