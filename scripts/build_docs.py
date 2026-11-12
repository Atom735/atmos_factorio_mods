#!/usr/bin/env python3
"""Compile per-language docs into the combined files shipped/published.

Sources (edit these):  README_EN.md, README_RU.md, changelog_EN.txt, changelog_RU.txt
Outputs (generated):   README.md, changelog.txt

README.md    = EN part, separator, RU part.
changelog.txt = per version, per category: EN entries followed by RU entries.
RU categories are matched to EN by name, or by position when translated.

Usage: py -3 scripts/build_docs.py [mod_folder ...] [--check]
Without folders, every top-level folder with an info.json and _EN sources is built.
"""
from __future__ import annotations

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SEPARATOR = "-" * 99
README_JOIN = "\n\n---\n\n"
HEADER = re.compile(r"^(Version|Date):\s*(.*)$")


def read(path: Path) -> str | None:
    return path.read_text(encoding="utf-8").replace("\r\n", "\n") if path.is_file() else None


def build_readme(en: str, ru: str | None) -> str:
    parts = [en.strip()]
    if ru and ru.strip():
        parts.append(ru.strip())
    return README_JOIN.join(parts) + "\n"


def parse_changelog(text: str) -> list[dict]:
    versions: list[dict] = []
    for block in text.split(SEPARATOR):
        lines = [l.rstrip() for l in block.split("\n") if l.strip()]
        if not lines:
            continue
        ver = {"version": None, "date": None, "categories": []}
        for line in lines:
            m = HEADER.match(line.strip()) if not line.startswith(" ") else None
            if m:
                ver[m.group(1).lower()] = m.group(2).strip()
            elif re.match(r"^  \S.*:$", line):
                ver["categories"].append([line.strip()[:-1], []])
            elif line.startswith("    "):
                if not ver["categories"]:
                    raise ValueError(f"entry outside category: {line!r}")
                ver["categories"][-1][1].append(line)
            else:
                raise ValueError(f"unrecognised changelog line: {line!r}")
        if not ver["version"]:
            raise ValueError("changelog block without Version:")
        versions.append(ver)
    return versions


def merge_changelog(en: str, ru: str | None) -> str:
    en_v = parse_changelog(en)
    ru_map = {v["version"]: v for v in parse_changelog(ru)} if ru else {}
    out: list[str] = []
    for v in en_v:
        out.append(SEPARATOR)
        out.append(f"Version: {v['version']}")
        if v["date"]:
            out.append(f"Date: {v['date']}")
        ru_cats = ru_map.get(v["version"], {}).get("categories", [])
        ru_by_name = {name: entries for name, entries in ru_cats}
        for i, (name, entries) in enumerate(v["categories"]):
            extra = ru_by_name.get(name)
            if extra is None and i < len(ru_cats):
                extra = ru_cats[i][1]
            out.append(f"  {name}:")
            out.extend(entries)
            out.extend(extra or [])
    return "\n".join(out) + "\n"


def build_mod(mod: Path, check: bool) -> bool:
    ok = True
    targets = []
    en_readme = read(mod / "README_EN.md")
    if en_readme is not None:
        targets.append((mod / "README.md", build_readme(en_readme, read(mod / "README_RU.md"))))
    en_log = read(mod / "changelog_EN.txt")
    if en_log is not None:
        targets.append((mod / "changelog.txt", merge_changelog(en_log, read(mod / "changelog_RU.txt"))))
    for path, content in targets:
        current = read(path)
        if current == content:
            continue
        if check:
            print(f"OUTDATED {path.relative_to(ROOT)}")
            ok = False
        else:
            path.write_text(content, encoding="utf-8", newline="\n")
            print(f"Built {path.relative_to(ROOT)}")
    return ok


def main(argv: list[str]) -> int:
    check = "--check" in argv
    names = [a for a in argv if not a.startswith("--")]
    if names:
        mods = [ROOT / n for n in names]
    else:
        mods = [p for p in sorted(ROOT.iterdir())
                if (p / "info.json").is_file() and ((p / "README_EN.md").is_file() or (p / "changelog_EN.txt").is_file())]
    ok = all([build_mod(m, check) for m in mods])
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
