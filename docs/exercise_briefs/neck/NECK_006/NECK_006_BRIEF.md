# NECK_006 — Діагональний погляд вниз ліворуч — праворуч

**Document type:** Exercise Production Brief  
**Exercise ID:** `NECK_006`  
**Slug:** `seated_diagonal_head_down_left_right`  
**Primary zone:** `neck`  
**Status:** `draft`  
**Asset status:** `images_included`  
**Difficulty:** starter / easy  
**Position:** seated  
**Movement type:** gentle diagonal neck flexion with light rotation  
**Framing:** `FULL_SAFE` + `UPPER_SAFE`  
**Mirror interpretation:** `used in the visual brief layout`  
**Schema:** Exercise Schema v1.3

---

## 1. Суть вправи

Користувач сидить рівно у нейтральному положенні, після чого м’яко опускає голову і погляд **по діагоналі вліво**, повертається у центр, а потім **по діагоналі вправо**. Рух невеликий, плавний, контрольований, без ривків і без участі плечей.

Це базова вправа на м’яку рухливість шиї та зниження скутості після тривалого сидіння.

---

## 2. Стартове положення

- сісти рівно на стілець;
- стопи стійко стоять на підлозі;
- спина витягнута, таз стабільний;
- плечі розслаблені й опущені;
- руки лежать на стегнах;
- голова у нейтральному положенні;
- погляд прямо.

---

## 3. Рух

### Phase A — diagonal down left
З нейтрального положення користувач **м’яко опускає голову й погляд по діагоналі вліво**. Підборіддя рухається вниз і трохи вбік, без різкого скручування.

### Phase B — diagonal down right
Після повернення у центр користувач **м’яко опускає голову й погляд по діагоналі вправо**. Амплітуда залишається невеликою і комфортною.

### Return logic
Після кожного діагонального руху голова повертається у нейтральне центральне положення.

### Canonical cycle
`center → diagonal down left → center → diagonal down right → center`

---

## 4. Виконавські підказки

- рух починається плавно, без ривка;
- плечі не піднімаються і не тягнуться за головою;
- корпус не нахиляється;
- очі й голова рухаються разом у вибрану діагональ;
- не потрібно притискати підборіддя силою;
- амплітуда лише комфортна, без болю.

---

## 5. Timing

- preparation countdown: `5 s`
- default active duration: `60 s`
- presets: `60 / 120 / 180 / 300 s`
- suggested cycle: approximately `5–6 s`
- completion condition: elapsed active time
- pause freezes timer and animation
- Stop is available at any time
- normal completion → `10 s` rest before the next exercise

---

## 6. Framing

Use:
- `setup_full_safe.png` for the initial whole-body seated position;
- `UPPER_SAFE` for motion frames so the diagonal neck movement is readable.

Mandatory:
- full head visible;
- full neck visible;
- both shoulders visible;
- hands visible on thighs in motion frames;
- motion frames must use the same crop and scale;
- the two diagonal directions must be clearly different and readable.

---

## 7. Production images

- `setup_full_safe.png`
- `motion_01_diagonal_down_left_upper_safe.png`
- `motion_02_diagonal_down_right_upper_safe.png`
- `preview.png`

Folder:
`assets/exercises/NECK_006/images/`

Note:
- runtime images remain clean production assets;
- no text, no arrows, no UI, no watermark;
- `preview.png` currently duplicates the left-diagonal motion frame as the clearest representative image.

---

## 8. Documentation artifacts

- `docs/exercise_briefs/neck/NECK_006/NECK_006_BRIEF.md`
- `docs/exercise_briefs/neck/NECK_006/NECK_006_brief_sheet_v1.png`

The visual brief for this exercise:
- keeps the same approved layout language as the previous neck briefs;
- uses the same seated model identity and outfit as `NECK_001`;
- contains no arrows;
- shows a clean three-step sequence: start, diagonal left, diagonal right.

---

## 9. Audio

Exercise-specific Ukrainian cues:

`audio/uk/exercises/NECK_006/setup.m4a`  
Suggested text: `Сядьте рівно. Розслабте плечі. Дивіться прямо.`

`audio/uk/exercises/NECK_006/start_movement.m4a`  
Suggested text: `М’яко опустіть голову й погляд по діагоналі вліво. Поверніться у центр. Потім по діагоналі вправо.`

Reusable common cues:
- `audio/uk/common/halfway.m4a` — `Половину виконано.`
- `audio/uk/common/completed.m4a` — `Готово.`

---

## 10. Safety / usability cues

- не піднімати плечі;
- не скручувати корпус;
- не рухатися через біль;
- не виконувати різко;
- зупинитися, якщо з’являється виражений дискомфорт або запаморочення.

---

## 11. QA checklist

- [x] Setup frame is full body and readable.
- [x] Motion frames clearly show two opposite diagonal-down directions.
- [x] Shoulders remain relaxed and level.
- [x] Runtime images contain no text / arrows / UI / watermark.
- [x] Visual brief follows the approved neck-sheet layout.
- [x] YAML paths match the real files.
