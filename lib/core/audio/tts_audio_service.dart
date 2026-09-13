/// Speaks voice cues with the platform text-to-speech engine.
///
/// The exercise files carry the cue text but the voice packs are not recorded
/// yet (`recording_spec.current_status: not_recorded`), and
/// docs/LOCALIZATION.md allows a TTS fallback in place of a voice pack. So the
/// app already speaks the authored lines; swapping in recorded audio later
/// only replaces this class.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../../domain/exercise/exercise.dart';
import 'audio_service.dart';

class TtsAudioService implements AudioService {
  TtsAudioService({required this.languageCode, FlutterTts? tts})
    : _tts = tts ?? FlutterTts();

  /// App language, so the cue is spoken in the language it was authored in.
  final String languageCode;

  final FlutterTts _tts;
  bool _configured = false;
  double _volume = 1;

  /// Calm and unhurried, per the exercise files' `voice_style_uk`.
  static const double _speechRate = 0.45;

  static const Map<String, String> _ttsLanguages = <String, String>{
    'uk': 'uk-UA',
    'en': 'en-US',
  };

  Future<void> _configure() async {
    if (_configured) return;
    _configured = true;
    try {
      await _tts.setLanguage(_ttsLanguages[languageCode] ?? 'en-US');
      await _tts.setSpeechRate(_speechRate);
      await _tts.setVolume(_volume);
      await _tts.setPitch(1);
      // Let a high-priority cue cut in rather than queueing behind a long one;
      // collision policy is decided by SessionAudioController.
      await _tts.awaitSpeakCompletion(false);
    } on Object catch (error) {
      // A device without the language installed must not break the session.
      debugPrint('[tts] configuration failed: $error');
    }
  }

  Future<Duration?> _speak(String? text) async {
    if (text == null || text.trim().isEmpty) return null;
    await _configure();
    try {
      await _tts.stop();
      await _tts.speak(text);
    } on Object catch (error) {
      debugPrint('[tts] speak failed: $error');
      return null;
    }
    return estimate(text);
  }

  /// Roughly how long [text] takes to say at [_speechRate].
  ///
  /// An estimate, because completion awaiting is off: the engine is asked not
  /// to report back so that a higher-priority cue can cut in mid-sentence. The
  /// caller still has to know when the voice is free, and a figure derived
  /// from the line itself is closer than any constant would be. Ukrainian and
  /// English both land near 150 words a minute at a normal rate, and
  /// flutter_tts treats 0.5 as normal.
  @visibleForTesting
  Duration estimate(String text) {
    final int words = text
        .split(RegExp(r'[\s]+'))
        .where((String word) => word.isNotEmpty)
        .length;
    const double perWordMs = 400 * (0.5 / _speechRate);
    // A short tail, so the next cue does not start on the last syllable.
    return Duration(milliseconds: (words * perWordMs).round() + 300);
  }

  @override
  Future<Duration?> playVoice(AudioEvent event) => _speak(event.text);

  @override
  Future<void> playCountdownTick(int secondsLeft) async {
    await _speak('$secondsLeft');
  }

  @override
  Future<void> playCommonLine(String name) async {
    // These lines live in the pack, not in the library's text, so there is
    // nothing to speak here. A pack without them simply counts silently.
  }

  @override
  Future<void> playMusic(String trackId) async {
    // No tracks exist yet (`music/` holds only a README), and TTS cannot
    // provide background music. Wired when the audio pack lands.
  }

  @override
  Future<void> pauseAll() async {
    try {
      await _tts.pause();
    } on Object {
      // Not every platform implements pause; stopping is close enough.
      await stopAll();
    }
  }

  @override
  Future<void> resumeAll() async {
    // Nothing to resume: cues are short and the next one arrives from the
    // timeline, which resumes at the same position.
  }

  @override
  Future<void> stopAll() async {
    try {
      await _tts.stop();
    } on Object catch (error) {
      debugPrint('[tts] stop failed: $error');
    }
  }

  @override
  Future<void> setVoiceVolume(double value) async {
    _volume = value;
    if (!_configured) return;
    try {
      await _tts.setVolume(value);
    } on Object catch (error) {
      debugPrint('[tts] volume failed: $error');
    }
  }

  @override
  Future<void> setMusicVolume(double value) async {
    // See playMusic.
  }
}
