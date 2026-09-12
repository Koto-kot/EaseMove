/// Settings plus the developer menu.
///
/// The developer menu exists only when the build's flags allow it — a
/// production build has no reachable path to it (docs/TECHNICAL_SPEC.md 20).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../core/config/feature_flags.dart';
import '../../core/localization/app_strings.dart';
import '../../core/storage/local_store.dart';
import '../../domain/exercise/exercise.dart';
import '../pro/paywall.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppStrings t = AppStrings.of(context);
    final AppSettings settings = ref.watch(settingsProvider);
    final SettingsController controller = ref.read(settingsProvider.notifier);
    final FeatureFlags flags = ref.watch(featureFlagsProvider);

    // Settings stays dark, like the menu it is reached from: it is chrome,
    // and nothing in it sits on the artwork's white.
    return Theme(
      data: AppTheme.dark(),
      child: Scaffold(
        appBar: AppBar(title: Text(t('app.settings.title'))),
        body: ListView(
          children: <Widget>[
            ListTile(
              leading: const Icon(Icons.workspace_premium_outlined),
              title: Text(t('app.pro.title')),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (BuildContext context) => const ProPlanScreen(),
                ),
              ),
            ),
            const Divider(),
            _SectionHeader(title: t('app.settings.audio')),
            SwitchListTile(
              title: Text(t('app.settings.voice')),
              value: settings.voiceEnabled,
              onChanged: controller.setVoiceEnabled,
            ),
            // How much is said while moving. Hidden when the voice is off,
            // because then none of the three choices changes anything.
            if (settings.voiceEnabled)
              for (final VoiceMode mode in VoiceMode.values)
                _ChoiceOption(
                  label: t('app.settings.voice_mode.${mode.id}'),
                  subtitle: t('app.settings.voice_mode.${mode.id}_hint'),
                  selected: settings.voiceMode == mode,
                  onTap: () => controller.setVoiceMode(mode),
                ),
            SwitchListTile(
              title: Text(t('app.settings.music')),
              value: settings.musicEnabled,
              onChanged: controller.setMusicEnabled,
            ),
            const Divider(),
            _SectionHeader(title: t('app.settings.language')),
            _ChoiceOption(
              label: t('app.settings.language_system'),
              selected: settings.localeOverride == null,
              onTap: () => controller.setLocaleOverride(null),
            ),
            for (final String locale in AppStrings.supportedLocales)
              _ChoiceOption(
                label: locale.toUpperCase(),
                selected: settings.localeOverride == locale,
                onTap: () => controller.setLocaleOverride(locale),
              ),
            const Divider(),
            SwitchListTile(
              title: Text(t('app.settings.reduced_motion')),
              value: settings.reducedMotion,
              onChanged: controller.setReducedMotion,
            ),
            SwitchListTile(
              title: Text(t('app.settings.reminders')),
              value: settings.remindersEnabled,
              onChanged: controller.setReminders,
            ),
            const Divider(),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                t('app.disclaimer'),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            if (flags.developerMenu) ...<Widget>[
              const Divider(),
              _SectionHeader(title: t('app.settings.developer')),
              ListTile(
                dense: true,
                title: Text(t('app.developer.environment')),
                trailing: Text(flags.environment.name),
              ),
              SwitchListTile(
                title: Text(t('app.developer.pro_mode')),
                value: settings.devProOverride,
                onChanged: controller.setDevPro,
              ),
              SwitchListTile(
                title: Text(t('app.developer.show_pending')),
                value: settings.devShowPending,
                onChanged: controller.setDevShowPending,
              ),
              SwitchListTile(
                title: Text(t('app.developer.skip_countdown')),
                value: settings.devSkipCountdowns,
                onChanged: controller.setDevSkipCountdowns,
              ),
              SwitchListTile(
                title: Text(t('app.developer.show_ids')),
                value: settings.devShowIds,
                onChanged: controller.setDevShowIds,
              ),
              ListTile(
                title: Text(t('app.developer.timing_multiplier')),
                subtitle: Slider(
                  value: settings.devTimingMultiplier,
                  min: 0.25,
                  max: 2,
                  divisions: 7,
                  label: '${settings.devTimingMultiplier}×',
                  onChanged: controller.setDevTimingMultiplier,
                ),
              ),
              ListTile(
                title: Text(t('app.developer.reset_stats')),
                trailing: const Icon(Icons.delete_outline),
                onTap: () async {
                  await ref.read(trackingRepositoryProvider).reset();
                  ref.read(activityRevisionProvider.notifier).state++;
                },
              ),
            ],
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

/// Single-choice row. A plain ListTile with a check mark keeps the selection
/// readable at large text sizes and does not depend on radio internals.
class _ChoiceOption extends StatelessWidget {
  const _ChoiceOption({
    required this.label,
    required this.selected,
    required this.onTap,
    this.subtitle,
  });

  final String label;
  final String? subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(label),
      subtitle: subtitle == null ? null : Text(subtitle!),
      trailing: selected ? const Icon(Icons.check) : null,
      selected: selected,
      onTap: onTap,
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Text(
        title,
        style: theme.textTheme.labelLarge?.copyWith(
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }
}
