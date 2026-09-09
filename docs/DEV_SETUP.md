# Dev Setup

## Вимоги

- Flutter stable (розроблялося на **3.47.2 / Dart 3.13.2**)
- Python 3.10+ (для content pipeline)

## Перший запуск

```bash
pip install -r tools/requirements.txt
python scripts/validate_library.py      # schema + identity validation YAML
python scripts/build_content.py         # YAML -> assets/content/*.json
flutter pub get
flutter test
```

## Платформи

`android/` та `ios/` є в репозиторії.

Для локального перегляду в браузері або на Windows-десктопі згенеруйте
додаткові таргети (вони в `.gitignore`):

```bash
flutter create . --platforms=web,windows --project-name ease_move
flutter run -d chrome
```

`flutter create` не перезаписує `lib/`, `pubspec.yaml` чи тести, але створює
шаблонний `test/widget_test.dart` — його треба видалити.

Windows-десктоп додатково вимагає Developer Mode у Windows (symlink support).

## Запуск

```bash
flutter run                                        # development
flutter run --dart-define=ENV=production           # production-флаги
```

Середовище — compile-time. `ENV`:

| ENV | Pro | Клінічний контент | Developer menu |
|---|---|---|---|
| `development` (default) | unlocked | pending_review видно | так |
| `test` | unlocked | pending_review видно | так |
| `production` | paywall | тільки `approved` | ні |

> У `production` наразі жодна вправа не показується — усі мають
> `clinical.status: pending_review`. Це очікувана поведінка clinical gate,
> а не помилка.

## Content pipeline

Authoring — тільки YAML у `data/`. Застосунок читає лише згенерований
`assets/content/`, який **комітиться** в репозиторій.

Після будь-якої зміни в `data/`:

```bash
python scripts/build_content.py
```

CI падає, якщо `assets/content` не синхронний із `data/`.

Що робить build-крок понад копіювання:

- валідує кожну вправу проти `schemas/exercise.schema.json`;
- зводить три authoring-форми `sequence` до однієї runtime-форми;
- перевіряє, що всі `frame_id` і `voice_event` у sequence існують;
- перевіряє, що `collections` вправи збігаються з `data/exercises/index.yaml`;
- перевіряє, що hotspot-и ведуть на наявні колекції;
- попереджає про неповні мовні пакети та про застарілі `body_map_hotspot_ids`.

## Developer menu

`Налаштування → Developer menu` (тільки non-production):
Pro-режим, показ вправ без рев'ю, пропуск відліків, множник часу,
показ ID, скидання статистики.

Множник часу зручний для ручної перевірки довгих вправ: `0.25×` проганяє
KNEE_001 за ~46 с замість 182 с.

## Тести

```bash
flutter test                                  # усе
flutter test test/session_machine_test.dart   # state machine
flutter test test/vertical_slice_test.dart    # acceptance-флоу TECHNICAL_SPEC 21
```

| Файл | Що покриває |
|---|---|
| `test/exercise_timeline_test.dart` | побудова timeline, кадри, розв'язання voice cues |
| `test/session_machine_test.dart` | усі інваріанти `APP_STATE_MACHINE.md` |
| `test/content_bundle_test.dart` | цілісність контенту, clinical gate, навігація каталогом |
| `test/localization_test.dart` | повнота ключів у всіх мовах |
| `test/entitlements_test.dart` | Free/Pro у кожному access mode |
| `test/vertical_slice_test.dart` | Тіло → Коліна → KNEE_001 → … → auto-next |

## Відомі обмеження цього slice

- Кадри вправ і body-map artwork ще не створені — рендеряться плейсхолдери.
- Контент вправ і назви колекцій існують лише українською (authoring-мова).
  Якщо мова застосунку `en`, UI-рядки будуть англійськими, а назви вправ і зон —
  українськими. Це очікуваний fallback до authoring-локалі; переклад контенту —
  окремий крок за чеклістом `LOCALIZATION.md`.
- Voice packs не записані — голос іде через системний TTS (`flutter_tts`),
  який озвучує `text_uk` з audio events. Записане аудіо замінить лише
  `TtsAudioService`.
- Фонової музики немає — у `music/` лише README, тому `playMusic` no-op.
- Billing не підключений — paywall показує повідомлення-заглушку.
- Нагадування: перемикач зберігається, планування нотифікацій не реалізоване.
