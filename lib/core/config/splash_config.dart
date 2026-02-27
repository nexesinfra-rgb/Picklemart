import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SplashConfig {
  // Brand Colors
  static const Color primaryColor = Color(0xFF2D1B69);
  static const Color secondaryColor = Color(0xFF1a1a1a);
  static const Color backgroundColor = Color(0xFF000000);
  static const Color textColor = Colors.white;
  static const Color accentColor = Color(0xFF2D1B69);

  // Animation Durations
  static const Duration logoAnimationDuration = Duration(milliseconds: 1500);
  static const Duration textAnimationDuration = Duration(milliseconds: 1000);
  static const Duration fadeAnimationDuration = Duration(milliseconds: 800);
  static const Duration totalSplashDuration = Duration(seconds: 10);
  static const Duration minimumSplashDuration = Duration(seconds: 8);

  // Logo Configuration
  static const double logoSizeMobile = 200.0;
  static const double logoSizeTablet = 250.0;
  static const double logoSizeUltraCompact = 160.0;
  static const double logoBorderWidth = 4.0;
  static const double logoShadowBlur = 30.0;
  static const double logoShadowSpread = 8.0;

  // Text Configuration
  static const String appName = 'Pickle Mart';
  static const String tagline = 'Your Business, Our Expertise';
  static const String teluguTagline = 'తెలుగింటి సాంప్రదాయ తయారీ ఫుడ్స్';
  static const double appNameFontSizeMobile = 24.0;
  static const double appNameFontSizeTablet = 28.0;
  static const double appNameFontSizeUltraCompact = 20.0;
  static const double taglineFontSizeMobile = 14.0;
  static const double taglineFontSizeTablet = 16.0;
  static const double taglineFontSizeUltraCompact = 12.0;
  static const double teluguTaglineFontSizeMobile = 16.0;
  static const double teluguTaglineFontSizeTablet = 18.0;
  static const double teluguTaglineFontSizeUltraCompact = 14.0;
  static const double letterSpacing = 2.0;
  static const double taglineLetterSpacing = 1.0;

  // Loading Indicator
  static const double loadingIndicatorSizeMobile = 40.0;
  static const double loadingIndicatorSizeUltraCompact = 30.0;
  static const double loadingIndicatorStrokeWidth = 2.0;

  // Responsive Breakpoints
  static const double ultraCompactBreakpoint = 344.0;
  static const double mobileBreakpoint = 600.0;
  static const double tabletBreakpoint = 900.0;

  // Animation Curves
  static const Curve logoScaleCurve = Curves.elasticOut;
  static const Curve logoOpacityCurve = Curves.easeIn;
  static const Curve textSlideCurve = Curves.easeOutCubic;
  static const Curve fadeCurve = Curves.easeInOut;

  // Gradient Configuration
  static const List<Color> backgroundGradientColors = [
    Color(0xFF000000),
    Color(0xFF1a1a1a),
    Color(0xFF000000),
  ];
  static const List<double> backgroundGradientStops = [0.0, 0.5, 1.0];

  // Status Bar Configuration
  static const SystemUiOverlayStyle statusBarStyle = SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarIconBrightness: Brightness.light,
  );

  // Logo Circle Configuration
  static const double logoCircleOpacity = 0.3;
  static const double logoGradientOpacity = 0.1;
  static const double logoGradientStop = 0.7;

  // Text Opacity
  static const double taglineOpacity = 0.7;
  static const double loadingIndicatorOpacity = 0.8;
}
