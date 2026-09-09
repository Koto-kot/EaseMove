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
      ],
      child: const EaseMoveApp(),
    ),
  );
}
