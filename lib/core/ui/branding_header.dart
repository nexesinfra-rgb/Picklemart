import 'package:flutter/material.dart';
import '../layout/responsive.dart';
import '../config/splash_config.dart';

/// A reusable branding header widget that displays the company logo and name
/// following industry standards for authentication screens
class BrandingHeader extends StatelessWidget {
  const BrandingHeader({
    super.key,
    this.logoSize,
    this.spacing,
    this.textStyle,
    this.alignment = MainAxisAlignment.center,
    this.showText = true,
  });

  final double? logoSize;
  final double? spacing;
  final TextStyle? textStyle;
  final MainAxisAlignment alignment;
  final bool showText;

  @override
  Widget build(BuildContext context) {
    final screenSize = Responsive.getScreenSize(context);
    final defaultLogoSize = logoSize ?? (screenSize == ScreenSize.mobile ? 80.0 : 100.0);
    final defaultSpacing = spacing ?? (screenSize == ScreenSize.mobile ? 16.0 : 24.0);

    return Column(
      mainAxisAlignment: alignment,
      children: [
        Image.asset(
          'assets/picklemart.png',
          width: defaultLogoSize,
          height: defaultLogoSize,
          fit: BoxFit.contain,
        ),
        if (showText) SizedBox(height: defaultSpacing),
        if (showText)
          Text(
            SplashConfig.appName,
            style: textStyle ??
                Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
          ),
      ],
    );
  }
}

/// A compact version of the branding header for smaller spaces
class CompactBrandingHeader extends StatelessWidget {
  const CompactBrandingHeader({
    super.key,
    this.logoSize,
    this.spacing,
    this.textStyle,
  });

  final double? logoSize;
  final double? spacing;
  final TextStyle? textStyle;

  @override
  Widget build(BuildContext context) {
    final screenSize = Responsive.getScreenSize(context);
    final defaultLogoSize = logoSize ?? (screenSize == ScreenSize.mobile ? 40.0 : 50.0);
    final defaultSpacing = spacing ?? 12.0;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Image.asset(
          'assets/picklemart.png',
          width: defaultLogoSize,
          height: defaultLogoSize,
          fit: BoxFit.contain,
        ),
        SizedBox(width: defaultSpacing),
        Flexible(
          child: Text(
            SplashConfig.appName,
            style: textStyle ??
                Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}


