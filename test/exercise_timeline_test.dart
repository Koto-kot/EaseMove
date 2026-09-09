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

    test('frame transitions walk their frames in order', () {
      final TimelineStep extend = timeline.steps[1];
      expect(extend.step.phase, 'PHASE_EXTEND');
      expect(extend.frameAt(extend.startMs), 'FRAME_START');
      expect(
        extend.frameAt(extend.startMs + extend.durationMs ~/ 2),
        'FRAME_LEFT_MID',
      );
      expect(extend.frameAt(extend.endMs - 1), 'FRAME_LEFT_EXTENDED');
    });

    test('reduced motion pins each step to one key pose', () {
      final TimelineStep extend = timeline.steps[1];
      expect(extend.step.frameTransition, isNotNull);

      // Normal playback walks the transition...
      expect(extend.frameAt(extend.startMs), 'FRAME_START');
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
      final List<ScheduledCue> holds = timeline.cues
          .where((ScheduledCue cue) => cue.eventId == 'VOICE_HOLD')
          .toList();
      expect(holds.length, 20, reason: 'one hold cue per repetition');
      expect(holds.first.atMs, 500 + 1800);
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
      final ScheduledCue cue = timeline.cues.firstWhere(
        (ScheduledCue cue) => cue.eventId == 'VOICE_HALFWAY',
      );
      expect(cue.atMs, timeline.totalDurationMs ~/ 2);
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

  group('cycle exercise (NECK_001)', () {
    test('repeat_cycles becomes one sideless block', () {
      final Exercise exercise = loadExerciseFromDisk('NECK_001');
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
