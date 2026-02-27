import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ionicons/ionicons.dart';
import '../../catalog/data/product.dart';
import '../../catalog/data/shared_product_provider.dart';
import '../../catalog/data/sort_option.dart';
import 'widgets/product_grid.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/layout/responsive.dart';
import '../../../core/ui/safe_scaffold.dart';
import '../../../core/ui/view_cart_button.dart';
import '../../../core/router/router_helpers.dart';
import '../../../core/utils/debouncer.dart';
import '../../../features/cart/application/cart_controller.dart';

class BrowseProductsScreen extends ConsumerStatefulWidget {
  final String kind; // tag | category | collection | brand
  final String value;
  const BrowseProductsScreen({
    super.key,
    required this.kind,
    required this.value,
  });

  @override
  ConsumerState<BrowseProductsScreen> createState() =>
      _BrowseProductsScreenState();
}

class _BrowseProductsScreenState extends ConsumerState<BrowseProductsScreen> {
  late String query;
  late SortOption sort;
  late bool inStockOnly;
  late double? minRating;
  final TextEditingController _searchController = TextEditingController();
  final _searchDebouncer = Debouncer(delay: const Duration(milliseconds: 500));
  bool _isInitialized = false;
  bool _isUpdatingUrl = false;

  @override
  void initState() {
    super.initState();
    // Initial values will be set from URL in didChangeDependencies
    query = '';
    sort = SortOption.relevance;
    inStockOnly = false;
    minRating = null;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      _loadFromUrl();
      _isInitialized = true;
    } else if (!_isUpdatingUrl) {
      // Listen for URL changes (browser back/forward, deep links)
      _syncFromUrl();
    }
  }

  void _loadFromUrl() {
    final state = GoRouterState.of(context);
    final qp = state.uri.queryParameters;
    
    final urlQuery = qp['q'] ?? '';
    final urlSort = SortOptionExtension.fromUrlValue(qp['sort']) ?? SortOption.relevance;
    final urlInStock = RouterHelpers.parseBool(qp['inStock']) ?? false;
    
    if (urlQuery != query || urlSort != sort || urlInStock != inStockOnly) {
      setState(() {
        query = urlQuery;
        sort = urlSort;
        inStockOnly = urlInStock;
        _searchController.text = urlQuery;
      });
    }
  }

  void _syncFromUrl() {
    final state = GoRouterState.of(context);
    final qp = state.uri.queryParameters;
    
    final urlQuery = qp['q'] ?? '';
    final urlSort = SortOptionExtension.fromUrlValue(qp['sort']) ?? SortOption.relevance;
    final urlInStock = RouterHelpers.parseBool(qp['inStock']) ?? false;
    final urlMinRating = qp['minRating'] != null ? double.tryParse(qp['minRating']!) : null;
    
    if (urlQuery != query || urlSort != sort || urlInStock != inStockOnly || urlMinRating != minRating) {
      setState(() {
        query = urlQuery;
        sort = urlSort;
        inStockOnly = urlInStock;
        minRating = urlMinRating;
        _searchController.text = urlQuery;
      });
    }
  }

  void _updateUrl({String? query, SortOption? sort, bool? inStock, double? minRating}) {
    if (_isUpdatingUrl) return;
    _isUpdatingUrl = true;
    
    final currentQuery = query ?? this.query;
    final currentSort = sort ?? this.sort;
    final currentInStock = inStock ?? inStockOnly;
    final currentMinRating = minRating ?? this.minRating;
    
    final url = RouterHelpers.buildBrowseUrl(
      widget.kind,
      widget.value,
      query: currentQuery.isEmpty ? null : currentQuery,
      sort: currentSort.urlValue,
      inStock: currentInStock ? true : null,
      minRating: currentMinRating,
    );
    
    context.go(url);
    // Reset flag after navigation completes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _isUpdatingUrl = false;
      }
    });
  }

  @override
  void dispose() {
    _searchDebouncer.dispose();
    _searchController.dispose();
    super.dispose();
  }

  bool _matchKind(Product p) {
    final v = widget.value.toLowerCase();
    switch (widget.kind.toLowerCase()) {
      case 'tag':
        return p.tags.any((t) => t.toLowerCase() == v);
      case 'category':
        return p.categories.any((t) => t.toLowerCase() == v);
      case 'brand':
        return (p.brand ?? '').toLowerCase() == v;
      default:
        return true;
    }
  }

  bool _matchQuery(Product p) {
    if (query.isEmpty) return true;
    final q = query.toLowerCase().trim();
    if (q.isEmpty) return true;
    
    // Search in product name
    if (p.name.toLowerCase().contains(q)) return true;
    
    // Search in subtitle
    if (p.subtitle != null && p.subtitle!.toLowerCase().contains(q)) {
      return true;
    }
    
    // Search in alternative names (with trimming and empty string filtering)
    if (p.alternativeNames.any((name) {
      final trimmedName = name.trim();
      return trimmedName.isNotEmpty && 
             trimmedName.toLowerCase().contains(q);
    })) {
      return true;
    }
    
    return false;
  }

  bool _isInStock(Product p) {
    if (!inStockOnly) return true;
    // Check isOutOfStock flag instead of stock count
    // Show all products except those marked as out of stock by admin
    return !p.isOutOfStock;
  }

  bool _matchRating(Product p) {
    if (minRating == null) return true;
    if (p.averageRating == null) return false;
    return p.averageRating! >= minRating!;
  }

  List<Product> _sort(List<Product> items) {
    switch (sort) {
      case SortOption.priceLowHigh:
        return [...items]..sort((a, b) => a.price.compareTo(b.price));
      case SortOption.priceHighLow:
        return [...items]..sort((a, b) => b.price.compareTo(a.price));
      case SortOption.ratingHighLow:
        return [...items]..sort((a, b) {
          final aRating = a.averageRating ?? 0.0;
          final bRating = b.averageRating ?? 0.0;
          return bRating.compareTo(aRating);
        });
      case SortOption.relevance:
        return items;
    }
  }

  /// Calculates the bottom padding needed for the scroll view to account for
  /// the sticky cart button when it's visible.
  /// Returns 0 if cart is empty (button is hidden), otherwise returns padding
  /// based on breakpoint.
  double _getBottomPaddingForCartButton(BuildContext context, bool hasCartItems) {
    if (!hasCartItems) return 0;
    
    final width = MediaQuery.of(context).size.width;
    final bp = Responsive.breakpointForWidth(width);
    
    // Calculate approximate cart button height based on breakpoint
    // Button height = vertical padding * 2 + row height (icon/text)
    // Icon container: icon size (20-24) + padding (16) = 36-40px
    // Text row: ~20px (compact) or ~34px (medium/expanded)
    // Row height: max(icon, text) = ~36-40px
    // Total: padding (24-32px) + row (36-40px) = ~60-72px
    double buttonHeight;
    double marginBottom;
    
    switch (bp) {
      case AppBreakpoint.compact:
        buttonHeight = 60.0; // 24px padding + 36px content
        marginBottom = 8.0;
        break;
      case AppBreakpoint.medium:
        buttonHeight = 66.0; // 28px padding + 38px content
        marginBottom = 12.0;
        break;
      case AppBreakpoint.expanded:
        buttonHeight = 72.0; // 32px padding + 40px content
        marginBottom = 16.0;
        break;
    }
    
    // Add spacing buffer to ensure content isn't cut off
    const spacing = 16.0;
    
    return buttonHeight + marginBottom + spacing;
  }

  void _openFilters() async {
    final result = await showModalBottomSheet<(SortOption, bool, double?)>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        SortOption tempSort = sort;
        bool tempStock = inStockOnly;
        double? tempMinRating = minRating;
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).padding.bottom + 8,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Ionicons.arrow_back_outline),
                        onPressed: () => Navigator.pop(context, null),
                      ),
                      Expanded(
                        child: Center(
                          child: Container(
                            height: 4,
                            width: 48,
                            decoration: BoxDecoration(
                              color: AppColors.outlineSoft,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 48), // Balance the back button width
                    ],
                  ),
                  const SizedBox(height: 8),
                  Flexible(
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              'Sort by',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ),
                          RadioListTile<SortOption>(
                            dense: true,
                            visualDensity: VisualDensity.compact,
                            title: const Text('Relevance'),
                            value: SortOption.relevance,
                            groupValue: tempSort,
                            onChanged:
                                (v) => setModalState(() => tempSort = v ?? tempSort),
                          ),
                          RadioListTile<SortOption>(
                            dense: true,
                            visualDensity: VisualDensity.compact,
                            title: const Text('Price: Low to High'),
                            value: SortOption.priceLowHigh,
                            groupValue: tempSort,
                            onChanged:
                                (v) => setModalState(() => tempSort = v ?? tempSort),
                          ),
                          RadioListTile<SortOption>(
                            dense: true,
                            visualDensity: VisualDensity.compact,
                            title: const Text('Price: High to Low'),
                            value: SortOption.priceHighLow,
                            groupValue: tempSort,
                            onChanged:
                                (v) => setModalState(() => tempSort = v ?? tempSort),
                          ),
                          RadioListTile<SortOption>(
                            dense: true,
                            visualDensity: VisualDensity.compact,
                            title: const Text('Rating: Highest First'),
                            value: SortOption.ratingHighLow,
                            groupValue: tempSort,
                            onChanged:
                                (v) => setModalState(() => tempSort = v ?? tempSort),
                          ),
                          const Divider(),
                          SwitchListTile(
                            dense: true,
                            visualDensity: VisualDensity.compact,
                            title: const Text('In stock only'),
                            value: tempStock,
                            onChanged: (v) => setModalState(() => tempStock = v),
                          ),
                          const Divider(),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: Text(
                              'Minimum Rating',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ),
                          RadioListTile<double?>(
                            dense: true,
                            visualDensity: VisualDensity.compact,
                            title: const Text('Any Rating'),
                            value: null,
                            groupValue: tempMinRating,
                            onChanged: (v) => setModalState(() => tempMinRating = v),
                          ),
                          RadioListTile<double?>(
                            dense: true,
                            visualDensity: VisualDensity.compact,
                            title: Row(
                              children: [
                                ...List.generate(3, (i) => const Icon(Icons.star, size: 14, color: Colors.amber)),
                                const Text(' 3+ Stars'),
                              ],
                            ),
                            value: 3.0,
                            groupValue: tempMinRating,
                            onChanged: (v) => setModalState(() => tempMinRating = v),
                          ),
                          RadioListTile<double?>(
                            dense: true,
                            visualDensity: VisualDensity.compact,
                            title: Row(
                              children: [
                                ...List.generate(4, (i) => const Icon(Icons.star, size: 14, color: Colors.amber)),
                                const Text(' 4+ Stars'),
                              ],
                            ),
                            value: 4.0,
                            groupValue: tempMinRating,
                            onChanged: (v) => setModalState(() => tempMinRating = v),
                          ),
                          RadioListTile<double?>(
                            dense: true,
                            visualDensity: VisualDensity.compact,
                            title: Row(
                              children: [
                                ...List.generate(5, (i) => const Icon(Icons.star, size: 14, color: Colors.amber)),
                                const Text(' 5 Stars Only'),
                              ],
                            ),
                            value: 5.0,
                            groupValue: tempMinRating,
                            onChanged: (v) => setModalState(() => tempMinRating = v),
                          ),
                          const SizedBox(height: 4),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: FilledButton(
                              onPressed:
                                  () => Navigator.pop(context, (tempSort, tempStock, tempMinRating)),
                              child: const Text('Apply'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            );
          },
        );
      },
    );
    if (result != null) {
      _updateUrl(sort: result.$1, inStock: result.$2, minRating: result.$3);
    }
  }

  @override
  Widget build(BuildContext context) {
    final title =
        '${widget.kind[0].toUpperCase()}${widget.kind.substring(1)}: ${widget.value}';

    // Always use the filtered view with allProductsProvider for proper filter support
    final items = ref.watch(allProductsProvider);
    final width = MediaQuery.of(context).size.width;
    final cardPadding = Responsive.getCardPadding(width);
    
    // Check if cart has items to determine if padding is needed
    final cartItems = ref.watch(cartProvider);
    final hasCartItems = cartItems.values.isNotEmpty;
    final bottomPadding = _getBottomPaddingForCartButton(context, hasCartItems);
    
    return SafeScaffold(
      appBar: AppBar(
        title: Text(title),
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Ionicons.arrow_back_outline),
          onPressed: () {
            // Try to pop first - this works if navigation stack is preserved
            if (context.canPop()) {
              context.pop();
            } else {
              // Fallback: navigate to catalog if stack is broken (e.g., by _updateUrl using context.go())
              // Users browsing products typically came from the catalog/categories screen
              context.go('/catalog');
            }
          },
        ),
      ),
      body: Stack(
        children: [
          Builder(
            builder: (context) {
              var filtered =
                  items
                      .where(_matchKind)
                      .where(_matchQuery)
                      .where(_isInStock)
                      .where(_matchRating)
                      .toList();
              filtered = _sort(filtered);
              return SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  cardPadding,
                  cardPadding,
                  cardPadding,
                  cardPadding + bottomPadding,
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            decoration: const InputDecoration(
                              prefixIcon: Icon(Ionicons.search_outline),
                              hintText: 'Search products',
                            ),
                            onChanged: (v) {
                              // Update local state immediately for responsive UI
                              setState(() => query = v);
                              // Debounce URL update to avoid excessive navigation
                              _searchDebouncer.debounce(() {
                                if (mounted) {
                                  _updateUrl(query: v);
                                }
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        OutlinedButton(
                          onPressed: _openFilters,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            minimumSize: const Size(48, 48),
                          ),
                          child: const Icon(Ionicons.options_outline),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (filtered.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 40),
                        child: Center(child: Text('No products found')),
                      )
                    else
                      ProductGrid(
                        items: filtered,
                        category: widget.kind == 'category' ? widget.value : null,
                      ),
                  ],
                ),
              );
            },
          ),
          // View Cart bottom sheet button
          const ViewCartButton(),
        ],
      ),
    );
  }
}
