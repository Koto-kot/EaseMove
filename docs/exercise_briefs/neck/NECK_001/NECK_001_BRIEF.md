# NECK_001 — Підборіддя назад

**Document type:** Exercise Production Brief  
**Exercise ID:** `NECK_001`  
**Slug:** `seated_chin_tuck`  
**Primary zone:** `neck`  
**Status:** `draft`  
**Asset status:** `images_included`  
**Difficulty:** starter / easy  
**Position:** seated  
**Movement type:** gentle cervical alignment / chin retraction  
**Framing:** `FULL_SAFE` + `UPPER_SAFE`  
**Schema:** Exercise Schema v1.3

---

## 1. Суть вправи

Користувач сидить рівно на стільці і м’яко відводить підборіддя назад, не нахиляючи голову вниз. Рух невеликий і контрольований: нейтральне положення → підборіддя назад → повернення у нейтраль.

Це базова вправа для м’якої активації та усвідомлення положення шиї.

---

## 2. Стартове положення

- сісти рівно на стілець;
- стопи стійко на підлозі;
- плечі розслаблені;
- голова прямо, погляд горизонтальний;
- руки спокійно розташовані вздовж тіла або на стегнах.

---

## 3. Рух

### Phase A — neutral
Нейтральне положення голови й шиї.

### Phase B — chin tuck
М’яко відвести підборіддя назад. Важливо: рух **назад, не вниз**.

### Return
Плавно повернутися у Phase A.

### Canonical cycle
`A → B → A`

---

## 4. Timing

- preparation countdown: `5 s`
- default active duration: `60 s`
- presets: `60 / 120 / 180 / 300 s`
- suggested cycle: approximately `4–5 s`
- completion condition: elapsed active time
- pause freezes timer and animation
- Stop is available at any time
- normal completion → `10 s` rest before the next exercise

---

## 5. Framing

Use:
- `setup_full_safe.png` for the initial whole-body seated position;
- `UPPER_SAFE` for motion frames because the neck movement is subtle and must be clearly readable.

Mandatory:
- head fully visible;
- neck fully visible;
- shoulders visible;
- do not crop through the active movement path;
- motion frames must share the same camera angle and nearly the same crop.

---

## 6. Production images

- `setup_full_safe.png`
- `motion_01_chin_forward_neutral_upper_safe.png`
- `motion_02_chin_tuck_upper_safe.png`
- `preview.png`

Folder:
`assets/exercises/NECK_001/images/`

---

## 7. Audio

Exercise-specific Ukrainian cues:

`audio/uk/exercises/NECK_001/setup.m4a`  
Suggested text: `Сядьте рівно. Розслабте плечі. Дивіться прямо.`

`audio/uk/exercises/NECK_001/start_movement.m4a`  
Suggested text: `М’яко відведіть підборіддя назад. Не нахиляйте голову вниз. Поверніться у звичайне положення.`

Reusable common cues:
- `audio/uk/common/halfway.m4a` — `Половину виконано.`
- `audio/uk/common/completed.m4a` — `Готово.`

---

## 8. Safety / usability cues

- рух має бути малим і контрольованим;
- не закидати голову;
- не нахиляти голову вниз під час руху назад;
- не піднімати плечі;
- зупинитися, якщо з’являється біль або виражений дискомфорт.

---

## 9. QA checklist

- [ ] Setup frame is full body and readable.
- [ ] Neck movement is clearly visible in profile.
- [ ] Motion direction is backward, not downward.
- [ ] Runtime images contain no text / arrows / UI / watermark.
- [ ] Visual brief sheet includes the directional clarification arrow.
- [ ] YAML paths match the real files.
