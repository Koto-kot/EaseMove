/// Screens around the player: the home cards and the activity history.
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

  void usePhoneScreen(WidgetTester tester) {
    tester.view
      ..devicePixelRatio = 1.0
      ..physicalSize = const Size(400, 900);
    addTearDown(tester.view.reset);
  }

  Future<void> tapCard(WidgetTester tester, String id) async {
    await tester.tap(find.byKey(ValueKey<String>('home.card.$id')));
    await settle(tester);
  }

  /// Activity moved out of a floating action into the drawer, since the
  /// approved home has no bottom navigation.
  Future<void> openActivity(WidgetTester tester) async {
    await tester.tap(find.byTooltip('Меню'));
    await settle(tester);
    await tester.tap(find.text('Моя активність'));
    await settle(tester);
  }

  setUp(() async {
    store = InMemoryLocalStore();
    await store.writeSettings(const AppSettings(localeOverride: 'uk'));
  });

  testWidgets('the approved home shows four cards and no bottom navigation', (
    WidgetTester tester,
  ) async {
    usePhoneScreen(tester);
    await tester.pumpWidget(wrap());
    await settle(tester);

    // docs/ui/home/HOME_SCREEN_LAYOUT_SPEC.md 4-6.
    expect(find.byType(NavigationBar), findsNothing);
    expect(find.text('Рухайся легше'), findsOneWidget);
    for (final String id in <String>['body', 'eyes', 'morning', 'sitting']) {
      expect(find.byKey(ValueKey<String>('home.card.$id')), findsOneWidget);
    }
    // No permanent zone labels around the figure (brief 4.1).
    expect(find.text('Коліна'), findsNothing);
  });

  testWidgets('a card whose section is still empty opens its empty state', (
    WidgetTester tester,
  ) async {
    usePhoneScreen(tester);
    await tester.pumpWidget(wrap());
    await settle(tester);

    // Очі ships before its exercises do.
    await tapCard(tester, 'eyes');

    expect(find.text('Для цієї зони ще немає вправ.'), findsOneWidget);
    expect(
      find.text('Очі'),
      findsNWidgets(2),
      reason: 'the card behind it and the app bar title',
    );
  });

  testWidgets('a card with content lists its exercises', (
    WidgetTester tester,
  ) async {
    usePhoneScreen(tester);
    await tester.pumpWidget(wrap());
    await settle(tester);

    // NECK_001, KNEE_001 and KNEE_002 all belong to after_sitting.
    await tapCard(tester, 'sitting');

    expect(find.text('Повороти голови'), findsOneWidget);
    expect(find.text('Розгинання ноги сидячи'), findsOneWidget);
  });

  testWidgets('the Body card lists the zones that have exercises', (
    WidgetTester tester,
  ) async {
    usePhoneScreen(tester);
    await tester.pumpWidget(wrap());
    await settle(tester);

    await tapCard(tester, 'body');

    expect(find.text('Оберіть зону'), findsOneWidget);
    expect(find.text('Коліна'), findsOneWidget);
    expect(find.text('Шия'), findsOneWidget);
    // A zone with no exercises is not offered as a dead end here.
    expect(find.text('Стопи'), findsNothing);
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

    usePhoneScreen(tester);
    await tester.pumpWidget(wrap());
    await settle(tester);

    await openActivity(tester);

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

    usePhoneScreen(tester);
    await tester.pumpWidget(wrap());
    await settle(tester);
    await openActivity(tester);

    expect(find.text('RETIRED_001'), findsOneWidget);
    expect(find.textContaining('зупинено раніше'), findsOneWidget);
  });
}
