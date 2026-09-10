#!/usr/bin/env python3
"""Verify the image assets against what the exercise library declares.

    python scripts/check_assets.py                # report
    python scripts/check_assets.py --require-complete   # also fail on missing

Runs the machine-checkable half of docs/EXERCISE_IMAGE_QA.md section F, plus
the technical rules in docs/IMAGE_ASSET_SPEC.md. The half a script cannot
judge — same person, same chair, correct side, no baked-in text — is what
tools/review.html is for.

Exit code 1 means an asset that exists is wrong: wrong size, undecodable, or
declared in one place and not the other. A file that has simply not been drawn
yet is reported and does not fail, so this can run in CI from day one; pass
--require-complete once the artwork is expected to be complete.
"""
from __future__ import annotations

import argparse
import sys
from pathlib import Path

from asset_tools import (
    BODY_MAP_MIN_HEIGHT,
    BODY_MAP_SPEC,
    CONTENT_RECT_TOLERANCE,
    HOME_SCREEN_SPEC,
    ExerciseAssets,
    PILLOW_HINT,
    ROOT,
    SAFE_AREA,
    content_bbox,
    has_pillow,
    is_bundled,
    load_library,
    load_yaml,
    pubspec_asset_dirs,
    safe_area_overflow,
)

errors: list[str] = []
warnings: list[str] = []
missing: list[str] = []


def error(message: str) -> None:
    errors.append(message)
    print("  ERR   " + message)


def warn(message: str) -> None:
    warnings.append(message)
    print("  WARN  " + message)


def absent(message: str) -> None:
    missing.append(message)
    print("  MISS  " + message)


def ok(message: str) -> None:
    print("  ok    " + message)


def check_image(
    path: Path,
    label: str,
    *,
    expect_size: tuple[int, int] | None,
    expect_format: str,
    transparent_preferred: bool,
    inspect: bool,
) -> None:
    """One file that exists on disk."""
    if not inspect:
        ok(label + " (present, not inspected)")
        return

    from PIL import Image, UnidentifiedImageError  # noqa: PLC0415

    try:
        with Image.open(path) as image:
            image.load()
            fmt = (image.format or "").lower()
            size = image.size
            bbox = content_bbox(image)
            bands = image.getbands()
    except (UnidentifiedImageError, OSError) as exc:
        error("{0}: cannot be decoded ({1})".format(label, exc))
        return

    problems: list[str] = []
    if fmt != expect_format:
        problems.append("format is {0}, expected {1}".format(fmt, expect_format))
    if expect_size and size != expect_size:
        problems.append(
            "size is {0}x{1}, expected {2}x{3}".format(
                size[0], size[1], expect_size[0], expect_size[1]
            )
        )
    if problems:
        error(label + ": " + "; ".join(problems))
        return

    if bbox is None:
        error(label + ": the image is blank - nothing but background")
        return

    overflow = safe_area_overflow(bbox, size)
    if overflow:
        warn(
            "{0}: content reaches past the central {1:.0%} by {2}. Fine for a "
            "floor or a wall, a defect if it is a limb.".format(
                label,
                SAFE_AREA,
                ", ".join(
                    "{0} {1}px".format(edge, value) for edge, value in overflow.items()
                ),
            )
        )
    if transparent_preferred and "A" not in bands:
        warn(label + ": no alpha channel, though the spec prefers a transparent background")
    if not overflow and (not transparent_preferred or "A" in bands):
        ok(label)


def check_exercise(exercise: ExerciseAssets, declared: list[str], inspect: bool) -> None:
    print("\n{0} - {1}  [{2}]".format(exercise.id, exercise.title, exercise.source))

    if not exercise.folder:
        error(exercise.id + ": assets.folder is not set")
        return
    if not is_bundled(exercise.folder + "/x.png", declared):
        error(
            "{0}: {1}/ is not listed under `flutter: assets:` in pubspec.yaml - "
            "its images would never load".format(exercise.id, exercise.folder)
        )

    referenced: list[str] = [frame.file for frame in exercise.frames]
    if exercise.preview_file:
        referenced.append(exercise.preview_file)

    # QA F: the animation block and assets.required must agree. Drift here is
    # how a frame ends up drawn but unused, or referenced but never ordered.
    declared_names = set(exercise.required) | set(exercise.optional)
    for asset in referenced:
        name = Path(asset).name
        if name not in declared_names:
            error(
                "{0}: {1} is used by the animation but not listed in "
                "assets.required".format(exercise.id, name)
            )
    for name in exercise.required:
        if name not in {Path(asset).name for asset in referenced}:
            error(
                "{0}: assets.required lists {1}, which the animation never "
                "uses".format(exercise.id, name)
            )

    if exercise.preview_source_frame_id and not exercise.frame_by_id(
        exercise.preview_source_frame_id
    ):
        error(
            "{0}: preview.source_frame_id is {1}, which is not one of its "
            "frames".format(exercise.id, exercise.preview_source_frame_id)
        )

    for asset in referenced:
        path = ROOT / asset
        label = "{0}/{1}".format(exercise.id, Path(asset).name)
        if not path.exists():
            absent(label + " - not drawn yet")
            continue
        # A preview is a crop of a frame, so only frames carry the master size.
        is_frame = asset != exercise.preview_file
        check_image(
            path,
            label,
            expect_size=(exercise.width_px, exercise.height_px) if is_frame else None,
            expect_format=exercise.master_format,
            transparent_preferred=exercise.transparent_preferred,
            inspect=inspect,
        )

    if exercise.folder_path.is_dir():
        known = {Path(asset).name for asset in referenced} | set(exercise.optional)
        for stray in sorted(exercise.folder_path.iterdir()):
            if (
                stray.is_file()
                and stray.name not in known
                and stray.suffix != ".md"
                and not stray.name.startswith(".")
            ):
                warn(
                    "{0}: {1} sits in the folder but nothing references it".format(
                        exercise.id, stray.name
                    )
                )


def check_body_map(declared: list[str], inspect: bool) -> None:
    """The home screen's two figures, and the content rect the hotspots use.

    The hotspot coordinates are compiled against `content_rect`, so a redrawn
    figure that shifts inside its canvas silently moves every dot. Re-measuring
    the PNG here is what catches that.
    """
    spec_path = ROOT / BODY_MAP_SPEC
    print("\nBody map  [{0}]".format(BODY_MAP_SPEC))
    if not spec_path.exists():
        error(BODY_MAP_SPEC + ": missing")
        return
    spec = load_yaml(spec_path)

    for view, art in spec["artwork"].items():
        asset = art["path"]
        label = "{0} ({1})".format(Path(asset).name, view)
        path = ROOT / asset
        if not is_bundled(asset, declared):
            error(
                "{0} is not listed under `flutter: assets:` in pubspec.yaml - "
                "it would never load".format(asset)
            )
        if not path.exists():
            absent(label + " - not drawn yet")
            continue
        if not inspect:
            ok(label + " (present, not inspected)")
            continue

        from PIL import Image, UnidentifiedImageError  # noqa: PLC0415

        try:
            with Image.open(path) as image:
                image.load()
                width, height = image.size
                bbox = content_bbox(image)
        except (UnidentifiedImageError, OSError) as exc:
            error("{0}: cannot be decoded ({1})".format(label, exc))
            continue

        problems: list[str] = []
        if (width, height) != (int(art["width_px"]), int(art["height_px"])):
            problems.append(
                "it is {0}x{1}, but the spec declares {2}x{3}".format(
                    width, height, art["width_px"], art["height_px"]
                )
            )
        if height <= width:
            problems.append("it is not portrait ({0}x{1})".format(width, height))
        if height < BODY_MAP_MIN_HEIGHT:
            problems.append(
                "it is {0}px tall, the spec asks for at least {1}".format(
                    height, BODY_MAP_MIN_HEIGHT
                )
            )
        if problems:
            error(label + ": " + "; ".join(problems))
            continue

        if bbox is None:
            error(label + ": the image is blank")
            continue

        rect = art["content_rect"]
        measured = {
            "left": bbox[0] / width,
            "top": bbox[1] / height,
            "right": bbox[2] / width,
            "bottom": bbox[3] / height,
        }
        drift = {
            edge: abs(measured[edge] - float(rect[edge]))
            for edge in ("left", "top", "right", "bottom")
        }
        worst = max(drift, key=lambda edge: drift[edge])
        if drift[worst] > CONTENT_RECT_TOLERANCE:
            error(
                "{0}: content_rect.{1} says {2:.4f} but the figure measures "
                "{3:.4f}. Re-measure with: python scripts/tune_hotspots.py".format(
                    label, worst, float(rect[worst]), measured[worst]
                )
            )
        else:
            ok("{0} ({1}x{2}, content rect within {3:.4f})".format(
                label, width, height, drift[worst]
            ))

    # Both figures share one set of normalized hotspots, so a difference in
    # scale between them puts every back-view dot in the wrong place.
    sizes = {
        view: (int(art["width_px"]), int(art["height_px"]))
        for view, art in spec["artwork"].items()
    }
    if len(set(sizes.values())) > 1:
        error("the body figures differ in size: {0}".format(sizes))

    # The four card icons are the other half of the home screen's assets.
    home_path = ROOT / HOME_SCREEN_SPEC
    if home_path.exists():
        for item in load_yaml(home_path)["sections"]["items"]:
            icon = item["icon"]
            if not is_bundled(icon, declared):
                error(icon + " is not listed under `flutter: assets:`")
            if not (ROOT / icon).exists():
                absent("{0} (card {1}) - missing".format(Path(icon).name, item["id"]))
            else:
                ok("{0} (card {1})".format(Path(icon).name, item["id"]))


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--require-complete",
        action="store_true",
        help="treat a not-yet-drawn asset as an error",
    )
    args = parser.parse_args()

    inspect = has_pillow()
    library = load_library()
    declared = pubspec_asset_dirs()

    print("Checking image assets against data/exercises/**.yaml")
    if not inspect:
        print("NOTE: " + PILLOW_HINT)
        print("      existence and declaration checks still run.")

    for exercise in library:
        check_exercise(exercise, declared, inspect)
    check_body_map(declared, inspect)

    print("\n" + "-" * 60)
    print(
        "errors: {0}   warnings: {1}   not drawn yet: {2}".format(
            len(errors), len(warnings), len(missing)
        )
    )
    if missing and not args.require_complete:
        print("Missing artwork is expected while the images are being made.")
    if not errors and not missing:
        print("Every declared asset is present and technically valid.")

    if errors:
        return 1
    if missing and args.require_complete:
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
