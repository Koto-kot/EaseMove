/// The shape of a music fade.
///
/// The ramp is separated from the player precisely so it can be checked here:
/// a test that needs a real audio backend would tell us nothing about whether
/// the music arrives smoothly (docs/DECISIONS.md 83).
library;

import 'package:ease_move/core/audio/volume_fader.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('a ramp', () {
    testWidgets('slides from one level to the other and lands exactly', (
      WidgetTester tester,
    ) async {
      final List<double> levels = <double>[];
      final VolumeFader fader = VolumeFader(
        apply: (double value) async => levels.add(value),
      );

      fader.ramp(from: 0, to: 1, over: const Duration(milliseconds: 500));
      expect(levels, <double>[0], reason: 'it starts where it says it starts');

      await tester.pump(const Duration(milliseconds: 250));
      expect(levels.last, closeTo(0.5, 0.001));
      expect(fader.isFading, isTrue);

      await tester.pump(const Duration(milliseconds: 250));
      expect(levels.last, 1);
      expect(fader.isFading, isFalse);

      for (int i = 1; i < levels.length; i++) {
        expect(
          levels[i],
          greaterThanOrEqualTo(levels[i - 1]),
          reason: 'a fade-in never dips',
        );
      }
      expect(
        levels.length,
        greaterThan(5),
        reason: 'enough steps to be heard as a slide, not as a staircase',
      );
    });

    testWidgets('reaches silence before it says it is done', (
      WidgetTester tester,
    ) async {
      final List<double> levels = <double>[];
      bool done = false;
      final VolumeFader fader = VolumeFader(
        apply: (double value) async => levels.add(value),
      );

      fader.ramp(
        from: 0.4,
        to: 0,
        over: const Duration(seconds: 1),
        onDone: () => done = true,
      );

      await tester.pump(const Duration(milliseconds: 950));
      expect(done, isFalse);
      expect(levels.last, greaterThan(0));

      await tester.pump(const Duration(milliseconds: 50));
      expect(levels.last, 0, reason: 'the player is only stopped in silence');
      expect(done, isTrue);
    });

    testWidgets('bends towards a level moved while it is running', (
      WidgetTester tester,
    ) async {
      final List<double> levels = <double>[];
      final VolumeFader fader = VolumeFader(
        apply: (double value) async => levels.add(value),
      );

      fader.ramp(from: 0, to: 1, over: const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 250));
      fader.target = 0.6;
      await tester.pump(const Duration(milliseconds: 250));

      expect(levels.last, closeTo(0.6, 0.001));
      expect(fader.isFading, isFalse);
    });

    testWidgets('with no time to take, lands at once', (
      WidgetTester tester,
    ) async {
      final List<double> levels = <double>[];
      bool done = false;
      final VolumeFader fader = VolumeFader(
        apply: (double value) async => levels.add(value),
      );

      fader.ramp(
        from: 0,
        to: 0.4,
        over: Duration.zero,
        onDone: () => done = true,
      );

      expect(levels, <double>[0.4]);
      expect(done, isTrue);
      expect(fader.isFading, isFalse);
      await tester.pump();
    });

    testWidgets('cancelled, it stops where it was and stays quiet', (
      WidgetTester tester,
    ) async {
      final List<double> levels = <double>[];
      bool done = false;
      final VolumeFader fader = VolumeFader(
        apply: (double value) async => levels.add(value),
      );

      fader.ramp(
        from: 1,
        to: 0,
        over: const Duration(seconds: 1),
        onDone: () => done = true,
      );
      await tester.pump(const Duration(milliseconds: 200));
      final double interrupted = levels.last;
      fader.cancel();

      // A pending timer would fail the test on its own; the point is that the
      // ramp is really gone, and that a hard stop does not run the callback
      // that belonged to the graceful one.
      await tester.pump(const Duration(seconds: 2));
      expect(levels.last, interrupted);
      expect(done, isFalse);
      expect(fader.isFading, isFalse);
    });
  });

  testWidgets('a level set while nothing is fading applies straight away', (
    WidgetTester tester,
  ) async {
    final List<double> levels = <double>[];
    final VolumeFader fader = VolumeFader(
      apply: (double value) async => levels.add(value),
    );

    fader.target = 0.25;
    expect(levels, <double>[0.25]);
    expect(fader.target, 0.25);
    await tester.pump();
  });
}
