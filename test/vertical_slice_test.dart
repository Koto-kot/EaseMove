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

  /// The approved map shows halo dots with no permanent labels, so the knee
  /// is reached by tapping its hotspot. Both knees are one paired zone: the
  /// pair pulses first, then navigation happens, so the pulse has to be given
  /// time to finish.
  Future<void> openKneeZone(WidgetTester tester) async {
    await tester.tap(find.byKey(const ValueKey<String>('hotspot.left_knee')));
    await tester.pump(const Duration(milliseconds: 400));
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

    // --- Home: the reserved title block, the map and the four cards.
    expect(find.text('Рухайся легше'), findsOneWidget);
    expect(find.text('Тіло'), findsOneWidget, reason: 'the Body card');
    expect(
      find.byKey(const ValueKey<String>('hotspot.left_knee')),
      findsOneWidget,
    );

    // --- Коліна: three large cards.
    await openKneeZone(tester);
    expect(find.byType(ExerciseCard), findsNWidgets(3));
    expect(find.text('Розгинання ноги сидячи'), findsOneWidget);

    // --- KNEE_001 opens in SELECTED and waits for an explicit Start.
    await tester.tap(find.text('Почати').first);
    await settle(tester);
    expect(find.byType(PlayerScreen), findsOneWidget);
    expect(playerState().state, SessionState.selected);

    // The instruction waits behind its own button, so the model keeps the
    // screen (docs/UX_FLOW.md C).
    expect(find.text('Початкове положення'), findsNothing);
    await tester.tap(find.text('Прочитати інструкцію'));
    await settle(tester);
    expect(find.text('Початкове положення'), findsOneWidget);

    // --- Start → five is lit, the setup line is said, nothing counts yet.
    await tester.tap(find.widgetWithText(FilledButton, 'Старт'));
    await settle(tester);
    expect(playerState().state, SessionState.prepCountdown);
    expect(playerState().snapshot.elapsedMs, 0);
    expect(audio.log, contains('voice:VOICE_PREPARE'));
    expect(find.text('Починаємо через'), findsOneWidget);
    expect(find.text('5'), findsOneWidget);
    expect(audio.log, isNot(contains('tick:4')));

    // --- The setup line ends, the opening announces the five itself, and the
    // ticking picks up at four. The exercise timer stays at zero throughout.
    await tester.pump(
      Duration(milliseconds: playerState().exercise!.timing.prepIntroMs),
    );
    expect(audio.log, contains('line:countdown_opening'));
    expect(audio.log, isNot(contains('tick:4')));
    expect(find.text('5'), findsOneWidget);

    await tester.pump(
      Duration(milliseconds: playerState().exercise!.timing.countdownOpeningMs),
    );
    expect(audio.log, contains('tick:4'));
    expect(playerState().snapshot.elapsedMs, 0);

    await tester.pump(const Duration(seconds: 2));
    expect(find.text('2'), findsOneWidget);

    // --- Countdown over: active, music started, metrics from the exercise data.
    await tester.pump(const Duration(seconds: 3));
    expect(playerState().state, SessionState.active);
    expect(find.text('Починаємо через'), findsNothing);
    expect(audio.log.where((String e) => e.startsWith('music:')), isNotEmpty);
    expect(find.text('Час'), findsOneWidget);
    expect(find.text('Повтор'), findsOneWidget);
    expect(find.text('Нога'), findsOneWidget);

    // --- Pause freezes the timeline; Continue resumes from the same position.
    await tester.pump(const Duration(seconds: 2));
    await tester.tap(find.byTooltip('Пауза'));
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

    await tester.tap(find.byTooltip('Продовжити'));
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
    // own setup line and then its own prep countdown.
    // The break announces itself, then counts the seconds it is showing.
    await tester.pump(const Duration(seconds: 5));
    expect(audio.log, contains('line:rest_intro'));

    await tester.pump(const Duration(seconds: 6));
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

    await tester.tap(find.byTooltip('Стоп'));
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

  testWidgets('a production build shows the same library as any other', (
    WidgetTester tester,
  ) async {
    // The clinical gate used to empty the app here, because nothing in the
    // library is marked approved (docs/DECISIONS.md 88).
    store = await seededStore();
    audio = LoggingAudioService();
    usePhoneScreen(tester);

    await tester.pumpWidget(wrap(AppEnvironment.production));
    await settle(tester);

    expect(find.text('Рухайся легше'), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('hotspot.left_knee')),
      findsOneWidget,
    );

    await openKneeZone(tester);
    expect(find.byType(ExerciseCard), findsNWidgets(3));
  });
  testWidgets('the last exercise in a collection ends on a completion screen', (
    WidgetTester tester,
  ) async {
    store = await seededStore(skipCountdowns: true, timingMultiplier: _speedUp);
    audio = LoggingAudioService();
    usePhoneScreen(tester);

    await tester.pumpWidget(wrap(AppEnvironment.development));
    await settle(tester);

    await openKneeZone(tester);
    // The third card is the last exercise in body_knees, so nothing can
    // auto-start behind it and the session ends in COMPLETED, not AUTO_REST.
    await tester.tap(find.text('Почати').last);
    await settle(tester);
    await tester.tap(find.widgetWithText(FilledButton, 'Старт'));
    await tester.pump(const Duration(seconds: 10));
    await settle(tester);

    final PlayerState state = container.read(
      playerControllerProvider((
        exerciseId: 'KNEE_003',
        collectionId: 'body_knees',
      )),
    );
    expect(state.state, SessionState.completed);
    expect(state.nextSummary, isNull);

    // What the session earned, then where else to go in the same zone.
    expect(find.text('Усього вправ'), findsOneWidget);
    expect(find.text('+1'), findsOneWidget);
    expect(find.textContaining('Інші вправи'), findsOneWidget);
    expect(find.text('Розгинання ноги сидячи'), findsOneWidget);

    await tester.tap(find.text('До тіла'));
    await settle(tester);
    expect(find.text('Рухайся легше'), findsOneWidget);
  });
}
