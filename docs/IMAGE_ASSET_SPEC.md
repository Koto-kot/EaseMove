# Image Asset Technical Specification v1.0

## 1. Формати

### Exercise frames
- preferred source: PNG;
- production delivery: PNG/WebP залежно від implementation benchmark;
- master не повинен мати compression artifacts;
- alpha дозволений, якщо background не є змістовною частиною вправи.

### Body map
- preferred: SVG або високоякісний PNG/WebP;
- hotspot layer не вбудовується у bitmap.

## 2. Базовий master size

Exercise frame:
- 1024 × 1024 px master;
- aspect ratio 1:1;
- Flutter може використовувати responsive contain/fit.

Body map:
- master portrait aspect ratio;
- рекомендовано щонайменше 1200 px по висоті для raster;
- SVG preferred, якщо фінальний стиль стабільний.

## 3. Safe area

Ключові частини тіла мають залишатися всередині центральних ~90% canvas.
Не притискати голову, кисті чи стопи до краю без потреби.

## 4. Naming

```text
assets/exercises/<EXERCISE_ID>/
  preview.png
  frame_<semantic_name>.png
```

Приклади:
- `frame_start.png`
- `frame_left_mid.png`
- `frame_left_extended.png`
- `frame_standing.png`

Не використовувати `image1.png`, `final2.png`, `new.png`.

## 5. Source of truth

Список required assets задає YAML вправи:

```yaml
assets:
  required:
    - preview.png
    - frame_start.png
```

Flutter/runtime не повинен вгадувати назви.

## 6. Frame consistency checklist

Усі кадри однієї вправи:
- same subject;
- same clothing;
- same camera;
- same crop;
- same background;
- same furniture;
- same lighting style;
- same visual scale;
- same floor/surface.

## 7. No baked-in UI

Forbidden:
- text;
- arrows;
- badges;
- timers;
- progress bars;
- numbers;
- branding;
- watermark.

## 8. Accessibility

- достатній contrast;
- поза зрозуміла без color-only cue;
- важливі кінцівки не перекриваються;
- silhouette читається;
- YAML містить `alt_text_uk`, надалі інші мови.

## 9. Body map assets

```text
assets/body-map/
  body_front.svg        # future production
  body_back.svg         # future production
  reference/            # optional non-production references
```

Hotspots зберігаються окремо:
`data/categories/body_hotspots.yaml`.

## 10. Body map coordinate system

Hotspot coordinates normalized:
- x/y/width/height = 0.0–1.0 відносно відповідного front/back canvas;
- origin = top-left;
- Flutter масштабує normalized rect разом із actual rendered body-map bounds.

## 11. Asset states

Рекомендовані metadata:
- `reference`
- `draft`
- `pending_review`
- `approved`
- `retired`

Production bundle включає лише approved production assets.

## 12. QA before commit

Перевірити:
- filenames;
- dimensions;
- correct pose;
- correct side;
- no embedded text;
- no watermark;
- consistent character;
- exact chair/surface;
- YAML path exists;
- clinical pose review status.
