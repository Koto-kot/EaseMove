import 'package:ease_move/domain/exercise/exercise.dart';
import 'package:ease_move/domain/exercise/exercise_timeline.dart';
import 'package:ease_move/domain/exercise/session_machine.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/test_assets.dart';

/// Ticks in whole seconds; the machine has no wall clock of its own.
List<SessionEffect> advance(SessionMachine machine, int seconds) {
  final List<SessionEffect> effects = <SessionEffect>[];
  for (int i = 0; i < seconds; i++) {
    effects.addAll(machine.tick(const Duration(seconds: 1)));
  }
  return effects;
}

/// `hasNextExercise` defaults to true: most cases here are about autoplay,
/// which only exists when something follows.
SessionMachine machineFor(
  String id, {
  bool skipCountdowns = false,
  String? collectionId,
  bool hasNextExercise = true,
}) {
  final Exercise exercise = loadExerciseFromDisk(id);
  return SessionMachine(
    exercise: exercise,
    timeline: ExerciseTimeline.build(exercise),
    collectionId: collectionId,
    skipCountdowns: skipCountdowns,
    hasNextExercise: hasNextExercise,
  );
}

void main() {
  group('manual start', () {
    test('a selected exercise never starts without Start (invariant 3)', () {
      final SessionMachine machine = machineFor('KNEE_001');
      expect(machine.state, SessionState.selected);

      advance(machine, 30);
      expect(machine.state, SessionState.selected);
      expect(machine.elapsedMs, 0);
    });

    test('Start runs a 5 second prep countdown before the exercise timer', () {
      final SessionMachine machine = machineFor('KNEE_001');
      final List<SessionEffect> onStart = machine.handle(
        SessionEventType.start,
      );

      expect(machine.state, SessionState.prepCountdown);
      expect(machine.snapshot.prepSecondsLeft, 5);
      expect(
        machine.elapsedMs,
        0,
        reason: 'exercise timer waits for the countdown',
      );
      expect(
        onStart.whereType<PlayVoiceCue>().map((PlayVoiceCue c) => c.eventId),
        contains('VOICE_PREPARE'),
      );
      expect(
        onStart.whereType<PlayCountdownTick>().map(
          (PlayCountdownTick t) => t.secondsLeft,
        ),
        <int>[5],
      );

      final List<int> ticks = <int>[];
      for (int i = 0; i < 4; i++) {
        ticks.addAll(
          machine
              .tick(const Duration(seconds: 1))
              .whereType<PlayCountdownTick>()
              .map((PlayCountdownTick t) => t.secondsLeft),
        );
      }
      expect(ticks, <int>[4, 3, 2, 1]);
      expect(machine.state, SessionState.prepCountdown);

      final List<SessionEffect> last = machine.tick(const Duration(seconds: 1));
      expect(machine.state, SessionState.active);
      expect(last.whereType<StartMusic>(), isNotEmpty);
    });

    test('skipCountdowns goes straight to active', () {
      final SessionMachine machine = machineFor(
        'KNEE_001',
        skipCountdowns: true,
      );
      machine.handle(SessionEventType.start);
      expect(machine.state, SessionState.active);
    });
  });

  group('active session', () {
    test(
      'elapsed time, repetitions and side all advance from one timeline',
      () {
        final SessionMachine machine = machineFor(
          'KNEE_001',
          skipCountdowns: true,
        );
        machine.handle(SessionEventType.start);

        advance(machine, 9); // 9000 ms — first repetition is 9100 ms long
        expect(machine.completedRepetitions, 0);
        expect(machine.currentSide, BodySide.left);

        machine.tick(const Duration(milliseconds: 100));
        expect(machine.completedRepetitions, 1);
        expect(machine.progress, closeTo(0.05, 1e-9));

        advance(machine, 82); // into the right-side block
        expect(machine.currentSide, BodySide.right);
      },
    );

    test(
      'pause freezes the timeline and resume continues from the same point',
      () {
        final SessionMachine machine = machineFor(
          'KNEE_001',
          skipCountdowns: true,
        );
        machine.handle(SessionEventType.start);
        advance(machine, 5);
        final int frozenAt = machine.elapsedMs;

        final List<SessionEffect> onPause = machine.handle(
          SessionEventType.pause,
        );
        expect(machine.state, SessionState.paused);
        expect(onPause.whereType<PauseAudio>(), isNotEmpty);

        advance(machine, 10);
        expect(
          machine.elapsedMs,
          frozenAt,
          reason: 'a paused timeline must not drift',
        );

        final List<SessionEffect> onResume = machine.handle(
          SessionEventType.resume,
        );
        expect(machine.state, SessionState.active);
        expect(onResume.whereType<ResumeAudio>(), isNotEmpty);

        advance(machine, 1);
        expect(machine.elapsedMs, frozenAt + 1000);
        expect(machine.snapshot.pauseCount, 1);
      },
    );

    test('pausing during the prep countdown keeps the countdown position', () {
      final SessionMachine machine = machineFor('KNEE_001');
      machine.handle(SessionEventType.start);
      advance(machine, 2);
      expect(machine.snapshot.prepSecondsLeft, 3);

      machine.handle(SessionEventType.pause);
      advance(machine, 5);
      expect(machine.snapshot.prepSecondsLeft, 3);

      machine.handle(SessionEventType.resume);
      expect(machine.state, SessionState.prepCountdown);
    });

    test(
      'voice cues fire once, in priority order, as the timeline crosses them',
      () {
        final SessionMachine machine = machineFor(
          'KNEE_001',
          skipCountdowns: true,
        );
        final List<String> played = <String>[
          for (final SessionEffect effect in machine.handle(
            SessionEventType.start,
          ))
            if (effect is PlayVoiceCue) effect.eventId,
        ];

        // At offset 0 the timeline is still in PHASE_START, so only the
        // repetition-triggered technique hint is due.
        expect(played, <String>['VOICE_PREPARE', 'VOICE_TOES']);

        // Then the movement phases fire in sequence order across repetition 1.
        final List<String> firstRepetition = <String>[
          for (final SessionEffect effect in advance(machine, 9))
            if (effect is PlayVoiceCue) effect.eventId,
        ];
        expect(
          firstRepetition,
          containsAllInOrder(<String>[
            'VOICE_EXTEND',
            'VOICE_HOLD',
            'VOICE_LOWER',
          ]),
        );
        expect(
          firstRepetition.where((String id) => id == 'VOICE_TOES'),
          isEmpty,
          reason: 'play_once_per_side must not repeat inside a side block',
        );
      },
    );
  });

  group('stop', () {
    test('Stop is accepted in any active state and is not a failure', () {
      for (final SessionState from in <SessionState>[
        SessionState.prepCountdown,
        SessionState.active,
        SessionState.paused,
      ]) {
        final SessionMachine machine = machineFor('KNEE_001');
        machine.handle(SessionEventType.start);
        if (from != SessionState.prepCountdown) {
          advance(machine, 6);
          if (from == SessionState.paused) {
            machine.handle(SessionEventType.pause);
          }
        }

        final List<SessionEffect> effects = machine.handle(
          SessionEventType.stop,
        );
        expect(machine.state, SessionState.stopped, reason: 'from $from');
        final SaveResult saved = effects.whereType<SaveResult>().single;
        expect(saved.result.earlyStop, isTrue);
        expect(saved.result.completed, isFalse);
        expect(
          effects.whereType<IncrementLifetimeCounter>(),
          isEmpty,
          reason: 'default policy does not count an early stop',
        );
      }
    });

    test('an early stop keeps the actual time and finished repetitions', () {
      final SessionMachine machine = machineFor(
        'KNEE_001',
        skipCountdowns: true,
      );
      machine.handle(SessionEventType.start);
      advance(machine, 20);

      final SessionResult result = machine
          .handle(SessionEventType.stop)
          .whereType<SaveResult>()
          .single
          .result;
      expect(result.actualActiveSeconds, 20);
      expect(result.completedRepetitions, 2);
      expect(result.side, 'left');
    });

    test('the lifetime policy is configurable, not per-exercise', () {
      final Exercise exercise = loadExerciseFromDisk('KNEE_001');
      final SessionMachine machine = SessionMachine(
        exercise: exercise,
        timeline: ExerciseTimeline.build(exercise),
        skipCountdowns: true,
        countEarlyStopInLifetime: true,
      );
      machine.handle(SessionEventType.start);
      advance(machine, 5);
      expect(
        machine
            .handle(SessionEventType.stop)
            .whereType<IncrementLifetimeCounter>(),
        isNotEmpty,
      );
    });

    test('a stopped exercise can be started again from the beginning', () {
      final SessionMachine machine = machineFor(
        'KNEE_001',
        skipCountdowns: true,
      );
      machine.handle(SessionEventType.start);
      advance(machine, 10);
      machine.handle(SessionEventType.stop);

      machine.handle(SessionEventType.start);
      expect(machine.state, SessionState.active);
      expect(machine.elapsedMs, 0);
    });
  });

  group('normal completion and auto-next', () {
    test(
      'completion saves the result, adds +1 and starts the rest countdown',
      () {
        final SessionMachine machine = machineFor(
          'NECK_001',
          skipCountdowns: true,
        );
        machine.handle(SessionEventType.start);

        // NECK_001 is 3 cycles x 17 s = 51 s of active time.
        final List<SessionEffect> effects = advance(machine, 51);
        final SaveResult saved = effects.whereType<SaveResult>().single;
        expect(saved.result.completed, isTrue);
        expect(saved.result.earlyStop, isFalse);
        expect(effects.whereType<IncrementLifetimeCounter>().length, 1);
        expect(
          effects.whereType<PlayVoiceCue>().map((PlayVoiceCue c) => c.eventId),
          contains('VOICE_COMPLETED'),
        );

        expect(machine.state, SessionState.autoRest);
        expect(machine.snapshot.restSecondsLeft, 10);
        expect(machine.snapshot.autoModeEnabled, isTrue);
      },
    );

    test(
      'rest runs the full 10 seconds and then asks for the next exercise',
      () {
        final SessionMachine machine = machineFor(
          'NECK_001',
          skipCountdowns: true,
        );
        machine.handle(SessionEventType.start);
        advance(machine, 51);

        final List<SessionEffect> nineSeconds = advance(machine, 9);
        expect(nineSeconds.whereType<AutoStartNext>(), isEmpty);
        expect(machine.state, SessionState.autoRest);

        final List<SessionEffect> zero = advance(machine, 1);
        expect(zero.whereType<AutoStartNext>().length, 1);
      },
    );

    test('the result is saved once, not on every following tick', () {
      final SessionMachine machine = machineFor(
        'NECK_001',
        skipCountdowns: true,
      );
      machine.handle(SessionEventType.start);
      final List<SessionEffect> effects = advance(machine, 80);
      expect(effects.whereType<SaveResult>().length, 1);
      expect(effects.whereType<IncrementLifetimeCounter>().length, 1);
    });

    test('the last exercise of a collection completes instead of resting', () {
      // Resting towards an auto-start that can never happen left the session
      // parked on a rest screen with the countdown at zero.
      final SessionMachine machine = machineFor(
        'KNEE_001',
        skipCountdowns: true,
        hasNextExercise: false,
      );
      machine.handle(SessionEventType.start);
      advance(machine, machine.timeline.totalDurationMs ~/ 1000 + 1);
      expect(machine.state, SessionState.completed);
      expect(machine.snapshot.autoModeEnabled, isFalse);
    });

    test('an auto-started exercise still gets its prep countdown', () {
      final SessionMachine machine = machineFor('KNEE_001');
      final List<SessionEffect> effects = machine.beginAutoStarted();

      expect(machine.state, SessionState.prepCountdown);
      expect(machine.snapshot.autoModeEnabled, isTrue);
      expect(effects.whereType<PlayCountdownTick>(), isNotEmpty);
    });
  });

  group('manual browse during rest (invariant 2)', () {
    test('Next cancels autoplay and requires a manual Start afterwards', () {
      final SessionMachine machine = machineFor(
        'NECK_001',
        skipCountdowns: true,
      );
      machine.handle(SessionEventType.start);
      advance(machine, 51);
      expect(machine.state, SessionState.autoRest);

      final List<SessionEffect> effects = machine.handle(SessionEventType.next);
      expect(machine.state, SessionState.manualBrowseNext);
      expect(machine.snapshot.autoModeEnabled, isFalse);
      expect(effects.whereType<RequestManualBrowse>().single.direction, 1);

      // The rest countdown is gone, so nothing can auto-start any more.
      final List<SessionEffect> later = advance(machine, 30);
      expect(later.whereType<AutoStartNext>(), isEmpty);
    });

    test(
      'Previous during an active exercise saves the attempt and stops audio',
      () {
        final SessionMachine machine = machineFor(
          'KNEE_001',
          skipCountdowns: true,
        );
        machine.handle(SessionEventType.start);
        advance(machine, 12);

        final List<SessionEffect> effects = machine.handle(
          SessionEventType.previous,
        );
        expect(effects.whereType<SaveResult>().single.result.earlyStop, isTrue);
        expect(effects.whereType<StopAudio>(), isNotEmpty);
        expect(effects.whereType<RequestManualBrowse>().single.direction, -1);
        expect(machine.state, SessionState.manualBrowseNext);
      },
    );
  });

  group('leaving the flow', () {
    test(
      'Exit stops autoplay, clears the session and keeps the statistics',
      () {
        final SessionMachine machine = machineFor(
          'KNEE_001',
          skipCountdowns: true,
        );
        machine.handle(SessionEventType.start);
        advance(machine, 15);

        final List<SessionEffect> effects = machine.handle(
          SessionEventType.exit,
        );
        expect(machine.state, SessionState.exited);
        expect(effects.whereType<SaveResult>().length, 1);
        expect(effects.whereType<StopAudio>(), isNotEmpty);
        expect(machine.snapshot.autoModeEnabled, isFalse);
      },
    );

    test('Exit from a browse state saves nothing', () {
      final SessionMachine machine = machineFor('KNEE_001');
      final List<SessionEffect> effects = machine.handle(SessionEventType.exit);
      expect(effects.whereType<SaveResult>(), isEmpty);
    });
  });

  test('the tracked result carries the source collection', () {
    final SessionMachine machine = machineFor(
      'KNEE_001',
      skipCountdowns: true,
      collectionId: 'body_knees',
    );
    machine.handle(SessionEventType.start);
    advance(machine, 3);
    final SessionResult result = machine
        .handle(SessionEventType.stop)
        .whereType<SaveResult>()
        .single
        .result;
    expect(result.collectionId, 'body_knees');
    expect(SessionResult.fromJson(result.toJson()).collectionId, 'body_knees');
  });
}
