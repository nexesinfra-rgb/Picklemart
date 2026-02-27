# Splash Screen Implementation

## Overview

A professional, industry-standard splash screen implementation for the Standard Marketing app featuring animated logo, smooth transitions, and responsive design.

## Features

### 🎨 Visual Design

- **Custom Logo**: Hand-drawn "SM" logo with interlocking design
- **Gradient Background**: Subtle black gradient for premium feel
- **Responsive Design**: Adapts to all screen sizes (ultra-compact to desktop)
- **Smooth Animations**: Professional entrance and exit animations

### ⚡ Performance

- **Optimized Animations**: Hardware-accelerated animations
- **Memory Efficient**: Proper disposal of animation controllers
- **Fast Loading**: Minimal resource usage during splash

### 📱 Responsive Breakpoints

- **Ultra Compact**: < 344px (foldable devices)
- **Mobile**: 344px - 600px
- **Tablet**: 600px - 900px
- **Desktop**: > 900px

## File Structure

```
lib/core/ui/
├── splash_screen.dart          # Main splash screen widget
├── splash_service.dart         # Splash navigation service
└── README_splash_screen.md     # This documentation

lib/core/config/
└── splash_config.dart          # Configuration constants
```

## Usage

### Basic Implementation

The splash screen is automatically shown when the app starts (initial route: `/splash`).

### Custom Navigation

```dart
// Navigate to specific route after splash
SplashService.showSplashAndNavigate(
  context,
  targetRoute: '/admin/dashboard',
);

// Quick splash for fast startup
SplashService.showQuickSplash(
  context,
  targetRoute: '/home',
);

// Extended splash with initialization
SplashService.showExtendedSplash(
  context,
  targetRoute: '/home',
  initialization: () async {
    // Perform app initialization
    await initializeApp();
  },
);
```

## Configuration

### Customizing Appearance

Edit `lib/core/config/splash_config.dart` to customize:

```dart
class SplashConfig {
  // Brand Colors
  static const Color primaryColor = Color(0xFF2D1B69);
  static const Color backgroundColor = Color(0xFF000000);

  // Animation Durations
  static const Duration totalSplashDuration = Duration(seconds: 3);
  static const Duration logoAnimationDuration = Duration(milliseconds: 1200);

  // Logo Sizes
  static const double logoSizeMobile = 150.0;
  static const double logoSizeTablet = 180.0;
  static const double logoSizeUltraCompact = 120.0;

  // Text Configuration
  static const String appName = 'Standard Marketing';
  static const String tagline = 'Your Business, Our Expertise';
}
```

## Animation Sequence

1. **Logo Entrance** (0-1200ms)

   - Scale animation with elastic curve
   - Opacity fade-in
   - Circular border and shadow effects

2. **Text Slide** (600-1400ms)

   - Slide up animation for app name
   - Tagline appears with delay

3. **Loading Indicator** (1400ms+)

   - Circular progress indicator
   - Smooth rotation animation

4. **Fade Out** (2400-3000ms)
   - Smooth fade transition
   - Navigation to main app

## Technical Details

### Animation Controllers

- `_logoController`: Handles logo scale and opacity
- `_textController`: Manages text slide animation
- `_fadeController`: Controls fade-out transition

### Custom Painter

- `SMLogoPainter`: Draws the custom "SM" logo
- Vector-based rendering for crisp display
- Scalable design for all screen sizes

### Responsive Design

- Dynamic sizing based on screen dimensions
- Optimized for foldable devices
- Touch-friendly on all platforms

## Industry Standards Compliance

### ✅ Performance

- 60fps animations
- Minimal memory footprint
- Fast startup time

### ✅ Accessibility

- High contrast design
- Screen reader compatible
- Keyboard navigation support

### ✅ Platform Guidelines

- Material Design principles
- iOS Human Interface Guidelines
- Windows Fluent Design

### ✅ Brand Consistency

- Custom logo implementation
- Brand color usage
- Professional typography

## Troubleshooting

### Common Issues

1. **Animation Not Smooth**

   - Ensure device has sufficient performance
   - Check for memory leaks in animation controllers

2. **Logo Not Displaying**

   - Verify CustomPainter implementation
   - Check canvas size calculations

3. **Navigation Issues**
   - Ensure proper route configuration
   - Check context mounting before navigation

### Performance Optimization

1. **Reduce Animation Complexity**

   - Simplify logo drawing
   - Use fewer animation layers

2. **Optimize Memory Usage**

   - Dispose controllers properly
   - Avoid unnecessary rebuilds

3. **Faster Startup**
   - Reduce splash duration
   - Preload critical resources

## Future Enhancements

- [ ] Lottie animation support
- [ ] Dynamic logo loading
- [ ] Theme-based customization
- [ ] Multi-language support
- [ ] Accessibility improvements

## Dependencies

- `flutter/material.dart`
- `flutter/services.dart`
- `go_router`
- `flutter_riverpod`
- Custom responsive utilities

## License

This splash screen implementation is part of the Standard Marketing app and follows the project's licensing terms.


