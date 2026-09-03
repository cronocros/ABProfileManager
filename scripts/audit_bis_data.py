#!/usr/bin/env python3
"""
Audit ABProfileManager BIS datasets before a data refresh or restructuring pass.
"""

from __future__ import annotations

import re
import sys
from collections import Counter, defaultdict
from pathlib import Path
from typing import Dict, Iterable, List, Sequence, Tuple


REPO_ROOT = Path(__file__).resolve().parents[1]
OVERALL_FILE = REPO_ROOT / "ABProfileManager" / "Data" / "BISData_Method.lua"

SPEC_HEADER_RE = re.compile(r"^\s*\[(\d+)\]\s*=\s*\{\s*$")
OVERALL_ENTRY_RE = re.compile(
    r'\{\s*dungeon\s*=\s*(nil|"[^"]*"),\s*boss\s*=\s*(nil|"[^"]*"),\s*itemID\s*=\s*(\d+),'
    r'\s*slot\s*=\s*"([^"]+)",\s*note\s*=\s*"([^"]+)",\s*sourceType\s*=\s*"([^"]+)",'
    r'\s*sourceLabel\s*=\s*"([^"]+)"\s*\}'
)

KNOWN_VARIANT_GROUPS: Sequence[Tuple[str, ...]] = (
    ("공결점 제나스", "공결탑 제나스"),
    ("알게타르 대학", "알게타르 아카데미"),
)


def lua_string(value: str) -> str:
    if value == "nil":
        return ""
    return value[1:-1]


def parse_entries(path: Path, entry_re: re.Pattern[str]) -> Dict[int, List[Dict[str, object]]]:
    spec_entries: Dict[int, List[Dict[str, object]]] = {}
    current_spec: int | None = None

    for raw_line in path.read_text(encoding="utf-8").splitlines():
        header = SPEC_HEADER_RE.match(raw_line)
        if header:
            current_spec = int(header.group(1))
            spec_entries.setdefault(current_spec, [])
            continue

        if current_spec is None:
            continue

        entry = entry_re.search(raw_line)
        if not entry:
            continue

        groups = entry.groups()
        parsed = {
            "dungeon": lua_string(groups[0]),
            "boss": lua_string(groups[1]),
            "itemID": int(groups[2]),
            "slot": groups[3],
            "note": groups[4],
        }
        if len(groups) >= 7:
            parsed["sourceType"] = groups[5]
            parsed["sourceLabel"] = groups[6]

        spec_entries[current_spec].append(parsed)

    return spec_entries


def count_by(entries: Iterable[Dict[str, object]], key: str) -> Counter[str]:
    counts: Counter[str] = Counter()
    for entry in entries:
        value = str(entry.get(key) or "")
        if value:
            counts[value] += 1
    return counts


def flatten(spec_entries: Dict[int, List[Dict[str, object]]]) -> List[Dict[str, object]]:
    rows: List[Dict[str, object]] = []
    for entries in spec_entries.values():
        rows.extend(entries)
    return rows


def overall_mythicplus_slots(
    overall_entries: Dict[int, List[Dict[str, object]]]
) -> Dict[int, set[str]]:
    by_spec: Dict[int, set[str]] = defaultdict(set)
    for spec_id, entries in overall_entries.items():
        for entry in entries:
            if entry.get("sourceType") == "mythicplus" and entry.get("note") == "BIS":
                by_spec[spec_id].add(str(entry["slot"]))
    return by_spec


def variant_hits(names: Iterable[str]) -> List[Tuple[str, ...]]:
    present = set(names)
    hits: List[Tuple[str, ...]] = []
    for group in KNOWN_VARIANT_GROUPS:
        hit = tuple(name for name in group if name in present)
        if len(hit) > 1:
            hits.append(hit)
    return hits


def print_counter(title: str, counts: Counter[str]) -> None:
    print(title)
    for key, value in sorted(counts.items(), key=lambda item: (-item[1], item[0])):
        print(f"  {key}: {value}")


def main() -> int:
    overall_by_spec = parse_entries(OVERALL_FILE, OVERALL_ENTRY_RE)
    overall_rows = flatten(overall_by_spec)
    overall_dungeons = sorted(
        {str(entry["dungeon"]) for entry in overall_rows if entry.get("dungeon")}
    )
    overall_mplus_labels = sorted(
        {
            str(entry["sourceLabel"])
            for entry in overall_rows
            if entry.get("sourceType") == "mythicplus" and entry.get("sourceLabel")
        }
    )

    print("== Overall dataset ==")
    print(f"file: {OVERALL_FILE}")
    print(f"specs: {len(overall_by_spec)}")
    print(f"rows: {len(overall_rows)}")
    print_counter("source types:", count_by(overall_rows, "sourceType"))
    print_counter("slot counts:", count_by(overall_rows, "slot"))
    print()

    print("unique dungeons:")
    for name in overall_dungeons:
        print(f"  {name}")
    print()

    print("== Naming variants ==")
    hits = variant_hits(overall_dungeons)
    if hits:
        for hit in hits:
            print("  variant group present: " + " / ".join(hit))
    else:
        print("  no known variant groups detected")
    print()

    print("== Mythic+ source labels ==")
    for label in overall_mplus_labels:
        print(f"  {label}")

    if len(overall_by_spec) != 40:
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
