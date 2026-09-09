/// Free / Pro access. UI asks `canUse(featureId)` and never inspects flags or
/// purchase state directly (docs/TECHNICAL_SPEC.md 12).
library;

import '../config/feature_flags.dart';

enum Tier { free, pro }

abstract interface class EntitlementsService {
  bool canUse(String featureId);

  /// A Free user still *sees* Pro features; this is only about access.
  bool isFeatureVisible(String featureId);
  bool get isPro;
  Tier get currentTier;
  Future<void> restorePurchases();
}

/// Local implementation for the MVP: no billing plugin wired yet, so access is
/// decided by the environment's access mode plus a stored tester/dev override.
class LocalEntitlementsService implements EntitlementsService {
  LocalEntitlementsService({
    required this.flags,
    this.hasPurchase = false,
    this.devProOverride = false,
  });

  FeatureFlags flags;
  bool hasPurchase;
  bool devProOverride;

  void updateFlags(FeatureFlags value) => flags = value;

  /// Developer menu toggle — non-production builds only.
  void setDevProOverride(bool value) {
    if (flags.isProduction) return;
    devProOverride = value;
  }

  void setPurchase(bool value) => hasPurchase = value;

  @override
  bool get isPro {
    switch (flags.proAccessMode) {
      case ProAccessMode.unlocked:
        return true;
      case ProAccessMode.disabled:
        return false;
      case ProAccessMode.tester:
        return devProOverride || hasPurchase;
      case ProAccessMode.paywall:
        return hasPurchase || (!flags.isProduction && devProOverride);
    }
  }

  @override
  Tier get currentTier => isPro ? Tier.pro : Tier.free;

  @override
  bool isFeatureVisible(String featureId) {
    if (!flags.isFeatureVisible(featureId)) return false;
    return flags.proVisibleToFree || isPro;
  }

  @override
  bool canUse(String featureId) {
    if (!flags.isFeatureVisible(featureId)) return false;
    if (!featureId.startsWith('pro_')) return true;
    return isPro;
  }

  @override
  Future<void> restorePurchases() async {
    // Billing plugin lands with release scope (docs/TECHNICAL_SPEC.md 14).
  }
}
