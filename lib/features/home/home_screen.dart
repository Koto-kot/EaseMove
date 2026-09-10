/// The approved home screen: menu and settings, a reserved title block, the
/// interactive body map, and four section cards
/// (docs/ui/home/HOME_SCREEN_LAYOUT_SPEC.md).
///
/// There is no bottom navigation in this MVP, which supersedes the tab shell
/// docs/MENU_AND_NAVIGATION.md describes (docs/DECISIONS.md 46).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/design_tokens.dart';
import '../../app/providers.dart';
import '../../core/localization/app_strings.dart';
import '../../data/content_bundle.dart';
import '../../data/exercise_repository.dart';
import '../activity/activity_screen.dart';
import '../exercise_catalog/catalog_screen.dart';
import '../settings/settings_screen.dart';
import 'widgets/body_map_view.dart';
import 'widgets/home_section_card.dart';
import 'zones_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppStrings t = AppStrings.of(context);
    final AsyncValue<ExerciseRepository> repository = ref.watch(
      exerciseRepositoryProvider,
    );

    return Scaffold(
      drawer: const _HomeDrawer(),
      body: SafeArea(
        child: repository.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (Object error, StackTrace stack) =>
              Center(child: Text(t('app.common.error'))),
          data: (ExerciseRepository repo) => _HomeBody(repo: repo),
        ),
      ),
    );
  }
}

class _HomeBody extends StatelessWidget {
  const _HomeBody({required this.repo});

  final ExerciseRepository repo;

  void _openCatalog(BuildContext context, String collectionId) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext context) =>
            CatalogScreen(collectionId: collectionId),
      ),
    );
  }

  /// A tap on the figure that leads nowhere says so where the finger is,
  /// rather than opening an empty screen the user has to back out of.
  void _openZone(BuildContext context, String collectionId) {
    if (repo.byCollection(collectionId).isEmpty) {
      final AppStrings t = AppStrings.of(context);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(t('app.body_map.zone_empty'))));
      return;
    }
    _openCatalog(context, collectionId);
  }

  /// A card is a named section, so it always opens: an empty one shows the
  /// catalog's own empty state under its own title.
  void _openSection(BuildContext context, HomeSection section) {
    if (section.opensZones) {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (BuildContext context) => const ZonesScreen(),
        ),
      );
      return;
    }
    final String? collectionId = section.targetCollectionId;
    if (collectionId != null) _openCatalog(context, collectionId);
  }

  @override
  Widget build(BuildContext context) {
    final AppStrings t = AppStrings.of(context);
    final ThemeData theme = Theme.of(context);
    final HomeConfig home = repo.bundle.home;
    final Map<String, String> zoneTitles = <String, String>{
      for (final BodyZone zone in repo.bundle.zones) zone.id: zone.shortTitle,
    };

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Tokens.gutter),
      child: Column(
        children: <Widget>[
          _Header(
            title: t(home.titleKey),
            subtitle: t(home.subtitleKey),
            showMenu: home.menuButton,
            showSettings: home.settingsButton,
          ),
          const SizedBox(height: 8),
          // The map takes what is left. When height runs short this shrinks
          // first, before the cards or their text (layout spec, responsive
          // priority).
          Expanded(
            child: BodyMapView(
              config: repo.bundle.bodyMap,
              zoneTitles: zoneTitles,
              onZoneSelected: (BodyHotspot spot) =>
                  _openZone(context, spot.collectionId),
            ),
          ),
          const SizedBox(height: Tokens.gap),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: Tokens.gap,
            crossAxisSpacing: Tokens.gap,
            // An icon, a title and up to three lines of subtitle: English
            // and Polish copy runs longer than the Ukrainian it was drawn
            // with.
            childAspectRatio: 1.2,
            children: <Widget>[
              for (final HomeSection section in home.sections)
                HomeSectionCard(
                  key: ValueKey<String>('home.card.${section.id}'),
                  section: section,
                  title: t(section.titleKey),
                  subtitle: t(section.subtitleKey),
                  onTap: () => _openSection(context, section),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            t('app.disclaimer'),
            textAlign: TextAlign.center,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.outline,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

/// Menu, title block and settings. The text block keeps its space whatever the
/// copy is, so a longer translation does not move the map (brief 3.2).
class _Header extends StatelessWidget {
  const _Header({
    required this.title,
    required this.subtitle,
    required this.showMenu,
    required this.showSettings,
  });

  final String title;
  final String subtitle;
  final bool showMenu;
  final bool showSettings;

  @override
  Widget build(BuildContext context) {
    final AppStrings t = AppStrings.of(context);
    final ThemeData theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (showMenu)
          IconButton(
            tooltip: t('app.home.menu'),
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          )
        else
          const SizedBox(width: Tokens.touchTarget),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Column(
              children: <Widget>[
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (showSettings)
          IconButton(
            tooltip: t('app.settings.title'),
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (BuildContext context) => const SettingsScreen(),
              ),
            ),
          )
        else
          const SizedBox(width: Tokens.touchTarget),
      ],
    );
  }
}

/// What the bottom tabs used to reach. Everything else on this screen is one
/// tap away already, so the drawer stays short.
class _HomeDrawer extends StatelessWidget {
  const _HomeDrawer();

  @override
  Widget build(BuildContext context) {
    final AppStrings t = AppStrings.of(context);
    final ThemeData theme = Theme.of(context);

    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
              child: Text(t('app.name'), style: theme.textTheme.headlineSmall),
            ),
            ListTile(
              leading: const Icon(Icons.insights_outlined),
              title: Text(t('app.activity.title')),
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (BuildContext context) => const ActivityScreen(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings_outlined),
              title: Text(t('app.settings.title')),
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (BuildContext context) => const SettingsScreen(),
                  ),
                );
              },
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                t('app.disclaimer'),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.outline,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
