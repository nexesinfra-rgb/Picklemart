import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ionicons/ionicons.dart';
import '../../../auth/application/auth_controller.dart';
import '../../application/wishlist_providers.dart';

/// Heart button widget for adding/removing products from wishlist
/// Positioned absolutely on product card image
class WishlistHeartButton extends ConsumerStatefulWidget {
  final String productId;
  final double? size;
  final Color? color;
  final double? top;
  final double? right;

  const WishlistHeartButton({
    super.key,
    required this.productId,
    this.size,
    this.color,
    this.top,
    this.right,
  });

  @override
  ConsumerState<WishlistHeartButton> createState() =>
      _WishlistHeartButtonState();
}

class _WishlistHeartButtonState extends ConsumerState<WishlistHeartButton> {
  bool _isProcessing = false;

  Future<void> _toggleWishlist() async {
    final authState = ref.read(authControllerProvider);
    if (!authState.isAuthenticated) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Please log in to add items to your purchase later list',
            ),
            duration: Duration(seconds: 2),
          ),
        );
      }
      return;
    }

    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      final controller = ref.read(wishlistControllerProvider.notifier);
      final isInWishlist = controller.isInWishlist(widget.productId);

      bool success;
      if (isInWishlist) {
        success = await controller.removeFromWishlist(widget.productId);
        if (mounted && success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Removed from purchase later'),
              duration: Duration(seconds: 1),
            ),
          );
        }
      } else {
        success = await controller.addToWishlist(widget.productId);
        if (mounted && success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Added to purchase later'),
              duration: Duration(seconds: 1),
            ),
          );
        }
      }

      if (mounted && !success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to update purchase later list'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isInWishlist = ref.watch(
      isProductInWishlistProvider(widget.productId),
    );
    final size = widget.size ?? 24.0;
    final color = widget.color ?? Colors.red;
    final top = widget.top ?? 8.0;
    final right = widget.right ?? 8.0;

    return Positioned(
      top: top,
      right: right,
      child: GestureDetector(
        onTap: _toggleWishlist,
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.9),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child:
              _isProcessing
                  ? SizedBox(
                    width: size * 0.6,
                    height: size * 0.6,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                    ),
                  )
                  : Icon(
                    isInWishlist ? Ionicons.heart : Ionicons.heart_outline,
                    size: size,
                    color: isInWishlist ? color : Colors.grey[600],
                  ),
        ),
      ),
    );
  }
}
