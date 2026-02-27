import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ionicons/ionicons.dart';
import '../../../../core/layout/responsive.dart';
import '../../../../core/navigation/route_history_provider.dart';
import '../../../../core/navigation/current_route_provider.dart';

import 'package:picklemart/features/admin/application/admin_order_controller.dart';

// Navigation item model
class AdminNavItem {
  final String title;
  final IconData icon;
  final String route;
  final Color color;
  final int badgeCount;

  const AdminNavItem({
    required this.title,
    required this.icon,
    required this.route,
    required this.color,
    this.badgeCount = 0,
  });
}

class AdminNavigation {
  static List<AdminNavItem> getNavigationItems(WidgetRef ref) {
    final unreadCount = ref.watch(unreadOrdersCountProvider);
    return [
      const AdminNavItem(
        title: 'Dashboard',
        icon: Ionicons.grid_outline,
        route: '/admin/dashboard',
        color: Colors.blue,
      ),
      const AdminNavItem(
        title: 'Accounts',
        icon: Ionicons.card_outline,
        route: '/admin/accounts',
        color: Colors.deepPurple,
      ),
      AdminNavItem(
        title: 'Orders',
        icon: Ionicons.basket_outline,
        route: '/admin/orders',
        color: Colors.green,
        badgeCount: unreadCount,
      ),
      const AdminNavItem(
        title: 'Cash Book',
        icon: Ionicons.wallet_outline,
        route: '/admin/credit-system',
        color: Colors.indigo,
      ),
      const AdminNavItem(
        title: 'More',
        icon: Ionicons.apps_outline,
        route: '/admin/more',
        color: Colors.grey,
      ),
    ];
  }

  /// Returns all navigation items including those not shown in the desktop sidebar
  /// This is used by the "More" screen to display all available admin tools
  static List<AdminNavItem> getAllNavigationItems(WidgetRef ref) {
    final unreadCount = ref.watch(unreadOrdersCountProvider);
    return [
      const AdminNavItem(
        title: 'Manufacturer List',
        icon: Ionicons.business_outline,
        route: '/admin/manufacturers',
        color: Colors.amber,
      ),
      const AdminNavItem(
        title: 'Dashboard',
        icon: Ionicons.grid_outline,
        route: '/admin/dashboard',
        color: Colors.blue,
      ),
      const AdminNavItem(
        title: 'Category Management',
        icon: Ionicons.folder_outline,
        route: '/admin/categories',
        color: Colors.teal,
      ),
      const AdminNavItem(
        title: 'Products',
        icon: Ionicons.cube_outline,
        route: '/admin/products',
        color: Colors.blue,
      ),
      const AdminNavItem(
        title: 'Featured Products',
        icon: Ionicons.star_outline,
        route: '/admin/featured-products',
        color: Colors.amber,
      ),
      AdminNavItem(
        title: 'Orders',
        icon: Ionicons.basket_outline,
        route: '/admin/orders',
        color: Colors.green,
        badgeCount: unreadCount,
      ),
      const AdminNavItem(
        title: 'Stores',
        icon: Ionicons.people_outline,
        route: '/admin/customers',
        color: Colors.orange,
      ),
      AdminNavItem(
        title: 'Analytics',
        icon: Ionicons.bar_chart_outline,
        route: '/admin/analytics',
        color: Colors.purple,
      ),
      AdminNavItem(
        title: 'Content',
        icon: Ionicons.document_text_outline,
        route: '/admin/content',
        color: Colors.brown,
      ),
      AdminNavItem(
        title: 'Hero Section',
        icon: Ionicons.images_outline,
        route: '/admin/hero-section',
        color: Colors.cyan,
      ),
      AdminNavItem(
        title: 'Ratings Management',
        icon: Ionicons.star,
        route: '/admin/ratings',
        color: Colors.amber,
      ),
      AdminNavItem(
        title: 'Chat',
        icon: Ionicons.chatbubbles_outline,
        route: '/admin/chat',
        color: Colors.pink,
      ),
      AdminNavItem(
        title: 'Admin Features',
        icon: Ionicons.settings_outline,
        route: '/admin/features',
        color: Colors.grey,
      ),
      AdminNavItem(
        title: 'Search Results',
        icon: Ionicons.search_outline,
        route: '/admin/search-results',
        color: Colors.indigo,
      ),
      AdminNavItem(
        title: 'Accounts',
        icon: Ionicons.card_outline,
        route: '/admin/accounts',
        color: Colors.deepPurple,
      ),
      AdminNavItem(
        title: 'Cash Book',
        icon: Ionicons.wallet_outline,
        route: '/admin/credit-system',
        color: Colors.indigo,
      ),
    ];
  }

  static List<AdminNavItem> getMobileNavigationItems(WidgetRef ref) {
    final unreadCount = ref.watch(unreadOrdersCountProvider);

    return [
      const AdminNavItem(
        title: 'Dashboard',
        icon: Ionicons.grid_outline,
        route: '/admin/dashboard',
        color: Colors.blue,
      ),
      const AdminNavItem(
        title: 'Accounts',
        icon: Ionicons.card_outline,
        route: '/admin/accounts',
        color: Colors.deepPurple,
      ),
      AdminNavItem(
        title: 'Orders',
        icon: Ionicons.basket_outline,
        route: '/admin/orders',
        color: Colors.green,
        badgeCount: unreadCount,
      ),
      const AdminNavItem(
        title: 'Cash Book',
        icon: Ionicons.wallet_outline,
        route: '/admin/credit-system',
        color: Colors.indigo,
      ),
      const AdminNavItem(
        title: 'More',
        icon: Ionicons.apps_outline,
        route: '/admin/more',
        color: Colors.grey,
      ),
    ];
  }

  static Widget buildStickyBottomNavigationBar(
    BuildContext context,
    WidgetRef ref,
  ) {
    final width = MediaQuery.of(context).size.width;
    final foldableBreakpoint = Responsive.getFoldableBreakpoint(width);

    // Use mobile navigation items for mobile devices and tablet-sized devices (up to 882px)
    if (Responsive.getScreenSize(context) == ScreenSize.mobile ||
        foldableBreakpoint != FoldableBreakpoint.large) {
      final mobileNavItems = getMobileNavigationItems(ref);

      // Get current route from GoRouterState to keep in sync with navigation
      final currentRouteState = GoRouterState.of(context);
      final currentRoute = getBaseRoute(currentRouteState.uri.path);
      final currentIndex = _getCurrentIndex(mobileNavItems, currentRoute);

      // Calculate responsive sizes based on width
      // At 288px: smaller sizes, at 400px+: medium, at 600px+: normal
      final isUltraCompact = width <= 288;
      final isCompact = width <= 400;

      final navHeight = isUltraCompact ? 56.0 : (isCompact ? 60.0 : 64.0);
      final iconSize = isUltraCompact ? 16.0 : (isCompact ? 18.0 : 20.0);
      final fontSize =
          isUltraCompact
              ? 9.0
              : (isCompact ? 10.0 : 12.0); // Smaller font at 288px
      final iconBackgroundSize =
          isUltraCompact ? 32.0 : (isCompact ? 36.0 : 40.0);

      return Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary,
          border: Border(
            top: BorderSide(width: 0.5, color: Colors.black.withOpacity(0.1)),
          ),
        ),
        child: NavigationBarTheme(
          data: NavigationBarThemeData(
            height: navHeight,
            backgroundColor: Colors.transparent,
            indicatorColor: Colors.black.withOpacity(0.08),
            surfaceTintColor: Colors.transparent,
            iconTheme: WidgetStateProperty.resolveWith((states) {
              return IconThemeData(
                size: iconSize,
                color:
                    states.contains(WidgetState.selected)
                        ? Colors.black
                        : Colors.black.withOpacity(0.6),
              );
            }),
            labelTextStyle: WidgetStateProperty.resolveWith((states) {
              return TextStyle(
                fontSize: fontSize,
                fontWeight:
                    states.contains(WidgetState.selected)
                        ? FontWeight.bold
                        : FontWeight.normal,
                color:
                    states.contains(WidgetState.selected)
                        ? Colors.black
                        : Colors.black.withOpacity(0.6),
              );
            }),
          ),
          child: NavigationBar(
            selectedIndex: currentIndex,
            backgroundColor: Colors.transparent,
            elevation: 0,
            onDestinationSelected: (index) {
              final item = mobileNavItems[index];
              final baseCurrentRoute = getBaseRoute(currentRoute);

              // Only navigate if it's a different route
              if (item.route != baseCurrentRoute) {
                // Save current route to history before navigating
                RouteHistoryHelper.saveCurrentRoute(
                  ref,
                  currentRouteState.uri.path,
                );

                // Navigate to the new route
                context.go(item.route);
              } else {
                // Force reload if clicking the same route
                final uri = Uri.tryParse(item.route);
                if (uri != null) {
                  final newUri = uri.replace(
                    queryParameters: {
                      ...uri.queryParameters,
                      'refresh':
                          DateTime.now().millisecondsSinceEpoch.toString(),
                    },
                  );
                  context.go(newUri.toString());
                }
              }
            },
            destinations:
                mobileNavItems.asMap().entries.map((entry) {
                  final index = entry.key;
                  final item = entry.value;
                  final isSelected = index == currentIndex;

                  // At 288px, use shorter labels for Dashboard and Cash Book to prevent truncation
                  String displayLabel = item.title;
                  if (isUltraCompact) {
                    if (item.route == '/admin/dashboard') {
                      displayLabel = 'Dash';
                    } else if (item.route == '/admin/credit-system') {
                      displayLabel = 'Cash';
                    }
                  }

                  return NavigationDestination(
                    icon: Badge(
                      label:
                          item.badgeCount > 0
                              ? Text(item.badgeCount.toString())
                              : null,
                      isLabelVisible: item.badgeCount > 0,
                      child: _buildIconWithBackground(
                        context,
                        item.icon,
                        iconSize,
                        iconBackgroundSize,
                        false,
                      ),
                    ),
                    selectedIcon: Badge(
                      label:
                          item.badgeCount > 0
                              ? Text(
                                item.badgeCount.toString(),
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              )
                              : null,
                      isLabelVisible: item.badgeCount > 0,
                      child: _buildIconWithBackground(
                        context,
                        _getFilledIcon(item.icon),
                        iconSize,
                        iconBackgroundSize,
                        true,
                      ),
                    ),
                    label: displayLabel,
                  );
                }).toList(),
          ),
        ),
      );
    } else {
      return const SizedBox.shrink(); // No bottom nav for desktop
    }
  }

  static int _getCurrentIndex(List<AdminNavItem> items, String currentRoute) {
    // Get base route to handle nested routes (e.g., /admin/products/form -> /admin/products)
    final baseRoute = getBaseRoute(currentRoute);
    final index = items.indexWhere((item) {
      return baseRoute == item.route;
    });
    return index >= 0 ? index : 0;
  }

  /// Build icon with background highlight for selected state
  static Widget _buildIconWithBackground(
    BuildContext context,
    IconData icon,
    double iconSize,
    double backgroundSize,
    bool isSelected,
  ) {
    if (isSelected) {
      // Selected: icon with a subtle dark highlight on the primary color background
      return Container(
        width: backgroundSize,
        height: backgroundSize,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, size: iconSize, color: Colors.black),
      );
    } else {
      // Unselected: just the icon
      return Icon(icon, size: iconSize, color: Colors.black.withOpacity(0.6));
    }
  }

  static IconData _getFilledIcon(IconData outlineIcon) {
    // Map outline icons to their filled counterparts
    switch (outlineIcon) {
      case Ionicons.grid_outline:
        return Ionicons.grid;
      case Ionicons.cube_outline:
        return Ionicons.cube;
      case Ionicons.card_outline:
        return Ionicons.card;
      case Ionicons.basket_outline:
        return Ionicons.basket;
      case Ionicons.people_outline:
        return Ionicons.people;
      case Ionicons.apps_outline:
        return Ionicons.apps;
      case Ionicons.wallet_outline:
        return Ionicons.wallet;
      default:
        return outlineIcon; // Return original if no filled version available
    }
  }
}

class AdminAppBar extends ConsumerWidget implements PreferredSizeWidget {
  final String title;
  final Widget? titleWidget;
  final bool showBackButton;
  final VoidCallback? onBackPressed;
  final List<Widget>? actions;
  final double toolbarHeight;

  const AdminAppBar({
    super.key,
    required this.title,
    this.titleWidget,
    this.showBackButton = false,
    this.onBackPressed,
    this.actions,
    this.toolbarHeight = kToolbarHeight,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Combine actions with notification icon
    final allActions = [
      if (actions != null) ...actions!,
      // Notification icon will be added by AdminScaffold in mobile layout
    ];

    return AppBar(
      title: titleWidget ?? Text(title),
      centerTitle: true,
      toolbarHeight: toolbarHeight,
      leading:
          showBackButton
              ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed:
                    onBackPressed ??
                    () {
                      // Try to pop first - navigation stack should be preserved now
                      if (context.canPop()) {
                        context.pop();
                      } else {
                        // Fallback: navigate to dashboard when stack is broken
                        // Most admin screens are accessed from the dashboard
                        context.go('/admin/dashboard');
                      }
                    },
              )
              : null,
      actions: allActions,
      elevation: 0,
      backgroundColor: Theme.of(context).colorScheme.surface,
      foregroundColor: Theme.of(context).colorScheme.onSurface,
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(toolbarHeight);
}
