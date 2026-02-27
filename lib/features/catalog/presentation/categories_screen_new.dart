import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ionicons/ionicons.dart';
import '../../../core/layout/responsive.dart';
import '../../../core/ui/safe_scaffold.dart';
import '../../catalog/data/shared_product_provider.dart';
import '../../catalog/data/recent_categories.dart';
import 'package:go_router/go_router.dart';
import 'widgets/responsive_product_grid.dart';

/// New categories screen with responsive grid and proper constraints
class CategoriesScreenNew extends ConsumerStatefulWidget {
  const CategoriesScreenNew({super.key});

  @override
  ConsumerState<CategoriesScreenNew> createState() =>
      _CategoriesScreenNewState();
}

class _CategoriesScreenNewState extends ConsumerState<CategoriesScreenNew> {
  String query = '';

  @override
  Widget build(BuildContext context) {
    final items = ref.watch(categoriesProvider);
    final screenWidth = MediaQuery.of(context).size.width;
    final cardPadding = Responsive.getCardPadding(screenWidth);

    return SafeScaffold(
      appBar: AppBar(title: const Text('Categories'), centerTitle: true),
      body: Builder(
        builder: (context) {
          if (items.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Ionicons.grid_outline, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No categories found',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          final filtered =
              items
                  .where(
                    (c) =>
                        query.isEmpty ||
                        c.toLowerCase().contains(query.toLowerCase()),
                  )
                  .toList();

          return Column(
            children: [
              // Search bar
              Padding(
                padding: Responsive.getResponsivePadding(screenWidth),
                child: TextField(
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Ionicons.search_outline),
                    hintText: 'Search categories',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                  onChanged: (v) => setState(() => query = v),
                ),
              ),
              // Categories grid
              Expanded(
                child: ResponsiveCategoryGrid(
                  categories: filtered,
                  onCategoryTap: (category) {
                    ref
                        .read(recentCategoriesProvider.notifier)
                        .markViewed(category);
                    context.pushNamed(
                      'browse',
                      pathParameters: {'kind': 'category', 'value': category},
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
