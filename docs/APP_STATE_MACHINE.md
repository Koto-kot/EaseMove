# App / Exercise State Machine

## Exercise session states

```text
BROWSING
  ↓ select
SELECTED
  ↓ Start
PREP_COUNTDOWN
  ↓ 0
ACTIVE
  ↔ PAUSED
  ↓ normal completion
COMPLETED
  ↓
AUTO_REST
  ↓ 0
PREP_AUTO_START / ACTIVE_NEXT
```

Додаткові виходи:

```text
ACTIVE → STOPPED
PAUSED → STOPPED
AUTO_REST → MANUAL_BROWSE_NEXT   (Previous/Next)
ANY_SESSION_STATE → EXITED
```

## State semantics

### BROWSING
Список зон, ситуацій або вправ.

### SELECTED
Вправа обрана, але ще не запущена.

### PREP_COUNTDOWN
5 секунд. Timer вправи ще не йде.

### ACTIVE
Працюють:
- sequence engine;
- elapsed time;
- progress;
- repetition model;
- animation;
- voice;
- music.

### PAUSED
Sequence position зберігається.

### STOPPED
User-initiated early stop. Немає failure UI.

### COMPLETED
Prescription/sequence завершена штатно.

### AUTO_REST
10 секунд. Видима наступна вправа. На 0 auto-start.

### MANUAL_BROWSE_NEXT
Auto-mode вимкнений. Вибір користувача вимагає Start.

## Events

- `SELECT_EXERCISE`
- `START`
- `PREP_TICK`
- `PREP_FINISHED`
- `PAUSE`
- `RESUME`
- `STOP`
- `PREVIOUS`
- `NEXT`
- `SEQUENCE_STEP_FINISHED`
- `REPETITION_FINISHED`
- `SIDE_BLOCK_FINISHED`
- `EXERCISE_FINISHED`
- `REST_TICK`
- `REST_FINISHED`
- `EXIT`

## Critical invariants

1. `STOP` приймається в будь-якому активному session state.
2. `Previous/Next` під час AUTO_REST скасовує autoplay.
3. Ручний вибір ніколи не запускає вправу без Start.
4. Auto-next не показує skip-rest.
5. Production не запускає unapproved exercise.
6. Timer, animation і voice керуються однією sequence timeline, а не незалежними таймерами.
