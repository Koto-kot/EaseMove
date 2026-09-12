# ELBOW_001 — Зігнути — розігнути руки

**Document type:** Exercise Production Brief  
**Exercise ID:** `ELBOW_001`  
**Slug:** `seated_bilateral_elbow_flexion_extension`  
**Primary zone:** `elbows`  
**Authoring language:** Ukrainian  
**Status:** `draft`  
**Difficulty:** very easy / starter  
**Equipment:** stable chair  
**Position:** seated  
**Movement type:** bilateral elbow flexion / extension  
**Target audience:** generally healthy adults; simple everyday movement / wellbeing use  
**Brief version:** `0.1.0`

---

## 1. Purpose

Проста стартова вправа для рухливості рук у ліктьових суглобах.

Людина сидить рівно на стільці. У вихідному положенні руки вільно опущені вздовж тулуба. Верхня частина рук залишається близько до тулуба. Людина одночасно згинає обидві руки в ліктях, підводячи кисті приблизно до рівня плечей, після чого плавно розгинає руки та повертається у вихідне положення.

Це не силова вправа: у руках немає гантелей, еспандерів або іншого опору.

---

## 2. Repository locations

### Human-readable brief
`docs/exercise_briefs/elbows/ELBOW_001/ELBOW_001_BRIEF.md`

### Concept / brief sheet
`docs/exercise_briefs/elbows/ELBOW_001/ELBOW_001_brief_sheet_v0.png`

Це робочий ескіз із текстом і поясненнями. Він **не є production asset** та не повинен потрапляти в UI застосунку.

### Future canonical exercise YAML
`data/exercises/elbows/ELBOW_001.yaml`

YAML має бути створений після затвердження цього brief і повинен посилатися на exact asset paths нижче.

### Production image folder
`assets/exercises/ELBOW_001/images/`

### Ukrainian exercise-specific audio
`audio/uk/exercises/ELBOW_001/`

### Reusable Ukrainian common audio
`audio/uk/common/`

---

## 3. Classification

Suggested classification:

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
  - `sitting`
  - `mobility`
  - `bilateral`
  - `beginner`
  - `gentle`
  - `no_resistance`
  - `no_equipment_except_chair`

---

## 4. Starting position

1. Сісти на стабільний стілець.
2. Корпус вертикальний, без вираженого нахилу вперед або назад.
3. Голова у нейтральному положенні, погляд вперед.
4. Плечі опущені та розслаблені.
5. Стопи повністю стоять на підлозі.
6. Коліна приблизно під прямим кутом.
7. Обидві руки вільно опущені вздовж тулуба.
8. Лікті розташовані близько до боків тулуба.
9. Долоні повернуті одна до одної або трохи вперед.
10. У руках немає предметів.

---

## 5. Movement

### Phase A — arms extended
Руки опущені вздовж тулуба. Лікті розігнуті без силового «замикання». Плечі залишаються розслабленими.

### Phase B — elbows flexed
Не піднімаючи плечі та не відводячи лікті далеко від тулуба, одночасно зігнути обидві руки в ліктях. Кисті піднімаються приблизно до рівня плечей або трохи нижче.

### Return
Плавно розігнути руки та повернутися до Phase A.

### Canonical cycle
`A → B → A`

---

## 6. Timing

Recommended prototype behavior:

- preparation countdown: `5 s`
- default active duration: `60 s`
- user-selectable duration presets: `60 / 120 / 180 / 300 s`
- recommended visual cycle: approximately `4 s`
  - flexion: about `2 s`
  - extension: about `2 s`
- movement is continuous and comfortable
- completion basis: elapsed active time
- pause freezes timer and animation
- Stop is available at any moment
- standard rest after normal completion: `10 s`
- early Stop is recorded neutrally and is not presented as failure

No side switch is required because both arms move simultaneously.

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
`assets/exercises/ELBOW_001/images/setup_full_safe.png`

**Framing:** `FULL`

**Purpose:** show the complete starting position before the exercise starts.

**Must show:**
- entire person
- full chair
- both feet
- both hands
- seated posture
- arms resting down alongside the torso

**Important:** this setup image may use a wider crop than the motion frames.

---

### 8.2 Motion frame 01 — extended

**Path:**  
`assets/exercises/ELBOW_001/images/motion_01_extended_mid_safe.png`

**Framing:** `UPPER`

**Crop:** approximately pelvis / lower abdomen to above the head, wide enough that both arms and hands are fully visible.

**Pose:**
- same seated torso position as setup
- shoulders down
- upper arms close to torso
- elbows extended
- hands down
- head neutral

---

### 8.3 Motion frame 02 — flexed

**Path:**  
`assets/exercises/ELBOW_001/images/motion_02_flexed_mid_safe.png`

**Framing:** `UPPER`

**Camera/crop:** exactly the same as `motion_01_extended_mid_safe.png`.

**Pose:**
- torso and head unchanged
- shoulders unchanged
- upper arms stay close to torso
- both elbows flex
- forearms rise
- hands reach approximately shoulder level or slightly below
- no clenched fists unless needed for visual consistency; hands relaxed

---

### 8.4 Preview image

**Target path:**  
`assets/exercises/ELBOW_001/images/preview.png`

For the first implementation, `preview.png` may be generated from `setup_full_safe.png`. It should remain a derived app asset rather than a separately illustrated pose.

---

## 9. Image sequence

Setup before Start:
`setup_full_safe.png`

Animation loop after countdown:
`motion_01_extended_mid_safe.png → motion_02_flexed_mid_safe.png → motion_01_extended_mid_safe.png`

The app may interpolate/fade between frames, but it must not invent a different body position.

---

## 10. Camera consistency rule

The setup frame and motion sequence serve different functions.

Therefore:

- same character identity across all images: **required**
- same clothes across all images: **required**
- same chair across all images: **required**
- same light/rendering style across all images: **required**
- same viewing direction / general camera angle: **required**
- setup frame may be `FULL`
- motion frames may be `UPPER`
- all motion frames must have exactly the same crop and camera

This intentionally replaces the earlier rule that every image in an exercise must have the same crop.

---

## 11. Image-generation reference

The concept sheet for this exercise is stored at:

`docs/exercise_briefs/elbows/ELBOW_001/ELBOW_001_brief_sheet_v0.png`

It is a composition reference only.

When production images are generated, use:
- canonical subject `adult_neutral_01`
- canonical style `exercise_visual_v1`
- the exact positional descriptions in sections 4–8
- the previous production motion frame as an identity/composition reference wherever the generation system supports image-to-image reference

---

## 12. Voice accompaniment

### Default voice mode: minimal

The default mode should not speak on every repetition. Use short cues only at meaningful points.

#### Exercise-specific setup cue
**Text:**  
`Сядьте рівно. Руки вільно опустіть уздовж тулуба.`

**Target file:**  
`audio/uk/exercises/ELBOW_001/setup.m4a`

#### Exercise-specific start cue
**Text:**  
`Зігніть руки в ліктях, потім плавно розігніть.`

**Target file:**  
`audio/uk/exercises/ELBOW_001/start_movement.m4a`

#### Reusable halfway cue
**Text:**  
`Половину виконано.`

**Target file:**  
`audio/uk/common/halfway.m4a`

#### Reusable completion cue
**Text:**  
`Готово.`

**Target file:**  
`audio/uk/common/completed.m4a`

### Recording style
- calm
- friendly
- clear
- natural
- unhurried
- no motivational shouting

### Source master / delivery
- recording master: WAV
- app delivery: M4A
- normalize levels
- trim unnecessary silence

---

## 13. Optional rhythm modes

These are optional app-level modes and should not be required to publish the exercise.

Possible modes:
- `minimal_voice` — default
- `phase_words` — repeated short rhythm: «Зігніть — розігніть»
- `count_1_2` — «Раз — два»
- `metronome`

If phase-word audio is implemented, use a reusable timing mechanism rather than recording a one-minute exercise-specific audio track.

---

## 14. Music

Use global music infrastructure; do not store a music file inside the `ELBOW_001` folder.

Recommended profile:
- `gentle_rhythm_01`
- instrumental
- loopable
- no vocals
- music volume = `0.5` relative to voice
- dynamic ducking = `false`

---

## 15. Accessibility

- reduced-motion mode: show the two static motion positions without smooth interpolation
- essential instructions must not depend on color
- the exercise remains understandable with audio disabled
- the exercise remains understandable with animation reduced to static steps
- screen-reader summary should be localized separately in the exercise YAML/localization system

Suggested Ukrainian screen-reader summary:

`Зігнути — розігнути руки. Сидячи на стільці, одночасно згинайте обидві руки в ліктях і плавно повертайте їх у вихідне положення.`

---

## 16. Tracking

Recommended tracking:
- actual active seconds
- completed session
- early stop
- pause count
- selected collection
- lifetime exercise counter increment on normal completion

A repetition counter is not required for the initial timed implementation.

---

## 17. QA checklist

Before the exercise is marked ready:

### Content
- [ ] Name matches the movement.
- [ ] Description is short and unambiguous.
- [ ] Both arms move simultaneously.
- [ ] No resistance or weights are shown.
- [ ] Movement is visually understandable without text.

### Setup frame
- [ ] Entire body is visible.
- [ ] Entire chair is readable enough to understand the position.
- [ ] Both feet are on the floor.
- [ ] Both hands are visible.
- [ ] Starting arm position is clear.

### Motion frames
- [ ] Same person in both frames.
- [ ] Same clothing.
- [ ] Same chair.
- [ ] Same background.
- [ ] Same light.
- [ ] Same camera angle.
- [ ] Same crop for both motion frames.
- [ ] Only the intended arm position changes materially.
- [ ] Shoulders do not rise in the flexed frame.
- [ ] Upper arms do not swing far forward.
- [ ] Both hands remain visible.
- [ ] No embedded text/arrows/UI/watermarks.

### Audio
- [ ] Exercise-specific files exist at the exact paths.
- [ ] Common cues are referenced instead of duplicated.
- [ ] Voice is understandable over music.
- [ ] Music does not duck automatically.

### App flow
- [ ] 5-second preparation countdown works.
- [ ] Pause freezes timer and animation.
- [ ] Stop works at any time.
- [ ] Normal completion starts the standard 10-second rest.
- [ ] Completion increments the lifetime exercise counter.

---

## 18. References / provenance

This exercise uses a generic everyday elbow flexion-extension movement.

Suggested popular electronic reference for the movement pattern:

- Verywell Fit — Hammer Curls: the article describes elbow flexion and notes that beginners can practice the movement without weight.
  `https://www.verywellfit.com/how-to-hammer-curls-techniques-benefits-variations-4788329`

Reference use:
- confirms the basic flexion movement pattern
- supports practicing the movement without resistance
- source wording, photos, and illustrations are **not** copied

The app title, wording, image sequence, character, graphics and audio are original project assets.

---

## 19. Files expected before this exercise is production-ready

Required:
- `docs/exercise_briefs/elbows/ELBOW_001/ELBOW_001_BRIEF.md`
- `data/exercises/elbows/ELBOW_001.yaml`
- `assets/exercises/ELBOW_001/images/setup_full_safe.png`
- `assets/exercises/ELBOW_001/images/motion_01_extended_mid_safe.png`
- `assets/exercises/ELBOW_001/images/motion_02_flexed_mid_safe.png`
- `assets/exercises/ELBOW_001/images/preview.png`
- `audio/uk/exercises/ELBOW_001/setup.m4a`
- `audio/uk/exercises/ELBOW_001/start_movement.m4a`

Referenced common assets:
- `audio/uk/common/halfway.m4a`
- `audio/uk/common/completed.m4a`

Development-only:
- `docs/exercise_briefs/elbows/ELBOW_001/ELBOW_001_brief_sheet_v0.png`

---

## 20. Next production step

Generate and approve the three source images in this order:

1. `setup_full_safe.png`
2. `motion_01_extended_mid_safe.png`
3. `motion_02_flexed_mid_safe.png`

Only after visual consistency is approved should `preview.png` and localized audio files be produced.
