import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ionicons/ionicons.dart';
import '../../data/admin_features.dart';
import '../../application/admin_fcm_notification_controller.dart';
import 'admin_notification_panel.dart';

/// Notification icon widget with badge count for admin navbar
class AdminNotificationIcon extends ConsumerStatefulWidget {
  const AdminNotificationIcon({super.key});

  @override
  ConsumerState<AdminNotificationIcon> createState() =>
      _AdminNotificationIconState();
}

class _AdminNotificationIconState extends ConsumerState<AdminNotificationIcon> {
  OverlayEntry? _overlayEntry;

  @override
  void dispose() {
    _removeOverlay();
    super.dispose();
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _showNotificationPanel(BuildContext context) {
    if (_overlayEntry != null) {
      _removeOverlay();
      ref.read(adminFcmNotificationControllerProvider.notifier).hidePanel();
      return;
    }

    final notificationState = ref.read(adminFcmNotificationControllerProvider);
    if (!notificationState.isPanelVisible) {
      ref.read(adminFcmNotificationControllerProvider.notifier).showPanel();
    }

    final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final size = renderBox.size;
    final offset = renderBox.localToGlobal(Offset.zero);

    _overlayEntry = OverlayEntry(
      builder: (context) {
        final screenSize = MediaQuery.of(context).size;
        final screenWidth = screenSize.width;
        final screenHeight = screenSize.height;

        // Calculate panel width (same logic as in AdminNotificationPanel)
        final panelWidth = (screenWidth * 0.9).clamp(280.0, 380.0);
        const margin = 16.0; // Minimum margin from screen edges

        // Calculate icon's right edge position
        final iconRightEdge = offset.dx + size.width;

        // Calculate available space on right and left sides
        final rightSpace = screenWidth - iconRightEdge;
        final leftSpace = offset.dx;

        // Determine if we should position from right or left
        // Prefer right alignment if there's enough space, otherwise use left
        final useRightPosition = rightSpace >= panelWidth + margin;

        // Calculate position
        double? left;
        double? right;

        if (useRightPosition) {
          // Position from right, aligning with icon's right edge
          // Ensure minimum margin from screen edge
          final calculatedRight = screenWidth - iconRightEdge;
          right = calculatedRight.clamp(
            margin,
            screenWidth - panelWidth - margin,
          );
          left = null;
        } else {
          // Position from left, ensuring minimum margin
          // Align with icon's left edge, but ensure it doesn't overflow
          final calculatedLeft = offset.dx;
          left = calculatedLeft.clamp(
            margin,
            screenWidth - panelWidth - margin,
          );
          right = null;
        }

        // Ensure panel doesn't overflow vertically
        final topPosition = offset.dy + size.height + 8;
        final maxTop = screenHeight - (screenHeight * 0.6) - margin;
        final top = topPosition.clamp(margin, maxTop);

        return GestureDetector(
          onTap: () {
            // Don't close when tapping inside the panel
          },
          child: Stack(
            children: [
              // Backdrop to close on outside tap
              Positioned.fill(
                child: GestureDetector(
                  onTap: () {
                    _removeOverlay();
                    ref
                        .read(adminFcmNotificationControllerProvider.notifier)
                        .hidePanel();
                  },
                  child: Container(color: Colors.transparent),
                ),
              ),
              // Notification panel
              Positioned(
                left: left,
                right: right,
                top: top,
                child: GestureDetector(
                  onTap: () {
                    // Prevent closing when tapping inside panel
                  },
                  child: Material(
                    elevation: 8,
                    borderRadius: BorderRadius.circular(8),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: panelWidth,
                        maxHeight: screenHeight * 0.6,
                      ),
                      child: const AdminNotificationPanel(),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  @override
  Widget build(BuildContext context) {
    final features = ref.watch(adminFeaturesProvider);
    if (!features.notificationsEnabled) {
      return const SizedBox.shrink();
    }

    final notificationState = ref.watch(adminFcmNotificationControllerProvider);
    final unreadCount = notificationState.unreadCount;

    // Listen for panel visibility changes - automatically cleaned up by Riverpod
    ref.listen<bool>(
      adminFcmNotificationControllerProvider.select(
        (state) => state.isPanelVisible,
      ),
      (previous, next) {
        if (!next && _overlayEntry != null) {
          _removeOverlay();
        }
      },
    );

    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          icon: const Icon(Ionicons.notifications_outline),
          onPressed: () {
            _showNotificationPanel(context);
          },
          tooltip: 'Notifications',
        ),
        if (unreadCount > 0)
          Positioned(
            right: 8,
            top: 8,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.error,
                shape: BoxShape.circle,
              ),
              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
              child: Text(
                unreadCount > 99 ? '99+' : unreadCount.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }
}
