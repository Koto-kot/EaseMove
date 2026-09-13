/// Audio abstraction from docs/FLUTTER_ARCHITECTURE.md.
///
/// The player behind this is swappable: recorded lines where the pack has
/// them, text-to-speech where it does not, and a logging stub in tests.
library;

import 'package:flutter/foundation.dart';

import '../../domain/exercise/exercise.dart';

abstract interface class AudioService {
  /// Starts the line and answers how long it will take.
  ///
  /// The answer is what lets [SessionAudioController] know when the voice is
  /// free again. `null` means the player cannot say — a stub that plays
  /// nothing, or a file whose length the platform did not report — and is
  /// read as "nothing is holding the voice".
  Future<Duration?> playVoice(AudioEvent event);
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
    this.musicVolume = 0.4,
    DateTime Function()? clock,
  }) : _now = clock ?? DateTime.now;

  final AudioService service;
  final AudioMix mix;
  final bool voiceEnabled;
  final bool musicEnabled;

  /// How loud the background music is, as the listener set it in Settings.
  /// The exercise files also carry a relative level, but a preference the
  /// listener can hear themselves change outranks a number in the data
  /// (docs/DECISIONS.md 76).
  final double musicVolume;

  /// Injectable so a test can move time without waiting for it.
  final DateTime Function() _now;

  /// The priority a cue that may not be spoken over is holding, and the moment
  /// it stops holding it.
  ///
  /// The deadline is the whole point. Nothing reports back when a line ends —
  /// text-to-speech is asked not to await completion so a cue can cut in — so
  /// a floor with no expiry would be permanent: the first non-interruptible
  /// cue of an exercise silenced the rhythm words, the counting and the
  /// halfway cue for the rest of the session (docs/DECISIONS.md 75).
  int _floorPriority = 0;
  DateTime? _floorUntil;

  /// A non-interruptible cue still being spoken wins over a lower-priority
  /// newcomer, which is the collision policy the exercise files describe.
  Future<void> play(AudioEvent event) async {
    if (!voiceEnabled) return;
    if (_floorHolds(event)) return;

    await service.setVoiceVolume(mix.voiceLevel);
    final Duration? length = await service.playVoice(event);

    if (event.interruptible || length == null) {
      _releaseFloor();
      return;
    }
    _floorPriority = event.priority;
    _floorUntil = _now().add(length);
  }

  bool _floorHolds(AudioEvent event) {
    final DateTime? until = _floorUntil;
    if (until == null) return false;
    if (!_now().isBefore(until)) {
      _releaseFloor();
      return false;
    }
    return event.priority <= _floorPriority;
  }

  void _releaseFloor() {
    _floorPriority = 0;
    _floorUntil = null;
  }

  Future<void> countdown(int secondsLeft) async {
    if (!voiceEnabled) return;
    await service.playCountdownTick(secondsLeft);
  }

  Future<void> startMusic(String trackId) async {
    if (!musicEnabled) return;
    // No dynamic ducking by default (docs/TECHNICAL_SPEC.md 10).
    await service.setMusicVolume(musicVolume);
    await service.playMusic(trackId);
  }

  Future<void> pause() => service.pauseAll();

  Future<void> resume() => service.resumeAll();

  Future<void> stop() async {
    _releaseFloor();
    await service.stopAll();
  }
}

/// Records what was requested. Used in tests, and as the provider's default so
/// no test reaches a platform channel by accident.
class LoggingAudioService implements AudioService {
  LoggingAudioService({this.voiceLength});

  /// What [playVoice] reports back. `null` — the default — plays nothing and
  /// so holds the voice for no time at all; a test that exercises the
  /// collision policy sets a length.
  final Duration? voiceLength;

  final List<String> log = <String>[];

  @override
  Future<Duration?> playVoice(AudioEvent event) async {
    log.add('voice:${event.id}');
    if (kDebugMode) {
      debugPrint(
        '[audio] voice ${event.id} — "${event.text ?? event.assetKey}"',
      );
    }
    return voiceLength;
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
