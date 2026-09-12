/// The optional rhythm modes and the read-aloud instructions
/// (docs/AUDIO_SPEC.md; ELBOW_001 brief sections 12–13).
///
/// The default stays quiet on purpose: a cue at the start, one halfway and one
/// at the end. The other two modes add one short word per half-cycle, and
/// nothing else about the session changes.
library;

import 'dart:io';

import 'package:ease_move/app/app.dart';
import 'package:ease_move/app/providers.dart';
import 'package:ease_move/core/audio/audio_service.dart';
import 'package:ease_move/core/audio/recorded_voice_audio_service.dart';
import 'package:ease_move/core/storage/local_store.dart';
import 'package:ease_move/domain/exercise/exercise.dart';
import 'package:ease_move/domain/exercise/exercise_timeline.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/test_assets.dart';

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

void main() {
  late Exercise exercise;

  setUp(() {
    exercise = loadExerciseFromDisk('ELBOW_001');
  });

  List<String> cueIds(VoiceMode mode) => ExerciseTimeline.build(
    exercise,
    voiceMode: mode,
  ).cues.map((ScheduledCue cue) => cue.eventId).toList();

  test('the default mode says nothing during the cycles', () {
    final List<String> ids = cueIds(VoiceMode.minimal);
    // prep and completion are fired by the session machine, not the timeline.
    expect(ids, <String>['VOICE_START_MOVEMENT', 'VOICE_HALFWAY']);
  });

  test('movement words speak once per half-cycle, in movement order', () {
    final List<String> ids = cueIds(VoiceMode.phaseWords);
    expect(ids.where((String id) => id == 'VOICE_PHASE_B'), hasLength(15));
    expect(ids.where((String id) => id == 'VOICE_PHASE_A'), hasLength(15));
    // The halfway cue is still there; the count words are not.
    expect(ids, contains('VOICE_HALFWAY'));
    expect(ids, isNot(contains('VOICE_COUNT_ONE')));

    // B is the movement away from the start pose, so it is said first.
    final List<String> rhythm = ids
        .where((String id) => id.startsWith('VOICE_PHASE_'))
        .toList();
    expect(rhythm.first, 'VOICE_PHASE_B');
    expect(rhythm[1], 'VOICE_PHASE_A');
  });

  test('counting swaps the same slots for one and two', () {
    final List<String> ids = cueIds(VoiceMode.count);
    expect(ids.where((String id) => id == 'VOICE_COUNT_ONE'), hasLength(15));
    expect(ids.where((String id) => id == 'VOICE_COUNT_TWO'), hasLength(15));
    expect(ids, isNot(contains('VOICE_PHASE_A')));
  });

  test('every exercise offers both rhythm modes with text to speak', () {
    for (int n = 1; n <= 9; n++) {
      final String id = 'ELBOW_${n.toString().padLeft(3, '0')}';
      final Exercise ex = loadExerciseFromDisk(id);
      for (final String eventId in <String>[
        'VOICE_PHASE_A',
        'VOICE_PHASE_B',
        'VOICE_COUNT_ONE',
        'VOICE_COUNT_TWO',
      ]) {
        final AudioEvent? event = ex.audioEventById(eventId);
        expect(event, isNotNull, reason: '$id/$eventId');
        expect(event!.text, isNotEmpty, reason: '$id/$eventId');
        expect(event.voiceMode, isNotNull, reason: '$id/$eventId');
        // Short enough to land inside a two-second half-cycle.
        expect(event.text!.length, lessThan(24), reason: '$id/$eventId');
      }
    }
  });

  test('the spoken instructions read the purpose, the setup and the steps', () {
    final String speech = exercise.text.spokenInstructions;
    expect(speech, contains(exercise.text.purpose!));
    expect(speech, contains(exercise.text.startPosition!));
    for (final String step in exercise.text.instructions) {
      expect(speech, contains(step));
    }
  });

  testWidgets('the idle screen reads the steps aloud on request', (
    WidgetTester tester,
  ) async {
    final InMemoryLocalStore store = InMemoryLocalStore();
    await store.writeSettings(const AppSettings(localeOverride: 'uk'));
    final LoggingAudioService audio = LoggingAudioService();

    tester.view
      ..devicePixelRatio = 1.0
      ..physicalSize = const Size(400, 900);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          localStoreProvider.overrideWithValue(store),
          assetBundleProvider.overrideWithValue(DiskAssetBundle()),
          audioServiceProvider.overrideWithValue(audio),
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
    await tester.tap(find.byKey(const ValueKey<String>('hotspot.left_elbow')));
    await tester.pump(const Duration(milliseconds: 400));
    await settle();
    await tester.tap(find.text('Почати').first);
    await settle();

    expect(audio.log, isEmpty);
    await tester.tap(find.text('Прослухати інструкцію'));
    await settle();
    expect(audio.log, contains('voice:VOICE_INSTRUCTIONS'));

    // Starting the session cuts the read-aloud short rather than talking over
    // the preparation cue.
    await tester.tap(find.widgetWithText(FilledButton, 'Старт'));
    await settle();
    expect(audio.log, contains('stop'));
    expect(audio.log, contains('voice:VOICE_SETUP'));
  });

  group('the recorded pack', () {
    late LoggingAudioService fallback;
    late RecordedVoiceAudioService service;

    setUp(() {
      fallback = LoggingAudioService();
      // Nothing is recorded yet, so every load fails — which is exactly the
      // state the app ships in today.
      service = RecordedVoiceAudioService(
        fallback: fallback,
        languageCode: 'uk',
        bundle: DiskAssetBundle(),
      );
    });

    test('a line that is not recorded is spoken instead', () async {
      final Exercise ex = loadExerciseFromDisk('ELBOW_001');
      final AudioEvent event = ex.audioEventById('VOICE_SETUP')!;
      expect(event.assetFile, 'audio/uk/exercises/ELBOW_001/setup.m4a');

      await service.playVoice(event);
      await service.playCountdownTick(3);

      expect(fallback.log, <String>['voice:VOICE_SETUP', 'tick:3']);
    });

    test('the English pack is complete and bundled', () async {
      final String pubspec = File('pubspec.yaml').readAsStringSync();
      final RecordedVoiceAudioService english = RecordedVoiceAudioService(
        fallback: fallback,
        languageCode: 'en',
        bundle: DiskAssetBundle(),
      );

      final List<String> ids = <String>[
        'NECK_001',
        'KNEE_001',
        'KNEE_002',
        'KNEE_003',
        ...elbowIds,
      ];
      for (final String id in ids) {
        final Exercise ex = loadExerciseFromDisk(id);
        for (final AudioEvent event in ex.audioEvents) {
          final String? path = english.localizedAssetPath(event.assetFile);
          if (path == null) continue;
          expect(File(path).existsSync(), isTrue, reason: '$id: $path');
          final String folder = path.substring(0, path.lastIndexOf('/') + 1);
          expect(pubspec, contains('- $folder'), reason: folder);
        }
      }

      // Including the countdown, which no exercise declares by name.
      for (int n = 1; n <= 5; n++) {
        expect(
          File('audio/en/common/countdown_$n.m4a').existsSync(),
          isTrue,
          reason: 'countdown_$n',
        );
      }

      // And the service resolves them to the pack rather than the fallback.
      // (Playing one here would need a real platform audio player.)
      expect(
        await english.isBundled('audio/en/exercises/ELBOW_001/setup.m4a'),
        isTrue,
      );
      expect(fallback.log, isEmpty);
    });

    test('the file is looked up under the chosen language', () {
      final RecordedVoiceAudioService english = RecordedVoiceAudioService(
        fallback: fallback,
        languageCode: 'en',
        bundle: DiskAssetBundle(),
      );
      expect(
        english.localizedAssetPath('audio/uk/exercises/ELBOW_001/setup.m4a'),
        'audio/en/exercises/ELBOW_001/setup.m4a',
      );
      expect(english.localizedAssetPath(null), isNull);
    });
  });

  testWidgets('Settings offers the three voice modes and remembers the pick', (
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
    await tester.tap(find.byTooltip('Налаштування'));
    await settle();

    expect(find.text('Мінімум голосу'), findsOneWidget);
    expect(find.text('Слова руху'), findsOneWidget);
    expect(find.text('Лічба'), findsOneWidget);

    await tester.tap(find.text('Слова руху'));
    await settle();
    expect(store.readSettings().voiceMode, VoiceMode.phaseWords);

    // Turning the voice off hides the choice: none of the three would change
    // anything while nothing is spoken.
    await tester.tap(find.text('Голосові команди'));
    await settle();
    expect(find.text('Слова руху'), findsNothing);
  });
}
