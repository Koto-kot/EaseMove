# NECK_004 — Погляд вниз — нейтраль

**Document type:** Exercise Production Brief  
**Exercise ID:** `NECK_004`  
**Slug:** `seated_head_nod_down_neutral`  
**Primary zone:** `neck`  
**Status:** `draft`  
**Asset status:** `images_included`  
**Difficulty:** starter / easy  
**Position:** seated  
**Movement type:** gentle cervical flexion to neutral  
**Framing:** `FULL_SAFE` + `UPPER_SAFE`  
**Mirror interpretation:** `format kept for consistency; left/right labeling not needed`  
**Schema:** Exercise Schema v1.3

---

## 1. Суть вправи

Користувач сидить рівно у нейтральному положенні, м’яко опускає голову і погляд вниз, а потім повертається у нейтраль. Рух невеликий, контрольований, без ривків і без округлення плечей.

Це базова вправа на м’яку рухливість шиї, що добре підходить для спокійної щоденної практики.

---

## 2. Стартове положення

- сісти рівно на стілець;
- стопи стійко стоять на підлозі;
- таз стабільний, спина витягнута;
- плечі розслаблені й опущені;
- руки лежать на стегнах;
- голова у нейтральному положенні;
- погляд прямо.

---

## 3. Рух

### Phase A — neutral
Початковий руховий кадр: голова у нейтральному положенні, шия витягнута, погляд прямо.

### Phase B — look down
З нейтрального положення користувач **м’яко опускає голову і погляд вниз**. Підборіддя рухається вниз у комфортному діапазоні, але без різкого притискання до грудей.

### Return logic
Після короткого контрольованого опускання голова плавно повертається у нейтральне положення.

### Canonical cycle
`neutral → down → neutral`

---

## 4. Виконавські підказки

- рух починається спокійно, без ривка;
- плечі залишаються нерухомими та розслабленими;
- корпус не нахиляється вперед;
- не потрібно тягнути голову силою вниз;
- амплітуда м’яка, комфортна, без болю.

Для цієї вправи **дзеркальний формат збережено лише як формат visual brief**, але спеціальних left/right-позначок не потрібно, бо рух не є латеральним.

---

## 5. Timing

- preparation countdown: `5 s`
- default active duration: `60 s`
- presets: `60 / 120 / 180 / 300 s`
- suggested cycle: approximately `4–5 s`
- completion condition: elapsed active time
- pause freezes timer and animation
- Stop is available at any time
- normal completion → `10 s` rest before the next exercise

---

## 6. Framing

Use:
- `setup_full_safe.png` for the initial whole-body seated position;
- `UPPER_SAFE` for motion frames so the neck movement is readable.

Mandatory:
- full head visible;
- full neck visible;
- both shoulders visible;
- hands visible on thighs in motion frames;
- the motion frames must use the same crop and scale;
- head-down frame must clearly show the lowered gaze and gentle neck flexion.

---

## 7. Production images

- `setup_full_safe.png`
- `motion_01_head_neutral_upper_safe.png`
- `motion_02_head_down_upper_safe.png`
- `preview.png`

Folder:
`assets/exercises/NECK_004/images/`

Note:
- runtime images stay clean and contain no text;
- no arrows, UI, logos, or watermark;
- `preview.png` currently duplicates the neutral motion frame as the clearest representative image.

---

## 8. Documentation artifacts

- `docs/exercise_briefs/neck/NECK_004/NECK_004_BRIEF.md`
- `docs/exercise_briefs/neck/NECK_004/NECK_004_brief_sheet_v1.png`

The visual brief for this exercise:
- keeps the same layout language as `NECK_001–NECK_003`;
- uses the same seated model identity;
- contains no arrows;
- explains the movement as `neutral → look down`.

---

## 9. Audio

Exercise-specific Ukrainian cues:

`audio/uk/exercises/NECK_004/setup.m4a`  
Suggested text: `Сядьте рівно. Розслабте плечі. Дивіться прямо.`

`audio/uk/exercises/NECK_004/start_movement.m4a`  
Suggested text: `З нейтрального положення м’яко опустіть голову й погляд вниз. Потім поверніться у нейтраль.`

Reusable common cues:
- `audio/uk/common/halfway.m4a` — `Половину виконано.`
- `audio/uk/common/completed.m4a` — `Готово.`

---

## 10. Safety / usability cues

- не рухати плечима вперед разом із головою;
- не сутулитися;
- не притискати підборіддя силою до грудей;
- рух має бути плавним і комфортним;
- зупинитися, якщо з’являється біль або виражений дискомфорт.

---

## 11. QA checklist

- [x] Setup frame is full body and readable.
- [x] Motion frames clearly show `neutral` and `look down`.
- [x] Shoulders remain relaxed and level.
- [x] Runtime images contain no text / arrows / UI / watermark.
- [x] Visual brief follows the approved neck-sheet layout.
- [x] YAML paths match the real files.
