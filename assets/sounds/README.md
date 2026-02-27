# Chat Sound Assets

This directory contains sound files for the chat feature.

## Required File

- `message_sound.mp3` - Sound played when a new chat message is received

## Getting a Sound File

You can use any short notification sound (typically 0.5-1 second). Options:

1. **Free sound resources:**
   - [Zapsplat](https://www.zapsplat.com/) - Free sound effects
   - [Freesound](https://freesound.org/) - Community sound library
   - [Mixkit](https://mixkit.co/free-sound-effects/notification/) - Free notification sounds

2. **Create your own:**
   - Use a simple "ping" or "pop" sound
   - Keep it short (under 1 second)
   - Use MP3 format for best compatibility

3. **Default system sounds:**
   - On iOS/Android, you could also use system notification sounds via platform channels

## File Format

- Format: MP3 (recommended) or WAV
- Duration: 0.5-1 second
- Volume: Moderate (not too loud, not too quiet)

## Adding the File

1. Place your sound file in this directory as `message_sound.mp3`
2. The app will automatically load it when chat is initialized

