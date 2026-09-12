/// Riverpod wiring.
///
/// Riverpod is the single state-management standard for the project — chosen at
/// code kickoff per docs/FLUTTER_ARCHITECTURE.md ("State management").
library;

import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/audio/audio_service.dart';
import '../core/clinical/clinical_gate.dart';
import '../core/config/feature_flags.dart';
import '../core/entitlements/entitlements_service.dart';
import '../core/localization/app_strings.dart';
import '../core/storage/local_store.dart';
import '../data/content_bundle.dart';
import '../data/exercise_repository.dart';
import '../data/tracking_repository.dart';
import '../domain/exercise/exercise.dart';

/// Overridden in main() with the build's real environment, and in tests.
final Provider<AppEnvironment> environmentProvider = Provider<AppEnvironment>(
  (Ref ref) => AppEnvironment.development,
);

/// Overridden in main() once shared_preferences is open.
final Provider<LocalStore> localStoreProvider = Provider<LocalStore>(
  (Ref ref) =>
      throw UnimplementedError('localStoreProvider must be overridden'),
);

final Provider<AudioService> audioServiceProvider = Provider<AudioService>(
  (Ref ref) => LoggingAudioService(),
);

class SettingsController extends StateNotifier<AppSettings> {
  SettingsController(this._store) : super(_store.readSettings());

  final LocalStore _store;

  Future<void> update(AppSettings settings) async {
    state = settings;
    await _store.writeSettings(settings);
  }

  Future<void> setLocaleOverride(String? locale) => update(
    locale == null
        ? state.copyWith(clearLocaleOverride: true)
        : state.copyWith(localeOverride: locale),
  );

  Future<void> setVoiceEnabled(bool value) =>
      update(state.copyWith(voiceEnabled: value));
  Future<void> setVoiceMode(VoiceMode value) =>
      update(state.copyWith(voiceMode: value));
  Future<void> setMusicEnabled(bool value) =>
      update(state.copyWith(musicEnabled: value));
  Future<void> setReducedMotion(bool value) =>
      update(state.copyWith(reducedMotion: value));
  Future<void> setReminders(bool value) =>
      update(state.copyWith(remindersEnabled: value));
  Future<void> setDevPro(bool value) =>
      update(state.copyWith(devProOverride: value));
  Future<void> setDevShowPending(bool value) =>
      update(state.copyWith(devShowPending: value));
  Future<void> setDevSkipCountdowns(bool value) =>
      update(state.copyWith(devSkipCountdowns: value));
  Future<void> setDevShowIds(bool value) =>
      update(state.copyWith(devShowIds: value));
  Future<void> setDevTimingMultiplier(double value) =>
      update(state.copyWith(devTimingMultiplier: value));
}

final StateNotifierProvider<SettingsController, AppSettings> settingsProvider =
    StateNotifierProvider<SettingsController, AppSettings>(
      (Ref ref) => SettingsController(ref.watch(localStoreProvider)),
    );

/// Environment defaults, with the developer menu applied on top. Production
/// ignores developer overrides by construction.
final Provider<FeatureFlags> featureFlagsProvider = Provider<FeatureFlags>((
  Ref ref,
) {
  final FeatureFlags base = FeatureFlags.forEnvironment(
    ref.watch(environmentProvider),
  );
  if (base.isProduction) return base;
  final AppSettings settings = ref.watch(settingsProvider);
  return base.copyWith(
    showPendingReviewContent: settings.devShowPending,
    timingMultiplier: settings.devTimingMultiplier,
  );
});

final Provider<ClinicalGate> clinicalGateProvider = Provider<ClinicalGate>(
  (Ref ref) => ClinicalGate(ref.watch(featureFlagsProvider)),
);

final Provider<EntitlementsService> entitlementsProvider =
    Provider<EntitlementsService>((Ref ref) {
      final FeatureFlags flags = ref.watch(featureFlagsProvider);
      final AppSettings settings = ref.watch(settingsProvider);
      return LocalEntitlementsService(
        flags: flags,
        devProOverride: settings.devProOverride,
      );
    });

/// `null` means the app's own rootBundle. Tests override this with a
/// disk-backed bundle so content can be exercised without a device.
final Provider<AssetBundle?> assetBundleProvider = Provider<AssetBundle?>(
  (Ref ref) => null,
);

final FutureProvider<ContentBundle> contentBundleProvider =
    FutureProvider<ContentBundle>(
      (Ref ref) => ContentBundle.load(bundle: ref.watch(assetBundleProvider)),
    );

final FutureProvider<ExerciseRepository> exerciseRepositoryProvider =
    FutureProvider<ExerciseRepository>((Ref ref) async {
      final ContentBundle bundle = await ref.watch(
        contentBundleProvider.future,
      );
      return ExerciseRepository(
        bundle: bundle,
        gate: ref.watch(clinicalGateProvider),
        assets: ref.watch(assetBundleProvider),
      );
    });

final Provider<TrackingRepository> trackingRepositoryProvider =
    Provider<TrackingRepository>(
      (Ref ref) => TrackingRepository(ref.watch(localStoreProvider)),
    );

/// Bumped after a session is saved so the activity screen refreshes.
final StateProvider<int> activityRevisionProvider = StateProvider<int>(
  (Ref ref) => 0,
);

final Provider<ActivityStats> activityStatsProvider = Provider<ActivityStats>((
  Ref ref,
) {
  ref.watch(activityRevisionProvider);
  return ref.watch(trackingRepositoryProvider).read();
});

/// Resolved app language: manual override, else the best supported system
/// language, else English (docs/LOCALIZATION.md).
final Provider<String> localeProvider = Provider<String>((Ref ref) {
  final String? override = ref.watch(settingsProvider).localeOverride;
  if (override != null && AppStrings.supportedLocales.contains(override)) {
    return override;
  }
  for (final ui.Locale locale
      in WidgetsBinding.instance.platformDispatcher.locales) {
    if (AppStrings.supportedLocales.contains(locale.languageCode)) {
      return locale.languageCode;
    }
  }
  return AppStrings.fallbackLocale;
});

final FutureProvider<AppStrings> stringsProvider = FutureProvider<AppStrings>(
  (Ref ref) => AppStrings.load(
    ref.watch(localeProvider),
    bundle: ref.watch(assetBundleProvider),
  ),
);
