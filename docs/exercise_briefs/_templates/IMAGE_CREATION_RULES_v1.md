# IMAGE CREATION RULES v1

## 1. General style
Use a calm wellbeing / physiotherapy-instructional visual style.
This project is not bodybuilding, not fitness-magazine, and not medical diagnosis imagery.

### Model baseline
- adult of ordinary non-athletic build
- neutral, friendly, calm appearance
- simple plain clothing
- no logos
- clean neutral light background
- soft even lighting

## 2. Image types
There are two image types in this repository:

### A. Production images
Used directly by the app.
Rules:
- no text
- no UI
- no arrows
- no watermarks
- clean isolated instructional look

### B. Visual brief sheets
Used for documentation only.
May include:
- exercise title
- panel labels
- short explanatory captions

## 3. Consistency inside one exercise
Within one exercise, keep:
- same person
- same outfit
- same props
- same environment
- same camera angle for motion frames
- same scale unless a specific framing rule says otherwise

## 4. Special rule for neck exercises
For neck exercises:
- the first image should usually show the **whole body in the initial position**
- motion images may use a closer **UPPER_SAFE** crop if this makes the neck movement clearer
- the closer crop must still fully show the head, neck, and any relevant shoulders / hands

## 5. Safety-first framing
Never crop the active moving body part.
Avoid cutting through:
- neck
- shoulders
- elbows
- wrists
- fingers
- hips
- knees
- ankles
- toes

If in doubt, choose a wider framing.

## 6. Approved framing suffixes
- `full_safe`
- `mid_safe`
- `upper_safe`
- `lower_safe`
- `detail_safe`

Use only one of these in the filename.

## 7. Preview image
`preview.png` should be a clean representative thumbnail for lists/cards.
Usually it is copied from:
- setup image, or
- the clearest motion image

## 8. Runtime vs documentation
Runtime app uses only:
- production images
- YAML data
- audio cues

The app does not use:
- visual brief sheet PNGs
- README documentation


## 9. Arrow policy
See `ANNOTATION_AND_ARROW_RULES_v1.md`.
Production runtime images must stay clean. Arrows are allowed only in visual brief sheets and other documentation artifacts.


## 10. Mirror-format documentation captions
For selected front-view exercises, especially neck exercises, the visual brief may use mirror-style left/right captions when that improves user understanding. Runtime image assets remain unchanged and contain no text.
