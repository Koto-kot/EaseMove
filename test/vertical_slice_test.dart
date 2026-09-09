/// The first code slice's acceptance criteria, end to end
/// (docs/TECHNICAL_SPEC.md 21):
///
///   Тіло → Коліна → 3 картки → KNEE_001 → Старт → 5 → active →
///   Пауза/Продовжити → завершення → +1 → 10 → auto-start наступної
///
/// Runs as a widget test rather than an on-device integration test so it stays
/// in CI; the developer timing multiplier keeps it fast without changing any
/// sequencing logic.
library;

import 'package:ease_move/app/app.dart';
import 'package:ease_move/app/providers.dart';
import 'package:ease_move/core/audio/audio_service.dart';
import 'package:ease_move/core/config/feature_flags.dart';
import 'package:ease_move/core/storage/local_store.dart';
import 'package:ease_move/data/tracking_repository.dart';
import 'package:ease_move/domain/exercise/session_machine.dart';
import 'package:ease_move/features/exercise_player/player_controller.dart';
import 'package:ease_move/features/exercise_player/player_screen.dart';
import 'package:ease_move/shared/widgets/exercise_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/test_assets.dart';

/// 0.1x keeps the exercise logic identical while shrinking wall time:
/// KNEE_001 runs 18.2 s instead of 182 s.
const double _speedUp = 0.1;

const PlayerArgs _knee001 = (
  exerciseId: 'KNEE_001',
  collectionId: 'body_knees',
);

void main() {
  late InMemoryLocalStore store;
  late LoggingAudioService audio;
  late ProviderContainer container;

  /// The test platform reports en-US, so the Ukrainian authoring locale is
  /// pinned explicitly — the same manual override a user can pick.
  Future<InMemoryLocalStore> seededStore({
    bool skipCountdowns = false,
    double timingMultiplier = 1.0,
  }) async {
    final InMemoryLocalStore store = InMemoryLocalStore();
    await store.writeSettings(
      AppSettings(
        localeOverride: 'uk',
        devSkipCountdowns: skipCountdowns,
        devTimingMultiplier: timingMultiplier,
      ),
    );
    return store;
  }

  Widget wrap(AppEnvironment environment) {
    return ProviderScope(
      overrides: <Override>[
        environmentProvider.overrideWithValue(environment),
        localStoreProvider.overrideWithValue(store),
        assetBundleProvider.overrideWithValue(DiskAssetBundle()),
        audioServiceProvider.overrideWithValue(audio),
      ],
      child: Consumer(
        builder: (BuildContext context, WidgetRef ref, Widget? child) {
          container = ProviderScope.containerOf(context);
          return const EaseMoveApp();
        },
      ),
    );
  }

  /// Lets async provider work and a few ticks land, without settling forever
  /// (the session ticker never goes idle).
  Future<void> settle(WidgetTester tester, {int frames = 8}) async {
    for (int i = 0; i < frames; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  /// A phone-sized surface, so the layout under test is the real one.
  void usePhoneScreen(WidgetTester tester) {
    tester.view
      ..devicePixelRatio = 1.0
      ..physicalSize = const Size(400, 900);
    addTearDown(tester.view.reset);
  }

  /// The body map fills most of the first screen; the zone list sits below it.
  Future<void> openKneeZone(WidgetTester tester) async {
    final Finder tile = find.widgetWithText(ListTile, 'Коліна');
    await tester.scrollUntilVisible(
      tile,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await settle(tester);
    await tester.tap(tile);
    await settle(tester);
  }

  PlayerState playerState() =>
      container.read(playerControllerProvider(_knee001));

  testWidgets('Body → Knees → KNEE_001 → start → pause → complete → auto-next', (
    WidgetTester tester,
  ) async {
    store = await seededStore(timingMultiplier: _speedUp);
    audio = LoggingAudioService();
    usePhoneScreen(tester);

    await tester.pumpWidget(wrap(AppEnvironment.development));
    await settle(tester);

    // --- Тіло: the body map and its zone list are on screen.
    expect(find.text('Тіло'), findsWidgets);
    expect(find.text('Оберіть зону'), findsOneWidget);

    // --- Коліна: three large cards.
    await openKneeZone(tester);
    expect(find.byType(ExerciseCard), findsNWidgets(3));
    expect(find.text('Розгинання ноги сидячи'), findsOneWidget);

    // --- KNEE_001 opens in SELECTED and waits for an explicit Start.
    await tester.tap(find.text('Почати').first);
    await settle(tester);
    expect(find.byType(PlayerScreen), findsOneWidget);
    expect(find.text('Початкове положення'), findsOneWidget);
    expect(playerState().state, SessionState.selected);

    // --- Start → 5 second prep countdown; the exercise timer stays at zero.
    await tester.tap(find.widgetWithText(FilledButton, 'Старт'));
    await settle(tester);
    expect(find.text('Починаємо через'), findsOneWidget);
    expect(playerState().state, SessionState.prepCountdown);
    expect(playerState().snapshot.elapsedMs, 0);
    expect(audio.log, contains('tick:5'));

    await tester.pump(const Duration(seconds: 2));
    expect(find.text('3'), findsOneWidget);

    // --- Countdown over: active, music started, metrics from the exercise data.
    await tester.pump(const Duration(seconds: 4));
    expect(playerState().state, SessionState.active);
    expect(find.text('Починаємо через'), findsNothing);
    expect(audio.log.where((String e) => e.startsWith('music:')), isNotEmpty);
    expect(find.text('Час'), findsOneWidget);
    expect(find.text('Повтор'), findsOneWidget);
    expect(find.text('Нога'), findsOneWidget);

    // --- Pause freezes the timeline; Continue resumes from the same position.
    await tester.pump(const Duration(seconds: 2));
    await tester.tap(find.widgetWithText(FilledButton, 'Пауза'));
    await settle(tester);
    expect(playerState().state, SessionState.paused);
    expect(audio.log, contains('pause'));

    final int frozenAt = playerState().snapshot.elapsedMs;
    expect(frozenAt, greaterThan(0));
    await tester.pump(const Duration(seconds: 3));
    expect(
      playerState().snapshot.elapsedMs,
      frozenAt,
      reason: 'a paused session must not advance',
    );

    await tester.tap(find.widgetWithText(FilledButton, 'Продовжити'));
    await settle(tester);
    expect(playerState().state, SessionState.active);
    expect(audio.log, contains('resume'));

    // --- Run to normal completion (18.2 s of exercise at 0.1x).
    await tester.pump(const Duration(seconds: 18));
    await settle(tester);

    final TrackingRepository tracking = container.read(
      trackingRepositoryProvider,
    );
    final ActivityStats stats = tracking.read();
    expect(stats.lifetimeCount, 1, reason: '+1 on normal completion');
    expect(stats.history.single.exerciseId, 'KNEE_001');
    expect(stats.history.single.completed, isTrue);
    expect(stats.history.single.collectionId, 'body_knees');
    expect(stats.history.single.completedRepetitions, 20);

    expect(playerState().state, SessionState.autoRest);
    expect(find.text('+1'), findsOneWidget);
    expect(find.text('Відпочинок'), findsOneWidget);
    // The next exercise is already visible during rest, and rest cannot be
    // skipped: there is no such control on screen.
    expect(find.text('Наступна вправа'), findsOneWidget);
    expect(find.text('Встати — сісти зі стільця'), findsOneWidget);

    // --- Rest reaches zero and the next exercise starts on its own, with its
    // own prep countdown.
    await tester.pump(const Duration(seconds: 10));
    await settle(tester);
    expect(find.text('Встати — сісти зі стільця'), findsWidgets);
    expect(find.text('Починаємо через'), findsOneWidget);
  });

  testWidgets('Stop is never framed as a failure and keeps the elapsed time', (
    WidgetTester tester,
  ) async {
    store = await seededStore(skipCountdowns: true, timingMultiplier: _speedUp);
    audio = LoggingAudioService();
    usePhoneScreen(tester);

    await tester.pumpWidget(wrap(AppEnvironment.development));
    await settle(tester);

    await openKneeZone(tester);
    await tester.tap(find.text('Почати').first);
    await settle(tester);
    await tester.tap(find.widgetWithText(FilledButton, 'Старт'));
    await tester.pump(const Duration(seconds: 3));

    await tester.tap(find.widgetWithText(OutlinedButton, 'Стоп'));
    await settle(tester);

    expect(find.text('Зупинено'), findsOneWidget);
    expect(find.text('Це не невдача. Ваш час збережено.'), findsOneWidget);

    final ActivityStats stats = container
        .read(trackingRepositoryProvider)
        .read();
    expect(stats.history.single.earlyStop, isTrue);
    expect(stats.history.single.actualActiveSeconds, greaterThan(0));
    expect(
      stats.lifetimeCount,
      0,
      reason: 'an early stop does not add +1 by default',
    );
  });

  testWidgets('production hides content that has not passed clinical review', (
    WidgetTester tester,
  ) async {
    store = await seededStore();
    audio = LoggingAudioService();
    usePhoneScreen(tester);

    await tester.pumpWidget(wrap(AppEnvironment.production));
    await settle(tester);

    // All four exercises are still pending_review, so no zone is offered.
    expect(find.text('Оберіть зону'), findsOneWidget);
    expect(find.widgetWithText(ListTile, 'Коліна'), findsNothing);
    expect(find.widgetWithText(ListTile, 'Шия'), findsNothing);
  });
}
