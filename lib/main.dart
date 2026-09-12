/// Entry point.
///
/// The environment is compile-time (`--dart-define=ENV=production`), so a
/// release build cannot be talked into development flags at runtime
/// (docs/FEATURE_FLAGS.md).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'app/providers.dart';
import 'core/audio/recorded_voice_audio_service.dart';
import 'core/audio/tts_audio_service.dart';
import 'core/config/feature_flags.dart';
import 'core/storage/local_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  const String envName = String.fromEnvironment(
    'ENV',
    defaultValue: 'development',
  );
  final AppEnvironment environment = switch (envName) {
    'production' => AppEnvironment.production,
    'test' => AppEnvironment.test,
    _ => AppEnvironment.development,
  };

  final PreferencesLocalStore store = await PreferencesLocalStore.open();

  runApp(
    ProviderScope(
      overrides: <Override>[
        environmentProvider.overrideWithValue(environment),
        localStoreProvider.overrideWithValue(store),
        // The provider's default is the logging stub, so tests never reach a
        // platform channel; the real app speaks the authored cues.
        audioServiceProvider.overrideWith((Ref ref) {
          final String locale = ref.watch(localeProvider);
          // Recorded lines win; everything not recorded yet is spoken.
          return RecordedVoiceAudioService(
            languageCode: locale,
            fallback: TtsAudioService(languageCode: locale),
          );
        }),
      ],
      child: const EaseMoveApp(),
    ),
  );
}
