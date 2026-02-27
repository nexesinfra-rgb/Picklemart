import 'package:flutter/material.dart';
import '../layout/responsive.dart';

/// Reusable SafeArea wrapper with responsive padding
/// Handles notches, status bars, and navigation bars properly across all breakpoints
class SafeScaffold extends StatelessWidget {
  final Widget body;
  final AppBar? appBar;
  final Widget? floatingActionButton;
  final Widget? bottomNavigationBar;
  final Widget? drawer;
  final Widget? endDrawer;
  final Color? backgroundColor;
  final bool resizeToAvoidBottomInset;
  final bool extendBody;
  final bool extendBodyBehindAppBar;

  const SafeScaffold({
    super.key,
    required this.body,
    this.appBar,
    this.floatingActionButton,
    this.bottomNavigationBar,
    this.drawer,
    this.endDrawer,
    this.backgroundColor,
    this.resizeToAvoidBottomInset = true,
    this.extendBody = false,
    this.extendBodyBehindAppBar = false,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final bp = Responsive.breakpointForWidth(width);

    // Get responsive SafeArea padding
    final EdgeInsets safeAreaPadding = _getSafeAreaPadding(bp);

    return Scaffold(
      appBar: appBar,
      body: SafeArea(
        top: true,
        bottom: true,
        left: true,
        right: true,
        minimum: safeAreaPadding,
        child: body,
      ),
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: bottomNavigationBar,
      drawer: drawer,
      endDrawer: endDrawer,
      backgroundColor: backgroundColor,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      extendBody: extendBody,
      extendBodyBehindAppBar: extendBodyBehindAppBar,
    );
  }

  EdgeInsets _getSafeAreaPadding(AppBreakpoint bp) {
    switch (bp) {
      case AppBreakpoint.compact:
        // Mobile: Compact spacing
        return const EdgeInsets.symmetric(horizontal: 16, vertical: 8);
      case AppBreakpoint.medium:
        // Tablet: Medium spacing
        return const EdgeInsets.symmetric(horizontal: 24, vertical: 12);
      case AppBreakpoint.expanded:
        // Desktop: Comfortable spacing
        return const EdgeInsets.symmetric(horizontal: 32, vertical: 16);
    }
  }
}

/// Helper extension for responsive padding utilities
extension ResponsiveSafeArea on BuildContext {
  /// Get responsive padding based on current screen size
  EdgeInsets get responsivePadding {
    final width = MediaQuery.of(this).size.width;
    return Responsive.getResponsivePadding(width);
  }

  /// Get responsive section spacing
  double get responsiveSpacing {
    final width = MediaQuery.of(this).size.width;
    return Responsive.getResponsiveSpacing(width);
  }

  /// Get responsive card padding
  double get responsiveCardPadding {
    final width = MediaQuery.of(this).size.width;
    if (width < 600) return 16.0;
    if (width < 1024) return 20.0;
    return 24.0;
  }

  /// Get responsive section spacing
  double get responsiveSectionSpacing {
    final width = MediaQuery.of(this).size.width;
    if (width < 600) return 16.0;
    if (width < 1024) return 24.0;
    return 32.0;
  }
}







