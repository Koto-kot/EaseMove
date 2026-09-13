/// The one way into everything that is not an exercise.
///
/// The home screen used to carry a menu and a settings button side by side,
/// and every other screen carried neither — so from a catalogue or a player
/// you had to walk back to the top to change the volume. Now there is one
/// button, it means the same thing everywhere, and it is on every screen
/// (docs/DECISIONS.md 84).
///
/// It opens one list rather than a choice between two: the menu is the page
/// (docs/DECISIONS.md 87).
library;

import 'package:flutter/material.dart';

import '../core/localization/app_strings.dart';
import '../features/menu/menu_screen.dart';

/// Opens the menu.
///
/// On a pushed screen it belongs in `AppBar.actions`: the leading slot is the
/// way back, and taking that away to make room for a menu costs more than it
/// gives.
class AppMenuButton extends StatelessWidget {
  const AppMenuButton({super.key});

  /// Whether the menu is already what you are looking at. The menu's own app
  /// bar leaves the button out rather than offering to open itself.
  static bool isOpen(BuildContext context) =>
      context.findAncestorWidgetOfExactType<MenuScreen>() != null;

  @override
  Widget build(BuildContext context) {
    if (isOpen(context)) return const SizedBox.shrink();
    final AppStrings t = AppStrings.of(context);
    return IconButton(
      tooltip: t('app.common.menu'),
      icon: const Icon(Icons.menu),
      onPressed: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (BuildContext context) => const MenuScreen(),
        ),
      ),
    );
  }
}
