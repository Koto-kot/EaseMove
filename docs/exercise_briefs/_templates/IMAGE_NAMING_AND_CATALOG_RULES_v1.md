# IMAGE NAMING AND CATALOG RULES v1

## Repository structure

### Briefs
`docs/exercise_briefs/neck/NECK_001/NECK_001_BRIEF.md`

### Visual brief sheet
`docs/exercise_briefs/neck/NECK_001/NECK_001_brief_sheet_v1.png`

### Production images
`assets/exercises/NECK_001/images/`

### YAML
`data/exercises/neck/NECK_001.yaml`

### Audio
`audio/uk/exercises/NECK_001/`

---

## Filename rules

### Exercise ID
Always use fixed 3-digit numbering:
- `NECK_001`
- `NECK_002`
- ...
- `NECK_010`

### Standard image filenames
- `setup_full_safe.png`
- `motion_01_<description>_<framing>.png`
- `motion_02_<description>_<framing>.png`
- `motion_03_<description>_<framing>.png` if needed
- `preview.png`

Examples:
- `motion_01_chin_tuck_upper_safe.png`
- `motion_02_head_turn_left_upper_safe.png`
- `motion_03_head_turn_right_upper_safe.png`

### Text rules
- lowercase words in the descriptive part
- words separated with underscores
- no spaces
- no non-latin characters in filenames
- `.png` extension for image assets

---

## Catalogization rules
Every exercise should have these folders/files:

1. Brief folder
- `docs/exercise_briefs/neck/NECK_001/NECK_001_BRIEF.md`
- optionally `NECK_001_brief_sheet_v1.png`

2. Image folder
- `assets/exercises/NECK_001/images/setup_full_safe.png`
- motion images
- `preview.png`
- optional `README.md`

3. Audio folder
- `audio/uk/exercises/NECK_001/README.md`
- later actual `.m4a` files

4. Data file
- `data/exercises/neck/NECK_001.yaml`

---

## Status convention
Possible asset status values:
- `draft`
- `brief_ready`
- `images_pending`
- `images_included`
- `qa_checked`

Recommended progression:
1. brief_ready
2. images_pending
3. images_included
4. qa_checked
