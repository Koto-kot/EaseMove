/// Flattens an exercise sequence into one absolute timeline.
///
/// docs/EXERCISE_ENGINE.md — "Sequence Engine є single source of truth".
/// Animation, voice cues and progress are all derived from this structure, so
/// they cannot drift apart the way independent timers would.
library;

import 'exercise.dart';

/// One sequence step placed at an absolute offset inside the whole exercise.
class TimelineStep {
  const TimelineStep({
    required this.index,
    required this.blockIndex,
    required this.side,
    required this.repetition,
    required this.repetitionsInBlock,
    required this.isLastStepOfRepetition,
    required this.step,
    required this.startMs,
  });

  final int index;
  final int blockIndex;

  /// `null` for exercises without a side model (NECK_001, KNEE_002).
  final BodySide? side;

  /// 1-based repetition number inside its block.
  final int repetition;
  final int repetitionsInBlock;
  final bool isLastStepOfRepetition;
  final SequenceStep step;
  final int startMs;

  int get durationMs => step.durationMs;
  int get endMs => startMs + durationMs;
  String? get phase => step.phase;

  /// Side of this step: an explicit per-step side (NECK_001) wins over the
  /// side of the enclosing block (KNEE_001).
  BodySide? get effectiveSide => step.side ?? side;

  /// Progress inside this step at [elapsedMs], clamped to 0..1.
  double localProgress(int elapsedMs) {
    if (durationMs <= 0) return 1;
    final double value = (elapsedMs - startMs) / durationMs;
    return value.clamp(0.0, 1.0);
  }

  /// The step's single key pose — the frame a reduced-motion viewer sees for
  /// the whole step, instead of the transition's frames swapping under them
  /// (docs/VISUAL_STYLE_GUIDE.md 11, TECHNICAL_SPEC.md 18).
  String? get keyFrameId =>
      step.frameId ?? step.frameTransition?.to ?? step.frameTransition?.from;

  /// Frame to show at [elapsedMs]. A transition walks its frames evenly.
  String? frameAt(int elapsedMs) {
    if (step.frameId != null) return step.frameId;
    final List<String> frames =
        step.frameTransition?.frameIds ?? const <String>[];
    if (frames.isEmpty) return null;
    final int slot = (localProgress(elapsedMs) * frames.length).floor();
    return frames[slot.clamp(0, frames.length - 1)];
  }
}

/// A voice cue resolved to an absolute offset before playback starts.
class ScheduledCue {
  const ScheduledCue({
    required this.atMs,
    required this.eventId,
    required this.priority,
    required this.interruptible,
  });

  final int atMs;
  final String eventId;
  final int priority;
  final bool interruptible;
}

class ExerciseTimeline {
  ExerciseTimeline({
    required this.steps,
    required this.cues,
    required this.totalRepetitions,
    required this.totalDurationMs,
  });

  /// Builds the timeline for [exercise], optionally scaled by
  /// [timingMultiplier] (developer menu, docs/FEATURE_FLAGS.md).
  factory ExerciseTimeline.build(
    Exercise exercise, {
    double timingMultiplier = 1.0,
  }) {
    final List<TimelineStep> steps = <TimelineStep>[];
    int cursor = 0;
    int index = 0;
    int totalRepetitions = 0;

    for (
      int blockIndex = 0;
      blockIndex < exercise.sequence.blocks.length;
      blockIndex++
    ) {
      final SequenceBlock block = exercise.sequence.blocks[blockIndex];
      totalRepetitions += block.repeat;
      for (int repetition = 1; repetition <= block.repeat; repetition++) {
        for (int s = 0; s < block.steps.length; s++) {
          final SequenceStep raw = block.steps[s];
          final SequenceStep scaled = timingMultiplier == 1.0
              ? raw
              : SequenceStep(
                  id: raw.id,
                  phase: raw.phase,
                  side: raw.side,
                  frameId: raw.frameId,
                  frameTransition: raw.frameTransition,
                  durationMs: (raw.durationMs * timingMultiplier).round().clamp(
                    1,
                    1 << 30,
                  ),
                  voiceEvent: raw.voiceEvent,
                );
          steps.add(
            TimelineStep(
              index: index,
              blockIndex: blockIndex,
              side: block.side,
              repetition: repetition,
              repetitionsInBlock: block.repeat,
              isLastStepOfRepetition: s == block.steps.length - 1,
              step: scaled,
              startMs: cursor,
            ),
          );
          cursor += scaled.durationMs;
          index++;
        }
      }
    }

    return ExerciseTimeline(
      steps: steps,
      cues: _resolveCues(exercise, steps, cursor),
      totalRepetitions: totalRepetitions,
      totalDurationMs: cursor,
    );
  }

  final List<TimelineStep> steps;

  /// Sorted by offset, then by descending priority.
  final List<ScheduledCue> cues;
  final int totalRepetitions;
  final int totalDurationMs;

  bool get isEmpty => steps.isEmpty;

  TimelineStep get first => steps.first;

  /// Step active at [elapsedMs]. Past the end, the last step is returned so the
  /// UI keeps showing the closing pose.
  TimelineStep stepAt(int elapsedMs) {
    if (elapsedMs <= 0) return steps.first;
    for (final TimelineStep step in steps) {
      if (elapsedMs < step.endMs) return step;
    }
    return steps.last;
  }

  /// Repetitions fully finished at [elapsedMs].
  int completedRepetitionsAt(int elapsedMs) {
    int completed = 0;
    for (final TimelineStep step in steps) {
      if (step.isLastStepOfRepetition && elapsedMs >= step.endMs) completed++;
    }
    return completed;
  }

  /// Repetitions finished inside the block that is active at [elapsedMs].
  int completedRepetitionsInCurrentBlockAt(int elapsedMs) {
    final int blockIndex = stepAt(elapsedMs).blockIndex;
    int completed = 0;
    for (final TimelineStep step in steps) {
      if (step.blockIndex == blockIndex &&
          step.isLastStepOfRepetition &&
          elapsedMs >= step.endMs) {
        completed++;
      }
    }
    return completed;
  }

  /// Progress 0..1 under the exercise's declared basis.
  double progressAt(int elapsedMs, ProgressBasis basis) {
    if (basis == ProgressBasis.completedRepetitions && totalRepetitions > 0) {
      return (completedRepetitionsAt(elapsedMs) / totalRepetitions).clamp(
        0.0,
        1.0,
      );
    }
    if (totalDurationMs <= 0) return 0;
    return (elapsedMs / totalDurationMs).clamp(0.0, 1.0);
  }

  /// Cues whose offset falls in `(fromMs, toMs]` — the window a tick advanced
  /// over. Highest priority first, so a collision resolves deterministically.
  List<ScheduledCue> cuesBetween(int fromMs, int toMs) {
    final List<ScheduledCue> due = <ScheduledCue>[
      for (final ScheduledCue cue in cues)
        if (cue.atMs > fromMs && cue.atMs <= toMs) cue,
    ];
    due.sort(
      (ScheduledCue a, ScheduledCue b) => b.priority.compareTo(a.priority),
    );
    return due;
  }

  static List<ScheduledCue> _resolveCues(
    Exercise exercise,
    List<TimelineStep> steps,
    int totalMs,
  ) {
    final List<ScheduledCue> cues = <ScheduledCue>[];

    void add(AudioEvent event, int atMs) {
      if (atMs < 0 || atMs > totalMs) return;
      cues.add(
        ScheduledCue(
          atMs: atMs,
          eventId: event.id,
          priority: event.priority,
          interruptible: event.interruptible,
        ),
      );
    }

    for (final AudioEvent event in exercise.audioEvents) {
      final AudioTrigger trigger = event.trigger;
      switch (trigger.event) {
        case 'sequence_phase_started':
          final Set<String> seenPhaseSides = <String>{};
          for (final TimelineStep step in steps) {
            if (step.phase != trigger.phase) continue;
            if (event.playOncePerSide) {
              final String key = step.effectiveSide?.id ?? 'none';
              if (!seenPhaseSides.add(key)) continue;
            }
            add(event, step.startMs);
          }

        case 'repetition_started':
          final Set<String> seenRepetitionSides = <String>{};
          for (final TimelineStep step in steps) {
            if (step.index > 0 &&
                !steps[step.index - 1].isLastStepOfRepetition) {
              continue;
            }
            final bool matchesNumber =
                trigger.repetitionNumber == null ||
                step.repetition == trigger.repetitionNumber;
            final bool matchesLast =
                trigger.relativePosition != 'last' ||
                step.repetition == step.repetitionsInBlock;
            if (!matchesNumber || !matchesLast) continue;
            if (event.playOncePerSide) {
              final String key =
                  step.effectiveSide?.id ?? 'block${step.blockIndex}';
              if (!seenRepetitionSides.add(key)) continue;
            }
            add(event, step.startMs);
          }

        case 'side_block_completed':
          for (final TimelineStep step in steps) {
            final bool isBlockEnd =
                step.index == steps.length - 1 ||
                steps[step.index + 1].blockIndex != step.blockIndex;
            if (!isBlockEnd) continue;
            if (trigger.side != null && step.side != trigger.side) continue;
            add(event, step.endMs);
          }

        case 'progress_crossed':
          final int percent = trigger.percent ?? 0;
          add(event, (totalMs * percent / 100).round());

        // prep_countdown_started and exercise_completed are fired by the
        // session machine itself: they sit outside the active timeline.
        default:
          break;
      }
    }

    cues.sort((ScheduledCue a, ScheduledCue b) {
      final int byTime = a.atMs.compareTo(b.atMs);
      return byTime != 0 ? byTime : b.priority.compareTo(a.priority);
    });
    return cues;
  }
}
