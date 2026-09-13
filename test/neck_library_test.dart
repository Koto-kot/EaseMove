/// The neck library delivered by `NECK_001_010_repository_pack_v14_QA`.
///
/// Ten exercises, all with artwork, and one of them older than the pack: head
/// turns were the repository's NECK_001 long before this pack numbered them
/// 002. That renumbering is the thing most likely to rot silently - a stale id
/// in a path, a cue file left behind under the old folder - so it is asserted
/// here rather than trusted.
library;

import 'dart:io';

import 'package:ease_move/app/app.dart';
import 'package:ease_move/app/providers.dart';
import 'package:ease_move/core/audio/audio_service.dart';
import 'package:ease_move/core/storage/local_store.dart';
import 'package:ease_move/data/content_bundle.dart';
import 'package:ease_move/data/exercise_repository.dart';
import 'package:ease_move/domain/exercise/exercise.dart';
import 'package:ease_move/domain/exercise/exercise_timeline.dart';
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

  const List<String> neckIds = <String>[
    'NECK_001',
    'NECK_002',
    'NECK_003',
    'NECK_004',
    'NECK_005',
    'NECK_006',
    'NECK_007',
    'NECK_008',
    'NECK_009',
    'NECK_010',
  ];

  /// The nine authored from the pack's briefs. NECK_002 is the older file and
  /// keeps its own shape, so it is not one of them.
  const List<String> timedIds = <String>[
    'NECK_001',
    'NECK_003',
    'NECK_004',
    'NECK_005',
    'NECK_006',
    'NECK_007',
    'NECK_008',
    'NECK_009',
    'NECK_010',
  ];

  test('the neck zone is filled, in the pack order, and reachable', () {
    final ExerciseRepository repo = ExerciseRepository(
      bundle: bundle,
      assets: DiskAssetBundle(),
    );
    expect(
      repo.byCollection('body_neck').map((ExerciseSummary s) => s.id),
      neckIds,
    );
    final Iterable<BodyHotspot> neck = bundle.bodyMap.hotspots.where(
      (BodyHotspot spot) => spot.zoneId == 'neck',
    );
    expect(neck, isNotEmpty);
    for (final BodyHotspot spot in neck) {
      expect(spot.collectionId, 'body_neck');
    }
  });

  test('every declared image exists on disk and is bundled by pubspec', () {
    final String pubspec = File('pubspec.yaml').readAsStringSync();
    for (final String id in neckIds) {
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

  test('the renumbering left nothing pointing at the old id', () {
    // Head turns used to be NECK_001. Every path inside the file has to have
    // moved with it, or the app quietly renders placeholders and plays the
    // fallback voice.
    final Exercise headTurns = loadExerciseFromDisk('NECK_002');
    expect(headTurns.text.title, 'Повороти голови');
    for (final ExerciseFrame frame in headTurns.frames.values) {
      expect(frame.file, contains('assets/exercises/NECK_002/'));
    }
    for (final AudioEvent event in headTurns.audioEvents) {
      final String? file = event.assetFile;
      if (file == null || !file.contains('/exercises/')) continue;
      expect(file, contains('/NECK_002/'));
      expect(File(file).existsSync(), isTrue, reason: file);
    }
    // And the chin tuck, which took the vacated id, is a different exercise.
    expect(loadExerciseFromDisk('NECK_001').text.title, 'Підборіддя назад');
  });

  test('the nine authored exercises are timed loops of 61 seconds', () {
    for (final String id in timedIds) {
      final Exercise exercise = loadExerciseFromDisk(id);
      final ExerciseTimeline timeline = ExerciseTimeline.build(exercise);

      expect(timeline.first.keyFrameId, 'FRAME_SETUP', reason: id);
      expect(timeline.totalDurationMs, 61000, reason: id);
      expect(exercise.timing.completionMode, 'timed_duration', reason: id);
      expect(exercise.progress.showRepetitionCounter, isFalse, reason: id);
      expect(exercise.progress.showSideLabel, isFalse, reason: id);
      for (final TimelineStep step in timeline.steps) {
        expect(step.effectiveSide, isNull, reason: id);
      }
    }
  });

  test('head turns kept the dosing its sources prescribe', () {
    // Three cycles with a five-second hold on each side, from the NHS
    // material the file cites - not the pack's undifferentiated 60 second
    // loop. It is also the library's only `repeat_cycles` exercise.
    final Exercise exercise = loadExerciseFromDisk('NECK_002');
    final ExerciseTimeline timeline = ExerciseTimeline.build(exercise);

    expect(timeline.totalRepetitions, 3);
    expect(timeline.totalDurationMs, 51000);
    expect(timeline.steps[1].effectiveSide, BodySide.left);
    expect(timeline.steps[5].effectiveSide, BodySide.right);
  });

  test('every neck exercise carries the cues its brief specifies', () {
    for (final String id in neckIds) {
      final Exercise exercise = loadExerciseFromDisk(id);
      for (final String eventId in <String>['VOICE_COMPLETED']) {
        final AudioEvent? event = exercise.audioEventById(eventId);
        expect(event, isNotNull, reason: '$id/$eventId');
        expect(event!.text, isNotEmpty, reason: '$id/$eventId');
      }
    }
    // The rhythm modes are data, so the nine authored files carry them and a
    // listener who picked a mode hears something in every one of them.
    for (final String id in timedIds) {
      final Exercise exercise = loadExerciseFromDisk(id);
      for (final String eventId in <String>[
        'VOICE_SETUP',
        'VOICE_START_MOVEMENT',
        'VOICE_PHASE_A',
        'VOICE_PHASE_B',
        'VOICE_COUNT_ONE',
        'VOICE_COUNT_TWO',
      ]) {
        final AudioEvent? event = exercise.audioEventById(eventId);
        expect(event, isNotNull, reason: '$id/$eventId');
        expect(event!.text, isNotEmpty, reason: '$id/$eventId');
      }
    }
  });

  test('both languages describe every neck frame for a screen reader', () {
    for (final String id in neckIds) {
      for (final String locale in <String>['uk', 'en']) {
        final Exercise exercise = loadExerciseFromDisk(id, locale: locale);
        expect(exercise.accessibilitySummary, isNotNull, reason: '$id/$locale');
        for (final ExerciseFrame frame in exercise.frames.values) {
          expect(frame.altText, isNotNull, reason: '$id/$locale/${frame.id}');
          expect(frame.altText, isNotEmpty, reason: '$id/$locale/${frame.id}');
        }
      }
    }
  });

  testWidgets('the neck dot opens the library and the first card plays', (
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
    Future<void> settle() async {
      for (int i = 0; i < 8; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }
    }

    await settle();
    await tester.tap(find.byKey(const ValueKey<String>('hotspot.neck')));
    await tester.pump(const Duration(milliseconds: 400));
    await settle();

    expect(find.text('Шия'), findsWidgets);
    expect(find.byType(ExerciseCard), findsAtLeastNWidgets(3));
    expect(find.text('Підборіддя назад'), findsOneWidget);

    await tester.tap(find.text('Почати').first);
    await settle();

    List<String?> shownAssets() => tester
        .widgetList<AssetImageOrPlaceholder>(
          find.byType(AssetImageOrPlaceholder),
        )
        .map((AssetImageOrPlaceholder w) => w.assetPath)
        .toList();

    expect(
      shownAssets(),
      contains('assets/exercises/NECK_001/images/preview.png'),
    );

    await tester.tap(find.widgetWithText(FilledButton, 'Старт'));
    await settle();

    expect(
      shownAssets(),
      contains('assets/exercises/NECK_001/images/setup_full_safe.png'),
    );
  });
}
