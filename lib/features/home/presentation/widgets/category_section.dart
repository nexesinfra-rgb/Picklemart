/*
Standard pattern: Use slivers for vertical scroll; each horizontal carousel sits in a fixed-height SizedBox.

Responsiveness: Compute cardWidth from breakpoints; drive cardHeight from aspect ratio (3:4).

Stability: Reserve 48px for the Add/Stepper control and use AnimatedSwitcher to avoid layout jumps.

No nested vertical scrollables to prevent constraint errors when switching between mobile/tablet/desktop.
*/

import 'package:flutter/material.dart';
import '../../../catalog/data/product.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/layout/responsive.dart';
import '../../../catalog/presentation/widgets/universal_product_card.dart';

class CategorySection extends StatelessWidget {
  final String title;
  final List<Product> products;
  final VoidCallback onViewAll;

  const CategorySection({
    super.key,
    required this.title,
    required this.products,
    required this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    // Responsive horizontal padding: slightly reduced on mobile to minimize side gaps
    final screenWidth = MediaQuery.of(context).size.width;
    final horizontalPadding =
        screenWidth < 600 ? 4.0 : (screenWidth < 1024 ? 10.0 : 14.0);
    return Padding(
      // Slightly tighter top spacing so the heading sits closer
      // to the previous section while keeping comfortable bottom space.
      padding: EdgeInsets.only(
        top: 4,
        bottom: 8,
        left: horizontalPadding,
        right: horizontalPadding,
      ),
      child: Card(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 0,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with title and View all button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: onViewAll,
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primary,
                    ),
                    child: const Text('View all'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Horizontal scrollable product cards
              LayoutBuilder(
                builder: (context, constraints) {
                  // Use unified Featured Products card width constraints
                  final width = constraints.maxWidth;
                  final cardWidth = Responsive.getUnifiedProductCardWidth(width);

                  // Calculate height based on card width and aspect ratio
                  final cardAspectRatio = UniversalProductCard.getCardAspectRatio(width, customCardWidth: cardWidth);
                  final overflowBuffer = 32.0; // Increased buffer for ListView padding and shadows
                  final estimatedCardHeight = (cardWidth / cardAspectRatio) + overflowBuffer;

                  // Use responsive horizontal padding matching Featured Products
                  final horizontalPadding = Responsive.getProductCardSectionPadding(width);
                  
                  return SizedBox(
                    height: estimatedCardHeight,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 8),
                      itemCount: products.length,
                      itemBuilder: (context, i) {
                        final isLast = i == products.length - 1;
                        return Padding(
                          padding: EdgeInsets.only(right: isLast ? 16 : 8),
                          child: SizedBox(
                            width: cardWidth,
                            child: UniversalProductCard(
                              product: products[i],
                              cardWidth: cardWidth,
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

