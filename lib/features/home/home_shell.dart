/// App shell with the four documented entry points:
/// Тіло / За комп'ютером / У ліжку / Очі (docs/MENU_AND_NAVIGATION.md).
///
/// The player is pushed as a full-screen route, so this navigation bar is not
/// on screen while Previous/Start-Pause/Stop/Next are.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/config/feature_flags.dart';
import '../../core/localization/app_strings.dart';
import '../activity/activity_screen.dart';
import '../body_map/body_map_screen.dart';
import '../exercise_catalog/catalog_screen.dart';
import '../settings/settings_screen.dart';

class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final AppStrings t = AppStrings.of(context);
    final FeatureFlags flags = ref.watch(featureFlagsProvider);

    final List<_Tab> tabs = <_Tab>[
      _Tab(
        labelKey: 'app.nav.body',
        icon: Icons.accessibility_new,
        builder: (BuildContext context) => const BodyMapScreen(),
      ),
      if (flags.isFeatureVisible('computer_module'))
        const _Tab(
          labelKey: 'app.nav.computer',
          icon: Icons.desktop_windows_outlined,
          collectionId: 'computer_break',
        ),
      if (flags.isFeatureVisible('bed_module'))
        const _Tab(
          labelKey: 'app.nav.bed',
          icon: Icons.bed_outlined,
          collectionId: 'bed_basic',
        ),
      if (flags.isFeatureVisible('eyes_module'))
        const _Tab(
          labelKey: 'app.nav.eyes',
          icon: Icons.visibility_outlined,
          collectionId: 'eyes_basic',
        ),
    ];

    final int index = _index.clamp(0, tabs.length - 1);
    final _Tab tab = tabs[index];

    return Scaffold(
      body: Stack(
        children: <Widget>[
          Positioned.fill(
            child: tab.builder != null
                ? tab.builder!(context)
                : SituationScreen(
                    collectionId: tab.collectionId!,
                    titleKey: tab.labelKey,
                  ),
          ),
          Positioned(
            top: 0,
            right: 0,
            child: SafeArea(
              child: Row(
                children: <Widget>[
                  IconButton(
                    tooltip: t('app.activity.title'),
                    icon: const Icon(Icons.insights_outlined),
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (BuildContext context) =>
                            const ActivityScreen(),
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: t('app.settings.title'),
                    icon: const Icon(Icons.settings_outlined),
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (BuildContext context) =>
                            const SettingsScreen(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (int value) => setState(() => _index = value),
        destinations: <Widget>[
          for (final _Tab item in tabs)
            NavigationDestination(
              icon: Icon(item.icon),
              label: t(item.labelKey),
            ),
        ],
      ),
    );
  }
}

class _Tab {
  const _Tab({
    required this.labelKey,
    required this.icon,
    this.collectionId,
    this.builder,
  }) : assert(collectionId != null || builder != null, 'tab needs a target');

  final String labelKey;
  final IconData icon;
  final String? collectionId;
  final WidgetBuilder? builder;
}
