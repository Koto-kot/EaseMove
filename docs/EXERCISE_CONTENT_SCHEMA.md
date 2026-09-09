# Exercise Content Schema v1.3

## Формат

Canonical authoring format: **YAML**.

Runtime може перетворювати YAML у JSON/build artifact.

## Верхні блоки

- `schema_version`
- `content_version`
- `exercise`
- `clinical`
- `locale`
- `ui`
- `timing`
- `repetition_model` — optional за типом вправи
- `movement_phases` — optional
- `sequence`
- `animation`
- `audio`
- `music`
- `flow`
- `accessibility`
- `tracking`
- `pro`
- `assets`
- `qa`
- `references`
- `metadata`

## Обов’язкова ідентичність

```yaml
exercise:
  id: "KNEE_001"
  slug: "seated_knee_extension"
```

ID immutable після production release.

## Clinical status

```yaml
clinical:
  status: pending_review
```

Allowed:
- `draft`
- `pending_review`
- `approved`
- `retired`

Production runtime показує тільки `approved`.

## Localization

Поточні exercise-файли містять `locale.uk` як authoring source.
Пізніше build pipeline може винести локалізації у language packs без зміни ключів.

## Assets

Exercise містить точні path до:
- preview;
- frame images;
- audio.

Production image не повинен містити текст.
Увесь текст рендерить UI.

## Source prescriptions vs app prescription

Важливе правило:

- `source_prescriptions` = що пишуть джерела;
- `app_prototype_prescription` = наша тестова реалізація;
- production prescription = тільки після clinical approval.

## Schema evolution

v1.0 — проста mobility exercise.
v1.1 — anatomy + repetitions + side blocks.
v1.2 — functional transition + variants + environment + balance checkpoint.
v1.3 — supine positioning + surface contact + surface variants.

Нові поля мають бути backward-compatible, коли це можливо.
