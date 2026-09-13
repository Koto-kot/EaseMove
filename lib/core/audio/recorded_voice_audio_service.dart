/// Plays the recorded voice pack, and speaks anything not recorded yet.
///
/// The exercise files name an exact file for every cue
/// (`audio/uk/exercises/ELBOW_001/setup.m4a`), and the pack is produced line
/// by line — `docs/generated/AUDIO_SCRIPT_<LANG>.md` is literally the
/// progress report. So the app cannot wait for a complete pack to start using it: this
/// service plays the file when it is bundled and hands the cue to
/// text-to-speech when it is not, which means a half-recorded pack is already
/// an improvement and never a regression.
library;

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';

import '../../domain/exercise/exercise.dart';
import 'audio_service.dart';
import 'volume_fader.dart';

class RecordedVoiceAudioService implements AudioService {
  RecordedVoiceAudioService({
    required this.fallback,
    required this.languageCode,
    AssetBundle? bundle,
    AudioPlayer? voicePlayer,
    AudioPlayer? musicPlayer,
  }) : _bundle = bundle ?? rootBundle {
    _voicePlayer = voicePlayer;
    _musicPlayer = musicPlayer;
  }

  /// Used for any line the pack does not carry yet.
  final AudioService fallback;

  /// App language, so a cue authored in Ukrainian is looked for under
  /// `audio/uk/` even when the file the exercise names is for another locale.
  final String languageCode;

  final AssetBundle _bundle;

  // Created on first use: before any line is recorded every cue goes to the
  // fallback, and a player that is never needed should never be built.
  AudioPlayer? _voicePlayer;
  AudioPlayer? _musicPlayer;

  AudioPlayer get _voice => _voicePlayer ??= AudioPlayer();
  AudioPlayer get _music => _musicPlayer ??= AudioPlayer();

  /// Shapes the music's entrances and exits. It never creates the player: a
  /// volume set before anything plays is only remembered.
  late final VolumeFader _musicFade = VolumeFader(
    apply: (double value) async => _musicPlayer?.setVolume(value),
  );

  /// The level the listener chose, kept across a fade to nothing so the next
  /// exercise starts where the last one left off. The opening value is only a
  /// floor: [setMusicVolume] runs before any track does
  /// (AppSettings.defaultMusicVolume).
  double _musicLevel = 0.4;

  /// Remembers what is bundled, so a missing line costs one failed load and
  /// not one per repetition.
  final Map<String, bool> _available = <String, bool>{};

  /// The authored path is for the authoring locale; a listener in another
  /// language needs the same file under their own folder.
  @visibleForTesting
  String? localizedAssetPath(String? assetFile) {
    if (assetFile == null || assetFile.isEmpty) return null;
    final List<String> parts = assetFile.split('/');
    // audio/<locale>/...
    if (parts.length < 3 || parts.first != 'audio') return assetFile;
    parts[1] = languageCode;
    return parts.join('/');
  }

  /// Whether the pack carries this line, cached after the first look.
  @visibleForTesting
  Future<bool> isBundled(String path) async {
    final bool? known = _available[path];
    if (known != null) return known;
    bool exists;
    try {
      await _bundle.load(path);
      exists = true;
    } on Object {
      exists = false;
    }
    _available[path] = exists;
    return exists;
  }

  @override
  Future<Duration?> playVoice(AudioEvent event) async {
    final String? path = localizedAssetPath(event.assetFile);
    if (path == null || !await isBundled(path)) {
      return fallback.playVoice(event);
    }
    try {
      return await _playAsset(path);
    } on Object catch (error) {
      // A bundled but unplayable file must not end the session silently.
      debugPrint('[audio] $path failed: $error');
      return fallback.playVoice(event);
    }
  }

  @override
  Future<void> playCountdownTick(int secondsLeft) async {
    final String path = 'audio/$languageCode/common/countdown_$secondsLeft.m4a';
    if (!await isBundled(path)) {
      await fallback.playCountdownTick(secondsLeft);
      return;
    }
    try {
      await _playAsset(path);
    } on Object catch (error) {
      debugPrint('[audio] $path failed: $error');
      await fallback.playCountdownTick(secondsLeft);
    }
  }

  @override
  Future<void> playCommonLine(String name) async {
    final String path = 'audio/$languageCode/common/$name.m4a';
    if (!await isBundled(path)) {
      await fallback.playCommonLine(name);
      return;
    }
    try {
      await _playAsset(path);
    } on Object catch (error) {
      debugPrint('[audio] $path failed: $error');
      await fallback.playCommonLine(name);
    }
  }

  /// Plays a bundled line and reports its length, which is what tells the
  /// caller when a cue that may not be spoken over has finished. `setAsset`
  /// answers null when the platform will not say; the caller then treats the
  /// voice as free, which is better than a session that goes quiet.
  Future<Duration?> _playAsset(String path) async {
    await _voice.stop();
    final Duration? length = await _voice.setAsset(path);
    _start(_voice);
    return length;
  }

  /// Starts a player without waiting for it.
  ///
  /// `AudioPlayer.play()` answers when playback *finishes*, not when it begins
  /// (just_audio's README says as much). Awaiting it means the next line of
  /// code runs a sentence later — or, for a looping track, never.
  void _start(AudioPlayer player) {
    unawaited(
      player.play().catchError((Object error) {
        debugPrint('[audio] play failed: $error');
      }),
    );
  }

  @override
  Future<void> playMusic(String trackId, {required Duration fadeIn}) async {
    final String path = 'audio/music/$trackId.m4a';
    if (!await isBundled(path)) return;
    try {
      _musicFade.cancel();
      await _music.setAsset(path);
      await _music.setLoopMode(LoopMode.one);
      // Silent first, then brought up: setting the asset does not reset the
      // volume, so without this the track would open at full level.
      await _music.setVolume(0);
      _start(_music);
      _musicFade.ramp(from: 0, to: _musicLevel, over: fadeIn);
    } on Object catch (error) {
      debugPrint('[audio] $path failed: $error');
    }
  }

  @override
  Future<void> stopMusic({required Duration fadeOut}) async {
    final AudioPlayer? player = _musicPlayer;
    if (player == null) return;
    if (!player.playing) {
      _musicFade.cancel();
      await player.stop();
      _musicFade.target = _musicLevel;
      return;
    }
    _musicFade.ramp(
      from: player.volume,
      to: 0,
      over: fadeOut,
      onDone: () => unawaited(_settleAfterFadeOut(player)),
    );
  }

  /// The track is only stopped once it cannot be heard, and the listener's
  /// level is put back for the next exercise.
  Future<void> _settleAfterFadeOut(AudioPlayer player) async {
    await player.stop();
    _musicFade.target = _musicLevel;
  }

  @override
  Future<void> pauseAll() async {
    await _voicePlayer?.pause();
    await _musicPlayer?.pause();
    await fallback.pauseAll();
  }

  @override
  Future<void> resumeAll() async {
    // The voice cue is not resumed: the timeline will deliver the next one at
    // its own offset, and half a sentence is worse than none.
    final AudioPlayer? music = _musicPlayer;
    if (music != null) _start(music);
    await fallback.resumeAll();
  }

  @override
  Future<void> stopAll() async {
    // Silence now, not gracefully: this is Stop, Exit and dispose, where a
    // track still fading in the background would be a bug and not a kindness.
    _musicFade.cancel();
    await _voicePlayer?.stop();
    await _musicPlayer?.stop();
    _musicFade.target = _musicLevel;
    await fallback.stopAll();
  }

  @override
  Future<void> setVoiceVolume(double value) async {
    await _voicePlayer?.setVolume(value);
    await fallback.setVoiceVolume(value);
  }

  @override
  Future<void> setMusicVolume(double value) async {
    _musicLevel = value;
    // A ramp in flight bends towards the new level rather than jumping to it,
    // so the slider stays usable while a preview is still arriving.
    _musicFade.target = value;
    await fallback.setMusicVolume(value);
  }

  Future<void> dispose() async {
    _musicFade.cancel();
    await _voicePlayer?.dispose();
    await _musicPlayer?.dispose();
  }
}
