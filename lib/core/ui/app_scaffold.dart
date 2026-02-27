import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ionicons/ionicons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/cart/application/cart_controller.dart';
import '../layout/responsive.dart';
import '../navigation/route_history_provider.dart';
import 'whatsapp_button.dart';

class AppScaffold extends StatelessWidget {
  final Widget child;
  const AppScaffold({super.key, required this.child});

  static final _tabs = [
    _Tab('/home', Ionicons.home_outline, Ionicons.home, 'Home'),
    _Tab('/catalog', Ionicons.grid_outline, Ionicons.grid, 'Catalog'),
    _Tab('/cart', Ionicons.cart_outline, Ionicons.cart, 'Cart'),
    _Tab('/orders', Ionicons.receipt_outline, Ionicons.receipt, 'Orders'),
    _Tab('/profile', Ionicons.person_outline, Ionicons.person, 'Profile'),
  ];

  int _indexForLocation(String location) {
    // Hide navigation for product detail pages
    if (location.startsWith('/product/')) {
      return -1; // No tab selected
    }
    final idx = _tabs.indexWhere((t) => location.startsWith(t.route));
    return idx < 0 ? 0 : idx;
  }

  void _onTap(BuildContext context, WidgetRef ref, int index) {
    // Save current route before navigating to new tab
    final currentLocation = GoRouterState.of(context).uri.path;
    final targetRoute = _tabs[index].route;
    
    // Only save history if navigating to a different route
    // The saveCurrentRoute method already prevents duplicate consecutive routes
    if (currentLocation != targetRoute) {
      RouteHistoryHelper.saveCurrentRoute(ref, currentLocation);
    }
    
    context.go(targetRoute);
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final bp = Responsive.breakpointForWidth(width);
    final location = GoRouterState.of(context).uri.toString();
    final currentIndex = _indexForLocation(location);
    final shouldShowBottomNav = currentIndex >= 0;

    // NavigationRail for wider screens
    if (bp != AppBreakpoint.compact) {
      final shouldShowNavRail = shouldShowBottomNav;
      return Scaffold(
        body: Stack(
          children: [
            Row(
              children: [
                if (shouldShowNavRail)
                  Consumer(
                    builder: (context, ref, _) {
                      final cartItems = ref.watch(cartProvider);
                      final count1 = cartItems.length;
                      print('66 - AppScaffold:Cart items: $count1');
                      final count = ref
                          .watch(cartProvider)
                          .values
                          .fold<int>(0, (s, it) => s + it.quantity);
                      return NavigationRail(
                        selectedIndex: currentIndex >= 0 ? currentIndex : 0,
                        onDestinationSelected: (i) => _onTap(context, ref, i),
                        labelType: NavigationRailLabelType.all,
                        destinations: [
                          for (int i = 0; i < _tabs.length; i++)
                            NavigationRailDestination(
                              icon: _buildIcon(i, count, false),
                              selectedIcon: _buildIcon(i, count, true),
                              label: Text(_tabs[i].label),
                            ),
                        ],
                      );
                    },
                  ),
                if (shouldShowNavRail) const VerticalDivider(width: 1),
                Expanded(child: child),
              ],
            ),
            // WhatsApp button overlay
            const DraggableWhatsAppButton(),
          ],
        ),
      );
    }

    // Bottom NavigationBar for mobile
    return Scaffold(
      body: Stack(
        children: [
          child,
          // WhatsApp button overlay
          const DraggableWhatsAppButton(),
        ],
      ),
      bottomNavigationBar:
          shouldShowBottomNav
              ? Consumer(
                builder: (context, ref, _) {
                  final cartItems = ref.watch(cartProvider);
                  final count1 = cartItems.length;
                  final count = ref
                      .watch(cartProvider)
                      .values
                      .fold<int>(0, (s, it) => s + it.quantity);
                  return NavigationBar(
                    selectedIndex: currentIndex,
                    onDestinationSelected: (i) => _onTap(context, ref, i),
                    destinations: [
                      for (int i = 0; i < _tabs.length; i++)
                        NavigationDestination(
                          icon: _buildIcon(i, count1, false),
                          selectedIcon: _buildIcon(i, count1, true),
                          label: _tabs[i].label,
                        ),
                    ],
                  );
                },
              )
              : null,
    );
  }

  Widget _buildIcon(int index, int cartCount, bool isSelected) {
    final tab = _tabs[index];
    final icon = isSelected ? tab.iconFilled : tab.iconOutline;
    
    // Cart badge (index 2)
    if (index == 2 && cartCount > 0) {
      return Badge.count(
        count: cartCount,
        child: Icon(icon),
      );
    }
    
    return Icon(icon);
  }
}

class _Tab {
  final String route;
  final IconData iconOutline;
  final IconData iconFilled;
  final String label;
  const _Tab(this.route, this.iconOutline, this.iconFilled, this.label);
}
