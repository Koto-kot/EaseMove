#!/usr/bin/env python3
"""Generate paste-ready image prompts from the exercise library.

Reads data/exercises/**.yaml and data/visual/*.yaml and writes
docs/generated/IMAGE_BRIEFS.md — one brief per frame, with the
exact filename the app expects and the QA checks that frame must pass.

Regenerate after any change to a pose, camera or frame list:

    python scripts/build_image_briefs.py

Fails when a frame has no English pose text in data/visual/frame_briefs_en.yaml,
so a new frame cannot silently ship without a brief.
"""
from __future__ import annotations

import sys
from pathlib import Path
from typing import Any

import yaml

ROOT = Path(__file__).resolve().parents[1]
DATA = ROOT / "data"
OUT = ROOT / "docs" / "generated" / "IMAGE_BRIEFS.md"

LOCALE = "uk"


def load(path: Path) -> Any:
    return yaml.safe_load(path.read_text(encoding="utf-8"))


def profile(profiles: dict, profile_id: str) -> dict:
    for entry in profiles["profiles"]:
        if entry["id"] == profile_id:
            return entry
    raise ValueError("unknown profile: " + profile_id)


def humanize(token: str) -> str:
    return token.replace("_", " ")


def subject_prompt(subject: dict) -> str:
    """The locked character description, repeated verbatim in every prompt.

    Consistency across frames is a hard requirement
    (docs/VISUAL_STYLE_GUIDE.md 3), and repeating the same sentence is the
    cheapest way to hold a generator to it.
    """
    return (
        "One and the same adult person in every frame: ordinary build, "
        "not athletic and not a fitness model, neutral friendly appearance, "
        "plain solid-colour comfortable clothing with no logos or text, "
        "no medical uniform, same hairstyle, same body proportions, "
        "same clothing colour in all frames."
    )


def style_prompt(style: dict, framing: dict) -> str:
    parts = [
        "Clean, calm, instructional illustration on a plain neutral light "
        "background with soft even lighting and no clutter.",
        "Camera: " + humanize(str(framing.get("camera", "front"))) + ", identical in every frame.",
        "Framing: " + humanize(str(framing.get("crop", "full body"))) + ".",
        "The pose must read clearly at thumbnail size.",
    ]
    if framing.get("chair_visible"):
        parts.append(
            "A plain stable chair without wheels or armrests, in exactly the "
            "same position and at the same angle in every frame."
        )
    if framing.get("surface_visible"):
        parts.append(
            "A plain firm flat surface (bed or mat) visible and identical in "
            "every frame, since contact with it is part of the technique."
        )
    return " ".join(parts)


FORBIDDEN = (
    "No text, letters, numbers, captions or labels anywhere in the image. "
    "No arrows, motion lines, circles or highlights. No watermark or logo. "
    "No exaggerated range of motion — keep it comfortable and realistic."
)


def render_exercise(path: Path, briefs: dict, subject_profiles: dict, style_profiles: dict) -> str:
    raw = load(path)
    ex = raw["exercise"]
    ex_id = ex["id"]
    animation = raw["animation"]
    framing = animation.get("framing", {})
    assets = raw.get("assets", {})
    loc = raw.get("locale", {}).get(LOCALE, {})

    subject = profile(subject_profiles, animation["subject"]["subject_profile_id"])
    style = profile(style_profiles, animation["style_profile_id"])
    spec = animation.get("asset_spec", {})
    size = "{0}x{1}".format(spec.get("width_px", 1024), spec.get("height_px", 1024))

    frame_briefs = briefs["exercises"].get(ex_id)
    if not frame_briefs:
        raise ValueError("no English briefs for exercise " + ex_id)

    lines: list[str] = []
    lines.append("## {0} — {1}".format(ex_id, loc.get("title", ex_id)))
    lines.append("")
    lines.append("- Zone: `{0}`".format(ex.get("classification", {}).get("primary_zone")))
    lines.append("- Clinical status: `{0}`".format(raw.get("clinical", {}).get("status")))
    lines.append("- Source: `{0}`".format(path.relative_to(ROOT).as_posix()))
    lines.append("- Folder: `{0}`".format(assets.get("folder", "")))
    lines.append(
        "- Master: {0} PNG{1}".format(
            size,
            ", transparent background preferred"
            if spec.get("transparent_background_preferred")
            else "",
        )
    )
    equipment = ex.get("exercise_properties", {}).get("equipment_required") or []
    if equipment:
        lines.append("- Equipment that must appear: " + ", ".join(humanize(e) for e in equipment))
    lines.append("")
    lines.append("**Must stay identical across all frames of this exercise:** "
                 + ", ".join(humanize(c) for c in style.get("consistency", [])) + ".")
    lines.append("")

    for frame in animation["frames"]:
        frame_id = frame["id"]
        brief = frame_briefs.get(frame_id)
        if not brief:
            raise ValueError("{0}: no English brief for frame {1}".format(ex_id, frame_id))

        lines.append("### {0}".format(frame_id))
        lines.append("")
        lines.append("Save as `{0}`".format(frame["file"]))
        lines.append("")
        lines.append("```text")
        lines.append(subject_prompt(subject))
        lines.append("")
        lines.append(brief["pose"].strip())
        lines.append("")
        lines.append(style_prompt(style, framing))
        lines.append("")
        lines.append(FORBIDDEN)
        lines.append("```")
        lines.append("")
        lines.append("Check before accepting: "
                     + ", ".join("`" + humanize(v) + "`" for v in frame.get("validation_points", []))
                     + ".")
        lines.append("")
        uk = frame.get("pose_description_" + LOCALE)
        if uk:
            lines.append("<sub>Authored pose ({0}): {1}</sub>".format(LOCALE, uk.strip()))
            lines.append("")

    preview = animation.get("preview") or {}
    if preview.get("file"):
        lines.append("### Preview")
        lines.append("")
        lines.append(
            "Save as `{0}` — a crop of `{1}`, no overlay text.".format(
                preview["file"], preview.get("source_frame_id", "")
            )
        )
        lines.append("")

    validation = assets.get("validation") or {}
    if validation:
        lines.append("**Acceptance checklist**")
        lines.append("")
        for key, value in validation.items():
            if value:
                lines.append("- [ ] {0}".format(humanize(key)))
        lines.append("")
    return "\n".join(lines)


def main() -> int:
    subject_profiles = load(DATA / "visual/subject_profiles.yaml")
    style_profiles = load(DATA / "visual/style_profiles.yaml")
    briefs = load(DATA / "visual/frame_briefs_en.yaml")
    index = load(DATA / "exercises/index.yaml")

    sections: list[str] = []
    sections.append("# Image briefs")
    sections.append("")
    sections.append(
        "Generated by `scripts/build_image_briefs.py` from the exercise "
        "library — do not edit by hand. Poses are authored in "
        "`data/exercises/**.yaml`; the English wording lives in "
        "`data/visual/frame_briefs_en.yaml`."
    )
    sections.append("")
    sections.append(
        "Each block below is one image. Paste the prompt as-is, generate, and "
        "save the result under the filename given above it — the app already "
        "references those exact paths and needs no code change."
    )
    sections.append("")
    sections.append("**Two things that break these images most often:**")
    sections.append("")
    sections.append(
        "1. *Left and right.* Every mention of left or right means the "
        "subject's own left or right, not the viewer's side of the picture. "
        "A mirrored frame is a wrong frame."
    )
    sections.append(
        "2. *Drift between frames.* The person, clothing, chair, surface, "
        "camera angle and body scale must be identical across a whole "
        "exercise. Generate one exercise in a single session and keep the seed "
        "or reference image."
    )
    sections.append("")
    sections.append("See also `docs/IMAGE_ASSET_SPEC.md`, `docs/VISUAL_STYLE_GUIDE.md` "
                    "and `docs/EXERCISE_IMAGE_QA.md`.")
    sections.append("")

    for entry in index["exercises"]:
        path = DATA / "exercises" / entry["file"]
        sections.append(render_exercise(path, briefs, subject_profiles, style_profiles))

    OUT.parent.mkdir(parents=True, exist_ok=True)
    OUT.write_text("\n".join(sections).rstrip() + "\n", encoding="utf-8")

    frames = sum(len(v) for v in briefs["exercises"].values())
    print("OK: {0}".format(OUT.relative_to(ROOT)))
    print("- exercises: {0}".format(len(index["exercises"])))
    print("- exercise frames: {0}".format(frames))
    return 0


if __name__ == "__main__":
    sys.exit(main())
