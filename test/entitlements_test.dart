import 'package:ease_move/core/config/feature_flags.dart';
import 'package:ease_move/core/entitlements/entitlements_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('development and test builds', () {
    test('Pro is fully unlocked without any purchase', () {
      for (final AppEnvironment env in <AppEnvironment>[
        AppEnvironment.development,
        AppEnvironment.test,
      ]) {
        final FeatureFlags flags = FeatureFlags.forEnvironment(env);
        final LocalEntitlementsService entitlements = LocalEntitlementsService(
          flags: flags,
        );

        expect(entitlements.isPro, isTrue, reason: env.name);
        expect(entitlements.currentTier, Tier.pro);
        expect(entitlements.canUse('pro_today_plan'), isTrue);
        expect(entitlements.canUse('pro_advanced_stats'), isTrue);
      }
    });

    test('the developer menu is available', () {
      expect(
        FeatureFlags.forEnvironment(AppEnvironment.development).developerMenu,
        isTrue,
      );
      expect(
        FeatureFlags.forEnvironment(AppEnvironment.production).developerMenu,
        isFalse,
      );
    });
  });

  group('production', () {
    final FeatureFlags flags = FeatureFlags.forEnvironment(
      AppEnvironment.production,
    );

    test('a Free user sees Pro features but cannot use them', () {
      final LocalEntitlementsService entitlements = LocalEntitlementsService(
        flags: flags,
      );

      expect(flags.proAccessMode, ProAccessMode.paywall);
      expect(entitlements.isPro, isFalse);
      expect(
        entitlements.isFeatureVisible('pro_today_plan'),
        isTrue,
        reason: 'visibility is what makes the contextual paywall possible',
      );
      expect(entitlements.canUse('pro_today_plan'), isFalse);
    });

    test('a purchase unlocks Pro features', () {
      final LocalEntitlementsService entitlements = LocalEntitlementsService(
        flags: flags,
        hasPurchase: true,
      );
      expect(entitlements.isPro, isTrue);
      expect(entitlements.canUse('pro_favorites'), isTrue);
    });

    test('the developer override cannot unlock Pro in production', () {
      final LocalEntitlementsService entitlements = LocalEntitlementsService(
        flags: flags,
      )..setDevProOverride(true);
      expect(entitlements.isPro, isFalse);
      expect(entitlements.canUse('pro_today_plan'), isFalse);
    });

    test(
      'a feature switched off in this build is neither visible nor usable',
      () {
        final LocalEntitlementsService entitlements = LocalEntitlementsService(
          flags: flags,
          hasPurchase: true,
        );
        expect(flags.isFeatureVisible('pro_ai_assistant'), isFalse);
        expect(entitlements.isFeatureVisible('pro_ai_assistant'), isFalse);
        expect(
          entitlements.canUse('pro_ai_assistant'),
          isFalse,
          reason: 'a visibility flag is not an entitlement',
        );
      },
    );

    test('free features stay usable without Pro', () {
      final LocalEntitlementsService entitlements = LocalEntitlementsService(
        flags: flags,
      );
      expect(entitlements.canUse('bed_module'), isTrue);
      expect(entitlements.canUse('computer_module'), isTrue);
    });
  });

  group('other access modes', () {
    test('tester mode unlocks Pro for a debug entitlement only', () {
      final FeatureFlags flags = FeatureFlags.forEnvironment(
        AppEnvironment.development,
      ).copyWith(proAccessMode: ProAccessMode.tester);
      expect(LocalEntitlementsService(flags: flags).isPro, isFalse);
      expect(
        (LocalEntitlementsService(flags: flags)..setDevProOverride(true)).isPro,
        isTrue,
      );
    });

    test('disabled mode locks Pro even with a purchase', () {
      final FeatureFlags flags = FeatureFlags.forEnvironment(
        AppEnvironment.development,
      ).copyWith(proAccessMode: ProAccessMode.disabled);
      expect(
        LocalEntitlementsService(flags: flags, hasPurchase: true).isPro,
        isFalse,
      );
    });
  });
}
