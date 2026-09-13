#!/usr/bin/env python3
"""Turn the licensed sources in data/music/tracks.yaml into the bundled pack.

    python scripts/build_music.py [--ffmpeg PATH] [--force]

Three things have to be true of background music that loops under a voice: it
must be free to ship, it must not change how loud the session is when the
listener switches track, and it must not click at the loop seam. So each
source is downloaded once, normalised to one integrated loudness with a
two-pass EBU R128 measurement, faded at both ends and encoded to the small AAC
file the app bundles.

The produced `.m4a` files are committed, so CI never runs this and never needs
ffmpeg; scripts/check_assets.py only checks that every declared track is on
disk. Re-run this when a track is added or replaced.
"""
from __future__ import annotations

import argparse
import json
import os
import re
import shutil
import subprocess
import sys
import urllib.request
from pathlib import Path

import yaml

if hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(errors="replace")

ROOT = Path(__file__).resolve().parents[1]
CATALOGUE = ROOT / "data/music/tracks.yaml"
CACHE = ROOT / "build/music_src"

# Windows has no ffmpeg on PATH here; this is where a CapCut install keeps one.
FALLBACK_FFMPEG = (
    Path(os.environ.get("LOCALAPPDATA", "")) / "CapCut/Apps/8.4.0.3562/ffmpeg.exe"
)


def find_ffmpeg(explicit: str | None) -> Path:
    for candidate in (explicit, shutil.which("ffmpeg"), FALLBACK_FFMPEG):
        if candidate and Path(candidate).exists():
            return Path(candidate)
    raise SystemExit(
        "ffmpeg not found. Pass --ffmpeg PATH; the built tracks are committed, "
        "so this is only needed when a track changes."
    )


def run(ffmpeg: Path, args: list[str]) -> str:
    """ffmpeg writes everything interesting to stderr, including the JSON."""
    done = subprocess.run(
        [str(ffmpeg), "-hide_banner", "-nostdin", "-y", *args],
        capture_output=True,
        text=True,
        errors="replace",
    )
    if done.returncode != 0:
        print(done.stderr[-2000:])
        raise SystemExit("ffmpeg failed: " + " ".join(args[:6]))
    return done.stderr


def download(url: str, target: Path) -> None:
    if target.exists() and target.stat().st_size > 0:
        return
    target.parent.mkdir(parents=True, exist_ok=True)
    print("  downloading {0}".format(url.rsplit("/", 1)[-1][:60]))
    request = urllib.request.Request(
        url, headers={"User-Agent": "EaseMove asset pipeline (build_music.py)"}
    )
    with urllib.request.urlopen(request, timeout=180) as response:
        target.write_bytes(response.read())


def measure(ffmpeg: Path, source: Path, loudness: dict) -> dict:
    """First pass: what this file actually measures, in EBU R128 terms."""
    stderr = run(
        ffmpeg,
        [
            "-i",
            str(source),
            "-af",
            "loudnorm=I={0}:TP={1}:LRA=11:print_format=json".format(
                loudness["integrated_lufs"], loudness["true_peak_dbtp"]
            ),
            "-f",
            "null",
            "-",
        ],
    )
    match = re.search(r"\{[^{}]*\"input_i\"[^{}]*\}", stderr, re.S)
    if not match:
        raise SystemExit("no loudnorm measurement for {0}".format(source.name))
    return json.loads(match.group(0))


def duration_ms(ffmpeg: Path, source: Path) -> int:
    """This ffmpeg build ships no ffprobe, so the header line is read instead."""
    stderr = run(ffmpeg, ["-i", str(source), "-f", "null", "-"])
    match = re.search(r"Duration: (\d+):(\d+):(\d+)\.(\d+)", stderr)
    if not match:
        raise SystemExit("no duration for {0}".format(source.name))
    hours, minutes, seconds, hundredths = (int(g) for g in match.groups())
    return ((hours * 60 + minutes) * 60 + seconds) * 1000 + hundredths * 10


def encode(
    ffmpeg: Path,
    source: Path,
    target: Path,
    stats: dict,
    loudness: dict,
    encoding: dict,
    length_ms: int,
) -> None:
    fade_in = encoding["fade_in_ms"] / 1000
    fade_out = encoding["fade_out_ms"] / 1000
    fade_out_at = max(0.0, length_ms / 1000 - fade_out)
    # Second pass: the measured values turn loudnorm from a guess into an exact
    # gain, and the limiter only engages on a track that needs lifting.
    chain = (
        "loudnorm=I={target_i}:TP={target_tp}:LRA=11:"
        "measured_I={measured_i}:measured_TP={measured_tp}:"
        "measured_LRA={measured_lra}:measured_thresh={measured_thresh}:"
        "offset={offset}:linear=true,"
        "afade=t=in:st=0:d={fade_in},"
        "afade=t=out:st={fade_out_at}:d={fade_out},"
        "aresample={rate}"
    ).format(
        target_i=loudness["integrated_lufs"],
        target_tp=loudness["true_peak_dbtp"],
        measured_i=stats["input_i"],
        measured_tp=stats["input_tp"],
        measured_lra=stats["input_lra"],
        measured_thresh=stats["input_thresh"],
        offset=stats["target_offset"],
        fade_in=fade_in,
        fade_out_at=fade_out_at,
        fade_out=fade_out,
        rate=encoding["sample_rate_hz"],
    )
    target.parent.mkdir(parents=True, exist_ok=True)
    run(
        ffmpeg,
        [
            "-i",
            str(source),
            "-af",
            chain,
            "-vn",
            "-map_metadata",
            "-1",
            "-c:a",
            "aac",
            "-b:a",
            "{0}k".format(encoding["bitrate_kbps"]),
            "-ac",
            str(encoding["channels"]),
            "-movflags",
            "+faststart",
            str(target),
        ],
    )


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--ffmpeg")
    parser.add_argument(
        "--force", action="store_true", help="rebuild tracks already on disk"
    )
    args = parser.parse_args()

    catalogue = yaml.safe_load(CATALOGUE.read_text(encoding="utf-8"))
    loudness = catalogue["loudness"]
    encoding = catalogue["encoding"]
    ffmpeg = find_ffmpeg(args.ffmpeg)

    problems: list[str] = []
    rows: list[tuple[str, str, str, str]] = []

    for track in catalogue["tracks"]:
        target = ROOT / track["file"]
        size = lambda: "{0:.1f} MB".format(target.stat().st_size / 1e6)

        if target.exists() and not args.force:
            print("{0}: already built".format(track["id"]))
            rows.append((track["id"], "-", "-", size()))
            continue

        print("{0}:".format(track["id"]))
        source = CACHE / "{0}{1}".format(
            track["id"], Path(track["source"]["download"]).suffix
        )
        download(track["source"]["download"], source)

        stats = measure(ffmpeg, source, loudness)
        length_ms = duration_ms(ffmpeg, source)
        print(
            "  measured {0} LUFS, {1} dBTP, {2} s".format(
                stats["input_i"], stats["input_tp"], length_ms // 1000
            )
        )

        encode(ffmpeg, source, target, stats, loudness, encoding, length_ms)

        # Verify rather than trust: a limiter that had to engage, or a filter
        # typo, would otherwise ship as a track audibly off the other two.
        after = measure(ffmpeg, target, loudness)
        achieved = float(after["input_i"])
        drift = abs(achieved - float(loudness["integrated_lufs"]))
        if drift > float(loudness["tolerance_lu"]):
            problems.append(
                "{0}: normalised to {1} LUFS, {2:.1f} LU off the {3} target".format(
                    track["id"], achieved, drift, loudness["integrated_lufs"]
                )
            )
        rows.append(
            (
                track["id"],
                "{0} LUFS".format(stats["input_i"]),
                "{0} LUFS".format(after["input_i"]),
                size(),
            )
        )

    print(
        "\n{0:<18} {1:>14} {2:>14} {3:>9}".format(
            "track", "source", "normalised", "size"
        )
    )
    for row in rows:
        print("{0:<18} {1:>14} {2:>14} {3:>9}".format(*row))

    for problem in problems:
        print("ERROR: " + problem)
    return 1 if problems else 0


if __name__ == "__main__":
    sys.exit(main())
