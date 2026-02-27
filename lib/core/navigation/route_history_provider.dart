import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider to track navigation history as a stack when navigating between tabs
/// This helps maintain navigation context when using context.go() which replaces routes
/// Note: Using a unique name to avoid hot reload issues when type changes
final routeHistoryStackProvider = StateProvider<List<String>>((ref) => []);

/// Maximum stack size to prevent memory issues
const int _maxStackSize = 20;

/// Helper to update the route history
class RouteHistoryHelper {
  /// Save the current route as history before navigating to a new route
  /// Pushes the route onto the stack, preventing duplicate consecutive routes
  static void saveCurrentRoute(WidgetRef ref, String currentRoute) {
    final stack = ref.read(routeHistoryStackProvider);
    
    // Don't add if it's the same as the last route in the stack (prevent duplicates)
    if (stack.isNotEmpty && stack.last == currentRoute) {
      return;
    }
    
    // Create a new list with the route added
    final newStack = [...stack, currentRoute];
    
    // Limit stack size to prevent memory issues
    if (newStack.length > _maxStackSize) {
      newStack.removeAt(0); // Remove oldest entry
    }
    
    ref.read(routeHistoryStackProvider.notifier).state = newStack;
  }

  /// Get the previous route from history and remove it from the stack
  /// Returns null if the stack is empty
  static String? popPreviousRoute(WidgetRef ref) {
    final stack = ref.read(routeHistoryStackProvider);
    if (stack.isEmpty) {
      return null;
    }
    
    // Pop the last route from the stack
    final previousRoute = stack.removeLast();
    ref.read(routeHistoryStackProvider.notifier).state = List.from(stack);
    
    return previousRoute;
  }

  /// Get the previous route from history without removing it
  /// Returns null if the stack is empty
  static String? getPreviousRoute(WidgetRef ref) {
    final stack = ref.read(routeHistoryStackProvider);
    if (stack.isEmpty) {
      return null;
    }
    return stack.last;
  }

  /// Clear the route history
  static void clearHistory(WidgetRef ref) {
    ref.read(routeHistoryStackProvider.notifier).state = [];
  }

  /// Remove all occurrences of a specific route from the stack
  /// Useful when navigating from nested routes (e.g., product detail → cart)
  static void removeRouteFromStack(WidgetRef ref, String route) {
    final stack = ref.read(routeHistoryStackProvider);
    final newStack = stack.where((r) => r != route).toList();
    ref.read(routeHistoryStackProvider.notifier).state = newStack;
  }
}

