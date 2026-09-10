/// The approved home screen: menu and settings, a reserved title block, the
/// interactive body map, and four section cards
/// (docs/ui/home/HOME_SCREEN_LAYOUT_SPEC.md).
///
/// There is no bottom navigation in this MVP, which supersedes the tab shell
/// docs/MENU_AND_NAVIGATION.md describes (docs/DECISIONS.md 46).
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/design_tokens.dart';
import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../core/localization/app_strings.dart';
import '../../data/content_bundle.dart';
import '../../data/exercise_repository.dart';
import '../activity/activity_screen.dart';
import '../exercise_catalog/catalog_screen.dart';
import '../settings/settings_screen.dart';
import 'widgets/body_map_view.dart';
import 'widgets/home_section_card.dart';
import 'widgets/shrink_to_fit.dart';
import 'zones_screen.dart';

/// The home screen's fixed sizes, public so a layout test can assert them.
abstract final class HomeMetrics {
  /// This is a phone screen. On a wide window it is centred at phone width
  /// rather than stretched: cards sized from their width grew to 740 px tall
  /// in a desktop browser and squeezed the body map out of existence.
  static const double maxContentWidth = 500;

  /// A card is an icon, a title and up to two lines of subtitle, and no
  /// taller than it needs to be: every pixel it gives up goes to the figure.
  /// Fixing its height rather than its aspect ratio is what keeps it that
  /// size at any window width.
  static const double cardHeight = 72;

  /// Below this the column stops shrinking and the screen scrolls, so the
  /// figure never collapses to a sliver.
  static const double minHeight = 560;
}

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppStrings t = AppStrings.of(context);
    final AsyncValue<ExerciseRepository> repository = ref.watch(
      exerciseRepositoryProvider,
    );

    // Every element of this screen sits on one white ground, so the theme is
    // overridden here rather than each widget colouring itself.
    return Theme(
      data: AppTheme.homeLight(),
      child: Scaffold(
        drawer: const _HomeDrawer(),
        body: SafeArea(
          child: repository.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (Object error, StackTrace stack) =>
                Center(child: Text(t('app.common.error'))),
            data: (ExerciseRepository repo) => _HomeBody(repo: repo),
          ),
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
    final HomeConfig home = repo.bundle.home;
    final Map<String, String> zoneTitles = <String, String>{
      for (final BodyZone zone in repo.bundle.zones) zone.id: zone.shortTitle,
    };

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: HomeMetrics.maxContentWidth,
        ),
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            // A definite height, so the map can still take what is left over:
            // the viewport when there is room, the minimum when there is not,
            // and then the page scrolls.
            final double height = math.max(
              constraints.maxHeight,
              HomeMetrics.minHeight,
            );
            return SingleChildScrollView(
              child: SizedBox(
                height: height,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Tokens.gutter,
                  ),
                  child: Column(
                    children: <Widget>[
                      _Header(
                        title: t(home.titleKey),
                        subtitle: home.showSubtitle
                            ? t(home.subtitleKey)
                            : null,
                        showMenu: home.menuButton,
                        showSettings: home.settingsButton,
                      ),
                      const SizedBox(height: 8),
                      // The map takes what is left. When height runs short
                      // this shrinks first, before the cards or their text
                      // (layout spec, responsive priority).
                      Expanded(
                        child: BodyMapView(
                          config: repo.bundle.bodyMap,
                          zoneTitles: zoneTitles,
                          hint: home.hintKey == null ? null : t(home.hintKey!),
                          onZoneSelected: (BodyHotspot spot) =>
                              _openZone(context, spot.collectionId),
                        ),
                      ),
                      const SizedBox(height: Tokens.gap),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        padding: EdgeInsets.zero,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              mainAxisSpacing: Tokens.gap,
                              crossAxisSpacing: Tokens.gap,
                              mainAxisExtent: HomeMetrics.cardHeight,
                            ),
                        itemCount: home.sections.length,
                        itemBuilder: (BuildContext context, int index) {
                          final HomeSection section = home.sections[index];
                          return HomeSectionCard(
                            key: ValueKey<String>('home.card.${section.id}'),
                            section: section,
                            title: t(section.titleKey),
                            subtitle: t(section.subtitleKey),
                            onTap: () => _openSection(context, section),
                          );
                        },
                      ),
                      const SizedBox(height: Tokens.gap),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
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

  /// Null when the config draws the explanatory line under the back figure
  /// instead of in the header.
  final String? subtitle;
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
            padding: const EdgeInsets.only(top: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                // One line that scales down rather than wrapping: at a large
                // system font size the title alone took two lines and pushed
                // the figure down the screen.
                ShrinkToFit(
                  child: Text(
                    title,
                    maxLines: 1,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (subtitle != null) ...<Widget>[
                  const SizedBox(height: 2),
                  ShrinkToFit(
                    child: Text(
                      subtitle!,
                      maxLines: 2,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
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
