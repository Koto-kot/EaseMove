#!/usr/bin/env python3
"""Generate a voice pack from the cue texts in the exercise library.

    python scripts/generate_voice.py --lang uk                      # plan only
    python scripts/generate_voice.py --lang en --engine sapi --yes  # local, offline
    python scripts/generate_voice.py --lang uk --yes                # OpenAI speech API
    python scripts/generate_voice.py --lang en --engine sapi --only ELBOW_001 --yes

Nothing is written without `--yes`: the default run prints every line it would
speak and the file it would write, so a wrong line costs nothing.

The lines come from the same place as docs/generated/AUDIO_SCRIPT.md — the
`audio.events` blocks of the exercise files — so what is spoken is word for
word what a person in a booth would have been handed. A file that already
exists is left alone unless `--force` is passed, which makes the script safe
to re-run after adding one exercise.

## Engines

`sapi` (Windows only, no network, no key)
    Speaks with an installed system voice and encodes the result with ffmpeg.
    Whether a language works depends on what is installed: run
    `--engine sapi --lang xx` without `--yes` and the script reports the voice
    it found, or says there is none.

`openai` (default)
    `pip install -r tools/requirements-generate.txt`, then put the key in
    `.env` at the repo root (gitignored):

        OPENAI_API_KEY=sk-...

    The script reads it from the environment; it is never printed or
    committed.

Either way this is a *placeholder* pack: good enough to hear the session end
to end and to judge pacing, not a substitute for the recorded voice the briefs
ask for. `clinical.safety.requires_professional_review.voice_cues` is still
true afterwards.
"""
from __future__ import annotations

import argparse
import json
import os
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

import yaml

if hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(errors="replace")

ROOT = Path(__file__).resolve().parents[1]
DATA = ROOT / "data"

AUTHORING_LOCALE = "uk"

MODEL = "gpt-4o-mini-tts"

# Calm, low-energy and unhurried, which is the `voice_style_uk` every exercise
# file declares. `alloy` is the most neutral of the preset voices.
VOICE = "alloy"

OPENAI_INSTRUCTIONS = (
    "Calm, friendly, clear and unhurried, at a slightly slower than normal "
    "pace, with no motivational energy and no shouting. This is guidance for "
    "someone moving gently, possibly an older person."
)

# The container the exercise files ask for. AAC is what an .m4a carries, and
# just_audio plays it on every target.
RESPONSE_FORMAT = "aac"

# Slower than the system default, for the same reason.
SAPI_RATE = -2

# Mono is plenty for speech and keeps the bundle small.
SAPI_SAMPLE_RATE = 22050

# docs/AUDIO_SPEC.md, recording pipeline: normalized, with silence trimmed.
# The synthesizer leaves up to a second of padding at each end, which on the
# one-second countdown ticks is the difference between "three" and "three"
# landing on top of "two".
FFMPEG_FILTER = (
    "silenceremove=start_periods=1:start_threshold=-50dB:start_silence=0.05:"
    "stop_periods=-1:stop_threshold=-50dB:stop_silence=0.08,"
    "loudnorm=I=-16:TP=-1.5:LRA=11"
)

# Spoken once and reused by every exercise (docs/AUDIO_SPEC.md).
COUNTDOWN = {
    "uk": {5: "П'ять.", 4: "Чотири.", 3: "Три.", 2: "Два.", 1: "Один."},
    "en": {5: "Five.", 4: "Four.", 3: "Three.", 2: "Two.", 1: "One."},
}


def load_env() -> None:
    """Read `.env` without adding a dependency, and never override a value
    already exported in the shell."""
    path = ROOT / ".env"
    if not path.exists():
        return
    for line in path.read_text(encoding="utf-8").splitlines():
        line = line.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        key, _, value = line.partition("=")
        os.environ.setdefault(key.strip(), value.strip().strip('"').strip("'"))


def openai_client():
    """Imported lazily so a planning run needs neither the package nor a key."""
    try:
        from openai import OpenAI  # noqa: PLC0415
    except ImportError as exc:
        raise SystemExit(
            "ERROR: pip install -r tools/requirements-generate.txt"
        ) from exc
    load_env()
    if not os.environ.get("OPENAI_API_KEY"):
        raise SystemExit(
            "ERROR: OPENAI_API_KEY is not set. Put it in .env at the repo "
            "root (gitignored) or export it in the shell."
        )
    return OpenAI()


def load_yaml(path: Path):
    return yaml.safe_load(path.read_text(encoding="utf-8"))


def localized(target: str, lang: str) -> str:
    """`audio/uk/...` as authored -> the same file under the wanted language."""
    parts = target.split("/")
    if len(parts) >= 3 and parts[0] == "audio":
        parts[1] = lang
    return "/".join(parts)


def collect(lang: str, only: str | None) -> list[tuple[str, str, str]]:
    """(target file, text, where it came from), deduplicated by target file."""
    lines: dict[str, tuple[str, str]] = {}

    if only is None:
        for seconds, text in COUNTDOWN.get(lang, {}).items():
            lines["audio/{0}/common/countdown_{1}.m4a".format(lang, seconds)] = (
                text,
                "countdown",
            )

    index = load_yaml(DATA / "exercises/index.yaml")
    for entry in index["exercises"]:
        if only and entry["id"] != only:
            continue
        raw = load_yaml(DATA / "exercises" / entry["file"])
        for event in raw.get("audio", {}).get("events", []):
            text = event.get("text_" + lang)
            target = event.get("target_file")
            if not text or not target:
                continue
            # First writer wins: a common cue is identical everywhere, and
            # this keeps the order stable across runs.
            lines.setdefault(
                localized(target, lang),
                (text, "{0}/{1}".format(entry["id"], event["id"])),
            )

    return [(target, lines[target][0], lines[target][1]) for target in sorted(lines)]


def missing_text(lang: str) -> list[str]:
    """Cues that have no line in this language, so the pack cannot be complete."""
    gaps: list[str] = []
    index = load_yaml(DATA / "exercises/index.yaml")
    for entry in index["exercises"]:
        raw = load_yaml(DATA / "exercises" / entry["file"])
        for event in raw.get("audio", {}).get("events", []):
            if event.get("text_" + AUTHORING_LOCALE) and not event.get("text_" + lang):
                gaps.append("{0}/{1}".format(entry["id"], event["id"]))
    return gaps


# ------------------------------------------------------------------- sapi ---


def find_ffmpeg(explicit: str | None) -> str:
    if explicit:
        if not Path(explicit).exists():
            raise SystemExit("ERROR: no ffmpeg at " + explicit)
        return explicit
    found = shutil.which("ffmpeg")
    if not found:
        raise SystemExit(
            "ERROR: ffmpeg is needed to write .m4a and was not found on PATH. "
            "Install it, or pass --ffmpeg with the full path."
        )
    return found


def powershell() -> str:
    for name in ("pwsh", "powershell"):
        found = shutil.which(name)
        if found:
            return found
    raise SystemExit("ERROR: the sapi engine needs PowerShell, which is Windows only.")


def sapi_voice(lang: str) -> str | None:
    """The first installed system voice whose culture matches [lang]."""
    script = (
        "Add-Type -AssemblyName System.Speech; "
        "(New-Object System.Speech.Synthesis.SpeechSynthesizer)."
        "GetInstalledVoices() | ForEach-Object "
        "{ $_.VoiceInfo.Name + '|' + $_.VoiceInfo.Culture }"
    )
    result = subprocess.run(
        [powershell(), "-NoProfile", "-NonInteractive", "-Command", script],
        capture_output=True,
        text=True,
        check=False,
    )
    for line in result.stdout.splitlines():
        name, _, culture = line.partition("|")
        if culture.strip().lower().startswith(lang.lower()):
            return name.strip()
    return None


def speak_with_sapi(
    todo: list[tuple[str, str, str]], voice: str, ffmpeg: str
) -> list[str]:
    """One PowerShell run for all the WAVs, then ffmpeg per file.

    Starting PowerShell once rather than per line is the difference between
    seconds and a minute and a half for a full pack.
    """
    written: list[str] = []
    with tempfile.TemporaryDirectory() as tmp:
        manifest = [
            {"text": text, "wav": str(Path(tmp) / ("line_%03d.wav" % n))}
            for n, (_, text, _) in enumerate(todo)
        ]
        manifest_path = Path(tmp) / "lines.json"
        manifest_path.write_text(
            json.dumps(manifest, ensure_ascii=False), encoding="utf-8"
        )

        script = """
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Speech
$lines = Get-Content -Raw -Encoding UTF8 '{manifest}' | ConvertFrom-Json
$synth = New-Object System.Speech.Synthesis.SpeechSynthesizer
$synth.SelectVoice('{voice}')
$synth.Rate = {rate}
$format = New-Object System.Speech.AudioFormat.SpeechAudioFormatInfo(
    {sample_rate},
    [System.Speech.AudioFormat.AudioBitsPerSample]::Sixteen,
    [System.Speech.AudioFormat.AudioChannel]::Mono)
foreach ($line in $lines) {{
    $synth.SetOutputToWaveFile($line.wav, $format)
    $synth.Speak($line.text)
}}
$synth.SetOutputToNull()
$synth.Dispose()
""".format(
            manifest=str(manifest_path).replace("'", "''"),
            voice=voice.replace("'", "''"),
            rate=SAPI_RATE,
            sample_rate=SAPI_SAMPLE_RATE,
        )
        script_path = Path(tmp) / "speak.ps1"
        script_path.write_text(script, encoding="utf-8")

        result = subprocess.run(
            [
                powershell(),
                "-NoProfile",
                "-NonInteractive",
                "-ExecutionPolicy",
                "Bypass",
                "-File",
                str(script_path),
            ],
            capture_output=True,
            text=True,
            check=False,
        )
        if result.returncode != 0:
            print(result.stdout)
            print(result.stderr)
            raise SystemExit("ERROR: speech synthesis failed")

        for (target, _, _), item in zip(todo, manifest):
            wav = Path(item["wav"])
            if not wav.exists() or wav.stat().st_size == 0:
                print("  FAILED {0}: nothing was spoken".format(target))
                continue
            path = ROOT / target
            path.parent.mkdir(parents=True, exist_ok=True)
            encode = subprocess.run(
                [
                    ffmpeg,
                    "-hide_banner",
                    "-loglevel",
                    "error",
                    "-y",
                    "-i",
                    str(wav),
                    "-af",
                    FFMPEG_FILTER,
                    "-c:a",
                    "aac",
                    "-b:a",
                    "64k",
                    "-ar",
                    "44100",
                    "-ac",
                    "1",
                    str(path),
                ],
                capture_output=True,
                text=True,
                check=False,
            )
            if encode.returncode != 0:
                print("  FAILED {0}: {1}".format(target, encode.stderr.strip()))
                continue
            written.append(target)
            print("  wrote {0} ({1} bytes)".format(target, path.stat().st_size))
    return written


# ----------------------------------------------------------------- openai ---


def speak_with_openai(todo: list[tuple[str, str, str]], lang: str) -> list[str]:
    api = openai_client()
    written: list[str] = []
    for target, text, _ in todo:
        path = ROOT / target
        path.parent.mkdir(parents=True, exist_ok=True)
        try:
            response = api.audio.speech.create(
                model=MODEL,
                voice=VOICE,
                input=text,
                instructions="Speak {0}. {1}".format(
                    "Ukrainian" if lang == "uk" else lang, OPENAI_INSTRUCTIONS
                ),
                response_format=RESPONSE_FORMAT,
            )
            path.write_bytes(response.read())
        except Exception as exc:  # noqa: BLE001 - report and keep going
            print("  FAILED {0}: {1}".format(target, exc))
            continue
        written.append(target)
        print("  wrote {0} ({1} bytes)".format(target, path.stat().st_size))
    return written


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--lang", default=AUTHORING_LOCALE, help="uk (default) or en")
    parser.add_argument(
        "--engine",
        default="openai",
        choices=("openai", "sapi"),
        help="openai (default) or sapi, the local Windows voice",
    )
    parser.add_argument("--only", help="one exercise id, e.g. ELBOW_001")
    parser.add_argument(
        "--yes", action="store_true", help="actually generate and write files"
    )
    parser.add_argument(
        "--force", action="store_true", help="re-record lines that already exist"
    )
    parser.add_argument("--ffmpeg", help="path to ffmpeg, if it is not on PATH")
    args = parser.parse_args()

    lines = collect(args.lang, args.only)
    if not lines:
        print(
            "No lines for language {0}: the exercise files carry no "
            "`text_{0}`.".format(args.lang)
        )
        return 1

    gaps = missing_text(args.lang)
    todo = [item for item in lines if args.force or not (ROOT / item[0]).exists()]

    voice = None
    if args.engine == "sapi":
        voice = sapi_voice(args.lang)

    print("language:       {0}".format(args.lang))
    print("lines in scope: {0}".format(len(lines)))
    print("to generate:    {0}".format(len(todo)))
    if args.engine == "sapi":
        print("engine:         system voice {0}".format(voice or "NONE INSTALLED"))
    else:
        print("engine:         {0}, voice {1}".format(MODEL, VOICE))
    if gaps:
        print(
            "untranslated:   {0} cue(s) have no text_{1}, e.g. {2}".format(
                len(gaps), args.lang, ", ".join(gaps[:3])
            )
        )
    print()

    for target, text, source in todo:
        print("  {0}".format(target))
        print("      [{0}] {1}".format(source, text))

    if not todo:
        print("Nothing to do. Pass --force to re-record.")
        return 0

    if not args.yes:
        print()
        print("Planning run: nothing was written. Add --yes to generate.")
        return 0

    if args.engine == "sapi":
        if not voice:
            raise SystemExit(
                "ERROR: no system voice is installed for '{0}'. Add one in "
                "Windows Settings, or use the openai engine.".format(args.lang)
            )
        written = speak_with_sapi(todo, voice, find_ffmpeg(args.ffmpeg))
    else:
        written = speak_with_openai(todo, args.lang)

    print()
    print("generated {0} of {1}".format(len(written), len(todo)))
    print("Now run: python scripts/build_audio_script.py")
    return 0 if len(written) == len(todo) else 1


if __name__ == "__main__":
    sys.exit(main())
