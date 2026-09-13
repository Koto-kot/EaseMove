/// The one way into everything that is not an exercise.
///
/// The home screen used to carry a menu and a settings button side by side,
/// and every other screen carried neither — so from a catalogue or a player
/// you had to walk back to the top to change the volume. Now there is one
/// button, it means the same thing everywhere, and it is on every screen
/// (docs/DECISIONS.md 84).
library;

import 'package:flutter/material.dart';

import '../core/localization/app_strings.dart';
import '../features/activity/activity_screen.dart';
import '../features/settings/settings_screen.dart';
import 'theme.dart';

/// A screen the menu leads to, so the menu can mark the one you are already
/// on instead of stacking a second copy of it.
enum AppMenuTarget { activity, settings }

/// Opens the [AppDrawer] of the surrounding Scaffold.
///
/// On a pushed screen it belongs in `AppBar.actions`: the leading slot is the
/// way back, and taking that away to make room for a menu costs more than it
/// gives.
class AppMenuButton extends StatelessWidget {
  const AppMenuButton({super.key});

  @override
  Widget build(BuildContext context) {
    final AppStrings t = AppStrings.of(context);
    return IconButton(
      tooltip: t('app.common.menu'),
      icon: const Icon(Icons.menu),
      onPressed: () => Scaffold.of(context).openDrawer(),
    );
  }
}

/// What the bottom tabs used to reach. Everything else is one tap away from
/// the home screen already, so the menu stays short.
class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key, this.current});

  /// The screen this drawer is being opened from, when the menu leads there.
  final AppMenuTarget? current;

  void _open(
    BuildContext context,
    AppMenuTarget target,
    WidgetBuilder builder,
  ) {
    Navigator.of(context).pop();
    // Tapping where you already are closes the menu and nothing more.
    if (target == current) return;
    Navigator.of(context).push(MaterialPageRoute<void>(builder: builder));
  }

  @override
  Widget build(BuildContext context) {
    final AppStrings t = AppStrings.of(context);
    final ThemeData theme = AppTheme.dark();

    // The menu stays dark: it is chrome over the white screen, not content.
    return Theme(
      data: theme,
      child: Drawer(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                child: Text(
                  t('app.name'),
                  style: theme.textTheme.headlineSmall,
                ),
              ),
              ListTile(
                leading: const Icon(Icons.insights_outlined),
                title: Text(t('app.activity.title')),
                selected: current == AppMenuTarget.activity,
                onTap: () => _open(
                  context,
                  AppMenuTarget.activity,
                  (BuildContext context) => const ActivityScreen(),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.settings_outlined),
                title: Text(t('app.settings.title')),
                selected: current == AppMenuTarget.settings,
                onTap: () => _open(
                  context,
                  AppMenuTarget.settings,
                  (BuildContext context) => const SettingsScreen(),
                ),
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
      ),
    );
  }
}
