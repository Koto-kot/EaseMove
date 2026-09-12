# ELBOW_004 — Згинання рук долонями вниз

**Document type:** Exercise Production Brief  
**Exercise ID:** `ELBOW_004`  
**Slug:** `seated_pronated_elbow_flexion_extension`  
**Primary zone:** `elbows`  
**Authoring language:** Ukrainian  
**Status:** `draft`  
**Asset status:** `images_included`  
**Difficulty:** easy / starter  
**Equipment:** stable chair  
**Position:** seated  
**Movement type:** bilateral elbow flexion / extension with forearms pronated  
**Target audience:** generally healthy adults; simple everyday movement / wellbeing use  
**Brief version:** `0.1.0`

---

## 1. Purpose

Проста вправа для руху в ліктях без ваги та без іншого опору.

Людина сидить рівно на стільці. Верхні частини рук залишаються близько до тулуба. У стартовій робочій позиції лікті зігнуті приблизно на 90°, передпліччя спрямовані вперед, а долоні повернуті вниз до підлоги. Не повертаючи передпліччя і не змінюючи положення долонь, людина сильніше згинає лікті, підводячи кисті ближче до плечей, після чого плавно повертається до положення приблизно 90°.

**Ключове правило:** долоні залишаються повернутими вниз протягом усього циклу. Це НЕ вправа на супінацію/пронацію передпліч.

---

## 2. Repository locations

Human brief:  
`docs/exercise_briefs/elbows/ELBOW_004/ELBOW_004_BRIEF.md`

Visual brief sheet:  
`docs/exercise_briefs/elbows/ELBOW_004/ELBOW_004_brief_sheet_v0.png`

Canonical YAML path:  
`data/exercises/elbows/ELBOW_004.yaml`

Production images folder:  
`assets/exercises/ELBOW_004/images/`

Exercise-specific audio:  
`audio/uk/exercises/ELBOW_004/`

Reusable common audio:  
`audio/uk/common/`

---

## 3. Classification

- primary zone: `elbows`
- secondary zones: `forearms`, `upper_arms`
- body-map hotspots: `left_elbow`, `right_elbow`
- collections:
  - `body_elbows`
  - `seated_gentle`
  - `computer_break`
  - `after_sitting`
- tags:
  - `elbows`
  - `arms`
  - `forearms`
  - `sitting`
  - `mobility`
  - `bilateral`
  - `pronated_forearm`
  - `palms_down`
  - `beginner`
  - `gentle`
  - `no_resistance`
  - `chair`

---

## 4. Starting position

1. Сісти на стабільний стілець.
2. Корпус вертикальний, без вираженого нахилу вперед або назад.
3. Голова у нейтральному положенні, погляд уперед.
4. Плечі опущені та розслаблені.
5. Стопи повністю стоять на підлозі.
6. Коліна приблизно під прямим кутом.
7. Верхні частини рук розташовані близько до тулуба.
8. Лікті зігнуті приблизно на 90°.
9. Передпліччя спрямовані горизонтально вперед.
10. Обидві долоні повернуті вниз до підлоги.
11. Зап’ястя прямі, пальці розслаблені.
12. У руках немає предметів.

---

## 5. Movement

### Phase A — forearms forward, palms down

Лікті зігнуті приблизно на 90°. Передпліччя горизонтально вперед. Долоні дивляться вниз. Верхні частини рук залишаються біля тулуба.

### Phase B — greater elbow flexion, palms still down

Не рухаючи плечима і не повертаючи передпліччя, сильніше зігнути обидва лікті. Кисті рухаються в напрямку плечей. Долоні весь час залишаються повернутими вниз. Зап’ястя залишаються прямими.

### Return

Плавно розігнути лікті назад приблизно до 90° і повернутися у Phase A.

### Canonical cycle

`A → B → A`

---

## 6. Timing

Recommended prototype behavior:

- preparation countdown: `5 s`
- default active duration: `60 s`
- user-selectable duration presets: `60 / 120 / 180 / 300 s`
- estimated cycle: approximately `4 s`
  - flexion toward shoulders: about `2 s`
  - return to 90°: about `2 s`
- movement is continuous and comfortable
- completion basis: elapsed active time
- pause freezes timer and animation
- Stop is available at any moment
- standard rest after normal completion: `10 s`
- no side switch: both arms move simultaneously

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

### 8.1 Setup image — full body

**Path:**  
`assets/exercises/ELBOW_004/images/setup_full_safe.png`

**Framing:** `FULL`

**Pose:** complete initial position with elbows at approximately 90°, forearms forward and palms down.

### 8.2 Motion frame 01 — start of motion cycle

**Path:**  
`assets/exercises/ELBOW_004/images/motion_01_forearms_forward_palms_down_mid_safe.png`

**Framing:** `UPPER`

**Pose:**
- elbows approximately 90°
- forearms horizontal forward
- palms face floor
- wrists neutral
- shoulders relaxed
- upper arms close to torso

### 8.3 Motion frame 02 — flexed

**Path:**  
`assets/exercises/ELBOW_004/images/motion_02_flexed_palms_down_mid_safe.png`

**Framing:** `UPPER`

**Camera/crop:** exactly the same as motion frame 01.

**Pose:**
- elbows flexed more than 90°
- hands closer to shoulders
- palms STILL face floor
- NO forearm rotation
- wrists straight
- shoulders and torso unchanged

### 8.4 Preview

**Path:**  
`assets/exercises/ELBOW_004/images/preview.png`

Derived from the approved setup image.

---

## 9. Image sequence

Setup before Start:

`setup_full_safe.png`

Animation loop after countdown:

`motion_01_forearms_forward_palms_down_mid_safe.png → motion_02_flexed_palms_down_mid_safe.png → motion_01_forearms_forward_palms_down_mid_safe.png`

---

## 10. Camera consistency rule

- same character identity across all images: required
- same clothes across all images: required
- same chair across all images: required
- same rendering style/light: required
- setup may use `FULL`
- motion frames use `UPPER`
- all motion frames must have identical crop and camera angle
- only elbow angle changes materially
- palm orientation must NOT change

---

## 11. Image-generation rejection rule

Reject an image immediately if it shows any of the following:

- palms turning up and down;
- forearm supination/pronation;
- elbow circles;
- one arm supporting or stretching the other;
- weights or resistance;
- shoulders lifting;
- upper arms moving far away from torso;
- different camera/crop between motion frames;
- embedded arrows/text/UI.

Current repository status: the production images are now included in the repository package and linked at the exact paths listed in section 8.

---

## 12. Voice accompaniment

### Exercise-specific setup cue

**Text:**  
`Сядьте рівно. Зігніть руки в ліктях. Передпліччя вперед, долоні вниз.`

**Target file:**  
`audio/uk/exercises/ELBOW_004/setup.m4a`

### Exercise-specific start cue

**Text:**  
`Підводьте кисті до плечей і плавно повертайте назад. Долоні залишаються вниз.`

**Target file:**  
`audio/uk/exercises/ELBOW_004/start_movement.m4a`

### Reusable common halfway cue

`audio/uk/common/halfway.m4a`  
Text: `Половину виконано.`

### Reusable completion cue

`audio/uk/common/completed.m4a`  
Text: `Готово.`

### Recording style

- calm
- friendly
- clear
- natural
- unhurried
- no motivational shouting

### Audio formats

- source master: WAV
- app delivery: M4A
- normalization required
- trim unnecessary silence

---

## 13. Optional rhythm modes

Possible app-level modes:

- `minimal_voice` — default
- `phase_words` — «До плечей — вперед»
- `count_1_2` — «Раз — два»
- `metronome`

Do not record a one-minute exercise-specific track; timing cues should be reusable/event-driven.

---

## 14. Music

Use global music infrastructure.

Recommended profile:
- `gentle_rhythm_01`
- instrumental
- loopable
- no vocals
- music volume = `0.5` relative to voice
- dynamic ducking = `false`

---

## 15. Accessibility

Suggested Ukrainian screen-reader summary:

`Згинання рук долонями вниз. Сидячи на стільці, тримайте лікті біля тулуба, передпліччя вперед і долоні вниз. Підводьте кисті до плечей та плавно повертайте руки назад.`

Reduced-motion mode:
- show the two static motion positions without smooth interpolation.

The exercise must remain understandable with audio disabled.

---

## 16. Tracking

Recommended:
- actual active seconds
- completed session
- early stop
- pause count
- selected collection
- lifetime exercise counter increment on normal completion

A repetition counter is not required for the initial timed implementation.

---

## 17. QA checklist

### Content
- [ ] Назва відповідає руху.
- [ ] У тексті немає плутанини з обертанням передпліч.
- [ ] Долоні вниз протягом усього циклу.
- [ ] Обидві руки рухаються одночасно.
- [ ] Немає опору або ваги.

### Setup
- [ ] Усе тіло видно.
- [ ] Стілець і стопи видно.
- [ ] Лікті приблизно 90°.
- [ ] Передпліччя вперед.
- [ ] Долоні вниз.

### Motion
- [ ] Same subject.
- [ ] Same clothing.
- [ ] Same chair/background/light.
- [ ] Same camera and crop in all motion frames.
- [ ] Only elbow angle changes materially.
- [ ] Palms stay down.
- [ ] No pronation/supination animation.
- [ ] Wrists stay neutral.
- [ ] Shoulders do not rise.
- [ ] No text/arrows/UI/watermarks.

### Audio / flow
- [ ] Exercise-specific paths exist.
- [ ] Common cues reused.
- [ ] 5-second prep works.
- [ ] Pause freezes timer/animation.
- [ ] Stop works at any time.
- [ ] Normal completion starts 10-second rest.

---

## 18. Reference / provenance

Popular electronic movement reference:

**Verywell Fit — “How to Do Reverse Curls: Proper Form, Variations, and Common Mistakes.”**

Reference URL:  
`https://www.verywellfit.com/reverse-bicep-curl-techniques-benefits-variations-4788211`

Reference evidence used:
- reverse-curl variation uses palms facing down;
- elbow flexion brings the hands toward the shoulders;
- upper arms remain relatively stationary;
- lowering is slow and controlled.

Important adaptation note:
- the source demonstrates a resistance exercise with weights;
- this app exercise uses only the underlying ordinary elbow movement pattern and removes external resistance;
- source text, photographs, illustrations, timing and training prescription are not copied.

---

## 19. Files expected before production-ready state

Required:
- `docs/exercise_briefs/elbows/ELBOW_004/ELBOW_004_BRIEF.md`
- `docs/exercise_briefs/elbows/ELBOW_004/ELBOW_004_brief_sheet_v0.png`
- `data/exercises/elbows/ELBOW_004.yaml`
- `assets/exercises/ELBOW_004/images/setup_full_safe.png`
- `assets/exercises/ELBOW_004/images/motion_01_forearms_forward_palms_down_mid_safe.png`
- `assets/exercises/ELBOW_004/images/motion_02_flexed_palms_down_mid_safe.png`
- `assets/exercises/ELBOW_004/images/preview.png`
- `audio/uk/exercises/ELBOW_004/setup.m4a`
- `audio/uk/exercises/ELBOW_004/start_movement.m4a`

Common:
- `audio/uk/common/halfway.m4a`
- `audio/uk/common/completed.m4a`

---

## 20. Current production status

`draft / images_included`

Do not mark this exercise ready until the two motion images clearly show elbow flexion with palms staying down and no forearm rotation.
