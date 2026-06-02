"""Validate the Myth 1/6 preview selector and curated full-link overrides."""

from __future__ import annotations

import re
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[1]
LINK_DB = REPO_ROOT / "ABProfileManager" / "Data" / "BISMythicVaultLinks.lua"
CATALOG = REPO_ROOT / "ABProfileManager" / "Data" / "BISCatalog.lua"
EXPECTED_PREVIEW_BONUS_LIST_ID = 12801
EXPECTED_SCHEMA_VERSION = 3
EXPECTED_DB2_BUILD = "12.0.1.66838"
EXPECTED_PREVIEW_ITEM_STRING_TEMPLATE = "item:%d::::::::::::1:%d"


def main() -> None:
    text = LINK_DB.read_text(encoding="utf-8")
    catalog_text = CATALOG.read_text(encoding="utf-8")

    schema_match = re.search(r"\bschemaVersion\s*=\s*(\d+)", text)
    if not schema_match or int(schema_match.group(1)) != EXPECTED_SCHEMA_VERSION:
        raise ValueError(
            "BISMythicVaultLinks.lua must declare "
            f"schemaVersion = {EXPECTED_SCHEMA_VERSION}"
        )

    db2_build_match = re.search(r'\bverifiedDB2Build\s*=\s*"([^"]+)"', text)
    if not db2_build_match or db2_build_match.group(1) != EXPECTED_DB2_BUILD:
        raise ValueError(
            "BISMythicVaultLinks.lua must declare verifiedDB2Build = "
            f'"{EXPECTED_DB2_BUILD}"'
        )

    baseline_match = re.search(r"\bbaselineItemLevel\s*=\s*(\d+)", text)
    if not baseline_match or int(baseline_match.group(1)) != 272:
        raise ValueError("BISMythicVaultLinks.lua must declare baselineItemLevel = 272")

    preview_bonus_match = re.search(r"\bgeneratedPreviewBonusListID\s*=\s*(\d+)", text)
    if (
        not preview_bonus_match
        or int(preview_bonus_match.group(1)) != EXPECTED_PREVIEW_BONUS_LIST_ID
    ):
        raise ValueError(
            "BISMythicVaultLinks.lua must declare generatedPreviewBonusListID = "
            f"{EXPECTED_PREVIEW_BONUS_LIST_ID}"
        )

    preview_template_match = re.search(
        r'\bgeneratedPreviewItemStringTemplate\s*=\s*"([^"]+)"',
        text,
    )
    if (
        not preview_template_match
        or preview_template_match.group(1) != EXPECTED_PREVIEW_ITEM_STRING_TEMPLATE
    ):
        raise ValueError(
            "BISMythicVaultLinks.lua must declare generatedPreviewItemStringTemplate = "
            f'"{EXPECTED_PREVIEW_ITEM_STRING_TEMPLATE}"'
        )

    catalog_item_ids = {
        int(value)
        for value in re.findall(r"\bitemID\s*=\s*(\d+)", catalog_text)
    }
    seen: set[int] = set()
    entries = re.findall(r'^\s*\[(\d+)\]\s*=\s*"([^"]+)"\s*,?\s*$', text, re.M)
    for raw_item_id, link in entries:
        item_id = int(raw_item_id)
        if item_id in seen:
            raise ValueError(f"Duplicate curated Myth link itemID: {item_id}")
        seen.add(item_id)
        if item_id not in catalog_item_ids:
            raise ValueError(f"Curated Myth link is not present in BISCatalog.lua: {item_id}")
        link_item_id = re.search(r"item:(\d+)", link)
        if not link_item_id or int(link_item_id.group(1)) != item_id:
            raise ValueError(f"Curated Myth link itemID mismatch: {item_id}")
        if link in {f"item:{item_id}", f"|Hitem:{item_id}|h"} or link.count(":") < 2:
            raise ValueError(f"Curated Myth link must contain the full item string: {item_id}")

    print(
        "ok: baseline=272 "
        f"schema={EXPECTED_SCHEMA_VERSION} "
        f"db2_build={EXPECTED_DB2_BUILD} "
        f"generated_preview_bonus={EXPECTED_PREVIEW_BONUS_LIST_ID} "
        f"template={EXPECTED_PREVIEW_ITEM_STRING_TEMPLATE} "
        f"curated_myth_links={len(entries)}"
    )


if __name__ == "__main__":
    main()
