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
    required this.restRemainingMs,
    required this.pauseCount,
    required this.autoModeEnabled,
  });

  final SessionState state;
  final int elapsedMs;
  final int prepRemainingMs;
  final int restRemainingMs;
  final int pauseCount;
  final bool autoModeEnabled;

  bool get isRunning =>
      state == SessionState.prepCountdown || state == SessionState.active;
  bool get isCountingDown => state == SessionState.prepCountdown;
  bool get isResting => state == SessionState.autoRest;

  /// Whole seconds remaining, the way a countdown reads: 5, 4, 3, 2, 1.
  int get prepSecondsLeft => (prepRemainingMs / 1000).ceil();
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
  final int _restDurationMs;

  SessionState _state = SessionState.selected;
  int _elapsedMs = 0;
  int _prepRemainingMs = 0;
  int _restRemainingMs = 0;
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

  List<SessionEffect> _enterPrep() {
    _state = SessionState.prepCountdown;
    _prepRemainingMs = _prepDurationMs;
    _lastCountdownSecondAnnounced = -1;
    _startedAt = _clock();

    final List<SessionEffect> effects = <SessionEffect>[];
    final AudioEvent? prepare = _eventByTrigger('prep_countdown_started');
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
      effects.addAll(_enterActive());
      return effects;
    }
    // Announce the first number immediately: 5 → 4 → 3 → 2 → 1
    // (docs/UX_FLOW.md B).
    _lastCountdownSecondAnnounced = (_prepRemainingMs / 1000).ceil();
    effects.add(PlayCountdownTick(_lastCountdownSecondAnnounced));
    return effects;
  }

  List<SessionEffect> _tickPrep(int deltaMs) {
    final List<SessionEffect> effects = <SessionEffect>[];
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

  List<SessionEffect> _tickRest(int deltaMs) {
    if (_autoNextRequested) return const <SessionEffect>[];
    _restRemainingMs -= deltaMs;
    if (_restRemainingMs > 0) return const <SessionEffect>[];
    _restRemainingMs = 0;
    // Invariant 4: rest runs to zero, then the next exercise auto-starts.
    // Requested exactly once, even if ticks keep arriving.
    _autoNextRequested = true;
    return const <SessionEffect>[AutoStartNext()];
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
