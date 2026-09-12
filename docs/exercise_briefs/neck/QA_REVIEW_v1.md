# NECK_001–NECK_010 — QA REVIEW v1

**Review date:** 2026-09-12  
**Package target:** cumulative Neck library  
**Automated structural issues after fixes:** 0

## 1. What passed

- All ten exercise IDs `NECK_001–NECK_010` are present.
- All ten YAML files parse successfully.
- YAML references to production images, briefs, and visual brief sheets resolve to existing files.
- Runtime PNG filenames use lowercase Latin descriptive names, underscores, approved framing suffixes, and `.png`.
- Every exercise contains `setup`, motion assets, `preview.png`, a text brief, a visual brief sheet, a YAML file, and an audio README.
- Runtime assets are separated from documentation assets.

## 2. Corrections applied in this QA pass

### Repository metadata
The root `README.md` and `NECK_LIBRARY_OVERVIEW.md` were stale and still described only `NECK_001–003` as complete. They now describe the full `NECK_001–010` library.

### Obsolete placeholders
Removed leftover `PLACEHOLDER.txt` files from completed exercises `NECK_004–NECK_007`.

### NECK_005 runtime cleanup
`motion_02_head_slightly_up_upper_safe.png` contained documentation text inside a runtime asset, which violated the runtime-image rule. It has been replaced with a text-free crop, and `preview.png` has been updated to the same clean asset.

### NECK_009 dimensions
The NECK_009 motion/preview images were `1024×1024` while the rest of the production series used `1254×1254`. They were normalized to `1254×1254` without renaming files.

## 3. Filename / path result

**PASS.** No missing production/document references were found after the corrections above.

## 4. Visual consistency review

The series is broadly consistent in:
- female model concept and dark low-bun hairstyle;
- lavender/purple top and dark trousers;
- calm physiotherapy-instructional presentation;
- light neutral / pale-blue backgrounds;
- square runtime assets;
- FULL_SAFE setup + closer motion framing;
- soft red contact highlight for isometric effort where used.

### Remaining non-blocking visual differences

1. `NECK_003_brief_sheet_v1.png` uses a near-square canvas rather than the common landscape 4:3 documentation layout.
2. `NECK_005_brief_sheet_v1.png` is also square and has noticeably more empty space than the other brief sheets.
3. NECK_009 motion frames use a slightly warmer neutral background than most of the series.
4. Camera orientation varies between front, profile, and 3/4 views. This is mostly exercise-driven and not treated as an error.
5. The first/setup image is not always identical to the image embedded in the generated visual brief sheet. Runtime assets remain the source of truth for the app.

## 5. Recommendation

The pack is technically coherent and can be used as the current repository baseline. For a later **visual-polish pass**, the highest-priority documentation-only work is to re-layout the `NECK_003` and `NECK_005` visual brief sheets into the same landscape 4:3 template; NECK_009 background tone can also be harmonized if exact visual matching is required.

## 6. Automated validation result

No unresolved structural/file-reference errors.

---

## 7. Repository integration pass (2026-09-13)

Added when the pack was brought into the app. The pack's own report above is
unchanged; this section records what the repository's checks found on top of
it. `scripts/check_assets.py` reports **0 errors** for the neck series.

### Resolved during integration

- **`NECK_002` had no neutral frame at the motion crop.** The pack ships head
  turns as a two-frame left/right loop, but this repository's version of the
  exercise passes through the centre between turns. The centre frame is now a
  crop of the pack's own setup shot, matched to the motion frames by head
  width and head height (`scripts`-adjacent tooling; see DECISIONS 72). Same
  model, camera, pose and light - no camera jump inside the cycle.
- **Numbering collision.** The repository already had head turns as
  `NECK_001`; the pack gives 001 to the chin tuck. The pack's numbering won
  and the older exercise moved to `NECK_002` with its content intact
  (DECISIONS 70-71).
- **All ten sets resized** from the delivered 1254x1254 to the 1024x1024
  master `docs/IMAGE_ASSET_SPEC.md` 2 requires.

### Open visual notes, not blocking

1. **`NECK_009` motion frames are framed tighter than the rest of the
   series.** Content reaches all four edges of the square; the other nine sit
   comfortably inside. This is the visible side of the pack's own note 3 - the
   NECK_009 assets were upscaled from 1024 to match the series - and it reads
   as a zoom-in when the catalog is scrolled.
2. **`NECK_005` motion 02 puts the head against the top edge.** The lifted
   chin reaches the top margin, against the series' own
   `active_limb_safe_margin_min: 0.05`. It is a head rather than a swinging
   limb, so nothing is cut off mid-movement, but it is the tightest frame in
   the set.
3. **`NECK_010` motion frames do not share a crop.** `motion_01` is
   `FULL_SAFE` and `motion_02` is `UPPER_SAFE`, so the camera moves inside the
   cycle. The YAML declares this honestly
   (`motion_frames_same_crop: false`) rather than claiming otherwise; a
   matching `UPPER_SAFE` neutral-at-the-wall frame would remove it.
4. Every `UPPER_SAFE` neck frame reports content at the bottom edge. That is
   the torso continuing out of the crop, which is what `UPPER_SAFE` means, and
   is expected rather than a defect.

