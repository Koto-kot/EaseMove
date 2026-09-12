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

Each language repeats the same tree: `audio/en/` mirrors `audio/uk/` file for
file, and the app swaps the folder for the language it is running in.

What has to be recorded, and what already is:
`docs/generated/AUDIO_SCRIPT_UK.md` and `AUDIO_SCRIPT_EN.md` (rebuild with
`python scripts/build_audio_script.py`).

A draft pack can be generated:

```text
python scripts/generate_voice.py --lang en --engine sapi --yes   # local voice
python scripts/generate_voice.py --lang uk --yes                 # speech API
```

`sapi` uses an installed Windows voice and needs ffmpeg on PATH; `openai`
needs `OPENAI_API_KEY` in `.env`. Both packs were produced with `sapi` and are
complete — Ukrainian with RHVoice Natalia, English with Microsoft Zira.
Windows ships no Ukrainian voice, so uk needs RHVoice (or another SAPI5 voice)
installed first: `rhvoice.org/uk-voices/`.

Until a line exists the app speaks it with text-to-speech, so a partial pack —
a new language, or a new exercise before its lines are made — is usable
(`lib/core/audio/recorded_voice_audio_service.dart`).
