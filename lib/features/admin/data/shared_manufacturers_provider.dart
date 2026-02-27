import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/manufacturer.dart';
import '../../../core/providers/supabase_provider.dart';
import 'manufacturer_repository.dart';

/// Shared manufacturers provider that fetches all manufacturers
/// Used by dashboard and other screens to get the total count and list
final sharedManufacturersProvider = FutureProvider<List<Manufacturer>>((
  ref,
) async {
  final supabaseClient = ref.watch(supabaseClientProvider);
  final repository = ManufacturerRepository(supabaseClient);

  try {
    if (kDebugMode) {
      print(
        '📊 sharedManufacturersProvider: Starting getAllManufacturers()...',
      );
    }
    final manufacturers = await repository.getAllManufacturers();
    if (kDebugMode) {
      print(
        '✅ sharedManufacturersProvider: getAllManufacturers returned ${manufacturers.length} manufacturers',
      );
    }
    return manufacturers;
  } catch (e, st) {
    if (kDebugMode) {
      print('❌ sharedManufacturersProvider ERROR: $e');
      print('Stack trace: $st');
    }
    rethrow;
  }
});
