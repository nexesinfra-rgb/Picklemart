import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider that watches the current route from GoRouter
/// This keeps Riverpod state synchronized with GoRouter navigation
/// Note: This provider needs to be used within a widget that has access to GoRouterState
/// For navigation bar, we'll use GoRouterState.of(context) directly in the widget
final currentRouteProvider = Provider<String>((ref) {
  // This provider is a placeholder - actual route is obtained via GoRouterState.of(context)
  // in widgets that have BuildContext access
  // We return a default value here, but the actual usage will be in the navigation widget
  return '/admin/dashboard';
});

/// Helper to get the base route (without query parameters or nested paths)
/// Used for navigation bar index matching
String getBaseRoute(String fullRoute) {
  // Remove query parameters
  final uri = Uri.tryParse(fullRoute);
  if (uri == null) return fullRoute;

  final path = uri.path;

  // Handle nested routes - return the base admin route
  // Check for routes with nested paths first (more specific)
  if (path.startsWith('/admin/products')) {
    return '/admin/products';
  } else if (path.startsWith('/admin/orders')) {
    return '/admin/orders';
  } else if (path.startsWith('/admin/customers')) {
    return '/admin/customers';
  } else if (path.startsWith('/admin/dashboard')) {
    return '/admin/dashboard';
  } else if (path.startsWith('/admin/more')) {
    return '/admin/more';
  } else if (path.startsWith('/admin/categories')) {
    return '/admin/categories';
  } else if (path.startsWith('/admin/featured-products')) {
    return '/admin/featured-products';
  } else if (path.startsWith('/admin/analytics')) {
    return '/admin/analytics';
  } else if (path.startsWith('/admin/content')) {
    return '/admin/content';
  } else if (path.startsWith('/admin/hero-section')) {
    return '/admin/hero-section';
  } else if (path.startsWith('/admin/features')) {
    return '/admin/features';
  } else if (path.startsWith('/admin/accounts')) {
    return '/admin/accounts';
  } else if (path.startsWith('/admin/search-results')) {
    return '/admin/search-results';
  } else if (path.startsWith('/admin/inventory')) {
    return '/admin/inventory';
  } else if (path.startsWith('/admin/notifications')) {
    return '/admin/notifications';
  } else if (path.startsWith('/admin/seo')) {
    return '/admin/seo';
  } else if (path.startsWith('/admin/marketing')) {
    return '/admin/marketing';
  }

  return path;
}
