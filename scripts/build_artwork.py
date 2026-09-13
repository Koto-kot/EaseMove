#!/usr/bin/env python3
"""Encode the PNG masters into the JPEGs the app bundles.

    python scripts/build_artwork.py            # whatever is missing or stale
    python scripts/build_artwork.py --force    # re-encode everything
    python scripts/build_artwork.py --dry-run  # say what would happen
    python scripts/build_artwork.py --quality 92

`masters/` holds what the artist delivered, `assets/` holds what ships. The
two trees mirror each other:

    masters/exercises/NECK_001/images/setup_full_safe.png   <- delivered
    assets/exercises/NECK_001/images/setup_full_safe.jpg    <- bundled

The masters are kept out of `assets/` on purpose: `pubspec.yaml` declares whole
folders, so a PNG sitting next to its JPEG would be bundled too and the app
would carry both (docs/DECISIONS.md 90).

PNG is the wrong container for a photograph of a person — 77 exercise frames
weighed 54 MB and weigh 5.5 MB afterwards, with no visible difference at the
size a phone draws them. Run this after unpacking a delivery, before
`check_assets.py`.
"""
from __future__ import annotations

import argparse
import sys
from pathlib import Path

from asset_tools import ROOT, require_pillow

MASTERS = ROOT / "masters"
BUNDLE = ROOT / "assets"

# 92 with 4:2:0 chroma: ten times smaller than PNG and indistinguishable on a
# photograph. Above this the file grows fast for nothing; below it the flat
# studio background starts to show blocking.
DEFAULT_QUALITY = 92


def bundled_path(master: Path) -> Path:
    """The JPEG that belongs to this master."""
    return BUNDLE / master.relative_to(MASTERS).with_suffix(".jpg")


def convert(image_module, master: Path, target: Path, quality: int) -> int:
    """Writes the JPEG. Answers how many bytes the bundle saves on it."""
    with image_module.open(master) as image:
        if "A" in image.getbands():
            # A hard stop rather than a warning: flattening a cut-out figure
            # onto white would look fine here and wrong in the app.
            raise SystemExit(
                "ERROR: {0} has an alpha channel; JPEG would flatten it. "
                "Decide what its background should be first.".format(master.name)
            )
        target.parent.mkdir(parents=True, exist_ok=True)
        image.convert("RGB").save(
            target,
            format="JPEG",
            quality=quality,
            subsampling=2,
            optimize=True,
            progressive=True,
        )
    return master.stat().st_size - target.stat().st_size


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--quality", type=int, default=DEFAULT_QUALITY)
    parser.add_argument("--force", action="store_true")
    parser.add_argument("--dry-run", action="store_true")
    args = parser.parse_args()

    if not MASTERS.is_dir():
        raise SystemExit("ERROR: masters/ is missing; nothing to encode.")

    image_module = require_pillow()
    saved = 0
    built = 0
    fresh = 0
    for master in sorted(MASTERS.rglob("*.png")):
        target = bundled_path(master)
        up_to_date = (
            target.exists()
            and target.stat().st_mtime >= master.stat().st_mtime
            and not args.force
        )
        if up_to_date:
            fresh += 1
            continue
        if args.dry_run:
            print("  would encode " + target.relative_to(ROOT).as_posix())
            built += 1
            continue
        before = master.stat().st_size
        saved += convert(image_module, master, target, args.quality)
        print(
            "  {0:<52} {1:6.0f} KB -> {2:5.0f} KB".format(
                target.relative_to(ROOT).as_posix(),
                before / 1024,
                target.stat().st_size / 1024,
            )
        )
        built += 1

    # A JPEG whose master is gone would keep shipping unnoticed.
    for stale in sorted(BUNDLE.rglob("*.jpg")):
        master = MASTERS / stale.relative_to(BUNDLE).with_suffix(".png")
        if not master.exists():
            print(
                "  WARNING: {0} has no master in masters/".format(
                    stale.relative_to(ROOT).as_posix()
                )
            )

    print()
    if built == 0:
        print("Every bundled image is current ({0} masters).".format(fresh))
        return 0
    print(
        "{0} encoded, {1} already current, {2:.1f} MB smaller than the "
        "masters.".format(built, fresh, saved / 1024 / 1024)
    )
    if not args.dry_run:
        print("Run scripts/check_assets.py next.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
