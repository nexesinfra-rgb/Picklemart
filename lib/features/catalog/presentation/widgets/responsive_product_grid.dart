import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ionicons/ionicons.dart';
import '../../../../core/layout/responsive_grid.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../catalog/data/product.dart';
import 'vertical_product_card.dart';
import 'universal_product_card.dart';

/// Responsive product grid with masonry layout and proper constraints
class ResponsiveProductGrid extends ConsumerWidget {
  final List<Product> products;
  final String? category;
  final bool useMasonryLayout;
  final ScrollController? scrollController;
  final bool shrinkWrap;

  const ResponsiveProductGrid({
    super.key,
    required this.products,
    this.category,
    this.useMasonryLayout = true,
    this.scrollController,
    this.shrinkWrap = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final screenWidth = MediaQuery.of(context).size.width;
    final gridConfig = ResponsiveGrid.getGridConfig(screenWidth);

    return Container(
      padding: ResponsiveGrid.getResponsivePadding(screenWidth),
      child: _buildStandardGrid(context, ref, gridConfig),
    );
  }

  // Masonry grid will be implemented when package issues are resolved
  // Widget _buildMasonryGrid(BuildContext context, WidgetRef ref, ResponsiveGridConfig config) {
  //   return MasonryGridView.count(
  //     controller: scrollController,
  //     shrinkWrap: shrinkWrap,
  //     physics: shrinkWrap ? const NeverScrollableScrollPhysics() : null,
  //     crossAxisCount: config.crossAxisCount,
  //     mainAxisSpacing: config.mainAxisSpacing,
  //     crossAxisSpacing: config.crossAxisSpacing,
  //     itemCount: products.length,
  //     itemBuilder: (context, index) {
  //       final product = products[index];
  //       return StandardProductCard(
  //         product: product,
  //         isHorizontal: false,
  //       );
  //     },
  //   );
  // }

  /// Calculate proper aspect ratio based on UniversalProductCard's actual dimensions
  /// Uses the same calculation logic as UniversalProductCard to ensure perfect fit
  double _calculateAspectRatio(double screenWidth) {
    // Use the static method from UniversalProductCard to get the exact aspect ratio
    return UniversalProductCard.getCardAspectRatio(screenWidth);
  }

  Widget _buildStandardGrid(
    BuildContext context,
    WidgetRef ref,
    ResponsiveGridConfig config,
  ) {
    if (shrinkWrap) {
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: config.crossAxisCount,
          childAspectRatio: config.childAspectRatio,
          crossAxisSpacing: config.crossAxisSpacing,
          mainAxisSpacing: config.mainAxisSpacing,
        ),
        itemCount: products.length,
        itemBuilder: (context, index) {
          final product = products[index];
          return UniversalProductCard(
            product: product,
          );
        },
      );
    } else {
      return ListView.builder(
        controller: scrollController,
        padding: const EdgeInsets.all(16),
        itemCount: products.length,
        cacheExtent: 500, // Cache 500px of off-screen items for smoother scrolling
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: VerticalProductCard(
              product: products[index],
            ),
          );
        },
      );
    }
  }
}

/// Responsive category grid with consistent layout
class ResponsiveCategoryGrid extends StatelessWidget {
  final List<String> categories;
  final Function(String) onCategoryTap;
  final ScrollController? scrollController;
  final bool shrinkWrap;

  const ResponsiveCategoryGrid({
    super.key,
    required this.categories,
    required this.onCategoryTap,
    this.scrollController,
    this.shrinkWrap = true,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final gridConfig = ResponsiveGrid.getGridConfig(screenWidth);
    final breakpointInfo = ResponsiveBreakpoints.getBreakpointInfo(screenWidth);

    return Container(
      padding: ResponsiveGrid.getResponsivePadding(screenWidth),
      child: GridView.builder(
        controller: scrollController,
        shrinkWrap: shrinkWrap,
        physics: shrinkWrap ? const NeverScrollableScrollPhysics() : null,
        gridDelegate: ResponsiveGrid.getStandardDelegate(screenWidth),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          return _buildCategoryCard(
            context,
            category,
            gridConfig,
            breakpointInfo,
          );
        },
      ),
    );
  }

  Widget _buildCategoryCard(
    BuildContext context,
    String category,
    ResponsiveGridConfig config,
    ResponsiveBreakpointInfo breakpointInfo,
  ) {
    final imageUrl = _getCategoryImage(category);

    if (breakpointInfo.isHorizontal) {
      return _buildHorizontalCategoryCard(context, category, imageUrl, config);
    } else {
      return _buildVerticalCategoryCard(context, category, imageUrl, config);
    }
  }

  Widget _buildVerticalCategoryCard(
    BuildContext context,
    String category,
    String imageUrl,
    ResponsiveGridConfig config,
  ) {
    return Container(
      constraints: BoxConstraints(
        maxWidth: config.maxCardWidth,
        maxHeight: config.maxCardHeight,
      ),
      child: InkWell(
        onTap: () => onCategoryTap(category),
        borderRadius: BorderRadius.circular(12),
        child: Card(
          clipBehavior: Clip.antiAlias,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: AppColors.outlineMedium, width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image section
              Expanded(
                flex: 3,
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(color: Color(0xFFF5F5F5)),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(12),
                    ),
                    child: Image.asset(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder:
                          (_, __, ___) => Container(
                            color: const Color(0xFFE5E7EB),
                            child: const Icon(
                              Ionicons.grid_outline,
                              color: Color(0xFF9CA3AF),
                              size: 32,
                            ),
                          ),
                    ),
                  ),
                ),
              ),
              // Category name
              Expanded(
                flex: 1,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Center(
                    child: Text(
                      category,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: _getResponsiveFontSize(config),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHorizontalCategoryCard(
    BuildContext context,
    String category,
    String imageUrl,
    ResponsiveGridConfig config,
  ) {
    return Container(
      constraints: BoxConstraints(
        maxWidth: config.maxCardWidth,
        maxHeight: config.maxCardHeight,
      ),
      child: InkWell(
        onTap: () => onCategoryTap(category),
        borderRadius: BorderRadius.circular(12),
        child: Card(
          clipBehavior: Clip.antiAlias,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: AppColors.outlineMedium, width: 1),
          ),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                // Image section
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: Container(
                      decoration: const BoxDecoration(color: Color(0xFFF5F5F5)),
                      child: Image.asset(
                        imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder:
                            (_, __, ___) => Container(
                              color: const Color(0xFFE5E7EB),
                              child: const Icon(
                                Ionicons.grid_outline,
                                color: Color(0xFF9CA3AF),
                                size: 24,
                              ),
                            ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Category name
                Expanded(
                  child: Text(
                    category,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Icon(Ionicons.chevron_forward_outline, size: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  double _getResponsiveFontSize(ResponsiveGridConfig config) {
    if (config.isHorizontal) {
      return 12;
    }

    if (config.crossAxisCount == 1) return 10;
    if (config.crossAxisCount == 2) return 11;
    if (config.crossAxisCount == 3) return 12;
    if (config.crossAxisCount == 4) return 13;
    return 14;
  }

  String _getCategoryImage(String category) {
    final map = <String, String>{
      'pickles': 'assets/picklemart.png',
      'pickle': 'assets/picklemart.png',
      'karam podis': 'assets/picklemart.png',
      'karam podi': 'assets/picklemart.png',
      'spice powders': 'assets/picklemart.png',
      'spice powder': 'assets/picklemart.png',
      'masalas': 'assets/picklemart.png',
      'masala': 'assets/picklemart.png',
      'gunpowder': 'assets/picklemart.png',
      'achar': 'assets/picklemart.png',
    };

    final key = category.toLowerCase();
    return map[key] ?? 'assets/picklemart.png';
  }
}
