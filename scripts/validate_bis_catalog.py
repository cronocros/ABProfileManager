#!/usr/bin/env python3
"""Validate generated ABProfileManager BIS catalog release invariants."""

from __future__ import annotations

import argparse
import re
import subprocess
from pathlib import Path
from typing import Dict, List, Optional, Tuple

from build_bis_catalog import SPEC_NAMES


REPO_ROOT = Path(__file__).resolve().parents[1]
CATALOG_FILE = REPO_ROOT / "ABProfileManager" / "Data" / "BISCatalog.lua"
DOC_DB_FILE = REPO_ROOT / "DOC" / "MidnightS1_MPlus_Addon_DB_v1.0.lua"


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
            "runtimeItemLinkRequired": get_lua_field(line, "runtimeItemLinkRequired"),
            "staticFinalBisVerified": get_lua_field(line, "staticFinalBisVerified"),
            "mythTrackVerified": get_lua_field(line, "mythTrackVerified"),
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


def validate_raid_preservation(current: Dict[int, List[Dict[str, object]]], previous: Dict[int, List[Dict[str, object]]]) -> None:
    previous_raid = {
        row_key(row)
        for rows in previous.values()
        for row in rows
        if row.get("sourceGroup") == "raid" and row.get("sourceType") == "raid"
    }
    current_raid = {
        row_key(row)
        for rows in current.values()
        for row in rows
        if row.get("sourceGroup") == "raid" and row.get("sourceType") == "raid"
    }
    missing = sorted(previous_raid - current_raid)
    if missing:
        preview = ", ".join(str(key) for key in missing[:10])
        raise ValueError(f"Missing preserved raid rows: {len(missing)} missing; first={preview}")


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
            if 'itemString = "' in raw or 'itemLink = "' in raw or "bonusID" in raw or "bonusIds" in raw:
                raise ValueError(f"M+ row contains static link/bonus data at line {row['line']}, item {item_id}")
            if row.get("staticFinalBisVerified") is not False or row.get("mythTrackVerified") is not False:
                raise ValueError(f"M+ row missing unverified BIS/Myth metadata at line {row['line']}, item {item_id}")
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
            elif source_group == "crafted":
                crafted_count += 1
                if "rewardProfiles" in raw:
                    raise ValueError(f"Crafted row must not embed rewardProfiles at line {row['line']}, item {row['itemID']}")
    if tier_count == 0:
        raise ValueError("Catalog has no tier rows")
    if crafted_count == 0:
        raise ValueError("Catalog has no crafted rows")


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
    validate_raid_preservation(current, previous)
    validate_mplus_rows(current)
    validate_tier_and_crafted_policy(current)

    total_rows = sum(len(rows) for rows in current.values())
    print(f"ok: specs={len(current)} rows={total_rows}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
