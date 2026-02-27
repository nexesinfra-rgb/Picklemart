import 'package:flutter/material.dart';
import '../layout/responsive.dart';

class ResponsiveFilledButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final bool isLoading;
  final double? width;
  final double? height;

  const ResponsiveFilledButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.isLoading = false,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final screenSize = Responsive.getScreenSize(context);

    return SizedBox(
      width:
          width ?? (screenSize == ScreenSize.mobile ? double.infinity : null),
      height: height ?? (screenSize == ScreenSize.mobile ? 48 : 44),
      child: FilledButton(
        onPressed: isLoading ? null : onPressed,
        child:
            isLoading
                ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),
                )
                : child,
      ),
    );
  }
}

class ResponsiveOutlinedButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final bool isLoading;
  final double? width;
  final double? height;

  const ResponsiveOutlinedButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.isLoading = false,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final screenSize = Responsive.getScreenSize(context);

    return SizedBox(
      width:
          width ?? (screenSize == ScreenSize.mobile ? double.infinity : null),
      height: height ?? (screenSize == ScreenSize.mobile ? 48 : 44),
      child: OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        child:
            isLoading
                ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Theme.of(context).colorScheme.primary,
                    ),
                  ),
                )
                : child,
      ),
    );
  }
}

class ResponsiveTextButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final bool isLoading;

  const ResponsiveTextButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: isLoading ? null : onPressed,
      child:
          isLoading
              ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Theme.of(context).colorScheme.primary,
                  ),
                ),
              )
              : child,
    );
  }
}

class ResponsiveIconButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget icon;
  final String? tooltip;
  final double? size;

  const ResponsiveIconButton({
    super.key,
    required this.onPressed,
    required this.icon,
    this.tooltip,
    this.size,
  });

  @override
  Widget build(BuildContext context) {
    final screenSize = Responsive.getScreenSize(context);
    final buttonSize = size ?? (screenSize == ScreenSize.mobile ? 40.0 : 36.0);

    return IconButton(
      onPressed: onPressed,
      icon: icon,
      tooltip: tooltip,
      iconSize: buttonSize * 0.6,
      style: IconButton.styleFrom(minimumSize: Size(buttonSize, buttonSize)),
    );
  }
}

class ResponsiveFloatingActionButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final String? tooltip;

  const ResponsiveFloatingActionButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final screenSize = Responsive.getScreenSize(context);

    return FloatingActionButton(
      onPressed: onPressed,
      tooltip: tooltip,
      // Adjust size based on screen size
      mini: screenSize == ScreenSize.mobile ? false : true,
      child: child,
    );
  }
}

class ResponsiveElevatedButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final bool isLoading;
  final double? width;
  final double? height;

  const ResponsiveElevatedButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.isLoading = false,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final screenSize = Responsive.getScreenSize(context);

    return SizedBox(
      width:
          width ?? (screenSize == ScreenSize.mobile ? double.infinity : null),
      height: height ?? (screenSize == ScreenSize.mobile ? 48 : 44),
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        child:
            isLoading
                ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),
                )
                : child,
      ),
    );
  }
}

class ResponsiveButtons {
  static double getFabSize(double width) {
    if (width >= 1024) return 64.0; // Desktop
    if (width >= 600) return 56.0; // Tablet
    return 48.0; // Mobile
  }
}
