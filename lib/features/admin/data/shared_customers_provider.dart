import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../application/admin_customer_controller.dart';
import 'customer_repository_provider.dart';

/// Shared customers provider that uses the customer repository
/// One-shot fetch (no realtime stream) - avoids infinite loading and shows errors clearly
final sharedCustomersProvider = FutureProvider<List<Customer>>((ref) async {
  final customerRepository = ref.watch(customerRepositoryProvider);
  try {
    if (kDebugMode) {
      print('📊 sharedCustomersProvider: Starting getAllCustomers()...');
    }
    final customers = await customerRepository.getAllCustomers();
    if (kDebugMode) {
      print(
        '✅ sharedCustomersProvider: getAllCustomers returned ${customers.length} customers',
      );
    }
    return customers;
  } catch (e, st) {
    if (kDebugMode) {
      print('❌ sharedCustomersProvider ERROR: $e');
      print('Stack trace: $st');
    }
    rethrow;
  }
});

