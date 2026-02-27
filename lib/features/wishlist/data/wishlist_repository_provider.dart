import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/supabase_provider.dart';
import '../../catalog/data/product_repository.dart';
import 'wishlist_repository.dart';
import 'wishlist_repository_supabase.dart';

/// Provider for wishlist repository
final wishlistRepositoryProvider = Provider<WishlistRepository>((ref) {
  final supabaseClient = ref.watch(supabaseClientProvider);
  final productRepository = ref.watch(productRepositoryProvider);
  return WishlistRepositorySupabase(supabaseClient, productRepository);
});





