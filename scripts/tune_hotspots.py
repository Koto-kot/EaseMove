#!/usr/bin/env python3
"""Render the hotspot overlay over the body artwork, to check it by eye.

    python scripts/tune_hotspots.py

Writes build/hotspot-debug/<view>.png: the artwork with every hotspot from
data/ui/body_map/body_hotspots.yaml drawn on it, labelled, plus the declared
content rect. docs/ui/home/HOME_SCREEN_REPOSITORY_BRIEF.md 19.8 asks for the
coordinates to be tuned visually against the final artwork, and the delivered
draft needed it — the neck dot sat on the mouth.

Also prints the measured content rect next to the declared one, so a drifting
value shows up here before check_assets.py fails on it.
"""
from __future__ import annotations

import sys
from pathlib import Path

from asset_tools import (
    BODY_MAP_SPEC,
    ROOT,
    content_bbox,
    load_yaml,
    require_pillow,
)

HOTSPOTS = ROOT / BODY_MAP_SPEC
OUT = ROOT / "build" / "hotspot-debug"

CORE = (37, 99, 235, 255)
HALO = (37, 99, 235, 70)
OUTLINE = (255, 255, 255, 255)
RECT = (220, 38, 38, 200)


def main() -> int:
    Image = require_pillow()
    from PIL import ImageDraw  # noqa: PLC0415

    spec = load_yaml(HOTSPOTS)
    OUT.mkdir(parents=True, exist_ok=True)

    for view, art in spec["artwork"].items():
        path = ROOT / art["path"]
        if not path.exists():
            print("MISS  " + art["path"])
            continue

        with Image.open(path) as source:
            image = source.convert("RGBA")
            measured = content_bbox(source)
        width, height = image.size
        overlay = Image.new("RGBA", image.size, (0, 0, 0, 0))
        draw = ImageDraw.Draw(overlay)

        declared = art["content_rect"]
        box = (
            declared["left"] * width,
            declared["top"] * height,
            declared["right"] * width,
            declared["bottom"] * height,
        )
        draw.rectangle(box, outline=RECT, width=3)

        for spot in spec["hotspots"]:
            if spot["view"] != view:
                continue
            cx = spot["cx"] * width
            cy = spot["cy"] * height
            rx = spot["w"] * width / 2
            ry = spot["h"] * height / 2
            # The oval is the declared zone extent; the dot is what the user
            # actually sees, so both are drawn.
            draw.ellipse((cx - rx, cy - ry, cx + rx, cy + ry), fill=HALO)
            draw.ellipse((cx - 14, cy - 14, cx + 14, cy + 14), fill=CORE)
            draw.ellipse((cx - 5, cy - 5, cx + 5, cy + 5), fill=OUTLINE)
            draw.text((cx + 20, cy - 6), spot["id"], fill=CORE)

        target = OUT / (view + ".png")
        Image.alpha_composite(image, overlay).convert("RGB").save(target)

        print("OK    " + target.relative_to(ROOT).as_posix())
        print(
            "      declared content rect {0:.4f},{1:.4f} .. {2:.4f},{3:.4f}".format(
                declared["left"], declared["top"], declared["right"], declared["bottom"]
            )
        )
        if measured:
            print(
                "      measured             {0:.4f},{1:.4f} .. {2:.4f},{3:.4f}".format(
                    measured[0] / width,
                    measured[1] / height,
                    measured[2] / width,
                    measured[3] / height,
                )
            )
    return 0


if __name__ == "__main__":
    sys.exit(main())
