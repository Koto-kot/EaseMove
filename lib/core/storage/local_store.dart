/// Local-first persistence. The MVP requires no account
/// (docs/TECHNICAL_SPEC.md 4).
library;

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/exercise/session_machine.dart';

class AppSettings {
  const AppSettings({
    this.localeOverride,
    this.voiceEnabled = true,
    this.musicEnabled = true,
    this.reducedMotion = false,
    this.remindersEnabled = false,
    this.devProOverride = false,
    this.devShowPending = true,
    this.devSkipCountdowns = false,
    this.devShowIds = false,
    this.devTimingMultiplier = 1.0,
  });

  /// `null` means "follow the system language" (docs/LOCALIZATION.md).
  final String? localeOverride;
  final bool voiceEnabled;
  final bool musicEnabled;
  final bool reducedMotion;
  final bool remindersEnabled;
  final bool devProOverride;
  final bool devShowPending;
  final bool devSkipCountdowns;
  final bool devShowIds;
  final double devTimingMultiplier;

  AppSettings copyWith({
    String? localeOverride,
    bool clearLocaleOverride = false,
    bool? voiceEnabled,
    bool? musicEnabled,
    bool? reducedMotion,
    bool? remindersEnabled,
    bool? devProOverride,
    bool? devShowPending,
    bool? devSkipCountdowns,
    bool? devShowIds,
    double? devTimingMultiplier,
  }) {
    return AppSettings(
      localeOverride: clearLocaleOverride
          ? null
          : (localeOverride ?? this.localeOverride),
      voiceEnabled: voiceEnabled ?? this.voiceEnabled,
      musicEnabled: musicEnabled ?? this.musicEnabled,
      reducedMotion: reducedMotion ?? this.reducedMotion,
      remindersEnabled: remindersEnabled ?? this.remindersEnabled,
      devProOverride: devProOverride ?? this.devProOverride,
      devShowPending: devShowPending ?? this.devShowPending,
      devSkipCountdowns: devSkipCountdowns ?? this.devSkipCountdowns,
      devShowIds: devShowIds ?? this.devShowIds,
      devTimingMultiplier: devTimingMultiplier ?? this.devTimingMultiplier,
    );
  }
}

abstract interface class LocalStore {
  AppSettings readSettings();
  Future<void> writeSettings(AppSettings settings);

  int readLifetimeCount();
  Future<void> incrementLifetimeCount();

  List<SessionResult> readHistory();
  Future<void> appendHistory(SessionResult result);

  Future<void> resetStats();
}

class PreferencesLocalStore implements LocalStore {
  PreferencesLocalStore(this._prefs);

  static const String _kLocale = 'settings.locale';
  static const String _kVoice = 'settings.voice';
  static const String _kMusic = 'settings.music';
  static const String _kReducedMotion = 'settings.reduced_motion';
  static const String _kReminders = 'settings.reminders';
  static const String _kDevPro = 'dev.pro';
  static const String _kDevPending = 'dev.pending';
  static const String _kDevSkip = 'dev.skip_countdown';
  static const String _kDevIds = 'dev.show_ids';
  static const String _kDevTiming = 'dev.timing_multiplier';
  static const String _kLifetime = 'stats.lifetime_count';
  static const String _kHistory = 'stats.history';

  /// Keeping the whole history in preferences is fine at MVP volume; a local
  /// database lands with cloud sync scope.
  static const int _historyLimit = 200;

  final SharedPreferences _prefs;

  static Future<PreferencesLocalStore> open() async =>
      PreferencesLocalStore(await SharedPreferences.getInstance());

  @override
  AppSettings readSettings() => AppSettings(
    localeOverride: _prefs.getString(_kLocale),
    voiceEnabled: _prefs.getBool(_kVoice) ?? true,
    musicEnabled: _prefs.getBool(_kMusic) ?? true,
    reducedMotion: _prefs.getBool(_kReducedMotion) ?? false,
    remindersEnabled: _prefs.getBool(_kReminders) ?? false,
    devProOverride: _prefs.getBool(_kDevPro) ?? false,
    devShowPending: _prefs.getBool(_kDevPending) ?? true,
    devSkipCountdowns: _prefs.getBool(_kDevSkip) ?? false,
    devShowIds: _prefs.getBool(_kDevIds) ?? false,
    devTimingMultiplier: _prefs.getDouble(_kDevTiming) ?? 1.0,
  );

  @override
  Future<void> writeSettings(AppSettings settings) async {
    if (settings.localeOverride == null) {
      await _prefs.remove(_kLocale);
    } else {
      await _prefs.setString(_kLocale, settings.localeOverride!);
    }
    await _prefs.setBool(_kVoice, settings.voiceEnabled);
    await _prefs.setBool(_kMusic, settings.musicEnabled);
    await _prefs.setBool(_kReducedMotion, settings.reducedMotion);
    await _prefs.setBool(_kReminders, settings.remindersEnabled);
    await _prefs.setBool(_kDevPro, settings.devProOverride);
    await _prefs.setBool(_kDevPending, settings.devShowPending);
    await _prefs.setBool(_kDevSkip, settings.devSkipCountdowns);
    await _prefs.setBool(_kDevIds, settings.devShowIds);
    await _prefs.setDouble(_kDevTiming, settings.devTimingMultiplier);
  }

  @override
  int readLifetimeCount() => _prefs.getInt(_kLifetime) ?? 0;

  @override
  Future<void> incrementLifetimeCount() =>
      _prefs.setInt(_kLifetime, readLifetimeCount() + 1);

  @override
  List<SessionResult> readHistory() {
    final List<String> raw =
        _prefs.getStringList(_kHistory) ?? const <String>[];
    final List<SessionResult> results = <SessionResult>[];
    for (final String entry in raw) {
      try {
        results.add(
          SessionResult.fromJson(jsonDecode(entry) as Map<String, dynamic>),
        );
      } on FormatException {
        // Skip a corrupted row rather than losing the whole history.
        continue;
      }
    }
    return results;
  }

  @override
  Future<void> appendHistory(SessionResult result) async {
    final List<String> raw = <String>[
      jsonEncode(result.toJson()),
      ...?_prefs.getStringList(_kHistory),
    ];
    await _prefs.setStringList(
      _kHistory,
      raw.length > _historyLimit ? raw.sublist(0, _historyLimit) : raw,
    );
  }

  @override
  Future<void> resetStats() async {
    await _prefs.remove(_kLifetime);
    await _prefs.remove(_kHistory);
  }
}

/// In-memory store for tests and widget previews.
class InMemoryLocalStore implements LocalStore {
  AppSettings _settings = const AppSettings();
  int _lifetime = 0;
  final List<SessionResult> _history = <SessionResult>[];

  @override
  AppSettings readSettings() => _settings;

  @override
  Future<void> writeSettings(AppSettings settings) async =>
      _settings = settings;

  @override
  int readLifetimeCount() => _lifetime;

  @override
  Future<void> incrementLifetimeCount() async => _lifetime++;

  @override
  List<SessionResult> readHistory() =>
      List<SessionResult>.unmodifiable(_history);

  @override
  Future<void> appendHistory(SessionResult result) async =>
      _history.insert(0, result);

  @override
  Future<void> resetStats() async {
    _lifetime = 0;
    _history.clear();
  }
}
