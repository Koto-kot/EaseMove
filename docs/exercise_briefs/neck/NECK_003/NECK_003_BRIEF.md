# NECK_003 — Нахил голови до плеча

**Document type:** Exercise Production Brief  
**Exercise ID:** `NECK_003`  
**Slug:** `seated_ear_to_shoulder`  
**Primary zone:** `neck`  
**Status:** `draft`  
**Asset status:** `images_included`  
**Difficulty:** starter / easy  
**Position:** seated  
**Movement type:** gentle lateral neck flexion  
**Framing:** `FULL_SAFE` + `UPPER_SAFE`  
**Mirror interpretation:** `enabled for visual brief labeling`  
**Schema:** Exercise Schema v1.3

---

## 1. Суть вправи

Користувач сидить рівно та плавно нахиляє голову в один бік, повертається у центр, а потім у другий бік. Рух м’який, контрольований, без ривків. Плечі залишаються розслабленими і не піднімаються.

Це базова вправа на м’яку рухливість шиї.

---

## 2. Стартове положення

- сісти рівно на стілець;
- стопи стійко на підлозі;
- плечі розслаблені;
- голова у нейтральному положенні;
- погляд прямо;
- руки лежать на стегнах.

---

## 3. Рух

### Phase A — tilt right (mirror label)
У **дзеркальному форматі показу** це кадр, який користувач сприймає як: **«Нахиліть голову вправо»**. Саме цей кадр використовується як перший руховий кадр у visual brief.

### Phase B — tilt left (mirror label)
У **дзеркальному форматі показу** це кадр, який користувач сприймає як: **«Нахиліть голову вліво»**.

### Return logic
Після кожного нахилу голова повертається у нейтральне центральне положення.

### Canonical cycle
`center → right → center → left → center`

---

## 4. Дзеркальний принцип підписів

Для деяких фронтальних вправ на шию користувач дивиться на модель так, ніби бачить себе у дзеркалі. Тому підпис у visual brief має відповідати **тому, як це бачить користувач**, а не лише анатомічному напрямку моделі.

Для `NECK_003`:
- середній кадр підписується: **«Нахиліть голову вправо.»**
- правий кадр підписується: **«Нахиліть голову вліво.»**

Це правило використано в `NECK_003_brief_sheet_v1.png`.

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
- `UPPER_SAFE` for motion frames so the side-bend of the neck is easy to read.

Mandatory:
- head fully visible;
- neck fully visible;
- shoulders visible;
- shoulders should remain level and relaxed in motion frames;
- motion frames must use the same crop and scale;
- do not crop through the active movement path.

---

## 7. Production images

- `setup_full_safe.png`
- `motion_01_ear_to_left_shoulder_upper_safe.png`
- `motion_02_ear_to_right_shoulder_upper_safe.png`
- `preview.png`

Folder:
`assets/exercises/NECK_003/images/`

Note:
- runtime image filenames stay anatomical / technical;
- visual-brief captions may use the mirror interpretation for user clarity.

---

## 8. Documentation artifacts

- `docs/exercise_briefs/neck/NECK_003/NECK_003_BRIEF.md`
- `docs/exercise_briefs/neck/NECK_003/NECK_003_brief_sheet_v1.png`

The visual brief for this exercise:
- uses **no arrows** in the final approved version;
- uses **mirror-style text labels** for left/right user interpretation.

---

## 9. Audio

Exercise-specific Ukrainian cues:

`audio/uk/exercises/NECK_003/setup.m4a`  
Suggested text: `Сядьте рівно. Розслабте плечі. Дивіться прямо.`

`audio/uk/exercises/NECK_003/start_movement.m4a`  
Suggested text: `Плавно нахиліть голову вправо. Поверніться у центр. Потім нахиліть голову вліво.`

Reusable common cues:
- `audio/uk/common/halfway.m4a` — `Половину виконано.`
- `audio/uk/common/completed.m4a` — `Готово.`

---

## 10. Safety / usability cues

- не піднімати плечі;
- не обертати голову під час нахилу;
- рух має бути плавним, без ривків;
- не тиснути рукою на голову;
- зупинитися, якщо з’являється біль або виражений дискомфорт.

---

## 11. QA checklist

- [ ] Setup frame is full body and readable.
- [ ] Motion frames clearly show two opposite side bends.
- [ ] Shoulders remain relaxed and level.
- [ ] Runtime images contain no text / arrows / UI / watermark.
- [ ] Visual brief uses mirror-format user labels.
- [ ] YAML paths match the real files.
