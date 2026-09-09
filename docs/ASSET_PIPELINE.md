# Asset Pipeline

## Правило

Одна exercise infographic не є production asset.

Production workflow:

`1 exercise YAML → exact frame brief → 2–6 original frames → QA → clinical pose review → approved assets`

## Exercise folder

Наприклад:

```text
assets/exercises/KNEE_001/
  preview.png
  frame_start.png
  frame_left_mid.png
  frame_left_extended.png
  frame_right_mid.png
  frame_right_extended.png
```

YAML є source of truth для required filenames.

## Frame consistency

Усі кадри вправи:
- та сама людина/персонаж;
- той самий одяг;
- той самий camera angle;
- той самий crop;
- та сама опора/стілець/ліжко;
- без тексту у зображенні;
- без watermark.

## Animation

Runtime:
- frame sequence;
- optional smooth interpolation;
- reduced-motion fallback = static steps.

## Preview

Preview може використовувати один ключовий frame.
Текст назви накладає UI, не image.


## Related specifications

- `VISUAL_STYLE_GUIDE.md`
- `IMAGE_ASSET_SPEC.md`
- `EXERCISE_IMAGE_QA.md`
- `IMAGE_BRIEF_TEMPLATE.md`
- `BODY_MAP_SPEC.md`
