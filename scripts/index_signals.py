#!/usr/bin/env python3
"""Index Factorio virtual signal icons into repo metadata (no images are copied).

Usage:
    py -3 scripts/index_signals.py [--factorio-data <path to Factorio/data>]

Writes:
    assets/signals/signals.json   machine-readable index
    assets/signals/SIGNALS.md     human-readable table
Creates (gitignored) junction assets/factorio-data -> Factorio data folder for local previews.
"""

import argparse
import json
import os
import re
import struct
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
OUT_DIR = ROOT / "assets" / "signals"
LINK = ROOT / "assets" / "factorio-data"
DEFAULT_DATA = Path(r"C:\Program Files (x86)\Steam\steamapps\common\Factorio\data")
MODS = ["core", "base", "quality", "elevated-rails", "recycler", "space-age"]

BLOCK_RE = re.compile(r"\{[^{}]*?type\s*=\s*\"virtual-signal\"[^{}]*?\}", re.S)
FIELD_RE = {
    key: re.compile(key + r"\s*=\s*\"([^\"]*)\"")
    for key in ("name", "icon", "subgroup", "order")
}
SIZE_RE = re.compile(r"icon_size\s*=\s*(\d+)")

SUBGROUP_HINTS = {
    "virtual-signal-special": "Wildcard signal used by combinators (everything / anything / each).",
    "virtual-signal-color": "Solid color signal, often used for lamp colors or status.",
    "virtual-signal-number": "Digit signal.",
    "virtual-signal-letter": "Latin letter signal.",
    "virtual-signal-punctuation": "Punctuation / symbol signal.",
    "virtual-signal-math": "Math / comparison operator signal.",
    "shapes": "Geometric shape signal.",
    "arrows": "Direction arrow signal.",
    "arrows-misc": "Rotation / misc arrow signal.",
    "pictographs": "Pictograph signal (status or theme symbol).",
    "parameters": "Blueprint parameter placeholder signal.",
    "qualities": "Quality-related signal.",
    "virtual-signal": "Miscellaneous virtual signal (status / utility).",
}


def parse_locale(path: Path, section: str):
    result = {}
    if not path.exists():
        return result
    current = None
    for line in path.read_text(encoding="utf-8").splitlines():
        line = line.strip()
        if line.startswith("[") and line.endswith("]"):
            current = line[1:-1]
        elif current == section and "=" in line:
            key, value = line.split("=", 1)
            result[key] = value
    return result


def png_size(path: Path):
    try:
        with path.open("rb") as handle:
            head = handle.read(24)
        if head[:8] == b"\x89PNG\r\n\x1a\n":
            return list(struct.unpack(">II", head[16:24]))
    except OSError:
        pass
    return None


def resolve_icon(data: Path, icon: str):
    match = re.match(r"__([\w-]+)__/(.*)", icon)
    if not match:
        return None
    return data / match.group(1) / match.group(2)


def describe(name: str, subgroup: str, en: str):
    hint = SUBGROUP_HINTS.get(subgroup, SUBGROUP_HINTS["virtual-signal"])
    return f"{en or name}. {hint}"


def ensure_link(data: Path):
    if LINK.exists():
        return
    if os.name == "nt":
        subprocess.run(["cmd", "/c", "mklink", "/J", str(LINK), str(data)], check=False, capture_output=True)
    else:
        LINK.symlink_to(data, target_is_directory=True)


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--factorio-data", type=Path, default=DEFAULT_DATA)
    args = parser.parse_args()
    data = args.factorio_data
    if not data.exists():
        sys.exit(f"Factorio data not found: {data}")

    locale_en, locale_ru = {}, {}
    for mod in MODS:
        for cfg in (data / mod / "locale" / "en").glob("*.cfg"):
            locale_en.update(parse_locale(cfg, "virtual-signal-name"))
        for cfg in (data / mod / "locale" / "ru").glob("*.cfg"):
            locale_ru.update(parse_locale(cfg, "virtual-signal-name"))

    signals = []
    for mod in MODS:
        for lua in sorted((data / mod / "prototypes").rglob("*.lua")):
            text = lua.read_text(encoding="utf-8", errors="replace")
            for block in BLOCK_RE.findall(text):
                fields = {key: (rx.search(block).group(1) if rx.search(block) else None) for key, rx in FIELD_RE.items()}
                if not fields["name"]:
                    continue
                icon_file = resolve_icon(data, fields["icon"]) if fields["icon"] else None
                size_match = SIZE_RE.search(block)
                name = fields["name"]
                en = locale_en.get(name, "")
                signals.append({
                    "name": name,
                    "mod": mod,
                    "subgroup": fields["subgroup"],
                    "order": fields["order"],
                    "icon": fields["icon"],
                    "icon_size": int(size_match.group(1)) if size_match else 64,
                    "image_size": png_size(icon_file) if icon_file else None,
                    "local_preview": (
                        "assets/factorio-data/" + icon_file.relative_to(data).as_posix()
                        if icon_file and icon_file.exists() else None
                    ),
                    "locale_en": en,
                    "locale_ru": locale_ru.get(name, ""),
                    "sprite": f"virtual-signal/{name}",
                    "rich_text": f"[virtual-signal={name}]",
                    "signal_id": {"type": "virtual", "name": name},
                    "description": describe(name, fields["subgroup"], en),
                })

    signals.sort(key=lambda s: (s["mod"] != "base", s["subgroup"] or "", s["order"] or "", s["name"]))
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    (OUT_DIR / "signals.json").write_text(
        json.dumps({"source": "Factorio data/*/prototypes (virtual-signal)", "count": len(signals), "signals": signals},
                   ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )

    lines = [
        "# Factorio virtual signals index",
        "",
        "Generated by `py -3 scripts/index_signals.py`. Icons are not stored in the repo;",
        "local previews resolve through the gitignored junction `assets/factorio-data`.",
        "",
        "Use in mods: sprite `virtual-signal/<name>`, rich text `[virtual-signal=<name>]`,",
        "SignalID `{type = \"virtual\", name = \"<name>\"}`, or the raw icon path in prototypes.",
        "",
        f"Total: {len(signals)}",
        "",
        "| Name | Mod | Subgroup | EN | RU | Icon |",
        "| --- | --- | --- | --- | --- | --- |",
    ]
    for s in signals:
        lines.append(
            f"| `{s['name']}` | {s['mod']} | {s['subgroup'] or ''} | {s['locale_en']} | {s['locale_ru']} | `{s['icon'] or ''}` |"
        )
    (OUT_DIR / "SIGNALS.md").write_text("\n".join(lines) + "\n", encoding="utf-8")

    ensure_link(data)
    print(f"Indexed {len(signals)} signals -> {OUT_DIR}")


if __name__ == "__main__":
    main()
