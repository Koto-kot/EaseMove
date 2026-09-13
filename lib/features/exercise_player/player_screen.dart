/// One player for every exercise. Renders whatever the exercise data
/// describes and never branches on an exercise id
/// (docs/EXERCISE_ENGINE.md, docs/UX_FLOW.md B–G).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/design_tokens.dart';
import '../../app/providers.dart';
import '../../core/localization/app_strings.dart';
import '../../core/storage/local_store.dart';
import '../../data/exercise_repository.dart';
import '../../data/tracking_repository.dart';
import '../../domain/exercise/exercise.dart';
import '../../domain/exercise/exercise_timeline.dart';
import '../../domain/exercise/session_machine.dart';
import '../../shared/widgets/asset_placeholder.dart';
import 'player_controller.dart';

class PlayerScreen extends ConsumerStatefulWidget {
  const PlayerScreen({required this.exerciseId, this.collectionId, super.key});

  final String exerciseId;
  final String? collectionId;

  @override
  ConsumerState<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends ConsumerState<PlayerScreen> {
  late final PlayerArgs _args = (
    exerciseId: widget.exerciseId,
    collectionId: widget.collectionId,
  );
  late final PlayerController _controller = ref.read(
    playerControllerProvider(_args).notifier,
  );

  @override
  void dispose() {
    // Leaving the flow stops autoplay, clears timers and saves whatever the
    // attempt earned (docs/UX_FLOW.md H).
    _controller.finalizeSession();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final PlayerArgs args = _args;
    final PlayerState state = ref.watch(playerControllerProvider(args));
    final PlayerController controller = _controller;
    final AppStrings t = AppStrings.of(context);
    final AppSettings settings = ref.watch(settingsProvider);
    final bool showIds = settings.devShowIds;

    if (state.loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final Exercise? exercise = state.exercise;
    if (exercise == null || state.error != null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(child: Text(t('app.common.error'))),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(exercise.text.title),
        actions: <Widget>[
          if (showIds)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(child: Text(exercise.id)),
            ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: switch (state.state) {
            SessionState.selected ||
            SessionState.manualBrowseNext ||
            SessionState.browsing => _SelectedView(
              state: state,
              controller: controller,
              voiceEnabled: settings.voiceEnabled,
            ),
            SessionState.stopped => _StoppedView(
              state: state,
              controller: controller,
            ),
            SessionState.autoRest => _RestView(
              state: state,
              controller: controller,
            ),
            SessionState.completed => _CompletedView(state: state),
            SessionState.prepCountdown ||
            SessionState.active ||
            SessionState.paused ||
            SessionState.exited => _ActiveView(
              state: state,
              controller: controller,
              reducedMotion: settings.reducedMotion,
            ),
          },
        ),
      ),
    );
  }
}

/// SELECTED — the exercise is chosen but never starts on its own.
class _SelectedView extends StatefulWidget {
  const _SelectedView({
    required this.state,
    required this.controller,
    required this.voiceEnabled,
  });

  final PlayerState state;
  final PlayerController controller;

  /// A voice turned off in Settings makes "listen" a dead button, so it is not
  /// offered at all and reading takes the whole row.
  final bool voiceEnabled;

  @override
  State<_SelectedView> createState() => _SelectedViewState();
}

class _SelectedViewState extends State<_SelectedView> {
  /// The steps are the instruction, and the instruction is shown the way the
  /// listener asked for it — aloud or on the page, never both and never
  /// unasked (docs/DECISIONS.md 69).
  bool _reading = false;

  /// A reading was asked for, so the same button offers to cut it short.
  ///
  /// Cues are spoken and forgotten — the voice is told to let a later cue cut
  /// in rather than queue behind this one (docs/AUDIO_SPEC.md, collision
  /// policy) — so nothing reports back when a reading ends. The offer to stop
  /// therefore stands until the listener takes it, reads instead, or starts.
  bool _speaking = false;

  void _listen() {
    if (_speaking) {
      _stopSpeaking();
      return;
    }
    widget.controller.speakInstructions();
    setState(() {
      _reading = false;
      _speaking = true;
    });
  }

  void _stopSpeaking() {
    widget.controller.stopSpeaking();
    setState(() => _speaking = false);
  }

  void _read() {
    if (_speaking) _stopSpeaking();
    setState(() => _reading = !_reading);
  }

  @override
  Widget build(BuildContext context) {
    final AppStrings t = AppStrings.of(context);
    final ThemeData theme = Theme.of(context);
    final Exercise exercise = widget.state.exercise!;
    final ExerciseText text = exercise.text;
    final bool canListen =
        widget.voiceEnabled && text.spokenInstructions.isNotEmpty;
    final bool canRead =
        text.startPosition != null ||
        text.instructions.isNotEmpty ||
        text.techniqueTips.isNotEmpty ||
        text.safety != null;

    // One size and one rhythm for everything that is read rather than
    // glanced at. The instruction is the longest text in the app and it is
    // read on a phone, so it gets the body size with a line height that
    // leaves the lines apart (docs/DECISIONS.md 79).
    final TextStyle? reading = theme.textTheme.bodyLarge?.copyWith(height: 1.5);

    // Start stays pinned: the primary action must never require scrolling.
    return Column(
      children: <Widget>[
        Expanded(
          child: ListView(
            padding: const EdgeInsets.only(bottom: 16),
            children: <Widget>[
              // The model steps aside while the text is being read: the two
              // together left the instruction squeezed into what was left of
              // the screen (docs/DECISIONS.md 69).
              if (!_reading) ...<Widget>[
                AspectRatio(
                  aspectRatio: 1,
                  child: AssetImageOrPlaceholder(
                    assetPath: exercise.previewAsset,
                    placeholderLabel: t('app.exercise.frame_missing'),
                    semanticLabel: exercise.accessibilitySummary ?? text.title,
                    caption: text.startPosition,
                  ),
                ),
                const SizedBox(height: 16),
              ],
              if (exercise.clinicalStatus != ClinicalStatus.approved)
                _Notice(text: t('app.exercise.pending_review_notice')),
              if (text.purpose != null) ...<Widget>[
                Text(text.purpose!, style: reading),
                const SizedBox(height: 20),
              ],
              // The instruction is on the page only while it is being read.
              if (_reading) ...<Widget>[
                if (text.startPosition != null)
                  _Section(
                    title: text.startPositionTitle ?? '',
                    child: Text(text.startPosition!, style: reading),
                  ),
                if (text.instructions.isNotEmpty)
                  _Section(
                    title: text.instructionsTitle ?? '',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        for (int i = 0; i < text.instructions.length; i++)
                          _ListItem(
                            marker: '${i + 1}.',
                            text: text.instructions[i],
                            style: reading,
                          ),
                      ],
                    ),
                  ),
                if (text.techniqueTips.isNotEmpty)
                  _Section(
                    title: text.techniqueTipsTitle ?? '',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        for (final String tip in text.techniqueTips)
                          _ListItem(marker: '•', text: tip, style: reading),
                      ],
                    ),
                  ),
                if (text.safety != null)
                  _Section(
                    title: text.safetyLabel ?? '',
                    child: Text(text.safety!, style: reading),
                  ),
              ],
            ],
          ),
        ),
        // Two ways to take the instruction in, offered side by side. Listening
        // happens here rather than over the movement: the steps take far
        // longer to say than a cue and would collide with the rhythm words
        // (docs/AUDIO_SPEC.md, collision policy).
        if (canListen || canRead)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: <Widget>[
                if (canListen)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _listen,
                      icon: Icon(
                        _speaking
                            ? Icons.stop_outlined
                            : Icons.volume_up_outlined,
                      ),
                      label: Text(
                        _speaking
                            ? t('app.exercise.stop_listening')
                            : t('app.exercise.listen_instructions'),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                if (canListen && canRead) const SizedBox(width: 12),
                if (canRead)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _read,
                      icon: Icon(
                        _reading ? Icons.expand_less : Icons.article_outlined,
                      ),
                      label: Text(
                        _reading
                            ? t('app.exercise.hide_instructions')
                            : t('app.exercise.read_instructions'),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: FilledButton.icon(
            onPressed: () {
              widget.controller.stopSpeaking();
              widget.controller.start();
            },
            icon: const Icon(Icons.play_arrow),
            label: Text(t(StringKeys.start)),
          ),
        ),
      ],
    );
  }
}

/// PREP_COUNTDOWN / ACTIVE / PAUSED.
class _ActiveView extends StatelessWidget {
  const _ActiveView({
    required this.state,
    required this.controller,
    required this.reducedMotion,
  });

  final PlayerState state;
  final PlayerController controller;

  /// When on, each step shows one static key pose instead of walking through
  /// the transition's frames.
  final bool reducedMotion;

  @override
  Widget build(BuildContext context) {
    final AppStrings t = AppStrings.of(context);
    final ThemeData theme = Theme.of(context);
    final Exercise exercise = state.exercise!;
    final SessionSnapshot snapshot = state.snapshot;
    final TimelineStep? step = state.currentStep;
    // The start pose and the number both hold for the whole of
    // PREP_COUNTDOWN: the spoken lines first, with five already lit, and then
    // the ticking (docs/UX_FLOW.md B).
    final bool beforeMovement = snapshot.state == SessionState.prepCountdown;

    final String? frameId = beforeMovement
        ? state.timeline?.first.keyFrameId
        : reducedMotion
        ? step?.keyFrameId
        : step?.frameAt(snapshot.elapsedMs);
    final ExerciseFrame? frame = frameId == null
        ? null
        : exercise.frames[frameId];

    final Color zoneTint = Tokens.zoneColor(
      exercise.primaryZone,
      theme.colorScheme,
    );

    return Column(
      children: <Widget>[
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(Tokens.cardRadius),
            child: Stack(
              alignment: Alignment.center,
              children: <Widget>[
                Positioned.fill(
                  child: AssetImageOrPlaceholder(
                    assetPath: frame?.file,
                    placeholderLabel: t('app.exercise.frame_missing'),
                    semanticLabel: frame?.altText,
                    caption: frame?.altText,
                  ),
                ),
                // Which part is doing the work, in that zone's colour — the
                // same colour its dot had on the body map.
                Positioned(
                  top: Tokens.gap,
                  left: Tokens.gap,
                  child: _ZoneChip(
                    label:
                        '${t('app.exercise.working_zone')} · '
                        '${t(StringKeys.bodyZone(exercise.primaryZone))}',
                    color: zoneTint,
                  ),
                ),
                if (beforeMovement)
                  _CountdownOverlay(
                    label: t(StringKeys.startsIn),
                    seconds: snapshot.prepSecondsLeft,
                  ),
                if (snapshot.state == SessionState.paused)
                  _CountdownOverlay(label: t(StringKeys.pause), seconds: null),
              ],
            ),
          ),
        ),
        const SizedBox(height: Tokens.gap),
        // The clock is the one number you glance at while moving, so it is
        // the largest thing on the screen and no longer one metric among
        // four.
        if (exercise.progress.showElapsedTime)
          _BigTimer(
            label: exercise.labels['elapsed_time'] ?? t(StringKeys.elapsedTime),
            value: _MetricsRow._formatDuration(snapshot.elapsedMs),
          ),
        if (exercise.progress.showProgressBar) ...<Widget>[
          const SizedBox(height: Tokens.gap),
          ClipRRect(
            borderRadius: BorderRadius.circular(Tokens.chipRadius),
            child: LinearProgressIndicator(
              value: state.progress,
              minHeight: 10,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              color: zoneTint,
            ),
          ),
        ],
        const SizedBox(height: Tokens.gap),
        _MetricsRow(state: state),
        const SizedBox(height: 16),
        _Controls(state: state, controller: controller),
        const SizedBox(height: 16),
      ],
    );
  }
}

/// COMPLETED → AUTO_REST: full rest, next exercise already visible, no skip.
class _RestView extends StatelessWidget {
  const _RestView({required this.state, required this.controller});

  final PlayerState state;
  final PlayerController controller;

  @override
  Widget build(BuildContext context) {
    final AppStrings t = AppStrings.of(context);
    final ThemeData theme = Theme.of(context);
    final ExerciseSummary? next = state.nextSummary;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Icon(Icons.check_circle, size: 72, color: theme.colorScheme.primary),
        const SizedBox(height: 12),
        Text(
          state.exercise?.text.completion ?? t('app.exercise.completed_title'),
          style: theme.textTheme.headlineSmall,
        ),
        const SizedBox(height: 4),
        Text(
          '+1',
          style: theme.textTheme.titleLarge?.copyWith(
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: 32),
        Text(t(StringKeys.rest), style: theme.textTheme.titleMedium),
        Text(
          '${state.snapshot.restSecondsLeft}',
          style: theme.textTheme.displayMedium?.copyWith(
            fontWeight: FontWeight.w300,
          ),
        ),
        const SizedBox(height: 32),
        if (next != null) ...<Widget>[
          Text(t(StringKeys.nextExercise), style: theme.textTheme.labelLarge),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: <Widget>[
                  SizedBox(
                    width: 64,
                    height: 64,
                    child: AssetImageOrPlaceholder(
                      assetPath: next.previewAsset,
                      placeholderLabel: t('app.exercise.frame_missing'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(next.title, style: theme.textTheme.titleMedium),
                  ),
                ],
              ),
            ),
          ),
        ] else
          Text(t('app.exercise.no_next'), style: theme.textTheme.bodyMedium),
        const Spacer(),
        // Previous/Next here cancel autoplay (docs/UX_FLOW.md G).
        // No "start now" or "skip rest" control: rest is part of the exercise.
        _Controls(state: state, controller: controller),
        const SizedBox(height: 16),
      ],
    );
  }
}

/// STOPPED — never presented as a failure (docs/UX_FLOW.md E).
class _StoppedView extends StatelessWidget {
  const _StoppedView({required this.state, required this.controller});

  final PlayerState state;
  final PlayerController controller;

  @override
  Widget build(BuildContext context) {
    final AppStrings t = AppStrings.of(context);
    final ThemeData theme = Theme.of(context);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Icon(
          Icons.pause_circle_outline,
          size: 64,
          color: theme.colorScheme.outline,
        ),
        const SizedBox(height: 12),
        Text(
          t('app.exercise.stopped_title'),
          style: theme.textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        Text(
          t('app.exercise.stopped_note'),
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 32),
        FilledButton.icon(
          onPressed: controller.start,
          icon: const Icon(Icons.play_arrow),
          label: Text(t(StringKeys.start)),
        ),
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed: () => Navigator.of(context).maybePop(),
          child: Text(t('app.common.back')),
        ),
      ],
    );
  }
}

class _MetricsRow extends StatelessWidget {
  const _MetricsRow({required this.state});

  final PlayerState state;

  @override
  Widget build(BuildContext context) {
    final AppStrings t = AppStrings.of(context);
    final Exercise exercise = state.exercise!;
    final ProgressSettings settings = exercise.progress;
    final TimelineStep? step = state.currentStep;

    // An exercise may rename a label — KNEE_001 calls the side "Нога" — so the
    // exercise's own `ui` block wins over the shared localization key.
    String label(String name, String key) => exercise.labels[name] ?? t(key);

    final List<Widget> metrics = <Widget>[
      if (settings.showRepetitionCounter)
        _Metric(
          label: label('repetition', StringKeys.repetition),
          value:
              '${state.completedRepetitionsInBlock + 1} '
              '${t('app.exercise.of_total')} ${step?.repetitionsInBlock ?? 0}',
        ),
      if (settings.showSideLabel && step?.effectiveSide != null)
        _Metric(
          label: label('side', StringKeys.side),
          value: _sideLabel(t, step!.effectiveSide!),
        ),
      if (!settings.showRepetitionCounter && !settings.showSideLabel)
        _Metric(
          label: label('progress', StringKeys.progress),
          value: '${(state.progress * 100).round()}%',
        ),
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: metrics,
    );
  }

  static String _sideLabel(AppStrings t, BodySide side) =>
      t(side == BodySide.left ? StringKeys.sideLeft : StringKeys.sideRight);

  static String _formatDuration(int milliseconds) {
    final int totalSeconds = milliseconds ~/ 1000;
    final String minutes = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final String seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Column(
      children: <Widget>[
        Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.outline,
          ),
        ),
        const SizedBox(height: 2),
        Text(value, style: theme.textTheme.titleLarge),
      ],
    );
  }
}

/// Previous / Start-Pause / Stop / Next. The app's bottom navigation is hidden
/// while these are on screen (docs/MENU_AND_NAVIGATION.md).
class _Controls extends StatelessWidget {
  const _Controls({required this.state, required this.controller});

  final PlayerState state;
  final PlayerController controller;

  @override
  Widget build(BuildContext context) {
    final AppStrings t = AppStrings.of(context);
    final SessionState sessionState = state.snapshot.state;
    final bool paused = sessionState == SessionState.paused;
    final bool running =
        sessionState == SessionState.active ||
        sessionState == SessionState.prepCountdown;
    final bool resting = sessionState == SessionState.autoRest;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: <Widget>[
        _RoundControl(
          icon: Icons.skip_previous,
          label: t(StringKeys.previous),
          onPressed: controller.previous,
        ),
        _RoundControl(
          icon: running ? Icons.pause : Icons.play_arrow,
          label: running
              ? t(StringKeys.pause)
              : paused
              ? t(StringKeys.resume)
              : t(StringKeys.start),
          onPressed: running || paused
              ? controller.pauseOrResume
              : controller.start,
          primary: true,
        ),
        // STOP is accepted in any active state (invariant 1).
        _RoundControl(
          icon: Icons.stop,
          label: t(StringKeys.stop),
          onPressed: running || paused || resting ? controller.stop : null,
        ),
        _RoundControl(
          icon: Icons.skip_next,
          label: t(StringKeys.next),
          onPressed: controller.next,
        ),
      ],
    );
  }
}

class _CountdownOverlay extends StatelessWidget {
  const _CountdownOverlay({required this.label, required this.seconds});

  final String label;
  final int? seconds;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(label, style: theme.textTheme.titleMedium),
          if (seconds != null)
            Text(
              '$seconds',
              style: theme.textTheme.displayLarge?.copyWith(
                fontWeight: FontWeight.w300,
              ),
            ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (title.isNotEmpty) ...<Widget>[
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
          ],
          child,
        ],
      ),
    );
  }
}

/// A numbered step or a bullet, with the marker in its own column.
///
/// A wrapped line then starts under the text rather than under the number,
/// which is what makes a list of steps scannable on a narrow screen.
class _ListItem extends StatelessWidget {
  const _ListItem({
    required this.marker,
    required this.text,
    required this.style,
  });

  final String marker;
  final String text;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(width: 26, child: Text(marker, style: style)),
          Expanded(child: Text(text, style: style)),
        ],
      ),
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.tertiaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: <Widget>[
          Icon(
            Icons.info_outline,
            color: theme.colorScheme.onTertiaryContainer,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onTertiaryContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A circular control with its name underneath. The name is also the tooltip,
/// so the button stays identifiable to a screen reader and in tests.
class _RoundControl extends StatelessWidget {
  const _RoundControl({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.primary = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  /// Start/Pause is the one control you press without looking, so it is
  /// filled and half again as large as the others.
  final bool primary;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final double diameter = primary ? 72 : Tokens.touchTarget;
    final ButtonStyle style = ButtonStyle(
      shape: const WidgetStatePropertyAll<OutlinedBorder>(CircleBorder()),
      padding: const WidgetStatePropertyAll<EdgeInsets>(EdgeInsets.zero),
      minimumSize: WidgetStatePropertyAll<Size>(Size(diameter, diameter)),
      fixedSize: WidgetStatePropertyAll<Size>(Size(diameter, diameter)),
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Tooltip(
          message: label,
          child: primary
              ? FilledButton(
                  onPressed: onPressed,
                  style: style,
                  child: Icon(icon, size: 32),
                )
              : OutlinedButton(
                  onPressed: onPressed,
                  style: style,
                  child: Icon(icon, size: 22),
                ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.outline,
          ),
        ),
      ],
    );
  }
}

/// The elapsed clock, sized to be read at arm's length mid-exercise.
class _BigTimer extends StatelessWidget {
  const _BigTimer({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Column(
      children: <Widget>[
        Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.outline,
          ),
        ),
        Text(
          value,
          style: theme.textTheme.displayMedium?.copyWith(
            fontWeight: FontWeight.w300,
            // Fixed-width digits: the clock must not jitter as it ticks.
            fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}

class _ZoneChip extends StatelessWidget {
  const _ZoneChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(Tokens.chipRadius),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(label, style: theme.textTheme.labelLarge),
        ],
      ),
    );
  }
}

/// COMPLETED with nothing queued behind it: the end of the flow, so it earns
/// a screen of its own rather than a rest countdown (docs/UX_FLOW.md F).
class _CompletedView extends ConsumerWidget {
  const _CompletedView({required this.state});

  final PlayerState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppStrings t = AppStrings.of(context);
    final ThemeData theme = Theme.of(context);
    final Exercise exercise = state.exercise!;
    final String zoneId = exercise.primaryZone;
    final Color zoneTint = Tokens.zoneColor(zoneId, theme.colorScheme);
    final ActivityStats stats = ref.watch(activityStatsProvider);
    final ExerciseRepository? repository = ref
        .watch(exerciseRepositoryProvider)
        .valueOrNull;

    // What else this zone offers. byZone already applies the clinical gate,
    // so a pending exercise cannot appear here in production.
    final List<ExerciseSummary> siblings = <ExerciseSummary>[
      if (repository != null)
        for (final ExerciseSummary summary in repository.byZone(zoneId))
          if (summary.id != exercise.id) summary,
    ];

    return ListView(
      padding: const EdgeInsets.only(top: 24, bottom: 24),
      children: <Widget>[
        Center(
          child: Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: zoneTint.withValues(alpha: 0.16),
            ),
            child: Icon(Icons.check_rounded, size: 52, color: zoneTint),
          ),
        ),
        const SizedBox(height: Tokens.gap),
        Text(
          exercise.text.completion ?? t('app.exercise.completed_title'),
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 24),
        Row(
          children: <Widget>[
            Expanded(
              child: _StatCard(
                label: t(StringKeys.elapsedTime),
                value: _MetricsRow._formatDuration(state.snapshot.elapsedMs),
              ),
            ),
            const SizedBox(width: Tokens.gap),
            Expanded(
              child: _StatCard(
                label: t('app.activity.lifetime'),
                value: '${stats.lifetimeCount}',
                delta: '+1',
              ),
            ),
          ],
        ),
        if (siblings.isNotEmpty) ...<Widget>[
          const SizedBox(height: 28),
          Text(
            '${t('app.exercise.more_in_zone')} · '
            '${t(StringKeys.bodyZone(zoneId))}',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: Tokens.gap),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: Tokens.gap,
            crossAxisSpacing: Tokens.gap,
            childAspectRatio: 0.82,
            children: <Widget>[
              for (final ExerciseSummary summary in siblings)
                _SiblingCard(summary: summary),
            ],
          ),
        ],
        const SizedBox(height: 28),
        FilledButton(
          // Back to where the flow began, not one screen back: the exercise
          // is finished and there is nothing to return to.
          onPressed: () =>
              Navigator.of(context).popUntil((Route<void> r) => r.isFirst),
          child: Text(t('app.exercise.back_to_body')),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value, this.delta});

  final String label;
  final String value;

  /// What this session added, shown next to the running total.
  final String? delta;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(Tokens.cardRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: <Widget>[
              Text(
                value,
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (delta != null) ...<Widget>[
                const SizedBox(width: 6),
                Text(
                  delta!,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _SiblingCard extends StatelessWidget {
  const _SiblingCard({required this.summary});

  final ExerciseSummary summary;

  @override
  Widget build(BuildContext context) {
    final AppStrings t = AppStrings.of(context);
    final ThemeData theme = Theme.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(Tokens.cardRadius),
      // Replaces the finished exercise instead of stacking on it, so Back
      // never walks through completed sessions.
      onTap: () => Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (BuildContext context) =>
              PlayerScreen(exerciseId: summary.id),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(Tokens.cardRadius),
              child: AssetImageOrPlaceholder(
                assetPath: summary.previewAsset,
                placeholderLabel: t('app.exercise.frame_missing'),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            summary.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}
