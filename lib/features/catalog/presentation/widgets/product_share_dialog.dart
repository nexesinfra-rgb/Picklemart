import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';
import '../../data/product.dart';
import '../../data/product_share_service.dart';
import '../../../../core/layout/responsive.dart';

/// Share dialog widget showing platform options
class ProductShareDialog extends StatelessWidget {
  final Product product;

  const ProductShareDialog({
    super.key,
    required this.product,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final breakpoint = Responsive.breakpointForWidth(width);

    // Get responsive values
    final iconSize = _getIconSize(breakpoint);
    final headerIconSize = _getHeaderIconSize(breakpoint);
    final containerPadding = _getContainerPadding(breakpoint);
    final gridSpacing = _getGridSpacing(breakpoint);
    final verticalPadding = _getVerticalPadding(breakpoint);
    final aspectRatio = _getAspectRatio(breakpoint);
    final iconLabelSpacing = _getIconLabelSpacing(breakpoint);

    return Container(
      padding: EdgeInsets.symmetric(
        vertical: verticalPadding,
        horizontal: containerPadding,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(
                Ionicons.share_social_outline,
                color: Theme.of(context).colorScheme.primary,
                size: headerIconSize,
              ),
              SizedBox(width: breakpoint == AppBreakpoint.compact ? 8 : 12),
              Text(
                'Share Product',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: breakpoint == AppBreakpoint.compact ? 16 : null,
                    ),
              ),
              const Spacer(),
              IconButton(
                icon: Icon(
                  Ionicons.close_outline,
                  size: breakpoint == AppBreakpoint.compact ? 20 : 24,
                ),
                onPressed: () => Navigator.of(context).pop(),
                tooltip: 'Close',
                padding: EdgeInsets.all(breakpoint == AppBreakpoint.compact ? 8 : 12),
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          SizedBox(height: breakpoint == AppBreakpoint.compact ? 16 : 20),
          // Share options - horizontal scrollable for mobile, grid for larger screens
          breakpoint == AppBreakpoint.compact
              ? _buildHorizontalScrollableRow(
                  context,
                  breakpoint: breakpoint,
                  iconSize: iconSize,
                  iconLabelSpacing: iconLabelSpacing,
                )
              : GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 3,
                  mainAxisSpacing: gridSpacing,
                  crossAxisSpacing: gridSpacing,
                  childAspectRatio: aspectRatio,
                  children: _buildShareOptionsList(
                    context,
                    breakpoint: breakpoint,
                    iconSize: iconSize,
                    iconLabelSpacing: iconLabelSpacing,
                  ),
                ),
          SizedBox(height: breakpoint == AppBreakpoint.compact ? 12 : 16),
        ],
      ),
    );
  }

  /// Get responsive icon size based on breakpoint
  double _getIconSize(AppBreakpoint breakpoint) {
    switch (breakpoint) {
      case AppBreakpoint.compact:
        return 20.0; // Mobile: compact size
      case AppBreakpoint.medium:
        return 24.0; // Tablet: compact size
      case AppBreakpoint.expanded:
        return 28.0; // Desktop: compact size
    }
  }

  /// Get responsive header icon size based on breakpoint
  double _getHeaderIconSize(AppBreakpoint breakpoint) {
    switch (breakpoint) {
      case AppBreakpoint.compact:
        return 20.0; // Mobile: compact size
      case AppBreakpoint.medium:
        return 22.0; // Tablet
      case AppBreakpoint.expanded:
        return 24.0; // Desktop
    }
  }

  /// Get responsive container padding based on breakpoint
  double _getContainerPadding(AppBreakpoint breakpoint) {
    switch (breakpoint) {
      case AppBreakpoint.compact:
        return 8.0; // Mobile - compact padding
      case AppBreakpoint.medium:
        return 10.0; // Tablet - compact padding
      case AppBreakpoint.expanded:
        return 12.0; // Desktop - compact padding
    }
  }

  /// Get responsive vertical padding based on breakpoint
  double _getVerticalPadding(AppBreakpoint breakpoint) {
    switch (breakpoint) {
      case AppBreakpoint.compact:
        return 16.0; // Mobile - reduced padding
      case AppBreakpoint.medium:
        return 18.0; // Tablet
      case AppBreakpoint.expanded:
        return 20.0; // Desktop
    }
  }

  /// Get responsive grid spacing based on breakpoint
  double _getGridSpacing(AppBreakpoint breakpoint) {
    switch (breakpoint) {
      case AppBreakpoint.compact:
        return 8.0; // Mobile - tighter spacing
      case AppBreakpoint.medium:
        return 12.0; // Tablet
      case AppBreakpoint.expanded:
        return 16.0; // Desktop
    }
  }

  /// Get responsive aspect ratio based on breakpoint
  /// Higher values make containers wider and less tall (more compact)
  double _getAspectRatio(AppBreakpoint breakpoint) {
    switch (breakpoint) {
      case AppBreakpoint.compact:
        return 1.35; // Mobile - wider, shorter, more compact
      case AppBreakpoint.medium:
        return 1.4; // Tablet - wider, shorter
      case AppBreakpoint.expanded:
        return 1.45; // Desktop - wider, shorter
    }
  }

  /// Get responsive spacing between icon and label
  double _getIconLabelSpacing(AppBreakpoint breakpoint) {
    switch (breakpoint) {
      case AppBreakpoint.compact:
        return 4.0; // Mobile - very tight spacing
      case AppBreakpoint.medium:
        return 6.0; // Tablet - tight spacing
      case AppBreakpoint.expanded:
        return 8.0; // Desktop - standard spacing
    }
  }

  /// Build horizontal scrollable row for mobile
  Widget _buildHorizontalScrollableRow(
    BuildContext context, {
    required AppBreakpoint breakpoint,
    required double iconSize,
    required double iconLabelSpacing,
  }) {
    return SizedBox(
      height: 100,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        children: _buildShareOptionsList(
          context,
          breakpoint: breakpoint,
          iconSize: iconSize,
          iconLabelSpacing: iconLabelSpacing,
        ).map((option) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: SizedBox(
            width: 70,
            child: option,
          ),
        )).toList(),
      ),
    );
  }

  /// Build list of share options
  List<Widget> _buildShareOptionsList(
    BuildContext context, {
    required AppBreakpoint breakpoint,
    required double iconSize,
    required double iconLabelSpacing,
  }) {
    return [
      _buildShareOption(
        context,
        iconColor: const Color(0xFF25D366), // WhatsApp green
        icon: Ionicons.logo_whatsapp,
        label: 'WhatsApp',
        breakpoint: breakpoint,
        iconSize: iconSize,
        iconLabelSpacing: iconLabelSpacing,
        onTap: () => _handleShare(context, SharePlatform.whatsapp),
      ),
      _buildShareOption(
        context,
        iconColor: const Color(0xFF2196F3), // Messages blue
        icon: Ionicons.chatbubble_outline,
        label: 'Messages',
        breakpoint: breakpoint,
        iconSize: iconSize,
        iconLabelSpacing: iconLabelSpacing,
        onTap: () => _handleShare(context, SharePlatform.sms),
      ),
      _buildShareOption(
        context,
        iconColor: const Color(0xFFEA4335), // Email red
        icon: Ionicons.mail_outline,
        label: 'Email',
        breakpoint: breakpoint,
        iconSize: iconSize,
        iconLabelSpacing: iconLabelSpacing,
        onTap: () => _handleShare(context, SharePlatform.email),
      ),
      _buildShareOption(
        context,
        iconColor: const Color(0xFF757575), // Copy Link gray
        icon: Ionicons.link_outline,
        label: 'Copy Link',
        breakpoint: breakpoint,
        iconSize: iconSize,
        iconLabelSpacing: iconLabelSpacing,
        onTap: () => _handleShare(context, SharePlatform.copyLink),
      ),
      _buildShareOption(
        context,
        iconColor: Theme.of(context).colorScheme.primary, // More - primary color
        icon: Ionicons.share_social_outline,
        label: 'More',
        breakpoint: breakpoint,
        iconSize: iconSize,
        iconLabelSpacing: iconLabelSpacing,
        onTap: () => _handleShare(context, SharePlatform.more),
      ),
    ];
  }

  /// Build minimal share option with colored icon (no background block)
  Widget _buildShareOption(
    BuildContext context, {
    required Color iconColor,
    required IconData icon,
    required String label,
    required AppBreakpoint breakpoint,
    required double iconSize,
    required double iconLabelSpacing,
    required VoidCallback onTap,
  }) {
    final fontSize = breakpoint == AppBreakpoint.compact ? 11.0 : 12.0;
    final buttonSize = breakpoint == AppBreakpoint.compact ? 56.0 : 64.0; // 56px ensures min 44px touch target
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(buttonSize / 2),
        splashColor: iconColor.withOpacity(0.2),
        highlightColor: iconColor.withOpacity(0.1),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Circular icon button with subtle background and smooth transitions
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              width: buttonSize,
              height: buttonSize,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: iconSize,
              ),
            ),
            SizedBox(height: iconLabelSpacing),
            // Minimal label
            Text(
              label,
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleShare(BuildContext context, SharePlatform platform) async {
    Navigator.of(context).pop(); // Close dialog first

    try {
      final success = await ProductShareService.shareProduct(product, platform);

      if (!context.mounted) return;

      if (success) {
        String message;
        switch (platform) {
          case SharePlatform.copyLink:
            message = 'Link copied to clipboard!';
            break;
          case SharePlatform.more:
            message = 'Sharing...';
            break;
          default:
            message = 'Opening ${platform.name}...';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            duration: const Duration(seconds: 2),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to share via ${platform.name}'),
            duration: const Duration(seconds: 2),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          duration: const Duration(seconds: 3),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Show share dialog as bottom sheet
  static void show(BuildContext context, Product product) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ProductShareDialog(product: product),
    );
  }
}

