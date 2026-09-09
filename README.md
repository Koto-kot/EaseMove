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

Це **Repository Pack v0.1**: продуктова й технічна специфікація, структура контенту,
Exercise Engine, локалізація, аудіо, Free/Pro-логіка, тестові feature flags і перші
структуровані вправи.

Застосунок ще не містить production-коду. Наступний етап — вертикальний MVP slice:

`Тіло → Коліна → список вправ → KNEE_001 → 5 с підготовки → виконання → 10 с відпочинку → auto-next`.

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
- `scripts/` — валідація бібліотеки.
- `src/` — майбутній код застосунку.

## Перші вправи

- `NECK_001` — Повороти голови.
- `KNEE_001` — Розгинання ноги сидячи.
- `KNEE_002` — Встати — сісти зі стільця.
- `KNEE_003` — Підтягування п’яти лежачи.

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
