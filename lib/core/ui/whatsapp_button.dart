import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ionicons/ionicons.dart';
import '../providers/whatsapp_button_provider.dart';
import '../services/url_launcher_service.dart';
import '../layout/responsive.dart';

/// Draggable WhatsApp floating button
class DraggableWhatsAppButton extends ConsumerStatefulWidget {
  const DraggableWhatsAppButton({super.key});

  @override
  ConsumerState<DraggableWhatsAppButton> createState() =>
      _DraggableWhatsAppButtonState();
}

class _DraggableWhatsAppButtonState
    extends ConsumerState<DraggableWhatsAppButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onTap() async {
    // Animate button press
    _animationController.forward().then((_) {
      _animationController.reverse();
    });

    // Launch WhatsApp
    final success = await UrlLauncherService.launchWhatsApp();
    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Could not open WhatsApp. Please install WhatsApp or try again.',
          ),
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  void _onPanStart(DragStartDetails details) {
    ref.read(whatsappButtonProvider.notifier).setDragging(true);
    _animationController.forward();
  }

  void _onPanUpdate(DragUpdateDetails details) {
    final screenSize = MediaQuery.of(context).size;
    final buttonSize = _getButtonSize();

    // Calculate new position with constraints
    double newX = details.globalPosition.dx - buttonSize / 2;
    double newY = details.globalPosition.dy - buttonSize / 2;

    // Keep button within screen bounds
    newX = newX.clamp(0, screenSize.width - buttonSize);
    newY = newY.clamp(
      0,
      screenSize.height - buttonSize - 100,
    ); // Account for bottom navigation

    ref
        .read(whatsappButtonProvider.notifier)
        .updatePosition(Offset(newX, newY));
  }

  void _onPanEnd(DragEndDetails details) {
    ref.read(whatsappButtonProvider.notifier).setDragging(false);
    _animationController.reverse();

    // Snap to edges if near screen edge
    _snapToEdge();
  }

  void _snapToEdge() {
    final screenSize = MediaQuery.of(context).size;
    final currentPosition = ref.read(whatsappButtonProvider).position;
    final buttonSize = _getButtonSize();

    double newX = currentPosition.dx;

    // Snap to left or right edge
    if (currentPosition.dx < screenSize.width / 2) {
      newX = 20; // Snap to left
    } else {
      newX = screenSize.width - buttonSize - 20; // Snap to right
    }

    ref
        .read(whatsappButtonProvider.notifier)
        .updatePosition(Offset(newX, currentPosition.dy));
  }

  double _getButtonSize() {
    final screenSize = Responsive.getScreenSize(context);
    switch (screenSize) {
      case ScreenSize.mobile:
        return 56.0;
      case ScreenSize.tablet:
        return 60.0;
      case ScreenSize.desktop:
        return 64.0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final whatsappState = ref.watch(whatsappButtonProvider);

    if (!whatsappState.isVisible) {
      return const SizedBox.shrink();
    }

    return Positioned(
      left: whatsappState.position.dx,
      top: whatsappState.position.dy,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: GestureDetector(
              onTap: _onTap,
              onPanStart: _onPanStart,
              onPanUpdate: _onPanUpdate,
              onPanEnd: _onPanEnd,
              child: Container(
                width: _getButtonSize(),
                height: _getButtonSize(),
                decoration: BoxDecoration(
                  color: const Color(0xFF25D366), // WhatsApp green
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  Ionicons.logo_whatsapp,
                  color: Colors.white,
                  size: _getButtonSize() * 0.5,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}


