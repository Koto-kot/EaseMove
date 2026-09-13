/// Moves a player's volume from where it is to where it should be, in steps.
///
/// The audio backend has no fade of its own: a player is at a volume or it is
/// not. Music that appears and disappears at full level is startling under a
/// voice that is asking you to breathe out, so the background track arrives
/// and leaves on a ramp (docs/DECISIONS.md 83).
///
/// Kept apart from the player so the shape of a fade can be tested without a
/// platform channel.
library;

import 'dart:async';

import 'package:flutter/foundation.dart';

class VolumeFader {
  VolumeFader({
    required this.apply,
    this.step = const Duration(milliseconds: 50),
  });

  /// Sets the volume on whatever is playing. Asynchronous because every audio
  /// backend's is, and its result is not waited for: a step that is late is
  /// better dropped than queued behind the next one.
  final Future<void> Function(double volume) apply;

  /// How often the level is nudged. 50 ms is short enough that a ramp is heard
  /// as a slide rather than as a staircase.
  final Duration step;

  Timer? _timer;
  double _from = 0;
  double _to = 0;
  int _steps = 0;
  int _taken = 0;
  VoidCallback? _onDone;

  bool get isFading => _timer != null;

  /// Where the ramp is heading, and the level the player sits at when no ramp
  /// is running.
  double get target => _to;

  /// Moving the destination mid-ramp — the volume slider in Settings — bends
  /// the ramp towards the new level instead of restarting it.
  set target(double value) {
    _to = value;
    if (!isFading) unawaited(apply(value));
  }

  /// Ramps from [from] to [to] over [over], then calls [onDone].
  ///
  /// A zero-length ramp is not a special case for the caller: it simply lands
  /// at once.
  void ramp({
    required double from,
    required double to,
    required Duration over,
    VoidCallback? onDone,
  }) {
    cancel();
    _from = from;
    _to = to;
    _taken = 0;
    _steps = over.inMilliseconds <= 0
        ? 0
        : (over.inMilliseconds / step.inMilliseconds).ceil();

    if (_steps <= 0) {
      unawaited(apply(to));
      onDone?.call();
      return;
    }
    _onDone = onDone;
    unawaited(apply(from));
    _timer = Timer.periodic(step, (_) => _advance());
  }

  void _advance() {
    _taken++;
    if (_taken >= _steps) {
      final VoidCallback? done = _onDone;
      final double landing = _to;
      cancel();
      unawaited(apply(landing));
      done?.call();
      return;
    }
    unawaited(apply(_from + (_to - _from) * (_taken / _steps)));
  }

  /// Abandons the ramp where it is. The volume stays where the last step put
  /// it, which is what a hard stop wants: nothing to hear either way.
  void cancel() {
    _timer?.cancel();
    _timer = null;
    _onDone = null;
  }
}
