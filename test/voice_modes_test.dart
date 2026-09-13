/// The optional rhythm modes and the read-aloud instructions
/// (docs/AUDIO_SPEC.md; ELBOW_001 brief sections 12–13).
///
/// The default stays quiet on purpose: a cue at the start and one at the end.
/// The other two modes add one short word per half-cycle, and nothing else
/// about the session changes.
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
    expect(ids, <String>['VOICE_START_MOVEMENT']);
  });

  test('movement words speak once per half-cycle, in movement order', () {
    final List<String> ids = cueIds(VoiceMode.phaseWords);
    expect(ids.where((String id) => id == 'VOICE_PHASE_B'), hasLength(15));
    expect(ids.where((String id) => id == 'VOICE_PHASE_A'), hasLength(15));
    // The movement command is still there; the count words are not.
    expect(ids, contains('VOICE_START_MOVEMENT'));
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

  group('the whole library, not just the elbows', () {
    /// Every exercise the app can open, read from the compiled index.
    List<String> libraryIds() {
      final Map<String, dynamic> index = loadJsonFromDisk(
        'assets/content/uk/index.json',
      );
      return <String>[
        for (final dynamic e in index['exercises'] as List<dynamic>)
          (e as Map)['id'] as String,
      ];
    }

    test('the three modes really differ, in every exercise', () {
      for (final String id in libraryIds()) {
        final Exercise ex = loadExerciseFromDisk(id);
        List<String> cues(VoiceMode mode) => ExerciseTimeline.build(
          ex,
          voiceMode: mode,
        ).cues.map((ScheduledCue cue) => cue.eventId).toList();

        final Set<String> minimal = cues(VoiceMode.minimal).toSet();
        final Set<String> words = cues(VoiceMode.phaseWords).toSet();
        final Set<String> counting = cues(VoiceMode.count).toSet();

        // The quiet default has to be quiet everywhere. Three knee exercises
        // and the head turns narrated every phase in all three modes, which
        // made the setting look broken (docs/DECISIONS.md 77).
        for (final String cueId in minimal) {
          expect(
            ex.audioEventById(cueId)!.voiceMode,
            isNull,
            reason: '$id: $cueId is spoken in the minimal mode',
          );
        }
        expect(
          words.difference(minimal),
          isNotEmpty,
          reason: '$id: the movement-words mode adds nothing',
        );
        expect(
          counting.difference(minimal),
          isNotEmpty,
          reason: '$id: the counting mode adds nothing',
        );
        expect(words.difference(minimal), isNot(counting.difference(minimal)));
      }
    });

    test('no cue is scheduled at a time no tick can reach', () {
      for (final String id in libraryIds()) {
        final Exercise ex = loadExerciseFromDisk(id);
        for (final VoiceMode mode in VoiceMode.values) {
          final ExerciseTimeline timeline = ExerciseTimeline.build(
            ex,
            voiceMode: mode,
          );
          for (final ScheduledCue cue in timeline.cues) {
            expect(cue.atMs, greaterThanOrEqualTo(0), reason: '$id/$cue');
            expect(
              cue.atMs,
              lessThanOrEqualTo(timeline.totalDurationMs),
              reason: '$id: ${cue.eventId} falls past the end',
            );
          }
        }
      }
    });

    test('a cue with an unreachable trigger would have no offset at all', () {
      // The compile step refuses an unknown trigger, so every cue in the
      // library reaches the timeline. This checks the other half: each
      // exercise's movement cues actually land somewhere.
      for (final String id in libraryIds()) {
        final Exercise ex = loadExerciseFromDisk(id);
        final Set<String> scheduled = <String>{
          for (final VoiceMode mode in VoiceMode.values)
            ...ExerciseTimeline.build(
              ex,
              voiceMode: mode,
            ).cues.map((ScheduledCue cue) => cue.eventId),
        };
        for (final AudioEvent event in ex.audioEvents) {
          // These two are fired by the session machine, outside the timeline.
          if (event.trigger.event == 'prep_countdown_started') continue;
          if (event.trigger.event == 'exercise_completed') continue;
          expect(
            scheduled,
            contains(event.id),
            reason: '$id: ${event.id} is never heard',
          );
        }
      }
    });
  });

  group('a cue that may not be spoken over', () {
    /// The controller has to be told when the voice is free again, because
    /// nothing reports a line finishing: text-to-speech is asked not to await
    /// completion so that a higher-priority cue can cut in. A clock the test
    /// drives stands in for the wall clock.
    late DateTime now;

    SessionAudioController controllerFor(AudioService service) {
      now = DateTime(2026);
      return SessionAudioController(
        service: service,
        mix: exercise.audioMix,
        voiceEnabled: true,
        musicEnabled: false,
        clock: () => now,
      );
    }

    List<String> spoken(LoggingAudioService audio) => <String>[
      for (final String entry in audio.log)
        if (entry.startsWith('voice:')) entry.substring(6),
    ];

    test('holds the voice while it runs, and lets go when it ends', () async {
      final LoggingAudioService audio = LoggingAudioService(
        voiceLength: const Duration(seconds: 3),
      );
      final SessionAudioController controller = controllerFor(audio);

      // "Зігніть руки в ліктях, потім плавно розігніть" — priority 100 and
      // not interruptible.
      await controller.play(exercise.audioEventById('VOICE_START_MOVEMENT')!);
      // The first rhythm word lands while it is still being said, and is
      // dropped rather than spoken over it.
      now = now.add(const Duration(seconds: 1));
      await controller.play(exercise.audioEventById('VOICE_PHASE_B')!);
      expect(spoken(audio), <String>['VOICE_START_MOVEMENT']);

      // Once the line is over, the rhythm words go through — for the whole
      // exercise, not just the next one. Before the floor could expire, the
      // first non-interruptible cue silenced every lower-priority cue until
      // the session ended (docs/DECISIONS.md 75).
      now = now.add(const Duration(seconds: 3));
      await controller.play(exercise.audioEventById('VOICE_PHASE_A')!);
      now = now.add(const Duration(seconds: 2));
      await controller.play(exercise.audioEventById('VOICE_PHASE_B')!);
      now = now.add(const Duration(seconds: 2));
      await controller.play(exercise.audioEventById('VOICE_PHASE_A')!);

      expect(spoken(audio), <String>[
        'VOICE_START_MOVEMENT',
        'VOICE_PHASE_A',
        'VOICE_PHASE_B',
        'VOICE_PHASE_A',
      ]);
    });

    test('a higher-priority cue still cuts in', () async {
      final LoggingAudioService audio = LoggingAudioService(
        voiceLength: const Duration(seconds: 3),
      );
      final SessionAudioController controller = controllerFor(audio);

      await controller.play(exercise.audioEventById('VOICE_START_MOVEMENT')!);
      now = now.add(const Duration(milliseconds: 500));
      // "Готово." is priority 120: the session ending outranks anything.
      await controller.play(exercise.audioEventById('VOICE_COMPLETED')!);

      expect(spoken(audio), <String>[
        'VOICE_START_MOVEMENT',
        'VOICE_COMPLETED',
      ]);
    });

    test('a player that says nothing holds nothing', () async {
      final LoggingAudioService audio = LoggingAudioService();
      final SessionAudioController controller = controllerFor(audio);

      await controller.play(exercise.audioEventById('VOICE_START_MOVEMENT')!);
      await controller.play(exercise.audioEventById('VOICE_PHASE_B')!);
      expect(spoken(audio), hasLength(2));
    });
  });

  test('the spoken instructions read the purpose, the setup and the steps', () {
    final String speech = exercise.text.spokenInstructions;
    expect(speech, contains(exercise.text.purpose!));
    expect(speech, contains(exercise.text.startPosition!));
    for (final String step in exercise.text.instructions) {
      expect(speech, contains(step));
    }
    // And the passage names the recording of itself, so the button plays the
    // pack's voice instead of the device's own (docs/DECISIONS.md 78).
    expect(
      exercise.text.spokenInstructionsAsset,
      'audio/uk/exercises/ELBOW_001/instructions.m4a',
    );
  });

  testWidgets('the idle screen reads the steps aloud on request', (
    WidgetTester tester,
  ) async {
    final LoggingAudioService audio = LoggingAudioService();
    await openFirstElbow(tester, audio: audio);

    expect(audio.log, isEmpty);
    await tester.tap(find.text('Прослухати інструкцію'));
    await settleFrames(tester);
    expect(audio.log, contains('voice:VOICE_INSTRUCTIONS'));

    // Aloud means aloud: the steps do not also land under the model.
    expect(find.text('Як виконувати'), findsNothing);

    // Starting the session cuts the read-aloud short rather than talking over
    // the preparation cue.
    await tester.tap(find.widgetWithText(FilledButton, 'Старт'));
    await settleFrames(tester);
    expect(audio.log, contains('stop'));
    expect(audio.log, contains('voice:VOICE_SETUP'));
  });

  testWidgets('reading and listening are two separate offers', (
    WidgetTester tester,
  ) async {
    final LoggingAudioService audio = LoggingAudioService();
    await openFirstElbow(tester, audio: audio);

    // Neither happens on its own: the model and the purpose are the whole
    // screen until the listener picks a way in.
    expect(find.byType(AspectRatio), findsWidgets);
    expect(find.text('Як виконувати'), findsNothing);
    expect(find.text('Зверніть увагу'), findsNothing);
    expect(find.text('Безпека'), findsNothing);
    expect(find.text('Прослухати інструкцію'), findsOneWidget);
    expect(find.text('Прочитати інструкцію'), findsOneWidget);

    // Reading puts the whole text on the page and says nothing. The model
    // steps aside to make room for it.
    await tester.tap(find.text('Прочитати інструкцію'));
    await settleFrames(tester);
    expect(find.byType(AspectRatio), findsNothing);
    expect(find.text('Початкове положення'), findsOneWidget);
    expect(find.text('Як виконувати'), findsOneWidget);
    expect(audio.log, isEmpty);

    // The step's number is its own column, so a wrapped line starts under the
    // text and not under the number (docs/DECISIONS.md 79). That means the
    // step reads as its own string, with no "1. " glued to the front.
    final String firstStep = loadExerciseFromDisk('ELBOW_001')
        .text
        .instructions
        .first;
    expect(find.text(firstStep), findsOneWidget);
    expect(find.text('1. $firstStep'), findsNothing);
    expect(find.text('1.'), findsOneWidget);

    // Read at 18, not at the platform's 16 (docs/DECISIONS.md 89).
    expect(tester.widget<Text>(find.text(firstStep)).style?.fontSize, 18);
    expect(
      tester.widget<Text>(find.text('Як виконувати')).style?.fontSize,
      greaterThan(18),
      reason: 'a heading is not smaller than the text under it',
    );

    // The tips and the warning are further down the same page. How many
    // drags that takes depends on the text size, so scroll until they show
    // rather than assuming a distance.
    Future<void> scrollTo(String label) async {
      for (int i = 0; i < 12 && find.text(label).evaluate().isEmpty; i++) {
        await tester.drag(find.byType(ListView), const Offset(0, -300));
        await settleFrames(tester);
      }
    }

    await scrollTo('Зверніть увагу');
    expect(find.text('Зверніть увагу'), findsOneWidget);
    await scrollTo('Безпека');
    expect(find.text('Безпека'), findsOneWidget);

    // The same button folds them away again.
    await tester.tap(find.text('Сховати інструкцію'));
    await settleFrames(tester);
    expect(find.text('Як виконувати'), findsNothing);

    // Listening offers to cut itself short, and takes the steps back off the
    // page if they were on it.
    await tester.tap(find.text('Прочитати інструкцію'));
    await settleFrames(tester);
    await tester.tap(find.text('Прослухати інструкцію'));
    await settleFrames(tester);
    expect(audio.log, contains('voice:VOICE_INSTRUCTIONS'));
    expect(find.text('Початкове положення'), findsNothing);

    await tester.tap(find.text('Зупинити'));
    await settleFrames(tester);
    expect(audio.log, contains('stop'));
    expect(find.text('Прослухати інструкцію'), findsOneWidget);
  });

  testWidgets('a silenced voice leaves only the offer to read', (
    WidgetTester tester,
  ) async {
    await openFirstElbow(
      tester,
      audio: LoggingAudioService(),
      settings: const AppSettings(localeOverride: 'uk', voiceEnabled: false),
    );

    expect(find.text('Прослухати інструкцію'), findsNothing);
    expect(find.text('Прочитати інструкцію'), findsOneWidget);
  });

  group('the recorded pack', () {
    late LoggingAudioService fallback;

    setUp(() {
      fallback = LoggingAudioService();
    });

    test('a line that is not recorded is spoken instead', () async {
      // Both packs are complete, so the fallback is exercised with a language
      // that has none — which is what any new language starts as.
      final RecordedVoiceAudioService unrecorded = RecordedVoiceAudioService(
        fallback: fallback,
        languageCode: 'pl',
        bundle: DiskAssetBundle(),
      );
      final Exercise ex = loadExerciseFromDisk('ELBOW_001');

      await unrecorded.playVoice(ex.audioEventById('VOICE_SETUP')!);
      await unrecorded.playCountdownTick(3);

      expect(fallback.log, <String>['voice:VOICE_SETUP', 'tick:3']);
    });

    for (final String lang in <String>['uk', 'en']) {
      test('the $lang pack is complete and bundled', () async {
        final String pubspec = File('pubspec.yaml').readAsStringSync();
        final RecordedVoiceAudioService pack = RecordedVoiceAudioService(
          fallback: fallback,
          languageCode: lang,
          bundle: DiskAssetBundle(),
        );

        final List<String> ids = <String>[
          'NECK_002',
          'KNEE_001',
          'KNEE_002',
          'KNEE_003',
          ...elbowIds,
        ];
        for (final String id in ids) {
          final Exercise ex = loadExerciseFromDisk(id);
          for (final AudioEvent event in ex.audioEvents) {
            final String? path = pack.localizedAssetPath(event.assetFile);
            if (path == null) continue;
            expect(File(path).existsSync(), isTrue, reason: '$id: $path');
            final String folder = path.substring(0, path.lastIndexOf('/') + 1);
            expect(pubspec, contains('- $folder'), reason: folder);
          }
        }

        // Including the read-aloud instruction passage, which is what the
        // "listen to the steps" button plays: before it was recorded, that
        // button fell through to the device's own text-to-speech and sounded
        // nothing like the rest of the session (docs/DECISIONS.md 78).
        for (final String id in ids) {
          final Exercise ex = loadExerciseFromDisk(id);
          final String? passage = pack.localizedAssetPath(
            ex.text.spokenInstructionsAsset,
          );
          expect(passage, isNotNull, reason: '$id has no read-aloud asset');
          expect(passage, startsWith('audio/$lang/'));
          expect(File(passage!).existsSync(), isTrue, reason: '$id: $passage');
          expect(await pack.isBundled(passage), isTrue, reason: passage);
        }

        // Including the countdown, which no exercise declares by name.
        for (int n = 1; n <= 5; n++) {
          expect(
            File('audio/$lang/common/countdown_$n.m4a').existsSync(),
            isTrue,
            reason: '$lang countdown_$n',
          );
        }

        // And the service resolves them to the pack rather than the fallback.
        // (Playing one here would need a real platform audio player.)
        expect(
          await pack.isBundled('audio/$lang/exercises/ELBOW_001/setup.m4a'),
          isTrue,
        );
        expect(fallback.log, isEmpty);
      });
    }

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
    await tester.tap(find.byTooltip('Меню'));
    await settle();
    await tester.tap(find.text('Голосові команди'));
    await settle();

    expect(find.text('Мінімум голосу'), findsOneWidget);
    expect(find.text('Лічба'), findsOneWidget);
    expect(find.text('Слова руху'), findsOneWidget);

    // The movement words are what a listener who never opens this screen
    // hears (docs/DECISIONS.md 85).
    expect(const AppSettings().voiceMode, VoiceMode.phaseWords);
    expect(store.readSettings().voiceMode, VoiceMode.phaseWords);

    await tester.tap(find.text('Лічба'));
    await settle();
    expect(store.readSettings().voiceMode, VoiceMode.count);

    await tester.tap(find.text('Слова руху'));
    await settle();
    expect(store.readSettings().voiceMode, VoiceMode.phaseWords);

    // Turning the voice off hides the choice: none of the three would change
    // anything while nothing is spoken.
    await tester.tap(find.text('Увімкнено'));
    await settle();
    expect(find.text('Слова руху'), findsNothing);
  });
}

/// The widget tests here all start on one idle exercise screen, reached the
/// way a listener reaches it: body → elbow → the first card.
Future<void> openFirstElbow(
  WidgetTester tester, {
  required AudioService audio,
  AppSettings settings = const AppSettings(localeOverride: 'uk'),
}) async {
  final InMemoryLocalStore store = InMemoryLocalStore();
  await store.writeSettings(settings);

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

  await settleFrames(tester);
  await tester.tap(find.byKey(const ValueKey<String>('hotspot.left_elbow')));
  await tester.pump(const Duration(milliseconds: 400));
  await settleFrames(tester);
  await tester.tap(find.text('Почати').first);
  await settleFrames(tester);
}

/// Pumps without `pumpAndSettle`: the body screen animates forever.
Future<void> settleFrames(WidgetTester tester) async {
  for (int i = 0; i < 8; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}
