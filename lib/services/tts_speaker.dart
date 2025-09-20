import 'dart:async';
import 'package:audio_session/audio_session.dart' as audio_session;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import '../models/tts_settings.dart';

class TtsSpeaker {
  final FlutterTts _tts = FlutterTts();
  AudioPlayer? _audioPlayer;
  audio_session.AudioSession? _session;
  bool _active = false;
  final TtsSettings _settings;
  static const MethodChannel _channel = MethodChannel('com.yourapp.live_run_pace/aimp');

  TtsSpeaker(this._settings);

  Future<void> init() async {
    // Always initialize audio session (needed for both TTS and MP3)
    _session = await audio_session.AudioSession.instance;

    // Configure audio session to behave like a phone call for proper interruption/resumption
    await _session!.configure(audio_session.AudioSessionConfiguration(
      avAudioSessionCategory: audio_session.AVAudioSessionCategory.playAndRecord,
      avAudioSessionCategoryOptions: audio_session.AVAudioSessionCategoryOptions.duckOthers |
          audio_session.AVAudioSessionCategoryOptions.defaultToSpeaker,
      avAudioSessionMode: audio_session.AVAudioSessionMode.voiceChat,
      avAudioSessionRouteSharingPolicy: audio_session.AVAudioSessionRouteSharingPolicy.defaultPolicy,
      avAudioSessionSetActiveOptions: audio_session.AVAudioSessionSetActiveOptions.none,
      androidAudioAttributes: const audio_session.AndroidAudioAttributes(
        contentType: audio_session.AndroidAudioContentType.speech,
        flags: audio_session.AndroidAudioFlags.none,
        usage: audio_session.AndroidAudioUsage.voiceCommunication,
      ),
      androidAudioFocusGainType: audio_session.AndroidAudioFocusGainType.gainTransient,
      androidWillPauseWhenDucked: false,
    ));

    // Add basic audio interruption listener for debugging
    _session!.interruptionEventStream.listen((event) {
      print('Audio interruption event: $event');
    });

    _session!.becomingNoisyEventStream.listen((_) {
      print('Audio becoming noisy event detected');
    });

    // Only configure TTS if it's enabled
    if (_settings.enabled) {
      await _tts.setLanguage("en-US");
      await _tts.setSpeechRate(_settings.speed);
      await _tts.setVolume(_settings.volume);
      await _tts.setPitch(1.0);
      await _tts.awaitSpeakCompletion(true);
    }

    // Initialize audio player for MP3 if needed
    if (_settings.mp3FilePath != null) {
      _audioPlayer = AudioPlayer();
    }
  }

  Future<void> speak(String text) async {
    print('=== Starting speak sequence ===');
    print('TTS enabled: ${_settings.enabled}');
    print('Pause other audio: ${_settings.pauseOtherAudio}');
    print('MP3 file: ${_settings.mp3FilePath != null ? "Yes" : "No"}');

    if (_session == null) await init();

    bool shouldAcquireFocus = _settings.pauseOtherAudio && !_active;

    try {
      // Request audio focus once for the entire sequence (TTS + MP3)
      if (shouldAcquireFocus) {
        print('Requesting audio focus...');
        _active = await _session!.setActive(true);
        if (_active) {
          print('Audio focus acquired successfully');
          // Add delay for focus acquisition to settle
          await Future.delayed(const Duration(milliseconds: 300));
        } else {
          print('Audio focus denied, continuing without focus');
        }
      }

      // Execute TTS if enabled
      if (_settings.enabled) {
        print('Starting TTS playback...');
        await _tts.speak(text);
        print('TTS playback completed');

        // Small delay between TTS and MP3
        await Future.delayed(const Duration(milliseconds: 100));
      }

      // Execute MP3 playback if available
      if (_settings.mp3FilePath != null) {
        print('Starting MP3 playback...');
        await _playMp3WithFocus();
        print('MP3 playback completed');
      }

      print('=== Speak sequence completed successfully ===');
    } catch (e) {
      print('Error in speak sequence: $e');
    } finally {
      // Always release focus after the complete sequence
      if (shouldAcquireFocus && _active) {
        print('Releasing audio focus...');
        await _release();
        print('Audio focus released');
      }
    }
  }

  Future<void> _playMp3WithFocus() async {
    if (_audioPlayer == null || _settings.mp3FilePath == null) return;

    try {
      print('Playing MP3 file: ${_settings.mp3FilePath}');

      // Start MP3 playback
      await _audioPlayer!.play(DeviceFileSource(_settings.mp3FilePath!));

      // Wait for MP3 completion with proper timeout handling
      final completer = Completer<void>();
      late StreamSubscription subscription;

      subscription = _audioPlayer!.onPlayerComplete.listen((_) {
        print('MP3 playback completed via onPlayerComplete');
        subscription.cancel();
        completer.complete();
      });

      // Also listen for any errors
      final errorSubscription = _audioPlayer!.onPlayerStateChanged.listen((state) {
        if (state == PlayerState.stopped && !completer.isCompleted) {
          print('MP3 playback stopped unexpectedly');
          subscription.cancel();
          completer.complete();
        }
      });

      try {
        // Wait for completion or timeout
        await completer.future.timeout(
          const Duration(seconds: 30),
          onTimeout: () {
            print('MP3 playback timed out');
            subscription.cancel();
            errorSubscription.cancel();
          },
        );
      } finally {
        errorSubscription.cancel();
      }
    } catch (e) {
      print('MP3 playback error: $e');
      rethrow;
    }
  }

  // Legacy method for backward compatibility (when TTS is disabled)
  Future<void> _playMp3() async {
    if (_settings.mp3FilePath != null) {
      // If MP3 is available, manage focus for MP3 only
      bool shouldAcquireFocus = _settings.pauseOtherAudio && !_active;

      try {
        if (shouldAcquireFocus) {
          print('Acquiring focus for MP3-only playback...');
          _active = await _session!.setActive(true);
          await Future.delayed(const Duration(milliseconds: 300));
        }

        await _playMp3WithFocus();
      } finally {
        if (shouldAcquireFocus && _active) {
          await _release();
        }
      }
    }
  }

  // Removed _onTtsComplete - we now manage the TTS->MP3 sequence manually in speak()

  Future<void> stop() async {
    await _tts.stop();
    await _audioPlayer?.stop();
    await _release();
  }

  Future<void> _release() async {
    if (_active && _session != null) {
      print('Releasing audio focus - other apps should resume now');
      _active = false;
      try {
        await _session!.setActive(false); // Release focus so other audio resumes
        print('Audio focus released successfully');
        // Add a small delay to ensure the focus release is processed
        await Future.delayed(const Duration(milliseconds: 100));

        // Resume AIMP if configured
        if (_settings.resumeAimpAfterPlayback) {
          await _resumeAimpPlayback();
        }
      } catch (e) {
        print('Error releasing audio focus: $e');
      }
    } else {
      print('No audio focus to release (not active or no session)');
    }
  }

  Future<void> _resumeAimpPlayback() async {
    try {
      print('Attempting to resume AIMP playback...');
      await _channel.invokeMethod('resumeAimp');
      print('AIMP resume command sent successfully');
    } catch (e) {
      print('Error resuming AIMP: $e');
    }
  }

  Future<void> dispose() async {
    await _tts.stop();
    await _audioPlayer?.dispose();
    await _release();
    _audioPlayer = null;
  }
}