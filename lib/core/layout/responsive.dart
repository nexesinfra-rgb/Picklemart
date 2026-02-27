import 'package:flutter/material.dart';

enum AppBreakpoint { compact, medium, expanded }

enum ScreenSize { mobile, tablet, desktop }

enum FoldableBreakpoint { ultraCompact, compact, medium, expanded, large }

class Responsive {
  static AppBreakpoint breakpointForWidth(double width) {
    if (width >= 1024) return AppBreakpoint.expanded;
    if (width >= 600) return AppBreakpoint.medium;
    return AppBreakpoint.compact;
  }

  static int columnsForWidth(double width) {
    switch (breakpointForWidth(width)) {
      case AppBreakpoint.compact:
        return 2;
      case AppBreakpoint.medium:
        return 3;
      case AppBreakpoint.expanded:
        return 5;
    }
  }

  // Target max width for a product card to avoid oversized cards on desktop
  static double gridMaxExtent(double width) {
    switch (breakpointForWidth(width)) {
      case AppBreakpoint.compact:
        return 270; // ~2 columns on phones (Original 180 * 1.5)
      case AppBreakpoint.medium:
        return 330; // 3–4 columns on tablets (Original 220 * 1.5)
      case AppBreakpoint.expanded:
        return 360; // 5–6 columns on desktop (Original 240 * 1.5)
    }
  }

  // Ultra-narrow devices (e.g., fold cover screens).
  static bool isUltraCompact(double width) => width < 288;
  // Single-column mobile breakpoint (request: <= 320px use 1 card/row)
  static bool isSingleColumnMobile(double width) => width <= 320;

  // Enhanced responsive utilities
  static bool isMobile(double width) => width < 600;
  static bool isTablet(double width) => width >= 600 && width < 1024;
  static bool isDesktop(double width) => width >= 1024;

  // Get responsive padding based on screen width
  static EdgeInsets getResponsivePadding(double width) {
    if (width < 600) {
      return const EdgeInsets.all(16.0);
    } else if (width < 1024) {
      return const EdgeInsets.all(20.0);
    } else {
      return const EdgeInsets.all(24.0);
    }
  }

  /// More compact content padding for primary screens like the Home page.
  /// Keeps vertical padding comfortable while reducing left/right space.
  static EdgeInsets getHomeContentPadding(double width) {
    if (width < 600) {
      return const EdgeInsets.symmetric(horizontal: 8.0, vertical: 16.0);
    } else if (width < 1024) {
      return const EdgeInsets.symmetric(horizontal: 12.0, vertical: 20.0);
    } else {
      return const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0);
    }
  }

  // Get responsive spacing based on screen width
  static double getResponsiveSpacing(double width) {
    if (width < 600) {
      return 12.0;
    } else if (width < 1024) {
      return 16.0;
    } else {
      return 20.0;
    }
  }

  // Get screen size based on width
  static ScreenSize getScreenSize(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width >= 1024) return ScreenSize.desktop;
    if (width >= 600) return ScreenSize.tablet;
    return ScreenSize.mobile;
  }

  // Get foldable breakpoint for specific device handling
  static FoldableBreakpoint getFoldableBreakpoint(double width) {
    if (width >= 1200) return FoldableBreakpoint.large;
    if (width >= 882) return FoldableBreakpoint.expanded;
    if (width >= 600) return FoldableBreakpoint.medium;
    if (width >= 288) return FoldableBreakpoint.compact;
    return FoldableBreakpoint.ultraCompact;
  }

  // Check if device is foldable mobile (specific breakpoints)
  static bool isFoldableMobile(double width) {
    return width >= 288 && width < 600;
  }

  // Check if device is ultra compact (very small screens)
  static bool isUltraCompactDevice(double width) {
    return width < 288;
  }

  // Get appropriate columns for foldable devices
  static int getColumnsForFoldable(double width) {
    final breakpoint = getFoldableBreakpoint(width);
    switch (breakpoint) {
      case FoldableBreakpoint.ultraCompact:
        return 1;
      case FoldableBreakpoint.compact:
        return 2;
      case FoldableBreakpoint.medium:
        return 3;
      case FoldableBreakpoint.expanded:
        return 4;
      case FoldableBreakpoint.large:
        return 5;
    }
  }

  // Get appropriate spacing for foldable devices
  static double getSpacingForFoldable(double width) {
    final breakpoint = getFoldableBreakpoint(width);
    switch (breakpoint) {
      case FoldableBreakpoint.ultraCompact:
        return 8.0;
      case FoldableBreakpoint.compact:
        return 12.0;
      case FoldableBreakpoint.medium:
        return 16.0;
      case FoldableBreakpoint.expanded:
        return 20.0;
      case FoldableBreakpoint.large:
        return 24.0;
    }
  }

  // Get SafeArea padding based on breakpoint
  static EdgeInsets getSafeAreaPadding(double width) {
    final bp = breakpointForWidth(width);
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

  // Get card padding based on breakpoint
  static double getCardPadding(double width) {
    final bp = breakpointForWidth(width);
    switch (bp) {
      case AppBreakpoint.compact:
        return 4.0;
      case AppBreakpoint.medium:
        return 20.0;
      case AppBreakpoint.expanded:
        return 24.0;
    }
  }

  // Get section spacing based on breakpoint
  static double getSectionSpacing(double width) {
    final bp = breakpointForWidth(width);
    switch (bp) {
      case AppBreakpoint.compact:
        return 16.0;
      case AppBreakpoint.medium:
        return 24.0;
      case AppBreakpoint.expanded:
        return 32.0;
    }
  }

  /// Calculate unified product card width based on Featured Products constraints
  /// Used app-wide for consistent product card sizing
  /// Mobile (< 600px): 165px (Original 110 * 1.5)
  /// Tablet (600-1024px): 360px (Original 240 * 1.5)
  /// Desktop (1024-1300px): 270px (Original 180 * 1.5)
  /// Large Desktop (≥ 1300px): 210-270px (calculated to show 8 products)
  static double getUnifiedProductCardWidth(double width) {
    if (width < 600) {
      // Mobile - 160px per card (Balanced size)
      return 160.0;
    } else if (width < 1024) {
      // Tablet - 210px per card
      return 210.0;
    } else if (width >= 1300) {
      // Large Desktop (>= 1300px) - calculate to show 8 products, but max 230px
      // Available width: width - padding (16px each side = 32px)
      // Card width: (availableWidth - spacing between 7 cards * 8px) / 8
      final availableWidth = width - 32; // 16px padding each side
      final spacingBetweenCards = 7 * 8; // 7 gaps between 8 cards, 8px each
      final calculatedWidth = (availableWidth - spacingBetweenCards) / 8;
      return calculatedWidth.clamp(190.0, 230.0); // Max 230px
    } else {
      // Desktop (1024-1300px) - 230px
      return 230.0;
    }
  }

  /// Get responsive horizontal padding for product card sections
  /// Mobile: 4px, Tablet: 12px, Desktop: 16px
  static double getProductCardSectionPadding(double width) {
    if (width < 600) {
      return 4.0;
    } else if (width < 1024) {
      return 12.0;
    } else {
      return 16.0;
    }
  }
}
