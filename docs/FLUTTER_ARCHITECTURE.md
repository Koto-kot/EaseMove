# Flutter Architecture v0.1

## Mandatory stack

- Flutter
- Dart
- Android
- iOS

## Core rule

Exercise content is data-driven. Flutter widgets must not hard-code individual exercises.

## Suggested layers

```text
lib/
  app/
    app.dart
    router.dart

  core/
    config/
      feature_flags.dart
    localization/
    storage/
    audio/
    billing/
    clinical_gate/

  domain/
    exercise/
      exercise.dart
      exercise_sequence.dart
      exercise_variant.dart
      exercise_result.dart
    collection/
    tracking/

  data/
    exercise_repository/
    collection_repository/
    local_storage/

  features/
    home/
    body_map/
    exercise_catalog/
    exercise_player/
    pro/
    reminders/
    settings/

  shared/
    widgets/
    models/
```

## Exercise Player

Flutter Exercise Player має бути один для всіх вправ.

Він отримує normalized exercise model і рендерить:
- frames/animation;
- elapsed time;
- progress;
- repetition/side/set labels;
- voice cues;
- music;
- controls;
- auto-rest / auto-next.

## State machine

Не будувати Exercise Player на наборі незалежних Timer callbacks.
Використовувати deterministic state/state-transition model.

Основні стани:
- browsing
- selected
- prepCountdown
- active
- paused
- stopped
- completed
- autoRest
- manualBrowseNext

## State management

Конкретну бібліотеку (Riverpod або BLoC) обрати на старті реалізації.
Критерії:
- testability;
- deterministic transitions;
- minimal boilerplate;
- підтримка feature flags / entitlement state.

Не змішувати декілька state-management підходів без потреби.

## Localization

Flutter localization pipeline:
- ARB / generated localization classes для common UI;
- exercise-localized content компілюється з content source;
- fallback English;
- automatic system/app language;
- manual override.

## Content build pipeline

Authoring:
`YAML`

Build:
`YAML → validate → normalized JSON/Dart bundle`

Runtime:
Flutter читає вже validated content bundle.

## Assets

Declare generated exercise assets in Flutter asset manifest/build tooling.
Не embed user-visible text у exercise PNG.

## Audio

Audio service API concept:

```dart
abstract interface class AudioService {
  Future<void> playVoice(String assetKey);
  Future<void> playMusic(String trackId);
  Future<void> pauseAll();
  Future<void> resumeAll();
  Future<void> stopAll();
  Future<void> setVoiceVolume(double value);
  Future<void> setMusicVolume(double value);
}
```

Default:
- voice 1.0
- music 0.5
- ducking false

## Entitlements

```dart
abstract interface class EntitlementsService {
  bool canUse(String featureId);
  bool get isPro;
  Future<void> restorePurchases();
}
```

Development/test:
Pro unlocked.

Production:
Free sees locked Pro → contextual paywall.

## Testing

Required:
- state-machine unit tests;
- YAML/schema validation in CI;
- Exercise Player widget tests;
- localization tests;
- entitlement mode tests;
- integration test for Body → Knees → KNEE_001 → auto-next.
