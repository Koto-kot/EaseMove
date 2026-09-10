/// What the "Body" card opens: every body zone that has exercises, in the
/// documented top-to-bottom order.
///
/// The map on the home screen is faster for "it hurts here"; this list is for
/// reading the zone names, which the halo dots deliberately do not show
/// (docs/ui/home/HOME_SCREEN_REPOSITORY_BRIEF.md 4.1).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/design_tokens.dart';
import '../../app/providers.dart';
import '../../core/localization/app_strings.dart';
import '../../data/content_bundle.dart';
import '../../data/exercise_repository.dart';
import '../exercise_catalog/catalog_screen.dart';

class ZonesScreen extends ConsumerWidget {
  const ZonesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppStrings t = AppStrings.of(context);
    final AsyncValue<ExerciseRepository> repository = ref.watch(
      exerciseRepositoryProvider,
    );

    return Scaffold(
      appBar: AppBar(title: Text(t('app.zones.title'))),
      body: repository.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (Object error, StackTrace stack) =>
            Center(child: Text(t('app.common.error'))),
        data: (ExerciseRepository repo) {
          final List<ExerciseCollection> zones = repo.nonEmptyZoneCollections();
          if (zones.isEmpty) {
            return Center(child: Text(t('app.body_map.zone_empty')));
          }
          return ListView.separated(
            padding: const EdgeInsets.symmetric(
              horizontal: Tokens.gutter,
              vertical: Tokens.gap,
            ),
            itemCount: zones.length,
            separatorBuilder: (BuildContext context, int index) =>
                const SizedBox(height: Tokens.gap),
            itemBuilder: (BuildContext context, int index) {
              final ExerciseCollection zone = zones[index];
              final int count = repo.byCollection(zone.id).length;
              return _ZoneTile(
                title: zone.title,
                count: count,
                color: Tokens.zoneColor(
                  zone.primaryZone ?? '',
                  Theme.of(context).colorScheme,
                ),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (BuildContext context) =>
                        CatalogScreen(collectionId: zone.id),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _ZoneTile extends StatelessWidget {
  const _ZoneTile({
    required this.title,
    required this.count,
    required this.color,
    required this.onTap,
  });

  final String title;
  final int count;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final AppStrings t = AppStrings.of(context);
    final ThemeData theme = Theme.of(context);
    final BorderRadius radius = BorderRadius.circular(Tokens.cardRadius);

    // Ukrainian counts three ways, so the noun comes from the pack rather than
    // from a plural suffix glued on in code.
    final String noun = count == 1
        ? t('app.catalog.count_one')
        : count < 5
        ? t('app.catalog.count_few')
        : t('app.catalog.count_many');

    return Material(
      color: theme.colorScheme.surfaceContainerLow,
      borderRadius: radius,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: <Widget>[
              Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(title, style: theme.textTheme.titleMedium),
                    Text(
                      '$count $noun',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
