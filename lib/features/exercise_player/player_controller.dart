/// Drives one exercise session: owns the ticker, applies the machine's effects
/// to audio and tracking, and resolves the next exercise for autoplay.
///
/// All sequencing decisions live in [SessionMachine]; this class only wires it
/// to the outside world (docs/APP_STATE_MACHINE.md).
library;

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/audio/audio_service.dart';
import '../../core/storage/local_store.dart';
import '../../data/exercise_repository.dart';
import '../../data/tracking_repository.dart';
import '../../domain/exercise/exercise.dart';
import '../../domain/exercise/exercise_timeline.dart';
import '../../domain/exercise/session_machine.dart';

typedef PlayerArgs = ({String exerciseId, String? collectionId});

class PlayerState {
  const PlayerState({
    required this.loading,
    required this.exercise,
    required this.timeline,
    required this.snapshot,
    required this.nextSummary,
    required this.completedRepetitions,
    required this.completedRepetitionsInBlock,
    required this.progress,
    required this.currentStep,
    required this.error,
  });

  static const PlayerState initial = PlayerState(
    loading: true,
    exercise: null,
    timeline: null,
    snapshot: SessionSnapshot(
      state: SessionState.selected,
      elapsedMs: 0,
      prepRemainingMs: 0,
      restRemainingMs: 0,
      pauseCount: 0,
      autoModeEnabled: false,
    ),
    nextSummary: null,
    completedRepetitions: 0,
    completedRepetitionsInBlock: 0,
    progress: 0,
    currentStep: null,
    error: null,
  );

  final bool loading;
  final Exercise? exercise;
  final ExerciseTimeline? timeline;
  final SessionSnapshot snapshot;
  final ExerciseSummary? nextSummary;
  final int completedRepetitions;
  final int completedRepetitionsInBlock;
  final double progress;
  final TimelineStep? currentStep;
  final Object? error;

  SessionState get state => snapshot.state;

  PlayerState copyWith({
    bool? loading,
    Exercise? exercise,
    ExerciseTimeline? timeline,
    SessionSnapshot? snapshot,
    ExerciseSummary? nextSummary,
    bool clearNext = false,
    int? completedRepetitions,
    int? completedRepetitionsInBlock,
    double? progress,
    TimelineStep? currentStep,
    Object? error,
  }) {
    return PlayerState(
      loading: loading ?? this.loading,
      exercise: exercise ?? this.exercise,
      timeline: timeline ?? this.timeline,
      snapshot: snapshot ?? this.snapshot,
      nextSummary: clearNext ? null : (nextSummary ?? this.nextSummary),
      completedRepetitions: completedRepetitions ?? this.completedRepetitions,
      completedRepetitionsInBlock:
          completedRepetitionsInBlock ?? this.completedRepetitionsInBlock,
      progress: progress ?? this.progress,
      currentStep: currentStep ?? this.currentStep,
      error: error,
    );
  }
}

class PlayerController extends StateNotifier<PlayerState> {
  PlayerController(this._ref, this._args) : super(PlayerState.initial) {
    _init();
  }

  /// 20 fps is enough for frame swaps and countdowns, and keeps cue resolution
  /// well under the shortest step in the library (500 ms).
  static const Duration _tickInterval = Duration(milliseconds: 50);

  final Ref _ref;
  final PlayerArgs _args;

  ExerciseRepository? _repository;
  late final TrackingRepository _tracking;
  SessionMachine? _machine;
  SessionAudioController? _audio;
  Timer? _timer;
  String? _currentExerciseId;
  String? _collectionId;

  Future<void> _init() async {
    _collectionId = _args.collectionId;
    _tracking = _ref.read(trackingRepositoryProvider);
    try {
      final ExerciseRepository repository = await _ref.read(
        exerciseRepositoryProvider.future,
      );
      _repository = repository;
      await _loadExercise(_args.exerciseId);
    } on Object catch (error) {
      if (mounted) state = state.copyWith(loading: false, error: error);
    }
  }

  Future<void> _loadExercise(
    String exerciseId, {
    bool autoStart = false,
  }) async {
    final ExerciseRepository? repository = _repository;
    if (repository == null) return;

    final Exercise exercise = await repository.load(exerciseId);
    if (!mounted) return;

    final AppSettings settings = _ref.read(settingsProvider);
    // featureFlagsProvider already folds the developer multiplier in, and
    // production pins it to 1.0.
    final double multiplier = _ref.read(featureFlagsProvider).timingMultiplier;
    final ExerciseTimeline timeline = ExerciseTimeline.build(
      exercise,
      timingMultiplier: multiplier,
    );

    final SessionMachine machine = SessionMachine(
      exercise: exercise,
      timeline: timeline,
      collectionId: _collectionId,
      skipCountdowns: settings.devSkipCountdowns,
    );

    _machine = machine;
    _currentExerciseId = exerciseId;
    _audio = SessionAudioController(
      service: _ref.read(audioServiceProvider),
      mix: exercise.audioMix,
      voiceEnabled: settings.voiceEnabled,
      musicEnabled: settings.musicEnabled,
    );

    final ExerciseSummary? next = _resolveNext(exerciseId);
    state = state.copyWith(
      loading: false,
      exercise: exercise,
      timeline: timeline,
      snapshot: machine.snapshot,
      currentStep: timeline.isEmpty ? null : timeline.first,
      completedRepetitions: 0,
      completedRepetitionsInBlock: 0,
      progress: 0,
      nextSummary: next,
      clearNext: next == null,
    );

    if (autoStart) {
      _apply(machine.beginAutoStarted());
      _startTicker();
    }
  }

  ExerciseSummary? _resolveNext(String exerciseId) {
    final String? collectionId = _collectionId;
    final ExerciseRepository? repository = _repository;
    if (collectionId == null || repository == null) return null;
    return repository.neighbour(collectionId, exerciseId, 1);
  }

  // ------------------------------------------------------------ user intents

  void start() => _dispatch(SessionEventType.start, startTicker: true);

  void pauseOrResume() {
    final SessionMachine? machine = _machine;
    if (machine == null) return;
    if (machine.state == SessionState.paused) {
      _dispatch(SessionEventType.resume, startTicker: true);
    } else {
      _dispatch(SessionEventType.pause);
      _stopTicker();
    }
  }

  void stop() {
    _dispatch(SessionEventType.stop);
    _stopTicker();
  }

  void previous() => _dispatch(SessionEventType.previous);

  void next() => _dispatch(SessionEventType.next);

  void exit() {
    _dispatch(SessionEventType.exit);
    _stopTicker();
  }

  /// Called from the screen's `dispose`: ends the session and persists whatever
  /// the attempt earned, without publishing state into a tree that is being
  /// torn down.
  void finalizeSession() {
    _stopTicker();
    final SessionMachine? machine = _machine;
    if (machine == null) return;
    _apply(machine.handle(SessionEventType.exit), publish: false);
  }

  void _dispatch(SessionEventType event, {bool startTicker = false}) {
    final SessionMachine? machine = _machine;
    if (machine == null) return;
    _apply(machine.handle(event));
    if (startTicker) _startTicker();
  }

  // ---------------------------------------------------------------- ticking

  void _startTicker() {
    if (_timer != null) return;
    _timer = Timer.periodic(_tickInterval, (_) => _onTick());
  }

  void _stopTicker() {
    _timer?.cancel();
    _timer = null;
  }

  /// Advances by the nominal interval. Timer.periodic keeps the average rate
  /// even when a callback is late, and a fixed delta keeps the session
  /// reproducible in tests.
  void _onTick() {
    final SessionMachine? machine = _machine;
    if (machine == null) return;
    _apply(machine.tick(_tickInterval));
  }

  // ---------------------------------------------------------------- effects

  void _apply(List<SessionEffect> effects, {bool publish = true}) {
    final SessionMachine? machine = _machine;
    if (machine == null) return;

    for (final SessionEffect effect in effects) {
      switch (effect) {
        case PlayVoiceCue(:final String eventId):
          final AudioEvent? event = machine.exercise.audioEventById(eventId);
          if (event != null) {
            unawaited(_audio?.play(event) ?? Future<void>.value());
          }

        case PlayCountdownTick(:final int secondsLeft):
          unawaited(_audio?.countdown(secondsLeft) ?? Future<void>.value());

        case StartMusic():
          unawaited(
            _audio?.startMusic('gentle_rhythm_01') ?? Future<void>.value(),
          );

        case PauseAudio():
          unawaited(_audio?.pause() ?? Future<void>.value());

        case ResumeAudio():
          unawaited(_audio?.resume() ?? Future<void>.value());

        case StopAudio():
          unawaited(_audio?.stop() ?? Future<void>.value());

        case SaveResult(:final SessionResult result):
          unawaited(_saveResult(result));

        case IncrementLifetimeCounter():
          unawaited(_incrementLifetime());

        case AutoStartNext():
          _stopTicker();
          unawaited(_advanceToNext());

        case RequestManualBrowse(:final int direction):
          _stopTicker();
          unawaited(_browse(direction));
      }
    }

    if (publish) _publish();
  }

  void _publish() {
    final SessionMachine? machine = _machine;
    if (machine == null || !mounted) return;
    state = state.copyWith(
      snapshot: machine.snapshot,
      currentStep: machine.currentStep,
      completedRepetitions: machine.completedRepetitions,
      completedRepetitionsInBlock: machine.completedRepetitionsInCurrentBlock,
      progress: machine.progress,
    );
  }

  Future<void> _saveResult(SessionResult result) async {
    await _tracking.save(result);
    _bumpActivityRevision();
  }

  Future<void> _incrementLifetime() async {
    await _tracking.incrementLifetime();
    _bumpActivityRevision();
  }

  /// Skipped once the provider is gone — the activity screen re-reads the
  /// store when it is next built anyway.
  void _bumpActivityRevision() {
    if (!mounted) return;
    try {
      _ref.read(activityRevisionProvider.notifier).state++;
    } on Object {
      // The container was disposed while the write was in flight.
    }
  }

  /// Rest hit zero: the next exercise starts on its own, no Start needed.
  Future<void> _advanceToNext() async {
    final ExerciseSummary? next = state.nextSummary;
    if (next == null) {
      _publish();
      return;
    }
    await _loadExercise(next.id, autoStart: true);
  }

  /// Manual Previous/Next: show the neighbour in `selected`, waiting for Start.
  Future<void> _browse(int direction) async {
    final String? current = _currentExerciseId;
    final String? collectionId = _collectionId;
    final ExerciseRepository? repository = _repository;
    if (current == null || collectionId == null || repository == null) return;

    final ExerciseSummary? target = repository.neighbour(
      collectionId,
      current,
      direction,
    );
    if (target == null) {
      _publish();
      return;
    }
    await _loadExercise(target.id);
  }

  @override
  void dispose() {
    _stopTicker();
    unawaited(_audio?.stop() ?? Future<void>.value());
    super.dispose();
  }
}

/// autoDispose: leaving the player ends the session rather than leaving a
/// paused machine and a running ticker behind.
final playerControllerProvider = StateNotifierProvider.autoDispose
    .family<PlayerController, PlayerState, PlayerArgs>(
      (Ref ref, PlayerArgs args) => PlayerController(ref, args),
    );
