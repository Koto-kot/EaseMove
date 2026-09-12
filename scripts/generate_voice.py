#!/usr/bin/env python3
"""Generate the voice pack from the cue texts with the OpenAI speech API.

    python scripts/generate_voice.py                     # plan only
    python scripts/generate_voice.py --yes               # actually call
    python scripts/generate_voice.py --only ELBOW_001 --yes
    python scripts/generate_voice.py --yes --force       # re-record everything

Nothing is sent to the API without `--yes`: the default run prints every line
it would speak and the file it would write, so a wrong line costs nothing.

The lines come from the same place as docs/generated/AUDIO_SCRIPT.md — the
`audio.events` blocks of the exercise files — so what is spoken is word for
word what a person in a booth would have been handed. A file that already
exists is left alone unless `--force` is passed, which makes the script safe
to re-run after adding one exercise.

This produces a *placeholder* pack: good enough to hear the session end to
end and to judge pacing, not a substitute for the recorded voice the briefs
ask for. `clinical.safety.requires_professional_review.voice_cues` is still
true afterwards.

## Setup

    pip install -r tools/requirements-generate.txt

Put the key in `.env` at the repo root (already gitignored):

    OPENAI_API_KEY=sk-...

The script reads it from the environment; it is never printed or committed.
"""
from __future__ import annotations

import argparse
import os
import sys
from pathlib import Path

import yaml

if hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(errors="replace")

ROOT = Path(__file__).resolve().parents[1]
DATA = ROOT / "data"

LOCALE = "uk"

MODEL = "gpt-4o-mini-tts"

# Calm, low-energy and unhurried, which is the `voice_style_uk` every exercise
# file declares. `alloy` is the most neutral of the preset voices.
VOICE = "alloy"

INSTRUCTIONS = (
    "Speak Ukrainian. Calm, friendly, clear and unhurried, at a slightly "
    "slower than normal pace, with no motivational energy and no shouting. "
    "This is guidance for someone moving gently, possibly an older person."
)

# The container the exercise files ask for. The API returns raw AAC, which is
# what an .m4a wrapper carries, and just_audio plays it on every target.
RESPONSE_FORMAT = "aac"

# Spoken once and reused by every exercise (docs/AUDIO_SPEC.md).
COUNTDOWN = {
    5: "П'ять.",
    4: "Чотири.",
    3: "Три.",
    2: "Два.",
    1: "Один.",
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


def client():
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


def collect(only: str | None) -> list[tuple[str, str, str]]:
    """(target file, text, where it came from), deduplicated by target file."""
    lines: dict[str, tuple[str, str]] = {}

    if only is None:
        for seconds, text in COUNTDOWN.items():
            lines["audio/{0}/common/countdown_{1}.m4a".format(LOCALE, seconds)] = (
                text,
                "countdown",
            )

    index = load_yaml(DATA / "exercises/index.yaml")
    for entry in index["exercises"]:
        if only and entry["id"] != only:
            continue
        raw = load_yaml(DATA / "exercises" / entry["file"])
        for event in raw.get("audio", {}).get("events", []):
            text = event.get("text_" + LOCALE)
            target = event.get("target_file")
            if not text or not target:
                continue
            # First writer wins: a common cue is identical everywhere, and
            # this keeps the order stable across runs.
            lines.setdefault(target, (text, "{0}/{1}".format(entry["id"], event["id"])))

    return [(target, lines[target][0], lines[target][1]) for target in sorted(lines)]


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--only", help="one exercise id, e.g. ELBOW_001")
    parser.add_argument(
        "--yes", action="store_true", help="actually call the API and write files"
    )
    parser.add_argument(
        "--force", action="store_true", help="re-record lines that already exist"
    )
    args = parser.parse_args()

    lines = collect(args.only)
    todo = [
        item
        for item in lines
        if args.force or not (ROOT / item[0]).exists()
    ]

    print("lines in scope: {0}".format(len(lines)))
    print("to generate:    {0}".format(len(todo)))
    print("model:          {0}, voice {1}".format(MODEL, VOICE))
    print()

    for target, text, source in todo:
        print("  {0}".format(target))
        print("      [{0}] {1}".format(source, text))

    if not todo:
        print("Nothing to do. Pass --force to re-record.")
        return 0

    if not args.yes:
        print()
        print("Planning run: nothing was sent. Add --yes to generate.")
        return 0

    api = client()
    written = 0
    for target, text, source in todo:
        path = ROOT / target
        path.parent.mkdir(parents=True, exist_ok=True)
        try:
            response = api.audio.speech.create(
                model=MODEL,
                voice=VOICE,
                input=text,
                instructions=INSTRUCTIONS,
                response_format=RESPONSE_FORMAT,
            )
            path.write_bytes(response.read())
        except Exception as exc:  # noqa: BLE001 - report and keep going
            print("  FAILED {0}: {1}".format(target, exc))
            continue
        written += 1
        print("  wrote {0} ({1} bytes)".format(target, path.stat().st_size))

    print()
    print("generated {0} of {1}".format(written, len(todo)))
    print("Now run: python scripts/build_audio_script.py")
    return 0 if written == len(todo) else 1


if __name__ == "__main__":
    sys.exit(main())
