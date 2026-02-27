import 'package:flutter/material.dart';

/// A widget that detects when its child is about to enter the viewport
/// and triggers a callback for lazy loading.
///
/// This widget wraps a section and monitors its position relative to the
/// viewport. When the section is within [loadThreshold] pixels of becoming
/// visible, it calls [onLoad] to trigger data loading.
class LazySection extends StatefulWidget {
  /// The child widget to wrap
  final Widget child;

  /// Callback triggered when section is about to become visible
  final VoidCallback onLoad;

  /// Distance in pixels from viewport edge to trigger loading (default: 300px)
  final double loadThreshold;

  /// Whether the section has already been loaded
  final bool isLoaded;

  const LazySection({
    super.key,
    required this.child,
    required this.onLoad,
    this.loadThreshold = 300.0,
    this.isLoaded = false,
  });

  @override
  State<LazySection> createState() => _LazySectionState();
}

class _LazySectionState extends State<LazySection> {
  final GlobalKey _key = GlobalKey();
  bool _hasTriggered = false;

  void _checkVisibility() {
    if (widget.isLoaded || _hasTriggered) return;

    final renderObject = _key.currentContext?.findRenderObject();
    if (renderObject == null || !renderObject.attached) return;

    final box = renderObject as RenderBox;
    final position = box.localToGlobal(Offset.zero);
    final size = box.size;

    // Get viewport dimensions
    final viewportHeight = MediaQuery.of(context).size.height;
    final viewportTop = 0.0;
    final viewportBottom = viewportHeight;

    // Calculate section position relative to viewport
    final sectionTop = position.dy;
    final sectionBottom = sectionTop + size.height;

    // Check if section is within load threshold of viewport
    // Trigger when section top is within threshold of viewport bottom
    final distanceToViewport = sectionTop - viewportBottom;

    // Trigger load if section is about to enter viewport
    if (distanceToViewport <= widget.loadThreshold) {
      _hasTriggered = true;
      widget.onLoad();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Use NotificationListener to detect scroll events
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification is ScrollUpdateNotification || 
            notification is ScrollEndNotification) {
          _checkVisibility();
        }
        return false;
      },
      child: Container(
        key: _key,
        child: widget.child,
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    // Check visibility after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !widget.isLoaded && !_hasTriggered) {
        _checkVisibility();
      }
    });
  }
}

