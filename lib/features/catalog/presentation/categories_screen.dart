import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ionicons/ionicons.dart';
import 'package:go_router/go_router.dart';
import '../../../core/layout/responsive.dart';
import '../../../core/ui/safe_scaffold.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/navigation/navigation_helper.dart';
import '../../admin/data/category_service.dart';
import '../../admin/domain/category.dart';
import '../../catalog/data/recent_categories.dart';
import '../../catalog/data/shared_product_provider.dart' as product_provider;

class CategoriesScreen extends ConsumerStatefulWidget {
  const CategoriesScreen({super.key});

  @override
  ConsumerState<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends ConsumerState<CategoriesScreen> {
  String query = '';

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);
    
    return SafeScaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Ionicons.arrow_back_outline),
          onPressed: () => NavigationHelper.handleBackNavigation(context, ref: ref),
        ),
        title: const Text('Categories'),
      ),
      body: categoriesAsync.when(
        data: (List<Category> categories) {
          // Filter to show only active categories
          var activeCategories = categories.where((c) => c.isActive).toList();
          
          // Apply custom sorting: priority order, then sort_order, then name
          activeCategories.sort((a, b) {
            // First sort by custom priority
            final priorityA = product_provider.getCategorySortPriority(a.name);
            final priorityB = product_provider.getCategorySortPriority(b.name);
            final priorityComparison = priorityA.compareTo(priorityB);
            if (priorityComparison != 0) return priorityComparison;
            
            // Then sort by sort_order
            final sortOrderComparison = a.sortOrder.compareTo(b.sortOrder);
            if (sortOrderComparison != 0) return sortOrderComparison;
            
            // Finally sort alphabetically by name
            return a.name.compareTo(b.name);
          });
          
          // Apply search filter if search query exists
          final searchQuery = query.toLowerCase().trim();
          if (searchQuery.isNotEmpty) {
            activeCategories = activeCategories.where((c) {
              return c.name.toLowerCase().contains(searchQuery) ||
                  c.description.toLowerCase().contains(searchQuery);
            }).toList();
          }
          
          if (activeCategories.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Ionicons.folder_outline,
                    size: 64,
                    color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No categories found',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Search bar
                TextField(
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Ionicons.search_outline),
                    hintText: 'Search categories',
                  ),
                  onChanged: (v) => setState(() => query = v),
                ),
                const SizedBox(height: 16),
                // Responsive vertical grid
                LayoutBuilder(
                  builder: (context, constraints) {
                    final width = constraints.maxWidth;
                    final bp = Responsive.breakpointForWidth(width);

                    // Determine number of columns based on breakpoint
                    int crossAxisCount;
                    double childAspectRatio;
                    double spacing;

                    if (bp == AppBreakpoint.compact) {
                      // Mobile: 2 columns
                      crossAxisCount = 2;
                      childAspectRatio = 1.2;
                      spacing = 16;
                    } else if (bp == AppBreakpoint.medium) {
                      // Tablet: 3 columns
                      crossAxisCount = 3;
                      childAspectRatio = 1.1;
                      spacing = 20;
                    } else {
                      // Desktop: 4 columns
                      crossAxisCount = 4;
                      childAspectRatio = 1.0;
                      spacing = 24;
                    }

                    return GridView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      shrinkWrap: true,
                      gridDelegate:
                          SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: crossAxisCount,
                            childAspectRatio: childAspectRatio,
                            crossAxisSpacing: spacing,
                            mainAxisSpacing: spacing,
                          ),
                      itemCount: activeCategories.length,
                      itemBuilder: (context, index) {
                        final category = activeCategories[index];
                        return _CategoryCard(
                          category: category,
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
                    );
                  },
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Ionicons.warning_outline,
                size: 64,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                'Failed to load categories',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '$error',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.7),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final Category category;
  final VoidCallback onTap;

  const _CategoryCard({
    required this.category,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.outlineMedium),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            // Image fills the entire card
            Positioned.fill(
              child: category.imageUrl != null && category.imageUrl!.isNotEmpty
                  ? Image.network(
                      category.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder:
                          (_, __, ___) => Container(
                            color: const Color(0xFFE5E7EB),
                            child: const Icon(
                              Icons.image_not_supported,
                              color: Colors.grey,
                            ),
                          ),
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          color: const Color(0xFFE5E7EB),
                          child: Center(
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                  : null,
                            ),
                          ),
                        );
                      },
                    )
                  : Container(
                      color: const Color(0xFFE5E7EB),
                      child: const Icon(
                        Icons.image_not_supported,
                        color: Colors.grey,
                        size: 48,
                      ),
                    ),
            ),
            // Text overlay at the bottom
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                ),
                child: Text(
                  category.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
