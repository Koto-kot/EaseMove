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


## Tooling

Три скрипти обслуговують цей пайплайн. Усі читають ті самі YAML, що й
`build_content.py`, тому окремого списку файлів ніде не ведеться.

### `scripts/check_assets.py`

Технічна половина `EXERCISE_IMAGE_QA.md` (розділ F) плюс правила
`IMAGE_ASSET_SPEC.md`:

- файл існує, декодується, це PNG;
- розмір точно `asset_spec.width_px × height_px` (1024×1024);
- зображення не порожнє;
- контент лишається в центральних 90% канви — **warning**, бо підлога чи стіна
  можуть законно доходити до краю, а от кисть чи стопа — ні;
- `animation.frames` і `assets.required` описують той самий набір файлів;
- `preview.source_frame_id` вказує на існуючий кадр;
- папка вправи присутня в `flutter: assets:` у `pubspec.yaml` — інакше
  зображення не потрапляють у збірку і тихо не завантажуються;
- body map: `front.png` і `back.png` однакового розміру, portrait, ≥1200 px.

Exit 1 — лише якщо наявний файл неправильний. Ненамальований кадр
повідомляється й не валить збірку, тому крок працює в CI з першого дня;
`--require-complete` робить із нього жорсткий гейт, коли графіка має бути повна.

### `scripts/make_previews.py`

`preview.png` не малюється руками: це квадратний кроп кадру з
`animation.preview.source_frame_id`, підтягнутий на фігуру (bbox + 6% полів) і
зменшений до 512×512.

```bash
python scripts/make_previews.py           # тільки застарілі
python scripts/make_previews.py --force
```

Перегенерувати після перемалювання вихідного кадру.

### `scripts/build_review_sheet.py`

Генерує `tools/review.html` — кадри однієї вправи в рядок, у порядку
послідовності, з авторським описом позы під кожним і чеклістом A–E збоку.
Саме тут ловиться те, чого скрипт не бачить: інша людина, зсунутий стілець,
віддзеркалена сторона. Сторінка генерована, у git не комітиться.

```bash
python scripts/build_review_sheet.py --open
```

## Related specifications

- `VISUAL_STYLE_GUIDE.md`
- `IMAGE_ASSET_SPEC.md`
- `EXERCISE_IMAGE_QA.md`
- `IMAGE_BRIEF_TEMPLATE.md`
- `BODY_MAP_SPEC.md`
