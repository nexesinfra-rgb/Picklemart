import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'order_repository_provider.dart';
import 'order_repository_supabase.dart';
import 'order_model.dart';

/// Shared orders provider that subscribes to all orders once
/// This reduces duplicate subscriptions - multiple controllers can watch this provider
/// instead of each creating their own subscription
final sharedOrdersProvider = StreamProvider<List<Order>>((ref) {
  final repository = ref.watch(orderRepositoryProvider);
  
  // Only subscribe if repository is OrderRepositorySupabase
  if (repository is OrderRepositorySupabase) {
    if (kDebugMode) {
      print('📦 SharedOrdersProvider: Creating shared subscription to all orders');
    }
    return repository.subscribeToAllOrders();
  } else {
    if (kDebugMode) {
      print('⚠️ SharedOrdersProvider: Repository is not OrderRepositorySupabase, returning empty stream');
    }
    // Return empty stream if repository doesn't support real-time
    return Stream.value([]);
  }
});

/// Convenience provider for accessing orders synchronously (last emitted value)
final allOrdersProvider = Provider<List<Order>>((ref) {
  final ordersAsync = ref.watch(sharedOrdersProvider);
  return ordersAsync.when(
    data: (orders) => orders,
    loading: () => [],
    error: (_, __) => [],
  );
});

