# HOME SCREEN / BODY MAP — REPOSITORY BRIEF
Version: 1.0  
Status: approved for repository setup  
Target: Flutter mobile app  
Scope: Home screen only

---

## 1. Purpose

The Home screen gives the user two simple entry points:

1. choose a body zone on the interactive Body Map;
2. open one of the four main product sections:
   - Body
   - Eyes
   - Morning
   - Sat too long / Sitting break

The screen must remain simple, calm, readable, and easy to tap.

This screen is not a medical diagnostic screen. It is a wellbeing / movement navigation screen.

---

## 2. Approved Home screen structure

The screen contains four vertical blocks:

1. Top controls + reserved text zone
2. Body Map
3. Four main section cards
4. Safe bottom spacing

There is **no bottom navigation bar** on this screen in the current MVP.

There is **no “Relax” card** in the current MVP. It may be added later or used as a Pro / future feature.

---

## 3. Top area

### 3.1 Controls

Left:
- hamburger / menu button

Right:
- settings button

Recommended Flutter controls:
- `IconButton`
- minimum touch target: 48×48 logical px

### 3.2 Reserved title area

A fixed layout region must be reserved for:
- main title
- short explanatory subtitle

Current mockup text such as “Рухайся легше” is **not final copy**.

The layout must support replacing title/subtitle without changing the composition of the screen.

### 3.3 Localization rule

Title and subtitle must never be baked into an image.

They must come from the localization layer.

Suggested keys:

```text
home.title
home.subtitle
```

The text must follow:
1. the language manually selected by the user, if set;
2. otherwise the supported language matching the device language;
3. otherwise the app fallback locale.

Recommended MVP locales:
- `uk`
- `en`
- `pl`

Recommended fallback:
- `en`

---

## 4. Body Map

### 4.1 Main visual composition

The approved composition is:

- one large **front-facing body model**
- model visually centered relative to the screen
- one smaller **back-view model** placed to the right
- body zones shown as visible circular buttons with a soft halo
- no permanent body-part text labels around the figure

The front figure is the primary visual anchor.

The back figure is secondary and must remain smaller.

### 4.2 Front model

Required production asset:

```text
assets/ui/home/body/body_front.png
```

Requirements:
- front-facing
- full body visible
- centered
- arms slightly separated from torso
- feet separated enough for independent foot/ankle hotspots
- no embedded hotspot circles
- no text
- no UI
- no arrows
- no labels
- no watermark

### 4.3 Back mini model

Required production asset:

```text
assets/ui/home/body/body_back_mini.png
```

Requirements:
- back-facing
- same visual family as front model
- full body visible
- no hotspot circles baked into image
- no text
- no labels
- no watermark

The back mini is used only for:
- upper back
- lower back / lumbar

---

## 5. Hotspot layer

Hotspots must be rendered by Flutter as a separate interactive overlay.

Do not bake hotspots into `body_front.png` or `body_back_mini.png`.

Canonical hotspot file:

```text
data/ui/body_map/body_hotspots.yaml
```

### 5.1 Visible hotspot

Each hotspot is a small visible button with a soft halo.

Recommended visual structure:

- core: 18–22 px
- halo: 44–56 px
- touch target: 56–72 px

Exact values may be scaled responsively.

### 5.2 Hotspot appearance

Normal:
- small bright core
- soft translucent halo

Pressed:
- core slightly compresses
- halo brightens / expands

Selected:
- short pulse
- then navigation

Recommended pulse duration:
- 250–350 ms
- default: 300 ms

### 5.3 Paired-zone behavior

For symmetrical body parts, tapping one side highlights **both sides**.

Example:

```text
tap left knee
→ highlight left knee + right knee
→ 300 ms pulse
→ open body_knees
```

This applies to:
- shoulders
- elbows
- wrists / hands
- hips / upper thighs
- knees
- shins
- ankles
- feet

Single zones:
- neck
- upper back
- lower back

### 5.4 Navigation targets

Recommended collections:

```text
body_neck
body_shoulders
body_elbows
body_wrists
body_hips
body_knees
body_shins
body_ankles
body_feet
body_upper_back
body_lower_back
```

---

## 6. Main section cards

The bottom section contains exactly four cards in the MVP:

1. Body
2. Eyes
3. Morning
4. Sitting break / Sat too long

Recommended layout:
- 2 columns × 2 rows
- equal card widths
- equal card heights
- consistent spacing
- rounded corners

The exact copy is localized.

---

## 7. Important production rule for the cards

**Do not use full raster button images with text baked into them.**

The visual mockups are reference only.

Production cards should be composed in Flutter from:
- card container / background
- icon asset
- localized title
- localized subtitle
- chevron icon

This is required for:
- localization
- accessibility
- responsive text
- larger system font sizes
- future copy changes

### 7.1 Production icon assets

Recommended:

```text
assets/ui/home/cards/icon_body.svg
assets/ui/home/cards/icon_eyes.svg
assets/ui/home/cards/icon_morning.svg
assets/ui/home/cards/icon_sitting.svg
```

If SVG is not used, use high-resolution transparent PNG:

```text
assets/ui/home/cards/icon_body.png
assets/ui/home/cards/icon_eyes.png
assets/ui/home/cards/icon_morning.png
assets/ui/home/cards/icon_sitting.png
```

Prefer SVG for simple icons.

### 7.2 Card visuals

Card background, border, radius and tint should be built in Flutter.

Suggested style tokens:

```yaml
cards:
  radius: 22
  border_width: 1
  body:
    tint: blue_soft
  eyes:
    tint: lavender_soft
  morning:
    tint: yellow_soft
  sitting:
    tint: mint_soft
```

Exact colors belong in app theme tokens, not image files.

### 7.3 Card content

Each card contains:

- icon on left
- title
- subtitle
- chevron on right

Suggested localization keys:

```text
home.card.body.title
home.card.body.subtitle

home.card.eyes.title
home.card.eyes.subtitle

home.card.morning.title
home.card.morning.subtitle

home.card.sitting.title
home.card.sitting.subtitle
```

Current Ukrainian working copy:

```text
Тіло
Вправи для всього тіла

Очі
Відпочинок для очей

Ранок
Бадьорість на весь день

Засидівся
Швидка розминка
```

This copy is working content, not hard-coded UI text.

---

## 8. Localization architecture

Recommended Flutter localization:

```text
lib/l10n/
  app_uk.arb
  app_en.arb
  app_pl.arb
```

Example:

```json
{
  "homeTitle": "Рухайся легше",
  "homeSubtitle": "Оберіть зону на тілі, щоб знайти вправи",
  "homeCardBodyTitle": "Тіло",
  "homeCardBodySubtitle": "Вправи для всього тіла",
  "homeCardEyesTitle": "Очі",
  "homeCardEyesSubtitle": "Відпочинок для очей",
  "homeCardMorningTitle": "Ранок",
  "homeCardMorningSubtitle": "Бадьорість на весь день",
  "homeCardSittingTitle": "Засидівся",
  "homeCardSittingSubtitle": "Швидка розминка"
}
```

Do not localize by replacing text inside images.

---

## 9. Language resolution

Recommended application logic:

```text
if user_selected_language exists:
    use user_selected_language
else if device_language is supported:
    use device_language
else:
    use fallback_locale
```

A manual language choice must persist across app restarts.

Voice language should follow the same selected app language unless the product later adds a separate voice-language setting.

---

## 10. Recommended repository structure

```text
assets/
└── ui/
    └── home/
        ├── body/
        │   ├── body_front.png
        │   └── body_back_mini.png
        │
        └── cards/
            ├── icon_body.svg
            ├── icon_eyes.svg
            ├── icon_morning.svg
            └── icon_sitting.svg

data/
└── ui/
    ├── body_map/
    │   └── body_hotspots.yaml
    │
    └── home/
        └── home_screen.yaml

docs/
└── ui/
    └── home/
        ├── HOME_SCREEN_REPOSITORY_BRIEF.md
        ├── HOME_SCREEN_LAYOUT_SPEC.md
        └── HOME_SCREEN_REFERENCE.png

lib/
├── features/
│   └── home/
│       ├── presentation/
│       │   ├── home_screen.dart
│       │   ├── widgets/
│       │   │   ├── body_map.dart
│       │   │   ├── body_hotspot.dart
│       │   │   ├── back_mini_map.dart
│       │   │   └── home_section_card.dart
│       │   └── home_controller.dart
│       └── domain/
│           └── home_section.dart
│
└── l10n/
    ├── app_uk.arb
    ├── app_en.arb
    └── app_pl.arb
```

---

## 11. Suggested `home_screen.yaml`

Recommended screen-level configuration:

```yaml
schema_version: "1.0"

screen:
  id: home
  status: approved_layout

header:
  reserve_title_area: true
  reserve_subtitle_area: true
  menu_button: true
  settings_button: true

body_map:
  front_asset: assets/ui/home/body/body_front.png
  back_asset: assets/ui/home/body/body_back_mini.png
  hotspots: data/ui/body_map/body_hotspots.yaml
  paired_highlight: true
  pulse_duration_ms: 300
  persistent_labels: false

sections:
  layout: grid_2x2

  items:
    - id: body
      icon: assets/ui/home/cards/icon_body.svg
      title_key: home.card.body.title
      subtitle_key: home.card.body.subtitle
      route: body

    - id: eyes
      icon: assets/ui/home/cards/icon_eyes.svg
      title_key: home.card.eyes.title
      subtitle_key: home.card.eyes.subtitle
      route: eyes

    - id: morning
      icon: assets/ui/home/cards/icon_morning.svg
      title_key: home.card.morning.title
      subtitle_key: home.card.morning.subtitle
      route: morning

    - id: sitting
      icon: assets/ui/home/cards/icon_sitting.svg
      title_key: home.card.sitting.title
      subtitle_key: home.card.sitting.subtitle
      route: sitting

excluded_from_mvp:
  - relax
  - bottom_navigation
```

---

## 12. Flutter composition

Recommended widget hierarchy:

```text
HomeScreen
├── SafeArea
│   └── Column
│       ├── HomeHeader
│       │   ├── MenuButton
│       │   ├── LocalizedTitleBlock
│       │   └── SettingsButton
│       │
│       ├── Expanded
│       │   └── BodyMap
│       │       ├── FrontBodyArtwork
│       │       ├── FrontHotspotOverlay
│       │       ├── BackMiniArtwork
│       │       └── BackHotspotOverlay
│       │
│       └── HomeSectionsGrid
│           ├── BodyCard
│           ├── EyesCard
│           ├── MorningCard
│           └── SittingCard
```

---

## 13. Responsive layout rules

The approved composition must be preserved on different phone sizes.

Rules:

- main front body remains visually centered;
- body must not be cropped;
- mini-back must not force the front body off-center;
- front figure receives priority when width is limited;
- 2×2 cards must remain readable;
- title/subtitle area must support 1–2 extra text lines in languages with longer copy;
- do not use fixed pixel offsets for body hotspots;
- body hotspot coordinates must be normalized to the artwork bounds.

For very small screens:
- slightly reduce Body Map height first;
- do not shrink card text below accessible minimums;
- allow subtitle wrapping.

---

## 14. Accessibility

Minimum requirements:

- every hotspot has a semantic label;
- paired hotspots announce the shared body area, e.g. “Коліна”;
- cards expose localized title + subtitle to screen readers;
- all tappable elements meet a minimum 48×48 logical px target;
- color alone must not be required to understand that a hotspot is interactive;
- support system text scaling;
- decorative body images should not duplicate spoken hotspot labels.

Example semantics:

```text
left_knee:
  semantic_label_key: body.zone.knees
  button: true
```

---

## 15. Assets vs runtime UI

### Image assets
Use images only for:
- front body artwork
- back mini artwork
- possibly icon artwork if not vector

### Flutter-rendered UI
Render in Flutter:
- hotspots
- halos
- cards
- borders
- backgrounds
- chevrons
- title
- subtitle
- localized text
- press states
- pulse animation

This separation is mandatory.

---

## 16. Reference mockup

The approved visual mockup is a design reference only.

Recommended repository location:

```text
docs/ui/home/HOME_SCREEN_REFERENCE.png
```

Do not ship the complete mockup as a production screen asset.

---

## 17. MVP scope — approved

Included:
- top menu
- settings
- reserved title area
- reserved subtitle area
- front body map
- mini back map
- visible halo hotspots
- paired-zone highlight logic
- four main section cards:
  - Body
  - Eyes
  - Morning
  - Sitting

Excluded for now:
- Relax
- bottom tab navigation
- My cycles
- History
- motivational bottom slogan

---

## 18. Acceptance checklist

### Layout
- [ ] Front body is visually centered.
- [ ] Back mini does not make the main figure appear off-center.
- [ ] No body part is cropped.
- [ ] Four cards are clearly visible.
- [ ] No bottom navigation appears.

### Body Map
- [ ] Hotspots are separate from PNG.
- [ ] Hotspots are visibly interactive.
- [ ] Tapping one paired zone highlights both sides.
- [ ] Pulse occurs before navigation.
- [ ] Neck / upper back / lower back behave as single zones.

### Cards
- [ ] Four cards only.
- [ ] Text is not baked into card images.
- [ ] Titles and subtitles come from localization.
- [ ] Icons are independent assets.
- [ ] Card styling is Flutter-rendered.

### Localization
- [ ] Device locale is detected.
- [ ] Manual language selection overrides device locale.
- [ ] Selected language persists.
- [ ] Unsupported locale falls back correctly.
- [ ] Long localized strings do not break layout.

### Accessibility
- [ ] Touch targets are at least 48×48 logical px.
- [ ] Screen reader labels exist for all hotspots.
- [ ] Screen reader labels exist for all cards.
- [ ] Text scaling does not clip content.

---

## 19. Next implementation step

After this brief is accepted:

1. finalize `body_front.png`;
2. finalize `body_back_mini.png`;
3. finalize four card icon assets;
4. create `body_hotspots.yaml`;
5. create `home_screen.yaml`;
6. create initial `uk / en / pl` ARB files;
7. implement `HomeScreen` in Flutter;
8. visually tune hotspot coordinates against the final artwork;
9. verify on at least one small and one large phone viewport.
