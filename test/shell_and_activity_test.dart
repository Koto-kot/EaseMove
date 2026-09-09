/// Screens around the player: the situation tabs and the activity history.
library;

import 'package:ease_move/app/app.dart';
import 'package:ease_move/app/providers.dart';
import 'package:ease_move/core/audio/audio_service.dart';
import 'package:ease_move/core/config/feature_flags.dart';
import 'package:ease_move/core/storage/local_store.dart';
import 'package:ease_move/domain/exercise/session_machine.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/test_assets.dart';

void main() {
  late InMemoryLocalStore store;
  late ProviderContainer container;

  Widget wrap() {
    return ProviderScope(
      overrides: <Override>[
        environmentProvider.overrideWithValue(AppEnvironment.development),
        localStoreProvider.overrideWithValue(store),
        assetBundleProvider.overrideWithValue(DiskAssetBundle()),
        audioServiceProvider.overrideWithValue(LoggingAudioService()),
      ],
      child: Consumer(
        builder: (BuildContext context, WidgetRef ref, Widget? child) {
          container = ProviderScope.containerOf(context);
          return const EaseMoveApp();
        },
      ),
    );
  }

  Future<void> settle(WidgetTester tester) async {
    for (int i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  setUp(() async {
    store = InMemoryLocalStore();
    await store.writeSettings(const AppSettings(localeOverride: 'uk'));
  });

  testWidgets(
    'a situation without content names itself instead of showing a bare notice',
    (WidgetTester tester) async {
      tester.view
        ..devicePixelRatio = 1.0
        ..physicalSize = const Size(400, 900);
      addTearDown(tester.view.reset);

      await tester.pumpWidget(wrap());
      await settle(tester);

      // Очі ships before its exercises do. The body map also offers it as a
      // quick-start tile, so address the navigation bar explicitly.
      await tester.tap(
        find.descendant(
          of: find.byType(NavigationBar),
          matching: find.text('Очі'),
        ),
      );
      await settle(tester);

      expect(find.text('Для цієї зони ще немає вправ.'), findsOneWidget);
      expect(
        find.text('Очі'),
        findsNWidgets(3),
        reason: 'nav label, app bar title and the empty-state heading',
      );
    },
  );

  testWidgets('a situation with content lists its exercises', (
    WidgetTester tester,
  ) async {
    tester.view
      ..devicePixelRatio = 1.0
      ..physicalSize = const Size(400, 900);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(wrap());
    await settle(tester);

    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text("За комп'ютером"),
      ),
    );
    await settle(tester);

    // NECK_001 and KNEE_001 both belong to computer_break.
    expect(find.text('Повороти голови'), findsOneWidget);
    expect(find.text('Розгинання ноги сидячи'), findsOneWidget);
  });

  testWidgets('activity history shows exercise titles, not ids', (
    WidgetTester tester,
  ) async {
    await store.appendHistory(
      SessionResult(
        exerciseId: 'KNEE_002',
        startedAt: DateTime(2026, 9, 8, 19, 30),
        actualActiveSeconds: 42,
        completed: true,
        earlyStop: false,
        completedRepetitions: 5,
        side: null,
        collectionId: 'body_knees',
        pauseCount: 0,
      ),
    );
    await store.incrementLifetimeCount();

    await tester.pumpWidget(wrap());
    await settle(tester);

    await tester.tap(find.byIcon(Icons.insights_outlined));
    await settle(tester);

    expect(find.text('Встати — сісти зі стільця'), findsOneWidget);
    expect(find.text('KNEE_002'), findsNothing);
    expect(find.text('1'), findsOneWidget, reason: 'lifetime counter');
    expect(find.textContaining('завершено'), findsOneWidget);

    expect(container.read(activityStatsProvider).lifetimeCount, 1);
  });

  testWidgets('an unknown exercise id still renders, falling back to the id', (
    WidgetTester tester,
  ) async {
    await store.appendHistory(
      SessionResult(
        exerciseId: 'RETIRED_001',
        startedAt: DateTime(2026, 9, 8, 19, 30),
        actualActiveSeconds: 12,
        completed: false,
        earlyStop: true,
        completedRepetitions: 0,
        side: null,
        collectionId: null,
        pauseCount: 1,
      ),
    );

    await tester.pumpWidget(wrap());
    await settle(tester);
    await tester.tap(find.byIcon(Icons.insights_outlined));
    await settle(tester);

    expect(find.text('RETIRED_001'), findsOneWidget);
    expect(find.textContaining('зупинено раніше'), findsOneWidget);
  });
}
