#!/usr/bin/env python3
"""
Refresh ABProfileManager/Data/BISData.lua from Wowhead Mythic+ gear sections.

Policy:
- Keep existing manual fallback entries as the seed dataset.
- Only add Mythic+ candidates for slots whose current Overall BiS is not Mythic+.
- Prefer Wowhead "Best Gear from Mythic+" candidates and resolve slot/source from
  the individual item pages.
"""

from __future__ import annotations

import json
import re
import sys
from pathlib import Path
from typing import Dict, Iterable, List, Optional, Sequence, Tuple

import requests

import refresh_wowhead_bis as overall


REPO_ROOT = Path(__file__).resolve().parents[1]
TARGET_FILE = REPO_ROOT / "ABProfileManager" / "Data" / "BISData.lua"
LEGACY_NOTE_ORDER = {"BIS": 0, "대체재": 1, "2순위": 2, "3순위": 3}
SLOT_ORDER = {
    "무기": 0,
    "보조장비": 1,
    "방패": 2,
    "머리": 3,
    "목": 4,
    "어깨": 5,
    "망토": 6,
    "가슴": 7,
    "손목": 8,
    "손": 9,
    "허리": 10,
    "다리": 11,
    "발": 12,
    "반지": 13,
    "장신구": 14,
}
ZONE_ID_TO_DUNGEON = {
    16573: "공결탑 제나스",
    15808: "윈드러너 첨탑",
    14032: "알게타르 대학",
    8910: "삼두정의 권좌",
    15829: "마법학자의 정원",
    16395: "마이사라 동굴",
    6988: "하늘탑",
    4813: "사론의 구덩이",
}
ITEM_LINE_RE = re.compile(
    r'\{\s*dungeon\s*=\s*"([^"]*)",\s*boss\s*=\s*(nil|"[^"]*"),\s*itemID\s*=\s*(\d+),\s*slot\s*=\s*"([^"]*)",\s*note\s*=\s*"([^"]*)"\s*\}'
)
SPEC_HEADER_RE = re.compile(r"^\s*\[(\d+)\]\s*=\s*\{\s*$")
MYTHIC_SECTION_RE = re.compile(
    r"Best Gear from Mythic\+.*?\[table[^\]]*\](.*?)\[\\/table\]",
    re.S,
)
ITEM_DATA_RE_TEMPLATE = r"\$\.extend\(g_items\[%d\], (\{.*?\})\);"
ARMOR_SLOT_MAP = {
    1: "머리",
    2: "목",
    3: "어깨",
    5: "가슴",
    6: "허리",
    7: "다리",
    8: "발",
    9: "손목",
    10: "손",
    11: "반지",
    12: "장신구",
    15: "망토",
    16: "망토",
    23: "보조장비",
}


def parse_existing_entries(path: Path) -> Tuple[Dict[int, List[Dict[str, object]]], Dict[int, Dict[str, object]]]:
    by_spec: Dict[int, List[Dict[str, object]]] = {}
    seed_by_item: Dict[int, Dict[str, object]] = {}
    current_spec: Optional[int] = None

    for raw_line in path.read_text(encoding="utf-8").splitlines():
        spec_match = SPEC_HEADER_RE.match(raw_line)
        if spec_match:
            current_spec = int(spec_match.group(1))
            by_spec[current_spec] = []
            continue

        if current_spec is None:
            continue

        item_match = ITEM_LINE_RE.search(raw_line)
        if not item_match:
            if raw_line.strip() == "},":
                current_spec = None
            continue

        dungeon, boss_raw, item_id_raw, slot, note = item_match.groups()
        boss = None if boss_raw == "nil" else boss_raw.strip('"')
        item_id = int(item_id_raw)
        entry = {
            "dungeon": dungeon,
            "boss": boss,
            "itemID": item_id,
            "slot": slot,
            "note": note,
        }
        by_spec[current_spec].append(entry)
        seed_by_item.setdefault(item_id, entry)

    return by_spec, seed_by_item


def extract_mythic_candidates(html_text: str) -> List[int]:
    match = MYTHIC_SECTION_RE.search(html_text)
    if not match:
        return []

    section = match.group(1)
    item_ids = [int(value) for value in re.findall(r"\[icon-badge=(\d+)", section)]
    if not item_ids:
        item_ids = [int(value) for value in re.findall(r"\[item=(\d+)", section)]

    seen = set()
    ordered: List[int] = []
    for item_id in item_ids:
        if item_id in seen:
            continue
        seen.add(item_id)
        ordered.append(item_id)
    return ordered


def resolve_slot_from_item(data: Dict[str, object]) -> Optional[str]:
    class_id = int(data.get("classs") or 0)
    subclass = int(data.get("subclass") or 0)
    slot_code = int(data.get("slot") or data.get("slotbak") or 0)

    if class_id == 2:
        return "무기"

    if slot_code == 14:
        if class_id == 4 and subclass == 6:
            return "방패"
        return "보조장비"

    return ARMOR_SLOT_MAP.get(slot_code)


def fetch_item_metadata(
    session: requests.Session,
    item_id: int,
    seed_entry: Optional[Dict[str, object]],
) -> Optional[Dict[str, object]]:
    if seed_entry:
        return {
            "itemID": item_id,
            "slot": seed_entry.get("slot"),
            "dungeon": seed_entry.get("dungeon"),
            "boss": seed_entry.get("boss"),
        }

    response = session.get(f"https://www.wowhead.com/item={item_id}", headers=overall.HEADERS, timeout=30)
    response.raise_for_status()

    match = re.search(ITEM_DATA_RE_TEMPLATE % item_id, response.text, re.S)
    if not match:
        return None

    data = json.loads(match.group(1))
    slot = resolve_slot_from_item(data)
    if not slot:
        return None

    dungeon = None
    boss = None
    for source_entry in data.get("sourcemore") or []:
        if not isinstance(source_entry, dict):
            continue
        zone_id = source_entry.get("z")
        if zone_id in ZONE_ID_TO_DUNGEON:
            dungeon = ZONE_ID_TO_DUNGEON[zone_id]
            boss = source_entry.get("n") or boss
            break

    if not dungeon:
        return None

    return {
        "itemID": item_id,
        "slot": slot,
        "dungeon": dungeon,
        "boss": boss,
    }


def sort_entries(entries: Iterable[Dict[str, object]]) -> List[Dict[str, object]]:
    return sorted(
        entries,
        key=lambda entry: (
            SLOT_ORDER.get(str(entry.get("slot") or ""), 999),
            LEGACY_NOTE_ORDER.get(str(entry.get("note") or ""), 99),
            str(entry.get("dungeon") or ""),
            int(entry.get("itemID") or 0),
        ),
    )


def lua_string(value: Optional[str]) -> str:
    if value is None:
        return "nil"
    return overall.lua_string(str(value))


def render_entry(entry: Dict[str, object]) -> str:
    return (
        "        { dungeon = "
        f"{lua_string(entry.get('dungeon'))}, boss = {lua_string(entry.get('boss'))}, "
        f"itemID = {int(entry['itemID'])}, slot = {overall.lua_string(str(entry['slot']))}, "
        f"note = {overall.lua_string(str(entry.get('note') or 'BIS'))} }},"
    )


def render_file(spec_entries: Dict[int, List[Dict[str, object]]]) -> str:
    lines = [
        "local _, ns = ...",
        "",
        "-- Wowhead Midnight Season 1 Mythic+ fallback dataset",
        "-- Generated from current Wowhead guide Mythic+ recommendations plus existing",
        "-- manual fallback entries. These rows are merged behind Overall BiS entries.",
        "",
        "ns.Data = ns.Data or {}",
        "ns.Data.BISItems = {",
        "",
    ]

    for spec_id in sorted(spec_entries):
        lines.append(f"    [{spec_id}] = {{")
        for entry in sort_entries(spec_entries[spec_id]):
            lines.append(render_entry(entry))
        lines.append("    },")
        lines.append("")

    lines.append("}")
    lines.append("")
    return "\n".join(lines)


def main() -> int:
    existing_entries, seed_by_item = parse_existing_entries(TARGET_FILE)
    overall_by_spec: Dict[int, List[Dict[str, object]]] = {}
    updated_entries = {spec_id: list(entries) for spec_id, entries in existing_entries.items()}
    session = requests.Session()
    added_rows = 0
    added_slots = 0

    for spec_id, url in overall.SPECS:
        overall_rows, _ = overall.parse_page(spec_id, url)
        overall_by_spec[spec_id] = overall_rows

        blocked_slots = {
            str(entry["slot"])
            for entry in overall_rows
            if str(entry.get("sourceType")) == "mythicplus"
        }
        target_slots = {
            str(entry["slot"])
            for entry in overall_rows
            if str(entry["slot"]) not in blocked_slots
        }
        covered_slots = {
            str(entry.get("slot"))
            for entry in updated_entries.get(spec_id, [])
            if str(entry.get("slot")) in target_slots
        }

        response = session.get(url, headers=overall.HEADERS, timeout=30)
        response.raise_for_status()
        candidates = extract_mythic_candidates(response.text)
        if not candidates:
            continue

        seen_keys = {
            (str(entry.get("slot") or ""), int(entry.get("itemID") or 0))
            for entry in updated_entries.get(spec_id, [])
        }

        for item_id in candidates:
            metadata = fetch_item_metadata(session, item_id, seed_by_item.get(item_id))
            if not metadata:
                continue

            slot = str(metadata["slot"])
            if slot not in target_slots:
                continue

            entry_key = (slot, item_id)
            if entry_key in seen_keys:
                covered_slots.add(slot)
                continue

            updated_entries.setdefault(spec_id, []).append(
                {
                    "dungeon": metadata.get("dungeon"),
                    "boss": metadata.get("boss"),
                    "itemID": item_id,
                    "slot": slot,
                    "note": "BIS",
                }
            )
            seen_keys.add(entry_key)
            if slot not in covered_slots:
                covered_slots.add(slot)
                added_slots += 1
            added_rows += 1

    rendered = render_file(updated_entries)
    TARGET_FILE.write_text(rendered, encoding="utf-8")

    total_specs = len(updated_entries)
    if total_specs != 39:
        raise ValueError(f"Expected 39 specs in fallback file, got {total_specs}")

    print(f"Updated {TARGET_FILE}")
    print(f"Specs: {total_specs}")
    print(f"Added rows: {added_rows}")
    print(f"Added slot coverage: {added_slots}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
