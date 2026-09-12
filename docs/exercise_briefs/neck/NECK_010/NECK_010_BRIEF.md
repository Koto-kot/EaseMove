# NECK_010 — Подвійне підборіддя біля стіни

**Document type:** Exercise Production Brief  
**Exercise ID:** `NECK_010`  
**Slug:** `standing_chin_tuck_at_wall`  
**Primary zone:** `neck`  
**Status:** `draft`  
**Asset status:** `images_included`  
**Difficulty:** starter / easy  
**Position:** standing  
**Movement type:** gentle standing chin tuck / cervical retraction at wall  
**Framing:** `FULL_SAFE` + `UPPER_SAFE`  
**Mirror interpretation:** `used in the visual brief layout`  
**Schema:** Exercise Schema v1.3

---

## 1. Суть вправи

Користувач стоїть біля стіни у нейтральному положенні, тримає спину й потилицю біля стіни та **м’яко відводить підборіддя назад**, не закидаючи голову і не опускаючи погляд. У результаті виникає легкий ефект “подвійного підборіддя”, що означає правильне втягування підборіддя назад.

Це базова вправа на м’який контроль положення голови, покращення постави та активацію глибоких м’язів шиї.

---

## 2. Стартове положення

- стати рівно біля стіни;
- спина витягнута;
- потилиця і верхня частина спини біля стіни;
- плечі розслаблені й опущені;
- руки вільно вздовж тіла;
- погляд прямо;
- підборіддя в нейтральному положенні.

---

## 3. Рух

### Phase A — wall neutral
Користувач стоїть біля стіни у нейтральному положенні, з рівною поставою, поглядом прямо та розслабленими плечима.

### Phase B — chin tuck at wall
З нейтрального положення користувач **м’яко відводить підборіддя назад** до шиї, немов створюючи «подвійне підборіддя». Голова не піднімається і не нахиляється вниз, а лише рухається назад у лінії погляду.

### Return logic
Після короткого утримання підборіддя плавно повертається у нейтральне положення.

### Canonical cycle
`wall neutral → chin tuck → neutral`

---

## 4. Виконавські підказки

- не закидати голову назад;
- не опускати підборіддя вниз;
- рух має бути невеликим і контрольованим;
- плечі не піднімаються;
- спина залишається рівною;
- погляд увесь час спрямований прямо;
- рух відбувається саме в шиї, а не через нахил усього корпусу.

---

## 5. Timing

- preparation countdown: `5 s`
- default active duration: `60 s`
- presets: `60 / 120 / 180 / 300 s`
- suggested hold / cycle: approximately `3–5 s`
- completion condition: elapsed active time
- pause freezes timer and animation
- Stop is available at any time
- normal completion → `10 s` rest before the next exercise

---

## 6. Framing

Use:
- `setup_full_safe.png` for the initial standing position;
- `motion_01_wall_neutral_full_safe.png` for the neutral full-body wall posture;
- `UPPER_SAFE` for the active chin-tuck frame so the neck retraction is clearly visible.

Mandatory:
- full body visible in setup and wall-neutral frame;
- full head visible;
- neck and shoulders clearly visible;
- the wall must remain readable in all frames;
- motion frame must clearly show the chin tuck difference from neutral;
- runtime images stay clean and consistent with the approved neck-series style.

---

## 7. Production images

- `setup_full_safe.png`
- `motion_01_wall_neutral_full_safe.png`
- `motion_02_wall_chin_tuck_upper_safe.png`
- `preview.png`

Folder:
`assets/exercises/NECK_010/images/`

Note:
- runtime images remain clean production assets;
- no text, no arrows, no UI, no watermark;
- `preview.png` currently duplicates the active chin-tuck frame as the clearest representative image.

---

## 8. Documentation artifacts

- `docs/exercise_briefs/neck/NECK_010/NECK_010_BRIEF.md`
- `docs/exercise_briefs/neck/NECK_010/NECK_010_brief_sheet_v1.png`

The visual brief for this exercise:
- keeps the same approved layout language as the previous neck briefs;
- uses the same woman/model identity and outfit family as the neck series;
- contains no arrows;
- shows a clear sequence: start, wall-neutral, chin tuck.

---

## 9. Audio

Exercise-specific Ukrainian cues:

`audio/uk/exercises/NECK_010/setup.m4a`  
Suggested text: `Станьте рівно біля стіни. Розслабте плечі. Дивіться прямо.`

`audio/uk/exercises/NECK_010/start_movement.m4a`  
Suggested text: `М’яко потягніть підборіддя назад, не закидаючи голову. Поверніться у нейтраль.`

Reusable common cues:
- `audio/uk/common/halfway.m4a` — `Половину виконано.`
- `audio/uk/common/completed.m4a` — `Готово.`

---

## 10. Safety / usability cues

- не робити рух через біль;
- не стискати щелепу;
- не затримувати дихання;
- не виконувати ривком;
- зупинитися, якщо з’являється виражений дискомфорт або запаморочення.

---

## 11. QA checklist

- [x] Setup frame exists.
- [x] Wall-neutral full-safe frame exists.
- [x] Active chin-tuck frame clearly differs from neutral.
- [x] Runtime images contain no text / arrows / UI / watermark.
- [x] Wall setup is clearly visible.
- [x] Visual brief follows the approved neck-sheet layout.
- [x] YAML paths match the real files.
