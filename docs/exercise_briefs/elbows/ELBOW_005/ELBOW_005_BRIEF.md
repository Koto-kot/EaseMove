# ELBOW_005 — Долоні вгору — вниз

**Document type:** Exercise Production Brief  
**Exercise ID:** `ELBOW_005`  
**Slug:** `seated_forearm_rotation_palms_up_down`  
**Primary zone:** `elbows`  
**Authoring language:** Ukrainian  
**Status:** `draft`  
**Asset status:** `images_included`  
**Difficulty:** easy / starter  
**Equipment:** stable chair  
**Position:** seated  
**Movement type:** forearm rotation with elbows flexed  
**Target audience:** generally healthy adults; simple everyday movement / wellbeing use  
**Brief version:** `0.1.0`

---

## 1. Purpose

Проста вправа для ліктів і передпліч без обладнання.

Людина сидить рівно на стільці. Верхні частини рук залишаються біля тулуба, лікті зігнуті приблизно на 90°, передпліччя спрямовані вперед. У положенні A долоні дивляться вгору. Потім людина плавно повертає передпліччя так, щоб долоні дивилися вниз. Після цього повертається у вихідне положення долонями вгору.

Ключове правило: лікті лишаються біля тулуба, а рух відбувається лише передпліччями.

---

## 2. Repository locations

Human brief:  
`docs/exercise_briefs/elbows/ELBOW_005/ELBOW_005_BRIEF.md`

Visual brief sheet:  
`docs/exercise_briefs/elbows/ELBOW_005/ELBOW_005_brief_sheet_v0.png`

Canonical YAML path:  
`data/exercises/elbows/ELBOW_005.yaml`

Production images folder:  
`assets/exercises/ELBOW_005/images/`

Exercise-specific audio:  
`audio/uk/exercises/ELBOW_005/`

Reusable common audio:  
`audio/uk/common/`

---

## 3. Classification

- primary zone: `elbows`
- secondary zones: `forearms`
- body-map hotspots: `left_elbow`, `right_elbow`
- collections:
  - `body_elbows`
  - `seated_gentle`
  - `computer_break`
  - `after_sitting`
- tags:
  - `elbows`
  - `forearms`
  - `sitting`
  - `mobility`
  - `bilateral`
  - `palms_up`
  - `palms_down`
  - `rotation`
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
7. Верхні частини рук біля тулуба.
8. Лікті зігнуті приблизно на 90°.
9. Передпліччя спрямовані вперед.
10. У позиції A долоні дивляться вгору.

---

## 5. Movement

### Phase A — palms up
Лікті біля тулуба. Передпліччя вперед. Долоні дивляться вгору.

### Phase B — palms down
Не змінюючи положення плечей і ліктів, плавно повернути передпліччя так, щоб долоні дивилися вниз.

### Return
Повернутися до положення долонями вгору.

### Canonical cycle
`A → B → A`

---

## 6. Timing

Recommended prototype behavior:

- preparation countdown: `5 s`
- default active duration: `60 s`
- user-selectable duration presets: `60 / 120 / 180 / 300 s`
- recommended visual cycle: approximately `4 s`
  - palms up to palms down: about `2 s`
  - palms down to palms up: about `2 s`
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

- `assets/exercises/ELBOW_005/images/setup_full_safe.png`
- `assets/exercises/ELBOW_005/images/motion_01_palms_up_mid_safe.png`
- `assets/exercises/ELBOW_005/images/motion_02_palms_down_mid_safe.png`
- `assets/exercises/ELBOW_005/images/preview.png`

Setup frame:
- FULL
- shows complete seated starting position

Motion frames:
- UPPER
- same crop and same camera angle
- only forearm rotation changes materially

---

## 9. Image sequence

Setup before Start:
`setup_full_safe.png`

Animation loop after countdown:
`motion_01_palms_up_mid_safe.png → motion_02_palms_down_mid_safe.png → motion_01_palms_up_mid_safe.png`

---

## 10. Voice accompaniment

### Exercise-specific setup cue
**Text:**  
`Сядьте рівно. Лікті біля тулуба. Долоні вгору.`

**Target file:**  
`audio/uk/exercises/ELBOW_005/setup.m4a`

### Exercise-specific start cue
**Text:**  
`Плавно поверніть долоні вниз і назад угору.`

**Target file:**  
`audio/uk/exercises/ELBOW_005/start_movement.m4a`

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

`Долоні вгору — вниз. Сидячи на стільці, тримайте лікті біля тулуба і повертайте передпліччя так, щоб долоні почергово дивилися вгору і вниз.`

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
- [ ] Лікті біля тулуба.
- [ ] Усі motion frames мають однаковий crop і camera angle.
- [ ] Рух відбувається лише передпліччями.
- [ ] Немає тексту / стрілок / UI / watermark.
- [ ] Exercise-specific audio paths визначені.
- [ ] Common cues reused.
- [ ] 5-second prep countdown works.
- [ ] Pause/Stop flow works.
- [ ] Normal completion starts 10-second rest.

---

## 14. Files expected before production-ready state

Required:
- `docs/exercise_briefs/elbows/ELBOW_005/ELBOW_005_BRIEF.md`
- `docs/exercise_briefs/elbows/ELBOW_005/ELBOW_005_brief_sheet_v0.png`
- `data/exercises/elbows/ELBOW_005.yaml`
- `assets/exercises/ELBOW_005/images/setup_full_safe.png`
- `assets/exercises/ELBOW_005/images/motion_01_palms_up_mid_safe.png`
- `assets/exercises/ELBOW_005/images/motion_02_palms_down_mid_safe.png`
- `assets/exercises/ELBOW_005/images/preview.png`
- `audio/uk/exercises/ELBOW_005/setup.m4a`
- `audio/uk/exercises/ELBOW_005/start_movement.m4a`

Referenced common assets:
- `audio/uk/common/halfway.m4a`
- `audio/uk/common/completed.m4a`
