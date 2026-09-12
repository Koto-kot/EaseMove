/// The elbows library delivered by `ELBOW_001_009_repository_pack_v6`.
///
/// These are the first exercises whose artwork actually exists, so this file
/// guards the two things that were previously untestable: that every frame a
/// timeline walks is a file on disk, and that the file is inside a folder
/// pubspec bundles. A path that is right in YAML and absent from the bundle
/// renders as the "missing frame" placeholder and nothing fails.
library;

import 'dart:io';

import 'package:ease_move/core/clinical/clinical_gate.dart';
import 'package:ease_move/core/config/feature_flags.dart';
import 'package:ease_move/data/content_bundle.dart';
import 'package:ease_move/data/exercise_repository.dart';
import 'package:ease_move/domain/exercise/exercise.dart';
import 'package:ease_move/domain/exercise/exercise_timeline.dart';
import 'package:ease_move/app/app.dart';
import 'package:ease_move/app/providers.dart';
import 'package:ease_move/core/audio/audio_service.dart';
import 'package:ease_move/core/storage/local_store.dart';
import 'package:ease_move/shared/widgets/asset_placeholder.dart';
import 'package:ease_move/shared/widgets/exercise_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/test_assets.dart';

void main() {
  late ContentBundle bundle;

  setUpAll(() async {
    bundle = await ContentBundle.load(bundle: DiskAssetBundle());
  });

  const List<String> elbowIds = <String>[
    'ELBOW_001',
    'ELBOW_002',
    'ELBOW_003',
    'ELBOW_004',
    'ELBOW_005',
    'ELBOW_006',
    'ELBOW_007',
    'ELBOW_008',
    'ELBOW_009',
  ];

  test('the elbow zone is filled and reachable from its body-map dot', () {
    final ExerciseRepository repo = ExerciseRepository(
      bundle: bundle,
      gate: ClinicalGate(
        FeatureFlags.forEnvironment(AppEnvironment.development),
      ),
      assets: DiskAssetBundle(),
    );
    expect(
      repo.byCollection('body_elbows').map((ExerciseSummary s) => s.id),
      elbowIds,
    );
    // Both elbow dots route to that same collection, so either one opens it.
    final Iterable<BodyHotspot> elbows = bundle.bodyMap.hotspots.where(
      (BodyHotspot spot) => spot.zoneId == 'elbows',
    );
    expect(elbows, hasLength(2));
    for (final BodyHotspot spot in elbows) {
      expect(spot.collectionId, 'body_elbows');
    }
  });

  test('every declared image exists on disk and is bundled by pubspec', () {
    final String pubspec = File('pubspec.yaml').readAsStringSync();
    for (final String id in elbowIds) {
      final Exercise exercise = loadExerciseFromDisk(id);
      final List<String?> paths = <String?>[
        exercise.previewAsset,
        for (final ExerciseFrame frame in exercise.frames.values) frame.file,
      ];
      expect(paths, isNotEmpty, reason: id);
      for (final String? path in paths) {
        expect(path, isNotNull, reason: id);
        expect(File(path!).existsSync(), isTrue, reason: path);
        final String folder = '${path.substring(0, path.lastIndexOf('/'))}/';
        expect(pubspec, contains('- $folder'), reason: folder);
      }
    }
  });

  test('a timed elbow exercise opens on its setup pose and loops for 61s', () {
    final Exercise exercise = loadExerciseFromDisk('ELBOW_001');
    final ExerciseTimeline timeline = ExerciseTimeline.build(exercise);

    // What the prep countdown sits on: the full-body start position, not the
    // first frame of the movement (docs/exercise_briefs .../ELBOW_001 8.1).
    expect(timeline.first.keyFrameId, 'FRAME_SETUP');
    expect(timeline.totalDurationMs, 61000);
    expect(exercise.timing.estimatedActiveSeconds, 61);
    expect(exercise.timing.completionMode, 'timed_duration');

    // Timed, so no repetition or side chrome on the player.
    expect(exercise.progress.showRepetitionCounter, isFalse);
    expect(exercise.progress.showSideLabel, isFalse);
    for (final TimelineStep step in timeline.steps) {
      expect(step.effectiveSide, isNull);
    }

    // One cycle of the loop: A -> B, then B -> A.
    final TimelineStep firstCycleStep = timeline.stepAt(1500);
    expect(firstCycleStep.step.frameTransition?.from, 'FRAME_EXTENDED');
    expect(firstCycleStep.step.frameTransition?.to, 'FRAME_FLEXED');
  });

  test('the elbow exercises carry the voice cues their briefs specify', () {
    for (final String id in elbowIds) {
      final Exercise exercise = loadExerciseFromDisk(id);
      for (final String eventId in <String>[
        'VOICE_SETUP',
        'VOICE_START_MOVEMENT',
        'VOICE_HALFWAY',
        'VOICE_COMPLETED',
      ]) {
        final AudioEvent? event = exercise.audioEventById(eventId);
        expect(event, isNotNull, reason: '$id/$eventId');
        expect(event!.text, isNotEmpty, reason: '$id/$eventId');
      }
    }
  });

  testWidgets('the elbow dot opens nine cards and the first one plays', (
    WidgetTester tester,
  ) async {
    final InMemoryLocalStore store = InMemoryLocalStore();
    await store.writeSettings(const AppSettings(localeOverride: 'uk'));

    tester.view
      ..devicePixelRatio = 1.0
      ..physicalSize = const Size(400, 900);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          localStoreProvider.overrideWithValue(store),
          assetBundleProvider.overrideWithValue(DiskAssetBundle()),
          audioServiceProvider.overrideWithValue(LoggingAudioService()),
        ],
        child: const EaseMoveApp(),
      ),
    );
    for (int i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }

    // Paired zone: the dots pulse first, then navigation happens.
    await tester.tap(find.byKey(const ValueKey<String>('hotspot.left_elbow')));
    await tester.pump(const Duration(milliseconds: 400));
    for (int i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }

    expect(find.text('Лікті'), findsWidgets);
    // The list builds lazily, so only what fits the phone screen exists;
    // the full nine are asserted against the repository above.
    expect(find.byType(ExerciseCard), findsAtLeastNWidgets(3));
    expect(find.text('Зігнути — розігнути руки'), findsOneWidget);

    await tester.tap(find.text('Почати').first);
    for (int i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }

    List<String?> shownAssets() => tester
        .widgetList<AssetImageOrPlaceholder>(
          find.byType(AssetImageOrPlaceholder),
        )
        .map((AssetImageOrPlaceholder w) => w.assetPath)
        .toList();

    // The idle player leads with the derived preview...
    expect(
      shownAssets(),
      contains('assets/exercises/ELBOW_001/images/preview.png'),
    );

    await tester.tap(find.widgetWithText(FilledButton, 'Старт'));
    for (int i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }

    // ...and the prep countdown sits on the delivered setup artwork.
    expect(
      shownAssets(),
      contains('assets/exercises/ELBOW_001/images/setup_full_safe.png'),
    );
  });
}
