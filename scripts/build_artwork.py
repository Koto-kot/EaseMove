#!/usr/bin/env python3
"""Turn the delivered PNG masters into the JPEGs the app bundles.

    python scripts/build_artwork.py            # convert whatever is still PNG
    python scripts/build_artwork.py --dry-run  # say what would happen
    python scripts/build_artwork.py --quality 92

The artist delivers PNG (`asset_spec.master_format`); the app ships JPEG
(`asset_spec.app_delivery_format`), the same two-format arrangement the voice
pack already has between its wav masters and its bundled m4a.

PNG is the wrong container for a photograph of a person: the 77 exercise
frames weighed 54 MB and weigh about 5 MB afterwards, with no visible
difference at the size a phone shows them (docs/DECISIONS.md 90). None of the
artwork carries an alpha channel, so nothing is lost by leaving it behind.

The PNG is removed after a successful conversion: the masters live in the
delivery packs and in git history, not in the shipped bundle. Run this after
unpacking a new pack, before `check_assets.py`.
"""
from __future__ import annotations

import argparse
import sys
from pathlib import Path

from asset_tools import ROOT, require_pillow

# Where bundled artwork lives. Everything under these is converted.
SOURCES = ("assets/exercises", "assets/ui")

# 92 with 4:2:0 chroma: ten times smaller than PNG and indistinguishable on a
# photograph. Above this the file grows fast for nothing; below it the flat
# studio background starts to show blocking.
DEFAULT_QUALITY = 92


def convert(image_module, source: Path, quality: int, dry_run: bool) -> int:
    """Writes the JPEG beside the PNG and removes it. Answers bytes saved."""
    target = source.with_suffix(".jpg")
    before = source.stat().st_size
    if dry_run:
        print("  would convert {0}".format(source.relative_to(ROOT).as_posix()))
        return 0

    with image_module.open(source) as image:
        if "A" in image.getbands():
            # Kept as a hard stop rather than a warning: flattening a cut-out
            # figure onto white would look fine here and wrong in the app.
            raise SystemExit(
                "ERROR: {0} has an alpha channel; JPEG would flatten it. "
                "Convert it by hand or keep it as PNG.".format(source.name)
            )
        image.convert("RGB").save(
            target,
            format="JPEG",
            quality=quality,
            subsampling=2,
            optimize=True,
            progressive=True,
        )
    after = target.stat().st_size
    source.unlink()
    print(
        "  {0:<52} {1:6.0f} KB -> {2:5.0f} KB".format(
            target.relative_to(ROOT).as_posix(), before / 1024, after / 1024
        )
    )
    return before - after


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--quality", type=int, default=DEFAULT_QUALITY)
    parser.add_argument("--dry-run", action="store_true")
    args = parser.parse_args()

    image_module = require_pillow()
    saved = 0
    converted = 0
    for source_dir in SOURCES:
        for png in sorted((ROOT / source_dir).rglob("*.png")):
            saved += convert(image_module, png, args.quality, args.dry_run)
            converted += 1

    if converted == 0:
        print("Nothing to convert: every bundled image is already JPEG.")
        return 0
    print()
    print(
        "{0} images, {1:.1f} MB saved.".format(converted, saved / 1024 / 1024)
    )
    if not args.dry_run:
        print("Re-run scripts/build_content.py: the frame paths changed.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
