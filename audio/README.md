# Audio assets

Directory convention:

```text
audio/
  uk/
    common/
      countdown_5.m4a ... countdown_1.m4a
      halfway.m4a
      completed.m4a
      count_one.m4a
      count_two.m4a
    exercises/
      ELBOW_001/
        setup.m4a
        start_movement.m4a
        phase_a.m4a
        phase_b.m4a
```

Common voice cues are recorded once and reused; exercise-specific phrases live
in the exercise folder. The exact file for every line is declared in the
exercise YAML (`audio.events[].target_file`) — nothing guesses a name.

What has to be recorded, and what already is:
`docs/generated/AUDIO_SCRIPT.md` (rebuild with
`python scripts/build_audio_script.py`).

A draft pack can be generated with `python scripts/generate_voice.py --yes`,
which needs `OPENAI_API_KEY` in `.env`. Until a line exists the app speaks it
with text-to-speech, so a partial pack is usable
(`lib/core/audio/recorded_voice_audio_service.dart`).
