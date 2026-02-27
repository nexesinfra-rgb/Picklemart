import 'package:audioplayers/audioplayers.dart';

class ChatSoundService {
  static final ChatSoundService _instance = ChatSoundService._internal();
  factory ChatSoundService() => _instance;
  ChatSoundService._internal();

  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isInitialized = false;
  bool _isPlaying = false;

  /// Initialize the sound service
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      _isInitialized = true;
    } catch (e) {
      // Error handled silently
    }
  }

  /// Play message received sound
  Future<void> playMessageSound() async {
    try {
      // Prevent playing multiple sounds simultaneously
      if (_isPlaying) return;
      
      _isPlaying = true;
      
      // Play sound from assets
      await _audioPlayer.play(AssetSource('sounds/message_sound.mp3'));
      
      // Reset playing flag after a short delay
      Future.delayed(const Duration(milliseconds: 500), () {
        _isPlaying = false;
      });
    } catch (e) {
      _isPlaying = false;
      // Fail silently - don't break chat functionality
    }
  }

  /// Dispose resources
  void dispose() {
    _audioPlayer.dispose();
  }
}

