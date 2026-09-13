/// One menu, on every screen, and one list inside it
/// (docs/DECISIONS.md 84 and 87).
///
/// The home screen used to be the only way to reach Settings, through a second
/// header button; from a catalogue or mid-exercise there was no way at all.
/// And the menu itself asked a question — activity or settings? — before
/// showing anything. These tests walk into the app and check both are gone.
library;

import 'package:ease_move/app/app.dart';
import 'package:ease_move/app/providers.dart';
import 'package:ease_move/core/audio/audio_service.dart';
import 'package:ease_move/core/storage/local_store.dart';
import 'package:ease_move/features/menu/menu_screen.dart';
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

  testWidgets('the menu is one list, with no question in front of it', (
    WidgetTester tester,
  ) async {
    await pumpApp(tester, store);

    await tester.tap(find.byTooltip('Меню'));
    await settle(tester);

    expect(find.byType(MenuScreen), findsOneWidget);
    // Activity is a row in the list, not one of two doors.
    expect(find.text('Моя активність'), findsOneWidget);
    expect(find.text('Голосові команди'), findsOneWidget);
    expect(find.text('Фонова музика'), findsOneWidget);
    expect(find.text('Мова'), findsOneWidget);

    // The menu does not offer to open itself.
    expect(
      find.descendant(
        of: find.byType(AppBar).last,
        matching: find.byTooltip('Меню'),
      ),
      findsNothing,
    );
  });

  testWidgets('a group holds its switch and its choice, and shows neither '
      'until it is opened', (WidgetTester tester) async {
    await pumpApp(tester, store);
    await tester.tap(find.byTooltip('Меню'));
    await settle(tester);

    // Closed, a row is a name and nothing else: no melody named under it, no
    // switch on it to mistake the row for (docs/DECISIONS.md 91).
    expect(find.text('Вечірнє фортепіано'), findsNothing);
    expect(find.text('Увімкнено'), findsNothing);

    await tester.tap(find.text('Фонова музика'));
    await settle(tester);
    expect(find.text('Увімкнено'), findsOneWidget);
    expect(find.text('Вечірнє фортепіано'), findsOneWidget);
    expect(find.text('Японський спокій'), findsOneWidget);
    expect(
      find.text('Торкніться, щоб послухати'),
      findsNothing,
      reason: 'a tap teaches that better than a sentence',
    );

    // The switch is the first thing in the group, above what it governs.
    await tester.tap(find.text('Увімкнено'));
    await settle(tester);
    expect(store.readSettings().musicEnabled, isFalse);
    expect(find.text('Вечірнє фортепіано'), findsNothing);
    expect(find.text('Увімкнено'), findsOneWidget);
  });

  testWidgets('what leaves the app is at the end of the menu', (
    WidgetTester tester,
  ) async {
    await pumpApp(tester, store);
    await tester.tap(find.byTooltip('Меню'));
    await settle(tester);

    // Everything above changes this app; these two open another screen, so
    // they sit under the settings rather than over them.
    final double music = tester.getTopLeft(find.text('Фонова музика')).dy;
    final double activity = tester.getTopLeft(find.text('Моя активність')).dy;
    final double pro = tester.getTopLeft(find.text('Мій план PRO')).dy;
    expect(activity, greaterThan(music));
    expect(pro, greaterThan(activity));
  });
}
