import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ionicons/ionicons.dart';
import '../../auth/application/auth_controller.dart';
import '../../catalog/presentation/widgets/product_grid.dart';
import '../application/wishlist_controller.dart';
import '../application/wishlist_providers.dart';
import '../../../core/ui/safe_scaffold.dart';
import '../../../core/layout/responsive.dart';

class WishlistScreen extends ConsumerWidget {
  const WishlistScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wishlistState = ref.watch(wishlistControllerProvider);
    final authState = ref.watch(authControllerProvider);
    final width = MediaQuery.of(context).size.width;
    final cardPadding = Responsive.getCardPadding(width);

    return SafeScaffold(
      appBar: AppBar(
        title: const Text('Purchase Later'),
      ),
      body: authState.isAuthenticated
          ? _buildAuthenticatedContent(context, ref, wishlistState, cardPadding)
          : _buildUnauthenticatedContent(context, cardPadding),
    );
  }

  Widget _buildAuthenticatedContent(
    BuildContext context,
    WidgetRef ref,
    WishlistState state,
    double cardPadding,
  ) {
    if (state.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Ionicons.warning_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              'Error loading purchase later list',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              state.error!,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () {
                ref.read(wishlistControllerProvider.notifier).loadWishlist();
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (state.products.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(cardPadding),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Ionicons.heart_outline,
                size: 80,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 24),
              Text(
                'Your purchase later list is empty',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Start adding products you want to purchase later',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.grey[600],
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              FilledButton.icon(
                onPressed: () {
                  // Navigate to catalog
                  Navigator.of(context).pop();
                },
                icon: const Icon(Ionicons.grid_outline),
                label: const Text('Browse Products'),
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with count
          Padding(
            padding: EdgeInsets.all(cardPadding),
            child: Row(
              children: [
                Icon(
                  Ionicons.heart,
                  color: Colors.red,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${state.products.length} ${state.products.length == 1 ? 'item' : 'items'} in your purchase later list',
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
              ],
            ),
          ),
          // Product grid
          ProductGrid(items: state.products),
        ],
      ),
    );
  }

  Widget _buildUnauthenticatedContent(
    BuildContext context,
    double cardPadding,
  ) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(cardPadding),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Ionicons.log_in_outline,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 24),
            Text(
              'Please log in to view your purchase later list',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Sign in to save products you love',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.grey[600],
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: () {
                // Navigate to login
                Navigator.of(context).pop();
              },
              icon: const Icon(Ionicons.log_in_outline),
              label: const Text('Log In'),
            ),
          ],
        ),
      ),
    );
  }
}

