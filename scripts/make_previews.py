#!/usr/bin/env python3
"""Build each exercise's preview.png from the frame its YAML nominates.

    python scripts/make_previews.py            # only what is out of date
    python scripts/make_previews.py --force    # rebuild everything
    python scripts/make_previews.py --dry-run  # say what would happen

docs/ASSET_PIPELINE.md: "Preview може використовувати один ключовий frame.
Текст назви накладає UI, не image." So a preview is never drawn by hand — it
is a square crop of `animation.preview.source_frame_id`, tightened onto the
subject so the thumbnail is not mostly background, and never carries text.

Regenerate after redrawing the source frame; the preview is derived, so it
should never be edited on its own.
"""
from __future__ import annotations

import argparse
import sys

from asset_tools import ROOT, content_bbox, load_library, require_pillow

# How much room to leave around the subject, as a share of the frame. Enough
# that the crop does not look shrink-wrapped onto the body.
PADDING = 0.06

DEFAULT_SIZE = 512


def crop_box(
    bbox: tuple[int, int, int, int], size: tuple[int, int]
) -> tuple[int, int, int, int]:
    """A square box around the subject, padded and clamped to the frame."""
    width, height = size
    pad_x = width * PADDING
    pad_y = height * PADDING
    left = bbox[0] - pad_x
    top = bbox[1] - pad_y
    right = bbox[2] + pad_x
    bottom = bbox[3] + pad_y

    side = min(max(right - left, bottom - top), float(min(width, height)))
    centre_x = (left + right) / 2
    centre_y = (top + bottom) / 2

    left = centre_x - side / 2
    top = centre_y - side / 2
    # Slide back inside the frame rather than shrinking the box: a smaller box
    # would cut into the subject.
    left = max(0.0, min(left, width - side))
    top = max(0.0, min(top, height - side))
    return (
        int(round(left)),
        int(round(top)),
        int(round(left + side)),
        int(round(top + side)),
    )


def build_one(exercise, size: int, force: bool, dry_run: bool) -> str:
    Image = require_pillow()

    if not exercise.preview_file:
        return "skip: {0} declares no preview".format(exercise.id)
    if not exercise.preview_source_frame_id:
        return "skip: {0} preview has no source_frame_id".format(exercise.id)

    frame = exercise.frame_by_id(exercise.preview_source_frame_id)
    if frame is None:
        return "ERROR: {0} preview points at unknown frame {1}".format(
            exercise.id, exercise.preview_source_frame_id
        )

    source = frame.path
    target = ROOT / exercise.preview_file
    if not source.exists():
        return "wait: {0} — {1} is not drawn yet".format(exercise.id, frame.name)
    if (
        target.exists()
        and not force
        and target.stat().st_mtime >= source.stat().st_mtime
    ):
        return "up to date: {0}/{1}".format(exercise.id, target.name)
    if dry_run:
        return "would build: {0}/{1} from {2}".format(
            exercise.id, target.name, frame.name
        )

    with Image.open(source) as image:
        image.load()
        bbox = content_bbox(image)
        if bbox is None:
            return "ERROR: {0}/{1} is blank".format(exercise.id, frame.name)
        box = crop_box(bbox, image.size)
        preview = image.crop(box)
        if preview.size != (size, size):
            preview = preview.resize((size, size), Image.LANCZOS)
        target.parent.mkdir(parents=True, exist_ok=True)
        preview.save(target, format="PNG", optimize=True)

    return "built: {0}/{1} ({2}x{2}) from {3} {4}".format(
        exercise.id, target.name, size, frame.id, box
    )


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--size", type=int, default=DEFAULT_SIZE)
    parser.add_argument("--force", action="store_true")
    parser.add_argument("--dry-run", action="store_true")
    parser.add_argument(
        "--only",
        metavar="EXERCISE_ID",
        help="restrict to one exercise",
    )
    args = parser.parse_args()

    failed = False
    for exercise in load_library():
        if args.only and exercise.id != args.only:
            continue
        line = build_one(exercise, args.size, args.force, args.dry_run)
        print(line)
        if line.startswith("ERROR"):
            failed = True
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
