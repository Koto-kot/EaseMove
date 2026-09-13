/// Who made what the app plays.
///
/// The melodies are third-party work under CC BY, which asks for the author to
/// be named wherever the work is used. The credit used to sit under every
/// melody in the menu, where it was four lines of small print in the middle of
/// a choice; it lives here instead, so choosing a melody stays a choice and
/// the licence is still honoured (docs/DECISIONS.md 92).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../core/localization/app_strings.dart';
import '../../data/content_bundle.dart';

class AboutScreen extends ConsumerWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppStrings t = AppStrings.of(context);
    final ThemeData theme = AppTheme.dark();
    final ContentBundle? content = ref.watch(contentBundleProvider).valueOrNull;
    final List<MusicTrack> tracks = content?.music ?? const <MusicTrack>[];

    return Theme(
      data: theme,
      child: Scaffold(
        appBar: AppBar(title: Text(t('app.about.title'))),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: <Widget>[
            Text(t('app.name'), style: theme.textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(t('app.disclaimer'), style: theme.textTheme.bodyMedium),
            const SizedBox(height: 28),
            Text(
              t('app.about.music'),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              t('app.about.music_note'),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            for (final MusicTrack track in tracks) ...<Widget>[
              Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(track.title, style: theme.textTheme.bodyLarge),
                    Text(
                      track.attribution,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    // The licence as text rather than a link: the app opens no
                    // browser, and CC asks for the URI, not for a tap.
                    Text(
                      track.licenceUrl,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
