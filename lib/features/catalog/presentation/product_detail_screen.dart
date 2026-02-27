import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ionicons/ionicons.dart';
import 'package:go_router/go_router.dart';
import '../../catalog/data/product_repository.dart';
import '../../catalog/data/product.dart';
import '../../catalog/data/measurement.dart';
import 'widgets/image_gallery.dart';
import 'widgets/shipping_eta.dart';
import 'widgets/measurement_selector.dart';
import '../../cart/application/cart_controller.dart';
import '../../wishlist/application/wishlist_providers.dart';
import '../../../core/ui/safe_scaffold.dart';
import '../../catalog/data/recent_categories.dart';
import '../../../core/providers/supabase_provider.dart';
import '../../catalog/data/shared_product_provider.dart';
import '../../../core/layout/responsive.dart';
import 'widgets/universal_product_card.dart';
import '../../ratings/presentation/widgets/star_rating_widget.dart';
import '../../ratings/presentation/widgets/rating_replies_section.dart';
import '../../ratings/data/rating_repository.dart';
import '../../profile/application/profile_controller.dart';

class ProductDetailScreen extends ConsumerStatefulWidget {
  final String productId;
  const ProductDetailScreen({super.key, required this.productId});

  @override
  ConsumerState<ProductDetailScreen> createState() =>
      _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  Map<String, String> selected = {};
  int qty = 1;
  MeasurementUnit? selectedMeasurementUnit;
  late Future<Product?> _productFuture;
  bool _loggedView = false;
  String? _viewRecordId;
  DateTime? _viewStartedAt;
  Timer? _durationUpdateTimer;
  static const Duration _updateInterval = Duration(seconds: 5);

  @override
  void initState() {
    super.initState();
    // Memoize the product future so UI state changes (like qty) don't refetch.
    _productFuture = ref
        .read(productRepositoryProvider)
        .fetchById(widget.productId);
  }

  @override
  void didUpdateWidget(covariant ProductDetailScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.productId != widget.productId) {
      _productFuture = ref
          .read(productRepositoryProvider)
          .fetchById(widget.productId);
      _loggedView = false;
      _viewRecordId = null;
      _viewStartedAt = null;
    }
  }

  Future<void> _logProductView(Product product) async {
    if (_loggedView) return;
    _loggedView = true;
    try {
      final supabase = ref.read(supabaseClientProvider);
      final userId = supabase.auth.currentUser?.id;
      final now = DateTime.now();
      // Use viewed_at as it exists in the schema (started_at may not exist)
      final inserted =
          await supabase
              .from('product_views')
              .insert({
                'product_id': product.id,
                'user_id': userId,
                'viewed_at': now.toIso8601String(),
              })
              .select('id, viewed_at')
              .maybeSingle();

      _viewRecordId = inserted != null ? inserted['id'] as String? : null;
      // Try to parse viewed_at, fallback to started_at if it exists, otherwise use now
      final viewedAtStr = inserted?['viewed_at'] as String?;
      final startedAtStr = inserted?['started_at'] as String?;
      final parsedStart =
          viewedAtStr != null
              ? DateTime.tryParse(viewedAtStr)
              : (startedAtStr != null ? DateTime.tryParse(startedAtStr) : null);
      _viewStartedAt = parsedStart ?? now;

      // Start periodic duration updates
      _startDurationUpdates();
    } catch (_) {
      // Best-effort; ignore logging failures
    }
  }

  void _startDurationUpdates() {
    _durationUpdateTimer?.cancel();
    if (_viewRecordId == null || _viewStartedAt == null) return;

    _durationUpdateTimer = Timer.periodic(_updateInterval, (timer) {
      if (!mounted || _viewRecordId == null || _viewStartedAt == null) {
        timer.cancel();
        return;
      }
      _updateDurationPeriodically();
    });
  }

  Future<void> _updateDurationPeriodically() async {
    if (_viewRecordId == null || _viewStartedAt == null) return;
    try {
      final supabase = ref.read(supabaseClientProvider);
      final now = DateTime.now();
      final rawDuration = now.difference(_viewStartedAt!).inSeconds;
      // Ensure duration is never negative (handle clock skew issues)
      final positiveDuration = rawDuration > 0 ? rawDuration : 0;
      await supabase
          .from('product_views')
          .update({'duration_seconds': positiveDuration})
          .eq('id', _viewRecordId as Object);
    } catch (_) {
      // Best-effort; ignore logging failures
    }
  }

  Future<void> _endProductView() async {
    // Cancel periodic updates first
    _durationUpdateTimer?.cancel();
    _durationUpdateTimer = null;

    if (_viewRecordId == null || _viewStartedAt == null) return;
    try {
      final supabase = ref.read(supabaseClientProvider);
      final endedAt = DateTime.now();
      final rawDuration = endedAt.difference(_viewStartedAt!).inSeconds;
      // Ensure duration is never negative (handle clock skew issues)
      final positiveDuration = rawDuration > 0 ? rawDuration : 0;
      // Update duration_seconds (ended_at may not exist in schema)
      await supabase
          .from('product_views')
          .update({'duration_seconds': positiveDuration})
          .eq('id', _viewRecordId as Object);
    } catch (_) {
      // Best-effort; ignore logging failures
    }
  }

  @override
  void dispose() {
    _durationUpdateTimer?.cancel();
    _endProductView();
    super.dispose();
  }

  Variant? _matchVariant(Product p) {
    for (final v in p.variants) {
      bool ok = true;
      for (final entry in selected.entries) {
        if (v.attributes[entry.key] != entry.value) {
          ok = false;
          break;
        }
      }
      if (ok && selected.length == v.attributes.length) return v;
    }
    return null;
  }

  Map<String, Set<String>> _allOptions(Product p) {
    final map = <String, Set<String>>{};
    for (final v in p.variants) {
      v.attributes.forEach((k, val) {
        map.putIfAbsent(k, () => <String>{}).add(val);
      });
    }
    return map;
  }

  bool _isValueAvailable(Product p, String key, String value) {
    for (final v in p.variants) {
      if (v.attributes[key] != value) continue;
      bool ok = true;
      for (final entry in selected.entries) {
        if (entry.key == key) continue;
        if (v.attributes[entry.key] != entry.value) {
          ok = false;
          break;
        }
      }
      if (ok && v.stock > 0) return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Product?>(
      future: _productFuture,
      builder: (context, snapshot) {
        final p = snapshot.data;
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (p == null) {
          return const Scaffold(body: Center(child: Text('Product not found')));
        }

        final variant = _matchVariant(p);

        if (!_loggedView) {
          Future.microtask(() => _logProductView(p));
        }

        // Handle measurement-based pricing
        double price;
        int stock;
        String sku;

        if (p.hasMeasurementPricing && p.measurement != null) {
          final measurement = p.measurement!;
          final currentUnit =
              selectedMeasurementUnit ?? measurement.defaultUnit;
          final pricing = measurement.getPricingForUnit(currentUnit);

          if (pricing != null) {
            price = pricing.price;
            stock = pricing.stock;
            sku = '${p.sku ?? p.id}-${currentUnit.shortName}';
          } else {
            // Fallback to base product pricing
            price = variant?.price ?? p.price;
            stock = variant?.stock ?? p.stock;
            sku = variant?.sku ?? p.sku ?? 'N/A';
          }
        } else {
          // Standard variant-based pricing
          price = variant?.price ?? p.price;
          stock = variant?.stock ?? p.stock;
          sku = variant?.sku ?? p.sku ?? 'N/A';
        }

        final images =
            (variant?.images.isNotEmpty == true)
                ? variant!.images
                : (p.images.isNotEmpty ? p.images : [p.imageUrl]);

        // Record categories as viewed once when opening a product
        WidgetsBinding.instance.addPostFrameCallback((_) {
          for (final c in p.categories) {
            ref.read(recentCategoriesProvider.notifier).markViewed(c);
          }
        });
        return SafeScaffold(
          appBar: AppBar(
            title: Text(p.name),
            actions: [
              // Wishlist heart button
              Consumer(
                builder: (context, ref, _) {
                  final isInWishlist = ref.watch(
                    isProductInWishlistProvider(p.id),
                  );
                  return IconButton(
                    icon: Icon(
                      isInWishlist ? Ionicons.heart : Ionicons.heart_outline,
                      color: isInWishlist ? Colors.red : null,
                    ),
                    onPressed: () {
                      final controller = ref.read(
                        wishlistControllerProvider.notifier,
                      );
                      if (isInWishlist) {
                        controller.removeFromWishlist(p.id);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Removed from purchase later'),
                            duration: Duration(seconds: 1),
                          ),
                        );
                      } else {
                        controller.addToWishlist(p.id);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Added to purchase later'),
                            duration: Duration(seconds: 1),
                          ),
                        );
                      }
                    },
                    tooltip:
                        isInWishlist
                            ? 'Remove from purchase later'
                            : 'Add to purchase later',
                  );
                },
              ),
              // Cart icon
              Consumer(
                builder: (context, ref, _) {
                  final cart = ref.watch(cartProvider);
                  print(
                    '308 DEBUG: Cart: $cart, in the product detail screen 308',
                  );
                  final count =
                      cart.values.map((item) => item.product.id).toSet().length;

                  final hasItems = count > 0;
                  return Container(
                    decoration: BoxDecoration(
                      color:
                          hasItems
                              ? Theme.of(
                                context,
                              ).colorScheme.primary.withOpacity(0.1)
                              : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      border:
                          hasItems
                              ? Border.all(
                                color: Theme.of(
                                  context,
                                ).colorScheme.primary.withOpacity(0.3),
                                width: 1.5,
                              )
                              : null,
                    ),
                    child: Badge.count(
                      count: count,
                      isLabelVisible: hasItems,
                      alignment: const Alignment(0.8, -0.8),
                      backgroundColor: Theme.of(context).colorScheme.error,
                      textStyle: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                      child: IconButton(
                        icon: Icon(
                          hasItems ? Ionicons.cart : Ionicons.cart_outline,
                          color:
                              hasItems
                                  ? Theme.of(context).colorScheme.primary
                                  : null,
                        ),
                        onPressed: () => context.goNamed('cart'),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
          body: Stack(
            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  final wide = constraints.maxWidth >= 900;
                  final content = ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1200),
                    child: Padding(
                      padding: Responsive.getHomeContentPadding(
                        constraints.maxWidth,
                      ),
                      child:
                          wide
                              ? Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    flex: 5,
                                    child: ImageGallery(
                                      images: images,
                                      product: p,
                                    ),
                                  ),
                                  const SizedBox(width: 24),
                                  Expanded(
                                    flex: 5,
                                    child: _InfoBlock(
                                      p: p,
                                      price: price,
                                      sku: sku,
                                      stock: stock,
                                      variant: variant,
                                      qty: qty,
                                      selected: selected,
                                      options: _allOptions(p),
                                      selectedMeasurementUnit:
                                          selectedMeasurementUnit,
                                      onSelect:
                                          (k, v) =>
                                              setState(() => selected[k] = v),
                                      onUnselect:
                                          (k) => setState(
                                            () => selected.remove(k),
                                          ),
                                      isValueAvailable:
                                          (k, v) => _isValueAvailable(p, k, v),
                                      onMeasurementUnitChanged:
                                          (unit) => setState(
                                            () =>
                                                selectedMeasurementUnit = unit,
                                          ),
                                    ),
                                  ),
                                ],
                              )
                              : Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ImageGallery(images: images, product: p),
                                  const SizedBox(height: 16),
                                  _InfoBlock(
                                    p: p,
                                    price: price,
                                    sku: sku,
                                    stock: stock,
                                    variant: variant,
                                    qty: qty,
                                    selected: selected,
                                    options: _allOptions(p),
                                    selectedMeasurementUnit:
                                        selectedMeasurementUnit,
                                    onSelect:
                                        (k, v) =>
                                            setState(() => selected[k] = v),
                                    onUnselect:
                                        (k) =>
                                            setState(() => selected.remove(k)),
                                    isValueAvailable:
                                        (k, v) => _isValueAvailable(p, k, v),
                                    onMeasurementUnitChanged:
                                        (unit) => setState(
                                          () => selectedMeasurementUnit = unit,
                                        ),
                                  ),
                                ],
                              ),
                    ),
                  );
                  return Align(
                    alignment: Alignment.topCenter,
                    child: SingleChildScrollView(child: content),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class _DetailAddOrQty extends ConsumerWidget {
  final Product product;
  final Variant? variant;
  final bool available;
  final int initialQty;
  final MeasurementUnit? measurementUnit;

  const _DetailAddOrQty({
    required this.product,
    required this.variant,
    required this.available,
    required this.initialQty,
    this.measurementUnit,
  });

  String _key(Product p, Variant? v, MeasurementUnit? unit) {
    if (unit != null) {
      return '${p.id}:${v?.sku ?? 'base'}:${unit.shortName}';
    }
    return '${p.id}:${v?.sku ?? 'base'}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartProvider);
    final key = _key(product, variant, measurementUnit);
    final item = cart[key];
    final qty = item?.quantity ?? 0;
    if (qty == 0) {
      return Row(
        children: [
          Expanded(
            child: FilledButton.icon(
              onPressed:
                  available
                      ? () => ref
                          .read(cartProvider.notifier)
                          .add(
                            product,
                            variant: variant,
                            qty: initialQty,
                            measurementUnit: measurementUnit,
                          )
                      : null,
              icon: const Icon(Ionicons.cart_outline, size: 18),
              label: const Text('Add to Cart'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: OutlinedButton(
              onPressed:
                  available
                      ? () {
                        ref
                            .read(cartProvider.notifier)
                            .add(
                              product,
                              variant: variant,
                              qty: initialQty,
                              measurementUnit: measurementUnit,
                            );
                        context.pushNamed('checkout-address');
                      }
                      : null,
              child: const Text('Buy Now'),
            ),
          ),
        ],
      );
    }
    return Row(
      children: [
        IconButton(
          icon: const Icon(Ionicons.remove_outline),
          onPressed:
              () => ref
                  .read(cartProvider.notifier)
                  .remove(
                    product,
                    variant: variant,
                    measurementUnit: measurementUnit,
                  ),
        ),
        Text('$qty'),
        IconButton(
          icon: const Icon(Ionicons.add_outline),
          onPressed:
              available
                  ? () => ref
                      .read(cartProvider.notifier)
                      .add(
                        product,
                        variant: variant,
                        measurementUnit: measurementUnit,
                      )
                  : null,
        ),
        const SizedBox(width: 8),
        TextButton(
          onPressed:
              () => ref
                  .read(cartProvider.notifier)
                  .delete(
                    product,
                    variant: variant,
                    measurementUnit: measurementUnit,
                  ),
          child: const Text('Remove'),
        ),
      ],
    );
  }
}

class _InfoBlock extends StatefulWidget {
  final Product p;
  final double price;
  final String sku;
  final int stock;
  final Variant? variant;
  final int qty;
  final Map<String, String> selected;
  final Map<String, Set<String>> options;
  final MeasurementUnit? selectedMeasurementUnit;
  final void Function(String key, String value) onSelect;
  final void Function(String key) onUnselect;
  final bool Function(String key, String value) isValueAvailable;
  final void Function(MeasurementUnit unit) onMeasurementUnitChanged;

  const _InfoBlock({
    required this.p,
    required this.price,
    required this.sku,
    required this.stock,
    required this.variant,
    required this.qty,
    required this.selected,
    required this.options,
    this.selectedMeasurementUnit,
    required this.onSelect,
    required this.onUnselect,
    required this.isValueAvailable,
    required this.onMeasurementUnitChanged,
  });

  @override
  State<_InfoBlock> createState() => _InfoBlockState();
}

class _InfoBlockState extends State<_InfoBlock> {
  bool _isDescriptionExpanded = false;
  static const int _descriptionCharacterLimit = 150;
  int _suggestedProductsPage = 1;
  int _similarProductsPage = 1;

  @override
  void didUpdateWidget(covariant _InfoBlock oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reset pagination when product changes
    if (oldWidget.p.id != widget.p.id) {
      _suggestedProductsPage = 1;
      _similarProductsPage = 1;
    }
  }

  Widget _buildDescription(String description) {
    final needsTruncation = description.length > _descriptionCharacterLimit;

    if (!needsTruncation) {
      // Description is short, show it normally
      return Text(description);
    }

    if (_isDescriptionExpanded) {
      // Show full description with "Read Less" link
      return Text.rich(
        TextSpan(
          text: description,
          style: Theme.of(context).textTheme.bodyMedium,
          children: [
            const TextSpan(text: ' '),
            TextSpan(
              text: 'Read Less',
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
              recognizer:
                  TapGestureRecognizer()
                    ..onTap = () {
                      setState(() {
                        _isDescriptionExpanded = false;
                      });
                    },
            ),
          ],
        ),
      );
    } else {
      // Show truncated description with "Read More" link
      // Truncate at word boundary for better UX
      String truncatedText = description.substring(
        0,
        _descriptionCharacterLimit,
      );
      final lastSpaceIndex = truncatedText.lastIndexOf(' ');
      if (lastSpaceIndex > _descriptionCharacterLimit * 0.8) {
        // Only use word boundary if it's not too far from the limit
        truncatedText = truncatedText.substring(0, lastSpaceIndex);
      }
      return Text.rich(
        TextSpan(
          text: '$truncatedText... ',
          style: Theme.of(context).textTheme.bodyMedium,
          children: [
            TextSpan(
              text: 'Read More',
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
              recognizer:
                  TapGestureRecognizer()
                    ..onTap = () {
                      setState(() {
                        _isDescriptionExpanded = true;
                      });
                    },
            ),
          ],
        ),
      );
    }
  }

  /// Calculate final price including tax
  double _calculateFinalPrice(
    double basePrice,
    Variant? variant,
    Product product,
  ) {
    // If variant exists, use variant's final price (with fallback to product tax)
    if (variant != null) {
      return variant.finalPriceWithFallback(product.tax);
    }
    // Otherwise use product's final price
    return product.finalPrice;
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.p;
    final price = widget.price;
    final sku = widget.sku;
    final stock = widget.stock;
    final variant = widget.variant;
    final qty = widget.qty;
    final selected = widget.selected;
    final options = widget.options;
    final selectedMeasurementUnit = widget.selectedMeasurementUnit;
    final onSelect = widget.onSelect;
    final onUnselect = widget.onUnselect;
    final isValueAvailable = widget.isValueAvailable;
    final onMeasurementUnitChanged = widget.onMeasurementUnitChanged;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(p.name, style: Theme.of(context).textTheme.titleLarge),
        if (p.subtitle != null) ...[
          const SizedBox(height: 4),
          Text(p.subtitle!, style: Theme.of(context).textTheme.bodyMedium),
        ],
        // Rating section hidden on product detail screen
        const SizedBox.shrink(),
        if (p.tags.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              for (final t in p.tags)
                ActionChip(
                  label: Text(t),
                  onPressed:
                      () => context.pushNamed(
                        'browse',
                        pathParameters: {'kind': 'tag', 'value': t},
                      ),
                ),
            ],
          ),
        ],
        const SizedBox(height: 12),
        // Measurement-based pricing display
        Consumer(
          builder: (context, ref, child) {
            final profile = ref.watch(currentProfileProvider);
            if (profile == null || !profile.priceVisibilityEnabled) {
              return const SizedBox.shrink();
            }
            if (p.hasMeasurementPricing && p.measurement != null) {
              return Column(
                children: [
                  MeasurementPriceDisplay(
                    measurement: p.measurement!,
                    selectedUnit:
                        selectedMeasurementUnit ?? p.measurement!.defaultUnit,
                    quantity: qty,
                    productTax: p.tax,
                  ),
                  const SizedBox(height: 12),
                  MeasurementSelector(
                    measurement: p.measurement!,
                    selectedUnit:
                        selectedMeasurementUnit ?? p.measurement!.defaultUnit,
                    onUnitChanged: onMeasurementUnitChanged,
                    productTax: p.tax,
                  ),
                ],
              );
            } else {
              // Standard pricing display
              return Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    '₹${_calculateFinalPrice(price, variant, p).toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              );
            }
          },
        ),
        const SizedBox(height: 12),
        const ShippingEta(),
        if (p.variants.isNotEmpty) ...[
          const SizedBox(height: 16),
          for (final entry in options.entries) ...[
            Text(
              entry.key,
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final val in entry.value)
                  ChoiceChip(
                    label: Text(val),
                    selected: selected[entry.key] == val,
                    onSelected:
                        isValueAvailable(entry.key, val)
                            ? (sel) =>
                                sel
                                    ? onSelect(entry.key, val)
                                    : onUnselect(entry.key)
                            : null,
                  ),
              ],
            ),
            const SizedBox(height: 12),
          ],
        ],
        const SizedBox(height: 16),
        _DetailAddOrQty(
          product: p,
          variant: variant,
          available: !p.isOutOfStock,
          initialQty: qty,
          measurementUnit: selectedMeasurementUnit,
        ),
        const SizedBox(height: 16),
        if (p.description != null) ...[
          Text(
            'Description',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          _buildDescription(p.description!),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () {
              context.push('/compare/select/${p.id}');
            },
            icon: const Icon(Ionicons.git_compare_outline),
            label: const Text('Compare Products'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
            ),
          ),
        ],
        if (p.categories.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(
            'Explore more',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final c in p.categories)
                ActionChip(
                  label: Text(c),
                  onPressed:
                      () => context.pushNamed(
                        'browse',
                        pathParameters: {'kind': 'category', 'value': c},
                      ),
                ),
            ],
          ),
          SizedBox(height: MediaQuery.of(context).size.width >= 900 ? 0 : 8),
          Text(
            'You may also like',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Consumer(
            builder: (context, ref, _) {
              final paginatedData = ref.watch(
                paginatedSuggestedProductsProvider((
                  productId: p.id,
                  page: _suggestedProductsPage,
                )),
              );

              if (paginatedData.totalProducts == 0) {
                return const SizedBox.shrink();
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final width = constraints.maxWidth;
                      // Use unified card widths across all breakpoints
                      final cardWidth = Responsive.getUnifiedProductCardWidth(
                        width,
                      );

                      // Calculate height based on card width and aspect ratio
                      final cardAspectRatio =
                          UniversalProductCard.getCardAspectRatio(
                            width,
                            customCardWidth: cardWidth,
                          );
                      final overflowBuffer =
                          32.0; // Increased buffer for ListView padding and shadows
                      final estimatedCardHeight =
                          (cardWidth / cardAspectRatio) + overflowBuffer;

                      // Use responsive horizontal padding matching Featured Products
                      final horizontalPadding =
                          Responsive.getProductCardSectionPadding(width);

                      return SizedBox(
                        height: estimatedCardHeight,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: EdgeInsets.symmetric(
                            horizontal: horizontalPadding,
                            vertical: 8,
                          ),
                          itemCount: paginatedData.products.length,
                          itemBuilder: (context, i) {
                            final isLast =
                                i == paginatedData.products.length - 1;
                            return Padding(
                              padding: EdgeInsets.only(right: isLast ? 16 : 8),
                              child: SizedBox(
                                width: cardWidth,
                                child: UniversalProductCard(
                                  product: paginatedData.products[i],
                                  cardWidth: cardWidth,
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                  // Pagination controls
                  if (paginatedData.totalPages > 1) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        border: Border(
                          top: BorderSide(
                            color: Theme.of(
                              context,
                            ).colorScheme.outline.withOpacity(0.2),
                          ),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            icon: const Icon(Ionicons.chevron_back_outline),
                            onPressed:
                                _suggestedProductsPage > 1
                                    ? () {
                                      setState(() {
                                        _suggestedProductsPage--;
                                      });
                                    }
                                    : null,
                            tooltip: 'Previous Page',
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              'Page ${paginatedData.currentPage} of ${paginatedData.totalPages}',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(fontWeight: FontWeight.w500),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Ionicons.chevron_forward_outline),
                            onPressed:
                                _suggestedProductsPage <
                                        paginatedData.totalPages
                                    ? () {
                                      setState(() {
                                        _suggestedProductsPage++;
                                      });
                                    }
                                    : null,
                            tooltip: 'Next Page',
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
          // Similar Products section
          Consumer(
            builder: (context, ref, _) {
              final paginatedData = ref.watch(
                paginatedSimilarProductsProvider((
                  productId: p.id,
                  page: _similarProductsPage,
                )),
              );

              if (paginatedData.totalProducts == 0) {
                return const SizedBox.shrink();
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  Text(
                    'Similar Products',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final width = constraints.maxWidth;
                      // Use unified Featured Products card width constraints
                      final cardWidth = Responsive.getUnifiedProductCardWidth(
                        width,
                      );

                      // Calculate estimated card height using unified aspect ratio
                      final cardAspectRatio =
                          UniversalProductCard.getCardAspectRatio(
                            width,
                            customCardWidth: cardWidth,
                          );
                      final overflowBuffer =
                          32.0; // Increased buffer for shadows and padding
                      final estimatedCardHeight =
                          (cardWidth / cardAspectRatio) + overflowBuffer;

                      // Use responsive horizontal padding matching Featured Products
                      final horizontalPadding =
                          Responsive.getProductCardSectionPadding(width);

                      return SizedBox(
                        height: estimatedCardHeight,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: EdgeInsets.symmetric(
                            horizontal: horizontalPadding,
                            vertical: 8,
                          ),
                          itemCount: paginatedData.products.length,
                          itemBuilder: (context, i) {
                            final isLast =
                                i == paginatedData.products.length - 1;
                            return Padding(
                              padding: EdgeInsets.only(right: isLast ? 16 : 8),
                              child: SizedBox(
                                width: cardWidth,
                                child: UniversalProductCard(
                                  product: paginatedData.products[i],
                                  cardWidth: cardWidth,
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                  // Pagination controls
                  if (paginatedData.totalPages > 1) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        border: Border(
                          top: BorderSide(
                            color: Theme.of(
                              context,
                            ).colorScheme.outline.withOpacity(0.2),
                          ),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            icon: const Icon(Ionicons.chevron_back_outline),
                            onPressed:
                                _similarProductsPage > 1
                                    ? () {
                                      setState(() {
                                        _similarProductsPage--;
                                      });
                                    }
                                    : null,
                            tooltip: 'Previous Page',
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              'Page ${paginatedData.currentPage} of ${paginatedData.totalPages}',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(fontWeight: FontWeight.w500),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Ionicons.chevron_forward_outline),
                            onPressed:
                                _similarProductsPage < paginatedData.totalPages
                                    ? () {
                                      setState(() {
                                        _similarProductsPage++;
                                      });
                                    }
                                    : null,
                            tooltip: 'Next Page',
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
        ],
      ],
    );
  }
}

/// Dialog to show all ratings for a product
class _RatingsDialog extends ConsumerWidget {
  final String productId;

  const _RatingsDialog({required this.productId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ratingsFuture = ref
        .read(ratingRepositoryProvider)
        .getProductRatingsWithUsers(productId);

    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Ionicons.star, color: Colors.amber),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Product Ratings',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Ionicons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // Ratings list
            Expanded(
              child: FutureBuilder<List<ProductRatingWithUser>>(
                future: ratingsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError ||
                      !snapshot.hasData ||
                      snapshot.data!.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Ionicons.star_outline,
                            size: 48,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            snapshot.hasError
                                ? 'Error loading ratings'
                                : 'No ratings yet',
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        ],
                      ),
                    );
                  }

                  final ratings = snapshot.data!;
                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: ratings.length,
                    itemBuilder: (context, index) {
                      final ratingWithUser = ratings[index];
                      final rating = ratingWithUser.rating;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    child: Text(
                                      ratingWithUser.userName
                                              ?.substring(0, 1)
                                              .toUpperCase() ??
                                          'U',
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          ratingWithUser.userName ??
                                              ratingWithUser.userEmail ??
                                              'Anonymous',
                                          style: Theme.of(
                                            context,
                                          ).textTheme.titleSmall?.copyWith(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        StarRatingDisplay(
                                          rating: rating.rating.toDouble(),
                                          starSize: 16,
                                          showCount: false,
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    _formatDate(rating.createdAt),
                                    style:
                                        Theme.of(context).textTheme.bodySmall,
                                  ),
                                ],
                              ),
                              if (rating.feedback != null &&
                                  rating.feedback!.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color:
                                        Theme.of(
                                          context,
                                        ).colorScheme.surfaceContainerHighest,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    rating.feedback!,
                                    style:
                                        Theme.of(context).textTheme.bodySmall,
                                    maxLines: 5,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                              // Replies section
                              const SizedBox(height: 12),
                              RatingRepliesSection(
                                ratingId: rating.id,
                                showInput: true,
                                maxInitialReplies: 3,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
