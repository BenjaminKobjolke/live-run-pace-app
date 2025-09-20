import 'dart:async';
import 'package:audio_session/audio_session.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:audioplayers/audioplayers.dart';
import '../models/tts_settings.dart';

class TtsSpeaker {
  final FlutterTts _tts = FlutterTts();
  AudioPlayer? _audioPlayer;
  AudioSession? _session;
  bool _active = false;
  final TtsSettings _settings;

  TtsSpeaker(this._settings);

  Future<void> init() async {
    if (!_settings.enabled) return;

    _session = await AudioSession.instance;
    await _session!.configure(const AudioSessionConfiguration.speech());

    // Configure TTS
    await _tts.setLanguage("en-US");
    await _tts.setSpeechRate(_settings.speed);
    await _tts.setVolume(_settings.volume);
    await _tts.setPitch(1.0);
    await _tts.awaitSpeakCompletion(true);

    // Set completion handler to release focus
    _tts.setCompletionHandler(_onTtsComplete);

    // Initialize audio player for MP3 if needed
    if (_settings.mp3FilePath != null) {
      _audioPlayer = AudioPlayer();
    }
  }

  Future<void> speak(String text) async {
    if (!_settings.enabled) {
      // If TTS disabled but MP3 available, just play MP3
      await _playMp3();
      return;
    }

    if (_session == null) await init();

    // Request audio focus before speaking
    if (_settings.pauseOtherAudio && !_active) {
      _active = await _session!.setActive(true);
      if (!_active) {
        // Focus denied, still try to speak without focus
        print('Audio focus denied, speaking without focus');
      }
    }

    try {
      // Add delay for audio focus acquisition
      if (_settings.pauseOtherAudio && _active) {
        await Future.delayed(const Duration(milliseconds: 250));
      }

      // Speak the text
      await _tts.speak(text);
    } catch (e) {
      print('TTS error: $e');
      await _release();
      // Still try to play MP3 if available
      await _playMp3();
    }
  }

  Future<void> _playMp3() async {
    if (_audioPlayer == null || _settings.mp3FilePath == null) return;

    try {
      // Use the same audio session for consistency
      await _audioPlayer!.play(DeviceFileSource(_settings.mp3FilePath!));

      // Wait for MP3 completion if we have audio focus
      if (_active) {
        final completer = Completer<void>();
        late StreamSubscription subscription;

        subscription = _audioPlayer!.onPlayerComplete.listen((_) async {
          subscription.cancel();
          await _release(); // Release focus after MP3 completes
          completer.complete();
        });

        // Wait for completion or timeout
        await completer.future.timeout(
          const Duration(seconds: 30),
          onTimeout: () {
            subscription.cancel();
            _release();
          },
        );
      }
    } catch (e) {
      print('MP3 playback error: $e');
      await _release();
    }
  }

  void _onTtsComplete() {
    // TTS completed, now play MP3 if available
    _playMp3();
  }

  Future<void> stop() async {
    await _tts.stop();
    await _audioPlayer?.stop();
    await _release();
  }

  Future<void> _release() async {
    if (_active && _session != null) {
      _active = false;
      try {
        await _session!.setActive(false); // Release focus so other audio resumes
      } catch (e) {
        print('Error releasing audio focus: $e');
      }
    }
  }

  Future<void> dispose() async {
    await _tts.stop();
    await _audioPlayer?.dispose();
    await _release();
    _audioPlayer = null;
  }
}