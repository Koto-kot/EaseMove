/// Audio abstraction from docs/FLUTTER_ARCHITECTURE.md.
///
/// Voice packs are not recorded yet (`recording_spec.current_status:
/// not_recorded`), so the default implementation resolves cues, respects the
/// mix and the collision policy, and simply reports what it would have played.
/// Swapping in just_audio later touches only [JustAudioService].
library;

import 'package:flutter/foundation.dart';

import '../../domain/exercise/exercise.dart';

abstract interface class AudioService {
  Future<void> playVoice(AudioEvent event);
  Future<void> playCountdownTick(int secondsLeft);
  Future<void> playMusic(String trackId);
  Future<void> pauseAll();
  Future<void> resumeAll();
  Future<void> stopAll();
  Future<void> setVoiceVolume(double value);
  Future<void> setMusicVolume(double value);
}

/// Applies the documented mix and priority rules on top of any player.
class SessionAudioController {
  SessionAudioController({
    required this.service,
    required this.mix,
    required this.voiceEnabled,
    required this.musicEnabled,
  });

  final AudioService service;
  final AudioMix mix;
  final bool voiceEnabled;
  final bool musicEnabled;

  AudioEvent? _playing;
  int _playingPriority = 0;

  /// A non-interruptible cue in flight wins over a lower-priority newcomer,
  /// which is the collision policy the exercise files describe.
  Future<void> play(AudioEvent event) async {
    if (!voiceEnabled) return;
    final AudioEvent? current = _playing;
    if (current != null &&
        !current.interruptible &&
        event.priority <= _playingPriority) {
      return;
    }
    _playing = event;
    _playingPriority = event.priority;
    await service.setVoiceVolume(mix.voiceLevel);
    await service.playVoice(event);
  }

  Future<void> countdown(int secondsLeft) async {
    if (!voiceEnabled) return;
    await service.playCountdownTick(secondsLeft);
  }

  Future<void> startMusic(String trackId) async {
    if (!musicEnabled) return;
    // No dynamic ducking by default (docs/TECHNICAL_SPEC.md 10).
    await service.setMusicVolume(mix.musicLevel * mix.voiceLevel);
    await service.playMusic(trackId);
  }

  Future<void> pause() => service.pauseAll();

  Future<void> resume() => service.resumeAll();

  Future<void> stop() async {
    _playing = null;
    _playingPriority = 0;
    await service.stopAll();
  }
}

/// Records what was requested. Used until voice packs exist, and asserted
/// against in tests.
class LoggingAudioService implements AudioService {
  final List<String> log = <String>[];

  @override
  Future<void> playVoice(AudioEvent event) async {
    log.add('voice:${event.id}');
    if (kDebugMode) {
      debugPrint(
        '[audio] voice ${event.id} — "${event.text ?? event.assetKey}"',
      );
    }
  }

  @override
  Future<void> playCountdownTick(int secondsLeft) async =>
      log.add('tick:$secondsLeft');

  @override
  Future<void> playMusic(String trackId) async => log.add('music:$trackId');

  @override
  Future<void> pauseAll() async => log.add('pause');

  @override
  Future<void> resumeAll() async => log.add('resume');

  @override
  Future<void> stopAll() async => log.add('stop');

  @override
  Future<void> setVoiceVolume(double value) async =>
      log.add('voiceVolume:$value');

  @override
  Future<void> setMusicVolume(double value) async =>
      log.add('musicVolume:$value');
}
