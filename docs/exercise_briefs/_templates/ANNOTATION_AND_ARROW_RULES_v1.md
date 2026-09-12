# ANNOTATION AND ARROW RULES v1

## Purpose
This document defines when arrows and short annotations are allowed in exercise visuals.

## Core rule
Arrows and explanatory text are **not allowed** inside runtime production image assets used directly by the app.

Runtime production assets must remain clean:
- no arrows
- no labels
- no interface chrome
- no captions
- no watermark

## Where arrows are allowed
Arrows are allowed in:
- visual brief sheets
- QA documentation
- internal design / review materials
- optional annotated helper images if the project later chooses to store them separately

## When arrows are recommended
Use arrows in the visual brief when:
- the movement is subtle;
- the direction is easy to misunderstand;
- left/right orientation must be clarified;
- the user may confuse backward vs downward motion.

Examples:
- `NECK_001` — chin goes **back**, not down;
- `NECK_002` — turn left / turn right;
- future wrist, shoulder, ankle, or eye exercises with subtle direction.

## Annotation style
Recommended arrow style:
- simple, clean, unobtrusive;
- one-color arrow (blue or project accent color);
- placed near the moving body part;
- should not hide anatomy or the movement path.

Short text annotation is allowed only when necessary, for example:
- `назад, не вниз`
- `вліво`
- `вправо`

## Naming recommendation for annotated files
Documentation images may use:
- `EXERCISE_ID_brief_sheet_v1.png`
- optionally later `EXERCISE_ID_brief_sheet_v2.png`
- if separate annotated helper assets are ever stored, use suffix `_annotated.png`

## Repository use
The app consumes clean production assets only.
Annotated visuals belong to documentation, not runtime.


## Mirror labeling for frontal exercises
For some front-view exercises, especially neck movements, explanatory captions in visual brief sheets may follow the user's mirror perception (for example, the user sees the model tilt as “вправо” when it appears as their own right side in a mirror).
This affects documentation captions only and does not require renaming runtime asset filenames.
