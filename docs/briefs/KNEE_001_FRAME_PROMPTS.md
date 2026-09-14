# KNEE_001 — Frame generation prompts

Aligned with `docs/ASSET_PIPELINE.md`: generate **FRAME_START as master**, then each later frame as an **edit of that master** (change only the pose). Do not regenerate the whole scene from scratch for each frame.

Negative constraints (all prompts): no text, no arrows, no badges, no timer, no watermark, no branding, no fitness-model / bodybuilding look, no medical coat, no logos on clothes, no camera jump, no chair drift.

Style anchors: `exercise_visual_v1`, subject `adult_neutral_01`, clean neutral instructional illustration/photo-real calm look, 1024×1024, three-quarter side view, full seated body with chair, head-to-feet crop, clean neutral background.

---

## 1) Master — FRAME_START → `frame_start.png`

**Mode:** generate from scratch

```text
Adult of ordinary non-athletic build sitting upright on a stable armless chair,
three-quarter side view, full body from head to feet including the chair.
Simple plain comfortable clothing, no logos. Clean neutral background.
Both feet flat on the floor, knees bent about 90 degrees, thighs on the seat,
torso upright, calm neutral expression. Soft even lighting. Square 1024x1024
composition with the figure centered in the safe area. No text, no arrows,
no watermark.
```

---

## 2) Edit — FRAME_LEFT_MID → `frame_left_mid.png`

**Mode:** edit of `frame_start.png` (same person, clothes, chair, camera, crop)

```text
Keep everything identical to the reference image except the left leg:
raise the left lower leg forward so the left knee is only partially extended.
Left thigh stays on the seat. Right foot stays flat on the floor. Torso stays
upright — do not lean back. Same chair position, same camera, same clothing.
No text, no arrows.
```

---

## 3) Edit — FRAME_LEFT_EXTENDED → `frame_left_extended.png`

**Mode:** edit of master (or of left_mid)

```text
Keep everything identical to the reference image except the left leg:
extend the left leg forward in a comfortable controlled range, pull the left
toes toward the body (gentle dorsiflexion). Left thigh remains on the seat.
Right foot remains flat on the floor. Torso upright, no lean back. Same chair,
camera, clothing, lighting. No text, no arrows.
```

---

## 4) Edit — FRAME_RIGHT_MID → `frame_right_mid.png`

**Mode:** edit of master

```text
Keep everything identical to the reference image except the right leg:
raise the right lower leg forward so the right knee is only partially extended
(true mirror of the left mid pose). Right thigh stays on the seat. Left foot
stays flat on the floor. Torso upright. Same chair, camera, clothing. No text,
no arrows.
```

---

## 5) Edit — FRAME_RIGHT_EXTENDED → `frame_right_extended.png`

**Mode:** edit of master (or of right_mid)

```text
Keep everything identical to the reference image except the right leg:
extend the right leg forward in a comfortable controlled range, pull the right
toes toward the body. Right thigh remains on the seat. Left foot remains flat
on the floor. Torso upright. Same chair, camera, clothing. No text, no arrows.
```

---

## Preview

Do not hand-draw `preview.png`. After frames exist:

```bash
python scripts/make_previews.py --only KNEE_001
```

Source frame: `FRAME_LEFT_EXTENDED`.

## Suggested generate_frames commands

```bash
# dry-run: print prompts only
python scripts/generate_frames.py --only KNEE_001

# generate (requires OPENAI_API_KEY in .env)
python scripts/generate_frames.py --only KNEE_001 --yes

# review sheet
python scripts/build_review_sheet.py --open
python scripts/check_assets.py
```
