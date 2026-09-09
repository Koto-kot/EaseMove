/// Lifetime counter and recent sessions.
///
/// No streaks, no guilt framing: an early stop is shown as a fact, not a
/// failure (docs/TECHNICAL_SPEC.md 16, docs/UX_FLOW.md E).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/localization/app_strings.dart';
import '../../data/content_bundle.dart';
import '../../data/tracking_repository.dart';
import '../../domain/exercise/exercise.dart';
import '../../domain/exercise/session_machine.dart';

class ActivityScreen extends ConsumerWidget {
  const ActivityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppStrings t = AppStrings.of(context);
    final ThemeData theme = Theme.of(context);
    final ActivityStats stats = ref.watch(activityStatsProvider);

    // History stores exercise ids; titles come from the catalog. A retired or
    // renamed exercise falls back to its id rather than vanishing.
    final Map<String, String> titles = ref
        .watch(contentBundleProvider)
        .maybeWhen(
          data: (ContentBundle bundle) => <String, String>{
            for (final ExerciseSummary summary in bundle.exercises)
              summary.id: summary.title,
          },
          orElse: () => const <String, String>{},
        );

    return Scaffold(
      appBar: AppBar(title: Text(t('app.activity.title'))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: <Widget>[
                  Text(
                    t('app.activity.lifetime'),
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${stats.lifetimeCount}',
                    style: theme.textTheme.displayMedium?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(t('app.activity.history'), style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          if (stats.history.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Text(
                t('app.activity.empty'),
                style: theme.textTheme.bodyMedium,
              ),
            )
          else
            for (final SessionResult result in stats.history)
              ListTile(
                leading: Icon(
                  result.completed
                      ? Icons.check_circle_outline
                      : Icons.pause_circle_outline,
                  color: result.completed
                      ? theme.colorScheme.primary
                      : theme.colorScheme.outline,
                ),
                title: Text(titles[result.exerciseId] ?? result.exerciseId),
                subtitle: Text(
                  '${_formatDate(result.startedAt)} · '
                  '${result.actualActiveSeconds} ${t('app.catalog.duration_seconds')} · '
                  '${result.completed ? t('app.activity.completed') : t('app.activity.early_stop')}',
                ),
                trailing: result.completedRepetitions > 0
                    ? Text('${result.completedRepetitions}×')
                    : null,
              ),
        ],
      ),
    );
  }

  static String _formatDate(DateTime value) {
    final String day = value.day.toString().padLeft(2, '0');
    final String month = value.month.toString().padLeft(2, '0');
    final String hour = value.hour.toString().padLeft(2, '0');
    final String minute = value.minute.toString().padLeft(2, '0');
    return '$day.$month $hour:$minute';
  }
}
