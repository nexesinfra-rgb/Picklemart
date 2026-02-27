import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

class OrderSoundService {
  static final OrderSoundService _instance = OrderSoundService._internal();
  factory OrderSoundService() => _instance;
  OrderSoundService._internal();

  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  bool _isInitialized = false;

  // Track order IDs that have already triggered a sound
  final Set<String> _processedOrderIds = {};

  /// Initialize the sound service
  Future<void> initialize() async {
    if (_isInitialized) return;
    try {
      // Set volume to max for order alerts
      await _audioPlayer.setVolume(1.0);
      _isInitialized = true;
      if (kDebugMode) {
        print('OrderSoundService: Initialized successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('OrderSoundService: Error initializing: $e');
      }
    }
  }

  /// Check if sound should play for this order
  bool shouldPlayForOrder(String orderId) {
    return !_processedOrderIds.contains(orderId);
  }

  /// Mark order as processed so it won't play sound again
  void markOrderAsPlayed(String orderId) {
    _processedOrderIds.add(orderId);
  }

  /// Play buzzer sound (repeated sound for attention)
  Future<void> playBuzzerSound() async {
    // Force log to console
    print('🔊 OrderSoundService: playBuzzerSound CALLED');

    try {
      if (_isPlaying) {
        print('🔊 OrderSoundService: Already playing, ignoring');
        return;
      }
      _isPlaying = true;

      // Ensure volume is max
      await _audioPlayer.setVolume(1.0);

      // Play 1 time for attention
      print('🔊 OrderSoundService: Playing beep');

      // Stop any current playback
      await _audioPlayer.stop();
      // Play fresh
      await _audioPlayer.play(AssetSource('sounds/message_sound.mp3'));

      // Wait for sound to finish or delay
      await Future.delayed(const Duration(milliseconds: 1000));

      _isPlaying = false;
    } catch (e) {
      // Always print error
      print('🔴 OrderSoundService ERROR: $e');
      _isPlaying = false;
    }
  }

  void dispose() {
    _audioPlayer.dispose();
  }
}
