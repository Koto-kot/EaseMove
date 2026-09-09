#!/usr/bin/env python3
"""Compile authoring YAML into a validated runtime JSON bundle.

Authoring format (canonical): data/**.yaml
Runtime format (generated):   assets/content/**.json

The Flutter app never parses YAML at runtime (docs/TECHNICAL_SPEC.md 22).
Schema validation runs here too, so a broken bundle can never be produced.
"""
from __future__ import annotations

import json
import shutil
import sys
from pathlib import Path
from typing import Any

import yaml
from jsonschema import Draft202012Validator

ROOT = Path(__file__).resolve().parents[1]
DATA = ROOT / "data"
OUT = ROOT / "assets" / "content"

CLINICAL_STATUSES = {"draft", "pending_review", "approved", "retired"}

# Situation entry points in the app's main navigation
# (docs/MENU_AND_NAVIGATION.md). They must exist even while still unfilled,
# otherwise a tab renders with no collection behind it.
NAVIGATION_COLLECTIONS = ("computer_break", "bed_basic", "eyes_basic")


def load_yaml(path: Path) -> Any:
    return yaml.safe_load(path.read_text(encoding="utf-8"))


def write_json(path: Path, payload: Any) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(
        json.dumps(payload, ensure_ascii=False, indent=2, sort_keys=False) + "\n",
        encoding="utf-8",
    )


# ---------------------------------------------------------------- sequence


def normalize_sequence(raw: dict) -> dict:
    """Collapse the three authoring shapes into one runtime shape.

    side_blocks           -> blocks with a side
    steps + repeat        -> one sideless block
    steps + repeat_cycles -> one sideless block
    """
    if "side_blocks" in raw:
        blocks = [
            {
                "side": block.get("side"),
                "repeat": int(block.get("repeat", 1)),
                "steps": [normalize_step(s) for s in block["steps"]],
            }
            for block in raw["side_blocks"]
        ]
    elif "steps" in raw:
        repeat = raw.get("repeat", raw.get("repeat_cycles", 1))
        blocks = [
            {
                "side": None,
                "repeat": int(repeat),
                "steps": [normalize_step(s) for s in raw["steps"]],
            }
        ]
    else:
        raise ValueError("sequence has neither side_blocks nor steps")

    for block in blocks:
        if block["repeat"] < 1:
            raise ValueError("sequence block repeat must be >= 1")
        if not block["steps"]:
            raise ValueError("sequence block has no steps")
    return {"blocks": blocks}


def normalize_step(step: dict) -> dict:
    transition = step.get("frame_transition")
    duration = int(step["duration_ms"])
    if duration <= 0:
        raise ValueError("step {0} has non-positive duration_ms".format(step.get("id")))
    if not transition and not step.get("frame_id"):
        raise ValueError(
            "step {0} has neither frame_id nor frame_transition".format(step.get("id"))
        )
    return {
        "id": step["id"],
        "phase": step.get("phase"),
        "side": step.get("side"),
        "frameId": step.get("frame_id"),
        "frameTransition": None
        if not transition
        else {
            "from": transition.get("from"),
            "via": transition.get("via"),
            "to": transition.get("to"),
        },
        "durationMs": duration,
        "voiceEvent": step.get("voice_event"),
    }


# ---------------------------------------------------------------- exercise


def compile_exercise(path: Path, locale: str) -> dict:
    raw = load_yaml(path)
    ex = raw["exercise"]
    classification = ex.get("classification", {})
    availability = ex.get("availability", {})
    clinical = raw.get("clinical", {})
    status = clinical.get("status")
    if status not in CLINICAL_STATUSES:
        raise ValueError("{0}: unknown clinical.status {1}".format(path.name, status))

    loc = raw.get("locale", {}).get(locale) or {}
    timing = raw.get("timing", {})
    progress = timing.get("progress", {})
    flow = raw.get("flow", {})
    animation = raw.get("animation", {})
    audio = raw.get("audio", {})

    frames = {}
    for frame in animation.get("frames", []):
        frames[frame["id"]] = {
            "id": frame["id"],
            "file": frame["file"],
            "altText": frame.get("alt_text_" + locale),
        }

    sequence = normalize_sequence(raw["sequence"])
    voice_events = {e["id"] for e in audio.get("events", [])}
    for block in sequence["blocks"]:
        for step in block["steps"]:
            for frame_id in frame_ids_of(step):
                if frame_id not in frames:
                    raise ValueError(
                        "{0}: step {1} references unknown frame {2}".format(
                            path.name, step["id"], frame_id
                        )
                    )
            cue = step["voiceEvent"]
            if cue and cue not in voice_events:
                raise ValueError(
                    "{0}: step {1} references unknown voice event {2}".format(
                        path.name, step["id"], cue
                    )
                )

    return {
        "id": ex["id"],
        "slug": ex["slug"],
        "schemaVersion": str(raw.get("schema_version", "")),
        "contentVersion": str(raw.get("content_version", "")),
        "clinicalStatus": status,
        "editorialStatus": ex.get("status", "draft"),
        "primaryZone": classification.get("primary_zone"),
        "secondaryZones": classification.get("secondary_zones") or [],
        "hotspotIds": classification.get("body_map_hotspot_ids") or [],
        "tags": flatten_tags(classification.get("tags")),
        "tagGroups": classification.get("tags") or {},
        "collections": classification.get("collections") or [],
        "collectionCandidates": classification.get("collection_candidates") or [],
        "text": compile_text(loc),
        "labels": compile_labels(raw.get("ui"), locale),
        "timing": {
            "prepCountdownSeconds": int(
                timing.get("prep_countdown_seconds", flow.get("start_countdown_seconds", 5))
            ),
            "restAfterSeconds": int(timing.get("rest_after_seconds", 10)),
            "completionMode": timing.get("completion_mode", "prescribed_repetitions"),
            "estimatedActiveSeconds": int(timing.get("estimated_active_duration_seconds", 0)),
        },
        "progress": {
            "basis": progress.get("basis", "sequence_time"),
            "showElapsedTime": bool(progress.get("show_elapsed_time", True)),
            "showProgressBar": bool(progress.get("show_progress_bar", True)),
            "showRepetitionCounter": bool(progress.get("show_repetition_counter", False)),
            "showSideLabel": bool(progress.get("show_side_label", False)),
            "showSetCounter": bool(progress.get("show_set_counter", False)),
        },
        "repetitionModel": compile_repetition_model(raw.get("repetition_model"), sequence),
        "movementPhases": [
            {"id": p["id"], "name": p.get("name_" + locale), "type": p.get("phase_type")}
            for p in raw.get("movement_phases", [])
        ],
        "sequence": sequence,
        "animation": {
            "reducedMotionFallback": animation.get("reduced_motion_fallback"),
            "frames": list(frames.values()),
            "preview": (animation.get("preview") or {}).get("file"),
        },
        "audio": {
            "events": [compile_audio_event(e, locale) for e in audio.get("events", [])],
            "mix": {
                "voiceLevel": float((audio.get("mix") or {}).get("voice_level", 1.0)),
                "musicLevel": float(
                    (audio.get("mix") or {}).get("music_level_relative_to_voice", 0.5)
                ),
                "dynamicDucking": bool((audio.get("mix") or {}).get("dynamic_ducking", False)),
            },
        },
        "flow": {
            "autoNextEnabled": bool((flow.get("auto_next") or {}).get("enabled", True)),
            "restSeconds": int(
                (flow.get("auto_next") or {}).get(
                    "rest_seconds", timing.get("rest_after_seconds", 10)
                )
            ),
            "incrementCounterOnCompletion": bool(
                (flow.get("completion") or {}).get("increment_lifetime_exercise_counter", True)
            ),
        },
        "accessibility": {
            "summary": (raw.get("accessibility", {}).get("screen_reader") or {}).get(
                "exercise_summary_" + locale
            ),
            "reducedMotionSupported": bool(
                (raw.get("accessibility", {}).get("reduced_motion") or {}).get("supported", True)
            ),
        },
        "pro": {
            "tier": availability.get("tier", "free"),
            "requiresPro": availability.get("tier", "free") != "free",
            "visibleToFree": bool(availability.get("visible_to_free_users", True)),
            "allowFavorite": bool((raw.get("pro") or {}).get("allow_favorite", False)),
            "includeInPersonalPlanPool": bool(
                (raw.get("pro") or {}).get("include_in_personal_plan_pool", False)
            ),
        },
    }


def flatten_tags(groups) -> list:
    """classification.tags is a dict of named groups; runtime wants a flat set."""
    if not groups:
        return []
    if isinstance(groups, list):
        return list(groups)
    flat = []
    for values in groups.values():
        for value in values or []:
            if value not in flat:
                flat.append(value)
    return flat


def frame_ids_of(step: dict) -> list:
    if step["frameId"]:
        return [step["frameId"]]
    transition = step["frameTransition"] or {}
    return [v for v in (transition.get("from"), transition.get("via"), transition.get("to")) if v]


def compile_text(loc: dict) -> dict:
    instructions = loc.get("instructions") or []
    return {
        "title": loc.get("title"),
        "shortTitle": loc.get("short_title"),
        "cardDescription": loc.get("card_description"),
        "categoryLabel": loc.get("category_label"),
        "purpose": loc.get("purpose_text"),
        "startPositionTitle": loc.get("start_position_title"),
        "startPosition": loc.get("start_position_text"),
        "instructionsTitle": loc.get("instructions_title"),
        "instructions": [
            {"step": int(item.get("step", n + 1)), "text": item.get("text")}
            for n, item in enumerate(instructions)
        ],
        "techniqueTipsTitle": loc.get("technique_tips_title"),
        "techniqueTips": loc.get("technique_tips") or [],
        "safetyLabel": loc.get("safety_label"),
        "safety": loc.get("safety_text"),
        "completion": loc.get("completion_text"),
    }


def compile_labels(ui, locale: str) -> dict:
    """Per-exercise label overrides, e.g. KNEE_001 calls the side "Нога".

    The UI falls back to the common localization key when a label is absent.
    """
    labels = ((ui or {}).get("exercise_screen") or {}).get("labels") or {}
    resolved = {}
    for name, value in labels.items():
        if not isinstance(value, dict):
            continue
        text = value.get("resolved_" + locale)
        if text:
            resolved[name] = text
    return resolved


def compile_repetition_model(model, sequence: dict) -> dict:
    blocks = sequence["blocks"]
    if not model:
        return {
            "type": "sequence_time",
            "sets": 1,
            "repetitionsPerBlock": blocks[0]["repeat"] if blocks else 1,
            "blockOrder": [b["side"] for b in blocks],
            "switchSideAutomatically": True,
            "resetCounterOnSideChange": False,
        }
    return {
        "type": model.get("type", "sequence_time"),
        "sets": int(model.get("sets", 1)),
        "repetitionsPerBlock": int(model.get("repetitions_per_block", model.get("repetitions", 1))),
        "blockOrder": model.get("block_order", [b["side"] for b in blocks]),
        "switchSideAutomatically": bool(model.get("switch_side_automatically", True)),
        "resetCounterOnSideChange": bool(
            model.get("reset_repetition_counter_on_side_change", False)
        ),
    }


def compile_audio_event(event: dict, locale: str) -> dict:
    trigger = event.get("trigger", {})
    return {
        "id": event["id"],
        "type": event.get("type"),
        "priority": int(event.get("priority", 50)),
        "interruptible": bool(event.get("interruptible", True)),
        "playOncePerSide": bool(event.get("play_once_per_side", False)),
        "text": event.get("text_" + locale),
        "assetKey": event.get("asset_key"),
        "assetFile": event.get("target_file"),
        "trigger": {
            "event": trigger.get("event"),
            "phase": trigger.get("phase"),
            "side": trigger.get("side"),
            "percent": trigger.get("percent"),
            "repetitionNumber": trigger.get("repetition_number"),
            "relativePosition": trigger.get("relative_position"),
            "offsetMs": trigger.get("offset_ms"),
        },
    }


# ---------------------------------------------------------------- bundle


def main() -> int:
    locale = "uk"
    schema = json.loads((ROOT / "schemas/exercise.schema.json").read_text(encoding="utf-8"))
    validator = Draft202012Validator(schema)

    index = load_yaml(DATA / "exercises/index.yaml")
    collections = load_yaml(DATA / "collections/collections.yaml")
    zones = load_yaml(DATA / "categories/body_zones.yaml")
    hotspots = load_yaml(DATA / "categories/body_hotspots.yaml")
    locale_packs = {}
    for pack in sorted((DATA / "localization").glob("*/common.yaml")):
        locale_packs[pack.parent.name] = load_yaml(pack)["strings"]
    if locale not in locale_packs:
        print("CONTENT BUILD FAILED")
        print("- missing authoring locale pack: data/localization/{0}/common.yaml".format(locale))
        return 1
    common = {"strings": locale_packs[locale]}

    errors = []
    warnings = []
    summaries = []
    compiled_all = []

    for entry in index["exercises"]:
        path = DATA / "exercises" / entry["file"]
        if not path.exists():
            errors.append("index references missing file: " + entry["file"])
            continue
        raw = load_yaml(path)
        for err in validator.iter_errors(raw):
            where = ".".join(str(x) for x in err.absolute_path) or "<root>"
            errors.append("{0}: schema error at {1}: {2}".format(path.name, where, err.message))
        try:
            compiled = compile_exercise(path, locale)
        except ValueError as exc:
            errors.append(str(exc))
            continue

        if compiled["id"] != entry["id"]:
            errors.append(
                "{0}: id {1} != index id {2}".format(path.name, compiled["id"], entry["id"])
            )
        if compiled["clinicalStatus"] != entry.get("clinical_status"):
            errors.append(
                "{0}: clinical status {1} != index {2}".format(
                    path.name, compiled["clinicalStatus"], entry.get("clinical_status")
                )
            )
        if sorted(compiled["collections"]) != sorted(entry.get("collections", [])):
            errors.append(path.name + ": collections differ from index entry")

        compiled_all.append(compiled)
        summaries.append(
            {
                "id": compiled["id"],
                "title": compiled["text"]["title"],
                "cardDescription": compiled["text"]["cardDescription"],
                "primaryZone": compiled["primaryZone"],
                "clinicalStatus": compiled["clinicalStatus"],
                "collections": compiled["collections"],
                "tags": compiled["tags"],
                "preview": compiled["animation"]["preview"],
                "estimatedActiveSeconds": compiled["timing"]["estimatedActiveSeconds"],
                "requiresPro": compiled["pro"]["requiresPro"],
            }
        )

    known_collections = {c["id"] for c in collections["collections"]}
    for nav_id in NAVIGATION_COLLECTIONS:
        if nav_id not in known_collections:
            errors.append(
                "navigation collection {0} is missing from "
                "data/collections/collections.yaml".format(nav_id)
            )

    for summary in summaries:
        for collection_id in summary["collections"]:
            if collection_id not in known_collections:
                errors.append("{0}: unknown collection {1}".format(summary["id"], collection_id))

    known_zones = {z["id"] for z in zones["zones"]}
    known_hotspots = {s["id"] for s in hotspots["hotspots"]}
    for compiled in compiled_all:
        if compiled["primaryZone"] not in known_zones:
            errors.append(
                "{0}: unknown primary zone {1}".format(compiled["id"], compiled["primaryZone"])
            )
        # Editorial hint only: navigation routes through hotspot action.collection_id,
        # so a stale id here must not break the build.
        for spot_id in compiled["hotspotIds"]:
            if spot_id not in known_hotspots:
                warnings.append(
                    "{0}: body_map_hotspot_ids references unknown hotspot {1}".format(
                        compiled["id"], spot_id
                    )
                )

    for spot in hotspots["hotspots"]:
        if spot["zone_id"] not in known_zones:
            errors.append("hotspot {0}: unknown zone {1}".format(spot["id"], spot["zone_id"]))
        target = (spot.get("action") or {}).get("collection_id")
        if target and target not in known_collections:
            errors.append("hotspot {0}: unknown collection {1}".format(spot["id"], target))

    if errors:
        print("CONTENT BUILD FAILED")
        for e in errors:
            print("-", e)
        return 1

    for w in warnings:
        print("WARNING:", w)

    if OUT.exists():
        shutil.rmtree(OUT)
    for compiled in compiled_all:
        write_json(OUT / "exercises" / (compiled["id"] + ".json"), compiled)

    write_json(
        OUT / "index.json",
        {
            "generatedFrom": "data/",
            "defaultLocale": locale,
            "exercises": summaries,
            "collections": [
                {
                    "id": c["id"],
                    "title": c.get("title_" + locale),
                    "type": c.get("type"),
                    "primaryZone": c.get("primary_zone"),
                    "sort": c.get("sort", "editorial"),
                }
                for c in collections["collections"]
            ],
            "zones": [
                {"id": z["id"], "title": z.get("title_" + locale), "order": int(z.get("order", 0))}
                for z in zones["zones"]
            ],
            "bodyMap": {
                "coordinateSystem": hotspots["coordinate_system"]["type"],
                "hotspots": [
                    {
                        "id": s["id"],
                        "zoneId": s["zone_id"],
                        "view": s["view"],
                        "labelKey": s["label_key"],
                        "priority": int(s.get("priority", 0)),
                        "rect": {
                            "x": float(s["rect"]["x"]),
                            "y": float(s["rect"]["y"]),
                            "width": float(s["rect"]["width"]),
                            "height": float(s["rect"]["height"]),
                        },
                        "action": {
                            "type": s["action"]["type"],
                            "collectionId": s["action"].get("collection_id"),
                        },
                    }
                    for s in hotspots["hotspots"]
                ],
            },
        },
    )
    authoring_keys = set(locale_packs[locale])
    for pack_locale, strings in sorted(locale_packs.items()):
        write_json(OUT / "localization" / (pack_locale + ".json"), strings)
        missing = sorted(authoring_keys - set(strings))
        if missing:
            print(
                "WARNING: locale {0} is missing {1} key(s), e.g. {2}".format(
                    pack_locale, len(missing), ", ".join(missing[:3])
                )
            )

    print("OK: content bundle written to " + str(OUT.relative_to(ROOT)))
    print("- exercises: {0}".format(len(summaries)))
    print("- collections: {0}".format(len(collections["collections"])))
    print("- zones: {0}".format(len(zones["zones"])))
    print("- hotspots: {0}".format(len(hotspots["hotspots"])))
    for pack_locale, strings in sorted(locale_packs.items()):
        print("- {0} common strings: {1}".format(pack_locale, len(strings)))
    return 0


if __name__ == "__main__":
    sys.exit(main())
