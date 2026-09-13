/// Background music: the catalogue, the choice and the volume
/// (docs/AUDIO_SPEC.md, "Фонова музика").
///
/// The music is third-party work under CC BY, normalised to one loudness by
/// scripts/build_music.py, so the tests here cover both halves of that: the
/// pack on disk matches what the app offers, and what the app offers carries
/// the credit the licence asks for.
library;

import 'dart:io';

import 'package:ease_move/app/app.dart';
import 'package:ease_move/app/providers.dart';
import 'package:ease_move/core/audio/audio_service.dart';
import 'package:ease_move/core/storage/local_store.dart';
import 'package:ease_move/data/content_bundle.dart';
import 'package:ease_move/domain/exercise/session_machine.dart';
import 'package:ease_move/features/exercise_player/player_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/test_assets.dart';

List<MusicTrack> catalogue({String locale = 'uk'}) {
  final Map<String, dynamic> index = loadJsonFromDisk(
    'assets/content/$locale/index.json',
  );
  return <MusicTrack>[
    for (final dynamic track in index['music'] as List<dynamic>)
      MusicTrack.fromJson((track as Map).cast<String, dynamic>()),
  ];
}

Future<void> settle(WidgetTester tester) async {
  for (int i = 0; i < 8; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

void main() {
  group('the pack', () {
    test('four melodies to choose between, each one bundled', () {
      final List<MusicTrack> tracks = catalogue();
      expect(tracks, hasLength(4));

      final String pubspec = File('pubspec.yaml').readAsStringSync();
      expect(
        pubspec,
        contains('- audio/music/'),
        reason: 'a track that is not declared cannot be loaded at runtime',
      );
      for (final MusicTrack track in tracks) {
        final File file = File(track.file);
        expect(file.existsSync(), isTrue, reason: '${track.id}: ${track.file}');
        expect(
          file.lengthSync(),
          greaterThan(100 * 1024),
          reason: '${track.id} is too small to be a melody',
        );
      }
    });

    test('every track names its author and licence', () {
      for (final MusicTrack track in catalogue()) {
        expect(track.attribution, isNotEmpty, reason: track.id);
        expect(
          track.attribution,
          contains('CC BY'),
          reason: '${track.id}: the credit has to name the licence',
        );
        expect(track.licenceUrl, startsWith('https://'), reason: track.id);
      }
    });

    test('the titles are translated, the credit is not', () {
      final List<MusicTrack> uk = catalogue();
      final List<MusicTrack> en = catalogue(locale: 'en');
      expect(
        uk.map((MusicTrack t) => t.id),
        en.map((MusicTrack t) => t.id),
        reason: 'the same tracks in the same order in every language',
      );
      for (int i = 0; i < uk.length; i++) {
        expect(uk[i].title, isNot(en[i].title), reason: uk[i].id);
        // The work and the author are names, and a licence asks for them
        // verbatim.
        expect(uk[i].attribution, en[i].attribution);
      }
    });

    test('not every melody is a piano', () {
      // Asked for directly: a listener who does not want a piano should still
      // have a choice, so at least two tracks are something else.
      final List<MusicTrack> tracks = catalogue(locale: 'en');
      final Iterable<MusicTrack> withoutPiano = tracks.where(
        (MusicTrack track) => !track.title.toLowerCase().contains('piano'),
      );
      expect(withoutPiano.length, greaterThanOrEqualTo(2));
      expect(
        tracks.map((MusicTrack track) => track.id),
        contains('japanese_calm'),
      );
    });

    test('the sources are declared with a free licence and one loudness', () {
      final String raw = File('data/music/tracks.yaml').readAsStringSync();
      expect(raw, contains('integrated_lufs: -20.0'));
      for (final MusicTrack track in catalogue()) {
        expect(raw, contains('id: ${track.id}'));
      }
    });
  });

  group('the choice', () {
    late InMemoryLocalStore store;
    late LoggingAudioService audio;

    Future<void> openSettings(WidgetTester tester) async {
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
      await settle(tester);
      // The menu is the settings list now, and the melodies live in a group
      // that opens on tap (docs/DECISIONS.md 87).
      await tester.tap(find.byTooltip('Меню'));
      await settle(tester);
      await tester.tap(find.text('Фонова музика'));
      await settle(tester);
    }

    setUp(() async {
      store = InMemoryLocalStore();
      audio = LoggingAudioService();
      await store.writeSettings(const AppSettings(localeOverride: 'uk'));
    });

    testWidgets('Settings lists the melodies and plays the one picked', (
      WidgetTester tester,
    ) async {
      await openSettings(tester);
      final List<MusicTrack> tracks = catalogue();

      for (final MusicTrack track in tracks) {
        expect(find.text(track.title), findsWidgets);
        expect(find.text(track.attribution), findsOneWidget);
      }

      // The audio section runs past the fold on a phone.
      await tester.ensureVisible(find.text(tracks[1].title));
      await settle(tester);
      await tester.tap(find.text(tracks[1].title));
      await settle(tester);
      expect(store.readSettings().musicTrackId, tracks[1].id);
      expect(
        audio.log,
        contains('music:${tracks[1].id}'),
        reason: 'picking a melody from a list of names has to be audible',
      );
    });

    testWidgets('the volume is 40% by default and the slider moves it', (
      WidgetTester tester,
    ) async {
      await openSettings(tester);

      expect(store.readSettings().musicVolume, 0.4);

      // The melodies push the volume past the fold on a phone.
      // `.last`: the home screen stays in the tree under Settings, and its
      // scroll view would be found first.
      await tester.scrollUntilVisible(
        find.byType(Slider),
        100,
        scrollable: find.byType(Scrollable).last,
      );
      await settle(tester);
      expect(find.text('40%'), findsOneWidget);
      // Drag the slider to the left: where exactly it lands is the widget's
      // business, the setting moving with it is ours.
      await tester.drag(find.byType(Slider).first, const Offset(-80, 0));
      await settle(tester);

      final double moved = store.readSettings().musicVolume;
      expect(moved, lessThan(0.4));
      expect(find.text('${(moved * 100).round()}%'), findsOneWidget);
    });

    testWidgets('turning the music off takes the melodies with it', (
      WidgetTester tester,
    ) async {
      await openSettings(tester);
      final List<MusicTrack> tracks = catalogue();
      expect(find.text(tracks.last.title), findsOneWidget);

      // The switch on the group's own row, not the row itself: tapping the
      // row would only close the group.
      await tester.tap(
        find.descendant(
          of: find.ancestor(
            of: find.text('Фонова музика'),
            matching: find.byType(ListTile),
          ),
          matching: find.byType(Switch),
        ),
      );
      await settle(tester);

      expect(find.text(tracks.last.title), findsNothing);
      expect(find.byType(Slider), findsNothing);
    });
  });

  group('the session', () {
    testWidgets('starts the chosen track at the chosen volume', (
      WidgetTester tester,
    ) async {
      final List<MusicTrack> tracks = catalogue();
      final InMemoryLocalStore store = InMemoryLocalStore();
      await store.writeSettings(
        AppSettings(
          localeOverride: 'uk',
          devSkipCountdowns: true,
          devTimingMultiplier: 0.1,
          musicTrackId: tracks.last.id,
          musicVolume: 0.15,
        ),
      );
      final LoggingAudioService audio = LoggingAudioService();
      late ProviderContainer container;

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
          child: Consumer(
            builder: (BuildContext context, WidgetRef ref, Widget? child) {
              container = ProviderScope.containerOf(context);
              return const EaseMoveApp();
            },
          ),
        ),
      );
      await settle(tester);
      await tester.tap(find.byKey(const ValueKey<String>('hotspot.left_knee')));
      await tester.pump(const Duration(milliseconds: 400));
      await settle(tester);
      await tester.tap(find.text('Почати').first);
      await settle(tester);
      await tester.tap(find.widgetWithText(FilledButton, 'Старт'));
      await settle(tester);

      expect(
        container
            .read(
              playerControllerProvider((
                exerciseId: 'KNEE_001',
                collectionId: 'body_knees',
              )),
            )
            .state,
        SessionState.active,
      );
      expect(audio.log, contains('music:${tracks.last.id}'));
      expect(
        audio.log,
        contains('musicVolume:0.15'),
        reason: 'the listener sets the level, not the exercise file',
      );
    });

    testWidgets('takes the music away when the movement ends', (
      WidgetTester tester,
    ) async {
      final InMemoryLocalStore store = InMemoryLocalStore();
      await store.writeSettings(
        const AppSettings(
          localeOverride: 'uk',
          devSkipCountdowns: true,
          devTimingMultiplier: 0.05,
        ),
      );
      final LoggingAudioService audio = LoggingAudioService();
      late ProviderContainer container;

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
          child: Consumer(
            builder: (BuildContext context, WidgetRef ref, Widget? child) {
              container = ProviderScope.containerOf(context);
              return const EaseMoveApp();
            },
          ),
        ),
      );
      await settle(tester);
      await tester.tap(find.byKey(const ValueKey<String>('hotspot.left_knee')));
      await tester.pump(const Duration(milliseconds: 400));
      await settle(tester);
      await tester.tap(find.text('Почати').first);
      await settle(tester);
      await tester.tap(find.widgetWithText(FilledButton, 'Старт'));
      await settle(tester);

      SessionState stateNow() => container
          .read(
            playerControllerProvider((
              exerciseId: 'KNEE_001',
              collectionId: 'body_knees',
            )),
          )
          .state;

      // Stopped as soon as the movement is over, so the break and the next
      // exercise's instructions are heard in quiet.
      for (int i = 0; i < 600 && stateNow() == SessionState.active; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }
      expect(stateNow(), isNot(SessionState.active));

      expect(audio.log, contains('musicStop'));
      expect(
        audio.log.indexOf('musicStop'),
        greaterThan(audio.log.indexWhere((String e) => e.startsWith('music:'))),
        reason: 'it is taken away after it was started, not instead',
      );
    });

    testWidgets('a track the build no longer carries falls back to the first', (
      WidgetTester tester,
    ) async {
      final InMemoryLocalStore store = InMemoryLocalStore();
      await store.writeSettings(
        const AppSettings(
          localeOverride: 'uk',
          devSkipCountdowns: true,
          devTimingMultiplier: 0.1,
          musicTrackId: 'a_track_that_was_removed',
        ),
      );
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
      await settle(tester);
      await tester.tap(find.byKey(const ValueKey<String>('hotspot.left_knee')));
      await tester.pump(const Duration(milliseconds: 400));
      await settle(tester);
      await tester.tap(find.text('Почати').first);
      await settle(tester);
      await tester.tap(find.widgetWithText(FilledButton, 'Старт'));
      await settle(tester);

      expect(audio.log, contains('music:${catalogue().first.id}'));
    });
  });
}
