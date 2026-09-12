# Proposed repository structure for exercise production

## Recommended approach

Do **not** keep all briefs in one flat folder and all images in one flat folder.

That works for the first few exercises but becomes hard to maintain once the library contains 100+ exercises and several images per exercise.

Use four logical layers:

```text
docs/exercise_briefs/
data/exercises/
assets/exercises/
audio/
```

Example:

```text
docs/
└── exercise_briefs/
    └── elbows/
        └── ELBOW_001/
            ├── ELBOW_001_BRIEF.md
            └── ELBOW_001_brief_sheet_v0.png

data/
└── exercises/
    └── elbows/
        └── ELBOW_001.yaml

assets/
├── reference/
│   └── subjects/
│       └── adult_neutral_01/
│           ├── seated_chair.png
│           ├── standing.png
│           ├── supine.png
│           └── seated_desk.png
└── exercises/
    └── ELBOW_001/
        └── images/
            ├── setup_full.png
            ├── motion_01_extended_upper.png
            ├── motion_02_flexed_upper.png
            └── preview.png

audio/
├── uk/
│   ├── common/
│   │   ├── halfway.m4a
│   │   └── completed.m4a
│   └── exercises/
│       └── ELBOW_001/
│           ├── setup.m4a
│           └── start_movement.m4a
├── en/
└── pl/
```

## Why this is preferable

- The human brief is separated from runtime data.
- The canonical YAML remains machine-readable.
- Every exercise has isolated production assets, so file names cannot collide.
- Shared model/style references are stored once, not copied into every exercise.
- Common voice cues are stored once per language.
- Exercise-specific voice cues remain beside their exercise ID.
- Development brief sheets never enter the production asset bundle.
- The structure scales cleanly to hundreds of exercises.

## Important schema/documentation update

The previous image rule required the same crop for every frame of one exercise.

The new production rule should be:

- setup/reference frame may use `FULL`
- motion frames may use `FULL`, `UPPER`, `LOWER`, or `DETAIL`
- all motion frames within one animation sequence must use the same crop and camera
- subject, clothing, prop, rendering style, lighting and general viewing angle remain consistent across setup and motion images

Therefore validation should eventually distinguish:

```yaml
setup_frame_may_use_different_crop: true
motion_frames_same_camera: true
motion_frames_same_crop: true
same_subject_all_frames: true
same_style_all_frames: true
```

instead of a single `same_crop_all_frames: true`.

## Brief as source of truth vs YAML

During content creation:

1. `ELBOW_001_BRIEF.md` is the human production specification.
2. Images/audio are created and approved against the brief.
3. `ELBOW_001.yaml` is then authored/updated with exact paths and runtime events.
4. The YAML is validated during the build step.
5. Runtime should consume validated build artifacts, not parse the human brief.

This avoids duplicating creative decisions in Flutter widgets.
