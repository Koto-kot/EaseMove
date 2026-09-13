/// One menu, on every screen (docs/DECISIONS.md 84).
///
/// The home screen used to be the only way to reach Settings, through a second
/// header button; from a catalogue or mid-exercise there was no way at all.
/// These tests walk into the app and check the button is still there.
library;

import 'package:ease_move/app/app.dart';
import 'package:ease_move/app/providers.dart';
import 'package:ease_move/core/audio/audio_service.dart';
import 'package:ease_move/core/storage/local_store.dart';
import 'package:ease_move/features/settings/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/test_assets.dart';

/// Long enough for a page transition to finish, so the screen underneath is
/// off stage and its own menu button is out of the finders' way.
Future<void> settle(WidgetTester tester) async {
  for (int i = 0; i < 16; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

/// The menu button of the screen on top.
///
/// A pushed route leaves the one below it in the tree, so an unscoped finder
/// counts that screen's button too; the top screen's app bar is the last one
/// built.
void expectMenuOnTop(WidgetTester tester, {required String reason}) {
  expect(
    find.descendant(
      of: find.byType(AppBar).last,
      matching: find.byTooltip('Меню'),
    ),
    findsOneWidget,
    reason: reason,
  );
}

Future<void> pumpApp(WidgetTester tester, InMemoryLocalStore store) async {
  tester.view
    ..devicePixelRatio = 1.0
    ..physicalSize = const Size(400, 900);
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[
        localStoreProvider.overrideWithValue(store),
        assetBundleProvider.overrideWithValue(DiskAssetBundle()),
        audioServiceProvider.overrideWithValue(LoggingAudioService()),
      ],
      child: const EaseMoveApp(),
    ),
  );
  await settle(tester);
}

void main() {
  late InMemoryLocalStore store;

  setUp(() async {
    store = InMemoryLocalStore();
    await store.writeSettings(const AppSettings(localeOverride: 'uk'));
  });

  testWidgets('the menu follows you from the home screen to the exercise', (
    WidgetTester tester,
  ) async {
    await pumpApp(tester, store);

    expect(find.byTooltip('Меню'), findsOneWidget, reason: 'home');
    expect(
      find.byIcon(Icons.settings_outlined),
      findsNothing,
      reason: 'the second header button is gone from the home screen',
    );

    await tester.tap(find.byKey(const ValueKey<String>('hotspot.left_knee')));
    await tester.pump(const Duration(milliseconds: 400));
    await settle(tester);
    expectMenuOnTop(tester, reason: 'the catalogue');

    await tester.tap(find.text('Почати').first);
    await settle(tester);
    expectMenuOnTop(tester, reason: 'the exercise screen');

    await tester.tap(find.widgetWithText(FilledButton, 'Старт'));
    await settle(tester);
    expectMenuOnTop(tester, reason: 'and during the exercise itself');
  });

  testWidgets('the menu opens Settings, and says so when it is already open', (
    WidgetTester tester,
  ) async {
    await pumpApp(tester, store);

    await tester.tap(find.byTooltip('Меню'));
    await settle(tester);
    expect(find.text('Моя активність'), findsOneWidget);
    await tester.tap(find.text('Налаштування'));
    await settle(tester);
    expect(find.byType(SettingsScreen), findsOneWidget);

    // The menu is here too, and the entry for this screen is marked rather
    // than opening a second copy of it.
    await tester.tap(find.byTooltip('Меню'));
    await settle(tester);
    final ListTile tile = tester.widget<ListTile>(
      find.ancestor(
        of: find.text('Налаштування').last,
        matching: find.byType(ListTile),
      ),
    );
    expect(tile.selected, isTrue);

    await tester.tap(find.text('Налаштування').last);
    await settle(tester);
    expect(
      find.byType(SettingsScreen),
      findsOneWidget,
      reason: 'the menu closed instead of pushing a second Settings',
    );
  });
}
