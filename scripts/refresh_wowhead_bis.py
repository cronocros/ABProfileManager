#!/usr/bin/env python3
"""
Refresh ABProfileManager/Data/BISData_Method.lua from Wowhead current Overall BiS pages.

This script only regenerates the `overallOverrides` block and keeps the legacy
fallback merge logic in BISData_Method.lua intact.
"""

from __future__ import annotations

import html
import json
import re
import sys
from pathlib import Path
from typing import Dict, Iterable, List, Optional, Sequence, Tuple

import requests


REPO_ROOT = Path(__file__).resolve().parents[1]
TARGET_FILE = REPO_ROOT / "ABProfileManager" / "Data" / "BISData_Method.lua"

HEADERS = {
    "Accept": (
        "text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,"
        "image/webp,image/apng,*/*;q=0.8"
    ),
    "Accept-Language": "ko,en-US;q=0.9,en;q=0.8",
    "Cache-Control": "max-age=0",
    "Sec-Ch-Ua": '"Chromium";v="135", "Not-A.Brand";v="8", "Google Chrome";v="135"',
    "Sec-Ch-Ua-Mobile": "?0",
    "Sec-Ch-Ua-Platform": '"Windows"',
    "Sec-Fetch-Dest": "document",
    "Sec-Fetch-Mode": "navigate",
    "Sec-Fetch-Site": "none",
    "Sec-Fetch-User": "?1",
    "Upgrade-Insecure-Requests": "1",
    "User-Agent": (
        "Mozilla/5.0 (Windows NT 10.0; Win64; x64) "
        "AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36"
    ),
}

SPECS: Sequence[Tuple[int, str]] = (
    (71, "https://www.wowhead.com/ko/guide/classes/warrior/arms/bis-gear"),
    (72, "https://www.wowhead.com/ko/guide/classes/warrior/fury/bis-gear"),
    (73, "https://www.wowhead.com/ko/guide/classes/warrior/protection/bis-gear"),
    (65, "https://www.wowhead.com/ko/guide/classes/paladin/holy/bis-gear"),
    (66, "https://www.wowhead.com/ko/guide/classes/paladin/protection/bis-gear"),
    (70, "https://www.wowhead.com/ko/guide/classes/paladin/retribution/bis-gear"),
    (253, "https://www.wowhead.com/ko/guide/classes/hunter/beast-mastery/bis-gear"),
    (254, "https://www.wowhead.com/ko/guide/classes/hunter/marksmanship/bis-gear"),
    (255, "https://www.wowhead.com/ko/guide/classes/hunter/survival/bis-gear"),
    (259, "https://www.wowhead.com/ko/guide/classes/rogue/assassination/bis-gear"),
    (260, "https://www.wowhead.com/ko/guide/classes/rogue/outlaw/bis-gear"),
    (261, "https://www.wowhead.com/ko/guide/classes/rogue/subtlety/bis-gear"),
    (256, "https://www.wowhead.com/ko/guide/classes/priest/discipline/bis-gear"),
    (257, "https://www.wowhead.com/ko/guide/classes/priest/holy/bis-gear"),
    (258, "https://www.wowhead.com/ko/guide/classes/priest/shadow/bis-gear"),
    (250, "https://www.wowhead.com/ko/guide/classes/death-knight/blood/bis-gear"),
    (251, "https://www.wowhead.com/ko/guide/classes/death-knight/frost/bis-gear"),
    (252, "https://www.wowhead.com/ko/guide/classes/death-knight/unholy/bis-gear"),
    (262, "https://www.wowhead.com/ko/guide/classes/shaman/elemental/bis-gear"),
    (263, "https://www.wowhead.com/ko/guide/classes/shaman/enhancement/bis-gear"),
    (264, "https://www.wowhead.com/ko/guide/classes/shaman/restoration/bis-gear"),
    (62, "https://www.wowhead.com/ko/guide/classes/mage/arcane/bis-gear"),
    (63, "https://www.wowhead.com/ko/guide/classes/mage/fire/bis-gear"),
    (64, "https://www.wowhead.com/ko/guide/classes/mage/frost/bis-gear"),
    (265, "https://www.wowhead.com/ko/guide/classes/warlock/affliction/bis-gear"),
    (266, "https://www.wowhead.com/ko/guide/classes/warlock/demonology/bis-gear"),
    (267, "https://www.wowhead.com/ko/guide/classes/warlock/destruction/bis-gear"),
    (268, "https://www.wowhead.com/ko/guide/classes/monk/brewmaster/bis-gear"),
    (269, "https://www.wowhead.com/ko/guide/classes/monk/windwalker/bis-gear"),
    (270, "https://www.wowhead.com/ko/guide/classes/monk/mistweaver/bis-gear"),
    (102, "https://www.wowhead.com/ko/guide/classes/druid/balance/bis-gear"),
    (103, "https://www.wowhead.com/ko/guide/classes/druid/feral/bis-gear"),
    (104, "https://www.wowhead.com/ko/guide/classes/druid/guardian/bis-gear"),
    (105, "https://www.wowhead.com/ko/guide/classes/druid/restoration/bis-gear"),
    (577, "https://www.wowhead.com/ko/guide/classes/demon-hunter/havoc/bis-gear"),
    (581, "https://www.wowhead.com/ko/guide/classes/demon-hunter/vengeance/bis-gear"),
    (1382, "https://www.wowhead.com/ko/guide/classes/demon-hunter/devourer/bis-gear"),
    (1467, "https://www.wowhead.com/ko/guide/classes/evoker/devastation/bis-gear"),
    (1468, "https://www.wowhead.com/ko/guide/classes/evoker/preservation/bis-gear"),
    (1473, "https://www.wowhead.com/ko/guide/classes/evoker/augmentation/bis-gear"),
)

SLOT_MAP = {
    "head": "머리",
    "helm": "머리",
    "neck": "목",
    "shoulder": "어깨",
    "shoulders": "어깨",
    "cloak": "망토",
    "cape": "망토",
    "chest": "가슴",
    "wrist": "손목",
    "bracers": "손목",
    "hands": "손",
    "gloves": "손",
    "belt": "허리",
    "waist": "허리",
    "legs": "다리",
    "feet": "발",
    "boots": "발",
    "ring": "반지",
    "ring1": "반지",
    "ring2": "반지",
    "ringset": "반지",
    "ringdefensive": "반지",
    "finger": "반지",
    "trinket": "장신구",
    "trinkets": "장신구",
    "trinket1": "장신구",
    "trinket2": "장신구",
    "trinketdamage": "장신구",
    "trinketdefense": "장신구",
    "alttrinket": "장신구",
    "weapon": "무기",
    "weapon2h": "무기",
    "weapon2h2": "무기",
    "weapon1h": "무기",
    "weapons1h": "무기",
    "mainhand": "무기",
    "mainhand2": "무기",
    "1hweapon": "무기",
    "2hweapon": "무기",
    "2hweapon2": "무기",
    "offhand": "보조장비",
    "offhand2": "보조장비",
    "offhand3": "보조장비",
    "shield": "방패",
}

SKILL_LABELS = {
    "164": "Blacksmithing",
    "165": "Leatherworking",
    "197": "Tailoring",
}

DUNGEON_LABELS = {
    "magistersterrace": "마법학자의 정원",
    "magisterterrace": "마법학자의 정원",
    "maisaracaverns": "마이사라 동굴",
    "nexuspointxenas": "공결탑 제나스",
    "nexuspoint": "공결탑 제나스",
    "windrunnerspire": "윈드러너 첨탑",
    "algetharacademy": "알게타르 대학",
    "algetharsacademy": "알게타르 대학",
    "algetharacademy2": "알게타르 대학",
    "seatofthetriumvirate": "삼두정의 권좌",
    "skyreach": "하늘탑",
    "pitofsaron": "사론의 구덩이",
}

SOURCE_NORMALIZATIONS = {
    "crafted": "Crafting",
    "craftingmisc": "Crafting",
    "thecatalyst": "Catalyst",
    "catalystraidvault": "Catalyst / Raid / Vault",
    "catalyst|raid|vault": "Catalyst / Raid / Vault",
    "raid|catalyst|vault": "Raid | Catalyst | Vault",
    "nexuspointxenas": "Nexus-Point Xenas",
    "magistersterrace": "Magisters' Terrace",
    "magisterterrace": "Magisters' Terrace",
    "salhadaar": "Fallen-King Salhadaar",
}

FILE_HEADER_RE = re.compile(
    r"-- .*?overall BIS dataset\n-- .*?\n-- authoritative current-season source for BISOverlay\.",
    re.S,
)


def normalize_key(text: str) -> str:
    return re.sub(r"[^a-z0-9]+", "", text.lower())


def strip_bbcode(text: str) -> str:
    stripped = re.sub(r"\[[^\]]+\]", "", text)
    stripped = html.unescape(stripped)
    stripped = stripped.replace("\\/", "/")
    stripped = stripped.replace("\\r", " ").replace("\\n", " ")
    stripped = stripped.replace("\r", " ").replace("\n", " ")
    stripped = re.sub(r"\s+", " ", stripped)
    return stripped.strip(" |/")


def normalize_slot(raw_slot: str) -> str:
    cleaned = strip_bbcode(raw_slot)
    key = normalize_key(cleaned)
    if key not in SLOT_MAP:
        raise ValueError(f"Unknown slot label: {cleaned!r}")
    return SLOT_MAP[key]


def normalize_source_label(raw_cell: str) -> str:
    skill_ids = re.findall(r"\[skill=(\d+)\]", raw_cell)
    text = strip_bbcode(raw_cell)

    if not text and skill_ids:
        return SKILL_LABELS.get(skill_ids[0], "Crafting")

    text = text.replace("|", " | ")
    text = re.sub(r"\s+\|\s+", " | ", text)
    text = re.sub(r"\s*/\s*", " / ", text)
    text = re.sub(r"\s+", " ", text).strip(" |/")
    text = re.sub(r"\(([^)]+)\)", r" / \1", text)
    text = re.sub(r"\s+", " ", text).strip(" |/")
    text = text.replace(" or Crafted", " / Crafting")
    text = text.replace(" or crafted", " / Crafting")
    text = text.replace("The Catalyst", "Catalyst")
    text = text.replace("Crafting / Misc", "Crafting")
    text = text.replace("Crafting/Misc", "Crafting")
    text = text.replace("Nexus Point Xenas", "Nexus-Point Xenas")
    text = text.replace("Magister's Terrace", "Magisters' Terrace")
    text = text.replace("Catalyst | Raid | Vault", "Catalyst / Raid / Vault")
    text = text.replace("Catalyst|Raid|Vault", "Catalyst / Raid / Vault")
    text = text.replace("Raid / Catalyst / Vault", "Raid | Catalyst | Vault")
    text = re.sub(r"\s+", " ", text).strip(" |/")
    text = normalize_mixed_source_modes(text)

    normalized = SOURCE_NORMALIZATIONS.get(normalize_key(text))
    if normalized:
        return normalized

    return text or "Crafting"


def find_mythicplus_dungeon(source_label: str) -> Optional[str]:
    normalized = normalize_key(source_label)
    matches: List[Tuple[int, str]] = []
    for alias_key, dungeon_name in DUNGEON_LABELS.items():
        if alias_key in normalized:
            matches.append((normalized.find(alias_key), dungeon_name))
    if not matches:
        return None
    matches.sort(key=lambda item: item[0])
    return matches[0][1]


def is_crafted_source(source_label: str) -> bool:
    return normalize_key(source_label) in {
        "crafting",
        "blacksmithing",
        "leatherworking",
        "tailoring",
        "engineering",
        "jewelcrafting",
        "alchemy",
        "enchanting",
        "inscription",
    }


def is_raid_meta_part(source_label: str) -> bool:
    return normalize_key(source_label) in {
        "raid",
        "vault",
        "catalyst",
        "tier",
        "tierset",
        "tieritem",
    }


def classify_source_part(source_label: str) -> str:
    if find_mythicplus_dungeon(source_label):
        return "mythicplus"
    if is_crafted_source(source_label):
        return "crafted"
    return "raid"


def normalize_mixed_source_modes(source_label: str) -> str:
    parts = [part.strip() for part in re.split(r"\s*(?:\||/)\s*", source_label) if part.strip()]
    if len(parts) < 2:
        return source_label

    concrete_parts = [part for part in parts if not is_raid_meta_part(part)]
    if concrete_parts and len(concrete_parts) < len(parts):
        return " / ".join(concrete_parts)

    part_modes = [classify_source_part(part) for part in parts]
    has_crafted = any(mode == "crafted" for mode in part_modes)
    has_non_crafted = any(mode != "crafted" for mode in part_modes)
    if has_crafted and has_non_crafted:
        kept_parts = [part for part, mode in zip(parts, part_modes) if mode != "crafted"]
        return " / ".join(kept_parts)

    return source_label


def classify_source(source_label: str) -> Tuple[str, Optional[str]]:
    dungeon_name = find_mythicplus_dungeon(source_label)
    if dungeon_name:
        return "mythicplus", dungeon_name
    if is_crafted_source(source_label):
        return "crafted", None
    return "raid", None


def parse_gatherer_data(html_text: str) -> Dict[str, Dict[str, object]]:
    match = re.search(r"WH\.Gatherer\.addData\(3, 1, (\{.*?\})\);", html_text, re.S)
    if not match:
        raise ValueError("WH.Gatherer.addData payload not found")
    return json.loads(match.group(1))


def extract_overall_segment(html_text: str) -> str:
    start = html_text.find("name=bis_items")
    if start == -1:
        raise ValueError("bis_items section not found")
    end = html_text.find("[\\/tab]", start)
    if end == -1:
        end = start + 50000
    return html_text[start:end]


def extract_rows(segment: str) -> Iterable[str]:
    return re.findall(r"\[tr\](.*?)\[\\/tr\]", segment, re.S)


def extract_source_options(raw_cell: str) -> List[str]:
    linked_options = [
        normalize_source_label(option)
        for option in re.findall(r"\[url [^\]]+\](.*?)\[\\/url\]", raw_cell, re.S)
        if strip_bbcode(option)
    ]
    if len(linked_options) > 1:
        return linked_options

    plain_text = strip_bbcode(raw_cell)
    split_options = [part.strip() for part in re.split(r"\s+or\s+", plain_text, flags=re.I) if part.strip()]
    if len(split_options) > 1:
        return [normalize_source_label(option) for option in split_options]

    return [normalize_source_label(raw_cell)]


def extract_item_ids(item_cell: str, source_option_count: int) -> List[int]:
    item_ids: List[int] = []
    seen = set()
    for match in re.finditer(r"\[item=(\d+)", item_cell):
        item_id = int(match.group(1))
        if item_id in seen:
            continue
        seen.add(item_id)
        item_ids.append(item_id)

    if len(item_ids) <= 1:
        return item_ids
    if source_option_count > 1 and source_option_count == len(item_ids):
        return item_ids
    return item_ids[:1]


def parse_page(spec_id: int, url: str) -> Tuple[List[Dict[str, object]], Optional[str]]:
    response = requests.get(url, headers=HEADERS, timeout=30)
    response.raise_for_status()
    html_text = response.text

    meta_match = re.search(r'<script type="application/ld\+json">(.*?)</script>', html_text, re.S)
    modified = None
    if meta_match:
        try:
            modified = json.loads(meta_match.group(1)).get("dateModified")
        except json.JSONDecodeError:
            modified = None

    gatherer_data = parse_gatherer_data(html_text)
    segment = extract_overall_segment(html_text)

    entries: List[Dict[str, object]] = []
    for row in extract_rows(segment):
        if "[item=" not in row:
            continue

        cells = re.findall(r"\[td(?: [^\]]*)?\](.*?)\[\\/td\]", row, re.S)
        item_index = next((index for index, cell in enumerate(cells) if "[item=" in cell), None)
        if item_index is None or item_index == 0 or item_index + 1 >= len(cells):
            continue

        source_options = extract_source_options(cells[item_index + 1])
        item_ids = extract_item_ids(cells[item_index], len(source_options))
        if not item_ids:
            continue

        slot_name = normalize_slot(cells[0])
        for index, item_id in enumerate(item_ids):
            source_label = source_options[min(index, len(source_options) - 1)]
            source_type, dungeon_name = classify_source(source_label)

            entries.append(
                {
                    "specID": spec_id,
                    "slot": slot_name,
                    "itemID": item_id,
                    "itemName": gatherer_data.get(str(item_id), {}).get("name_kokr")
                    or gatherer_data.get(str(item_id), {}).get("name"),
                    "note": "BIS",
                    "sourceType": source_type,
                    "sourceLabel": source_label,
                    "dungeon": dungeon_name,
                }
            )

    if not entries:
        raise ValueError(f"No BIS rows parsed for spec {spec_id}")

    return entries, modified


def lua_string(value: str) -> str:
    escaped = value.replace("\\", "\\\\").replace('"', '\\"')
    return f'"{escaped}"'


def render_entry(entry: Dict[str, object]) -> str:
    dungeon_value = "nil" if entry["dungeon"] is None else lua_string(str(entry["dungeon"]))
    return (
        "        { dungeon = "
        f"{dungeon_value}, boss = nil, itemID = {entry['itemID']}, "
        f"slot = {lua_string(str(entry['slot']))}, note = \"BIS\", "
        f"sourceType = {lua_string(str(entry['sourceType']))}, "
        f"sourceLabel = {lua_string(str(entry['sourceLabel']))} }},"
    )


def render_overrides(overrides: Dict[int, List[Dict[str, object]]]) -> str:
    lines = ["local overallOverrides = {"]
    for spec_id in sorted(overrides):
        lines.append(f"    [{spec_id}] = {{")
        for entry in overrides[spec_id]:
            lines.append(render_entry(entry))
        lines.append("    },")
    lines.append("}")
    return "\n".join(lines)


def update_target_file(rendered_overrides: str) -> None:
    original = TARGET_FILE.read_text(encoding="utf-8")
    start = original.index("local overallOverrides = {")
    end = original.index("\n\nfor specID, overallItems in pairs(overallOverrides) do")

    header = FILE_HEADER_RE.sub(
        "-- Wowhead Midnight Season 1 overall BIS dataset\n"
        "-- Generated from Wowhead current Overall BiS guides. This file is treated as the\n"
        "-- authoritative current-season source for BISOverlay.",
        original[:start],
        count=1,
    )
    updated = header + rendered_overrides + original[end:]
    TARGET_FILE.write_text(updated, encoding="utf-8")


def validate(overrides: Dict[int, List[Dict[str, object]]], total_rows: int) -> None:
    if len(overrides) != len(SPECS):
        raise ValueError(f"Expected {len(SPECS)} specs, got {len(overrides)}")
    if 262 not in overrides:
        raise ValueError("Elemental Shaman (262) is missing")
    if 1382 not in overrides:
        raise ValueError("Devourer Demon Hunter (1382) is missing")
    if total_rows < 600:
        raise ValueError(f"Unexpectedly low row count: {total_rows}")

    representative_counts = {
        269: 17,
        270: 16,
        263: 16,
        577: 16,
        1382: 16,
        1473: 16,
    }
    for spec_id, expected_count in representative_counts.items():
        actual_count = len(overrides[spec_id])
        if actual_count != expected_count:
            raise ValueError(
                f"Representative spec {spec_id} expected {expected_count} entries, got {actual_count}"
            )

    expected = {
        ("머리", 250015, "raid", "Tier Set"),
        ("목", 250247, "raid", "Midnight Falls"),
        ("허리", 251082, "mythicplus", "Windrunner Spire"),
        ("장신구", 249343, "raid", "Chimaerus"),
        ("장신구", 193701, "mythicplus", "Algeth'ar Academy"),
    }
    actual = {
        (str(entry["slot"]), int(entry["itemID"]), str(entry["sourceType"]), str(entry["sourceLabel"]))
        for entry in overrides[269]
    }
    missing = expected - actual
    if missing:
        raise ValueError(f"Windwalker validation failed: missing {sorted(missing)!r}")

    crafted_markers = ("Crafting", "Blacksmithing", "Leatherworking", "Tailoring")
    for spec_id, entries in overrides.items():
        for entry in entries:
            source_type = str(entry["sourceType"])
            source_label = str(entry["sourceLabel"])
            if source_type == "crafted":
                continue
            if any(normalize_key(marker) in normalize_key(source_label) for marker in crafted_markers):
                raise ValueError(
                    "Mixed crafting label left in non-crafted entry: "
                    f"spec {spec_id}, item {entry['itemID']}, label {source_label!r}"
                )
            if source_type == "raid" and " / Raid" in source_label:
                raise ValueError(
                    "Raid meta suffix left in raid entry: "
                    f"spec {spec_id}, item {entry['itemID']}, label {source_label!r}"
                )


def main() -> int:
    overrides: Dict[int, List[Dict[str, object]]] = {}
    modified_dates: Dict[int, Optional[str]] = {}
    total_rows = 0

    for spec_id, url in SPECS:
        rows, modified = parse_page(spec_id, url)
        overrides[spec_id] = rows
        modified_dates[spec_id] = modified
        total_rows += len(rows)

    validate(overrides, total_rows)
    update_target_file(render_overrides(overrides))

    print(f"Updated {TARGET_FILE}")
    print(f"Specs: {len(overrides)}")
    print(f"Rows: {total_rows}")
    print(
        "Modified dates: "
        + ", ".join(
            f"{spec_id}={modified_dates[spec_id].split('T')[0] if modified_dates[spec_id] else '?'}"
            for spec_id, _ in SPECS
        )
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
