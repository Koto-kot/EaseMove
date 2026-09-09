/// Contextual paywall: it explains the feature that was tapped, and is never
/// thrown at the user on app open (docs/MENU_AND_NAVIGATION.md).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/entitlements/entitlements_service.dart';
import '../../core/localization/app_strings.dart';

class Paywall {
  /// Runs [onAllowed] when the entitlement permits the feature, otherwise
  /// shows the contextual sheet. UI code never tests `isPro` itself.
  static Future<void> guard(
    BuildContext context,
    WidgetRef ref, {
    required String featureId,
    required String featureTitle,
    required String explanation,
    required VoidCallback onAllowed,
  }) async {
    final EntitlementsService entitlements = ref.read(entitlementsProvider);
    if (entitlements.canUse(featureId)) {
      onAllowed();
      return;
    }
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (BuildContext context) =>
          _PaywallSheet(featureTitle: featureTitle, explanation: explanation),
    );
  }
}

class _PaywallSheet extends ConsumerWidget {
  const _PaywallSheet({required this.featureTitle, required this.explanation});

  final String featureTitle;
  final String explanation;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppStrings t = AppStrings.of(context);
    final ThemeData theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(t('app.paywall.title'), style: theme.textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text(featureTitle, style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(explanation, style: theme.textTheme.bodyMedium),
          const SizedBox(height: 24),
          FilledButton(
            // Billing lands with release scope (docs/TECHNICAL_SPEC.md 14).
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(t('app.paywall.not_available'))),
            ),
            child: Text(t('app.paywall.subscribe')),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: () => ref.read(entitlementsProvider).restorePurchases(),
            child: Text(t('app.paywall.restore')),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(t('app.paywall.close')),
          ),
        ],
      ),
    );
  }
}

/// `Мій план PRO` section. Free sees every entry with a PRO badge; tapping one
/// opens the paywall for that specific feature.
class ProPlanScreen extends ConsumerWidget {
  const ProPlanScreen({super.key});

  static const List<({String featureId, String titleKey})> _entries =
      <({String featureId, String titleKey})>[
        (featureId: 'pro_today_plan', titleKey: 'app.pro.today'),
        (featureId: 'pro_profile', titleKey: 'app.pro.profile'),
        (featureId: 'pro_profile', titleKey: 'app.pro.zones'),
        (featureId: 'pro_today_plan', titleKey: 'app.pro.programs'),
        (featureId: 'pro_advanced_stats', titleKey: 'app.pro.progress'),
        (featureId: 'pro_favorites', titleKey: 'app.pro.favorites'),
      ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppStrings t = AppStrings.of(context);
    final EntitlementsService entitlements = ref.watch(entitlementsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(t('app.pro.title'))),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: <Widget>[
          for (final ({String featureId, String titleKey}) entry in _entries)
            if (entitlements.isFeatureVisible(entry.featureId))
              ListTile(
                title: Text(t(entry.titleKey)),
                trailing: entitlements.canUse(entry.featureId)
                    ? const Icon(Icons.chevron_right)
                    : const Icon(Icons.lock_outline),
                onTap: () => Paywall.guard(
                  context,
                  ref,
                  featureId: entry.featureId,
                  featureTitle: t(entry.titleKey),
                  explanation: t('app.paywall.title'),
                  onAllowed: () => ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        '${t(entry.titleKey)} — ${t("app.pro.badge")}',
                      ),
                    ),
                  ),
                ),
              ),
        ],
      ),
    );
  }
}
