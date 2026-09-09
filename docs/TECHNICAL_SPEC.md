# Technical Specification v0.1

## 1. Platforms

- iOS
- Android

## 2. Mandatory implementation stack

Cross-platform mobile application:
- **Flutter**
- **Dart**

Це зафіксований стек проєкту. Не використовувати React Native, TypeScript або інший UI framework
без окремого перегляду технічного рішення.

Версії Flutter/Dart не pinяться в продуктовому ТЗ; на старті коду фіксуються актуальні stable-версії
у репозиторії та CI.

Native platform services підключаються через Flutter plugins / platform channels для:
- app-specific language;
- audio;
- notifications/haptics;
- local persistence;
- Apple App Store / Google Play billing.

## 3. Flutter architecture

Рекомендовані логічні модулі:

```text
AppShell
Navigation
Entitlements
FeatureFlags
ExerciseCatalog
ExerciseEngine
ExerciseStateMachine
AudioEngine
MusicEngine
Localization
Tracking
LocalStorage
Reminders
Billing
ClinicalGate
AssetResolver
```

## 4. Local-first MVP

MVP не вимагає акаунта.

Локально зберігаються:
- settings;
- language;
- audio settings;
- reminder settings;
- lifetime count;
- exercise history;
- Pro profile, якщо є;
- favorites.

Exercise content може бути bundled із застосунком.
Remote content update — пізніше.

## 5. Exercise content

Canonical authoring = YAML.

Runtime build може:
1. validate YAML;
2. compile to JSON;
3. bundle index;
4. include only approved production content.

Exercise logic не hard-code.

## 6. Clinical gate

API concept:

```text
canRenderExercise(exercise, environment)
```

Development:
- pending allowed by flag.

Production:
- `clinical.status === approved`.

## 7. Collections

Exercise має:
- tags;
- collections;
- collection_candidates.

Catalog filters by explicit collection.
Recommendation engine може використовувати tags.

## 8. Exercise Player

Required:
- animation;
- elapsed timer;
- progress;
- repetition/side where applicable;
- voice;
- music;
- Previous;
- Start/Pause/Continue;
- Stop;
- Next.

## 9. Timing

Global defaults:
- manual prep = 5 sec;
- auto-rest = 10 sec.

Exercise YAML може містити specific sequence timing.

Single source of truth:
**sequence timeline/state machine**.

Не запускати animation/audio/progress незалежними timers, що можуть розсинхронізуватися.

## 10. Audio

Default mix:
- voice 1.0
- music 0.5
- no ducking

Audio events мають priorities і collision policy.

## 11. Localization

- auto from app/device language;
- manual override;
- fallback English;
- no hard-coded visible strings;
- country of store не визначає app language;
- interface language and voice language можуть бути independent у Pro.

## 12. Free / Pro entitlement

Centralized service:

```text
EntitlementsService
  canUse(featureId)
  currentTier()
  restorePurchases()
```

Development:
`access_mode = unlocked`

Production:
`access_mode = paywall`

Free бачить locked Pro.

## 13. Feature flags

Centralized config.
Не розкидати `if pro` по UI.

## 14. Billing

На release:
- Apple in-app purchase/subscription;
- Google Play Billing;
- monthly/yearly/lifetime залежно final catalog.

Runtime access визначається entitlement, а не просто локальним boolean.

## 15. Tracking model

Exercise result:

```json
{
  "exerciseId": "KNEE_001",
  "startedAt": "...",
  "actualActiveSeconds": 52,
  "completed": true,
  "earlyStop": false,
  "completedRepetitions": 10,
  "side": null,
  "collectionId": "body_knees"
}
```

## 16. Lifetime counter

Global service з однією policy:
- normal completion increments;
- early-stop behavior configurable.

Не використовувати streak як guilt mechanism.

## 17. Reminders

Local scheduled reminders достатні для MVP.
Permission запитується контекстно.

## 18. Accessibility

- touch targets ≈ 44×44 CSS/dp min;
- scalable text;
- screen reader labels;
- essential info not color-only;
- reduced motion;
- великі exercise visuals.

## 19. Data privacy

MVP local-first мінімізує збір персональних даних.
Pro profile може містити чутливі поля; не надсилати на backend без окремої необхідності й privacy design.

## 20. Testing build

Developer menu:
- Pro mode;
- clinical visibility;
- timing multiplier;
- skip countdowns;
- reset stats/profile;
- force locale;
- show IDs.

Production build не містить доступного developer menu.

## 21. First code slice acceptance criteria

Flow:

`Тіло → Коліна → 3 cards → KNEE_001 → Start → 5 → active → Pause/Resume → complete → +1 → 10 → next auto-start`

Must also prove:
- Pro locked/unlocked mode;
- localization keys;
- YAML load;
- pending content dev gate;
- production approval gate;
- tracking persistence.


## 22. Flutter-specific implementation requirements

### Project structure

Рекомендована базова структура:

```text
lib/
  app/
  core/
    config/
    localization/
    storage/
    audio/
    billing/
  features/
    body/
    exercise_catalog/
    exercise_player/
    pro/
    reminders/
    settings/
  domain/
    exercises/
    collections/
    tracking/
  data/
    repositories/
    models/
  widgets/
```

### State management

State management має підтримувати:
- deterministic Exercise State Machine;
- pause/resume без втрати sequence position;
- centralized feature flags;
- centralized entitlements;
- testability.

Конкретну Flutter-бібліотеку state management (наприклад Riverpod/BLoC) обрати на code kickoff
і зафіксувати одним стандартом для всього проєкту.

### Content loading

YAML використовується як authoring format у repository.
Перед runtime рекомендовано build-step перетворювати YAML у validated JSON/Dart assets,
щоб не покладатися на parsing великої бібліотеки YAML у production runtime.

### Localization

Використовувати Flutter localization infrastructure (`flutter_localizations` / ARB або еквівалентний
стандартний pipeline). Exercise IDs та localization keys залишаються стабільними.

### Audio

Flutter Audio Engine повинен:
- відтворювати voice cues;
- відтворювати looped background music;
- підтримувати voice/music volume independently;
- не застосовувати dynamic ducking за замовчуванням;
- синхронізувати cues із Exercise State Machine.

### Billing

Entitlements abstraction має бути незалежним від UI.
Production integration:
- Google Play Billing;
- Apple In-App Purchase;
через підтримуваний Flutter plugin/adaptor.

### Testing

Обов’язкові:
- unit tests для state machine;
- unit tests для content validation logic;
- widget tests для Exercise Player;
- integration test для першого vertical slice.


## 23. Body Map visual/data architecture

Головний екран `Тіло` використовує:
- artwork: `assets/body-map/`;
- zones: `data/categories/body_zones.yaml`;
- normalized hit areas: `data/categories/body_hotspots.yaml`.

Flutter не hard-code hotspot coordinates у widgets.
Hotspots масштабуються відносно фактично відрендерених bounds body-map artwork.

Див.:
- `docs/BODY_MAP_SPEC.md`
- `docs/VISUAL_STYLE_GUIDE.md`
- `docs/IMAGE_ASSET_SPEC.md`
