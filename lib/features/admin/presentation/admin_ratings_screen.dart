import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ionicons/ionicons.dart';
import '../../../core/ui/safe_scaffold.dart';
import '../../../core/layout/responsive.dart';
import '../../ratings/data/rating_repository.dart';
import '../../ratings/presentation/widgets/star_rating_widget.dart';
import '../../ratings/presentation/widgets/rating_replies_section.dart';
import '../../../core/providers/supabase_provider.dart';
import '../../catalog/data/product_repository.dart';
import '../../catalog/data/product.dart';

class AdminRatingsScreen extends ConsumerStatefulWidget {
  const AdminRatingsScreen({super.key});

  @override
  ConsumerState<AdminRatingsScreen> createState() => _AdminRatingsScreenState();
}

class _AdminRatingsScreenState extends ConsumerState<AdminRatingsScreen> {
  bool _loading = false;
  List<Product> _products = [];
  String _searchQuery = '';
  String? _selectedProductId;
  List<ProductRatingWithUser> _productRatings = [];
  List<ProductRatingWithUser> _allProductRatings = [];

  // Filter states
  int? _selectedRatingFilter; // 1-5 or null for all
  DateTime? _startDate;
  DateTime? _endDate;
  String _userSearchQuery = '';
  final Set<String> _selectedRatingIds = {}; // For bulk delete

  // Pagination states
  int _ratingsCurrentPage = 1;
  bool _ratingsHasMore = true;
  bool _ratingsIsLoadingMore = false;

  @override
  void initState() {
    super.initState();
    // Delay initialization slightly to avoid hot reload issues
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadProducts();
    });
  }

  Future<void> _loadProducts() async {
    if (!mounted) return;

    setState(() => _loading = true);
    try {
      final supabase = ref.read(supabaseClientProvider);

      // Get all ratings with product_id and rating to calculate stats
      final ratingsResponse = await supabase
          .from('product_ratings')
          .select('product_id, rating')
          .order('created_at', ascending: false);

      if (ratingsResponse.isEmpty) {
        if (mounted) {
          setState(() {
            _products = [];
            _loading = false;
          });
        }
        return;
      }

      // Calculate rating stats per product
      final productRatingStats = <String, Map<String, dynamic>>{};
      for (final rating in ratingsResponse) {
        final productId = rating['product_id'] as String?;
        if (productId == null) continue;

        if (!productRatingStats.containsKey(productId)) {
          productRatingStats[productId] = {'count': 0, 'total': 0.0};
        }

        final ratingValue = (rating['rating'] as num?)?.toInt() ?? 0;
        productRatingStats[productId]!['count'] =
            (productRatingStats[productId]!['count'] as int) + 1;
        productRatingStats[productId]!['total'] =
            (productRatingStats[productId]!['total'] as double) + ratingValue;
      }

      // Calculate average ratings
      final productIdsWithRatings = productRatingStats.keys.toSet();

      if (productIdsWithRatings.isEmpty) {
        if (mounted) {
          setState(() {
            _products = [];
            _loading = false;
          });
        }
        return;
      }

      // Fetch products that have ratings
      final productRepository = ref.read(productRepositoryProvider);
      final allProducts = await productRepository.fetchAll();

      // Filter and update products with actual rating data
      final productsWithRatings = <Product>[];
      for (final product in allProducts) {
        if (productIdsWithRatings.contains(product.id)) {
          final stats = productRatingStats[product.id]!;
          final count = stats['count'] as int;
          final total = stats['total'] as double;
          final average = count > 0 ? (total / count) : 0.0;

          // Create updated product with correct rating data
          final updatedProduct = Product(
            id: product.id,
            name: product.name,
            imageUrl: product.imageUrl,
            images: product.images,
            price: product.price,
            subtitle: product.subtitle,
            brand: product.brand,
            sku: product.sku,
            createdAt: product.createdAt,
            updatedAt: product.updatedAt,
            stock: product.stock,
            description: product.description,
            tags: product.tags,
            categories: product.categories,
            variants: product.variants,
            measurement: product.measurement,
            alternativeNames: product.alternativeNames,
            isFeatured: product.isFeatured,
            featuredPosition: product.featuredPosition,
            averageRating: average,
            ratingCount: count,
          );

          productsWithRatings.add(updatedProduct);
        }
      }

      // Sort by average rating (highest first)
      productsWithRatings.sort(
        (a, b) => (b.averageRating ?? 0.0).compareTo(a.averageRating ?? 0.0),
      );

      if (mounted) {
        setState(() {
          _products = productsWithRatings;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading products: ${e.toString()}'),
            action: SnackBarAction(
              label: 'Retry',
              onPressed: () => _loadProducts(),
            ),
          ),
        );
      }
    }
  }

  Future<void> _loadProductRatings(String productId) async {
    try {
      final repository = ref.read(ratingRepositoryProvider);
      final ratings = await repository.getProductRatingsWithUsersPaginated(
        productId,
        page: 1,
        limit: 50,
      );
      final hasMore = ratings.length == 50;
      if (mounted) {
        setState(() {
          _selectedProductId = productId;
          _allProductRatings = ratings;
          _productRatings = _applyFilters(ratings);
          _selectedRatingIds.clear();
          _ratingsCurrentPage = 1;
          _ratingsHasMore = hasMore;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading ratings: ${e.toString()}'),
            action: SnackBarAction(
              label: 'Retry',
              onPressed: () => _loadProductRatings(productId),
            ),
          ),
        );
      }
    }
  }

  Future<void> _loadMoreRatings() async {
    if (_ratingsIsLoadingMore ||
        !_ratingsHasMore ||
        _selectedProductId == null) {
      return;
    }

    setState(() => _ratingsIsLoadingMore = true);

    try {
      final repository = ref.read(ratingRepositoryProvider);
      final nextPage = _ratingsCurrentPage + 1;
      final newRatings = await repository.getProductRatingsWithUsersPaginated(
        _selectedProductId!,
        page: nextPage,
        limit: 50,
      );

      final hasMore = newRatings.length == 50;
      final allRatings = [..._allProductRatings, ...newRatings];

      if (mounted) {
        setState(() {
          _allProductRatings = allRatings;
          _productRatings = _applyFilters(allRatings);
          _ratingsCurrentPage = nextPage;
          _ratingsHasMore = hasMore;
          _ratingsIsLoadingMore = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _ratingsIsLoadingMore = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading more ratings: ${e.toString()}'),
          ),
        );
      }
    }
  }

  List<ProductRatingWithUser> _applyFilters(
    List<ProductRatingWithUser> ratings,
  ) {
    var filtered = ratings;

    // Rating value filter
    if (_selectedRatingFilter != null) {
      filtered =
          filtered
              .where((r) => r.rating.rating == _selectedRatingFilter)
              .toList();
    }

    // Date range filter
    if (_startDate != null) {
      filtered =
          filtered
              .where(
                (r) =>
                    r.rating.createdAt.isAfter(_startDate!) ||
                    r.rating.createdAt.isAtSameMomentAs(_startDate!),
              )
              .toList();
    }
    if (_endDate != null) {
      final endDateWithTime = DateTime(
        _endDate!.year,
        _endDate!.month,
        _endDate!.day,
        23,
        59,
        59,
      );
      filtered =
          filtered
              .where(
                (r) =>
                    r.rating.createdAt.isBefore(endDateWithTime) ||
                    r.rating.createdAt.isAtSameMomentAs(endDateWithTime),
              )
              .toList();
    }

    // User search filter
    if (_userSearchQuery.isNotEmpty) {
      final query = _userSearchQuery.toLowerCase();
      filtered =
          filtered
              .where(
                (r) =>
                    (r.userName?.toLowerCase().contains(query) ?? false) ||
                    (r.userEmail?.toLowerCase().contains(query) ?? false),
              )
              .toList();
    }

    return filtered;
  }

  void _applyFiltersToRatings() {
    setState(() {
      _productRatings = _applyFilters(_allProductRatings);
      _selectedRatingIds.clear();
    });
  }

  Future<void> _deleteRating(String ratingId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Rating'),
            content: const Text('Are you sure you want to delete this rating?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Delete'),
              ),
            ],
          ),
    );

    if (confirmed != true) return;

    try {
      final repository = ref.read(ratingRepositoryProvider);
      await repository.deleteRating(ratingId);

      if (_selectedProductId != null) {
        await _loadProductRatings(_selectedProductId!);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Rating deleted successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error deleting rating: $e')));
      }
    }
  }

  Future<void> _bulkDeleteRatings() async {
    if (_selectedRatingIds.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Ratings'),
            content: Text(
              'Are you sure you want to delete ${_selectedRatingIds.length} rating(s)?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Delete'),
              ),
            ],
          ),
    );

    if (confirmed != true) return;

    try {
      final repository = ref.read(ratingRepositoryProvider);
      int deletedCount = 0;
      int errorCount = 0;

      for (final ratingId in _selectedRatingIds) {
        try {
          await repository.deleteRating(ratingId);
          deletedCount++;
        } catch (e) {
          errorCount++;
        }
      }

      if (_selectedProductId != null) {
        await _loadProductRatings(_selectedProductId!);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              errorCount > 0
                  ? 'Deleted $deletedCount rating(s). $errorCount failed.'
                  : 'Deleted $deletedCount rating(s) successfully',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error deleting ratings: $e')));
      }
    }
  }

  List<Product> get _filteredProducts {
    if (_searchQuery.isEmpty) return _products;
    return _products
        .where(
          (p) =>
              p.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              p.brand?.toLowerCase().contains(_searchQuery.toLowerCase()) ==
                  true,
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final padding = Responsive.getCardPadding(width);
    final spacing = Responsive.getSectionSpacing(width);
    final isMobile = Responsive.isMobile(width);
    final isTablet = Responsive.isTablet(width);
    final isDesktop = Responsive.isDesktop(width);

    return SafeScaffold(
      appBar: AppBar(
        title: const Text('Ratings Management'),
        leading: IconButton(
          icon: const Icon(Ionicons.arrow_back),
          onPressed: () {
            // Check for previousRoute query parameter
            final state = GoRouterState.of(context);
            final previousRoute = state.uri.queryParameters['previousRoute'];

            if (previousRoute != null && previousRoute.isNotEmpty) {
              // Navigate to the previous route from query parameter
              context.go(previousRoute);
            } else if (Navigator.of(context).canPop()) {
              // Try to pop if there's a navigation stack
              context.pop();
            } else {
              // Fallback to admin more screen if no previous route
              context.go('/admin/more');
            }
          },
        ),
      ),
      body:
          _loading
              ? const Center(child: CircularProgressIndicator())
              : isMobile
              ? _buildMobileLayout(context, width, padding, spacing)
              : _buildDesktopLayout(context, width, padding, spacing),
    );
  }

  Widget _buildMobileLayout(
    BuildContext context,
    double width,
    double padding,
    double spacing,
  ) {
    if (_selectedProductId == null) {
      // Show products list
      return Column(
        children: [
          Padding(
            padding: EdgeInsets.all(padding),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search products...',
                prefixIcon: const Icon(Ionicons.search_outline),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
              ),
              onChanged: (value) {
                setState(() => _searchQuery = value);
              },
            ),
          ),
          Expanded(
            child:
                _filteredProducts.isEmpty
                    ? Center(
                      child: Text(
                        _searchQuery.isEmpty
                            ? 'No products with ratings'
                            : 'No products found',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    )
                    : ListView.builder(
                      padding: EdgeInsets.all(padding),
                      itemCount: _filteredProducts.length,
                      itemBuilder: (context, index) {
                        final product = _filteredProducts[index];
                        return _buildProductCard(
                          context,
                          product,
                          padding,
                          spacing,
                          false,
                        );
                      },
                    ),
          ),
        ],
      );
    } else {
      // Show ratings for selected product
      return Column(
        children: [
          _buildProductHeader(context, padding),
          _buildFiltersSection(context, padding, spacing, false),
          Expanded(child: _buildRatingsList(context, padding, spacing)),
        ],
      );
    }
  }

  Widget _buildDesktopLayout(
    BuildContext context,
    double width,
    double padding,
    double spacing,
  ) {
    return Row(
      children: [
        // Products list
        Expanded(
          flex: width < 1024 ? 3 : 2,
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                right: BorderSide(
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                ),
              ),
            ),
            child: Column(
              children: [
                // Search bar
                Padding(
                  padding: EdgeInsets.all(padding),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search products...',
                      prefixIcon: const Icon(Ionicons.search_outline),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Theme.of(context).colorScheme.surface,
                    ),
                    onChanged: (value) {
                      setState(() => _searchQuery = value);
                    },
                  ),
                ),
                // Products list
                Expanded(
                  child:
                      _filteredProducts.isEmpty
                          ? Center(
                            child: Text(
                              _searchQuery.isEmpty
                                  ? 'No products with ratings'
                                  : 'No products found',
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                          )
                          : ListView.builder(
                            padding: EdgeInsets.symmetric(horizontal: padding),
                            itemCount: _filteredProducts.length,
                            itemBuilder: (context, index) {
                              final product = _filteredProducts[index];
                              return _buildProductCard(
                                context,
                                product,
                                padding,
                                spacing,
                                true,
                              );
                            },
                          ),
                ),
              ],
            ),
          ),
        ),
        // Ratings detail
        Expanded(
          flex: width < 1024 ? 4 : 3,
          child:
              _selectedProductId == null
                  ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Ionicons.star_outline,
                          size: 64,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Select a product to view ratings',
                          style: Theme.of(context).textTheme.titleMedium,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                  : Column(
                    children: [
                      _buildProductHeader(context, padding),
                      _buildFiltersSection(context, padding, spacing, true),
                      Expanded(
                        child: _buildRatingsList(context, padding, spacing),
                      ),
                    ],
                  ),
        ),
      ],
    );
  }

  Widget _buildProductCard(
    BuildContext context,
    Product product,
    double padding,
    double spacing,
    bool isDesktop,
  ) {
    final isSelected = _selectedProductId == product.id;
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      margin: EdgeInsets.only(
        bottom: spacing * 0.5,
        left: isDesktop ? 0 : padding,
        right: isDesktop ? 0 : padding,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color:
              isSelected
                  ? theme.colorScheme.primary
                  : theme.dividerColor.withOpacity(0.1),
          width: isSelected ? 2 : 1,
        ),
      ),
      color:
          isSelected
              ? theme.colorScheme.primaryContainer.withOpacity(0.1)
              : null,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _showRateLimitingModal(product),
        child: Padding(
          padding: EdgeInsets.all(isDesktop ? 12 : 16),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  color: theme.colorScheme.surfaceContainerHighest,
                  child: Image.network(
                    product.imageUrl,
                    width: isDesktop ? 64 : 72,
                    height: isDesktop ? 64 : 72,
                    fit: BoxFit.cover,
                    errorBuilder:
                        (context, error, stackTrace) => Container(
                          width: isDesktop ? 64 : 72,
                          height: isDesktop ? 64 : 72,
                          child: Icon(
                            Ionicons.image_outline,
                            size: isDesktop ? 24 : 28,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      product.name,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: isDesktop ? 13 : 15,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        StarRatingDisplay(
                          rating: product.averageRating ?? 0.0,
                          ratingCount: product.ratingCount,
                          starSize: 14,
                          showCount: false,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          (product.averageRating ?? 0.0).toStringAsFixed(1),
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${product.ratingCount} rating${product.ratingCount != 1 ? 's' : ''}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (!isDesktop)
                Icon(
                  Ionicons.chevron_forward_outline,
                  size: 20,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductHeader(BuildContext context, double padding) {
    final product = _products.firstWhere(
      (p) => p.id == _selectedProductId,
      orElse:
          () =>
              _products.isNotEmpty
                  ? _products.first
                  : Product(
                    id: '',
                    name: 'Product',
                    imageUrl: '',
                    images: const [],
                    price: 0,
                  ),
    );

    return Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
          ),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Ionicons.close),
            onPressed: () {
              setState(() {
                _selectedProductId = null;
                _productRatings = [];
                _selectedRatingIds.clear();
              });
            },
            tooltip: 'Close',
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '${_productRatings.length} rating${_productRatings.length != 1 ? 's' : ''}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFiltersSection(
    BuildContext context,
    double padding,
    double spacing,
    bool isDesktop,
  ) {
    final hasActiveFilters =
        _selectedProductId != null ||
        _selectedRatingFilter != null ||
        _startDate != null ||
        _endDate != null ||
        _userSearchQuery.isNotEmpty;

    return Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Active filter chips
          if (hasActiveFilters) ...[
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (_selectedProductId != null)
                  _buildFilterChip(
                    context,
                    label:
                        _products
                            .firstWhere(
                              (p) => p.id == _selectedProductId,
                              orElse:
                                  () =>
                                      _products.isNotEmpty
                                          ? _products.first
                                          : Product(
                                            id: '',
                                            name: 'Product',
                                            imageUrl: '',
                                            images: const [],
                                            price: 0,
                                          ),
                            )
                            .name,
                    count: _productRatings.length,
                    onDismiss: () {
                      setState(() {
                        _selectedProductId = null;
                        _productRatings = [];
                        _selectedRatingIds.clear();
                      });
                    },
                  ),
                if (_selectedRatingFilter != null)
                  _buildFilterChip(
                    context,
                    label:
                        '$_selectedRatingFilter star${_selectedRatingFilter! > 1 ? 's' : ''}',
                    onDismiss: () {
                      setState(() {
                        _selectedRatingFilter = null;
                        _applyFiltersToRatings();
                      });
                    },
                  ),
                if (_startDate != null && _endDate != null)
                  _buildFilterChip(
                    context,
                    label:
                        '${_formatDate(_startDate!)} - ${_formatDate(_endDate!)}',
                    onDismiss: () {
                      setState(() {
                        _startDate = null;
                        _endDate = null;
                        _applyFiltersToRatings();
                      });
                    },
                  ),
                if (_userSearchQuery.isNotEmpty)
                  _buildFilterChip(
                    context,
                    label: 'User: $_userSearchQuery',
                    onDismiss: () {
                      setState(() {
                        _userSearchQuery = '';
                        _applyFiltersToRatings();
                      });
                    },
                  ),
              ],
            ),
            const SizedBox(height: 12),
          ],
          // Filter controls
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                // Rating filter
                DropdownButton<int>(
                  value: _selectedRatingFilter,
                  hint: const Text('Rating'),
                  items:
                      [1, 2, 3, 4, 5].map((rating) {
                          return DropdownMenuItem<int>(
                            value: rating,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                StarRatingDisplay(
                                  rating: rating.toDouble(),
                                  starSize: 14,
                                  showCount: false,
                                ),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    '$rating star${rating > 1 ? 's' : ''}',
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList()
                        ..insert(
                          0,
                          const DropdownMenuItem<int>(
                            value: null,
                            child: Text('All Ratings'),
                          ),
                        ),
                  onChanged: (value) {
                    setState(() {
                      _selectedRatingFilter = value;
                      _applyFiltersToRatings();
                    });
                  },
                ),
                const SizedBox(width: 12),
                // Date range filter
                OutlinedButton.icon(
                  onPressed: () async {
                    final DateTimeRange? picked = await showDateRangePicker(
                      context: context,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) {
                      setState(() {
                        _startDate = picked.start;
                        _endDate = picked.end;
                        _applyFiltersToRatings();
                      });
                    }
                  },
                  icon: const Icon(Ionicons.calendar_outline, size: 16),
                  label: Text(
                    _startDate != null && _endDate != null
                        ? '${_formatDate(_startDate!)} - ${_formatDate(_endDate!)}'
                        : 'Date Range',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 12),
                // User search
                SizedBox(
                  width: isDesktop ? 200 : 150,
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search user...',
                      prefixIcon: const Icon(Ionicons.person_outline, size: 18),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _userSearchQuery = value;
                        _applyFiltersToRatings();
                      });
                    },
                  ),
                ),
                if (_selectedRatingIds.isNotEmpty) ...[
                  const SizedBox(width: 12),
                  OutlinedButton.icon(
                    onPressed: _bulkDeleteRatings,
                    icon: const Icon(Ionicons.trash_outline, size: 16),
                    label: Text(
                      'Delete (${_selectedRatingIds.length})',
                      overflow: TextOverflow.ellipsis,
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(
    BuildContext context, {
    required String label,
    int? count,
    required VoidCallback onDismiss,
  }) {
    return Chip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(label, overflow: TextOverflow.ellipsis, maxLines: 1),
          ),
          if (count != null) ...[
            const SizedBox(width: 4),
            Text(
              '$count rating${count != 1 ? 's' : ''}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ],
      ),
      onDeleted: onDismiss,
      deleteIcon: const Icon(Ionicons.close_circle, size: 18),
      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
    );
  }

  Widget _buildRatingsList(
    BuildContext context,
    double padding,
    double spacing,
  ) {
    if (_productRatings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Ionicons.filter_outline,
              size: 48,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'No ratings match the filters',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(padding),
      itemCount: _productRatings.length + (_ratingsHasMore ? 1 : 0),
      itemBuilder: (context, index) {
        // Show load more button at the end
        if (index == _productRatings.length) {
          return Padding(
            padding: EdgeInsets.only(top: padding),
            child:
                _ratingsIsLoadingMore
                    ? const Center(child: CircularProgressIndicator())
                    : OutlinedButton.icon(
                      onPressed: _loadMoreRatings,
                      icon: const Icon(Ionicons.refresh_outline),
                      label: const Text('Load More'),
                    ),
          );
        }

        final ratingWithUser = _productRatings[index];
        final rating = ratingWithUser.rating;
        final isSelected = _selectedRatingIds.contains(rating.id);

        return Card(
          margin: EdgeInsets.only(bottom: spacing * 0.5),
          elevation: isSelected ? 2 : 0,
          color:
              isSelected
                  ? Theme.of(
                    context,
                  ).colorScheme.primaryContainer.withOpacity(0.3)
                  : null,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side:
                isSelected
                    ? BorderSide(
                      color: Theme.of(context).colorScheme.primary,
                      width: 1,
                    )
                    : BorderSide.none,
          ),
          child: Padding(
            padding: EdgeInsets.all(padding * 0.75),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Checkbox
                Checkbox(
                  value: isSelected,
                  onChanged: (value) {
                    setState(() {
                      if (value == true) {
                        _selectedRatingIds.add(rating.id);
                      } else {
                        _selectedRatingIds.remove(rating.id);
                      }
                    });
                  },
                ),
                const SizedBox(width: 8),
                // Avatar
                CircleAvatar(
                  radius: 20,
                  child: Text(
                    (ratingWithUser.userName?.substring(0, 1).toUpperCase() ??
                        ratingWithUser.userEmail
                            ?.substring(0, 1)
                            .toUpperCase() ??
                        'U'),
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
                const SizedBox(width: 12),
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // User name
                      Text(
                        ratingWithUser.userName ??
                            ratingWithUser.userEmail ??
                            'Anonymous',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      // Star rating
                      StarRatingDisplay(
                        rating: rating.rating.toDouble(),
                        starSize: 16,
                        showCount: false,
                      ),
                      // Feedback
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
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            rating.feedback!,
                            style: Theme.of(context).textTheme.bodySmall,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                      const SizedBox(height: 4),
                      // Date
                      Text(
                        'Rated on ${_formatDate(rating.createdAt)}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Delete button
                IconButton(
                  icon: const Icon(Ionicons.trash_outline, color: Colors.red),
                  onPressed: () => _deleteRating(rating.id),
                  tooltip: 'Delete rating',
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  // Rate limiting information data class
  Future<Map<String, dynamic>> _getRateLimitingInfo(String productId) async {
    try {
      final repository = ref.read(ratingRepositoryProvider);
      final ratings = await repository.getProductRatingsWithUsers(productId);

      // Get unique user IDs
      final uniqueUserIds = ratings.map((r) => r.rating.userId).toSet();
      final uniqueRatersCount = uniqueUserIds.length;
      final totalRatingsCount = ratings.length;

      // Calculate average rating
      final averageRating =
          ratings.isEmpty
              ? 0.0
              : ratings.map((r) => r.rating.rating).reduce((a, b) => a + b) /
                  ratings.length;

      // Check if users can rate multiple times (if total > unique, some users rated multiple times)
      final canRateMultipleTimes = totalRatingsCount > uniqueRatersCount;
      final multipleRatersCount = totalRatingsCount - uniqueRatersCount;

      // Get member list with details
      final membersList =
          ratings.map((ratingWithUser) {
            return {
              'ratingId': ratingWithUser.rating.id,
              'userId': ratingWithUser.rating.userId,
              'userName': ratingWithUser.userName ?? 'Anonymous',
              'userEmail': ratingWithUser.userEmail ?? 'No email',
              'rating': ratingWithUser.rating.rating,
              'feedback': ratingWithUser.rating.feedback,
              'createdAt': ratingWithUser.rating.createdAt,
              'orderId': ratingWithUser.rating.orderId,
            };
          }).toList();

      // Sort by date (newest first)
      membersList.sort(
        (a, b) =>
            (b['createdAt'] as DateTime).compareTo(a['createdAt'] as DateTime),
      );

      return {
        'uniqueRatersCount': uniqueRatersCount,
        'totalRatingsCount': totalRatingsCount,
        'averageRating': averageRating,
        'canRateMultipleTimes': canRateMultipleTimes,
        'multipleRatersCount': multipleRatersCount,
        'membersList': membersList,
      };
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading rate limiting info: ${e.toString()}'),
          ),
        );
      }
      return {
        'uniqueRatersCount': 0,
        'totalRatingsCount': 0,
        'averageRating': 0.0,
        'canRateMultipleTimes': false,
        'multipleRatersCount': 0,
        'membersList': <Map<String, dynamic>>[],
      };
    }
  }

  Future<void> _showRateLimitingModal(Product product) async {
    // Show loading dialog first
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    final rateLimitingInfo = await _getRateLimitingInfo(product.id);

    if (!mounted) return;

    // Close loading dialog
    Navigator.of(context).pop();

    // Show rate limiting modal
    if (!mounted) return;

    showDialog(
      context: context,
      builder:
          (context) => _RateLimitingModal(
            product: product,
            initialRateLimitingInfo: rateLimitingInfo,
            onRefresh: () async {
              return await _getRateLimitingInfo(product.id);
            },
            onDeleteRating: (ratingId) async {
              await _deleteRating(ratingId);
              // Reload products to update rating counts
              await _loadProducts();
            },
          ),
    );
  }

  Widget _buildStatisticsSection(
    BuildContext context,
    Map<String, dynamic> info,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Statistics',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    context,
                    'Unique Raters',
                    '${info['uniqueRatersCount']}',
                    Ionicons.people_outline,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    context,
                    'Total Ratings',
                    '${info['totalRatingsCount']}',
                    Ionicons.star_outline,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    context,
                    'Average Rating',
                    (info['averageRating'] as double).toStringAsFixed(1),
                    Ionicons.star,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildRateLimitingStatus(
    BuildContext context,
    Map<String, dynamic> info,
  ) {
    final canRateMultipleTimes = info['canRateMultipleTimes'] as bool;
    final multipleRatersCount = info['multipleRatersCount'] as int;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Ionicons.shield_checkmark_outline,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Rate Limiting Status',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color:
                    canRateMultipleTimes
                        ? Theme.of(
                          context,
                        ).colorScheme.errorContainer.withOpacity(0.3)
                        : Theme.of(
                          context,
                        ).colorScheme.primaryContainer.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color:
                      canRateMultipleTimes
                          ? Theme.of(context).colorScheme.error
                          : Theme.of(context).colorScheme.primary,
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    canRateMultipleTimes
                        ? Ionicons.warning_outline
                        : Ionicons.checkmark_circle_outline,
                    color:
                        canRateMultipleTimes
                            ? Theme.of(context).colorScheme.error
                            : Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          canRateMultipleTimes
                              ? 'Multiple Ratings Detected'
                              : 'Single Rating Per User',
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          canRateMultipleTimes
                              ? '$multipleRatersCount user(s) have rated this product multiple times. Rate limiting may not be properly enforced.'
                              : 'Each user can rate this product only once. Rate limiting is properly enforced.',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Rate Limiting Rules:',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            _buildRuleItem(
              context,
              'Users can only rate products from purchased orders',
            ),
            _buildRuleItem(context, 'One rating per user per product'),
            _buildRuleItem(
              context,
              'Ratings can be updated but not duplicated',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRuleItem(BuildContext context, String rule) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            Ionicons.checkmark_circle,
            size: 16,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(rule, style: Theme.of(context).textTheme.bodySmall),
          ),
        ],
      ),
    );
  }

  Widget _buildMembersList(
    BuildContext context,
    List<Map<String, dynamic>> membersList,
    String productId,
    Function(String) onDeleteRating,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Ionicons.people_outline,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Members Who Rated (${membersList.length})',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (membersList.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Icon(
                        Ionicons.people_outline,
                        size: 48,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No members have rated this product yet',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: membersList.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final member = membersList[index];
                  final ratingId = member['ratingId'] as String;
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    leading: CircleAvatar(
                      child: Text(
                        (member['userName'] as String)
                            .substring(0, 1)
                            .toUpperCase(),
                      ),
                    ),
                    title: Text(
                      member['userName'] as String,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          member['userEmail'] as String,
                          style: Theme.of(context).textTheme.bodySmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        StarRatingDisplay(
                          rating: (member['rating'] as int).toDouble(),
                          starSize: 14,
                          showCount: false,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Rated on ${_formatDate(member['createdAt'] as DateTime)}',
                          style: Theme.of(
                            context,
                          ).textTheme.bodySmall?.copyWith(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (member['feedback'] != null &&
                            (member['feedback'] as String).isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: Icon(
                              Ionicons.chatbubble_outline,
                              size: 20,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        IconButton(
                          icon: const Icon(
                            Ionicons.trash_outline,
                            color: Colors.red,
                            size: 20,
                          ),
                          onPressed: () => onDeleteRating(ratingId),
                          tooltip: 'Delete rating',
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

// Stateful widget for the rate limiting modal
class _RateLimitingModal extends ConsumerStatefulWidget {
  final Product product;
  final Map<String, dynamic> initialRateLimitingInfo;
  final Future<Map<String, dynamic>> Function() onRefresh;
  final Future<void> Function(String) onDeleteRating;

  const _RateLimitingModal({
    required this.product,
    required this.initialRateLimitingInfo,
    required this.onRefresh,
    required this.onDeleteRating,
  });

  @override
  ConsumerState<_RateLimitingModal> createState() => _RateLimitingModalState();
}

class _RateLimitingModalState extends ConsumerState<_RateLimitingModal> {
  late Map<String, dynamic> _rateLimitingInfo;
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    _rateLimitingInfo = widget.initialRateLimitingInfo;
  }

  Future<void> _handleDeleteRating(String ratingId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Rating'),
            content: const Text(
              'Are you sure you want to delete this rating? This action cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Delete'),
              ),
            ],
          ),
    );

    if (confirmed != true) return;

    setState(() => _isDeleting = true);

    try {
      await widget.onDeleteRating(ratingId);

      // Refresh modal data
      final updatedInfo = await widget.onRefresh();
      if (mounted) {
        setState(() {
          _rateLimitingInfo = updatedInfo;
          _isDeleting = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isDeleting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting rating: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      widget.product.imageUrl,
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                      errorBuilder:
                          (context, error, stackTrace) => Container(
                            width: 60,
                            height: 60,
                            color: Colors.grey.shade200,
                            child: const Icon(Ionicons.image_outline),
                          ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.product.name,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        StarRatingDisplay(
                          rating: widget.product.averageRating ?? 0.0,
                          ratingCount: widget.product.ratingCount,
                          starSize: 16,
                          showCount: true,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Ionicons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            // Content
            Expanded(
              child:
                  _isDeleting
                      ? const Center(child: CircularProgressIndicator())
                      : SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Statistics Section
                            _buildStatisticsSection(context, _rateLimitingInfo),
                            const SizedBox(height: 24),
                            // Rate Limiting Status
                            _buildRateLimitingStatus(
                              context,
                              _rateLimitingInfo,
                            ),
                            const SizedBox(height: 24),
                            // Members List
                            _buildMembersList(
                              context,
                              _rateLimitingInfo['membersList']
                                  as List<Map<String, dynamic>>,
                              widget.product.id,
                              _handleDeleteRating,
                            ),
                          ],
                        ),
                      ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatisticsSection(
    BuildContext context,
    Map<String, dynamic> info,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Statistics',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    context,
                    'Unique Raters',
                    '${info['uniqueRatersCount']}',
                    Ionicons.people_outline,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    context,
                    'Total Ratings',
                    '${info['totalRatingsCount']}',
                    Ionicons.star_outline,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    context,
                    'Average Rating',
                    (info['averageRating'] as double).toStringAsFixed(1),
                    Ionicons.star,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildRateLimitingStatus(
    BuildContext context,
    Map<String, dynamic> info,
  ) {
    final canRateMultipleTimes = info['canRateMultipleTimes'] as bool;
    final multipleRatersCount = info['multipleRatersCount'] as int;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Ionicons.shield_checkmark_outline,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Rate Limiting Status',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color:
                    canRateMultipleTimes
                        ? Theme.of(
                          context,
                        ).colorScheme.errorContainer.withOpacity(0.3)
                        : Theme.of(
                          context,
                        ).colorScheme.primaryContainer.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color:
                      canRateMultipleTimes
                          ? Theme.of(context).colorScheme.error
                          : Theme.of(context).colorScheme.primary,
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    canRateMultipleTimes
                        ? Ionicons.warning_outline
                        : Ionicons.checkmark_circle_outline,
                    color:
                        canRateMultipleTimes
                            ? Theme.of(context).colorScheme.error
                            : Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          canRateMultipleTimes
                              ? 'Multiple Ratings Detected'
                              : 'Single Rating Per User',
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          canRateMultipleTimes
                              ? '$multipleRatersCount user(s) have rated this product multiple times. Rate limiting may not be properly enforced.'
                              : 'Each user can rate this product only once. Rate limiting is properly enforced.',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Rate Limiting Rules:',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            _buildRuleItem(
              context,
              'Users can only rate products from purchased orders',
            ),
            _buildRuleItem(context, 'One rating per user per product'),
            _buildRuleItem(
              context,
              'Ratings can be updated but not duplicated',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRuleItem(BuildContext context, String rule) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            Ionicons.checkmark_circle,
            size: 16,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(rule, style: Theme.of(context).textTheme.bodySmall),
          ),
        ],
      ),
    );
  }

  Widget _buildMembersList(
    BuildContext context,
    List<Map<String, dynamic>> membersList,
    String productId,
    Function(String) onDeleteRating,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Ionicons.people_outline,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Members Who Rated (${membersList.length})',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (membersList.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Icon(
                        Ionicons.people_outline,
                        size: 48,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No members have rated this product yet',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: membersList.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final member = membersList[index];
                  final ratingId = member['ratingId'] as String;
                  return _MemberRatingCard(
                    member: member,
                    ratingId: ratingId,
                    onDeleteRating: onDeleteRating,
                  );
                },
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

/// Widget for displaying a member rating with expandable replies
class _MemberRatingCard extends ConsumerStatefulWidget {
  final Map<String, dynamic> member;
  final String ratingId;
  final Function(String) onDeleteRating;

  const _MemberRatingCard({
    required this.member,
    required this.ratingId,
    required this.onDeleteRating,
  });

  @override
  ConsumerState<_MemberRatingCard> createState() => _MemberRatingCardState();
}

class _MemberRatingCardState extends ConsumerState<_MemberRatingCard> {
  bool _isExpanded = false;
  int _replyCount = 0;
  bool _isLoadingReplyCount = true;

  @override
  void initState() {
    super.initState();
    _loadReplyCount();
  }

  Future<void> _loadReplyCount() async {
    try {
      final repository = ref.read(ratingRepositoryProvider);
      final count = await repository.getReplyCount(widget.ratingId);
      if (mounted) {
        setState(() {
          _replyCount = count;
          _isLoadingReplyCount = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingReplyCount = false);
      }
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isMobile = Responsive.isMobile(width);
    final padding = Responsive.getCardPadding(width) * 0.75;

    return Column(
      children: [
        Padding(
          padding: EdgeInsets.all(padding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // User info row
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    child: Text(
                      (widget.member['userName'] as String)
                          .substring(0, 1)
                          .toUpperCase(),
                    ),
                  ),
                  SizedBox(width: padding * 0.75),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.member['userName'] as String,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.member['userEmail'] as String,
                          style: Theme.of(context).textTheme.bodySmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        StarRatingDisplay(
                          rating: (widget.member['rating'] as int).toDouble(),
                          starSize: 14,
                          showCount: false,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Rated on ${_formatDate(widget.member['createdAt'] as DateTime)}',
                          style: Theme.of(
                            context,
                          ).textTheme.bodySmall?.copyWith(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              // Feedback text
              if (widget.member['feedback'] != null &&
                  (widget.member['feedback'] as String).isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: EdgeInsets.all(padding * 0.75),
                  decoration: BoxDecoration(
                    color:
                        Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    widget.member['feedback'] as String,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
              // Action buttons below feedback
              const SizedBox(height: 12),
              Row(
                children: [
                  // Reply count badge and expand button
                  if (!_isLoadingReplyCount && _replyCount > 0)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Chip(
                        label: Text('$_replyCount'),
                        avatar: const Icon(
                          Ionicons.chatbubble_outline,
                          size: 16,
                        ),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                  // Expand/collapse button
                  TextButton.icon(
                    onPressed: () {
                      setState(() => _isExpanded = !_isExpanded);
                    },
                    icon: Icon(
                      _isExpanded ? Ionicons.chevron_up : Ionicons.chevron_down,
                      size: 16,
                    ),
                    label: Text(_isExpanded ? 'Hide replies' : 'Show replies'),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.symmetric(
                        horizontal: padding * 0.5,
                        vertical: padding * 0.25,
                      ),
                    ),
                  ),
                  const Spacer(),
                  // Delete button
                  IconButton(
                    icon: const Icon(
                      Ionicons.trash_outline,
                      color: Colors.red,
                      size: 20,
                    ),
                    onPressed: () => widget.onDeleteRating(widget.ratingId),
                    tooltip: 'Delete rating',
                  ),
                ],
              ),
            ],
          ),
        ),
        // Replies section
        if (_isExpanded)
          Padding(
            padding: EdgeInsets.symmetric(horizontal: padding),
            child: RatingRepliesSection(
              ratingId: widget.ratingId,
              showInput: true,
              onReplyAdded: _loadReplyCount,
            ),
          ),
      ],
    );
  }
}
