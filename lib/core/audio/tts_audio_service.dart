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

  Future<void> _speak(String? text) async {
    if (text == null || text.trim().isEmpty) return;
    await _configure();
    try {
      await _tts.stop();
      await _tts.speak(text);
    } on Object catch (error) {
      debugPrint('[tts] speak failed: $error');
    }
  }

  @override
  Future<void> playVoice(AudioEvent event) => _speak(event.text);

  @override
  Future<void> playCountdownTick(int secondsLeft) => _speak('$secondsLeft');

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
