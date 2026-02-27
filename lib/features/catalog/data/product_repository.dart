import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'product.dart';
import 'hardware_products.dart';
import '../../../core/providers/supabase_provider.dart';
import '../../admin/data/product_repository_supabase.dart';

abstract class ProductRepository {
  Future<List<Product>> fetchFeatured();
  Future<List<Product>> fetchAll();
  Future<List<Product>> fetchPaginated({int page = 1, int limit = 20});
  Future<List<Product>> fetchFeaturedPaginated({int page = 1, int limit = 20});
  Future<List<Product>> fetchByCategory(
    String category, {
    int page = 1,
    int limit = 20,
  });
  Future<Product?> fetchById(String id);
}

class InMemoryProductRepository implements ProductRepository {
  InMemoryProductRepository();

  final List<Product> _products = HardwareProducts.getProducts();

  @override
  Future<List<Product>> fetchFeatured() async => _products.take(6).toList();

  @override
  Future<List<Product>> fetchAll() async => _products;

  @override
  Future<List<Product>> fetchPaginated({int page = 1, int limit = 20}) async {
    final startIndex = (page - 1) * limit;
    final endIndex = startIndex + limit;

    if (startIndex >= _products.length) return [];

    return _products.sublist(
      startIndex,
      endIndex > _products.length ? _products.length : endIndex,
    );
  }

  @override
  Future<List<Product>> fetchFeaturedPaginated({int page = 1, int limit = 20}) async {
    final featuredProducts = _products.where((p) => p.isFeatured).toList();
    final startIndex = (page - 1) * limit;
    final endIndex = startIndex + limit;

    if (startIndex >= featuredProducts.length) return [];

    return featuredProducts.sublist(
      startIndex,
      endIndex > featuredProducts.length ? featuredProducts.length : endIndex,
    );
  }

  @override
  Future<List<Product>> fetchByCategory(
    String category, {
    int page = 1,
    int limit = 20,
  }) async {
    final categoryProducts =
        _products
            .where(
              (p) => p.categories.any(
                (c) => c.toLowerCase() == category.toLowerCase(),
              ),
            )
            .toList();

    final startIndex = (page - 1) * limit;
    final endIndex = startIndex + limit;

    if (startIndex >= categoryProducts.length) return [];

    return categoryProducts.sublist(
      startIndex,
      endIndex > categoryProducts.length ? categoryProducts.length : endIndex,
    );
  }

  @override
  Future<Product?> fetchById(String id) async =>
      _products.where((e) => e.id == id).firstOrNull;
}

extension<T> on Iterable<T> {
  T? get firstOrNull {
    final it = iterator;
    if (it.moveNext()) return it.current;
    return null;
  }
}

final productRepositoryProvider = Provider<ProductRepository>((ref) {
  // Use Supabase repository for real-time data
  final supabaseClient = ref.watch(supabaseClientProvider);
  return ProductRepositorySupabase(supabaseClient);
});

/// Legacy featured products provider (no longer used by Home screen).
/// Kept for backward compatibility; new code should use the shared
/// `featuredProductsProvider` in `shared_product_provider.dart`, which
/// reads from live Supabase data and respects is_featured/featured_position.
final featuredProductsProvider = FutureProvider((ref) async {
  return ref.read(productRepositoryProvider).fetchFeatured();
});

// Note: allProductsProvider is now defined in shared_product_provider.dart
// This is kept for backward compatibility but should be migrated
final allProductsProviderLegacy = FutureProvider((ref) async {
  return ref.read(productRepositoryProvider).fetchAll();
});

final categoriesProviderLegacy = FutureProvider<List<String>>((ref) async {
  final products = await ref.watch(allProductsProviderLegacy.future);
  final set = <String>{};
  for (final p in products) {
    set.addAll(p.categories);
  }
  final list = set.toList()..sort();
  return list;
});
