#!/usr/bin/env python3
"""
Sync the DOC BIS seed files with the current generated BIS overlay catalog and
inject stable itemID annotations without breaking the build pipeline.
"""

from __future__ import annotations

import argparse
import re
from collections import defaultdict
from pathlib import Path
from typing import DefaultDict, Dict, List, Optional

import build_bis_catalog as build


CATALOG_FILE = build.TARGET_FILE
FINAL_DOC_FILE = build.DOC_FINAL_FILE
COMPANION_DOC_FILE = build.DOC_COMPANION_FILE

CATALOG_SPEC_RE = re.compile(r"^\s*\[(\d+)\]\s*=\s*\{\s*$")
CATALOG_ENTRY_RE = re.compile(
    r'\{\s*slot = "([^"]+)", itemID = (\d+), nameKoKR = "((?:\\.|[^"])*)", '
    r'nameEnUS = "((?:\\.|[^"])*)".*?sourceGroup = "([^"]+)",'
)
FINAL_ITEM_LINE_RE = re.compile(
    r"^- (?:(itemID:\s*[\d\s/]+)\s*[-—]\s*)?([^*]*?)\*\*([^*]+)\*\*"
    r"(?:\s*/\s*\*\*([^*]+)\*\*)?\s*[-—]\s*(.+)$"
)
FINAL_TIER_LINE_RE = re.compile(
    r"^- ([^:]+):\s*\*\*([^*]+)\*\*(?:\s*[-—]\s*itemID:\s*\d+)?$"
)
COMPANION_LINE_RE = re.compile(
    r"^- \*\*([^*]+)\*\* \(([^)]+)\)(?:\s*[-—]\s*itemID:\s*\d+)?$"
)

TIER_SLOT_ALIASES = {
    "Head": "머리",
    "Shoulder": "어깨",
    "Shoulders": "어깨",
    "Chest": "가슴",
    "Hands": "손",
    "Gloves": "손",
    "Waist": "허리",
    "Legs": "다리",
    "Feet": "발",
    "Boots": "발",
    "Back": "망토",
    "Neck": "목",
    "Ring": "반지",
    "Trinket": "장신구",
    "Weapon": "무기",
    "Off-Hand": "보조장비",
    "Off Hand": "보조장비",
    "Shield": "방패",
}

COMPANION_NAME_ALIASES = {
    "그림자베기 절단도": "Shadowslash Slicer",
}

FINAL_INTRO_LINES = [
    "# WoW Midnight 시즌 1 — 전 클래스 쐐기(Mythic+) 파밍 최종 정리본",
    "",
    "기준일: 2026-04-18",
    "기준: **Midnight 시즌 1 / Mythic+ 기준**",
    "참고: 이 문서는 **현재 BIS 오버레이 카탈로그(`ABProfileManager/Data/BISCatalog.lua`)와 동기화된 정리본**이다.",
    "",
    "> 문서 내 `itemID`는 현재 BIS 오버레이 카탈로그와 동일한 식별값이다.",
    "> 아이템명은 **영문 원문 기준**, 던전명은 **한글(영문)** 병기 기준으로 유지했다.",
    "",
    "## 공통 기준",
    "- 시즌 1 Mythic+ 던전 풀은 다음 8개다: **마법학자의 정원(Magisters' Terrace)**, **마이사라 동굴(Maisara Caverns)**, **제나스 지점(Nexus-Point Xenas)**, **윈드러너 첨탑(Windrunner Spire)**, **알게타르 대학(Algeth'ar Academy)**, **삼두정의 권좌(Seat of the Triumvirate)**, **하늘탑(Skyreach)**, **사론의 구덩이(Pit of Saron)**.",
    "- 아래 목록은 **현재 BIS 오버레이 카탈로그 기준**으로 정리했으며, itemID와 현지화명 검증은 생성 파이프라인에서 **Retail DB2(Wago DB2, 12.0.1 계열)** 기준으로 맞춘다.",
    "- `itemID`는 각 항목의 현재 오버레이 row와 동일한 값을 문서에 직접 표기했다.",
    "- 슬롯명은 한글로 유지하고, 아이템명은 오역을 피하기 위해 영문 원문 기준으로 유지한다.",
    "",
    "---",
    "",
]

COMPANION_INTRO_LINES = [
    "# WoW Midnight 시즌 1 — 아이템 한글명 보조판",
    "",
    "기준일: 2026-04-18",
    "기준: **wow_midnight_s1_mplus_bis_final.md**와 현재 BIS 오버레이 카탈로그를 기준으로 정리한 **한글명 보조판**",
    "주의: 이 문서는 **현재 오버레이 카탈로그의 koKR / enUS / itemID 기준값**을 함께 싣는다. 최종 식별은 반드시 **itemID + 영문 원문**을 기준으로 한다.",
    "",
    "## 아이템 한글명 매핑",
    "",
]


def unlua_string(value: str) -> str:
    return value.replace(r"\\", "\\").replace(r"\"", '"')


def parse_catalog(path: Path) -> Dict[int, List[Dict[str, object]]]:
    catalog: Dict[int, List[Dict[str, object]]] = {}
    current_spec: Optional[int] = None

    for raw_line in path.read_text(encoding="utf-8").splitlines():
        spec_match = CATALOG_SPEC_RE.match(raw_line)
        if spec_match:
            current_spec = int(spec_match.group(1))
            catalog.setdefault(current_spec, [])
            continue

        entry_match = CATALOG_ENTRY_RE.search(raw_line)
        if not entry_match or current_spec is None:
            continue

        slot, item_id, name_ko, name_en, source_group = entry_match.groups()
        catalog[current_spec].append(
            {
                "specID": current_spec,
                "slot": slot,
                "itemID": int(item_id),
                "nameKoKR": unlua_string(name_ko),
                "nameEnUS": unlua_string(name_en),
                "sourceGroup": source_group,
            }
        )

    if not catalog:
        raise ValueError(f"Catalog parse failed: {path}")
    return catalog


def build_catalog_indices(
    catalog: Dict[int, List[Dict[str, object]]]
) -> tuple[Dict[int, Dict[str, List[Dict[str, object]]]], Dict[str, List[Dict[str, object]]]]:
    by_spec: Dict[int, Dict[str, List[Dict[str, object]]]] = {}
    global_index: DefaultDict[str, List[Dict[str, object]]] = defaultdict(list)

    for spec_id, rows in catalog.items():
        spec_index: DefaultDict[str, List[Dict[str, object]]] = defaultdict(list)
        for row in rows:
            en_key = build.normalize_key(
                build.DOC_ITEM_NAME_ALIASES.get(
                    build.normalize_key(str(row["nameEnUS"])),
                    str(row["nameEnUS"]),
                )
            )
            ko_key = build.normalize_key(str(row["nameKoKR"]))
            spec_index[en_key].append(row)
            global_index[en_key].append(row)
            if ko_key:
                spec_index[ko_key].append(row)
                global_index[ko_key].append(row)
        by_spec[spec_id] = dict(spec_index)
    return by_spec, dict(global_index)


def choose_entry(
    candidates: List[Dict[str, object]],
    *,
    slot_hint: Optional[str] = None,
    source_group_hint: Optional[str] = None,
) -> Optional[Dict[str, object]]:
    filtered = list(candidates)
    if slot_hint:
        slot_matches = [entry for entry in filtered if str(entry["slot"]) == slot_hint]
        if slot_matches:
            filtered = slot_matches
    if source_group_hint:
        source_matches = [entry for entry in filtered if str(entry["sourceGroup"]) == source_group_hint]
        if source_matches:
            filtered = source_matches
    if not filtered:
        return None
    filtered.sort(
        key=lambda entry: (
            build.SOURCE_GROUP_ORDER.get(str(entry["sourceGroup"]), 99),
            int(entry["itemID"]),
        )
    )
    return filtered[0]


def resolve_catalog_entry(
    spec_id: int,
    item_name: str,
    by_spec: Dict[int, Dict[str, List[Dict[str, object]]]],
    global_index: Dict[str, List[Dict[str, object]]],
    *,
    slot_hint: Optional[str] = None,
    source_group_hint: Optional[str] = None,
) -> Dict[str, object]:
    raw_key = build.normalize_key(item_name)
    item_key = build.normalize_key(build.DOC_ITEM_NAME_ALIASES.get(raw_key, item_name))

    candidates = list((by_spec.get(spec_id) or {}).get(item_key) or [])
    entry = choose_entry(candidates, slot_hint=slot_hint, source_group_hint=source_group_hint)
    if entry:
        return entry

    candidates = list(global_index.get(item_key) or [])
    entry = choose_entry(candidates, slot_hint=slot_hint, source_group_hint=source_group_hint)
    if entry:
        return entry

    raise ValueError(f"Catalog entry not found for spec {spec_id}, item {item_name!r}")


def replace_intro(
    lines: List[str],
    heading: str,
    intro_lines: List[str],
    *,
    keep_heading: bool = True,
) -> List[str]:
    try:
        start = lines.index(heading)
    except ValueError as exc:
        raise ValueError(f"Heading not found: {heading!r}") from exc
    tail_start = start if keep_heading else start + 1
    return intro_lines + lines[tail_start:]


def sync_final_doc(
    lines: List[str],
    by_spec: Dict[int, Dict[str, List[Dict[str, object]]]],
    global_index: Dict[str, List[Dict[str, object]]],
) -> tuple[List[str], int]:
    updated = replace_intro(lines, "## 1) 풍운 수도사 (Windwalker Monk)", FINAL_INTRO_LINES)
    current_spec: Optional[int] = None
    current_heading: Optional[str] = None
    updated_rows = 0

    for idx, raw_line in enumerate(updated):
        line = raw_line.rstrip()

        spec_match = build.DOC_SPEC_RE.match(line)
        if spec_match:
            current_spec = build.DOC_SECTION_SPEC_IDS.get(int(spec_match.group(1)))
            current_heading = None
            continue

        slot_match = build.DOC_SLOT_RE.match(line)
        if slot_match:
            current_heading = build.clean_markdown(slot_match.group(1))
            if current_heading == "우선 파밍 인던":
                current_heading = None
            continue

        if current_spec is None or current_heading is None:
            continue

        if build.SLOT_HINTS.get(current_heading) == "TIER":
            tier_match = FINAL_TIER_LINE_RE.match(line.strip())
            if not tier_match:
                continue
            slot_prefix, item_name = tier_match.groups()
            normalized_slot = build.clean_markdown(slot_prefix)
            normalized_slot = TIER_SLOT_ALIASES.get(normalized_slot, normalized_slot)
            slot_hint = build.DOC_SLOT_PREFIXES.get(normalized_slot)
            entry = resolve_catalog_entry(
                current_spec,
                item_name,
                by_spec,
                global_index,
                slot_hint=slot_hint,
                source_group_hint="tier",
            )
            updated[idx] = f"- {normalized_slot}: **{entry['nameEnUS']}** — itemID: {entry['itemID']}"
            updated_rows += 1
            continue

        item_match = FINAL_ITEM_LINE_RE.match(line.strip())
        if not item_match:
            continue

        _, prefix, first_item, second_item, raw_source = item_match.groups()
        source_text = build.clean_markdown(raw_source)
        source_group_hint = build.classify_doc_source(source_text)
        slot_hint = build.SLOT_HINTS.get(current_heading)
        prefix_text = prefix or ""

        first_entry = resolve_catalog_entry(
            current_spec,
            first_item,
            by_spec,
            global_index,
            slot_hint=slot_hint,
            source_group_hint=source_group_hint,
        )

        if second_item:
            second_entry = resolve_catalog_entry(
                current_spec,
                second_item,
                by_spec,
                global_index,
                slot_hint=slot_hint,
                source_group_hint=source_group_hint,
            )
            updated[idx] = (
                f"- itemID: {first_entry['itemID']} / {second_entry['itemID']} — "
                f"{prefix_text}**{first_entry['nameEnUS']}** / **{second_entry['nameEnUS']}** — {raw_source}"
            )
        else:
            updated[idx] = (
                f"- itemID: {first_entry['itemID']} — "
                f"{prefix_text}**{first_entry['nameEnUS']}** — {raw_source}"
            )
        updated_rows += 1

    return updated, updated_rows


def sync_companion_doc(
    lines: List[str],
    global_index: Dict[str, List[Dict[str, object]]],
) -> tuple[List[str], int]:
    updated = replace_intro(
        lines,
        "## 아이템 한글명 매핑",
        COMPANION_INTRO_LINES,
        keep_heading=False,
    )
    result: List[str] = []
    updated_rows = 0
    seen_mapping_heading = False

    for raw_line in updated:
        if raw_line.strip() == "## 아이템 한글명 매핑":
            if seen_mapping_heading:
                continue
            seen_mapping_heading = True
        match = COMPANION_LINE_RE.match(raw_line.strip())
        if not match:
            result.append(raw_line)
            continue
        ko_name, en_name = match.groups()
        alias_name = COMPANION_NAME_ALIASES.get(en_name) or COMPANION_NAME_ALIASES.get(ko_name)
        resolved_name = alias_name or en_name
        item_key = build.normalize_key(
            build.DOC_ITEM_NAME_ALIASES.get(build.normalize_key(resolved_name), resolved_name)
        )
        candidates = list(global_index.get(item_key) or [])
        if not candidates:
            candidates = list(global_index.get(build.normalize_key(ko_name)) or [])
        entry = choose_entry(candidates)
        if not entry:
            normalized_ko = build.normalize_key(ko_name)
            normalized_en = build.normalize_key(en_name)
            is_multi = " / " in ko_name or " / " in en_name
            is_dungeon = bool(build.canonicalize_dungeon(ko_name) or build.canonicalize_dungeon(en_name))
            is_non_item = "bis" in normalized_ko or "bis" in normalized_en
            if is_multi or is_dungeon or is_non_item:
                continue
            raise ValueError(f"Companion entry not found: {en_name!r} / {ko_name!r}")
        result.append(f"- **{entry['nameKoKR']}** ({entry['nameEnUS']}) — itemID: {entry['itemID']}")
        updated_rows += 1

    return result, updated_rows


def count_final_item_ids(lines: List[str]) -> int:
    return sum(1 for line in lines if "itemID:" in line and line.lstrip().startswith("-"))


def count_companion_item_ids(lines: List[str]) -> int:
    return sum(1 for line in lines if COMPANION_LINE_RE.match(line.strip()) and "itemID:" in line)


def collapse_blank_lines(lines: List[str]) -> List[str]:
    collapsed: List[str] = []
    previous_blank = False
    for line in lines:
        is_blank = not line.strip()
        if is_blank and previous_blank:
            continue
        collapsed.append(line)
        previous_blank = is_blank
    return collapsed


def apply_global_name_aliases(lines: List[str]) -> List[str]:
    updated = list(lines)
    for source_name, target_name in build.DOC_ITEM_NAME_ALIASES_RAW.items():
        updated = [line.replace(source_name, target_name) for line in updated]
    return updated


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--check", action="store_true", help="Validate only, do not write changes")
    args = parser.parse_args()

    catalog = parse_catalog(CATALOG_FILE)
    by_spec, global_index = build_catalog_indices(catalog)

    final_lines = FINAL_DOC_FILE.read_text(encoding="utf-8").splitlines()
    companion_lines = COMPANION_DOC_FILE.read_text(encoding="utf-8").splitlines()

    synced_final, final_rows = sync_final_doc(final_lines, by_spec, global_index)
    synced_companion, companion_rows = sync_companion_doc(companion_lines, global_index)
    synced_final = apply_global_name_aliases(synced_final)
    synced_final = collapse_blank_lines(synced_final)
    synced_companion = collapse_blank_lines(synced_companion)

    if not args.check:
        FINAL_DOC_FILE.write_text("\n".join(synced_final) + "\n", encoding="utf-8")
        COMPANION_DOC_FILE.write_text("\n".join(synced_companion) + "\n", encoding="utf-8")

    final_id_rows = count_final_item_ids(synced_final)
    companion_id_rows = count_companion_item_ids(synced_companion)
    print(f"[sync] final rows updated: {final_rows}")
    print(f"[sync] companion rows updated: {companion_rows}")
    print(f"[sync] final itemID lines: {final_id_rows}")
    print(f"[sync] companion itemID lines: {companion_id_rows}")


if __name__ == "__main__":
    main()
