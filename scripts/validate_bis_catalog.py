#!/usr/bin/env python3
"""Validate generated ABProfileManager BIS catalog release invariants."""

from __future__ import annotations

import argparse
import re
import subprocess
from pathlib import Path
from typing import Dict, List, Optional, Tuple

from build_bis_catalog import (
    SPEC_NAMES,
    parse_addon_db_specs,
    parse_addon_db_simple_item_table,
    parse_addon_db_tier_sets,
    parse_addon_db_trinkets,
    parse_addon_db_weapons,
    render_stat_priorities,
    render_stat_priority_table,
    trinket_matches_spec,
    weapon_matches_spec,
)


REPO_ROOT = Path(__file__).resolve().parents[1]
CATALOG_FILE = REPO_ROOT / "ABProfileManager" / "Data" / "BISCatalog.lua"
DOC_DB_FILE = REPO_ROOT / "DOC" / "MidnightS1_MPlus_Addon_DB_v1.3.lua"
STAT_PRIORITIES_FILE = REPO_ROOT / "ABProfileManager" / "Data" / "StatPriorities.lua"
STAT_PRIORITY_TABLE_FILE = REPO_ROOT / "ABProfileManager" / "Data" / "StatPriorityTable.lua"
EXPECTED_SOURCE_GROUP_COUNTS = {
    "mythicplus": 2554,
    "raid": 285,
    "crafted": 91,
    "tier": 200,
}


def lua_unescape(value: str) -> str:
    return value.replace('\\"', '"').replace("\\\\", "\\")


def get_lua_field(line: str, field: str) -> object:
    match = re.search(rf'\b{re.escape(field)}\s*=\s*(nil|true|false|-?\d+|"(?:(?:\\.)|[^"\\])*")', line)
    if not match:
        return None
    raw = match.group(1)
    if raw == "nil":
        return None
    if raw == "true":
        return True
    if raw == "false":
        return False
    if raw.startswith('"') and raw.endswith('"'):
        return lua_unescape(raw[1:-1])
    return int(raw)


def parse_catalog_text(text: str) -> Dict[int, List[Dict[str, object]]]:
    catalog: Dict[int, List[Dict[str, object]]] = {}
    current_spec: Optional[int] = None
    for line_no, line in enumerate(text.splitlines(), start=1):
        spec_match = re.match(r"^\s*\[(\d+)\]\s*=\s*\{", line)
        if spec_match:
            current_spec = int(spec_match.group(1))
            catalog.setdefault(current_spec, [])
            continue
        if current_spec is None or "{ slot =" not in line:
            continue
        row = {
            "line": line_no,
            "raw": line,
            "specID": current_spec,
            "slot": str(get_lua_field(line, "slot") or ""),
            "itemID": int(get_lua_field(line, "itemID") or 0),
            "sourceGroup": str(get_lua_field(line, "sourceGroup") or ""),
            "sourceType": str(get_lua_field(line, "sourceType") or ""),
            "overallRank": int(get_lua_field(line, "overallRank") or 0),
            "sourceRank": int(get_lua_field(line, "sourceRank") or 0),
            "nameEnUS": str(get_lua_field(line, "nameEnUS") or ""),
            "displaySourceEnUS": str(get_lua_field(line, "displaySourceEnUS") or ""),
            "dungeonEnUS": str(get_lua_field(line, "dungeonEnUS") or ""),
            "runtimeItemLinkRequired": get_lua_field(line, "runtimeItemLinkRequired"),
            "requiresRuntimeItemLink": get_lua_field(line, "requiresRuntimeItemLink"),
            "staticFinalBisVerified": get_lua_field(line, "staticFinalBisVerified"),
            "mythTrackVerified": get_lua_field(line, "mythTrackVerified"),
            "bisValidationLevel": get_lua_field(line, "bisValidationLevel"),
            "statPriorityVerified": get_lua_field(line, "statPriorityVerified"),
            "statPrioritySummary": get_lua_field(line, "statPrioritySummary"),
            "staticPriorityStatus": get_lua_field(line, "staticPriorityStatus"),
            "v13Evidence": get_lua_field(line, "v13Evidence"),
        }
        catalog[current_spec].append(row)
    return catalog


def load_previous_catalog_text() -> str:
    result = subprocess.run(
        ["git", "show", "HEAD:ABProfileManager/Data/BISCatalog.lua"],
        cwd=REPO_ROOT,
        text=True,
        encoding="utf-8",
        capture_output=True,
        check=True,
    )
    return result.stdout


def row_key(row: Dict[str, object]) -> Tuple[int, str, int, str, str]:
    return (
        int(row["specID"]),
        str(row["slot"]),
        int(row["itemID"]),
        str(row["sourceGroup"]),
        str(row["sourceType"]),
    )


def validate_specs(catalog: Dict[int, List[Dict[str, object]]]) -> None:
    expected = set(SPEC_NAMES)
    actual = set(catalog)
    if actual != expected:
        missing = sorted(expected - actual)
        unexpected = sorted(actual - expected)
        raise ValueError(f"Spec mismatch. missing={missing} unexpected={unexpected}")
    empty = sorted(spec_id for spec_id, rows in catalog.items() if not rows)
    if empty:
        raise ValueError(f"Specs with no rows: {empty}")


def get_source_row_keys(catalog: Dict[int, List[Dict[str, object]]], source_groups: set[str]) -> set[Tuple[int, str, int, str, str]]:
    return {
        row_key(row)
        for rows in catalog.values()
        for row in rows
        if str(row.get("sourceGroup") or "") in source_groups
    }


def validate_preserved_source_rows(
    current: Dict[int, List[Dict[str, object]]],
    previous: Dict[int, List[Dict[str, object]]],
    source_groups: set[str],
) -> None:
    expected = get_source_row_keys(previous, source_groups)
    actual = get_source_row_keys(current, source_groups)
    if actual != expected:
        missing = sorted(expected - actual)
        unexpected = sorted(actual - expected)
        raise ValueError(
            f"Preserved source rows changed for {sorted(source_groups)}. "
            f"missing={missing[:10]} unexpected={unexpected[:10]}"
        )


def validate_unique_row_keys(catalog: Dict[int, List[Dict[str, object]]]) -> None:
    seen: set[Tuple[int, str, int, str, str]] = set()
    for rows in catalog.values():
        for row in rows:
            key = row_key(row)
            if key in seen:
                raise ValueError(f"Duplicate catalog row: {key}")
            seen.add(key)


def validate_mplus_rows(catalog: Dict[int, List[Dict[str, object]]]) -> None:
    mplus_count = 0
    for rows in catalog.values():
        for row in rows:
            if row.get("sourceGroup") != "mythicplus":
                continue
            mplus_count += 1
            raw = str(row["raw"])
            item_id = row["itemID"]
            if "mplus_end_of_dungeon" not in raw or "mplus_great_vault_voidcore" not in raw:
                raise ValueError(f"M+ row missing reward profiles at line {row['line']}, item {item_id}")
            if 'upgradeTrack = "Hero"' not in raw or "itemLevel = 266" not in raw:
                raise ValueError(f"M+ row missing Hero end reward profile at line {row['line']}, item {item_id}")
            if 'upgradeTrack = "Myth"' not in raw or "itemLevel = 272" not in raw:
                raise ValueError(f"M+ row missing Myth vault reward profile at line {row['line']}, item {item_id}")
            if row.get("runtimeItemLinkRequired") is not True:
                raise ValueError(f"M+ row missing runtimeItemLinkRequired=true at line {row['line']}, item {item_id}")
            if row.get("requiresRuntimeItemLink") is not True:
                raise ValueError(f"M+ row missing requiresRuntimeItemLink=true at line {row['line']}, item {item_id}")
            if 'itemString = "' in raw or 'itemLink = "' in raw or "bonusID" in raw or "bonusIds" in raw:
                raise ValueError(f"M+ row contains static link/bonus data at line {row['line']}, item {item_id}")
            if row.get("staticFinalBisVerified") is not False or row.get("mythTrackVerified") is not False:
                raise ValueError(f"M+ row missing unverified BIS/Myth metadata at line {row['line']}, item {item_id}")
            if row.get("bisValidationLevel") != "STRICT_STATIC_DB_CANNOT_CERTIFY_FINAL_BIS__RUNTIME_SIM_REQUIRED":
                raise ValueError(f"M+ row missing strict BIS validation level at line {row['line']}, item {item_id}")
            if row.get("statPriorityVerified") is not True or not row.get("statPrioritySummary"):
                raise ValueError(f"M+ row missing stat-priority metadata at line {row['line']}, item {item_id}")
            if row.get("staticPriorityStatus") != "STATIC_POOL_ONLY_ITEMLINK_REQUIRED_FOR_REAL_PRIORITY":
                raise ValueError(f"M+ row missing v1.3 static priority status at line {row['line']}, item {item_id}")
            if row.get("v13Evidence") != "RUNTIME_ITEMLINK_STATS_REQUIRED":
                raise ValueError(f"M+ row missing v1.3 runtime evidence at line {row['line']}, item {item_id}")
    if mplus_count == 0:
        raise ValueError("Catalog has no Mythic+ rows")


def validate_tier_and_crafted_policy(catalog: Dict[int, List[Dict[str, object]]]) -> None:
    tier_count = 0
    crafted_count = 0
    for rows in catalog.values():
        for row in rows:
            source_group = row.get("sourceGroup")
            raw = str(row["raw"])
            if source_group == "tier":
                tier_count += 1
                if "rewardProfiles" in raw:
                    raise ValueError(f"Tier row must not embed rewardProfiles at line {row['line']}, item {row['itemID']}")
                if row.get("runtimeItemLinkRequired") is not True:
                    raise ValueError(f"Tier row missing runtimeItemLinkRequired=true at line {row['line']}, item {row['itemID']}")
                if row.get("requiresRuntimeItemLink") is not True:
                    raise ValueError(f"Tier row missing requiresRuntimeItemLink=true at line {row['line']}, item {row['itemID']}")
                if row.get("staticFinalBisVerified") is not False or row.get("mythTrackVerified") is not False:
                    raise ValueError(f"Tier row missing unverified BIS/Myth metadata at line {row['line']}, item {row['itemID']}")
                if row.get("bisValidationLevel") != "STRICT_STATIC_DB_CANNOT_CERTIFY_FINAL_BIS__RUNTIME_SIM_REQUIRED":
                    raise ValueError(f"Tier row missing strict BIS validation level at line {row['line']}, item {row['itemID']}")
                if row.get("statPriorityVerified") is not True or not row.get("statPrioritySummary"):
                    raise ValueError(f"Tier row missing stat-priority metadata at line {row['line']}, item {row['itemID']}")
                if row.get("staticPriorityStatus") != "STATIC_POOL_ONLY_ITEMLINK_REQUIRED_FOR_REAL_PRIORITY":
                    raise ValueError(f"Tier row missing v1.3 static priority status at line {row['line']}, item {row['itemID']}")
                if row.get("v13Evidence") != "RUNTIME_ITEMLINK_STATS_REQUIRED":
                    raise ValueError(f"Tier row missing v1.3 runtime evidence at line {row['line']}, item {row['itemID']}")
            elif source_group == "crafted":
                crafted_count += 1
                if "rewardProfiles" in raw:
                    raise ValueError(f"Crafted row must not embed rewardProfiles at line {row['line']}, item {row['itemID']}")
    if tier_count == 0:
        raise ValueError("Catalog has no tier rows")
    if crafted_count == 0:
        raise ValueError("Catalog has no crafted rows")


def validate_source_group_counts(catalog: Dict[int, List[Dict[str, object]]]) -> None:
    actual = {source_group: 0 for source_group in EXPECTED_SOURCE_GROUP_COUNTS}
    for rows in catalog.values():
        for row in rows:
            source_group = str(row.get("sourceGroup") or "")
            if source_group in actual:
                actual[source_group] += 1
    if actual != EXPECTED_SOURCE_GROUP_COUNTS:
        raise ValueError(f"Source group count mismatch. expected={EXPECTED_SOURCE_GROUP_COUNTS} actual={actual}")


def validate_en_us_fields(catalog: Dict[int, List[Dict[str, object]]]) -> None:
    for rows in catalog.values():
        for row in rows:
            item_id = row["itemID"]
            name_en = str(row.get("nameEnUS") or "")
            source_en = str(row.get("displaySourceEnUS") or "")
            dungeon_en = str(row.get("dungeonEnUS") or "")
            if not name_en or re.search(r"[가-힣]", name_en):
                raise ValueError(f"Invalid enUS item name at line {row['line']}, item {item_id}: {name_en!r}")
            if re.search(r"[가-힣]", source_en):
                raise ValueError(f"Invalid enUS source at line {row['line']}, item {item_id}: {source_en!r}")
            if not source_en:
                raise ValueError(f"Missing enUS source at line {row['line']}, item {item_id}")
            if re.search(r"[가-힣]", dungeon_en):
                raise ValueError(f"Invalid enUS dungeon at line {row['line']}, item {item_id}: {dungeon_en!r}")
            if row.get("sourceGroup") == "mythicplus" and not dungeon_en:
                raise ValueError(f"M+ row missing enUS source at line {row['line']}, item {item_id}")


def build_expected_addon_source_keys(doc_db: Path) -> set[Tuple[int, str, int, str, str]]:
    text = doc_db.read_text(encoding="utf-8")
    specs, _ = parse_addon_db_specs(text)
    tier_sets = parse_addon_db_tier_sets(text)
    accessory_rows = parse_addon_db_simple_item_table(text, "ACCESSORIES")
    armor_rows_by_armor = {
        "CLOTH": parse_addon_db_simple_item_table(text, "CLOTH_ARMOR"),
        "LEATHER": parse_addon_db_simple_item_table(text, "LEATHER_ARMOR"),
        "MAIL": parse_addon_db_simple_item_table(text, "MAIL_ARMOR"),
        "PLATE": parse_addon_db_simple_item_table(text, "PLATE_ARMOR"),
    }
    trinket_rows = parse_addon_db_trinkets(text)
    weapon_rows = parse_addon_db_weapons(text)
    expected: set[Tuple[int, str, int, str, str]] = set()

    for spec_id, spec in specs.items():
        tier = tier_sets.get(int(spec.get("tierSetId") or 0))
        for piece in tier.get("pieces", []) if tier else []:
            expected.add((spec_id, str(piece["slot"]), int(piece["itemID"]), "tier", "tier"))

        mplus_rows = list(accessory_rows) + list(armor_rows_by_armor.get(str(spec.get("armor") or ""), []))
        mplus_rows.extend(row for row in trinket_rows if trinket_matches_spec(row, spec))
        mplus_rows.extend(row for row in weapon_rows if weapon_matches_spec(row, spec_id, spec))
        for row in mplus_rows:
            expected.add((spec_id, str(row["slot"]), int(row["itemID"]), "mythicplus", "mythicplus"))
    return expected


def validate_addon_source_rows(catalog: Dict[int, List[Dict[str, object]]], doc_db: Path) -> None:
    expected = build_expected_addon_source_keys(doc_db)
    actual = get_source_row_keys(catalog, {"mythicplus", "tier"})
    if actual != expected:
        missing = sorted(expected - actual)
        unexpected = sorted(actual - expected)
        raise ValueError(f"Generated DOC source rows changed. missing={missing[:10]} unexpected={unexpected[:10]}")


def validate_doc_db_and_stat_tables(doc_db: Path) -> None:
    from luaparser import ast

    text = doc_db.read_text(encoding="utf-8")
    ast.parse(text)
    specs, policies = parse_addon_db_specs(text)
    expected = set(SPEC_NAMES)
    if set(specs) != expected or set(policies) != expected:
        raise ValueError("DOC DB must contain policies for all 40 specializations")
    for spec_id, policy in policies.items():
        secondary_order = policy.get("secondaryOrder")
        secondary_weights = policy.get("secondaryWeights")
        if not secondary_order or not secondary_weights:
            raise ValueError(f"DOC DB spec {spec_id} is missing representative stat priority data")

    expected_compact = render_stat_priorities(policies)
    expected_popup = render_stat_priority_table(policies)
    compact = STAT_PRIORITIES_FILE.read_text(encoding="utf-8")
    popup = STAT_PRIORITY_TABLE_FILE.read_text(encoding="utf-8")
    if compact != expected_compact:
        raise ValueError(f"Generated stat priorities are stale: {STAT_PRIORITIES_FILE}")
    if popup != expected_popup:
        raise ValueError(f"Generated stat priority table is stale: {STAT_PRIORITY_TABLE_FILE}")
    ast.parse(compact)
    ast.parse(popup)


def main() -> int:
    parser = argparse.ArgumentParser(description="Validate generated ABProfileManager BIS catalog.")
    parser.add_argument("--catalog", type=Path, default=CATALOG_FILE)
    parser.add_argument("--doc-db", type=Path, default=DOC_DB_FILE)
    args = parser.parse_args()

    if not args.doc_db.exists():
        raise FileNotFoundError(args.doc_db)
    current = parse_catalog_text(args.catalog.read_text(encoding="utf-8"))
    previous = parse_catalog_text(load_previous_catalog_text())

    validate_specs(current)
    validate_unique_row_keys(current)
    validate_preserved_source_rows(current, previous, {"raid", "crafted"})
    validate_mplus_rows(current)
    validate_tier_and_crafted_policy(current)
    validate_source_group_counts(current)
    validate_en_us_fields(current)
    validate_addon_source_rows(current, args.doc_db)
    validate_doc_db_and_stat_tables(args.doc_db)

    total_rows = sum(len(rows) for rows in current.values())
    print(f"ok: specs={len(current)} rows={total_rows}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
