# Exercise Brief Template v2 — FULL_SAFE / UPPER_SAFE

## Purpose
A repository template for exercise production briefs.

## Mandatory visual consistency
- same model identity across all frames of one exercise
- same clothing
- same lighting
- same chair / wall / table / mat if used
- same camera direction within motion frames
- no text baked into production image assets
- no arrows
- no UI
- no badges
- no branding
- no watermark

## Framing levels

### FULL_SAFE
Use when the whole body must be visible.
Mandatory:
- no cropped hands
- no cropped feet
- no cropped moving limbs
- safe margin around the whole figure

### MID_SAFE
Use when the exercise focuses on the upper or lower body and a closer crop is acceptable,
but all relevant moving body parts must remain fully visible.

### UPPER_SAFE
Especially useful for neck, face, shoulder-girdle, elbows, wrists and hand details.
Mandatory:
- head fully visible
- neck fully visible
- all relevant arms / hands fully visible when they are part of the movement
- do not crop through the active joints or the active moving path
- keep a small safe margin around the active body region

## Standard production files
- `setup_full_safe.png` or `setup_<framing>.png`
- `motion_01_<pose>_<framing>.png`
- `motion_02_<pose>_<framing>.png`
- additional motion frames if needed
- `preview.png`

## Visual brief sheet
Each exercise may also have:
- `EXERCISE_ID_brief_sheet_v1.png`

This is a documentation artifact, not a runtime image.
