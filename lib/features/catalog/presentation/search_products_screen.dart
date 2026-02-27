import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ionicons/ionicons.dart';
import 'package:go_router/go_router.dart';
import '../../catalog/data/shared_product_provider.dart';
import '../../catalog/data/sort_option.dart';
import 'widgets/responsive_product_grid.dart';
import '../../../core/ui/safe_scaffold.dart';
import '../../../core/layout/responsive.dart';
import '../../../core/router/router_helpers.dart';
import '../../../core/navigation/navigation_helper.dart';
import '../../../core/theme/app_colors.dart';
import '../../search/data/search_results_repository.dart';
import '../../auth/application/auth_controller.dart';

class SearchProductsScreen extends ConsumerStatefulWidget {
  const SearchProductsScreen({super.key});

  @override
  ConsumerState<SearchProductsScreen> createState() =>
      _SearchProductsScreenState();
}

class _SearchProductsScreenState extends ConsumerState<SearchProductsScreen> {
  late String query;
  String _searchText = '';
  final _controller = TextEditingController();
  bool _isInitialized = false;
  bool _isUpdatingUrl = false;
  String? _lastLoggedQuery; // Track last logged query to avoid duplicates
  
  // Filter state
  SortOption _sort = SortOption.relevance;
  double? _minPrice;
  double? _maxPrice;
  List<String> _selectedCategories = [];
  List<String> _selectedBrands = [];
  bool _inStockOnly = false;
  double? _minRating;

  @override
  void initState() {
    super.initState();
    query = '';
    _searchText = '';
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Defer accessing router state until after the frame is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      
      if (!_isInitialized) {
        _loadFromUrl();
        _isInitialized = true;
      } else if (!_isUpdatingUrl) {
        // Listen for URL changes (browser back/forward, deep links)
        _syncFromUrl();
      }
    });
  }

  void _loadFromUrl() {
    try {
      final state = GoRouterState.of(context);
      final qp = state.uri.queryParameters;
      final urlQuery = qp['q'] ?? '';
      
      // Parse filter parameters
      final urlSort = SortOptionExtension.fromUrlValue(qp['sort']) ?? SortOption.relevance;
      final urlMinPrice = RouterHelpers.parseDouble(qp['minPrice']);
      final urlMaxPrice = RouterHelpers.parseDouble(qp['maxPrice']);
      final urlCategories = RouterHelpers.parseStringList(qp['categories']) ?? [];
      final urlBrands = RouterHelpers.parseStringList(qp['brands']) ?? [];
      final urlInStock = RouterHelpers.parseBool(qp['inStock']) ?? false;
      final urlMinRating = RouterHelpers.parseDouble(qp['minRating']);

      if (mounted) {
        setState(() {
          query = urlQuery;
          _searchText = urlQuery;
          _controller.text = urlQuery;
          _sort = urlSort;
          _minPrice = urlMinPrice;
          _maxPrice = urlMaxPrice;
          _selectedCategories = urlCategories;
          _selectedBrands = urlBrands;
          _inStockOnly = urlInStock;
          _minRating = urlMinRating;
        });
      }
    } catch (e) {
      // Router state not available yet, ensure lists are initialized
      if (mounted) {
        setState(() {
          _selectedCategories = _selectedCategories;
          _selectedBrands = _selectedBrands;
        });
      }
    }
  }

  void _syncFromUrl() {
    if (!mounted) return;
    try {
      final state = GoRouterState.of(context);
      final qp = state.uri.queryParameters;
      final urlQuery = qp['q'] ?? '';
      
      // Parse filter parameters
      final urlSort = SortOptionExtension.fromUrlValue(qp['sort']) ?? SortOption.relevance;
      final urlMinPrice = RouterHelpers.parseDouble(qp['minPrice']);
      final urlMaxPrice = RouterHelpers.parseDouble(qp['maxPrice']);
      final urlCategories = RouterHelpers.parseStringList(qp['categories']) ?? [];
      final urlBrands = RouterHelpers.parseStringList(qp['brands']) ?? [];
      final urlInStock = RouterHelpers.parseBool(qp['inStock']) ?? false;
      final urlMinRating = RouterHelpers.parseDouble(qp['minRating']);

      if (mounted) {
        setState(() {
          query = urlQuery;
          _searchText = urlQuery;
          _controller.text = urlQuery;
          _sort = urlSort;
          _minPrice = urlMinPrice;
          _maxPrice = urlMaxPrice;
          _selectedCategories = urlCategories;
          _selectedBrands = urlBrands;
          _inStockOnly = urlInStock;
          _minRating = urlMinRating;
        });
      }
    } catch (e) {
      // Router state not available yet, ensure lists are initialized
      if (mounted) {
        setState(() {
          _selectedCategories = _selectedCategories;
          _selectedBrands = _selectedBrands;
        });
      }
    }
  }

  void _updateUrl({String? newQuery}) {
    if (_isUpdatingUrl) return;
    _isUpdatingUrl = true;

    final url = RouterHelpers.buildSearchUrl(
      (newQuery ?? query).isEmpty ? null : (newQuery ?? query),
      sort: _sort.urlValue,
      minPrice: _minPrice,
      maxPrice: _maxPrice,
      categories: (_selectedCategories.isEmpty) ? null : _selectedCategories,
      brands: (_selectedBrands.isEmpty) ? null : _selectedBrands,
      inStock: _inStockOnly ? true : null,
      minRating: _minRating,
    );
    context.go(url);
    // Reset flag after navigation completes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _isUpdatingUrl = false;
      }
    });
  }
  
  void _updateFilters() {
    _updateUrl();
  }

  void _performSearch() {
    final currentQuery = _controller.text.trim();
    setState(() {
      query = currentQuery;
      _searchText = currentQuery;
      // Reset logged query when performing new search
      if (_lastLoggedQuery != currentQuery) {
        _lastLoggedQuery = null;
      }
    });
    _updateUrl(newQuery: currentQuery);
  }

  void _logSearchResult(String searchQuery) {
    // Get auth state for user info
    final authState = ref.read(authControllerProvider);
    final repository = ref.read(searchResultsRepositoryProvider);

    // Log the search result asynchronously (don't await to avoid blocking UI)
    repository.logSearchResult(
      userId: authState.userId,
      userName: authState.name,
      searchQuery: searchQuery,
    );
  }
  
  int get _activeFilterCount {
    int count = 0;
    if (_sort != SortOption.relevance) count++;
    if (_minPrice != null || _maxPrice != null) count++;
    if (_selectedCategories.isNotEmpty) count++;
    if (_selectedBrands.isNotEmpty) count++;
    if (_inStockOnly) count++;
    if (_minRating != null) count++;
    return count;
  }
  
  void _openSortDialog() async {
    final result = await showModalBottomSheet<SortOption>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        SortOption tempSort = _sort;
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
                        onPressed: () => Navigator.pop(context),
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
                      const SizedBox(width: 48),
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
                            onChanged: (v) => setModalState(() => tempSort = v ?? tempSort),
                          ),
                          RadioListTile<SortOption>(
                            dense: true,
                            visualDensity: VisualDensity.compact,
                            title: const Text('Price: Low to High'),
                            value: SortOption.priceLowHigh,
                            groupValue: tempSort,
                            onChanged: (v) => setModalState(() => tempSort = v ?? tempSort),
                          ),
                          RadioListTile<SortOption>(
                            dense: true,
                            visualDensity: VisualDensity.compact,
                            title: const Text('Price: High to Low'),
                            value: SortOption.priceHighLow,
                            groupValue: tempSort,
                            onChanged: (v) => setModalState(() => tempSort = v ?? tempSort),
                          ),
                          RadioListTile<SortOption>(
                            dense: true,
                            visualDensity: VisualDensity.compact,
                            title: const Text('Rating: Highest First'),
                            value: SortOption.ratingHighLow,
                            groupValue: tempSort,
                            onChanged: (v) => setModalState(() => tempSort = v ?? tempSort),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: FilledButton(
                      onPressed: () {
                        Navigator.pop(context, tempSort);
                      },
                      child: const Text('Apply'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
    
    if (result != null && result != _sort) {
      setState(() {
        _sort = result;
      });
      _updateFilters();
    }
  }
  
  void _openPriceRangeDialog() async {
    final allProducts = ref.read(allProductsProvider);
    if (allProducts.isEmpty) return;
    
    final prices = allProducts.map((p) => p.price).toList();
    final minAvailablePrice = prices.reduce((a, b) => a < b ? a : b);
    final maxAvailablePrice = prices.reduce((a, b) => a > b ? a : b);
    
    double tempMinPrice = _minPrice ?? minAvailablePrice;
    double tempMaxPrice = _maxPrice ?? maxAvailablePrice;
    
    final minController = TextEditingController(
      text: tempMinPrice.toStringAsFixed(2),
    );
    final maxController = TextEditingController(
      text: tempMaxPrice.toStringAsFixed(2),
    );
    
    final result = await showModalBottomSheet<({double? min, double? max})>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            void updateMinPrice(double value) {
              setModalState(() {
                tempMinPrice = value.clamp(minAvailablePrice, tempMaxPrice);
                minController.text = tempMinPrice.toStringAsFixed(2);
                minController.selection = TextSelection.collapsed(
                  offset: minController.text.length,
                );
              });
            }
            
            void updateMaxPrice(double value) {
              setModalState(() {
                tempMaxPrice = value.clamp(tempMinPrice, maxAvailablePrice);
                maxController.text = tempMaxPrice.toStringAsFixed(2);
                maxController.selection = TextSelection.collapsed(
                  offset: maxController.text.length,
                );
              });
            }
            
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
                        onPressed: () => Navigator.pop(context),
                      ),
                      const Expanded(
                        child: Center(
                          child: Text(
                            'Price Range',
                            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
                          ),
                        ),
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            decoration: const InputDecoration(
                              labelText: 'Min Price',
                              prefixText: '\$',
                            ),
                            keyboardType: TextInputType.number,
                            controller: minController,
                            onChanged: (value) {
                              final parsed = double.tryParse(value);
                              if (parsed != null && parsed >= minAvailablePrice) {
                                updateMinPrice(parsed);
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextField(
                            decoration: const InputDecoration(
                              labelText: 'Max Price',
                              prefixText: '\$',
                            ),
                            keyboardType: TextInputType.number,
                            controller: maxController,
                            onChanged: (value) {
                              final parsed = double.tryParse(value);
                              if (parsed != null && parsed <= maxAvailablePrice) {
                                updateMaxPrice(parsed);
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: RangeSlider(
                      values: RangeValues(tempMinPrice, tempMaxPrice),
                      min: minAvailablePrice,
                      max: maxAvailablePrice,
                      divisions: 100,
                      labels: RangeLabels(
                        '\$${tempMinPrice.toStringAsFixed(0)}',
                        '\$${tempMaxPrice.toStringAsFixed(0)}',
                      ),
                      onChanged: (values) {
                        updateMinPrice(values.start);
                        updateMaxPrice(values.end);
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              Navigator.pop(context, (min: null, max: null));
                            },
                            child: const Text('Clear'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: FilledButton(
                            onPressed: () {
                              Navigator.pop(
                                context,
                                (min: tempMinPrice == minAvailablePrice ? null : tempMinPrice,
                                 max: tempMaxPrice == maxAvailablePrice ? null : tempMaxPrice),
                              );
                            },
                            child: const Text('Apply'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
    
    minController.dispose();
    maxController.dispose();
    
    if (result != null) {
      setState(() {
        _minPrice = result.min;
        _maxPrice = result.max;
      });
      _updateFilters();
    }
  }
  
  void _openCategoryDialog() async {
    final categories = ref.watch(categoriesProvider);
    final selected = List<String>.from(_selectedCategories);
    final searchController = TextEditingController();
    
    final result = await showModalBottomSheet<List<String>>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            String searchQuery = searchController.text;
            
            final filteredCategories = categories.where((cat) {
              return cat.toLowerCase().contains(searchQuery.toLowerCase());
            }).toList();
            
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
                        onPressed: () => Navigator.pop(context),
                      ),
                      const Expanded(
                        child: Center(
                          child: Text(
                            'Categories',
                            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
                          ),
                        ),
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: TextField(
                      controller: searchController,
                      decoration: const InputDecoration(
                        hintText: 'Search categories...',
                        prefixIcon: Icon(Ionicons.search_outline),
                      ),
                      onChanged: (value) {
                        setModalState(() {});
                      },
                    ),
                  ),
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: filteredCategories.length,
                      itemBuilder: (context, index) {
                        final category = filteredCategories[index];
                        final isSelected = selected.contains(category);
                        return CheckboxListTile(
                          dense: true,
                          visualDensity: VisualDensity.compact,
                          title: Text(category),
                          value: isSelected,
                          onChanged: (value) {
                            setModalState(() {
                              if (value == true) {
                                selected.add(category);
                              } else {
                                selected.remove(category);
                              }
                            });
                          },
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: FilledButton(
                      onPressed: () {
                        Navigator.pop(context, selected);
                      },
                      child: const Text('Apply'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
    
    searchController.dispose();
    
    if (result != null) {
      setState(() {
        _selectedCategories = result;
      });
      _updateFilters();
    }
  }
  
  void _openBrandDialog() async {
    final brands = ref.watch(brandsProvider);
    final selected = List<String>.from(_selectedBrands);
    final searchController = TextEditingController();
    
    final result = await showModalBottomSheet<List<String>>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            String searchQuery = searchController.text;
            
            final filteredBrands = brands.where((brand) {
              return brand.toLowerCase().contains(searchQuery.toLowerCase());
            }).toList();
            
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
                        onPressed: () => Navigator.pop(context),
                      ),
                      const Expanded(
                        child: Center(
                          child: Text(
                            'Brands',
                            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
                          ),
                        ),
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: TextField(
                      controller: searchController,
                      decoration: const InputDecoration(
                        hintText: 'Search brands...',
                        prefixIcon: Icon(Ionicons.search_outline),
                      ),
                      onChanged: (value) {
                        setModalState(() {});
                      },
                    ),
                  ),
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: filteredBrands.length,
                      itemBuilder: (context, index) {
                        final brand = filteredBrands[index];
                        final isSelected = selected.contains(brand);
                        return CheckboxListTile(
                          dense: true,
                          visualDensity: VisualDensity.compact,
                          title: Text(brand),
                          value: isSelected,
                          onChanged: (value) {
                            setModalState(() {
                              if (value == true) {
                                selected.add(brand);
                              } else {
                                selected.remove(brand);
                              }
                            });
                          },
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: FilledButton(
                      onPressed: () {
                        Navigator.pop(context, selected);
                      },
                      child: const Text('Apply'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
    
    searchController.dispose();
    
    if (result != null) {
      setState(() {
        _selectedBrands = result;
      });
      _updateFilters();
    }
  }
  
  void _openRatingDialog() async {
    double? tempMinRating = _minRating;
    
    final result = await showModalBottomSheet<double?>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
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
                        onPressed: () => Navigator.pop(context),
                      ),
                      const Expanded(
                        child: Center(
                          child: Text(
                            'Minimum Rating',
                            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
                          ),
                        ),
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),
                  Flexible(
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
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
                                ...List.generate(4, (i) => const Icon(Icons.star, size: 14, color: Colors.amber)),
                                const Icon(Icons.star_half, size: 14, color: Colors.amber),
                                const Text(' 4.5+ Stars'),
                              ],
                            ),
                            value: 4.5,
                            groupValue: tempMinRating,
                            onChanged: (v) => setModalState(() => tempMinRating = v),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: FilledButton(
                      onPressed: () {
                        Navigator.pop(context, tempMinRating);
                      },
                      child: const Text('Apply'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
    
    if (result != _minRating) {
      setState(() {
        _minRating = result;
      });
      _updateFilters();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final cardPadding = Responsive.getCardPadding(width);

    return SafeScaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Ionicons.arrow_back_outline),
          onPressed: () => NavigationHelper.handleBackNavigation(context),
        ),
        title: const Text('Search'),
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 4, vertical: cardPadding),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    autofocus: true,
                    decoration: const InputDecoration(
                      hintText: 'Search products, brands, tags',
                    ),
                    onChanged: (v) {
                      // Update local text state only, don't trigger search
                      setState(() => _searchText = v);
                    },
                    onSubmitted: (_) {
                      // Trigger search when user presses Enter
                      _performSearch();
                    },
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _performSearch,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.textPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    minimumSize: const Size(56, 48),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  child: const Icon(Ionicons.search_outline),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Builder(
              builder: (context) {
                // Trim the query for empty check
                final trimmedQuery = query.trim();

                // Use the filtered search provider with all filter parameters
                final filters = SearchFilters(
                  query: query,
                  sort: _sort,
                  minPrice: _minPrice,
                  maxPrice: _maxPrice,
                  categories: _selectedCategories,
                  brands: _selectedBrands,
                  inStockOnly: _inStockOnly,
                  minRating: _minRating,
                );
                final filtered = ref.watch(filteredSearchProductsProvider(filters));

                if (trimmedQuery.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Center(
                      child: Text(
                        'Type your search and click the search button',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  );
                }

                if (filtered.isEmpty) {
                  // Log the search result if it hasn't been logged yet
                  if (trimmedQuery.isNotEmpty && _lastLoggedQuery != trimmedQuery) {
                    _lastLoggedQuery = trimmedQuery;
                    _logSearchResult(trimmedQuery);
                  }

                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Ionicons.search_outline,
                            size: 64,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'No results found',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Try different keywords or check spelling',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                // Use ResponsiveProductGrid with shrinkWrap: true so it can be
                // inside SingleChildScrollView (returns Column instead of ListView)
                return SingleChildScrollView(
                  child: ResponsiveProductGrid(
                    products: filtered,
                    shrinkWrap: true,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
