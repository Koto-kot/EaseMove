/// One player for every exercise. Renders whatever the exercise data
/// describes and never branches on an exercise id
/// (docs/EXERCISE_ENGINE.md, docs/UX_FLOW.md B–G).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/localization/app_strings.dart';
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
    final bool showIds = ref.watch(settingsProvider).devShowIds;

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
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: switch (state.state) {
            SessionState.selected ||
            SessionState.manualBrowseNext ||
            SessionState.browsing => _SelectedView(
              state: state,
              controller: controller,
            ),
            SessionState.stopped => _StoppedView(
              state: state,
              controller: controller,
            ),
            SessionState.autoRest || SessionState.completed => _RestView(
              state: state,
              controller: controller,
            ),
            SessionState.prepCountdown ||
            SessionState.active ||
            SessionState.paused ||
            SessionState.exited => _ActiveView(
              state: state,
              controller: controller,
            ),
          },
        ),
      ),
    );
  }
}

/// SELECTED — the exercise is chosen but never starts on its own.
class _SelectedView extends StatelessWidget {
  const _SelectedView({required this.state, required this.controller});

  final PlayerState state;
  final PlayerController controller;

  @override
  Widget build(BuildContext context) {
    final AppStrings t = AppStrings.of(context);
    final ThemeData theme = Theme.of(context);
    final Exercise exercise = state.exercise!;
    final ExerciseText text = exercise.text;

    // Start stays pinned: the primary action must never require scrolling.
    return Column(
      children: <Widget>[
        Expanded(
          child: ListView(
            padding: const EdgeInsets.only(bottom: 16),
            children: <Widget>[
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
              if (exercise.clinicalStatus != ClinicalStatus.approved)
                _Notice(text: t('app.exercise.pending_review_notice')),
              if (text.purpose != null) ...<Widget>[
                Text(text.purpose!, style: theme.textTheme.bodyLarge),
                const SizedBox(height: 20),
              ],
              if (text.startPosition != null)
                _Section(
                  title: text.startPositionTitle ?? '',
                  child: Text(
                    text.startPosition!,
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
              if (text.instructions.isNotEmpty)
                _Section(
                  title: text.instructionsTitle ?? '',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      for (int i = 0; i < text.instructions.length; i++)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(
                            '${i + 1}. ${text.instructions[i]}',
                            style: theme.textTheme.bodyMedium,
                          ),
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
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(
                            '• $tip',
                            style: theme.textTheme.bodyMedium,
                          ),
                        ),
                    ],
                  ),
                ),
              if (text.safety != null)
                _Section(
                  title: text.safetyLabel ?? '',
                  child: Text(text.safety!, style: theme.textTheme.bodyMedium),
                ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: FilledButton.icon(
            onPressed: controller.start,
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
  const _ActiveView({required this.state, required this.controller});

  final PlayerState state;
  final PlayerController controller;

  @override
  Widget build(BuildContext context) {
    final AppStrings t = AppStrings.of(context);
    final ThemeData theme = Theme.of(context);
    final Exercise exercise = state.exercise!;
    final SessionSnapshot snapshot = state.snapshot;
    final TimelineStep? step = state.currentStep;
    final bool counting = snapshot.isCountingDown;

    final String? frameId = counting
        ? state.timeline?.first.step.frameId ?? state.timeline?.first.frameAt(0)
        : step?.frameAt(snapshot.elapsedMs);
    final ExerciseFrame? frame = frameId == null
        ? null
        : exercise.frames[frameId];

    return Column(
      children: <Widget>[
        Expanded(
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
              if (counting)
                _CountdownOverlay(
                  label: t(StringKeys.startsIn),
                  seconds: snapshot.prepSecondsLeft,
                ),
              if (snapshot.state == SessionState.paused)
                _CountdownOverlay(label: t(StringKeys.pause), seconds: null),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _MetricsRow(state: state),
        if (exercise.progress.showProgressBar) ...<Widget>[
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: state.progress,
              minHeight: 10,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
            ),
          ),
        ],
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
      if (settings.showElapsedTime)
        _Metric(
          label: label('elapsed_time', StringKeys.elapsedTime),
          value: _formatDuration(state.snapshot.elapsedMs),
        ),
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
      children: <Widget>[
        Expanded(
          child: OutlinedButton(
            onPressed: controller.previous,
            child: FittedBox(child: Text(t(StringKeys.previous))),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 2,
          child: FilledButton.icon(
            onPressed: running || paused
                ? controller.pauseOrResume
                : controller.start,
            icon: Icon(running ? Icons.pause : Icons.play_arrow),
            label: FittedBox(
              child: Text(
                running
                    ? t(StringKeys.pause)
                    : paused
                    ? t(StringKeys.resume)
                    : t(StringKeys.start),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        // STOP is accepted in any active state (invariant 1).
        Expanded(
          child: OutlinedButton(
            onPressed: running || paused || resting ? controller.stop : null,
            child: FittedBox(child: Text(t(StringKeys.stop))),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: OutlinedButton(
            onPressed: controller.next,
            child: FittedBox(child: Text(t(StringKeys.next))),
          ),
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
      padding: const EdgeInsets.only(bottom: 20),
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
            const SizedBox(height: 8),
          ],
          child,
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
