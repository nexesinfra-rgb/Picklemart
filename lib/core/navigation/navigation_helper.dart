import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'route_history_provider.dart';

/// Navigation helper utility for contextual fallback routes
class NavigationHelper {
  /// Returns the appropriate fallback route based on the current route
  /// 
  /// This is used when the navigation stack is broken (context.canPop() returns false)
  /// and we need to provide a logical fallback destination instead of always going to home.
  /// 
  /// If [ref] is provided, checks route history first before falling back to defaults.
  static String getContextualFallbackRoute(
    String currentRoute, {
    WidgetRef? ref,
  }) {
    // Normalize the route (remove query parameters and trailing slashes)
    final normalizedRoute = currentRoute.split('?').first.replaceAll(RegExp(r'/$'), '');
    
    // If ref is provided, check route history first
    if (ref != null) {
      final previousRoute = RouteHistoryHelper.getPreviousRoute(ref);
      if (previousRoute != null && previousRoute.isNotEmpty) {
        // Normalize previous route
        final normalizedPrevious = previousRoute.split('?').first.replaceAll(RegExp(r'/$'), '');
        
        // For orders, if previous route was catalog, return to catalog
        if (normalizedRoute == '/orders' && normalizedPrevious == '/catalog') {
          return '/catalog';
        }
        
        // For other cases, if previous route is a valid main tab route, use it
        if (['/home', '/catalog', '/cart', '/orders', '/profile'].contains(normalizedPrevious)) {
          return normalizedPrevious;
        }
      }
    }
    
    // Map routes to their contextual fallbacks
    switch (normalizedRoute) {
      case '/search':
        // Navigate back to home when back button is pressed
        return '/home';
      
      case '/cart':
      case '/orders':
      case '/profile':
      case '/catalog':
        // These main screens can fallback to home
        return '/home';
      
      default:
        // Default fallback for any other route
        return '/home';
    }
  }
  
  /// Handles back button navigation with contextual fallback
  /// 
  /// Tries to pop the navigation stack first. If that's not possible,
  /// uses the route history stack to navigate back. If the stack is empty,
  /// navigates to a contextual fallback route based on the current location.
  /// 
  /// If [ref] is provided, will check route history stack to determine the best fallback.
  static void handleBackNavigation(
    BuildContext context, {
    WidgetRef? ref,
  }) {
    // First, try to use the native navigation stack
    if (context.canPop()) {
      context.pop();
      return;
    }
    
    // Get current route from GoRouterState
    final state = GoRouterState.of(context);
    final currentRoute = state.uri.path;
    
    // If we have route history, use it
    if (ref != null) {
      final previousRoute = RouteHistoryHelper.popPreviousRoute(ref);
      if (previousRoute != null && previousRoute.isNotEmpty) {
        // Normalize the previous route
        final normalizedPrevious = previousRoute.split('?').first.replaceAll(RegExp(r'/$'), '');
        final normalizedCurrent = currentRoute.split('?').first.replaceAll(RegExp(r'/$'), '');
        
        // Prevent infinite loops - don't navigate to the same route
        if (normalizedPrevious != normalizedCurrent) {
          context.go(previousRoute);
          return;
        }
      }
    }
    
    // Fallback to contextual route if stack is empty or same route
    final fallbackRoute = getContextualFallbackRoute(currentRoute, ref: ref);
    context.go(fallbackRoute);
  }
}

