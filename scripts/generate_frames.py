#!/usr/bin/env python3
"""Generate exercise frames with the OpenAI image API (gpt-image-1).

    python scripts/generate_frames.py --only KNEE_001              # plan only
    python scripts/generate_frames.py --only KNEE_001 --yes        # actually call
    python scripts/generate_frames.py --body-map --yes
    python scripts/generate_frames.py --only KNEE_001 --frame FRAME_LEFT_MID --yes --force

Nothing is sent to the API without `--yes`: the default run prints the exact
prompt for every image it would make, so a wrong pose costs nothing.

## Why it works frame by frame

The hard requirement is not a good picture, it is the *same* picture five
times over with one limb moved (docs/VISUAL_STYLE_GUIDE.md 3). Text prompts
drift, so this script generates one master frame per exercise and produces
every other frame as an **edit of that master**, with the master passed back
as the reference image. The pose text then only has to describe the change.

The prompts come from the same functions that write docs/generated/
IMAGE_BRIEFS.md, so what the API is asked for is word for word what a human
illustrator would be handed.

## Setup

    pip install -r tools/requirements-generate.txt

Put the key in `.env` at the repo root (already gitignored):

    OPENAI_API_KEY=sk-...

The script reads it from the environment; it is never printed or committed.
"""
from __future__ import annotations

import argparse
import base64
import os
import sys
import time
from pathlib import Path
from typing import Any

from asset_tools import (
    BODY_MAP_DIR,
    DATA,
    ROOT,
    load_yaml,
)
from build_image_briefs import FORBIDDEN, profile, style_prompt, subject_prompt

CANDIDATES = ROOT / "build" / "frame-candidates"

MODEL = "gpt-image-1"

# Prepended to every edit. The reference image carries the identity; this
# sentence stops the model from treating the pose text as a new scene.
SAME_SCENE = (
    "This is the same exercise, the same person and the same scene as the "
    "reference image. Keep the face, hair, body proportions, clothing and "
    "clothing colour identical. Keep the chair or surface, the background, "
    "the lighting, the camera angle and the framing identical. Change only "
    "the body position, exactly as described next."
)

# The single most common defect in generated exercise art.
LATERALITY = (
    "Left and right always mean the subject's own left and right, not the "
    "viewer's side of the picture."
)

TRANSPARENT = "The background must be fully transparent."


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
    if not os.environ.get("OPENAI_API_KEY"):
        raise SystemExit(
            "ERROR: OPENAI_API_KEY is not set. Put it in .env at the repo root "
            "(that file is gitignored) or export it in your shell."
        )
    return OpenAI()


# ------------------------------------------------------------------- prompts


def exercise_context(path: Path) -> dict[str, Any]:
    raw = load_yaml(path)
    animation = raw["animation"]
    subject_profiles = load_yaml(DATA / "visual/subject_profiles.yaml")
    style_profiles = load_yaml(DATA / "visual/style_profiles.yaml")
    briefs = load_yaml(DATA / "visual/frame_briefs_en.yaml")
    ex_id = raw["exercise"]["id"]
    return {
        "id": ex_id,
        "animation": animation,
        "framing": animation.get("framing", {}),
        "spec": animation.get("asset_spec", {}),
        "subject": profile(subject_profiles, animation["subject"]["subject_profile_id"]),
        "style": profile(style_profiles, animation["style_profile_id"]),
        "briefs": briefs["exercises"].get(ex_id) or {},
    }


def pose_text(ctx: dict[str, Any], frame_id: str) -> str:
    brief = ctx["briefs"].get(frame_id)
    if not brief:
        raise SystemExit(
            "ERROR: {0}/{1} has no English brief in "
            "data/visual/frame_briefs_en.yaml".format(ctx["id"], frame_id)
        )
    return brief["pose"].strip()


def master_prompt(ctx: dict[str, Any], frame_id: str, transparent: bool) -> str:
    parts = [
        subject_prompt(ctx["subject"]),
        pose_text(ctx, frame_id),
        style_prompt(ctx["style"], ctx["framing"]),
        LATERALITY,
        FORBIDDEN,
    ]
    if transparent:
        parts.append(TRANSPARENT)
    return "\n\n".join(parts)


def edit_prompt(ctx: dict[str, Any], frame_id: str, transparent: bool) -> str:
    parts = [SAME_SCENE, pose_text(ctx, frame_id), LATERALITY, FORBIDDEN]
    if transparent:
        parts.append(TRANSPARENT)
    return "\n\n".join(parts)


def body_map_prompt(view: str, transparent: bool) -> str:
    style_profiles = load_yaml(DATA / "visual/style_profiles.yaml")
    style = profile(style_profiles, "body_map_v1")
    if view == "front":
        pose = (
            "A simplified, non-photorealistic full-body human figure, {0}, "
            "standing straight and facing the viewer, arms relaxed and "
            "slightly away from the body, feet together.".format(
                style["style"].replace("_", " ")
            )
        )
    else:
        pose = (
            "The same figure seen from directly behind: same scale, same "
            "stance, same clothing, standing straight, arms relaxed and "
            "slightly away from the body, feet together."
        )
    parts = [
        pose,
        "Neutral adult of ordinary build - not athletic, not an anatomical or "
        "muscle chart, not a medical diagram. Soft, even, friendly rendering "
        "suitable for older users. The figure is centred and fills the frame "
        "vertically with a small even margin.",
        "No text, no labels, no arrows, no highlighted or coloured zones, no "
        "dots or markers on the body: the app draws its own interactive layer "
        "on top.",
    ]
    if transparent:
        parts.append(TRANSPARENT)
    return "\n\n".join(parts)


# --------------------------------------------------------------------- calls


def call_api(
    api,
    prompt: str,
    size: str,
    quality: str,
    transparent: bool,
    reference: Path | None,
) -> bytes:
    """One image, as PNG bytes. Retries the transient failures only."""
    kwargs: dict[str, Any] = {
        "model": MODEL,
        "prompt": prompt,
        "size": size,
        "quality": quality,
        "output_format": "png",
        "n": 1,
    }
    if transparent:
        kwargs["background"] = "transparent"

    delays = (5, 15, 45)
    for attempt in range(len(delays) + 1):
        try:
            if reference is None:
                result = api.images.generate(**kwargs)
            else:
                with reference.open("rb") as handle:
                    # input_fidelity keeps the reference's face and clothing;
                    # older API versions do not know the argument, so it is
                    # dropped on the retry below rather than hard-required.
                    result = api.images.edit(
                        image=handle, input_fidelity="high", **kwargs
                    )
            return base64.b64decode(result.data[0].b64_json)
        except TypeError:
            if reference is not None:
                with reference.open("rb") as handle:
                    result = api.images.edit(image=handle, **kwargs)
                return base64.b64decode(result.data[0].b64_json)
            raise
        except Exception as exc:  # noqa: BLE001 - the SDK's error tree varies
            name = type(exc).__name__
            transient = name in {
                "RateLimitError",
                "APIConnectionError",
                "APITimeoutError",
                "InternalServerError",
                "APIStatusError",
            }
            if not transient or attempt == len(delays):
                raise
            wait = delays[attempt]
            print("    {0}: {1} - retrying in {2}s".format(name, exc, wait))
            time.sleep(wait)
    raise RuntimeError("unreachable")


def write_image(data: bytes, target: Path) -> None:
    target.parent.mkdir(parents=True, exist_ok=True)
    target.write_bytes(data)


# ----------------------------------------------------------------- the plan


def plan_exercise(
    ctx: dict[str, Any], frame_filter: str | None, force: bool
) -> list[dict[str, Any]]:
    """What to make, in order. The master must exist before any edit, so it is
    always first and always the reference for the rest."""
    frames = ctx["animation"]["frames"]
    if not frames:
        return []
    master = frames[0]
    master_path = ROOT / master["file"]
    jobs: list[dict[str, Any]] = []

    wants_master = frame_filter in (None, master["id"])
    if wants_master and (force or not master_path.exists()):
        jobs.append(
            {
                "kind": "master",
                "frame_id": master["id"],
                "target": master_path,
                "reference": None,
            }
        )

    for frame in frames[1:]:
        if frame_filter not in (None, frame["id"]):
            continue
        target = ROOT / frame["file"]
        if target.exists() and not force:
            continue
        jobs.append(
            {
                "kind": "edit",
                "frame_id": frame["id"],
                "target": target,
                "reference": master_path,
            }
        )
    return jobs


def run(args: argparse.Namespace) -> int:
    load_env()
    index = load_yaml(DATA / "exercises/index.yaml")

    size_for: dict[Path, str] = {}
    prompt_for: dict[Path, str] = {}
    all_jobs: list[dict[str, Any]] = []

    if not args.body_map:
        for entry in index["exercises"]:
            path = DATA / "exercises" / entry["file"]
            ctx = exercise_context(path)
            if args.only and ctx["id"] != args.only:
                continue
            spec = ctx["spec"]
            transparent = (
                args.transparent
                if args.transparent is not None
                else bool(spec.get("transparent_background_preferred"))
            )
            size = "{0}x{1}".format(
                spec.get("width_px", 1024), spec.get("height_px", 1024)
            )
            for job in plan_exercise(ctx, args.frame, args.force):
                job["exercise"] = ctx["id"]
                job["transparent"] = transparent
                size_for[job["target"]] = size
                prompt_for[job["target"]] = (
                    master_prompt(ctx, job["frame_id"], transparent)
                    if job["kind"] == "master"
                    else edit_prompt(ctx, job["frame_id"], transparent)
                )
                all_jobs.append(job)

    if args.body_map:
        # The app composites the figure over its own background, so a light
        # backdrop would render as a pale slab in the dark theme: transparent
        # by default here, unlike the illustrator-facing brief.
        transparent = True if args.transparent is None else args.transparent
        front = ROOT / BODY_MAP_DIR / "front.png"
        for view in ("front", "back"):
            target = ROOT / BODY_MAP_DIR / (view + ".png")
            if target.exists() and not args.force:
                continue
            job = {
                "kind": "master" if view == "front" else "edit",
                "exercise": "body-map",
                "frame_id": view,
                "target": target,
                # The back view is an edit of the front so both figures share
                # a height and scale - one set of hotspots is scaled over both.
                "reference": None if view == "front" else front,
                "transparent": transparent,
            }
            size_for[target] = args.body_map_size
            prompt_for[target] = body_map_prompt(view, transparent)
            all_jobs.append(job)

    if not all_jobs:
        print("Nothing to do: every requested image already exists (--force to redo).")
        return 0

    print(
        "{0} image(s) to make, model {1}, quality {2}\n".format(
            len(all_jobs), MODEL, args.quality
        )
    )
    for job in all_jobs:
        target = job["target"]
        print(
            "{0}  {1} -> {2}  [{3}, {4}]".format(
                job["kind"].upper().ljust(6),
                job["exercise"] + "/" + job["frame_id"],
                target.relative_to(ROOT).as_posix(),
                size_for[target],
                "transparent" if job["transparent"] else "opaque",
            )
        )
        if job["reference"] is not None:
            print("        reference: " + job["reference"].relative_to(ROOT).as_posix())
        if args.show_prompts or not args.yes:
            for line in prompt_for[target].splitlines():
                print("        | " + line)
        print()

    if not args.yes:
        print("Plan only - nothing was sent. Add --yes to generate.")
        return 0
    if len(all_jobs) > args.budget:
        print(
            "Refusing to make {0} images in one run (--budget is {1}). Narrow it "
            "with --only / --frame, or raise --budget on purpose.".format(
                len(all_jobs), args.budget
            )
        )
        return 1

    api = client()
    made = 0
    for job in all_jobs:
        target = job["target"]
        reference = job["reference"]
        if reference is not None and not reference.exists():
            print(
                "SKIP  {0}: its reference {1} does not exist yet - make the "
                "master frame first".format(
                    job["frame_id"], reference.relative_to(ROOT).as_posix()
                )
            )
            continue

        print("... " + target.relative_to(ROOT).as_posix())
        for variant in range(1, args.variants + 1):
            data = call_api(
                api,
                prompt_for[target],
                size_for[target],
                args.quality,
                job["transparent"],
                reference,
            )
            if args.variants == 1:
                write_image(data, target)
                print("    saved " + target.relative_to(ROOT).as_posix())
            else:
                # Alternates never land on the real path: pick one by hand and
                # copy it over, so a chosen frame is never silently replaced.
                candidate = (
                    CANDIDATES
                    / job["exercise"]
                    / "{0}.v{1}.png".format(job["frame_id"], variant)
                )
                write_image(data, candidate)
                print("    saved " + candidate.relative_to(ROOT).as_posix())
            made += 1

    print("\n{0} image(s) written.".format(made))
    print("Next: python scripts/make_previews.py")
    print("      python scripts/check_assets.py")
    print("      python scripts/build_review_sheet.py --open")
    return 0


def main() -> int:
    parser = argparse.ArgumentParser(
        description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter
    )
    parser.add_argument("--only", metavar="EXERCISE_ID")
    parser.add_argument(
        "--frame",
        metavar="FRAME_ID",
        help="one frame; an edit still uses the exercise's master as reference",
    )
    parser.add_argument("--body-map", action="store_true", help="the two figures")
    parser.add_argument("--body-map-size", default="1024x1536")
    parser.add_argument(
        "--quality", default="high", choices=("low", "medium", "high", "auto")
    )
    parser.add_argument(
        "--variants",
        type=int,
        default=1,
        help="more than one writes to build/frame-candidates/ instead of the "
        "asset path, to pick from by hand",
    )
    parser.add_argument(
        "--transparent",
        dest="transparent",
        action="store_true",
        default=None,
        help="force a transparent background (default: what asset_spec asks for)",
    )
    parser.add_argument(
        "--opaque", dest="transparent", action="store_false", help="force a background"
    )
    parser.add_argument(
        "--force", action="store_true", help="redo images that already exist"
    )
    parser.add_argument(
        "--budget",
        type=int,
        default=8,
        help="refuse to make more than this many images in one run",
    )
    parser.add_argument("--show-prompts", action="store_true")
    parser.add_argument(
        "--yes", action="store_true", help="actually call the API and write files"
    )
    return run(parser.parse_args())


if __name__ == "__main__":
    sys.exit(main())
