# NECK_009 — Ізометрія долонею до потилиці

**Document type:** Exercise Production Brief  
**Exercise ID:** `NECK_009`  
**Slug:** `seated_isometric_palm_back_head`  
**Primary zone:** `neck`  
**Status:** `draft`  
**Asset status:** `images_included`  
**Difficulty:** starter / easy  
**Position:** seated  
**Movement type:** gentle posterior isometric neck activation  
**Framing:** `FULL_SAFE` + `UPPER_SAFE`  
**Contact visualization:** `soft red highlight in active phase`  
**Schema:** Exercise Schema v1.3

---

## 1. Суть вправи

Користувач сидить рівно, кладе долоню на потилицю і **м’яко натискає потилицею назад у долоню**, а долонею створює зустрічний опір. Голова при цьому залишається майже нерухомою й у нейтральному положенні.

Це ізометрична вправа: зовнішній рух мінімальний, а основна дія — коротке контрольоване зусилля назад без закидання голови.

---

## 2. Стартове положення

- сісти рівно на стілець;
- стопи стійко стоять на підлозі;
- спина витягнута, таз стабільний;
- плечі опущені й розслаблені;
- голова у нейтральному положенні;
- погляд прямо;
- вільна рука лежить на стегні.

---

## 3. Рух

### Phase A — hand to back of head
З нейтрального положення користувач піднімає руку й **кладе долоню на потилицю**. Голова не відхиляється назад, шия залишається довгою, плечі — розслабленими.

Технічний filename збережено як `motion_01_hands_behind_head_upper_safe.png` для сумісності з уже затвердженою структурою пакета, хоча в демонстрації використовується одна активна долоня.

### Phase B — isometric back-head press
Користувач **м’яко натискає потилицею в долоню**, а долоня утримує голову від руху назад. Видимого зміщення голови бути не повинно.

### Return logic
Після короткого утримання напругу послаблюють, руку опускають і повертаються у нейтральне положення.

### Canonical cycle
`neutral → palm to back of head → gentle isometric press → release → neutral`

---

## 4. Візуальне правило контакту

Для активної ізометричної фази використовуємо **м’яке червоне підсвічення зони контакту долоні з потилицею**.

Підсвічення:
- помітне, але без жорсткого контуру;
- не повинно виглядати як біль або травма;
- використовується тільки в активному кадрі;
- допомагає відрізнити просте розміщення долоні від фактичного ізометричного натиску.

У підготовчому кадрі `motion_01_hands_behind_head_upper_safe.png` червоного підсвічення немає.

---

## 5. Timing

- preparation countdown: `5 s`
- default active duration: `60 s`
- presets: `60 / 120 / 180 / 300 s`
- suggested isometric hold: `3–5 s`
- suggested release: approximately `2 s`
- completion condition: elapsed active time
- pause freezes timer and animation
- Stop is available at any time
- normal completion → `10 s` rest before the next exercise

---

## 6. Framing

Use:
- `setup_full_safe.png` for the initial seated position;
- profile / slight three-quarter `UPPER_SAFE` framing for the hand-to-occiput phases, because the contact point must be visible.

Mandatory:
- full head visible;
- neck visible;
- active shoulder and arm fully readable;
- palm-to-occiput contact point clearly visible;
- head stays neutral without extension;
- active and preparation frames use the same crop and scale;
- soft red highlight remains localized to the contact zone in the active frame.

---

## 7. Production images

- `setup_full_safe.png`
- `motion_01_hands_behind_head_upper_safe.png`
- `motion_02_isometric_back_head_press_upper_safe.png`
- `preview.png`

Folder:
`assets/exercises/NECK_009/images/`

Runtime assets:
- contain no text;
- contain no arrows;
- contain no UI, logo, or watermark;
- active phase may contain the approved soft red contact highlight because the isometric effort is otherwise visually subtle.

`preview.png` currently duplicates the active isometric frame.

---

## 8. Model continuity

The neck series keeps one visual identity. For `NECK_009` preserve the established look from `NECK_001`:
- dark brown hair gathered low;
- lavender / purple short-sleeve shirt;
- dark charcoal pants;
- calm neutral expression;
- seated instructional presentation;
- simple light studio background.

The exact side-profile crop is chosen here so the occiput contact is readable.

---

## 9. Documentation artifacts

- `docs/exercise_briefs/neck/NECK_009/NECK_009_BRIEF.md`
- `docs/exercise_briefs/neck/NECK_009/NECK_009_brief_sheet_v1.png`

The visual brief:
- follows the approved neck-series three-panel layout;
- uses no arrows;
- separates hand placement from the active press using the soft red contact highlight only in the third panel.

---

## 10. Audio

Exercise-specific Ukrainian cues:

`audio/uk/exercises/NECK_009/setup.m4a`  
Suggested text: `Сядьте рівно. Розслабте плечі. Тримайте голову прямо.`

`audio/uk/exercises/NECK_009/start_movement.m4a`  
Suggested text: `Покладіть долоню на потилицю. М’яко натискайте потилицею в долоню, не відхиляючи голову назад.`

Reusable common cues:
- `audio/uk/common/halfway.m4a` — `Половину виконано.`
- `audio/uk/common/completed.m4a` — `Готово.`

---

## 11. Safety / usability cues

- не тиснути сильно;
- не закидати голову назад;
- не піднімати плечі;
- не затримувати дихання;
- зберігати голову у нейтральному положенні;
- зупинитися, якщо з’являється біль, виражений дискомфорт або запаморочення.

---

## 12. QA checklist

- [x] Setup frame uses the approved NECK_001 source asset.
- [x] Preparation and active frames show the same side-profile model and outfit.
- [x] Preparation frame contains no red contact highlight.
- [x] Active frame contains a localized soft red occiput contact highlight.
- [x] Head stays neutral without visible backward movement.
- [x] Runtime images contain no text / arrows / UI / watermark.
- [x] Visual brief uses the approved three-panel neck layout.
- [x] YAML paths match the real files.
