import 'package:flutter/material.dart';

/// Animated typing indicator with 3 bouncing dots
class TypingIndicatorDots extends StatefulWidget {
  final Color? color;
  final double dotSize;
  final Duration animationDuration;

  const TypingIndicatorDots({
    super.key,
    this.color,
    this.dotSize = 8.0,
    this.animationDuration = const Duration(milliseconds: 600),
  });

  @override
  State<TypingIndicatorDots> createState() => _TypingIndicatorDotsState();
}

class _TypingIndicatorDotsState extends State<TypingIndicatorDots>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();
    
    // Create 3 animation controllers for 3 dots
    _controllers = List.generate(
      3,
      (index) => AnimationController(
        duration: widget.animationDuration,
        vsync: this,
      ),
    );

    // Create animations with staggered delays
    _animations = _controllers.map((controller) {
      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: controller,
          curve: Curves.easeInOut,
        ),
      );
    }).toList();

    // Start animations with staggered delays
    for (int i = 0; i < _controllers.length; i++) {
      Future.delayed(Duration(milliseconds: i * 200), () {
        if (mounted) {
          _controllers[i].repeat(reverse: true);
        }
      });
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? Theme.of(context).colorScheme.primary;
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        return AnimatedBuilder(
          animation: _animations[index],
          builder: (context, child) {
            // Scale and opacity animation
            final scale = 0.5 + (_animations[index].value * 0.5);
            final opacity = 0.3 + (_animations[index].value * 0.7);
            
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: widget.dotSize,
              height: widget.dotSize,
              decoration: BoxDecoration(
                color: color.withOpacity(opacity),
                shape: BoxShape.circle,
              ),
              transform: Matrix4.identity()..scale(scale),
            );
          },
        );
      }),
    );
  }
}

