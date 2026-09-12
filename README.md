# Movement & Wellbeing App — Repository Pack v0.1

Робочий репозиторій мобільного застосунку для простих повсякденних рухів і вправ.
Продукт не будується навколо схуднення, калорій, «ідеального тіла» чи спортивних челенджів.

> **Продуктова теза:** Ми не будуємо нове тіло — ми допомагаємо краще почуватися у своєму.


## Technology stack

- **Flutter**
- **Dart**
- iOS + Android from one codebase

Flutter/Dart є зафіксованим стеком проєкту.

## Статус

**v0.3 — затверджений домашній екран + вертикальний MVP slice.**

Працює наскрізний флоу з `TECHNICAL_SPEC.md` 21:

`мапа тіла → коліно → список вправ → KNEE_001 → Старт → 5 с підготовки →
виконання → Пауза/Продовжити → завершення → +1 → 10 с відпочинку →
auto-start наступної`

Реалізовано:

- Exercise Engine на нормалізованому timeline (анімація, голос і прогрес з одного джерела);
- детермінований state machine з усіма інваріантами `APP_STATE_MACHINE.md`;
- content pipeline `YAML → validate → JSON bundle` (застосунок не парсить YAML у runtime);
- домашній екран за `HOME_SCREEN_REPOSITORY_PACK_v1`: інтерактивна мапа тіла
  (доставлений артворк, 19 hotspot-ів, парне підсвічування, pulse → навігація)
  і 2x2 картки Тіло / Очі / Ранок / Засидівся, без нижньої навігації;
- каталог, плеєр з великим таймером, екран завершення, активність,
  налаштування, developer menu;
- clinical gate, feature flags, Free/Pro entitlements, contextual paywall;
- локалізація `uk` + `en`, частковий `pl` (домашній екран і зони) з per-key
  fallback, усе з одного authoring-джерела;
- 95 тестів (state machine, timeline, контент, локалізація, entitlements,
  домашній екран, бібліотека ліктів, режими голосу, acceptance-флоу).

Ще не зроблено: production-кадри для шиї та колін (артворк тіла й дев'яти
ліктьових вправ уже є), запис voice packs (тексти всіх 66 реплік готові —
`docs/generated/AUDIO_SCRIPT.md`; поки не записані, застосунок промовляє їх
через TTS), billing, планування нагадувань.
Див. `docs/DEV_SETUP.md` → «Відомі обмеження».

Швидкий старт: **`docs/DEV_SETUP.md`**.

## Demo

**https://koto-kot.github.io/EaseMove/**

Web-збірка того ж коду, для перегляду UI та флоу. Збирається з
`ENV=development`, тому показує вправи зі статусом `pending_review` —
інакше каталог був би порожній. Це **не** реліз і не медична рекомендація:
дозування, safety-тексти й пози не пройшли клінічного рев'ю
(`docs/SAFETY_AND_CLINICAL_REVIEW.md`).

Цільові платформи продукту — iOS та Android; web існує лише як demo.

## Ключові принципи

- мінімум питань і когнітивного навантаження;
- Free можна використовувати без анкети;
- Pro-функції Free-користувач бачить, але вони заблоковані paywall;
- у development/test Pro повністю відкритий feature flag;
- одна вправа може входити в багато зон/наборів без дублювання;
- усі вправи є даними, а не hard-coded екранами;
- production показує тільки вправи зі `clinical.status: approved`;
- тексти та голос локалізуються незалежно від логіки вправи;
- основна мова визначається мовою застосунку/телефону, не країною магазину;
- AI у майбутньому може лише вибирати з перевіреної бібліотеки, а не вигадувати вправи.

## Структура

- `docs/` — продуктове й технічне ТЗ.
- `data/exercises/` — бібліотека вправ YAML.
- `data/collections/` — метадані наборів.
- `data/categories/` — зони тіла.
- `data/localization/` — загальні локалізовані UI-рядки.
- `schemas/` — машинна схема вправ.
- `config/` — feature flags.
- `assets/` — майбутні production-кадри вправ і UI assets.
- `audio/` — майбутні voice packs.
- `music/` — фонова музика.
- `scripts/` — валідація бібліотеки та build контенту.
- `lib/` — код застосунку (Flutter).
- `test/` — тести.
- `assets/content/` — згенерований runtime-bundle (не редагувати вручну).

## Перші вправи

- `NECK_001` — Повороти голови.
- `KNEE_001` — Розгинання ноги сидячи.
- `KNEE_002` — Встати — сісти зі стільця.
- `KNEE_003` — Підтягування п’яти лежачи.
- `ELBOW_001`–`ELBOW_009` — лікті: від згинання рук сидячи до віджимань
  від стіни. Це перші вправи з готовим артворком
  (`docs/exercise_briefs/elbows/INDEX.md`).

Усі вони поки мають `clinical.status: pending_review`.

## Документи, з яких почати

1. `docs/PRODUCT_CONCEPT.md`
2. `docs/TECHNICAL_SPEC.md`
3. `docs/MENU_AND_NAVIGATION.md`
4. `docs/UX_FLOW.md`
5. `docs/APP_STATE_MACHINE.md`
6. `docs/EXERCISE_ENGINE.md`
7. `docs/EXERCISE_CONTENT_SCHEMA.md`
8. `docs/FEATURE_FLAGS.md`
9. `docs/SAFETY_AND_CLINICAL_REVIEW.md`

## Важливо

Цей репозиторій не є медичним протоколом. Дозування, варіанти, safety-тексти,
протипоказання та production-анімації мають пройти професійне клінічне рев’ю.


## Visual specifications

- `docs/VISUAL_STYLE_GUIDE.md`
- `docs/IMAGE_ASSET_SPEC.md`
- `docs/BODY_MAP_SPEC.md`
- `docs/IMAGE_BRIEF_TEMPLATE.md`
- `docs/EXERCISE_IMAGE_QA.md`
- `data/categories/body_hotspots.yaml`
- `data/visual/style_profiles.yaml`
- `data/visual/subject_profiles.yaml`
