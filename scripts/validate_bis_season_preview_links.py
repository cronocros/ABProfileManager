"""Validate non-M+ BIS season preview link selectors."""

from __future__ import annotations

import re
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[1]
PREVIEW_DB = REPO_ROOT / "ABProfileManager" / "Data" / "BISSeasonPreviewLinks.lua"
CATALOG = REPO_ROOT / "ABProfileManager" / "Data" / "BISCatalog.lua"
TOC = REPO_ROOT / "ABProfileManager" / "ABProfileManager.toc"
EXPECTED_DB2_BUILD = "12.0.1.66838"


def require_contains(text: str, needle: str, source: Path, reason: str) -> None:
    if needle not in text:
        raise ValueError(f"{source.relative_to(REPO_ROOT)}: missing {needle!r}; {reason}")


def catalog_sources() -> dict[str, set[int]]:
    text = CATALOG.read_text(encoding="utf-8")
    by_source: dict[str, set[int]] = {}
    for match in re.finditer(r"\{ slot = .*?\},", text):
        row = match.group(0)
        item_match = re.search(r"\bitemID\s*=\s*(\d+)", row)
        source_match = re.search(r'\bsourceGroup\s*=\s*"([^"]+)"', row)
        if item_match and source_match:
            by_source.setdefault(source_match.group(1), set()).add(int(item_match.group(1)))
    return by_source


def validate_overrides(text: str, by_source: dict[str, set[int]]) -> None:
    root_match = re.search(r"\blinksBySourceAndItemID\s*=\s*\{(.*)^\s*\}\s*,?\s*^\s*\}\s*$", text, re.M | re.S)
    if not root_match:
        raise ValueError(f"{PREVIEW_DB.relative_to(REPO_ROOT)}: missing linksBySourceAndItemID root table")
    override_text = root_match.group(1)
    for source in ("raid", "tier", "crafted"):
        section_match = re.search(
            rf"\b{source}\s*=\s*\{{(.*?)^\s*\}}\s*,",
            override_text,
            re.M | re.S,
        )
        if not section_match:
            raise ValueError(f"{PREVIEW_DB.relative_to(REPO_ROOT)}: missing {source} override table")
        for raw_item_id, link in re.findall(r'^\s*\[(\d+)\]\s*=\s*"([^"]+)"\s*,?', section_match.group(1), re.M):
            item_id = int(raw_item_id)
            if item_id not in by_source.get(source, set()):
                raise ValueError(f"{source} preview override itemID is not in BISCatalog.lua: {item_id}")
            link_item_id = re.search(r"item:(\d+)", link)
            if not link_item_id or int(link_item_id.group(1)) != item_id:
                raise ValueError(f"{source} preview override itemID mismatch: {item_id}")
            if link in {f"item:{item_id}", f"|Hitem:{item_id}|h"} or link.count(":") < 2:
                raise ValueError(f"{source} preview override must contain a full item string: {item_id}")


def main() -> None:
    text = PREVIEW_DB.read_text(encoding="utf-8")
    toc = TOC.read_text(encoding="utf-8")
    by_source = catalog_sources()

    require_contains(toc, "Data\\BISSeasonPreviewLinks.lua", TOC, "season preview DB must load before BISOverlay")
    require_contains(text, 'verifiedDB2Build = "12.0.1.66838"', PREVIEW_DB, "DB2 build must be recorded")
    require_contains(text, "raid = {", PREVIEW_DB, "raid preview profile is required")
    require_contains(text, "tier = {", PREVIEW_DB, "tier preview profile is required")
    require_contains(text, "crafted = {", PREVIEW_DB, "crafted preview profile is required")
    require_contains(text, "minItemLevel = 272", PREVIEW_DB, "raid/tier preview must stay in Myth range")
    require_contains(text, "maxItemLevel = 298", PREVIEW_DB, "raid preview must allow Sporefall Mythic max item level")
    require_contains(text, "maxItemLevel = 289", PREVIEW_DB, "tier preview must allow Myth max upgrade")
    require_contains(text, "targetItemLevel = 285", PREVIEW_DB, "crafted preview must target R5 285")
    require_contains(text, "requireMythText = true", PREVIEW_DB, "raid/tier preview must verify Myth tooltip text")
    require_contains(text, "item:%d::::::::::::3:6652:13335:12806", PREVIEW_DB, "raid Myth selector must be present")
    require_contains(text, "item:%d::::::::::::5:13340:13440:6652:13574:12804", PREVIEW_DB, "tier Myth selector must be present")
    require_contains(text, "item:%d::::::::::::6:12214:12497:12066:8960:12384:13622", PREVIEW_DB, "crafted R5 selector must be present")
    validate_overrides(text, by_source)

    print(
        "ok: season preview links "
        f"db2_build={EXPECTED_DB2_BUILD} "
        f"raid_items={len(by_source.get('raid', set()))} "
        f"tier_items={len(by_source.get('tier', set()))} "
        f"crafted_items={len(by_source.get('crafted', set()))}"
    )


if __name__ == "__main__":
    main()
