/// Large exercise card: roughly three fit a viewport, then vertical scroll
/// (docs/MVP_SCOPE.md, docs/UX_FLOW.md A).
library;

import 'package:flutter/material.dart';

import '../../core/localization/app_strings.dart';
import '../../domain/exercise/exercise.dart';
import 'asset_placeholder.dart';
import 'pro_badge.dart';

class ExerciseCard extends StatelessWidget {
  const ExerciseCard({
    required this.summary,
    required this.onStart,
    required this.showId,
    super.key,
  });

  final ExerciseSummary summary;
  final VoidCallback onStart;
  final bool showId;

  @override
  Widget build(BuildContext context) {
    final AppStrings t = AppStrings.of(context);
    final ThemeData theme = Theme.of(context);

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onStart,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              SizedBox(
                width: 96,
                height: 96,
                child: AssetImageOrPlaceholder(
                  assetPath: summary.previewAsset,
                  placeholderLabel: t('app.exercise.frame_missing'),
                  semanticLabel: summary.title,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            summary.title,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if (summary.requiresPro) const ProBadge(),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      summary.cardDescription,
                      style: theme.textTheme.bodyMedium,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: <Widget>[
                        _DurationChip(seconds: summary.estimatedActiveSeconds),
                        if (summary.clinicalStatus != ClinicalStatus.approved)
                          Tooltip(
                            message: t('app.exercise.pending_review_notice'),
                            child: Icon(
                              Icons.info_outline,
                              size: 18,
                              color: theme.colorScheme.tertiary,
                            ),
                          ),
                        if (showId)
                          Text(summary.id, style: theme.textTheme.labelSmall),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: onStart,
                        child: Text(t(StringKeys.exerciseStart)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DurationChip extends StatelessWidget {
  const _DurationChip({required this.seconds});

  final int seconds;

  @override
  Widget build(BuildContext context) {
    final AppStrings t = AppStrings.of(context);
    final String label = seconds >= 60
        ? '${(seconds / 60).round()} ${t('app.catalog.duration_minutes')}'
        : '$seconds ${t('app.catalog.duration_seconds')}';
    return Chip(
      visualDensity: VisualDensity.compact,
      avatar: const Icon(Icons.schedule, size: 16),
      label: Text(label),
    );
  }
}
