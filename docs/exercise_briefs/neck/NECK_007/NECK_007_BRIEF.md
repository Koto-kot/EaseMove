# NECK_007 — Ізометрія долонею в лоб

**Document type:** Exercise Production Brief  
**Exercise ID:** `NECK_007`  
**Slug:** `seated_isometric_palm_forehead`  
**Primary zone:** `neck`  
**Status:** `draft`  
**Asset status:** `images_included`  
**Difficulty:** starter / easy  
**Position:** seated  
**Movement type:** gentle isometric neck activation in flexion direction  
**Framing:** `FULL_SAFE` + `UPPER_SAFE`  
**Mirror interpretation:** `used in the visual brief layout`  
**Schema:** Exercise Schema v1.3

---

## 1. Суть вправи

Користувач сидить рівно у нейтральному положенні, кладе долоню на лоб і **м’яко створює зустрічний опір** без помітного руху голови. Це ізометрична вправа: долоня тисне на лоб, а голова легко протидіє, залишаючись майже нерухомою.

Це базова вправа на м’яку активацію м’язів шиї та покращення контролю положення голови.

---

## 2. Стартове положення

- сісти рівно на стілець;
- стопи стійко стоять на підлозі;
- спина витягнута, таз стабільний;
- плечі розслаблені й опущені;
- голова у нейтральному положенні;
- погляд прямо;
- одна рука лежить на стегні, інша готується до контакту з лобом.

---

## 3. Рух

### Phase A — palm to forehead
З нейтрального положення користувач **кладе долоню на центр лоба**. Лікоть вільно зігнутий, плечі розслаблені, голова залишається рівною.

### Phase B — isometric forehead press
Користувач **м’яко натискає лобом у долоню**, а долонею створює зустрічний опір. Видимого руху голови майже немає: це утримання в нейтральному положенні.

### Return logic
Після короткого утримання напругу послаблюють і повертаються у нейтральну позицію.

### Canonical cycle
`neutral → palm to forehead → gentle isometric press → release → neutral`

---

## 4. Виконавські підказки

- не тиснути сильно;
- голова не відхиляється назад і не нахиляється вперед;
- плечі залишаються розслабленими;
- дихання спокійне;
- напруга м’яка, контрольована, без болю;
- долоня лише створює легкий опір, а не штовхає голову різко.

---

## 5. Timing

- preparation countdown: `5 s`
- default active duration: `60 s`
- presets: `60 / 120 / 180 / 300 s`
- suggested effort per repetition: approximately `3–5 s`
- completion condition: elapsed active time
- pause freezes timer and animation
- Stop is available at any time
- normal completion → `10 s` rest before the next exercise

---

## 6. Framing

Use:
- `setup_full_safe.png` for the initial whole-body seated position;
- `UPPER_SAFE` for motion frames so hand placement and neck position are clearly visible.

Mandatory:
- full head visible;
- full neck visible;
- both shoulders visible;
- active hand fully visible on the forehead;
- non-active hand visible on the thigh;
- motion frames must use the same crop and scale;
- isometric action must read clearly even though head movement is minimal.

---

## 7. Production images

- `setup_full_safe.png`
- `motion_01_palm_to_forehead_upper_safe.png`
- `motion_02_isometric_forehead_press_upper_safe.png`
- `preview.png`

Folder:
`assets/exercises/NECK_007/images/`

Note:
- runtime images remain clean production assets;
- no text, no arrows, no UI, no watermark;
- `preview.png` currently duplicates the palm-to-forehead frame as the clearest representative image.

---

## 8. Documentation artifacts

- `docs/exercise_briefs/neck/NECK_007/NECK_007_BRIEF.md`
- `docs/exercise_briefs/neck/NECK_007/NECK_007_brief_sheet_v1.png`

The visual brief for this exercise:
- keeps the same approved layout language as the previous neck briefs;
- uses the same seated model identity and outfit as `NECK_001`;
- contains no arrows;
- shows a clean three-step sequence: start, hand placement, isometric press; the active press frame may use a slightly larger and more visible soft red contact highlight on the forehead to distinguish the effort phase.

---

## 9. Audio

Exercise-specific Ukrainian cues:

`audio/uk/exercises/NECK_007/setup.m4a`  
Suggested text: `Сядьте рівно. Розслабте плечі. Дивіться прямо.`

`audio/uk/exercises/NECK_007/start_movement.m4a`  
Suggested text: `Покладіть долоню на лоб. М’яко натискайте лобом у долоню, не рухаючи головою.`

Reusable common cues:
- `audio/uk/common/halfway.m4a` — `Половину виконано.`
- `audio/uk/common/completed.m4a` — `Готово.`

---

## 10. Safety / usability cues

- не затримувати дихання;
- не тиснути занадто сильно;
- не піднімати плечі;
- не виконувати через біль;
- зупинитися, якщо з’являється дискомфорт або запаморочення.

---

## 11. QA checklist

- [x] Setup frame is full body and readable.
- [x] Motion frame A clearly shows palm placement on the forehead.
- [x] Motion frame B shows the gentle isometric press position.
- [x] The effort/contact point is visually readable with a slightly larger soft red highlight.
- [x] Runtime images contain no text / arrows / UI / watermark.
- [x] Visual brief follows the approved neck-sheet layout.
- [x] YAML paths match the real files.
