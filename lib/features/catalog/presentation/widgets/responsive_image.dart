import 'package:flutter/material.dart';
import '../../../../core/layout/responsive.dart';
import '../../../../core/widgets/lazy_image.dart';

class ResponsiveImage extends StatelessWidget {
  final String imageUrl;
  final BoxFit fit;
  final Widget? errorWidget;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;

  const ResponsiveImage({
    super.key,
    required this.imageUrl,
    this.fit = BoxFit.fill,
    this.errorWidget,
    this.width,
    this.height,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final bp = Responsive.breakpointForWidth(screenWidth);

    // Get responsive dimensions
    final responsiveWidth = _getResponsiveWidth(screenWidth, bp);
    final responsiveHeight = _getResponsiveHeight(screenWidth, bp);

    return LazyImage(
      imageUrl: imageUrl,
      fit: fit,
      width: width ?? responsiveWidth,
      height: height ?? responsiveHeight,
      borderRadius: borderRadius,
      errorWidget: errorWidget,
    );
  }

  double _getResponsiveWidth(double screenWidth, AppBreakpoint bp) {
    if (bp == AppBreakpoint.compact) {
      return screenWidth < 340
          ? 120
          : screenWidth < 380
          ? 140
          : 160;
    } else if (screenWidth < 600) {
      return 150;
    } else if (screenWidth < 750) {
      return 180;
    } else if (screenWidth < 900) {
      return 200;
    } else if (screenWidth < 1200) {
      return 220;
    } else {
      return 250;
    }
  }

  double _getResponsiveHeight(double screenWidth, AppBreakpoint bp) {
    if (bp == AppBreakpoint.compact) {
      return screenWidth < 340
          ? 120
          : screenWidth < 380
          ? 140
          : 160;
    } else if (screenWidth < 600) {
      return 150;
    } else if (screenWidth < 750) {
      return 180;
    } else if (screenWidth < 900) {
      return 200;
    } else if (screenWidth < 1200) {
      return 220;
    } else {
      return 250;
    }
  }
}
