import 'package:ease_move/domain/exercise/exercise.dart';
import 'package:ease_move/domain/exercise/exercise_timeline.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/test_assets.dart';

void main() {
  group('side_blocks exercise (KNEE_001)', () {
    late Exercise exercise;
    late ExerciseTimeline timeline;

    setUp(() {
      exercise = loadExerciseFromDisk('KNEE_001');
      timeline = ExerciseTimeline.build(exercise);
    });

    test('flattens both side blocks into one absolute timeline', () {
      // 2 sides × 10 repetitions × 4 steps.
      expect(timeline.steps.length, 80);
      expect(timeline.totalRepetitions, 20);
      // Per repetition: 500 + 1800 + 5000 + 1800 = 9100 ms.
      expect(timeline.totalDurationMs, 20 * 9100);
    });

    test('steps are contiguous with no gaps or overlaps', () {
      int cursor = 0;
      for (final TimelineStep step in timeline.steps) {
        expect(step.startMs, cursor);
        cursor = step.endMs;
      }
      expect(cursor, timeline.totalDurationMs);
    });

    test('left block runs before right, and side is carried per step', () {
      expect(timeline.steps.first.side, BodySide.left);
      expect(timeline.steps.last.side, BodySide.right);
      final TimelineStep atSwitch = timeline.stepAt(10 * 9100);
      expect(atSwitch.side, BodySide.right);
      expect(
        atSwitch.repetition,
        1,
        reason: 'repetition counter restarts per side',
      );
    });

    test('repetition counting only credits finished repetitions', () {
      expect(timeline.completedRepetitionsAt(0), 0);
      expect(timeline.completedRepetitionsAt(9099), 0);
      expect(timeline.completedRepetitionsAt(9100), 1);
      expect(timeline.completedRepetitionsAt(timeline.totalDurationMs), 20);
      expect(timeline.completedRepetitionsInCurrentBlockAt(11 * 9100), 1);
    });

    test('progress follows the declared basis', () {
      expect(exercise.progress.basis, ProgressBasis.completedRepetitions);
      expect(
        timeline.progressAt(9100, ProgressBasis.completedRepetitions),
        closeTo(0.05, 1e-9),
      );
      expect(timeline.progressAt(9099, ProgressBasis.completedRepetitions), 0);
      // Same instant, time basis: partial credit.
      expect(
        timeline.progressAt(9100, ProgressBasis.sequenceTime),
        closeTo(9100 / timeline.totalDurationMs, 1e-9),
      );
    });

    test('a transition starts moving on the word, not halfway through it', () {
      final TimelineStep extend = timeline.steps[1];
      expect(extend.step.phase, 'PHASE_EXTEND');
      // FRAME_START is where the step before left off, so the step does not
      // play it again: at the instant "Повільно випряміть ногу" is said, the
      // leg is already on its way (docs/DECISIONS.md 80).
      expect(extend.frameAt(extend.startMs), 'FRAME_LEFT_MID');
      expect(
        extend.frameAt(extend.startMs + extend.durationMs ~/ 2),
        'FRAME_LEFT_EXTENDED',
      );
      expect(extend.frameAt(extend.endMs - 1), 'FRAME_LEFT_EXTENDED');
    });

    test('a two-frame transition arrives at once', () {
      // Most of the library has no intermediate frame. There the whole step is
      // the destination pose, so the picture and the word change together.
      final Exercise elbow = loadExerciseFromDisk('ELBOW_001');
      final ExerciseTimeline elbowTimeline = ExerciseTimeline.build(elbow);
      final TimelineStep flex = elbowTimeline.steps[1];
      expect(flex.step.phase, 'PHASE_B');
      expect(flex.step.frameTransition!.from, 'FRAME_EXTENDED');
      expect(flex.frameAt(flex.startMs), 'FRAME_FLEXED');
      expect(flex.frameAt(flex.endMs - 1), 'FRAME_FLEXED');
    });

    test('no step in the library opens on the pose it is leaving', () {
      // What the listener hears and what they see have to agree: a step that
      // spends its first moments on the pose it is moving away from puts the
      // picture behind the word by half a step (docs/DECISIONS.md 80). A step
      // that holds a pose has a single frame and nothing to move.
      final Map<String, dynamic> index = loadJsonFromDisk(
        'assets/content/uk/index.json',
      );
      int checked = 0;
      for (final dynamic entry in index['exercises'] as List<dynamic>) {
        final String id = (entry as Map)['id'] as String;
        final ExerciseTimeline built = ExerciseTimeline.build(
          loadExerciseFromDisk(id),
        );
        for (final TimelineStep step in built.steps) {
          final FrameTransition? transition = step.step.frameTransition;
          if (transition == null) continue;
          checked++;
          expect(
            step.frameAt(step.startMs),
            isNot(transition.from),
            reason: '$id/${step.step.id} opens on the pose it is leaving',
          );
          expect(
            step.frameAt(step.endMs - 1),
            transition.to,
            reason: '$id/${step.step.id} does not arrive',
          );
        }
      }
      expect(checked, greaterThan(40), reason: 'the library has transitions');
    });

    test('reduced motion pins each step to one key pose', () {
      final TimelineStep extend = timeline.steps[1];
      expect(extend.step.frameTransition, isNotNull);

      // Normal playback travels through the intermediate pose...
      expect(extend.frameAt(extend.startMs), 'FRAME_LEFT_MID');
      expect(extend.frameAt(extend.endMs - 1), 'FRAME_LEFT_EXTENDED');

      // ...while reduced motion shows the settled pose for the whole step.
      expect(extend.keyFrameId, 'FRAME_LEFT_EXTENDED');

      // A hold step has a single frame either way.
      final TimelineStep hold = timeline.steps[2];
      expect(hold.step.frameId, 'FRAME_LEFT_EXTENDED');
      expect(hold.keyFrameId, 'FRAME_LEFT_EXTENDED');

      // Every step must resolve to a real frame in this mode too.
      for (final TimelineStep step in timeline.steps) {
        expect(
          exercise.frames.containsKey(step.keyFrameId),
          isTrue,
          reason: step.step.id,
        );
      }
    });

    test('phase cues are scheduled at every phase start', () {
      // "Тримайте" is a movement word, so it belongs to the rhythm mode; the
      // quiet default schedules no phase cue at all.
      final ExerciseTimeline rhythm = ExerciseTimeline.build(
        exercise,
        voiceMode: VoiceMode.phaseWords,
      );
      final List<ScheduledCue> holds = rhythm.cues
          .where((ScheduledCue cue) => cue.eventId == 'VOICE_HOLD')
          .toList();
      expect(holds.length, 20, reason: 'one hold cue per repetition');
      expect(holds.first.atMs, 500 + 1800);

      expect(
        timeline.cues.where((ScheduledCue cue) => cue.eventId == 'VOICE_HOLD'),
        isEmpty,
      );
    });

    test('play_once_per_side cue fires once per side', () {
      final List<ScheduledCue> toes = timeline.cues
          .where((ScheduledCue cue) => cue.eventId == 'VOICE_TOES')
          .toList();
      expect(toes.length, 2);
      expect(toes.first.atMs, 0);
      expect(toes.last.atMs, 10 * 9100);
    });

    test('side_block_completed cue lands at the end of the left block', () {
      final ScheduledCue cue = timeline.cues.firstWhere(
        (ScheduledCue cue) => cue.eventId == 'VOICE_SWITCH_SIDE',
      );
      expect(cue.atMs, 10 * 9100);
    });

    test('progress_crossed cue lands at the declared percentage', () {
      // No exercise uses this trigger any more — the halfway cue was the last
      // one, and it was dropped because it interrupted the movement — but the
      // engine still resolves it, so it is exercised against a cue added to a
      // real exercise here rather than left untested.
      final Map<String, dynamic> raw = loadJsonFromDisk(
        'assets/content/uk/exercises/KNEE_001.json',
      );
      (raw['audio']['events'] as List<dynamic>).add(<String, dynamic>{
        'id': 'VOICE_THREE_QUARTERS',
        'type': 'progress',
        'priority': 50,
        'interruptible': true,
        'text': 'Три чверті.',
        'trigger': <String, dynamic>{
          'event': 'progress_crossed',
          'percent': 75,
        },
      });
      final ExerciseTimeline built = ExerciseTimeline.build(
        Exercise.fromJson(raw),
      );
      final ScheduledCue cue = built.cues.firstWhere(
        (ScheduledCue cue) => cue.eventId == 'VOICE_THREE_QUARTERS',
      );
      expect(cue.atMs, (built.totalDurationMs * 75 / 100).round());
    });

    test('last repetition cue fires once per block', () {
      final List<ScheduledCue> last = timeline.cues
          .where((ScheduledCue cue) => cue.eventId == 'VOICE_LAST_REP')
          .toList();
      expect(last.length, 2);
      expect(last.first.atMs, 9 * 9100);
    });

    test('cues are ordered by time, then by descending priority', () {
      for (int i = 1; i < timeline.cues.length; i++) {
        final ScheduledCue previous = timeline.cues[i - 1];
        final ScheduledCue current = timeline.cues[i];
        expect(previous.atMs <= current.atMs, isTrue);
        if (previous.atMs == current.atMs) {
          expect(previous.priority >= current.priority, isTrue);
        }
      }
    });

    test('timing multiplier scales every step', () {
      final ExerciseTimeline fast = ExerciseTimeline.build(
        exercise,
        timingMultiplier: 0.5,
      );
      expect(fast.totalDurationMs, timeline.totalDurationMs ~/ 2);
      expect(fast.steps.length, timeline.steps.length);
    });
  });

  group('cycle exercise (NECK_002)', () {
    test('repeat_cycles becomes one sideless block', () {
      final Exercise exercise = loadExerciseFromDisk('NECK_002');
      final ExerciseTimeline timeline = ExerciseTimeline.build(exercise);

      expect(exercise.sequence.blocks.length, 1);
      expect(exercise.sequence.blocks.single.side, isNull);
      expect(timeline.steps.length, 3 * 8);
      expect(timeline.totalRepetitions, 3);
      // A per-step side still drives the side label mid-cycle.
      expect(timeline.steps[1].effectiveSide, BodySide.left);
      expect(timeline.steps[5].effectiveSide, BodySide.right);
      expect(exercise.progress.basis, ProgressBasis.sequenceTime);
    });
  });

  group('full_cycle exercise (KNEE_002)', () {
    test('repeat becomes one block with five repetitions', () {
      final Exercise exercise = loadExerciseFromDisk('KNEE_002');
      final ExerciseTimeline timeline = ExerciseTimeline.build(exercise);

      expect(timeline.totalRepetitions, 5);
      expect(timeline.steps.length, 5 * 5);
      expect(exercise.repetitionModel.type, 'full_cycle');
      expect(timeline.steps.every((TimelineStep s) => s.side == null), isTrue);
    });
  });
}
