import 'dart:io';

import 'package:ease_move/data/content_bundle.dart';
import 'package:ease_move/data/exercise_repository.dart';
import 'package:ease_move/domain/exercise/exercise.dart';
import 'package:ease_move/domain/exercise/exercise_timeline.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/test_assets.dart';

void main() {
  late ContentBundle bundle;

  setUpAll(() async {
    bundle = await ContentBundle.load(bundle: DiskAssetBundle());
  });

  test('the generated bundle exists — run scripts/build_content.py first', () {
    for (final String locale in <String>['uk', 'en']) {
      expect(
        File('assets/content/$locale/index.json').existsSync(),
        isTrue,
        reason: locale,
      );
    }
  });

  test('every catalog entry parses and has renderable text', () {
    expect(bundle.exercises, isNotEmpty);
    for (final ExerciseSummary summary in bundle.exercises) {
      expect(summary.title, isNotEmpty, reason: summary.id);
      expect(summary.cardDescription, isNotEmpty, reason: summary.id);
      expect(summary.primaryZone, isNotEmpty, reason: summary.id);
      expect(
        summary.estimatedActiveSeconds,
        greaterThan(0),
        reason: summary.id,
      );
    }
  });

  test('every exercise record parses into a runnable timeline', () {
    for (final ExerciseSummary summary in bundle.exercises) {
      final Exercise exercise = loadExerciseFromDisk(summary.id);
      final ExerciseTimeline timeline = ExerciseTimeline.build(exercise);

      expect(timeline.steps, isNotEmpty, reason: summary.id);
      expect(timeline.totalDurationMs, greaterThan(0), reason: summary.id);
      expect(
        (timeline.totalDurationMs / 1000).round(),
        exercise.timing.estimatedActiveSeconds,
        reason:
            '${summary.id}: authored estimate must match the built timeline',
      );

      // Every frame a step points at must exist in the animation block.
      for (final TimelineStep step in timeline.steps) {
        final String? frameId = step.frameAt(step.startMs);
        expect(
          exercise.frames.containsKey(frameId),
          isTrue,
          reason: '${summary.id}/$frameId',
        );
      }

      // Every scheduled cue must resolve to a declared audio event.
      for (final ScheduledCue cue in timeline.cues) {
        expect(
          exercise.audioEventById(cue.eventId),
          isNotNull,
          reason: cue.eventId,
        );
      }
    }
  });

  test('collections referenced by exercises exist in the bundle', () {
    final Set<String> ids = <String>{
      for (final ExerciseCollection collection in bundle.collections)
        collection.id,
    };
    for (final ExerciseSummary summary in bundle.exercises) {
      for (final String collectionId in summary.collections) {
        expect(ids, contains(collectionId), reason: summary.id);
      }
    }
  });

  test('body map hotspots sit on the figure and route to a collection', () {
    expect(bundle.bodyMap.hotspots, isNotEmpty);
    final Set<String> ids = <String>{
      for (final ExerciseCollection collection in bundle.collections)
        collection.id,
    };
    final Set<String> spotIds = <String>{
      for (final BodyHotspot spot in bundle.bodyMap.hotspots) spot.id,
    };
    for (final BodyHotspot spot in bundle.bodyMap.hotspots) {
      // Compiled into the cropped figure's space, so anything outside 0..1 is
      // a dot the user could never reach.
      expect(spot.cx, inInclusiveRange(0, 1), reason: spot.id);
      expect(spot.cy, inInclusiveRange(0, 1), reason: spot.id);
      expect(spot.view, anyOf('front', 'back_mini'), reason: spot.id);
      expect(bundle.bodyMap.artwork, contains(spot.view), reason: spot.id);
      expect(ids, contains(spot.collectionId), reason: spot.id);
      expect(bundle.zoneById(spot.zoneId), isNotNull, reason: spot.id);
      expect(spot.highlightTargets, contains(spot.id), reason: spot.id);
      for (final String target in spot.highlightTargets) {
        expect(spotIds, contains(target), reason: spot.id);
      }
    }
  });

  test('paired zones highlight both sides and share one collection', () {
    // docs/ui/home/HOME_SCREEN_REPOSITORY_BRIEF.md 5.3.
    final Map<String, List<BodyHotspot>> byGroup =
        <String, List<BodyHotspot>>{};
    for (final BodyHotspot spot in bundle.bodyMap.hotspots) {
      byGroup.putIfAbsent(spot.group, () => <BodyHotspot>[]).add(spot);
    }
    for (final MapEntry<String, List<BodyHotspot>> entry in byGroup.entries) {
      final Set<String> collections = <String>{
        for (final BodyHotspot spot in entry.value) spot.collectionId,
      };
      expect(collections, hasLength(1), reason: entry.key);
      for (final BodyHotspot spot in entry.value) {
        expect(spot.highlightTargets.toSet(), <String>{
          for (final BodyHotspot s in entry.value) s.id,
        }, reason: spot.id);
      }
    }
  });

  test('every home card points somewhere that exists', () {
    final HomeConfig home = bundle.home;
    expect(home.sections, hasLength(4));
    expect(home.titleKey, isNotEmpty);
    for (final HomeSection section in home.sections) {
      if (section.opensZones) continue;
      expect(
        bundle.collectionById(section.targetCollectionId!),
        isNotNull,
        reason: section.id,
      );
    }
  });

  test('every navigation entry point resolves to a collection', () {
    // The four home cards, per docs/ui/home/HOME_SCREEN_LAYOUT_SPEC.md.
    for (final String id in <String>[
      'eyes_basic',
      'morning_energy',
      'after_sitting',
    ]) {
      final ExerciseCollection? collection = bundle.collectionById(id);
      expect(collection, isNotNull, reason: id);
      expect(collection!.title, isNotEmpty, reason: id);
    }
  });

  group('the library is shown whole', () {
    // The clinical gate is gone: it hid anything not marked `approved`, and
    // nothing in the library is marked approved, so outside a development
    // build the app had no content at all (docs/DECISIONS.md 88).
    test('every environment shows the same exercises', () {
      final ExerciseRepository production = ExerciseRepository(
        bundle: bundle,
        assets: DiskAssetBundle(),
      );
      expect(production.byCollection('body_knees'), isNotEmpty);
      expect(production.byCollection('body_neck'), hasLength(10));
      expect(production.byCollection('body_elbows'), hasLength(9));
      expect(production.nonEmptyZoneCollections(), isNotEmpty);
    });

    test('the status still travels with each exercise', () {
      // Removing the gate removed the filter, not the fact: the exercise
      // screen still says a movement has not been reviewed.
      expect(
        bundle.exercises.every(
          (ExerciseSummary summary) =>
              summary.clinicalStatus == ClinicalStatus.pendingReview,
        ),
        isTrue,
      );
    });
  });

  group('catalog navigation', () {
    late ExerciseRepository repository;

    setUp(() {
      repository = ExerciseRepository(
        bundle: bundle,
        assets: DiskAssetBundle(),
      );
    });

    test('a zone lists its exercises in index order', () {
      final List<ExerciseSummary> knees = repository.byCollection('body_knees');
      expect(knees.map((ExerciseSummary s) => s.id), <String>[
        'KNEE_001',
        'KNEE_002',
        'KNEE_003',
      ]);
    });

    test(
      'one exercise can belong to several collections without duplication',
      () {
        final List<String> computer = repository
            .byCollection('computer_break')
            .map((ExerciseSummary s) => s.id)
            .toList();

        // Every one of these is also in body_<zone> and in after_sitting, and
        // each still appears exactly once here.
        expect(computer.toSet(), hasLength(computer.length));
        expect(computer, containsAll(<String>['NECK_002', 'KNEE_001']));
        expect(
          computer.where((String id) => id.startsWith('ELBOW_')),
          hasLength(9),
        );
        expect(
          computer.where((String id) => id.startsWith('NECK_')),
          hasLength(10),
        );

        // The library order carries over from the index, not the collection.
        expect(computer.first, 'NECK_001');
      },
    );

    test('neighbour lookup walks the collection and stops at its ends', () {
      expect(repository.neighbour('body_knees', 'KNEE_001', 1)?.id, 'KNEE_002');
      expect(
        repository.neighbour('body_knees', 'KNEE_002', -1)?.id,
        'KNEE_001',
      );
      expect(repository.neighbour('body_knees', 'KNEE_001', -1), isNull);
      expect(repository.neighbour('body_knees', 'KNEE_003', 1), isNull);
    });

    test('zone collections come back in the documented body order', () {
      expect(
        repository.nonEmptyZoneCollections().map(
          (ExerciseCollection c) => c.id,
        ),
        // KNEE_002 also belongs to body_hips, so that zone is non-empty too,
        // and the order is the zone order of data/categories/body_zones.yaml.
        <String>['body_neck', 'body_elbows', 'body_hips', 'body_knees'],
      );
    });

    test('the full record loads from the bundle and is cached', () async {
      final Exercise first = await repository.load('KNEE_001');
      final Exercise second = await repository.load('KNEE_001');
      expect(first, same(second));
      expect(first.text.instructions.length, 7);
    });
  });
}
