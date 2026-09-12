/// Plays the recorded voice pack, and speaks anything not recorded yet.
///
/// The exercise files name an exact file for every cue
/// (`audio/uk/exercises/ELBOW_001/setup.m4a`), and the pack is produced line
/// by line — `docs/generated/AUDIO_SCRIPT.md` is literally the progress
/// report. So the app cannot wait for a complete pack to start using it: this
/// service plays the file when it is bundled and hands the cue to
/// text-to-speech when it is not, which means a half-recorded pack is already
/// an improvement and never a regression.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';

import '../../domain/exercise/exercise.dart';
import 'audio_service.dart';

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
  Future<void> playVoice(AudioEvent event) async {
    final String? path = localizedAssetPath(event.assetFile);
    if (path == null || !await isBundled(path)) {
      await fallback.playVoice(event);
      return;
    }
    try {
      await _voice.stop();
      await _voice.setAsset(path);
      await _voice.play();
    } on Object catch (error) {
      // A bundled but unplayable file must not end the session silently.
      debugPrint('[audio] $path failed: $error');
      await fallback.playVoice(event);
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
      await _voice.stop();
      await _voice.setAsset(path);
      await _voice.play();
    } on Object catch (error) {
      debugPrint('[audio] $path failed: $error');
      await fallback.playCountdownTick(secondsLeft);
    }
  }

  @override
  Future<void> playMusic(String trackId) async {
    final String path = 'audio/music/$trackId.m4a';
    if (!await isBundled(path)) return;
    try {
      await _music.setAsset(path);
      await _music.setLoopMode(LoopMode.one);
      await _music.play();
    } on Object catch (error) {
      debugPrint('[audio] $path failed: $error');
    }
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
    await _musicPlayer?.play();
    await fallback.resumeAll();
  }

  @override
  Future<void> stopAll() async {
    await _voicePlayer?.stop();
    await _musicPlayer?.stop();
    await fallback.stopAll();
  }

  @override
  Future<void> setVoiceVolume(double value) async {
    await _voicePlayer?.setVolume(value);
    await fallback.setVoiceVolume(value);
  }

  @override
  Future<void> setMusicVolume(double value) async {
    await _musicPlayer?.setVolume(value);
    await fallback.setMusicVolume(value);
  }

  Future<void> dispose() async {
    await _voicePlayer?.dispose();
    await _musicPlayer?.dispose();
  }
}
