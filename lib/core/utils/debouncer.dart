import 'dart:async';
import 'package:flutter/material.dart';

/// A utility class for debouncing function calls
/// 
/// Use this to delay execution of a function until after a specified
/// amount of time has passed since it was last invoked.
/// 
/// Example:
/// ```dart
/// final debouncer = Debouncer(delay: const Duration(milliseconds: 500));
/// 
/// // Call this multiple times rapidly
/// debouncer.debounce(() {
///   // This will only execute once, 500ms after the last call
///   performSearch();
/// });
/// ```
class Debouncer {
  final Duration delay;
  Timer? _timer;

  Debouncer({Duration? delay})
      : delay = delay ?? const Duration(milliseconds: 500);

  /// Debounces a function call
  /// 
  /// If called multiple times within the delay period, only the last
  /// call will be executed after the delay has passed.
  void debounce(VoidCallback action) {
    _timer?.cancel();
    _timer = Timer(delay, action);
  }

  /// Immediately cancels any pending debounced calls
  void cancel() {
    _timer?.cancel();
    _timer = null;
  }

  /// Checks if there's a pending debounced call
  bool get isPending => _timer?.isActive ?? false;

  /// Disposes the debouncer, canceling any pending calls
  void dispose() {
    cancel();
  }
}

