import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider for managing WhatsApp button state
final whatsappButtonProvider =
    StateNotifierProvider<WhatsAppButtonNotifier, WhatsAppButtonState>((ref) {
      return WhatsAppButtonNotifier();
    });

/// State class for WhatsApp button
class WhatsAppButtonState {
  final bool isVisible;
  final Offset position;
  final bool isDragging;

  const WhatsAppButtonState({
    this.isVisible = true,
    this.position = const Offset(20, 100), // Default position
    this.isDragging = false,
  });

  WhatsAppButtonState copyWith({
    bool? isVisible,
    Offset? position,
    bool? isDragging,
  }) {
    return WhatsAppButtonState(
      isVisible: isVisible ?? this.isVisible,
      position: position ?? this.position,
      isDragging: isDragging ?? this.isDragging,
    );
  }
}

/// Notifier for WhatsApp button state management
class WhatsAppButtonNotifier extends StateNotifier<WhatsAppButtonState> {
  WhatsAppButtonNotifier() : super(const WhatsAppButtonState());

  /// Update button position
  void updatePosition(Offset newPosition) {
    state = state.copyWith(position: newPosition);
  }

  /// Set dragging state
  void setDragging(bool isDragging) {
    state = state.copyWith(isDragging: isDragging);
  }

  /// Toggle button visibility
  void toggleVisibility() {
    state = state.copyWith(isVisible: !state.isVisible);
  }

  /// Hide button
  void hide() {
    state = state.copyWith(isVisible: false);
  }

  /// Show button
  void show() {
    state = state.copyWith(isVisible: true);
  }

  /// Reset to default position
  void resetPosition() {
    state = state.copyWith(position: const Offset(20, 100));
  }
}


