# KNEE_001 — Voice cues

Source: `data/exercises/knees/KNEE_001.yaml` → `audio.events` + `docs/AUDIO_SPEC.md`.

Recording status in YAML: `not_recorded`.
Master: WAV (normalized, silence trimmed) → app delivery: M4A.
Voice style: спокійний, доброзичливий, чіткий, без поспіху; короткі фрази.
Mix: voice 100%, music 50% relative, no dynamic ducking.
Priority rule: movement cue > progress cue.

## Exercise-specific — `audio/uk/exercises/KNEE_001/`

| ID | File | Text (uk) | Type | Trigger | Priority | Notes |
|---|---|---|---|---|---|---|
| `VOICE_PREPARE` | `prepare.m4a` | Приготуйтеся. Сядьте рівно, стопи поставте на підлогу. | instruction | prep_countdown_started | 80 | interruptible |
| `VOICE_EXTEND` | `extend.m4a` | Повільно випряміть ногу. | movement | PHASE_EXTEND started | 100 | not interruptible |
| `VOICE_TOES` | `toes.m4a` | Підтягніть носок до себе. | technique | repetition 1 started | 70 | play_once_per_side |
| `VOICE_LOWER` | `lower.m4a` | Повільно опустіть ногу. | movement | PHASE_LOWER started | 100 | not interruptible |

## Common reusable — `audio/uk/common/`

| ID | File | Text (uk) | Type | Trigger | Priority | Notes |
|---|---|---|---|---|---|---|
| `VOICE_HOLD` | `hold.m4a` | Тримайте. | movement | PHASE_HOLD started | 90 | interruptible |
| `VOICE_SWITCH_SIDE` | `switch_leg.m4a` | Тепер інша нога. | transition | left side_block completed | 120 | not interruptible |
| `VOICE_HALFWAY` | `halfway.m4a` | Половину виконано. | progress | progress 50% | 50 | delay until primary cue finishes |
| `VOICE_LAST_REP` | `last_repetition.m4a` | Останній повтор. | progress | last repetition started | 60 | delay until primary cue finishes |
| `VOICE_COMPLETED` | `completed.m4a` | Готово. | completion | exercise_completed | 120 | not interruptible |

## Global countdown pack

Use global audio pack for seconds: **5, 4, 3, 2, 1** (prep countdown 5 s).

## Recording checklist

- [ ] All exercise-specific M4A files exist under `audio/uk/exercises/KNEE_001/`
- [ ] Common pack exists under `audio/uk/common/` (shared across exercises)
- [ ] Countdown pack available
- [ ] Masters archived as WAV
- [ ] Levels normalized; leading/trailing silence trimmed
- [ ] Clinical review of voice cues (`requires_professional_review.voice_cues: true`)
- [ ] Update YAML `audio.recording_spec.current_status` when recorded
