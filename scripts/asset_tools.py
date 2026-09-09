#!/usr/bin/env python3
"""Shared helpers for the image-asset scripts.

check_assets.py, make_previews.py and build_review_sheet.py all need the same
two things: the frame list an exercise declares, and where the drawn subject
actually sits inside a PNG. Keeping that in one place means the safe-area
check and the preview crop can never disagree about what "the content" is.

Pillow is imported lazily: reading the library needs no image support, so a
machine without Pillow can still run the parts that only read YAML.
"""
from __future__ import annotations

import sys
from dataclasses import dataclass, field
from pathlib import Path
from typing import Any

import yaml

# These scripts are CLI-only and print exercise titles and file paths. A
# Windows console in a legacy code page cannot encode every character in the
# data, and a report must not die on one arrow: replace instead of raising.
if hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(errors="replace")

ROOT = Path(__file__).resolve().parents[1]
DATA = ROOT / "data"

LOCALE = "uk"

# The two files lib/features/body_map/body_map_screen.dart loads by view name.
BODY_MAP_VIEWS: tuple[str, ...] = ("front", "back")
BODY_MAP_DIR = "assets/body-map"

# docs/IMAGE_ASSET_SPEC.md 2: a raster body map should be portrait and at
# least this tall; SVG is preferred once the style is settled.
BODY_MAP_MIN_HEIGHT = 1200

# docs/IMAGE_ASSET_SPEC.md 3: key body parts stay inside the central ~90%.
SAFE_AREA = 0.90

PILLOW_HINT = "pip install -r tools/requirements.txt  (Pillow is needed to inspect images)"


def load_yaml(path: Path) -> Any:
    return yaml.safe_load(path.read_text(encoding="utf-8"))


@dataclass
class Frame:
    id: str
    file: str
    pose: str = ""
    alt_text: str = ""
    validation_points: list[str] = field(default_factory=list)

    @property
    def path(self) -> Path:
        return ROOT / self.file

    @property
    def name(self) -> str:
        return Path(self.file).name


@dataclass
class ExerciseAssets:
    id: str
    title: str
    source: str
    zone: str
    clinical_status: str
    folder: str
    frames: list[Frame]
    required: list[str]
    optional: list[str]
    width_px: int
    height_px: int
    master_format: str
    transparent_preferred: bool
    preview_file: str | None
    preview_source_frame_id: str | None
    validation: dict[str, Any]

    @property
    def folder_path(self) -> Path:
        return ROOT / self.folder

    def frame_by_id(self, frame_id: str) -> Frame | None:
        for frame in self.frames:
            if frame.id == frame_id:
                return frame
        return None


def load_library() -> list[ExerciseAssets]:
    """Every exercise in index order, with its declared image assets."""
    index = load_yaml(DATA / "exercises/index.yaml")
    result: list[ExerciseAssets] = []
    for entry in index["exercises"]:
        path = DATA / "exercises" / entry["file"]
        result.append(_read_exercise(path))
    return result


def _read_exercise(path: Path) -> ExerciseAssets:
    raw = load_yaml(path)
    ex = raw["exercise"]
    animation = raw.get("animation", {})
    spec = animation.get("asset_spec", {})
    assets = raw.get("assets", {})
    preview = animation.get("preview") or {}
    loc = raw.get("locale", {}).get(LOCALE, {})

    frames = [
        Frame(
            id=frame["id"],
            file=frame["file"],
            pose=(frame.get("pose_description_" + LOCALE) or "").strip(),
            alt_text=(frame.get("alt_text_" + LOCALE) or "").strip(),
            validation_points=list(frame.get("validation_points") or []),
        )
        for frame in animation.get("frames", [])
    ]

    return ExerciseAssets(
        id=ex["id"],
        title=loc.get("title", ex["id"]),
        source=path.relative_to(ROOT).as_posix(),
        zone=ex.get("classification", {}).get("primary_zone", ""),
        clinical_status=raw.get("clinical", {}).get("status", ""),
        folder=assets.get("folder", ""),
        frames=frames,
        required=list(assets.get("required") or []),
        optional=list(assets.get("optional") or []),
        width_px=int(spec.get("width_px", 1024)),
        height_px=int(spec.get("height_px", 1024)),
        master_format=str(spec.get("master_format", "png")).lower(),
        transparent_preferred=bool(spec.get("transparent_background_preferred")),
        preview_file=preview.get("file"),
        preview_source_frame_id=preview.get("source_frame_id"),
        validation=dict(assets.get("validation") or {}),
    )


def pubspec_asset_dirs() -> list[str]:
    """The `flutter: assets:` entries, as declared. A folder that is missing
    from this list is not bundled, so its images silently never load."""
    spec = load_yaml(ROOT / "pubspec.yaml")
    return [str(entry) for entry in (spec.get("flutter", {}).get("assets") or [])]


def is_bundled(asset_path: str, declared: list[str]) -> bool:
    """Flutter bundles a file when it is listed outright, or when the folder
    it sits in is listed with a trailing slash."""
    if asset_path in declared:
        return True
    parent = Path(asset_path).parent.as_posix() + "/"
    return parent in declared


# --------------------------------------------------------------------- images


def require_pillow():
    try:
        from PIL import Image  # noqa: PLC0415
    except ImportError as exc:  # pragma: no cover - environment dependent
        raise SystemExit("ERROR: " + PILLOW_HINT) from exc
    return Image


def has_pillow() -> bool:
    try:
        import PIL  # noqa: F401, PLC0415
    except ImportError:
        return False
    return True


def content_bbox(image) -> tuple[int, int, int, int] | None:
    """Where the drawn subject sits, as (left, top, right, bottom).

    Transparent images give an exact answer from the alpha channel. For opaque
    ones the flat background is inferred from the four corners, which is what
    the briefs ask for ("plain neutral light background"). Returns None for an
    image with no content at all.
    """
    from PIL import Image, ImageChops  # noqa: PLC0415

    if "A" in image.getbands():
        alpha = image.getchannel("A")
        if alpha.getextrema()[0] < 255:
            return alpha.getbbox()

    rgb = image.convert("RGB")
    width, height = rgb.size
    corners = [
        rgb.getpixel((0, 0)),
        rgb.getpixel((width - 1, 0)),
        rgb.getpixel((0, height - 1)),
        rgb.getpixel((width - 1, height - 1)),
    ]
    background = tuple(sorted(channel)[len(channel) // 2] for channel in zip(*corners))
    flat = Image.new("RGB", rgb.size, background)
    # 24 out of 255 per channel: tolerant of soft-lit gradients in the
    # background, still catching a limb against a light wall.
    mask = ImageChops.difference(rgb, flat).convert("L").point(
        lambda value: 255 if value > 24 else 0
    )
    return mask.getbbox()


def safe_area_overflow(
    bbox: tuple[int, int, int, int], size: tuple[int, int]
) -> dict[str, int]:
    """How far the content reaches past the safe area, per edge, in pixels."""
    width, height = size
    margin_x = width * (1 - SAFE_AREA) / 2
    margin_y = height * (1 - SAFE_AREA) / 2
    left, top, right, bottom = bbox
    overflow = {
        "left": int(round(margin_x - left)),
        "top": int(round(margin_y - top)),
        "right": int(round(right - (width - margin_x))),
        "bottom": int(round(bottom - (height - margin_y))),
    }
    return {edge: value for edge, value in overflow.items() if value > 0}
