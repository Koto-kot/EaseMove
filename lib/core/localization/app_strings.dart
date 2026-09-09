/// Key-based UI strings.
///
/// The single source is `data/localization/<locale>/common.yaml`, compiled to
/// `assets/content/localization/<locale>.json` by scripts/build_content.py, so
/// UI strings and exercise content stay in one authoring pipeline
/// (docs/LOCALIZATION.md). Widgets never hold visible literals.
library;

import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

class AppStrings {
  const AppStrings({required this.locale, required this.strings});

  final String locale;
  final Map<String, String> strings;

  static const List<String> supportedLocales = <String>['uk', 'en'];
  static const String fallbackLocale = 'en';

  static Future<AppStrings> load(String locale, {AssetBundle? bundle}) async {
    final AssetBundle assets = bundle ?? rootBundle;
    Map<String, String> loaded;
    try {
      loaded = _decode(
        await assets.loadString('assets/content/localization/$locale.json'),
      );
    } on Object {
      // A language pack may not be built yet; keys then render as keys rather
      // than crashing the screen. Fallback English is handled by localeProvider.
      loaded = <String, String>{};
    }
    return AppStrings(locale: locale, strings: loaded);
  }

  static Map<String, String> _decode(String raw) {
    final Map<String, dynamic> decoded =
        jsonDecode(raw) as Map<String, dynamic>;
    return decoded.map(
      (String key, dynamic value) => MapEntry<String, String>(key, '$value'),
    );
  }

  /// Returns the key itself when missing, which makes gaps obvious in review
  /// and keeps `showIds` developer mode useful.
  String call(String key) => strings[key] ?? key;

  String? maybe(String key) => strings[key];

  bool get isEmpty => strings.isEmpty;

  static AppStrings of(BuildContext context) {
    final AppStringsScope? scope = context
        .dependOnInheritedWidgetOfExactType<AppStringsScope>();
    assert(scope != null, 'AppStringsScope is missing above this widget');
    return scope!.strings;
  }
}

class AppStringsScope extends InheritedWidget {
  const AppStringsScope({
    required this.strings,
    required super.child,
    super.key,
  });

  final AppStrings strings;

  @override
  bool updateShouldNotify(AppStringsScope oldWidget) =>
      oldWidget.strings != strings;
}

/// UI string keys used by the app shell. Exercise-level text comes from the
/// exercise record itself, not from here.
abstract final class StringKeys {
  static const String previous = 'common.control.previous';
  static const String start = 'common.control.start';
  static const String pause = 'common.control.pause';
  static const String resume = 'common.control.continue';
  static const String stop = 'common.control.stop';
  static const String next = 'common.control.next';
  static const String exerciseStart = 'common.exercise.start';
  static const String elapsedTime = 'common.exercise.elapsed_time';
  static const String progress = 'common.exercise.progress';
  static const String repetition = 'common.exercise.repetition';
  static const String side = 'common.exercise.side';
  static const String sideLeft = 'common.exercise.side_left';
  static const String sideRight = 'common.exercise.side_right';
  static const String set = 'common.exercise.set';
  static const String startsIn = 'common.exercise.starts_in';
  static const String rest = 'common.exercise.rest';
  static const String nextExercise = 'common.exercise.next_exercise';

  static String bodyZone(String zoneId) => 'body_zone.$zoneId';
}
