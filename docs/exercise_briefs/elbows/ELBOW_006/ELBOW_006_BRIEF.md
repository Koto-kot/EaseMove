# ELBOW_006 — Кисті до плечей — вперед

**Document type:** Exercise Production Brief  
**Exercise ID:** `ELBOW_006`  
**Slug:** `seated_hands_to_shoulders_then_forward`  
**Primary zone:** `elbows`  
**Authoring language:** Ukrainian  
**Status:** `draft`  
**Asset status:** `images_included`  
**Difficulty:** easy / starter  
**Equipment:** stable chair  
**Position:** seated  
**Movement type:** bilateral elbow flexion to forward extension  
**Target audience:** generally healthy adults; simple everyday movement / wellbeing use  
**Brief version:** `0.1.0`

---

## 1. Purpose

Проста вправа для ліктів і рук без обладнання.

Людина сидить рівно на стільці. У положенні A кисті розташовані біля плечей, лікті зігнуті. Потім людина плавно випрямляє обидві руки вперед на рівні грудей або плечей. Після цього повертає кисті назад до плечей.

Ключове правило: рух виконується спокійно, без ривків, корпус залишається вертикальним, плечі не піднімаються.

---

## 2. Repository locations

Human brief:  
`docs/exercise_briefs/elbows/ELBOW_006/ELBOW_006_BRIEF.md`

Visual brief sheet:  
`docs/exercise_briefs/elbows/ELBOW_006/ELBOW_006_brief_sheet_v0.png`

Canonical YAML path:  
`data/exercises/elbows/ELBOW_006.yaml`

Production images folder:  
`assets/exercises/ELBOW_006/images/`

Exercise-specific audio:  
`audio/uk/exercises/ELBOW_006/`

Reusable common audio:  
`audio/uk/common/`

---

## 3. Classification

- primary zone: `elbows`
- secondary zones: `forearms`, `upper_arms`, `shoulders`
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
  - `forward_reach`
  - `beginner`
  - `gentle`
  - `chair`

---

## 4. Starting position

1. Сісти на стабільний стілець.
2. Корпус вертикальний, без нахилу.
3. Голова у нейтральному положенні, погляд уперед.
4. Плечі опущені та розслаблені.
5. Стопи повністю стоять на підлозі.
6. Коліна приблизно під прямим кутом.
7. Обидві кисті біля плечей.
8. Лікті зігнуті, верхні частини рук близько до тулуба.
9. Пальці розслаблені.
10. У руках немає предметів.

---

## 5. Movement

### Phase A — hands at shoulders
Кисті біля плечей. Лікті зігнуті. Плечі опущені. Корпус рівний.

### Phase B — arms forward
Плавно випрямити обидві руки вперед на рівні грудей або плечей. Лікті майже прямі, але не заблоковані. Долоні дивляться одна до одної або трохи вниз.

### Return
Повернути кисті назад до плечей і знову перейти в положення A.

### Canonical cycle
`A → B → A`

---

## 6. Timing

Recommended prototype behavior:

- preparation countdown: `5 s`
- default active duration: `60 s`
- user-selectable duration presets: `60 / 120 / 180 / 300 s`
- recommended visual cycle: approximately `4 s`
  - from shoulders forward: about `2 s`
  - return to shoulders: about `2 s`
- movement is continuous and comfortable
- completion basis: elapsed active time
- pause freezes timer and animation
- Stop is available at any moment
- standard rest after normal completion: `10 s`

---

## 7. Image system

### Canonical visual profile
`exercise_visual_v1`

### Canonical subject
`adult_neutral_01`

Use the approved reference character:
- adult woman of ordinary non-athletic build
- dark brown hair tied in a low bun
- lavender short-sleeve T-shirt
- dark plain trousers/leggings
- white plain trainers
- calm neutral-friendly facial expression
- no logos
- no medical clothing

### Prop
Same light wooden stable chair throughout the exercise.

### Background
Clean light neutral background, soft even lighting, minimal environment.

### No embedded graphics
Production exercise images must contain:
- no text
- no arrows
- no numbers
- no highlighted joints
- no UI
- no badges
- no logo
- no watermark

---

## 8. Required images and exact filenames

- `assets/exercises/ELBOW_006/images/setup_full_safe.png`
- `assets/exercises/ELBOW_006/images/motion_01_hands_at_shoulders_mid_safe.png`
- `assets/exercises/ELBOW_006/images/motion_02_arms_forward_mid_safe.png`
- `assets/exercises/ELBOW_006/images/preview.png`

Setup frame:
- FULL
- shows complete seated starting position with кисті біля плечей

Motion frames:
- UPPER
- same crop and same camera angle
- only arm position changes materially

---

## 9. Image sequence

Setup before Start:
`setup_full_safe.png`

Animation loop after countdown:
`motion_01_hands_at_shoulders_mid_safe.png → motion_02_arms_forward_mid_safe.png → motion_01_hands_at_shoulders_mid_safe.png`

---

## 10. Voice accompaniment

### Exercise-specific setup cue
**Text:**  
`Сядьте рівно. Кисті біля плечей.`

**Target file:**  
`audio/uk/exercises/ELBOW_006/setup.m4a`

### Exercise-specific start cue
**Text:**  
`Плавно випряміть обидві руки вперед і поверніть назад до плечей.`

**Target file:**  
`audio/uk/exercises/ELBOW_006/start_movement.m4a`

### Reusable common halfway cue
`audio/uk/common/halfway.m4a`  
Text: `Половину виконано.`

### Reusable completion cue
`audio/uk/common/completed.m4a`  
Text: `Готово.`

Recording style:
- calm
- friendly
- clear
- unhurried

---

## 11. Accessibility

Suggested Ukrainian screen-reader summary:

`Кисті до плечей — вперед. Сидячи на стільці, починайте з кистями біля плечей, плавно випрямляйте обидві руки вперед і поверніть їх назад.`

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
- [ ] Кисті в старті біля плечей.
- [ ] Усі motion frames мають однаковий crop і camera angle.
- [ ] Руки вперед на зрозумілу відстань.
- [ ] Плечі не піднімаються.
- [ ] Немає тексту / стрілок / UI / watermark.
- [ ] Exercise-specific audio paths визначені.
- [ ] Common cues reused.
- [ ] 5-second prep countdown works.
- [ ] Pause/Stop flow works.
- [ ] Normal completion starts 10-second rest.

---

## 14. Files expected before production-ready state

Required:
- `docs/exercise_briefs/elbows/ELBOW_006/ELBOW_006_BRIEF.md`
- `docs/exercise_briefs/elbows/ELBOW_006/ELBOW_006_brief_sheet_v0.png`
- `data/exercises/elbows/ELBOW_006.yaml`
- `assets/exercises/ELBOW_006/images/setup_full_safe.png`
- `assets/exercises/ELBOW_006/images/motion_01_hands_at_shoulders_mid_safe.png`
- `assets/exercises/ELBOW_006/images/motion_02_arms_forward_mid_safe.png`
- `assets/exercises/ELBOW_006/images/preview.png`
- `audio/uk/exercises/ELBOW_006/setup.m4a`
- `audio/uk/exercises/ELBOW_006/start_movement.m4a`

Referenced common assets:
- `audio/uk/common/halfway.m4a`
- `audio/uk/common/completed.m4a`
