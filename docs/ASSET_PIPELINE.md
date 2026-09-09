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

### `scripts/generate_frames.py`

Генерація кадрів через OpenAI Images (`gpt-image-1`).

```bash
pip install -r tools/requirements-generate.txt
cp .env.example .env          # і вписати OPENAI_API_KEY

python scripts/generate_frames.py --only KNEE_001          # тільки план
python scripts/generate_frames.py --only KNEE_001 --yes    # генерувати
python scripts/generate_frames.py --body-map --yes
```

**Майстер-кадр + редагування.** Складність не в якості картинки, а в тому, щоб
це була *та сама* картинка 5 разів із переставленою ногою. Текстові промпти
дрифтують, тому перший кадр вправи генерується з нуля, а кожен наступний — як
**edit цього майстер-кадру**, який передається назад як reference. Опис позы
тоді описує лише зміну, а не сцену. Для body map так само: `back.png` — це
edit `front.png`, тому обидві фігури мають однакову висоту й масштаб, як і
вимагають спільні нормалізовані hotspot-и.

Промпти складаються тими самими функціями, що пишуть `IMAGE_BRIEFS.md`, тому
API отримує дослівно те саме, що отримав би ілюстратор.

Запобіжники:

- без `--yes` нічого не надсилається — друкується точний промпт кожного
  зображення, тож неправильна поза коштує нуль;
- наявний файл не перезаписується без `--force`: вибраний кадр не має тихо
  зникати;
- `--budget` (типово 8) не дає одному запуску спалити всю бібліотеку;
- `--variants N` пише альтернативи в `build/frame-candidates/`, а не на робочий
  шлях — обраний варіант копіюється руками.

`--transparent` / `--opaque` перекривають `asset_spec`. Для body map прозорий
фон стоїть типово, хоча брифи для людини просять світлий: застосунок накладає
фігуру на власне тло, і світла підкладка виглядала б як біла плита в темній
темі.

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
