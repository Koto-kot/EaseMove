/// Catalog access.
///
/// Everything the bundle carries is shown. There used to be a clinical gate
/// here that hid anything not marked `approved`, which in practice hid the
/// whole library outside a development build (docs/DECISIONS.md 88).
library;

import 'package:flutter/services.dart';

import '../domain/exercise/exercise.dart';
import 'content_bundle.dart';

class ExerciseRepository {
  ExerciseRepository({required this.bundle, this.assets});

  final ContentBundle bundle;

  final AssetBundle? assets;
  final Map<String, Exercise> _cache = <String, Exercise>{};

  /// Exercises of a collection, in editorial (index) order.
  List<ExerciseSummary> byCollection(String collectionId) => <ExerciseSummary>[
    for (final ExerciseSummary summary in bundle.exercises)
      if (summary.collections.contains(collectionId)) summary,
  ];

  List<ExerciseSummary> byZone(String zoneId) => <ExerciseSummary>[
    for (final ExerciseSummary summary in bundle.exercises)
      if (summary.primaryZone == zoneId) summary,
  ];

  /// Zone collections that have at least one exercise, in the documented
  /// top-to-bottom order (docs/MENU_AND_NAVIGATION.md).
  List<ExerciseCollection> nonEmptyZoneCollections() {
    final Map<String, int> order = <String, int>{
      for (final BodyZone zone in bundle.zones) zone.id: zone.order,
    };
    final List<ExerciseCollection> result = <ExerciseCollection>[
      for (final ExerciseCollection collection in bundle.collections)
        if (collection.isBodyZone && byCollection(collection.id).isNotEmpty)
          collection,
    ];
    result.sort((ExerciseCollection a, ExerciseCollection b) {
      final int aOrder = order[a.primaryZone] ?? 1 << 20;
      final int bOrder = order[b.primaryZone] ?? 1 << 20;
      return aOrder.compareTo(bOrder);
    });
    return result;
  }

  /// Full record for the player. Cached: the player needs the current and the
  /// next exercise, not the whole library (docs/EXERCISE_ENGINE.md, Scaling).
  Future<Exercise> load(String id) async {
    final Exercise? cached = _cache[id];
    if (cached != null) return cached;
    final Exercise exercise = await ContentBundle.loadExercise(
      id,
      bundle: assets,
      // The record has to come from the same language as the catalog row the
      // user tapped, or the player would open in the other language.
      locale: bundle.locale,
    );
    _cache[id] = exercise;
    return exercise;
  }

  /// Neighbour lookup inside the collection the user entered from, which is
  /// what Previous/Next and auto-next walk through.
  ExerciseSummary? neighbour(
    String collectionId,
    String currentId,
    int direction,
  ) {
    final List<ExerciseSummary> list = byCollection(collectionId);
    final int index = list.indexWhere((ExerciseSummary s) => s.id == currentId);
    if (index < 0) return null;
    final int target = index + direction;
    if (target < 0 || target >= list.length) return null;
    return list[target];
  }
}
