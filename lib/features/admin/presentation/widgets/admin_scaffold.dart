import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ionicons/ionicons.dart';
import '../../../../core/layout/responsive.dart';
import '../../../../core/navigation/current_route_provider.dart';
import '../../application/admin_auth_controller.dart';
import '../../application/admin_order_controller.dart';
import 'admin_navigation.dart';

/// A reusable scaffold for admin screens that provides:
/// - Persistent sidebar for desktop mode (width >= 882px)
/// - Bottom navigation for mobile/tablet (< 882px)
/// - Consistent layout across all admin screens
class AdminScaffold extends ConsumerWidget {
  final String title;
  final Widget? titleWidget;
  final Widget body;
  final bool showBackButton;
  final VoidCallback? onBackPressed;
  final List<Widget>? actions;
  final double? toolbarHeight;
  final Widget? bottomNavigationBar;
  final bool showFloatingActionButton;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;

  const AdminScaffold({
    super.key,
    required this.title,
    this.titleWidget,
    required this.body,
    this.showBackButton = false,
    this.onBackPressed,
    this.actions,
    this.toolbarHeight,
    this.bottomNavigationBar,
    this.showFloatingActionButton = true,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mediaQuery = MediaQuery.of(context);
    final width = mediaQuery.size.width;
    final screenSize = Responsive.getScreenSize(context);
    final foldableBreakpoint = Responsive.getFoldableBreakpoint(width);
    final adminUser = ref.watch(currentAdminProvider);
    final navItems = AdminNavigation.getNavigationItems(ref);

    // Ensure order controller is initialized and kept alive to listen for new orders/sounds
    // This allows sound notifications to work across all admin screens
    // Using listen keeps the provider alive even if we don't use the value
    ref.listen(adminOrderControllerProvider, (_, __) {});

    // Fire-and-forget: initialize() handles idempotency internally
    Future(() {
      if (context.mounted) {
        ref.read(adminOrderControllerProvider.notifier).initialize();
      }
    });

    // Desktop layout (>= 882px) - show sidebar
    // Use a slightly lower threshold to ensure sidebar shows on desktop
    final isDesktop = width >= 882.0;

    if (isDesktop) {
      return _buildDesktopLayout(context, ref, adminUser, navItems);
    }
    // Tablet/mobile layout (< 882px) - show bottom nav
    else {
      return _buildMobileLayout(context, ref, width, foldableBreakpoint);
    }
  }

  Widget _buildDesktopLayout(
    BuildContext context,
    WidgetRef ref,
    adminUser,
    List<AdminNavItem> navItems,
  ) {
    return Scaffold(
      floatingActionButton:
          showFloatingActionButton ? floatingActionButton : null,
      floatingActionButtonLocation: floatingActionButtonLocation,
      body: Row(
        children: [
          // Left Sidebar
          _buildSidebar(context, ref, adminUser, navItems),
          // Main Content
          Expanded(
            child: Column(
              children: [
                // Top App Bar
                _buildTopAppBar(context, ref, adminUser),
                // Main Content
                Expanded(child: body),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileLayout(
    BuildContext context,
    WidgetRef ref,
    double width,
    FoldableBreakpoint foldableBreakpoint,
  ) {
    // Create logout button
    final logoutButton = IconButton(
      icon: const Icon(Ionicons.log_out_outline),
      onPressed: () async {
        await ref.read(adminAuthControllerProvider.notifier).signOut();
        if (context.mounted) {
          context.goNamed('admin-login');
        }
      },
      tooltip: 'Sign Out',
    );

    // Combine existing actions with logout button
    final allActions = [
      if (actions != null) ...actions!,
      // Notification bell hidden as per request
      // const AdminNotificationIcon(),
      logoutButton,
    ];

    return Scaffold(
      floatingActionButton:
          showFloatingActionButton ? floatingActionButton : null,
      appBar: AdminAppBar(
        title: title,
        titleWidget: titleWidget,
        showBackButton: showBackButton,
        onBackPressed: onBackPressed,
        actions: allActions,
        toolbarHeight: toolbarHeight ?? kToolbarHeight,
      ),
      body: body,
      bottomNavigationBar:
          bottomNavigationBar ??
          AdminNavigation.buildStickyBottomNavigationBar(context, ref),
    );
  }

  Widget _buildTopAppBar(BuildContext context, WidgetRef ref, adminUser) {
    return Container(
      height: toolbarHeight ?? 64.0,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
          ),
        ),
      ),
      child: Row(
        children: [
          titleWidget ??
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
          const Spacer(),
          if (actions != null) ...actions!,
          // Notification bell hidden as per request
          // const AdminNotificationIcon(),
          const SizedBox(width: 8),
          _buildUserMenu(context, ref, adminUser),
        ],
      ),
    );
  }

  Widget _buildSidebar(
    BuildContext context,
    WidgetRef ref,
    adminUser,
    List<AdminNavItem> navItems,
  ) {
    // Get current route for highlighting
    final currentRouteState = GoRouterState.of(context);
    final currentRoute = getBaseRoute(currentRouteState.uri.path);

    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          right: BorderSide(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
          ),
        ),
      ),
      child: Column(
        children: [
          // Logo/Header
          Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Ionicons.settings_outline,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Admin Panel',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  adminUser?.name ?? 'Admin',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Navigation Items
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: navItems.length,
              itemBuilder: (context, index) {
                final item = navItems[index];
                final isSelected = getBaseRoute(item.route) == currentRoute;
                return _buildSidebarNavItem(context, item, isSelected);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarNavItem(
    BuildContext context,
    AdminNavItem item,
    bool isSelected,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color:
            isSelected
                ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: Badge(
          isLabelVisible: item.badgeCount > 0,
          label: Text(item.badgeCount.toString()),
          child: Icon(
            item.icon,
            color:
                isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            size: 20,
          ),
        ),
        title: Text(
          item.title,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected ? Theme.of(context).colorScheme.primary : null,
          ),
        ),
        onTap: () {
          // Use context.go() to replace route instead of pushing
          // This ensures the sidebar persists
          final currentRouteState = GoRouterState.of(context);
          final baseCurrentRoute = getBaseRoute(currentRouteState.uri.path);

          // Only navigate if it's a different route
          if (item.route != baseCurrentRoute) {
            context.go(item.route);
          } else {
            // Force reload if clicking the same route
            // Append a timestamp to force GoRouter/Riverpod to register a change
            final uri = Uri.tryParse(item.route);
            if (uri != null) {
              final newUri = uri.replace(
                queryParameters: {
                  ...uri.queryParameters,
                  'refresh': DateTime.now().millisecondsSinceEpoch.toString(),
                },
              );
              context.go(newUri.toString());
            }
          }
        },
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        hoverColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
      ),
    );
  }

  Widget _buildUserMenu(BuildContext context, WidgetRef ref, adminUser) {
    return Consumer(
      builder: (context, ref, _) {
        final admin = ref.watch(currentAdminProvider);
        return PopupMenuButton<String>(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  child: Text(
                    admin?.name.substring(0, 1).toUpperCase() ?? 'A',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  admin?.name ?? 'Admin',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          onSelected: (value) async {
            if (value == 'logout') {
              await ref.read(adminAuthControllerProvider.notifier).signOut();
              if (context.mounted) {
                context.goNamed('admin-login');
              }
            }
          },
          itemBuilder:
              (context) => [
                const PopupMenuItem(
                  value: 'logout',
                  child: Row(
                    children: [
                      Icon(Ionicons.log_out_outline),
                      SizedBox(width: 8),
                      Text('Sign Out'),
                    ],
                  ),
                ),
              ],
        );
      },
    );
  }
}
