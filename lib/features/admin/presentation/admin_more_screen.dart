import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/layout/responsive.dart';
import 'widgets/admin_navigation.dart';
import 'widgets/admin_auth_guard.dart';
import 'widgets/admin_scaffold.dart';

class AdminMoreScreen extends ConsumerWidget {
  const AdminMoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final width = MediaQuery.of(context).size.width;
    final foldableBreakpoint = Responsive.getFoldableBreakpoint(width);
    final spacing = Responsive.getSpacingForFoldable(width);

    final mediaQuery = MediaQuery.of(context);
    final systemBottomPadding = mediaQuery.viewPadding.bottom;

    // Calculate responsive navigation bar height
    final isUltraCompact = width <= 288;
    final isCompact = width <= 400;
    final bottomNavHeight = isUltraCompact ? 56.0 : (isCompact ? 60.0 : 64.0);
    final totalBottomSpacing =
        bottomNavHeight + systemBottomPadding + 40; // 40px buffer

    return AdminAuthGuard(
      child: AdminScaffold(
        title: 'More',
        showBackButton: true,
        body: SingleChildScrollView(
          padding: EdgeInsets.all(spacing),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Text(
                'Admin Tools',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: spacing * 0.5),
              Text(
                'Access all admin features',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
              SizedBox(height: spacing),

              // Navigation Items Grid
              _buildNavigationGrid(context, ref, foldableBreakpoint, spacing),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavigationGrid(
    BuildContext context,
    WidgetRef ref,
    FoldableBreakpoint foldableBreakpoint,
    double spacing,
  ) {
    // Get all navigation items (including those not in sidebar) and filter out "More" since we're already on the More screen
    final allNavItems =
        AdminNavigation.getAllNavigationItems(
          ref,
        ).where((item) => item.route != '/admin/more').toList();
    final isUltraCompact =
        foldableBreakpoint == FoldableBreakpoint.ultraCompact;
    final isCompact = foldableBreakpoint == FoldableBreakpoint.compact;

    // Determine grid columns based on screen size
    int crossAxisCount;
    if (isUltraCompact) {
      crossAxisCount = 2;
    } else if (isCompact) {
      crossAxisCount = 2;
    } else {
      crossAxisCount = 3;
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: spacing * 0.75,
        mainAxisSpacing: spacing * 0.75,
        childAspectRatio: isUltraCompact ? 1.1 : 1.0,
      ),
      itemCount: allNavItems.length,
      itemBuilder: (context, index) {
        final item = allNavItems[index];
        return _buildNavigationCard(context, item, isUltraCompact, isCompact);
      },
    );
  }

  Widget _buildNavigationCard(
    BuildContext context,
    AdminNavItem item,
    bool isUltraCompact,
    bool isCompact,
  ) {
    final iconSize = isUltraCompact ? 20.0 : 24.0;
    final titleSize = isUltraCompact ? 10.0 : 12.0;
    final padding = isUltraCompact ? 8.0 : 12.0;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(isUltraCompact ? 8 : 12),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: InkWell(
        onTap: () {
          // Use push for screens accessible from More screen to preserve navigation stack
          // Use go for main navigation screens
          final routesFromMore = [
            '/admin/analytics',
            '/admin/categories',
            '/admin/content',
            '/admin/features',
            '/admin/search-results',
            '/admin/hero-section',
          ];

          // Manufacturer List should use push
          if (item.route == '/admin/manufacturers' ||
              routesFromMore.contains(item.route)) {
            context.push(item.route);
          } else {
            // Pass previousRoute query parameter so the destination screen knows where it came from
            final uri = Uri.parse(item.route);
            final updatedUri = uri.replace(
              queryParameters: {
                ...uri.queryParameters,
                'previousRoute': '/admin/more',
              },
            );
            context.go(updatedUri.toString());
          }
        },
        borderRadius: BorderRadius.circular(isUltraCompact ? 8 : 12),
        child: Container(
          padding: EdgeInsets.all(padding),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(isUltraCompact ? 8 : 12),
                decoration: BoxDecoration(
                  color: item.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(isUltraCompact ? 8 : 12),
                ),
                child: Badge(
                  isLabelVisible: item.badgeCount > 0,
                  label: Text(item.badgeCount.toString()),
                  child: Icon(item.icon, color: item.color, size: iconSize),
                ),
              ),
              SizedBox(height: isUltraCompact ? 6 : 8),
              Text(
                item.title,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  fontSize: titleSize,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
