/// Deterministic exercise session state machine.
///
/// docs/APP_STATE_MACHINE.md. Deliberately free of timers, audio players and
/// widgets: the outside world only pushes events and elapsed time in, and gets
/// a new immutable state plus a list of effects out. That keeps every invariant
/// in the doc unit-testable.
library;

import 'exercise.dart';
import 'exercise_timeline.dart';

enum SessionState {
  browsing,
  selected,
  prepCountdown,
  active,
  paused,
  stopped,
  completed,
  autoRest,
  manualBrowseNext,
  exited,
}

enum SessionEventType {
  selectExercise,
  start,
  pause,
  resume,
  stop,
  previous,
  next,
  exit,
}

/// Something the outside world has to do. The machine never does it itself.
sealed class SessionEffect {
  const SessionEffect();
}

class PlayVoiceCue extends SessionEffect {
  const PlayVoiceCue(
    this.eventId, {
    required this.interruptible,
    required this.priority,
  });
  final String eventId;
  final bool interruptible;
  final int priority;
}

class PlayCountdownTick extends SessionEffect {
  const PlayCountdownTick(this.secondsLeft);
  final int secondsLeft;
}

/// A line the session says on its own rather than one an exercise declares:
/// the countdown's opening and the break announcement
/// (data/audio/common_lines.yaml).
class PlayCommonLine extends SessionEffect {
  const PlayCommonLine(this.name);

  /// Asset stem under `audio/<lang>/common/`.
  final String name;
}

class StartMusic extends SessionEffect {
  const StartMusic();
}

class PauseAudio extends SessionEffect {
  const PauseAudio();
}

class ResumeAudio extends SessionEffect {
  const ResumeAudio();
}

class StopAudio extends SessionEffect {
  const StopAudio();
}

/// Emitted once per finished attempt — normal completion or early stop.
class SaveResult extends SessionEffect {
  const SaveResult(this.result);
  final SessionResult result;
}

class IncrementLifetimeCounter extends SessionEffect {
  const IncrementLifetimeCounter();
}

/// Auto-rest reached zero: load and start the next exercise (no user action).
class AutoStartNext extends SessionEffect {
  const AutoStartNext();
}

/// Autoplay was cancelled by a manual Previous/Next during rest.
class RequestManualBrowse extends SessionEffect {
  const RequestManualBrowse(this.direction);
  final int direction; // -1 previous, +1 next
}

class SessionResult {
  const SessionResult({
    required this.exerciseId,
    required this.startedAt,
    required this.actualActiveSeconds,
    required this.completed,
    required this.earlyStop,
    required this.completedRepetitions,
    required this.side,
    required this.collectionId,
    required this.pauseCount,
  });

  final String exerciseId;
  final DateTime startedAt;
  final int actualActiveSeconds;
  final bool completed;
  final bool earlyStop;
  final int completedRepetitions;
  final String? side;
  final String? collectionId;
  final int pauseCount;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'exerciseId': exerciseId,
    'startedAt': startedAt.toIso8601String(),
    'actualActiveSeconds': actualActiveSeconds,
    'completed': completed,
    'earlyStop': earlyStop,
    'completedRepetitions': completedRepetitions,
    'side': side,
    'collectionId': collectionId,
    'pauseCount': pauseCount,
  };

  static SessionResult fromJson(Map<String, dynamic> json) => SessionResult(
    exerciseId: json['exerciseId'] as String,
    startedAt: DateTime.parse(json['startedAt'] as String),
    actualActiveSeconds: (json['actualActiveSeconds'] as num?)?.toInt() ?? 0,
    completed: json['completed'] as bool? ?? false,
    earlyStop: json['earlyStop'] as bool? ?? false,
    completedRepetitions: (json['completedRepetitions'] as num?)?.toInt() ?? 0,
    side: json['side'] as String?,
    collectionId: json['collectionId'] as String?,
    pauseCount: (json['pauseCount'] as num?)?.toInt() ?? 0,
  );
}

/// Immutable snapshot the UI renders.
class SessionSnapshot {
  const SessionSnapshot({
    required this.state,
    required this.elapsedMs,
    required this.prepRemainingMs,
    required this.prepIntroRemainingMs,
    required this.prepOpeningRemainingMs,
    required this.prepSecondsTotal,
    required this.restRemainingMs,
    required this.pauseCount,
    required this.autoModeEnabled,
  });

  final SessionState state;
  final int elapsedMs;
  final int prepRemainingMs;

  /// Time left in the spoken setup line. The screen holds the start pose while
  /// it runs.
  final int prepIntroRemainingMs;

  /// Time left in "Починаємо вправу через п'ять". The ticking starts after it,
  /// at four, because the line has already said the five.
  final int prepOpeningRemainingMs;

  /// The number the countdown starts from, which is what the screen shows for
  /// as long as the two spoken lines run.
  final int prepSecondsTotal;

  final int restRemainingMs;
  final int pauseCount;
  final bool autoModeEnabled;

  bool get isRunning =>
      state == SessionState.prepCountdown || state == SessionState.active;

  /// PREP_COUNTDOWN covers the two spoken lines and then the numbers. The
  /// number is on screen throughout — five is lit while the lines run, which
  /// is what makes the countdown feel started rather than pending.
  bool get isPreparing =>
      state == SessionState.prepCountdown &&
      (prepIntroRemainingMs > 0 || prepOpeningRemainingMs > 0);
  bool get isCountingDown => state == SessionState.prepCountdown;
  bool get isResting => state == SessionState.autoRest;

  /// Whole seconds remaining, the way a countdown reads: 5, 4, 3, 2, 1, 0.
  int get prepSecondsLeft =>
      isPreparing ? prepSecondsTotal : (prepRemainingMs / 1000).ceil();
  int get restSecondsLeft => (restRemainingMs / 1000).ceil();
}

/// Drives one exercise attempt. Create a new instance per exercise.
class SessionMachine {
  SessionMachine({
    required this.exercise,
    required this.timeline,
    this.collectionId,
    this.skipCountdowns = false,
    this.hasNextExercise = false,
    this.countEarlyStopInLifetime = false,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now,
       _prepDurationMs = skipCountdowns
           ? 0
           : exercise.timing.prepCountdownSeconds * 1000,
       _prepIntroDurationMs = skipCountdowns ? 0 : exercise.timing.prepIntroMs,
       _prepOpeningDurationMs = skipCountdowns
           ? 0
           : exercise.timing.countdownOpeningMs,
       _restIntroDurationMs = skipCountdowns
           ? 0
           : exercise.timing.completionMs + exercise.timing.restIntroMs,
       _completionDurationMs = skipCountdowns
           ? 0
           : exercise.timing.completionMs,
       _restDurationMs = exercise.flow.restSeconds * 1000;

  final Exercise exercise;
  final ExerciseTimeline timeline;
  final String? collectionId;
  final bool skipCountdowns;

  /// Whether the collection has anything queued behind this exercise. Rest
  /// exists to bridge two exercises, so the last one in a collection ends in
  /// COMPLETED instead of resting towards an auto-start that never comes.
  final bool hasNextExercise;

  /// Global policy, not per-exercise (docs/UX_FLOW.md E).
  final bool countEarlyStopInLifetime;

  final DateTime Function() _clock;
  final int _prepDurationMs;
  final int _prepIntroDurationMs;
  final int _prepOpeningDurationMs;

  /// "Готово." and then the break announcement, before the break's own
  /// numbers start.
  final int _restIntroDurationMs;
  final int _completionDurationMs;
  final int _restDurationMs;

  SessionState _state = SessionState.selected;
  int _elapsedMs = 0;
  int _prepRemainingMs = 0;
  int _prepIntroRemainingMs = 0;
  int _prepOpeningRemainingMs = 0;
  int _restRemainingMs = 0;
  int _restIntroRemainingMs = 0;
  bool _restIntroAnnounced = true;
  int _lastRestSecondAnnounced = -1;
  int _pauseCount = 0;
  bool _autoModeEnabled = false;
  bool _resultSaved = false;
  bool _autoNextRequested = false;
  DateTime? _startedAt;
  int _lastCountdownSecondAnnounced = -1;

  SessionSnapshot get snapshot => SessionSnapshot(
    state: _state,
    elapsedMs: _elapsedMs,
    prepRemainingMs: _prepRemainingMs,
    prepIntroRemainingMs: _prepIntroRemainingMs,
    prepOpeningRemainingMs: _prepOpeningRemainingMs,
    prepSecondsTotal: exercise.timing.prepCountdownSeconds,
    restRemainingMs: _restRemainingMs,
    pauseCount: _pauseCount,
    autoModeEnabled: _autoModeEnabled,
  );

  SessionState get state => _state;
  int get elapsedMs => _elapsedMs;

  TimelineStep get currentStep => timeline.stepAt(_elapsedMs);

  int get completedRepetitions => timeline.completedRepetitionsAt(_elapsedMs);

  int get completedRepetitionsInCurrentBlock =>
      timeline.completedRepetitionsInCurrentBlockAt(_elapsedMs);

  double get progress =>
      timeline.progressAt(_elapsedMs, exercise.progress.basis);

  BodySide? get currentSide => currentStep.effectiveSide;

  /// Starts this attempt in autoplay: no manual Start, no prep countdown skip.
  /// Used when the previous exercise's rest reached zero (docs/UX_FLOW.md F).
  List<SessionEffect> beginAutoStarted() {
    _autoModeEnabled = true;
    return _enterPrep();
  }

  List<SessionEffect> handle(SessionEventType event) {
    switch (event) {
      case SessionEventType.selectExercise:
        _state = SessionState.selected;
        return const <SessionEffect>[];

      case SessionEventType.start:
        // Invariant 3: a manually selected exercise never starts without Start.
        if (_state != SessionState.selected &&
            _state != SessionState.stopped &&
            _state != SessionState.manualBrowseNext) {
          return const <SessionEffect>[];
        }
        _elapsedMs = 0;
        _resultSaved = false;
        return _enterPrep();

      case SessionEventType.pause:
        if (_state != SessionState.active &&
            _state != SessionState.prepCountdown) {
          return const <SessionEffect>[];
        }
        _state = SessionState.paused;
        _pauseCount++;
        return const <SessionEffect>[PauseAudio()];

      case SessionEventType.resume:
        if (_state != SessionState.paused) return const <SessionEffect>[];
        _state = _prepRemainingMs > 0
            ? SessionState.prepCountdown
            : SessionState.active;
        return const <SessionEffect>[ResumeAudio()];

      // Invariant 1: STOP is accepted in any active session state.
      case SessionEventType.stop:
        if (_state == SessionState.browsing || _state == SessionState.exited) {
          return const <SessionEffect>[];
        }
        return _finish(completed: false);

      case SessionEventType.previous:
        return _manualBrowse(-1);

      case SessionEventType.next:
        return _manualBrowse(1);

      case SessionEventType.exit:
        final List<SessionEffect> effects = <SessionEffect>[];
        if (_state == SessionState.active ||
            _state == SessionState.paused ||
            _state == SessionState.prepCountdown) {
          effects.addAll(_finish(completed: false));
        }
        _autoModeEnabled = false;
        _state = SessionState.exited;
        effects.add(const StopAudio());
        return effects;
    }
  }

  /// Advances time. The only clock in the engine: animation, cues and progress
  /// all read from [_elapsedMs] (docs/EXERCISE_ENGINE.md, "Timeline rule").
  List<SessionEffect> tick(Duration delta) {
    final int deltaMs = delta.inMilliseconds;
    if (deltaMs <= 0) return const <SessionEffect>[];

    switch (_state) {
      case SessionState.prepCountdown:
        return _tickPrep(deltaMs);
      case SessionState.active:
        return _tickActive(deltaMs);
      case SessionState.autoRest:
        return _tickRest(deltaMs);
      case SessionState.browsing:
      case SessionState.selected:
      case SessionState.paused:
      case SessionState.stopped:
      case SessionState.completed:
      case SessionState.manualBrowseNext:
      case SessionState.exited:
        return const <SessionEffect>[];
    }
  }

  /// Start: the exercise's setup line, then "Починаємо вправу через п'ять",
  /// then 4, 3, 2, 1, 0.
  ///
  /// All of it goes to one voice, so each part waits for the one before it —
  /// started together, none of them is heard (docs/UX_FLOW.md B). The five is
  /// on screen from the first moment and stays lit until the opening line has
  /// said it, which is why the ticking picks up at four.
  List<SessionEffect> _enterPrep() {
    _state = SessionState.prepCountdown;
    _prepRemainingMs = _prepDurationMs;
    _lastCountdownSecondAnnounced = -1;
    _startedAt = _clock();

    final List<SessionEffect> effects = <SessionEffect>[];
    final AudioEvent? prepare = _eventByTrigger('prep_countdown_started');
    _prepIntroRemainingMs = prepare == null ? 0 : _prepIntroDurationMs;
    _prepOpeningRemainingMs = _prepOpeningDurationMs;
    if (prepare != null) {
      effects.add(
        PlayVoiceCue(
          prepare.id,
          interruptible: prepare.interruptible,
          priority: prepare.priority,
        ),
      );
    }
    if (_prepRemainingMs <= 0) {
      _prepIntroRemainingMs = 0;
      _prepOpeningRemainingMs = 0;
      effects.addAll(_enterActive());
      return effects;
    }
    if (_prepIntroRemainingMs > 0) return effects;
    effects.addAll(_openCountdown());
    return effects;
  }

  /// The setup line is over: say the opening, and hold the numbers until it
  /// finishes. With nothing to say, the numbers start at once.
  List<SessionEffect> _openCountdown() {
    if (_prepOpeningRemainingMs > 0) {
      return <SessionEffect>[const PlayCommonLine('countdown_opening')];
    }
    return _beginCountdownNumbers();
  }

  /// The opening has said the first number, so the clock starts one second in.
  List<SessionEffect> _beginCountdownNumbers() {
    _prepRemainingMs =
        _prepDurationMs - (_prepOpeningDurationMs > 0 ? 1000 : 0);
    if (_prepRemainingMs <= 0) {
      _prepRemainingMs = 0;
      return <SessionEffect>[const PlayCountdownTick(0), ..._enterActive()];
    }
    _lastCountdownSecondAnnounced = (_prepRemainingMs / 1000).ceil();
    return <SessionEffect>[PlayCountdownTick(_lastCountdownSecondAnnounced)];
  }

  List<SessionEffect> _tickPrep(int deltaMs) {
    final List<SessionEffect> effects = <SessionEffect>[];

    if (_prepIntroRemainingMs > 0) {
      _prepIntroRemainingMs -= deltaMs;
      if (_prepIntroRemainingMs > 0) return effects;
      // Whatever of this tick was left over belongs to what comes next.
      deltaMs = -_prepIntroRemainingMs;
      _prepIntroRemainingMs = 0;
      effects.addAll(_openCountdown());
      if (deltaMs <= 0 || _state != SessionState.prepCountdown) return effects;
    }

    if (_prepOpeningRemainingMs > 0) {
      _prepOpeningRemainingMs -= deltaMs;
      if (_prepOpeningRemainingMs > 0) return effects;
      deltaMs = -_prepOpeningRemainingMs;
      _prepOpeningRemainingMs = 0;
      effects.addAll(_beginCountdownNumbers());
      if (deltaMs <= 0 || _state != SessionState.prepCountdown) return effects;
    }

    _prepRemainingMs -= deltaMs;

    final int secondsLeft = _prepRemainingMs <= 0
        ? 0
        : (_prepRemainingMs / 1000).ceil();
    if (secondsLeft > 0 && secondsLeft != _lastCountdownSecondAnnounced) {
      _lastCountdownSecondAnnounced = secondsLeft;
      effects.add(PlayCountdownTick(secondsLeft));
    }

    if (_prepRemainingMs <= 0) {
      _prepRemainingMs = 0;
      // Zero is spoken as the movement starts; the exercise's own first
      // instruction follows it immediately, which is the right order.
      effects.add(const PlayCountdownTick(0));
      effects.addAll(_enterActive());
    }
    return effects;
  }

  List<SessionEffect> _enterActive() {
    _state = SessionState.active;
    final List<SessionEffect> effects = <SessionEffect>[const StartMusic()];
    // Cues sitting exactly at 0 belong to the first step.
    effects.addAll(_cueEffects(-1, 0));
    return effects;
  }

  List<SessionEffect> _tickActive(int deltaMs) {
    final int before = _elapsedMs;
    final int after = (before + deltaMs).clamp(0, timeline.totalDurationMs);
    _elapsedMs = after;

    final List<SessionEffect> effects = <SessionEffect>[
      ..._cueEffects(before, after),
    ];

    if (after >= timeline.totalDurationMs) {
      effects.addAll(_finish(completed: true));
    }
    return effects;
  }

  /// The break: "Готово.", then "Перерва між вправами — десять секунд", then
  /// the seconds spoken as the timer shows them.
  ///
  /// The numbers name whatever second is on screen rather than starting from
  /// ten, because the two announcements have already used some of the break
  /// and a number that disagrees with the timer is worse than no number.
  List<SessionEffect> _tickRest(int deltaMs) {
    if (_autoNextRequested) return const <SessionEffect>[];
    final List<SessionEffect> effects = <SessionEffect>[];

    _restRemainingMs -= deltaMs;

    if (_restIntroRemainingMs > 0) {
      final int before = _restIntroRemainingMs;
      _restIntroRemainingMs -= deltaMs;
      // The announcement waits for "Готово." to finish before it starts.
      if (!_restIntroAnnounced &&
          before > _restIntroRemainingMs &&
          _restIntroRemainingMs <=
              _restIntroDurationMs - _completionDurationMs) {
        _restIntroAnnounced = true;
        effects.add(const PlayCommonLine('rest_intro'));
      }
    }

    if (_restRemainingMs > 0) {
      if (_restIntroRemainingMs <= 0) {
        final int secondsLeft = (_restRemainingMs / 1000).ceil();
        if (secondsLeft != _lastRestSecondAnnounced) {
          _lastRestSecondAnnounced = secondsLeft;
          effects.add(PlayCountdownTick(secondsLeft));
        }
      }
      return effects;
    }

    _restRemainingMs = 0;
    // Invariant 4: rest runs to zero, then the next exercise auto-starts.
    // Requested exactly once, even if ticks keep arriving. No zero is spoken:
    // the next exercise's own setup line lands on the same instant.
    _autoNextRequested = true;
    effects.add(const AutoStartNext());
    return effects;
  }

  List<SessionEffect> _finish({required bool completed}) {
    final List<SessionEffect> effects = <SessionEffect>[];

    if (!_resultSaved) {
      _resultSaved = true;
      effects.add(SaveResult(_buildResult(completed: completed)));
      if (completed && exercise.flow.incrementCounterOnCompletion) {
        effects.add(const IncrementLifetimeCounter());
      } else if (!completed && countEarlyStopInLifetime) {
        effects.add(const IncrementLifetimeCounter());
      }
    }

    if (completed) {
      final AudioEvent? done = _eventByTrigger('exercise_completed');
      if (done != null) {
        effects.add(
          PlayVoiceCue(
            done.id,
            interruptible: done.interruptible,
            priority: done.priority,
          ),
        );
      }
      _state = SessionState.completed;
      if (exercise.flow.autoNextEnabled && hasNextExercise) {
        _autoModeEnabled = true;
        _state = SessionState.autoRest;
        _restRemainingMs = _restDurationMs;
        _restIntroRemainingMs = _restIntroDurationMs;
        _restIntroAnnounced = _restIntroDurationMs <= 0;
        _lastRestSecondAnnounced = -1;
        _autoNextRequested = false;
      }
    } else {
      _autoModeEnabled = false;
      _state = SessionState.stopped;
      effects.add(const StopAudio());
    }
    return effects;
  }

  /// Invariant 2: Previous/Next during rest cancels autoplay; the newly shown
  /// exercise then requires a manual Start with its own prep countdown.
  List<SessionEffect> _manualBrowse(int direction) {
    final List<SessionEffect> effects = <SessionEffect>[];
    if (_state == SessionState.active ||
        _state == SessionState.paused ||
        _state == SessionState.prepCountdown) {
      effects.addAll(_finish(completed: false));
    }
    _autoModeEnabled = false;
    _restRemainingMs = 0;
    _restIntroRemainingMs = 0;
    _state = SessionState.manualBrowseNext;
    effects.add(const StopAudio());
    effects.add(RequestManualBrowse(direction));
    return effects;
  }

  SessionResult _buildResult({required bool completed}) {
    final bool sideAware = exercise.progress.showSideLabel;
    return SessionResult(
      exerciseId: exercise.id,
      startedAt: _startedAt ?? _clock(),
      actualActiveSeconds: (_elapsedMs / 1000).round(),
      completed: completed,
      earlyStop: !completed,
      completedRepetitions: completedRepetitions,
      side: sideAware ? currentSide?.id : null,
      collectionId: collectionId,
      pauseCount: _pauseCount,
    );
  }

  List<SessionEffect> _cueEffects(int fromMs, int toMs) {
    return <SessionEffect>[
      for (final ScheduledCue cue in timeline.cuesBetween(fromMs, toMs))
        PlayVoiceCue(
          cue.eventId,
          interruptible: cue.interruptible,
          priority: cue.priority,
        ),
    ];
  }

  AudioEvent? _eventByTrigger(String triggerEvent) {
    for (final AudioEvent event in exercise.audioEvents) {
      if (event.trigger.event == triggerEvent) return event;
    }
    return null;
  }
}
