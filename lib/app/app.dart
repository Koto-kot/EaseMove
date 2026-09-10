/// Root widget: theme, localization scope and the app shell.
library;

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/localization/app_strings.dart';
import '../features/home/home_screen.dart';
import 'providers.dart';
import 'theme.dart';

class EaseMoveApp extends ConsumerWidget {
  const EaseMoveApp({super.key});

  static const List<LocalizationsDelegate<dynamic>> _delegates =
      <LocalizationsDelegate<dynamic>>[
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<AppStrings> strings = ref.watch(stringsProvider);
    final String locale = ref.watch(localeProvider);
    final List<Locale> supported = <Locale>[
      for (final String code in AppStrings.supportedLocales) Locale(code),
    ];

    return MaterialApp(
      title: 'EaseMove',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      locale: Locale(locale),
      supportedLocales: supported,
      localizationsDelegates: _delegates,
      // The scope goes in `builder` so it sits above the Navigator and every
      // pushed route (catalog, player) can resolve strings too.
      builder: (BuildContext context, Widget? child) => strings.when(
        loading: () => const _Splash(),
        error: (Object error, StackTrace stack) => const _Splash(failed: true),
        data: (AppStrings t) =>
            AppStringsScope(strings: t, child: child ?? const _Splash()),
      ),
      home: const HomeScreen(),
    );
  }
}

class _Splash extends StatelessWidget {
  const _Splash({this.failed = false});

  final bool failed;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: failed
            ? const Icon(Icons.error_outline, size: 40)
            : const CircularProgressIndicator(),
      ),
    );
  }
}
