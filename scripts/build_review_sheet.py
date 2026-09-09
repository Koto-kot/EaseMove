#!/usr/bin/env python3
"""Build tools/review.html — every frame of an exercise side by side.

    python scripts/build_review_sheet.py
    python scripts/build_review_sheet.py --open

Then open tools/review.html in a browser. Nothing is served and nothing is
fetched: the page references the PNGs by relative path, so it works from
file:// with no dev server.

This is the half of docs/EXERCISE_IMAGE_QA.md a script cannot judge. The
frames of one exercise sit in a row, in sequence order, with the authored pose
text under each one, so drift — a different person, a chair that moved, a
mirrored side — shows up as soon as you look along the row.

The page is generated, so it is not committed; rerun after new artwork lands.
"""
from __future__ import annotations

import argparse
import sys
import webbrowser
from html import escape
from pathlib import Path

from asset_tools import (
    BODY_MAP_DIR,
    BODY_MAP_VIEWS,
    ExerciseAssets,
    ROOT,
    load_library,
)

OUT = ROOT / "tools" / "review.html"

# docs/EXERCISE_IMAGE_QA.md, the checks a human has to make.
CHECKLIST: list[tuple[str, list[str]]] = [
    (
        "A. Identity",
        [
            "same person in every frame",
            "same clothing, same hair",
            "same body proportions",
            "same camera angle and crop",
            "same background",
        ],
    ),
    (
        "B. Movement",
        [
            "frame order matches the sequence",
            "the working side is the right one - a mirrored frame is a wrong frame",
            "parts that should not move have not moved",
            "range is comfortable, not exaggerated",
            "joints bend the way the pose text says",
        ],
    ),
    (
        "C. Equipment",
        [
            "same chair / bed / mat throughout",
            "the chair has not shifted or rotated",
            "the floor does not deform",
        ],
    ),
    (
        "D. Cleanliness",
        ["no baked-in text", "no arrows or counters", "no logo, no watermark"],
    ),
    (
        "E. Accessibility",
        [
            "the working limb is visible",
            "the silhouette reads at thumbnail size",
            "no cue depends on colour alone",
        ],
    ),
]

CSS = """
:root { color-scheme: light dark; --line: #d8d8d8; --muted: #6b6b6b; --miss: #b3261e; }
@media (prefers-color-scheme: dark) {
  :root { --line: #3a3a3a; --muted: #a0a0a0; --miss: #f2b8b5; }
}
body { margin: 0; padding: 24px; font: 14px/1.5 system-ui, sans-serif; }
h1 { font-size: 20px; margin: 0 0 4px; }
h2 { font-size: 17px; margin: 36px 0 2px; }
.sub, .meta { color: var(--muted); }
.meta { font-size: 12px; margin-bottom: 12px; }
.row { display: flex; gap: 14px; overflow-x: auto; padding-bottom: 8px; }
.frame { flex: 0 0 220px; }
.frame img, .miss {
  width: 220px; height: 220px; border: 1px solid var(--line); border-radius: 10px;
  object-fit: contain; background: #fafafa; display: block;
}
@media (prefers-color-scheme: dark) { .frame img, .miss { background: #202020; } }
.miss {
  display: grid; place-items: center; text-align: center; padding: 12px;
  color: var(--miss); font-size: 12px; box-sizing: border-box;
}
.fid { font-weight: 600; margin-top: 8px; }
.file { font-family: ui-monospace, monospace; font-size: 11px; color: var(--muted); }
.pose { font-size: 12px; margin-top: 6px; }
.vp { font-size: 11px; color: var(--muted); margin-top: 6px; }
.preview { border-left: 3px solid var(--line); padding-left: 14px; }
.qa { display: flex; flex-wrap: wrap; gap: 20px; margin: 14px 0 0; font-size: 12px; }
.qa ul { list-style: none; margin: 4px 0 0; padding: 0; }
.qa li { margin: 2px 0; }
.qa b { font-size: 11px; text-transform: uppercase; letter-spacing: .04em; color: var(--muted); }
hr { border: 0; border-top: 1px solid var(--line); margin: 28px 0 0; }
"""


def rel(asset_path: str) -> str:
    """Path from tools/ to an asset in the repo."""
    return "../" + asset_path


def frame_cell(label: str, file_path: str, body: str, extra: str = "") -> list[str]:
    exists = (ROOT / file_path).exists()
    out = ['<div class="frame {0}">'.format(extra)]
    if exists:
        out.append(
            '<a href="{0}" target="_blank"><img src="{0}" alt="{1}"></a>'.format(
                escape(rel(file_path)), escape(label)
            )
        )
    else:
        out.append('<div class="miss">not drawn yet</div>')
    out.append('<div class="fid">{0}</div>'.format(escape(label)))
    out.append('<div class="file">{0}</div>'.format(escape(Path(file_path).name)))
    out.append(body)
    out.append("</div>")
    return out


def render_exercise(exercise: ExerciseAssets) -> str:
    out: list[str] = []
    out.append("<h2>{0} - {1}</h2>".format(escape(exercise.id), escape(exercise.title)))
    out.append(
        '<div class="meta">zone <code>{0}</code> | clinical <code>{1}</code> | '
        "{2} | brief: docs/generated/IMAGE_BRIEFS.md</div>".format(
            escape(exercise.zone),
            escape(exercise.clinical_status),
            escape(exercise.source),
        )
    )

    out.append('<div class="row">')
    for frame in exercise.frames:
        body = ""
        if frame.pose:
            body += '<div class="pose">{0}</div>'.format(escape(frame.pose))
        if frame.validation_points:
            body += '<div class="vp">check: {0}</div>'.format(
                escape(", ".join(p.replace("_", " ") for p in frame.validation_points))
            )
        out.extend(frame_cell(frame.id, frame.file, body))

    if exercise.preview_file:
        source = exercise.preview_source_frame_id or "?"
        out.extend(
            frame_cell(
                "preview",
                exercise.preview_file,
                '<div class="vp">generated from {0} by '
                "scripts/make_previews.py</div>".format(escape(source)),
                extra="preview",
            )
        )
    out.append("</div>")

    out.append('<div class="qa">')
    for title, items in CHECKLIST:
        out.append("<div><b>{0}</b><ul>".format(escape(title)))
        for item in items:
            out.append(
                '<li><label><input type="checkbox"> {0}</label></li>'.format(
                    escape(item)
                )
            )
        out.append("</ul></div>")
    out.append("</div><hr>")
    return "\n".join(out)


def render_body_map() -> str:
    out: list[str] = ["<h2>Body map</h2>"]
    out.append(
        '<div class="meta">One figure, two views, same scale and stance: the app '
        "scales one shared set of normalized hotspots over both "
        "(docs/BODY_MAP_SPEC.md).</div>"
    )
    out.append('<div class="row">')
    for view in BODY_MAP_VIEWS:
        out.extend(
            frame_cell(
                view,
                "{0}/{1}.png".format(BODY_MAP_DIR, view),
                '<div class="vp">check: same height and scale in both views, '
                "no dots or labels baked in</div>",
            )
        )
    out.append("</div><hr>")
    return "\n".join(out)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--open", action="store_true", help="open the page in a browser when done"
    )
    args = parser.parse_args()

    library = load_library()
    drawn = 0
    total = 0
    for exercise in library:
        for asset in [f.file for f in exercise.frames] + (
            [exercise.preview_file] if exercise.preview_file else []
        ):
            total += 1
            if (ROOT / asset).exists():
                drawn += 1
    for view in BODY_MAP_VIEWS:
        total += 1
        if (ROOT / BODY_MAP_DIR / (view + ".png")).exists():
            drawn += 1

    parts: list[str] = [
        "<!doctype html>",
        '<html lang="uk"><head><meta charset="utf-8">',
        '<meta name="viewport" content="width=device-width, initial-scale=1">',
        "<title>EaseMove - image review</title>",
        "<style>" + CSS + "</style></head><body>",
        "<h1>Image review</h1>",
        '<div class="sub">{0} of {1} assets drawn. Generated by '
        "scripts/build_review_sheet.py - do not edit; rerun it instead."
        "</div><hr>".format(drawn, total),
        render_body_map(),
    ]
    parts.extend(render_exercise(exercise) for exercise in library)
    parts.append("</body></html>")

    OUT.parent.mkdir(parents=True, exist_ok=True)
    OUT.write_text("\n".join(parts) + "\n", encoding="utf-8")
    print("OK: {0}  ({1}/{2} assets drawn)".format(OUT.relative_to(ROOT), drawn, total))
    if args.open:
        webbrowser.open(OUT.as_uri())
    return 0


if __name__ == "__main__":
    sys.exit(main())
