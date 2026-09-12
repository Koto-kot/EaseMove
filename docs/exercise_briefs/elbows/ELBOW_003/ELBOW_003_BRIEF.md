# ELBOW_003 — Згинання рук долонями всередину

**Document type:** Exercise Production Brief  
**Exercise ID:** `ELBOW_003`  
**Slug:** `seated_elbow_flexion_palms_in`  
**Primary zone:** `elbows`  
**Authoring language:** Ukrainian  
**Status:** `draft`  
**Equipment:** stable chair  
**Position:** seated  
**Brief version:** `0.1.0`

---

## 1. Purpose

Людина сидить рівно на стільці. Обидві руки рухаються одночасно: з положення вздовж тулуба руки згинаються в ліктях, а долоні/кулаки залишаються повернутими всередину. Це м’який варіант згинання рук із нейтральним положенням кисті.

---

## 2. Repository locations

Human brief:  
`docs/exercise_briefs/elbows/ELBOW_003/ELBOW_003_BRIEF.md`

Visual brief sheet:  
`docs/exercise_briefs/elbows/ELBOW_003/ELBOW_003_brief_sheet_v0.png`

Canonical YAML path:  
`data/exercises/elbows/ELBOW_003.yaml`

Production images folder:  
`assets/exercises/ELBOW_003/images/`

Exercise-specific audio:  
`audio/uk/exercises/ELBOW_003/`

Reusable common audio:  
`audio/uk/common/`

---

## 3. Classification

- primary zone: `elbows`
- body-map hotspots: `left_elbow`, `right_elbow`
- collections:
  - `body_elbows`
  - `seated_gentle`
  - `computer_break`
  - `after_sitting`
- tags:
  - `elbows`
  - `arms`
  - `sitting`
  - `mobility`
  - `bilateral`
  - `palms_in`
  - `beginner`
  - `gentle`
  - `no_resistance`
  - `chair`

---

## 4. Starting position

- Сісти на стабільний стілець.
- Корпус вертикальний, без нахилу.
- Голова в нейтральному положенні, погляд уперед.
- Плечі опущені та розслаблені.
- Стопи повністю стоять на підлозі.
- Коліна приблизно під прямим кутом.
- Руки розташовані вздовж тулуба.
- У руках немає предметів.

---

## 5. Movement

### Phase A — neutral palms inward
Обидві руки опущені вздовж тулуба. Кисті розташовані в нейтральному положенні — долонями всередину.

### Phase B — elbows flexed, palms inward
Обидві руки одночасно згинаються в ліктях. Передпліччя піднімаються, а долоні / кулаки весь час залишаються повернутими всередину.

### Return
Плавно повернутися до вихідного положення.

Canonical sequence:  
`neutral_palms_in → flexed_palms_in → neutral_palms_in`



---

## 6. Timing

Recommended prototype behavior:

- preparation countdown: `5 s`
- default active duration: `60 s`
- user-selectable duration presets: `60 / 120 / 180 / 300 s`
- movement tempo: comfortable and unhurried
- completion basis: elapsed active time
- pause freezes timer and animation
- Stop is available at any time
- standard rest after normal completion: `10 s`

---

## 7. Required images and exact filenames

- `assets/exercises/ELBOW_003/images/setup_full_safe.png`
- `assets/exercises/ELBOW_003/images/motion_01_neutral_palms_in_mid_safe.png`
- `assets/exercises/ELBOW_003/images/motion_02_flexed_palms_in_mid_safe.png`
- `assets/exercises/ELBOW_003/images/preview.png`

Rules:
- `setup_full_safe.png` shows the complete initial body position
- motion frames use the same crop and camera
- no text, no arrows, no UI, no watermarks
- same subject, clothes, chair, lighting and rendering style on all images

---

## 8. Image notes

- Visual style: clean semi-realistic health-app illustration
- Character: `adult_neutral_01`
- Lavender T-shirt, dark leggings/trousers, white trainers
- Light wooden chair with beige upholstered seat/back
- Light neutral background
- Soft even lighting

---

## 9. Voice accompaniment

Exercise-specific:
- `audio/uk/exercises/ELBOW_003/setup.m4a`  
  Text: “Сядьте рівно. Руки опустіть уздовж тулуба. Долоні всередину.”
- `audio/uk/exercises/ELBOW_003/start_movement.m4a`  
  Text: “Зігніть обидві руки в ліктях і плавно розігніть.”

Reusable common:
- `audio/uk/common/halfway.m4a` — “Половину виконано.”
- `audio/uk/common/completed.m4a` — “Готово.”

Recording style:
- calm
- friendly
- clear
- unhurried

---

## 10. Music

Global music profile:
- `gentle_rhythm_01`
- instrumental
- loopable
- no vocals
- voice = 100%
- music = 50% relative to voice
- ducking = off

---

## 11. Accessibility

Suggested Ukrainian screen-reader summary:

`Згинання рук долонями всередину. Сидячи на стільці, одночасно згинайте обидві руки в ліктях і поверніться у вихідне положення, зберігаючи долоні всередину.`

Reduced motion mode may show only the static motion positions without smooth interpolation.

---

## 12. Tracking

Recommended tracking:
- actual active seconds
- completed session
- early stop
- pause count
- selected collection
- lifetime exercise counter increment on normal completion

---

## 13. QA checklist

- [ ] Назва відповідає руху.
- [ ] Візуально зрозуміло, яка рука або обидві руки рухаються.
- [ ] Немає гантелей, еспандерів чи іншого опору.
- [ ] Setup frame показує повне положення тіла.
- [ ] Усі motion frames мають однаковий crop і camera angle.
- [ ] Змінюється тільки потрібне положення рук.
- [ ] Немає text / arrows / UI / watermark.
- [ ] Exercise-specific audio paths визначені.
- [ ] Common cues reused, not duplicated.
- [ ] 5-second prep countdown works.
- [ ] Pause/Stop flow works.
- [ ] Normal completion starts 10-second rest.

---

## 14. Files expected before production-ready state

Required:
- `docs/exercise_briefs/elbows/ELBOW_003/ELBOW_003_BRIEF.md`
- `docs/exercise_briefs/elbows/ELBOW_003/ELBOW_003_brief_sheet_v0.png`
- `data/exercises/elbows/ELBOW_003.yaml`
- `assets/exercises/ELBOW_003/images/setup_full_safe.png`
- `assets/exercises/ELBOW_003/images/motion_01_neutral_palms_in_mid_safe.png`
- `assets/exercises/ELBOW_003/images/motion_02_flexed_palms_in_mid_safe.png`
- `assets/exercises/ELBOW_003/images/preview.png`
- `audio/uk/exercises/ELBOW_003/setup.m4a`
- `audio/uk/exercises/ELBOW_003/start_movement.m4a`

Referenced common assets:
- `audio/uk/common/halfway.m4a`
- `audio/uk/common/completed.m4a`
