/// Centralized feature flags and environment defaults.
///
/// Mirrors config/feature_flags.yaml (docs/FEATURE_FLAGS.md). Nothing in the UI
/// may test `if (pro)` on its own — it asks EntitlementsService, which asks
/// these flags.
library;

enum AppEnvironment { development, test, production }

enum ProAccessMode {
  /// Everything Pro is open — development and test builds.
  unlocked,

  /// Free sees Pro, tapping checks entitlement and shows a contextual paywall.
  paywall,

  /// Pro only for a tester allowlist / debug entitlement.
  tester,

  /// Emergency switch. Never a normal Free strategy.
  disabled,
}

class FeatureFlags {
  const FeatureFlags({
    required this.environment,
    required this.proVisibleToFree,
    required this.proAccessMode,
    required this.showPendingReviewContent,
    required this.approvedContentOnly,
    required this.developerMenu,
    required this.timingMultiplier,
    required this.features,
  });

  /// Environment defaults from config/feature_flags.yaml.
  factory FeatureFlags.forEnvironment(AppEnvironment environment) {
    switch (environment) {
      case AppEnvironment.production:
        return FeatureFlags(
          environment: environment,
          proVisibleToFree: true,
          proAccessMode: ProAccessMode.paywall,
          showPendingReviewContent: false,
          approvedContentOnly: true,
          developerMenu: false,
          timingMultiplier: 1.0,
          features: _defaultFeatures,
        );
      case AppEnvironment.development:
      case AppEnvironment.test:
        return FeatureFlags(
          environment: environment,
          proVisibleToFree: true,
          proAccessMode: ProAccessMode.unlocked,
          showPendingReviewContent: true,
          approvedContentOnly: false,
          developerMenu: true,
          timingMultiplier: 1.0,
          features: _defaultFeatures,
        );
    }
  }

  static const Map<String, bool> _defaultFeatures = <String, bool>{
    'pro_today_plan': true,
    'pro_profile': true,
    'pro_favorites': true,
    'pro_advanced_stats': true,
    'pro_audio_customization': true,
    'pro_smart_reminders': true,
    'pro_ai_assistant': false,
    'pro_human_curator': false,
    'eyes_module': true,
    'bed_module': true,
    'computer_module': true,
  };

  final AppEnvironment environment;
  final bool proVisibleToFree;
  final ProAccessMode proAccessMode;
  final bool showPendingReviewContent;
  final bool approvedContentOnly;
  final bool developerMenu;
  final double timingMultiplier;
  final Map<String, bool> features;

  bool get isProduction => environment == AppEnvironment.production;

  /// Whether a feature exists in this build at all. Distinct from entitlement:
  /// visibility says it is shipped, entitlement says it is usable.
  bool isFeatureVisible(String featureId) => features[featureId] ?? false;

  FeatureFlags copyWith({
    ProAccessMode? proAccessMode,
    bool? showPendingReviewContent,
    bool? approvedContentOnly,
    double? timingMultiplier,
  }) {
    return FeatureFlags(
      environment: environment,
      proVisibleToFree: proVisibleToFree,
      proAccessMode: proAccessMode ?? this.proAccessMode,
      showPendingReviewContent:
          showPendingReviewContent ?? this.showPendingReviewContent,
      approvedContentOnly: approvedContentOnly ?? this.approvedContentOnly,
      developerMenu: developerMenu,
      timingMultiplier: timingMultiplier ?? this.timingMultiplier,
      features: features,
    );
  }
}
