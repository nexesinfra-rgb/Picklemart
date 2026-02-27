import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';
import '../../../../core/layout/responsive.dart';
import '../../../../core/widgets/lazy_image.dart';
import '../../data/product.dart';
import 'fullscreen_image_viewer.dart';
import 'product_share_dialog.dart';

class ImageGallery extends StatefulWidget {
  final List<String> images;
  final Product? product; // Optional product for sharing
  const ImageGallery({
    super.key,
    required this.images,
    this.product,
  });

  @override
  State<ImageGallery> createState() => _ImageGalleryState();
}

class _ImageGalleryState extends State<ImageGallery> {
  final _controller = PageController();
  int _index = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bp = Responsive.breakpointForWidth(MediaQuery.of(context).size.width);
    final showArrows = bp != AppBreakpoint.compact;

    return Column(
      children: [
        AspectRatio(
          aspectRatio: 1,
          child: Stack(
            children: [
              PageView.builder(
                controller: _controller,
                onPageChanged: (i) => setState(() => _index = i),
                itemCount: widget.images.length,
                itemBuilder:
                    (context, i) => ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: GestureDetector(
                        onTap:
                            () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder:
                                    (_) => FullscreenImageViewer(
                                      images: widget.images,
                                      initialIndex: i,
                                    ),
                                fullscreenDialog: true,
                              ),
                            ),
                        child: widget.product != null && widget.product!.isOutOfStock
                            ? ColorFiltered(
                                colorFilter: ColorFilter.mode(Colors.grey, BlendMode.saturation),
                                child: LazyImage(
                                  imageUrl: widget.images[i],
                                  fit: BoxFit.fill,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              )
                            : LazyImage(
                                imageUrl: widget.images[i],
                                fit: BoxFit.fill,
                                borderRadius: BorderRadius.circular(20),
                              ),
                      ),
                    ),
              ),
              if (widget.product != null && widget.product!.isOutOfStock)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              if (widget.product != null && widget.product!.isOutOfStock)
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Out of Stock',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              // Share icon (top-right corner)
              if (widget.product != null)
                Positioned(
                  top: 8,
                  right: 8,
                  child: GestureDetector(
                    onTap: () {
                      ProductShareDialog.show(context, widget.product!);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Ionicons.share_social_outline,
                        size: 20,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ),
              if (showArrows) ...[
                Positioned(
                  left: 8,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: _NavButton(
                      icon: Icons.chevron_left,
                      onTap: () {
                        final prev = (_index - 1).clamp(
                          0,
                          widget.images.length - 1,
                        );
                        _controller.animateToPage(
                          prev,
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeOut,
                        );
                      },
                      enabled: _index > 0,
                    ),
                  ),
                ),
                Positioned(
                  right: widget.product != null ? 48 : 8, // Adjust position if share icon exists
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: _NavButton(
                      icon: Icons.chevron_right,
                      onTap: () {
                        final next = (_index + 1).clamp(
                          0,
                          widget.images.length - 1,
                        );
                        _controller.animateToPage(
                          next,
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeOut,
                        );
                      },
                      enabled: _index < widget.images.length - 1,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (int i = 0; i < widget.images.length; i++)
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: _index == i ? 20 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _index == i ? Colors.black : Colors.black26,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _NavButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool enabled;
  const _NavButton({
    required this.icon,
    required this.onTap,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black45,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(20),
        child: Icon(
          icon,
          color: enabled ? Colors.white : Colors.white38,
          size: 28,
        ),
      ),
    );
  }
}
