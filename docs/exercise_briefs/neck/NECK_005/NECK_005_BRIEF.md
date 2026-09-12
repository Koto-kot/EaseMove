# NECK_005 — Легкий погляд вгору — нейтраль

**Document type:** Exercise Production Brief  
**Exercise ID:** `NECK_005`  
**Slug:** `seated_head_up_neutral`  
**Primary zone:** `neck`  
**Status:** `draft`  
**Asset status:** `images_included`  
**Difficulty:** starter / easy  
**Position:** seated  
**Movement type:** gentle cervical extension to neutral  
**Framing:** `FULL_SAFE` + `UPPER_SAFE`  
**Mirror interpretation:** `not applicable`  
**Schema:** Exercise Schema v1.3

---

## 1. Суть вправи

Користувач сидить рівно у нейтральному положенні, **злегка піднімає підборіддя та погляд угору**, а потім плавно повертається у нейтраль. Рух невеликий і комфортний: це не сильне закидання голови назад.

Вправа належить до базових м’яких рухів для шиї та добре підходить для коротких щоденних рухових пауз.

---

## 2. Стартове положення

- сісти рівно на стілець;
- стопи стійко стоять на підлозі;
- таз стабільний;
- спина витягнута, без прогину назад;
- плечі розслаблені й опущені;
- руки лежать на стегнах;
- голова у нейтральному положенні;
- погляд прямо.

---

## 3. Рух

### Phase A — neutral
Голова у нейтральному положенні, шия витягнута, погляд прямо.

### Phase B — slightly up
Користувач **м’яко піднімає підборіддя і погляд трохи вгору**. Амплітуда мала; шия не повинна різко заламуватися назад.

### Return logic
Після короткого контрольованого підйому голова плавно повертається у нейтральне положення.

### Canonical cycle
`neutral → slightly up → neutral`

---

## 4. Виконавські підказки

- рух виконується повільно й без ривків;
- плечі залишаються опущеними;
- корпус не відхиляється назад;
- не потрібно сильно закидати голову;
- погляд спрямовується трохи вгору разом із рухом голови;
- амплітуда тільки комфортна.

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
- `UPPER_SAFE` for neutral and upward motion frames.

Mandatory:
- full head visible;
- full neck visible;
- both shoulders visible;
- enough room above the head for the upward movement;
- neutral and motion frames should use compatible scale;
- upward frame must show a **small** increase in head extension, not an exaggerated backbend.

---

## 7. Production images

- `setup_full_safe.png`
- `motion_01_head_neutral_upper_safe.png`
- `motion_02_head_slightly_up_upper_safe.png`
- `preview.png`

Folder:  
`assets/exercises/NECK_005/images/`

Runtime rules:
- no text;
- no arrows;
- no UI;
- no logos;
- no watermark.

---

## 8. Documentation artifacts

- `docs/exercise_briefs/neck/NECK_005/NECK_005_BRIEF.md`
- `docs/exercise_briefs/neck/NECK_005/NECK_005_brief_sheet_v1.png`

The visual brief uses the same three-block structure as previous neck exercises:
1. старт / `FULL_SAFE`;
2. neutral / `UPPER_SAFE`;
3. slight look up / `UPPER_SAFE`.

---

## 9. Audio

Exercise-specific Ukrainian cues:

`audio/uk/exercises/NECK_005/setup.m4a`  
Suggested text: `Сядьте рівно. Розслабте плечі. Дивіться прямо.`

`audio/uk/exercises/NECK_005/start_movement.m4a`  
Suggested text: `М’яко підніміть підборіддя і погляд трохи вгору. Потім поверніться у нейтраль.`

Reusable common cues:
- `audio/uk/common/halfway.m4a` — `Половину виконано.`
- `audio/uk/common/completed.m4a` — `Готово.`

---

## 10. Safety / usability cues

- не закидати голову різко назад;
- не прогинати корпус разом із головою;
- не піднімати плечі;
- виконувати тільки у комфортній амплітуді;
- зупинитися, якщо з’являється біль, виражений дискомфорт або запаморочення.

---

## 11. QA checklist

- [x] Setup frame exists and follows `FULL_SAFE`.
- [x] Neutral frame exists and follows `UPPER_SAFE`.
- [x] Upward motion frame clearly communicates a gentle upward look.
- [x] Runtime images contain no text / arrows / UI / watermark.
- [x] Visual brief sheet exists.
- [x] YAML paths match the included files.
