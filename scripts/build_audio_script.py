#!/usr/bin/env python3
"""Collect every spoken line in the library into one recording script.

    python scripts/build_audio_script.py

The exercise files are the source of truth for what the app says: each
`audio.events` entry carries the text, the asset key and the exact file the
player will look for. Whoever records the voice pack — a person in a booth or
scripts/generate_voice.py — needs that as one ordered list per language, not
spread across thirteen YAML files, so it is generated here.

Lines whose `asset_key` starts with `common.` are recorded once and reused by
every exercise (docs/AUDIO_SPEC.md). A line already on disk is marked as
recorded, so the script doubles as the progress report for the voice pack.
"""
from __future__ import annotations

import sys
from pathlib import Path

import yaml

if hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(errors="replace")

ROOT = Path(__file__).resolve().parents[1]
DATA = ROOT / "data"
OUT = ROOT / "docs/generated/AUDIO_SCRIPT.md"

LOCALE = "uk"

# The preparation countdown is spoken from the global pack rather than per
# exercise (docs/AUDIO_SPEC.md, "Common reusable").
COUNTDOWN = {
    5: "П'ять.",
    4: "Чотири.",
    3: "Три.",
    2: "Два.",
    1: "Один.",
}

VOICE_MODE_LABELS = {
    None: "завжди",
    "phase_words": "режим «Слова руху»",
    "count": "режим «Лічба»",
}


def load(path: Path):
    return yaml.safe_load(path.read_text(encoding="utf-8"))


def escape(text: str) -> str:
    """Markdown table cells cannot carry a raw pipe or a line break."""
    return text.replace("|", "\\|").replace("\n", " ").strip()


def exercise_count(count: int) -> str:
    """1 вправа, 2-4 вправи, 5+ вправ - the report reads as prose."""
    tail = count % 100
    if 11 <= tail <= 14:
        return "{0} вправ".format(count)
    last = count % 10
    if last == 1:
        return "{0} вправа".format(count)
    if 2 <= last <= 4:
        return "{0} вправи".format(count)
    return "{0} вправ".format(count)


def status(target: str | None) -> str:
    if not target:
        return "немає шляху"
    return "записано" if (ROOT / target).exists() else "потрібно записати"


def main() -> int:
    index = load(DATA / "exercises/index.yaml")

    # target file -> (text, mode, [exercise ids that use it])
    common: dict[str, dict] = {}
    for seconds, text in COUNTDOWN.items():
        common["audio/{0}/common/countdown_{1}.m4a".format(LOCALE, seconds)] = {
            "text": text,
            "mode": None,
            "used_by": ["відлік підготовки"],
        }

    sections: list[str] = []
    total = 0
    recorded = 0

    for entry in index["exercises"]:
        raw = load(DATA / "exercises" / entry["file"])
        ex_id = raw["exercise"]["id"]
        title = raw.get("locale", {}).get(LOCALE, {}).get("title", ex_id)
        rows: list[str] = []

        for event in raw.get("audio", {}).get("events", []):
            text = event.get("text_" + LOCALE)
            target = event.get("target_file")
            mode = event.get("voice_mode")
            if not text:
                continue
            if str(event.get("asset_key", "")).startswith("common."):
                shared = common.setdefault(
                    target, {"text": text, "mode": mode, "used_by": []}
                )
                shared["used_by"].append(ex_id)
                continue
            total += 1
            state = status(target)
            if state == "записано":
                recorded += 1
            rows.append(
                "| `{0}` | {1} | {2} | `{3}` | {4} |".format(
                    event["id"],
                    VOICE_MODE_LABELS.get(mode, mode),
                    escape(text),
                    target or "",
                    state,
                )
            )

        if not rows:
            continue
        sections.append("## {0} — {1}\n".format(ex_id, title))
        sections.append("| Репліка | Коли | Текст | Файл | Стан |")
        sections.append("|---|---|---|---|---|")
        sections.extend(rows)
        sections.append("")

    common_rows: list[str] = []
    for target in sorted(common):
        item = common[target]
        total += 1
        state = status(target)
        if state == "записано":
            recorded += 1
        users = item["used_by"]
        used = users[0] if len(users) == 1 else exercise_count(len(users))
        common_rows.append(
            "| {0} | {1} | `{2}` | {3} | {4} |".format(
                escape(item["text"]),
                VOICE_MODE_LABELS.get(item["mode"], item["mode"]),
                target,
                used,
                state,
            )
        )

    head = [
        "# Сценарій озвучки — {0}".format(LOCALE),
        "",
        "Згенеровано `scripts/build_audio_script.py` з `data/exercises/**.yaml`.",
        "Не редагувати вручну: правити треба текст репліки у файлі вправи.",
        "",
        "**Стиль:** спокійний, доброзичливий, чіткий, без поспіху, короткі фрази.",
        "Не говорити поверх критичної команди руху (docs/AUDIO_SPEC.md).",
        "",
        "**Формат:** майстер WAV, нормалізований, із підрізаною тишею; ",
        "доставка в застосунок — M4A/AAC за шляхом із колонки «Файл».",
        "",
        "**Режими голосу:** «завжди» звучить у будь-якому режимі; репліки режимів ",
        "«Слова руху» та «Лічба» звучать лише тоді, коли користувач обрав цей ",
        "режим у Налаштуваннях, і мають бути короткими — вони мусять вкластися в ",
        "половину циклу руху (близько двох секунд).",
        "",
        "Записано {0} із {1} реплік.".format(recorded, total),
        "",
        "## Спільні репліки",
        "",
        "Записуються один раз і використовуються всіма вправами.",
        "",
        "| Текст | Коли | Файл | Використовує | Стан |",
        "|---|---|---|---|---|",
    ]

    lines = head + common_rows + [""] + sections
    OUT.parent.mkdir(parents=True, exist_ok=True)
    OUT.write_text("\n".join(lines).rstrip() + "\n", encoding="utf-8")

    print("OK: " + str(OUT.relative_to(ROOT)))
    print("- lines: {0}".format(total))
    print("- recorded: {0}".format(recorded))
    return 0


if __name__ == "__main__":
    sys.exit(main())
