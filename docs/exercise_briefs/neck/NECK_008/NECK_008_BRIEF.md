# NECK_008 — Ізометрія долонею до скроні

**Document type:** Exercise Production Brief  
**Exercise ID:** `NECK_008`  
**Slug:** `seated_isometric_palm_temple`  
**Primary zone:** `neck`  
**Status:** `draft`  
**Asset status:** `images_included`  
**Difficulty:** starter / easy  
**Position:** seated  
**Movement type:** gentle lateral isometric neck activation  
**Framing:** `FULL_SAFE` + `UPPER_SAFE`  
**Mirror interpretation:** `enabled for visual brief labeling`  
**Schema:** Exercise Schema v1.3

---

## 1. Суть вправи

Користувач сидить рівно, прикладає долоню до скроні й **м’яко створює зустрічний опір**, не дозволяючи голові нахилитися вбік. Потім вправа повторюється для іншої сторони.

Це ізометрична вправа: видимого руху голови майже немає. Працює лише легкий контрольований тиск скронею в долоню та долонею назустріч.

---

## 2. Стартове положення

- сісти рівно на стілець;
- стопи стійко на підлозі;
- спина витягнута, таз стабільний;
- плечі опущені й розслаблені;
- голова у нейтральному положенні;
- погляд прямо;
- вільна рука лежить на стегні.

---

## 3. Рух

### Phase A — palm to left temple (technical filename)
Долоня розміщується на **лівій скроні моделі**. Модель м’яко натискає скронею в долоню, а долоня створює зустрічний опір. Голова залишається вертикальною.

У **дзеркальному форматі для користувача** цей кадр підписується як виконання **праворуч**.

### Phase B — palm to right temple (technical filename)
Долоня розміщується на **правій скроні моделі**. Виконується такий самий м’який ізометричний натиск без руху голови.

У **дзеркальному форматі для користувача** цей кадр підписується як виконання **ліворуч**.

### Return logic
Після утримання напругу послаблюють, руку опускають і переходять на інший бік.

### Canonical cycle
`neutral → right-side user press → release → left-side user press → release → neutral`

---

## 4. Візуальне правило контакту

Для активної ізометричної фази використовуємо **м’яке червоне підсвічення зони контакту долоні зі скронею**.

Підсвічення:
- трохи помітніше, ніж у першій версії NECK_007;
- м’яке, без жорсткого контуру;
- не повинно виглядати як травма або біль;
- служить лише для того, щоб користувач одразу відрізнив активний натиск від звичайного дотику.

Цей принцип можна повторно використовувати для інших ізометричних вправ, де рух зовні майже непомітний.

---

## 5. Timing

- preparation countdown: `5 s`
- default active duration: `60 s`
- presets: `60 / 120 / 180 / 300 s`
- suggested isometric hold: `3–5 s` per side
- short release between sides: approximately `2 s`
- completion condition: elapsed active time
- pause freezes timer and animation
- Stop is available at any time
- normal completion → `10 s` rest before the next exercise

---

## 6. Framing

Use:
- `setup_full_safe.png` for the initial whole-body seated position;
- `UPPER_SAFE` for both isometric side-press frames.

Mandatory:
- full head visible;
- full neck visible;
- both shoulders visible;
- active hand and contact point fully visible;
- free hand visible on the thigh;
- head remains level and centered;
- motion frames use matching crop and scale;
- red contact highlight remains inside the temple/hand contact area.

---

## 7. Production images

- `setup_full_safe.png`
- `motion_01_palm_to_left_temple_upper_safe.png`
- `motion_02_palm_to_right_temple_upper_safe.png`
- `preview.png`

Folder:
`assets/exercises/NECK_008/images/`

Runtime assets:
- contain no text;
- contain no arrows;
- contain no UI, logo, or watermark;
- may contain the approved soft red contact highlight because it communicates an otherwise invisible isometric effort.

`preview.png` currently duplicates the first side-press frame.

---

## 8. Mirror principle

For the visual brief, captions follow the **user's mirror interpretation**, while technical filenames remain anatomical to the model.

Therefore:
- `motion_01_palm_to_left_temple_upper_safe.png` → user caption **«Натискайте скронею в долоню справа.»**
- `motion_02_palm_to_right_temple_upper_safe.png` → user caption **«Натискайте скронею в долоню зліва.»**

Do not rename the production files to match mirror captions.

---

## 9. Documentation artifacts

- `docs/exercise_briefs/neck/NECK_008/NECK_008_BRIEF.md`
- `docs/exercise_briefs/neck/NECK_008/NECK_008_brief_sheet_v1.png`

The visual brief:
- follows the approved neck-series three-panel layout;
- uses the same `NECK_001` base model, outfit, chair, and background;
- uses no arrows;
- includes soft red contact highlighting on the two active isometric frames.

---

## 10. Audio

Exercise-specific Ukrainian cues:

`audio/uk/exercises/NECK_008/setup.m4a`  
Suggested text: `Сядьте рівно. Розслабте плечі. Дивіться прямо.`

`audio/uk/exercises/NECK_008/start_movement.m4a`  
Suggested text: `Прикладіть долоню до скроні. М’яко натискайте скронею в долоню, не нахиляючи голову. Потім змініть бік.`

Reusable common cues:
- `audio/uk/common/halfway.m4a` — `Половину виконано.`
- `audio/uk/common/completed.m4a` — `Готово.`

---

## 11. Safety / usability cues

- не тиснути сильно;
- не нахиляти голову вбік;
- не піднімати плечі;
- не затримувати дихання;
- зберігати голову по центру;
- зупинитися, якщо з’являється біль, виражений дискомфорт або запаморочення.

---

## 12. QA checklist

- [x] Setup frame uses the approved NECK_001 model and outfit.
- [x] Both side-press frames use the same model, clothing, chair, and background.
- [x] Two opposite temple-contact directions are visually distinct.
- [x] Head stays neutral without visible lateral movement.
- [x] Active contact zones use a soft red highlight.
- [x] Runtime images contain no text / arrows / UI / watermark.
- [x] Visual brief uses mirror-format user captions.
- [x] YAML paths match the real files.
