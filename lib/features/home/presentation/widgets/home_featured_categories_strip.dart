import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/layout/responsive.dart';
import '../../../catalog/data/shared_product_provider.dart';
import '../../../catalog/data/recent_categories.dart';
import '../../../admin/domain/category.dart';

class HomeFeaturedCategoriesStrip extends ConsumerWidget {
  final int maxCount;
  const HomeFeaturedCategoriesStrip({super.key, this.maxCount = 8});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(databaseCategoriesProvider);
    final viewed = ref.watch(recentCategoriesProvider);

    return categoriesAsync.when(
      data: (categories) {
        // Use the categories directly as they are already sorted by priority
        // Do NOT reorder based on viewed history to keep the order stable
        final ordered = categories;

        if (ordered.isEmpty) return const SizedBox.shrink();

        // Display only the first maxCount categories
        final displayItems = ordered.take(maxCount).toList();

        return SizedBox(
          height: 100, // Further reduced height to prevent overflow
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: displayItems.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, i) {
              final category = displayItems[i];
              return _MiniCategoryCard(
                label: category.name,
                imageUrl: category.imageUrl,
                onTap: () {
                  ref
                      .read(recentCategoriesProvider.notifier)
                      .markViewed(category.name);
                  context.pushNamed(
                    'browse',
                    pathParameters: {
                      'kind': 'category',
                      'value': category.name,
                    },
                  );
                },
              );
            },
          ),
        );
      },
      loading:
          () => const SizedBox(
            height: 100,
            child: Center(child: CircularProgressIndicator()),
          ),
      error: (error, stackTrace) {
        // On error, fall back to the old categoriesProvider
        final items = ref.watch(categoriesProvider);

        // Sort the fallback list using the same priority logic
        final ordered = List<String>.from(items)..sort((a, b) {
          final priorityA = getCategorySortPriority(a);
          final priorityB = getCategorySortPriority(b);
          return priorityA.compareTo(priorityB);
        });

        if (ordered.isEmpty) return const SizedBox.shrink();

        final displayItems = ordered.take(maxCount).toList();

        return SizedBox(
          height: 100,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: displayItems.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, i) {
              final c = displayItems[i];
              final img = _imageForCategory(c);
              return _MiniCategoryCard(
                label: c,
                imageUrl: img,
                isAsset: true,
                onTap: () {
                  ref.read(recentCategoriesProvider.notifier).markViewed(c);
                  context.pushNamed(
                    'browse',
                    pathParameters: {'kind': 'category', 'value': c},
                  );
                },
              );
            },
          ),
        );
      },
    );
  }
}

class _MiniCategoryCard extends StatelessWidget {
  final String label;
  final String? imageUrl;
  final bool isAsset;
  final VoidCallback onTap;
  const _MiniCategoryCard({
    required this.label,
    this.imageUrl,
    this.isAsset = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final bp = Responsive.breakpointForWidth(width);
    final responsiveWidth = _getResponsiveCardWidth(width, bp);
    final responsivePadding = _getResponsivePadding(width, bp);
    final responsiveFontSize = _getResponsiveFontSize(width, bp);
    final responsiveBorderRadius = _getResponsiveBorderRadius(width, bp);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(responsiveBorderRadius),
      child: SizedBox(
        width: responsiveWidth,
        child: Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(responsiveBorderRadius),
            side: const BorderSide(color: AppColors.outlineMedium),
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              // Image fills the entire card
              Positioned.fill(child: _buildImage()),
              // Text overlay at the bottom
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: EdgeInsets.all(responsivePadding),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(responsiveBorderRadius),
                      bottomRight: Radius.circular(responsiveBorderRadius),
                    ),
                  ),
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: responsiveFontSize,
                      color: Colors.white,
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

  Widget _buildImage() {
    // If imageUrl is null or empty, use fallback
    if (imageUrl == null || imageUrl!.isEmpty) {
      final fallbackImage = _imageForCategory(label);
      return Image.asset(
        fallbackImage,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(color: const Color(0xFFE5E7EB)),
      );
    }

    // If it's an asset path (starts with 'assets/'), use Image.asset
    if (isAsset || imageUrl!.startsWith('assets/')) {
      return Image.asset(
        imageUrl!,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) {
          // Fallback to category mapping if asset fails
          final fallbackImage = _imageForCategory(label);
          return Image.asset(
            fallbackImage,
            fit: BoxFit.cover,
            errorBuilder:
                (_, __, ___) => Container(color: const Color(0xFFE5E7EB)),
          );
        },
      );
    }

    // Otherwise, it's a network URL - use Image.network
    return Image.network(
      imageUrl!,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Container(
          color: const Color(0xFFE5E7EB),
          child: Center(
            child: CircularProgressIndicator(
              value:
                  loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                      : null,
            ),
          ),
        );
      },
      errorBuilder: (_, __, ___) {
        // Fallback to category mapping if network image fails
        final fallbackImage = _imageForCategory(label);
        return Image.asset(
          fallbackImage,
          fit: BoxFit.cover,
          errorBuilder:
              (_, __, ___) => Container(color: const Color(0xFFE5E7EB)),
        );
      },
    );
  }
}

double _getResponsiveCardWidth(double width, AppBreakpoint bp) {
  // More compact card width for home featured categories to prevent overflow
  if (bp == AppBreakpoint.compact) {
    return width < 340
        ? 70
        : width < 380
        ? 80
        : 85; // Very compact for mobile
  } else if (width < 600) {
    return 90; // Small screens
  } else if (width < 750) {
    return 100; // Medium-small screens
  } else if (width < 900) {
    return 110; // Medium screens
  } else if (width < 1200) {
    return 120; // Large screens
  } else {
    return 130; // Extra large screens
  }
}

double _getResponsivePadding(double width, AppBreakpoint bp) {
  // Minimal padding for home featured categories to prevent overflow
  if (bp == AppBreakpoint.compact) {
    return width < 340
        ? 2.0
        : width < 380
        ? 3.0
        : 4.0; // Very minimal padding for mobile
  } else if (width < 600) {
    return 4.0; // Small screens
  } else if (width < 750) {
    return 5.0; // Medium-small screens
  } else if (width < 900) {
    return 6.0; // Medium screens
  } else if (width < 1200) {
    return 7.0; // Large screens
  } else {
    return 8.0; // Extra large screens
  }
}

double _getResponsiveFontSize(double width, AppBreakpoint bp) {
  // Smaller font sizes for home featured categories to prevent overflow
  if (bp == AppBreakpoint.compact) {
    return width < 340
        ? 8
        : width < 380
        ? 9
        : 10; // Very small fonts for mobile
  } else if (width < 600) {
    return 10; // Small screens
  } else if (width < 750) {
    return 11; // Medium-small screens
  } else if (width < 900) {
    return 12; // Medium screens
  } else if (width < 1200) {
    return 13; // Large screens
  } else {
    return 14; // Extra large screens
  }
}

double _getResponsiveBorderRadius(double width, AppBreakpoint bp) {
  // Responsive border radius for mini category cards
  if (bp == AppBreakpoint.compact) {
    return width < 340
        ? 8.0
        : width < 380
        ? 10.0
        : 12.0; // Compact screens
  } else if (width < 600) {
    return 12.0; // Small screens
  } else if (width < 750) {
    return 14.0; // Medium-small screens
  } else if (width < 900) {
    return 16.0; // Medium screens
  } else if (width < 1200) {
    return 18.0; // Large screens
  } else {
    return 20.0; // Extra large screens
  }
}

String _imageForCategory(String label) {
  // Map food categories to actual asset images
  // Expanded mapping to include more category name variations
  final map = <String, String>{
    // Pickles
    'pickles': 'assets/picklemart.png',
    'pickle': 'assets/picklemart.png',
    'achar': 'assets/picklemart.png',
    'indian pickle': 'assets/picklemart.png',

    // Karam Podis
    'karam podis': 'assets/picklemart.png',
    'karam podi': 'assets/picklemart.png',
    'gunpowder': 'assets/picklemart.png',
    'idli podi': 'assets/picklemart.png',
    'dosa podi': 'assets/picklemart.png',
    'chutney podi': 'assets/picklemart.png',

    // Spice Powders
    'spice powders': 'assets/picklemart.png',
    'spice powder': 'assets/picklemart.png',
    'masala powder': 'assets/picklemart.png',
    'spice mix': 'assets/picklemart.png',
    'ground spices': 'assets/picklemart.png',
    'sambar powder': 'assets/picklemart.png',
    'rasam powder': 'assets/picklemart.png',
    'curry powder': 'assets/picklemart.png',

    // Masalas
    'masalas': 'assets/picklemart.png',
    'masala': 'assets/picklemart.png',
    'garam masala': 'assets/picklemart.png',
    'chaat masala': 'assets/picklemart.png',
    'biryani masala': 'assets/picklemart.png',
    'tandoori masala': 'assets/picklemart.png',
    'pav bhaji masala': 'assets/picklemart.png',
    'spice blend': 'assets/picklemart.png',
    'masala mix': 'assets/picklemart.png',
  };

  final key = label.toLowerCase().trim();
  return map[key] ?? 'assets/picklemart.png'; // Default to picklemart image
}
