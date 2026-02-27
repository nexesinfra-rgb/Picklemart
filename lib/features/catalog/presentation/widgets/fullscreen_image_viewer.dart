import 'package:flutter/material.dart';
import '../../../../core/layout/responsive.dart';
import '../../../../core/widgets/lazy_image.dart';

class FullscreenImageViewer extends StatefulWidget {
  final List<String> images;
  final int initialIndex;
  const FullscreenImageViewer({
    super.key,
    required this.images,
    this.initialIndex = 0,
  });

  @override
  State<FullscreenImageViewer> createState() => _FullscreenImageViewerState();
}

class _FullscreenImageViewerState extends State<FullscreenImageViewer> {
  late final PageController _controller;
  late int _index;
  final TransformationController _transform = TransformationController();
  static const double _minScale = 1.0;
  static const double _maxScale = 5.0;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex;
    _controller = PageController(initialPage: _index);
  }

  @override
  void dispose() {
    _controller.dispose();
    _transform.dispose();
    super.dispose();
  }

  void _resetZoom() {
    _transform.value = Matrix4.identity();
  }

  void _zoomBy(double factor) {
    final currentScale = _transform.value.getMaxScaleOnAxis();
    final next = (currentScale * factor).clamp(_minScale, _maxScale);
    setState(() {
      _transform.value = Matrix4.identity()..scale(next);
    });
  }

  @override
  Widget build(BuildContext context) {
    final bp = Responsive.breakpointForWidth(MediaQuery.of(context).size.width);
    final showArrows = bp != AppBreakpoint.compact;
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          PageView.builder(
            controller: _controller,
            onPageChanged:
                (i) => setState(() {
                  _index = i;
                  _resetZoom();
                }),
            itemCount: widget.images.length,
            itemBuilder:
                (context, i) {
                  final screenSize = MediaQuery.of(context).size;
                  final containerWidth = screenSize.width * 0.9;
                  final containerHeight = screenSize.height * 0.8;
                  
                  return Center(
                    child: InteractiveViewer(
                      transformationController: _transform,
                      minScale: _minScale,
                      maxScale: _maxScale,
                      child: Container(
                        width: containerWidth,
                        height: containerHeight,
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: LazyImage(
                            imageUrl: widget.images[i],
                            fit: BoxFit.contain,
                            errorWidget: const Icon(
                              Icons.broken_image,
                              color: Colors.white54,
                              size: 64,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
          ),
          // Close button
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 8,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          // Dots indicator
          Positioned(
            bottom: 24,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (int i = 0; i < widget.images.length; i++)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: _index == i ? 22 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _index == i ? Colors.white : Colors.white38,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
              ],
            ),
          ),
          // Zoom controls
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            right: 8,
            child: Row(
              children: [
                _CircleButton(icon: Icons.remove, onTap: () => _zoomBy(0.8)),
                const SizedBox(width: 8),
                _CircleButton(icon: Icons.add, onTap: () => _zoomBy(1.25)),
                const SizedBox(width: 8),
                _CircleButton(icon: Icons.refresh, onTap: _resetZoom),
              ],
            ),
          ),
          if (showArrows) ...[
            Positioned(
              left: 8,
              top: 0,
              bottom: 0,
              child: Center(
                child: _CircleButton(
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
                ),
              ),
            ),
            Positioned(
              right: 8,
              top: 0,
              bottom: 0,
              child: Center(
                child: _CircleButton(
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
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _CircleButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white24,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Icon(icon, color: Colors.white, size: 28),
        ),
      ),
    );
  }
}
