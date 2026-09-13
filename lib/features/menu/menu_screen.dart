/// Everything that is not an exercise, in one list.
///
/// The menu used to be two entries — activity and settings — and settings
/// itself was a long flat page. Now the menu *is* the page: activity at the
/// top, then one collapsed row per thing you might change, so what you are
/// looking for is one tap away and nothing else is in the way
/// (docs/DECISIONS.md 87).
///
/// The developer section exists only when the build's flags allow it — a
/// production build has no reachable path to it (docs/TECHNICAL_SPEC.md 20).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../core/audio/audio_service.dart';
import '../../core/config/feature_flags.dart';
import '../../core/localization/app_strings.dart';
import '../../core/storage/local_store.dart';
import '../../data/content_bundle.dart';
import '../../domain/exercise/exercise.dart';
import '../activity/activity_screen.dart';
import '../pro/paywall.dart';

class MenuScreen extends ConsumerStatefulWidget {
  const MenuScreen({super.key});

  @override
  ConsumerState<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends ConsumerState<MenuScreen> {
  /// Picking a melody from a list of names is guesswork, so choosing one plays
  /// it. It keeps playing until the listener picks another, turns the music
  /// off or leaves — nothing else on this screen makes a sound.
  ///
  /// Held rather than re-read, because the preview also has to be stopped from
  /// `dispose`, where `ref` is already gone.
  AudioService? _preview;

  void _previewTrack(MusicTrack track, double volume) {
    final AudioService audio = ref.read(audioServiceProvider);
    _preview = audio;
    audio.setMusicVolume(volume);
    // A short fade here rather than the session's: a tap is a question, and
    // the answer should not take two seconds to arrive.
    audio.playMusic(track.id, fadeIn: MusicFade.preview);
  }

  void _stopPreview() {
    final AudioService? audio = _preview;
    if (audio == null) return;
    _preview = null;
    audio.stopAll();
  }

  @override
  void dispose() {
    _stopPreview();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppStrings t = AppStrings.of(context);
    final AppSettings settings = ref.watch(settingsProvider);
    final SettingsController controller = ref.read(settingsProvider.notifier);
    final FeatureFlags flags = ref.watch(featureFlagsProvider);
    final ContentBundle? content = ref.watch(contentBundleProvider).valueOrNull;
    final List<MusicTrack> tracks = content?.music ?? const <MusicTrack>[];
    final MusicTrack? chosen = content?.resolveMusicTrack(
      settings.musicTrackId,
    );

    // The menu stays dark: it is chrome over the white screen, not content.
    return Theme(
      data: AppTheme.dark(),
      child: Scaffold(
        appBar: AppBar(title: Text(t('app.menu.title'))),
        body: ListView(
          children: <Widget>[
            ListTile(
              leading: const Icon(Icons.insights_outlined),
              title: Text(t('app.activity.title')),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (BuildContext context) => const ActivityScreen(),
                ),
              ),
            ),
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

            // Each of these is a switch you can flick without opening it, and
            // a choice you open when you want it.
            _Group(
              icon: Icons.record_voice_over_outlined,
              title: t('app.settings.voice'),
              summary: settings.voiceEnabled
                  ? t('app.settings.voice_mode.${settings.voiceMode.id}')
                  : t('app.common.off'),
              enabled: settings.voiceEnabled,
              onToggle: controller.setVoiceEnabled,
              children: <Widget>[
                if (settings.voiceEnabled)
                  for (final VoiceMode mode in VoiceMode.values)
                    _ChoiceOption(
                      label: t('app.settings.voice_mode.${mode.id}'),
                      subtitle: t('app.settings.voice_mode.${mode.id}_hint'),
                      selected: settings.voiceMode == mode,
                      onTap: () => controller.setVoiceMode(mode),
                    ),
              ],
            ),
            _Group(
              icon: Icons.music_note_outlined,
              title: t('app.settings.music'),
              summary: settings.musicEnabled
                  ? (chosen?.title ?? '')
                  : t('app.common.off'),
              enabled: settings.musicEnabled,
              onToggle: (bool value) {
                if (!value) _stopPreview();
                controller.setMusicEnabled(value);
              },
              children: <Widget>[
                if (settings.musicEnabled) ...<Widget>[
                  // No "tap to hear it" line: tapping a name plays it, which
                  // the first tap teaches better than a sentence does.
                  for (final MusicTrack track in tracks)
                    _ChoiceOption(
                      label: track.title,
                      // The licence asks for the credit to travel with the
                      // music.
                      subtitle: track.attribution,
                      selected: track.id == chosen?.id,
                      onTap: () {
                        controller.setMusicTrack(track.id);
                        _previewTrack(track, settings.musicVolume);
                      },
                    ),
                  ListTile(
                    title: Text(t('app.settings.music_volume')),
                    trailing: Text('${(settings.musicVolume * 100).round()}%'),
                    subtitle: Slider(
                      value: settings.musicVolume,
                      divisions: 20,
                      label: '${(settings.musicVolume * 100).round()}%',
                      onChanged: (double value) {
                        controller.setMusicVolume(value);
                        // A volume slider has to be heard while it moves, so
                        // the preview follows it rather than waiting for a
                        // replay.
                        _preview?.setMusicVolume(value);
                      },
                    ),
                  ),
                ],
              ],
            ),
            _Group(
              icon: Icons.language_outlined,
              title: t('app.settings.language'),
              summary:
                  settings.localeOverride?.toUpperCase() ??
                  t('app.settings.language_system'),
              children: <Widget>[
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
              ],
            ),
            const Divider(),
            SwitchListTile(
              secondary: const Icon(Icons.animation_outlined),
              title: Text(t('app.settings.reduced_motion')),
              value: settings.reducedMotion,
              onChanged: controller.setReducedMotion,
            ),
            SwitchListTile(
              secondary: const Icon(Icons.notifications_none),
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

/// One collapsed row: a name, what it is set to, and — where the group has
/// one — the switch that turns it off without opening it.
class _Group extends StatelessWidget {
  const _Group({
    required this.icon,
    required this.title,
    required this.summary,
    required this.children,
    this.enabled,
    this.onToggle,
  });

  final IconData icon;
  final String title;

  /// What the row says while it is closed, so the setting can be read without
  /// opening it.
  final String summary;
  final List<Widget> children;

  /// `null` for a group with nothing to turn off, such as the language.
  final bool? enabled;
  final ValueChanged<bool>? onToggle;

  @override
  Widget build(BuildContext context) {
    final bool? on = enabled;
    final ValueChanged<bool>? toggle = onToggle;
    return ExpansionTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(summary),
      trailing: on == null || toggle == null
          ? null
          : Switch(value: on, onChanged: toggle),
      childrenPadding: EdgeInsets.zero,
      // No outline of its own: the list is already a list.
      shape: const Border(),
      collapsedShape: const Border(),
      children: children,
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
