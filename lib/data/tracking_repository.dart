/// Lifetime counter and exercise history.
///
/// One policy in one place (docs/TECHNICAL_SPEC.md 16). A streak is never used
/// as a guilt mechanism, so nothing here computes one.
library;

import '../core/storage/local_store.dart';
import '../domain/exercise/session_machine.dart';

class ActivityStats {
  const ActivityStats({required this.lifetimeCount, required this.history});

  final int lifetimeCount;
  final List<SessionResult> history;

  static const ActivityStats empty = ActivityStats(
    lifetimeCount: 0,
    history: <SessionResult>[],
  );
}

class TrackingRepository {
  TrackingRepository(this._store);

  final LocalStore _store;

  ActivityStats read() => ActivityStats(
    lifetimeCount: _store.readLifetimeCount(),
    history: _store.readHistory(),
  );

  Future<void> save(SessionResult result) => _store.appendHistory(result);

  Future<void> incrementLifetime() => _store.incrementLifetimeCount();

  Future<void> reset() => _store.resetStats();
}
