import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/supabase_provider.dart';
import '../../admin/data/product_repository_supabase.dart';
import 'cart_repository.dart';
import 'cart_repository_supabase.dart';

/// Product repository Supabase provider (for cart operations)
final productRepositorySupabaseProvider = Provider<ProductRepositorySupabase>((ref) {
  final supabaseClient = ref.watch(supabaseClientProvider);
  return ProductRepositorySupabase(supabaseClient);
});

/// Cart repository provider
final cartRepositoryProvider = Provider<CartRepository>((ref) {
  final supabaseClient = ref.watch(supabaseClientProvider);
  final productRepository = ref.watch(productRepositorySupabaseProvider);
  
  return CartRepositorySupabase(supabaseClient, productRepository);
});

