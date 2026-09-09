# Exercise Engine

## Мета

Одна універсальна runtime-система виконує необмежену кількість вправ із YAML/JSON content blocks.
Нові вправи не повинні вимагати нового hard-coded screen.

## Exercise = data

Кожна вправа описує:

- identity;
- zone/tags/collections;
- clinical status;
- localized text;
- timing/prescription;
- repetition model;
- movement phases;
- sequence steps;
- animation frames;
- audio events;
- music behavior;
- flow;
- tracking;
- Pro eligibility;
- assets;
- QA;
- references.

## Collections vs tags

### Tags
Описують властивість:
- `neck`
- `computer`
- `sitting`
- `supine`
- `mobility`
- `balance_component`

### Collections
Описують curated destination:
- `body_neck`
- `body_knees`
- `computer_break`
- `bed_basic`

Membership у collection зберігається в самій вправі.
`collection_candidates` — редакторська підказка, але не показує вправу автоматично.

## Runtime algorithm

1. Load exercise record.
2. Reject if environment/clinical gate не дозволяє показ.
3. Resolve localization.
4. Resolve selected variant.
5. Resolve prescription.
6. Build normalized sequence timeline.
7. Bind frames and audio events to sequence events.
8. Execute through state machine.
9. Track actual result.
10. Resolve next exercise from current collection.

## Timeline rule

Animation, voice and progress не запускаються окремими `setTimeout`.
Sequence Engine є single source of truth.

При Pause:
- timeline freezes;
- elapsed active time freezes;
- animation freezes;
- scheduled cues freeze/cancel/resume safely.

## Repetition models

Схема v1.3 підтримує щонайменше:

- `sequence_time`
- `full_cycle`
- `side_blocks`
- bilateral alternating
- bilateral simultaneous
- hold phases
- transition/checkpoint phases
- surface-slide phases

## Variants

Exercise може мати variants:
- assistance;
- surface;
- easier/harder;
- position.

Variant не повинен автоматично змінюватися без явної approved logic.

## Clinical gate

Development:
- можна показувати `pending_review`.

Production:
- тільки `approved`.

Це має бути централізована функція, не scattered conditions.

## Scaling

Бібліотека повинна підтримувати сотні вправ.
Exercise list UI використовує metadata; Player завантажує повний record тільки для selected/next items.
