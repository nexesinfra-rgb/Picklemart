import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ionicons/ionicons.dart';
import '../../cart/application/cart_controller.dart';
import '../../catalog/data/measurement.dart';
import '../../../core/ui/responsive_buttons.dart';
import '../../../core/ui/safe_scaffold.dart';
import '../../../core/layout/responsive.dart';
import '../../../core/navigation/navigation_helper.dart';
import '../../../core/widgets/lazy_image.dart';
import '../../../core/constants/ui_constants.dart';
import 'package:go_router/go_router.dart';
import '../../profile/application/profile_controller.dart';

class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  double _getItemPrice(CartItem item) {
    if (item.measurementUnit != null && item.product.hasMeasurementPricing) {
      final measurement = item.product.measurement!;
      final pricing = measurement.getPricingForUnit(item.measurementUnit!);
      final basePrice = pricing?.price ?? item.product.price;
      // Calculate final price with tax for measurement pricing
      if (item.product.tax != null && item.product.tax! > 0) {
        return basePrice + (basePrice * item.product.tax! / 100);
      }
      return basePrice;
    }
    // Use variant's final price with fallback to product tax, or product's final price
    if (item.variant != null) {
      return item.variant!.finalPriceWithFallback(item.product.tax);
    }
    return item.product.finalPrice;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartProvider);
    final items = cart.values.toList();
    final total = ref.read(cartProvider.notifier).total;
    final totalItems = items.fold<int>(0, (sum, item) => sum + item.quantity);
    
    // Debug logging
    if (kDebugMode) {
      print('DEBUG: Cart Screen - Unique products: ${cart.length}');
      cart.forEach((key, item) {
        print('  - $key: ${item.product.name} (qty: ${item.quantity})');
      });
    }
    final width = MediaQuery.of(context).size.width;
    final cardPadding = Responsive.getCardPadding(width);
    // Slightly smaller padding for screen edges so content is closer to borders
    final edgePadding = cardPadding * kScreenEdgePaddingFactor;
    final sectionSpacing = Responsive.getSectionSpacing(width);

    return SafeScaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Ionicons.arrow_back_outline),
          onPressed: () => NavigationHelper.handleBackNavigation(context, ref: ref),
        ),
        title: Text('Cart ($totalItems items)'),
      ),
      body: items.isEmpty
              ? Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: edgePadding,
                    vertical: cardPadding,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Ionicons.cart_outline,
                          size: 64,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      SizedBox(height: sectionSpacing),
                      Text(
                        'Your cart is empty',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: cardPadding * 0.5),
                      Text(
                        'Add items to your cart to get started',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                      SizedBox(height: sectionSpacing),
                      FilledButton.icon(
                        onPressed: () => context.goNamed('home'),
                        icon: const Icon(Ionicons.home_outline),
                        label: const Text('Start Shopping'),
                        style: FilledButton.styleFrom(
                          padding: EdgeInsets.symmetric(
                            horizontal: cardPadding * 1.5,
                            vertical: cardPadding * 0.75,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )
              : Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.symmetric(
                        horizontal: edgePadding,
                        vertical: cardPadding,
                      ),
                      child: Column(
                        children:
                            items.map((item) {
                              return Padding(
                                padding: EdgeInsets.only(bottom: cardPadding * 0.75),
                                child: Card(
                                  elevation: 2,
                                  child: Padding(
                                    padding: EdgeInsets.all(cardPadding),
                                    child: Column(
                                      children: [
                                        Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            SizedBox(
                                              width: 64,
                                              height: 64,
                                              child: ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                child: LazyImage(
                                                  imageUrl: item.product.imageUrl,
                                                  fit: BoxFit.cover,
                                                  borderRadius: BorderRadius.circular(12),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    item.product.name,
                                                    maxLines: 2,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style:
                                                        Theme.of(
                                                          context,
                                                        ).textTheme.titleSmall,
                                                  ),
                                                  if (item.variant != null) ...[
                                                    const SizedBox(height: 2),
                                                    Text(
                                                      item
                                                          .variant!
                                                          .attributes
                                                          .entries
                                                          .map(
                                                            (e) =>
                                                                '${e.key}: ${e.value}',
                                                          )
                                                          .join(' • '),
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      style:
                                                          Theme.of(
                                                            context,
                                                          ).textTheme.bodySmall,
                                                    ),
                                                  ],
                                                  if (item.measurementUnit !=
                                                      null) ...[
                                                    const SizedBox(height: 2),
                                                    Text(
                                                      'Per ${item.measurementUnit!.shortName}',
                                                      style:
                                                          Theme.of(
                                                            context,
                                                          ).textTheme.bodySmall,
                                                    ),
                                                  ],
                                                  const SizedBox(height: 4),
                                                  Consumer(
                                                    builder: (context, ref, child) {
                                                      final profile = ref.watch(currentProfileProvider);
                                                      if (profile == null || !profile.priceVisibilityEnabled) {
                                                        return const SizedBox.shrink();
                                                      }
                                                      return Text(
                                                        '₹${_getItemPrice(item).toStringAsFixed(2)}',
                                                        style: const TextStyle(
                                                          fontWeight:
                                                              FontWeight.w600,
                                                        ),
                                                      );
                                                    },
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 12),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Row(
                                              children: [
                                                ResponsiveIconButton(
                                                  onPressed:
                                                      () => ref
                                                          .read(
                                                            cartProvider
                                                                .notifier,
                                                          )
                                                          .remove(
                                                            item.product,
                                                            variant:
                                                                item.variant,
                                                            measurementUnit:
                                                                item.measurementUnit,
                                                          ),
                                                  icon: const Icon(
                                                    Ionicons
                                                        .remove_circle_outline,
                                                  ),
                                                ),
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 8.0,
                                                      ),
                                                  child: Text(
                                                    '${item.quantity}',
                                                  ),
                                                ),
                                                ResponsiveIconButton(
                                                  onPressed:
                                                      () => ref
                                                          .read(
                                                            cartProvider
                                                                .notifier,
                                                          )
                                                          .add(
                                                            item.product,
                                                            variant:
                                                                item.variant,
                                                            measurementUnit:
                                                                item.measurementUnit,
                                                          ),
                                                  icon: const Icon(
                                                    Ionicons.add_circle_outline,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            TextButton(
                                              onPressed:
                                                  () => ref
                                                      .read(
                                                        cartProvider.notifier,
                                                      )
                                                      .delete(
                                                        item.product,
                                                        variant: item.variant,
                                                        measurementUnit:
                                                            item.measurementUnit,
                                                      ),
                                              child: const Text('Remove'),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                      ),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 4,
                          offset: const Offset(0, -2),
                        ),
                      ],
                    ),
                    padding: EdgeInsets.symmetric(
                      horizontal: edgePadding,
                      vertical: cardPadding,
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Total',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Consumer(
                              builder: (context, ref, child) {
                                final profile = ref.watch(currentProfileProvider);
                                if (profile == null || !profile.priceVisibilityEnabled) {
                                  return const SizedBox.shrink();
                                }
                                return Text(
                                  '₹${total.toStringAsFixed(2)}',
                                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                        SizedBox(height: cardPadding * 0.75),
                        FilledButton.icon(
                          onPressed: () => context.pushNamed('checkout-address'),
                          icon: const Icon(Ionicons.checkmark_circle_outline),
                          label: const Text('Proceed to Checkout'),
                          style: FilledButton.styleFrom(
                            padding: EdgeInsets.symmetric(
                              horizontal: cardPadding * 1.5,
                              vertical: cardPadding * 1.25,
                            ),
                            minimumSize: const Size(double.infinity, 0),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
    );
  }
}
