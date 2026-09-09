# Exercise Image QA Checklist

## A. Identity / consistency
- Same subject across frames.
- Same clothing.
- Same hair.
- Same body proportions.
- Same camera/crop.
- Same background.

## B. Movement accuracy
- Frame order matches YAML sequence.
- Working side is correct.
- Stationary body parts remain stationary.
- Range is not exaggerated.
- Joint direction matches pose description.
- Contact points match clinical metadata.

## C. Equipment / environment
- Same chair/bed/mat in every frame.
- Chair does not move.
- Floor/surface does not deform.
- Required clearance is visible where needed.

## D. UI cleanliness
- No baked-in text.
- No arrows.
- No counters.
- No logo.
- No watermark.

## E. Accessibility
- Important limb is visible.
- Pose silhouette reads clearly.
- No essential cue depends only on color.
- Alt text exists in exercise YAML.

## F. Technical
- Correct filename.
- Correct path.
- Correct dimensions/aspect ratio.
- Image decodes successfully.
- Asset listed in exercise `assets.required`.

## G. Clinical gate
- Pose reviewed.
- Any easier/harder variant reviewed independently.
- Production status only after approval.
