/// Activity and Settings, reachable from every browse screen.
///
/// They live in each screen's AppBar rather than in a floating overlay, so a
/// long translated title can never collide with them.
library;

import 'package:flutter/material.dart';

import '../../core/localization/app_strings.dart';
import '../activity/activity_screen.dart';
import '../settings/settings_screen.dart';

List<Widget> homeActions(BuildContext context) {
  final AppStrings t = AppStrings.of(context);
  return <Widget>[
    IconButton(
      tooltip: t('app.activity.title'),
      icon: const Icon(Icons.insights_outlined),
      onPressed: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (BuildContext context) => const ActivityScreen(),
        ),
      ),
    ),
    IconButton(
      tooltip: t('app.settings.title'),
      icon: const Icon(Icons.settings_outlined),
      onPressed: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (BuildContext context) => const SettingsScreen(),
        ),
      ),
    ),
  ];
}
