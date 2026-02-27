import 'package:flutter/material.dart';
import 'responsive.dart';
import '../../features/catalog/presentation/widgets/universal_product_card.dart';

/// Enhanced responsive grid system with proper breakpoints and overflow prevention
class ResponsiveGrid {
  /// Get responsive grid configuration based on screen width
  static ResponsiveGridConfig getGridConfig(double width) {
    final bp = Responsive.breakpointForWidth(width);
    final isUltraCompact = Responsive.isUltraCompact(width);
    final isSingleColumn = Responsive.isSingleColumnMobile(width);
    final dynamicAspectRatio = UniversalProductCard.getCardAspectRatio(width);

    if (isUltraCompact) {
      return ResponsiveGridConfig(
        crossAxisCount: 1,
        childAspectRatio: 0.85, // Taller for single column mobile (was 1.5)
        crossAxisSpacing: 8.0,
        mainAxisSpacing: 8.0,
        padding: 12.0,
        maxCardWidth: (width - 24.0),
        maxCardHeight: 450.0,
        isHorizontal: false,
      );
    }

    switch (bp) {
      case AppBreakpoint.compact:
        return ResponsiveGridConfig(
          crossAxisCount: 2,
          childAspectRatio: dynamicAspectRatio,
          crossAxisSpacing: 12.0,
          mainAxisSpacing: 12.0,
          padding: 4.0,
          maxCardWidth: ((width - 20.0) / 2) * 1.2,
          maxCardHeight: 240.0,
          isHorizontal: false,
        );
      case AppBreakpoint.medium:
        return ResponsiveGridConfig(
          crossAxisCount: 3,
          childAspectRatio: dynamicAspectRatio,
          crossAxisSpacing: 16.0,
          mainAxisSpacing: 16.0,
          padding: 20.0,
          maxCardWidth: ((width - 80.0) / 3) * 1.2,
          maxCardHeight: 264.0,
          isHorizontal: false,
        );
      case AppBreakpoint.expanded:
        return ResponsiveGridConfig(
          crossAxisCount: 4,
          childAspectRatio: dynamicAspectRatio,
          crossAxisSpacing: 20.0,
          mainAxisSpacing: 20.0,
          padding: 24.0,
          maxCardWidth: ((width - 120.0) / 4) * 1.2,
          maxCardHeight: 288.0,
          isHorizontal: false,
        );
    }
  }

  // Masonry grid delegate will be implemented when package issues are resolved
  // static SliverStaggeredGridDelegate getMasonryDelegate(double width) {
  //   final config = getGridConfig(width);
  //
  //   if (config.isHorizontal) {
  //     return SliverStaggeredGridDelegateWithFixedCrossAxisCount(
  //       crossAxisCount: config.crossAxisCount,
  //       mainAxisSpacing: config.mainAxisSpacing,
  //       crossAxisSpacing: config.crossAxisSpacing,
  //       staggeredTileBuilder: (index) => const StaggeredTile.fit(1),
  //     );
  //   }

  //   return SliverStaggeredGridDelegateWithFixedCrossAxisCount(
  //     crossAxisCount: config.crossAxisCount,
  //     mainAxisSpacing: config.mainAxisSpacing,
  //     crossAxisSpacing: config.crossAxisSpacing,
  //     staggeredTileBuilder: (index) => StaggeredTile.fit(1),
  //   );
  // }

  /// Get standard grid delegate for consistent layout
  static SliverGridDelegate getStandardDelegate(double width) {
    final config = getGridConfig(width);

    if (config.isHorizontal) {
      return SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: config.crossAxisCount,
        childAspectRatio: config.childAspectRatio,
        crossAxisSpacing: config.crossAxisSpacing,
        mainAxisSpacing: config.mainAxisSpacing,
      );
    }

    return SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: config.crossAxisCount,
      childAspectRatio: config.childAspectRatio,
      crossAxisSpacing: config.crossAxisSpacing,
      mainAxisSpacing: config.mainAxisSpacing,
    );
  }

  /// Get responsive padding for containers
  static EdgeInsets getResponsivePadding(double width) {
    final config = getGridConfig(width);
    return EdgeInsets.all(config.padding);
  }

  /// Get responsive spacing between elements
  static double getResponsiveSpacing(double width) {
    final config = getGridConfig(width);
    return config.crossAxisSpacing;
  }
}

/// Configuration class for responsive grid settings
class ResponsiveGridConfig {
  final int crossAxisCount;
  final double childAspectRatio;
  final double crossAxisSpacing;
  final double mainAxisSpacing;
  final double padding;
  final double maxCardWidth;
  final double maxCardHeight;
  final bool isHorizontal;

  const ResponsiveGridConfig({
    required this.crossAxisCount,
    required this.childAspectRatio,
    required this.crossAxisSpacing,
    required this.mainAxisSpacing,
    required this.padding,
    required this.maxCardWidth,
    required this.maxCardHeight,
    required this.isHorizontal,
  });
}

/// Enhanced breakpoint system with better mobile/tablet/desktop handling
class ResponsiveBreakpoints {
  // Mobile breakpoints
  static const double mobileSmall = 288;
  static const double mobileMedium = 375;
  static const double mobileLarge = 414;

  // Tablet breakpoints
  static const double tabletSmall = 600;
  static const double tabletMedium = 768;
  static const double tabletLarge = 900;

  // Desktop breakpoints
  static const double desktopSmall = 1024;
  static const double desktopMedium = 1200;
  static const double desktopLarge = 1440;

  /// Get detailed breakpoint information
  static ResponsiveBreakpointInfo getBreakpointInfo(double width) {
    if (width < mobileSmall) {
      return ResponsiveBreakpointInfo(
        type: ResponsiveBreakpointType.ultraCompact,
        columns: 1,
        isHorizontal: true,
        maxWidth: width,
      );
    } else if (width < mobileMedium) {
      return ResponsiveBreakpointInfo(
        type: ResponsiveBreakpointType.mobileSmall,
        columns: 1,
        isHorizontal: true,
        maxWidth: width,
      );
    } else if (width < mobileLarge) {
      return ResponsiveBreakpointInfo(
        type: ResponsiveBreakpointType.mobileMedium,
        columns: 2,
        isHorizontal: false,
        maxWidth: width,
      );
    } else if (width < tabletSmall) {
      return ResponsiveBreakpointInfo(
        type: ResponsiveBreakpointType.mobileLarge,
        columns: 2,
        isHorizontal: false,
        maxWidth: width,
      );
    } else if (width < tabletMedium) {
      return ResponsiveBreakpointInfo(
        type: ResponsiveBreakpointType.tabletSmall,
        columns: 3,
        isHorizontal: false,
        maxWidth: width,
      );
    } else if (width < tabletLarge) {
      return ResponsiveBreakpointInfo(
        type: ResponsiveBreakpointType.tabletMedium,
        columns: 3,
        isHorizontal: false,
        maxWidth: width,
      );
    } else if (width < desktopSmall) {
      return ResponsiveBreakpointInfo(
        type: ResponsiveBreakpointType.tabletLarge,
        columns: 4,
        isHorizontal: false,
        maxWidth: width,
      );
    } else if (width < desktopMedium) {
      return ResponsiveBreakpointInfo(
        type: ResponsiveBreakpointType.desktopSmall,
        columns: 4,
        isHorizontal: false,
        maxWidth: width,
      );
    } else if (width < desktopLarge) {
      return ResponsiveBreakpointInfo(
        type: ResponsiveBreakpointType.desktopMedium,
        columns: 5,
        isHorizontal: false,
        maxWidth: width,
      );
    } else {
      return ResponsiveBreakpointInfo(
        type: ResponsiveBreakpointType.desktopLarge,
        columns: 6,
        isHorizontal: false,
        maxWidth: width,
      );
    }
  }
}

enum ResponsiveBreakpointType {
  ultraCompact,
  mobileSmall,
  mobileMedium,
  mobileLarge,
  tabletSmall,
  tabletMedium,
  tabletLarge,
  desktopSmall,
  desktopMedium,
  desktopLarge,
}

class ResponsiveBreakpointInfo {
  final ResponsiveBreakpointType type;
  final int columns;
  final bool isHorizontal;
  final double maxWidth;

  const ResponsiveBreakpointInfo({
    required this.type,
    required this.columns,
    required this.isHorizontal,
    required this.maxWidth,
  });
}
