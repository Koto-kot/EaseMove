import 'dart:convert';
import 'dart:io';

import 'package:ease_move/core/localization/app_strings.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/test_assets.dart';

/// Locales translated in full. A partial pack is legitimate: the runtime
/// stacks it over the fallback, so it only has to carry what it translates.
const List<String> _fullLocales = <String>['uk', 'en'];
const List<String> _partialLocales = <String>['pl'];

/// Keys the app shell resolves at runtime. A missing key renders as the key
/// itself, so this list is the guard against that reaching a screen.
const List<String> _requiredKeys = <String>[
  StringKeys.previous,
  StringKeys.start,
  StringKeys.pause,
  StringKeys.resume,
  StringKeys.stop,
  StringKeys.next,
  StringKeys.exerciseStart,
  StringKeys.elapsedTime,
  StringKeys.progress,
  StringKeys.repetition,
  StringKeys.side,
  StringKeys.sideLeft,
  StringKeys.sideRight,
  StringKeys.startsIn,
  StringKeys.rest,
  StringKeys.nextExercise,
  'app.name',
  'app.home.title',
  'app.home.subtitle',
  'app.home.menu',
  'app.home.card.body.title',
  'app.home.card.body.subtitle',
  'app.home.card.eyes.title',
  'app.home.card.eyes.subtitle',
  'app.home.card.morning.title',
  'app.home.card.morning.subtitle',
  'app.home.card.sitting.title',
  'app.home.card.sitting.subtitle',
  'app.zones.title',
  'app.body_map.zone_empty',
  'app.catalog.empty',
  'app.catalog.duration_minutes',
  'app.catalog.duration_seconds',
  'app.exercise.pending_review_notice',
  'app.exercise.frame_missing',
  'app.exercise.of_total',
  'app.exercise.completed_title',
  'app.exercise.stopped_title',
  'app.exercise.stopped_note',
  'app.exercise.no_next',
  'app.activity.title',
  'app.activity.lifetime',
  'app.activity.history',
  'app.activity.empty',
  'app.activity.completed',
  'app.activity.early_stop',
  'app.settings.title',
  'app.settings.language',
  'app.settings.language_system',
  'app.settings.audio',
  'app.settings.voice',
  'app.settings.music',
  'app.settings.reduced_motion',
  'app.settings.reminders',
  'app.settings.developer',
  'app.developer.pro_mode',
  'app.developer.show_pending',
  'app.developer.skip_countdown',
  'app.developer.show_ids',
  'app.developer.timing_multiplier',
  'app.developer.reset_stats',
  'app.developer.environment',
  'app.pro.badge',
  'app.pro.title',
  'app.paywall.title',
  'app.paywall.subscribe',
  'app.paywall.restore',
  'app.paywall.close',
  'app.paywall.not_available',
  'app.common.error',
  'app.common.back',
  'app.disclaimer',
];

Map<String, String> _pack(String locale) {
  final Map<String, dynamic> raw = jsonDecode(
    File('assets/content/localization/$locale.json').readAsStringSync(),
  ) as Map<String, dynamic>;
  return raw.map(
    (String key, dynamic value) => MapEntry<String, String>(key, '$value'),
  );
}

void main() {
  test('every supported locale has a built pack', () {
    for (final String locale in AppStrings.supportedLocales) {
      expect(
        File('assets/content/localization/$locale.json').existsSync(),
        isTrue,
        reason: locale,
      );
    }
  });

  test('the authoring locale and its translation carry the same keys', () {
    final Map<String, String> uk = _pack('uk');
    final Map<String, String> en = _pack('en');
    expect(en.keys.toSet(), uk.keys.toSet());
  });

  test('every key the app asks for exists in uk and en, non-empty', () {
    for (final String locale in _fullLocales) {
      final Map<String, String> pack = _pack(locale);
      for (final String key in _requiredKeys) {
        expect(
          pack.containsKey(key),
          isTrue,
          reason: '$locale is missing $key',
        );
        expect(
          pack[key]!.trim(),
          isNotEmpty,
          reason: '$locale has an empty $key',
        );
      }
    }
  });

  test('a partial pack invents no keys of its own', () {
    // Polish was delivered for the home screen only, so every key it does
    // carry must exist in the fallback too — otherwise it is a typo.
    final Set<String> en = _pack('en').keys.toSet();
    for (final String locale in _partialLocales) {
      for (final String key in _pack(locale).keys) {
        expect(en, contains(key), reason: '$locale/$key');
      }
    }
  });

  test(
    'a partial locale resolves every required key via the fallback',
    () async {
      for (final String locale in _partialLocales) {
        final AppStrings strings = await AppStrings.load(
          locale,
          bundle: DiskAssetBundle(),
        );
        for (final String key in _requiredKeys) {
          expect(strings(key), isNot(key), reason: '$locale/$key');
        }
        // ...and still prefers its own translation where it has one.
        expect(strings('app.home.title'), _pack(locale)['app.home.title']);
      }
    },
  );

  test('every body zone has a label', () {
    final Map<String, dynamic> index = loadJsonFromDisk(
      'assets/content/index.json',
    );
    for (final String locale in _fullLocales) {
      final Map<String, String> pack = _pack(locale);
      for (final dynamic zone in index['zones'] as List<dynamic>) {
        final String id = (zone as Map<String, dynamic>)['id'] as String;
        expect(
          pack.containsKey(StringKeys.bodyZone(id)),
          isTrue,
          reason: '$locale/$id',
        );
      }
    }
  });

  test('AppStrings falls back to the key when a string is missing', () async {
    final AppStrings strings = await AppStrings.load(
      'uk',
      bundle: DiskAssetBundle(),
    );
    expect(strings(StringKeys.start), isNot(StringKeys.start));
    expect(strings('nope.not.a.key'), 'nope.not.a.key');
    expect(strings.maybe('nope.not.a.key'), isNull);
  });

  test('an unsupported locale falls back to English, not to keys', () async {
    final AppStrings strings = await AppStrings.load(
      'zz',
      bundle: DiskAssetBundle(),
    );
    expect(strings.isEmpty, isFalse);
    expect(strings(StringKeys.start), _pack('en')[StringKeys.start]);
  });
}
