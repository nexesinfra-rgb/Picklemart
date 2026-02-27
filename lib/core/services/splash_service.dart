import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SplashService {
  static const Duration _splashDuration = Duration(seconds: 10);
  static const Duration _minimumSplashDuration = Duration(seconds: 8);

  /// Shows splash screen and navigates to the appropriate screen
  static Future<void> showSplashAndNavigate(
    BuildContext context, {
    String? targetRoute,
    Duration? customDuration,
  }) async {
    final startTime = DateTime.now();

    // Navigate to splash screen
    if (context.mounted) {
      context.go('/splash');
    }

    // Wait for minimum splash duration
    await Future.delayed(_minimumSplashDuration);

    // Calculate remaining time to reach total duration
    final elapsed = DateTime.now().difference(startTime);
    final remaining = _splashDuration - elapsed;

    if (remaining.inMilliseconds > 0) {
      await Future.delayed(remaining);
    }

    // Navigate to target route
    if (context.mounted) {
      final route = targetRoute ?? _getDefaultRoute();
      context.go(route);
    }
  }

  /// Determines the default route based on app state
  static String _getDefaultRoute() {
    // In a real app, you would check authentication state here
    // For now, we'll go to the role selection screen
    return '/';
  }

  /// Quick splash for fast app startup
  static Future<void> showQuickSplash(
    BuildContext context, {
    String? targetRoute,
  }) async {
    if (context.mounted) {
      context.go('/splash');
    }

    await Future.delayed(const Duration(milliseconds: 1500));

    if (context.mounted) {
      final route = targetRoute ?? _getDefaultRoute();
      context.go(route);
    }
  }

  /// Extended splash for app initialization
  static Future<void> showExtendedSplash(
    BuildContext context, {
    String? targetRoute,
    required Future<void> Function() initialization,
  }) async {
    if (context.mounted) {
      context.go('/splash');
    }

    // Run initialization tasks
    await initialization();

    // Ensure minimum splash time
    await Future.delayed(_minimumSplashDuration);

    if (context.mounted) {
      final route = targetRoute ?? _getDefaultRoute();
      context.go(route);
    }
  }
}
