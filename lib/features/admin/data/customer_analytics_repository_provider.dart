import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/supabase_provider.dart';
import 'customer_analytics_repository.dart';

/// Provider for CustomerAnalyticsRepository instance
final customerAnalyticsRepositoryProvider =
    Provider<CustomerAnalyticsRepository>((ref) {
  final supabaseClient = ref.watch(supabaseClientProvider);
  return CustomerAnalyticsRepository(supabaseClient);
});

