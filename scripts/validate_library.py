#!/usr/bin/env python3
from pathlib import Path
import json, sys, yaml
from jsonschema import Draft202012Validator

ROOT = Path(__file__).resolve().parents[1]
SCHEMA = json.loads((ROOT / "schemas/exercise.schema.json").read_text(encoding="utf-8"))
validator = Draft202012Validator(SCHEMA)

exercise_files = sorted((ROOT / "data/exercises").rglob("*.yaml"))
exercise_files = [p for p in exercise_files if p.name != "index.yaml"]

errors = []
ids = {}
slugs = {}

for path in exercise_files:
    try:
        data = yaml.safe_load(path.read_text(encoding="utf-8"))
    except Exception as exc:
        errors.append(f"{path}: YAML parse error: {exc}")
        continue

    for err in validator.iter_errors(data):
        where = ".".join(str(x) for x in err.absolute_path)
        errors.append(f"{path}: schema error at {where or '<root>'}: {err.message}")

    ex = data.get("exercise", {})
    ex_id = ex.get("id")
    slug = ex.get("slug")

    if ex_id:
        if ex_id in ids:
            errors.append(f"duplicate exercise id {ex_id}: {ids[ex_id]} and {path}")
        ids[ex_id] = path
    if slug:
        if slug in slugs:
            errors.append(f"duplicate exercise slug {slug}: {slugs[slug]} and {path}")
        slugs[slug] = path

if errors:
    print("VALIDATION FAILED")
    for e in errors:
        print("-", e)
    sys.exit(1)

print(f"OK: {len(exercise_files)} exercise files validated.")
for ex_id, path in sorted(ids.items()):
    print(f"- {ex_id}: {path.relative_to(ROOT)}")
