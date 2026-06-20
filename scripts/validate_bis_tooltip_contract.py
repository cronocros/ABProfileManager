"""Validate static contracts for BIS hover tooltips and taint-safe number handling."""

from __future__ import annotations

import re
from pathlib import Path

from luaparser import ast as lua_ast
from luaparser.astnodes import LocalAssign, LocalFunction


REPO_ROOT = Path(__file__).resolve().parents[1]
BIS_OVERLAY = REPO_ROOT / "ABProfileManager" / "UI" / "BISOverlay.lua"
STATS_OVERLAY = REPO_ROOT / "ABProfileManager" / "UI" / "StatsOverlay.lua"
UTILS = REPO_ROOT / "ABProfileManager" / "Utils.lua"
DB = REPO_ROOT / "ABProfileManager" / "DB.lua"
DEFAULTS = REPO_ROOT / "ABProfileManager" / "Data" / "Defaults.lua"
RUNTIME_SCORING = REPO_ROOT / "ABProfileManager" / "Data" / "BISRuntimeScoring.lua"
MAX_BIS_OVERLAY_TOP_LEVEL_LOCALS = 198


def require_contains(text: str, needle: str, source: Path, reason: str) -> None:
    if needle not in text:
        raise ValueError(f"{source.relative_to(REPO_ROOT)}: missing {needle!r}; {reason}")


def require_absent(text: str, needle: str, source: Path, reason: str) -> None:
    if needle in text:
        raise ValueError(f"{source.relative_to(REPO_ROOT)}: found forbidden {needle!r}; {reason}")


def strip_lua_line_comments(text: str) -> str:
    return re.sub(r"--[^\n]*", "", text)


def get_safe_number_body(text: str) -> str:
    match = re.search(
        r"function\s+Utils\.SafeNumber\s*\(\s*value\s*\)(.*?)^end\s*$",
        strip_lua_line_comments(text),
        re.M | re.S,
    )
    if not match:
        raise ValueError("ABProfileManager/Utils.lua: could not locate Utils.SafeNumber(value)")
    return match.group(1)


def count_top_level_lua_locals(text: str) -> int:
    tree = lua_ast.parse(text)
    count = 0
    for node in tree.body.body:
        if isinstance(node, LocalAssign):
            count += len(node.targets)
        elif isinstance(node, LocalFunction):
            count += 1
    return count


def main() -> None:
    bis_overlay = BIS_OVERLAY.read_text(encoding="utf-8")
    stats_overlay = STATS_OVERLAY.read_text(encoding="utf-8")
    utils = UTILS.read_text(encoding="utf-8")
    db = DB.read_text(encoding="utf-8")
    defaults = DEFAULTS.read_text(encoding="utf-8")
    runtime_scoring = RUNTIME_SCORING.read_text(encoding="utf-8")
    bis_top_level_locals = count_top_level_lua_locals(bis_overlay)

    if bis_top_level_locals > MAX_BIS_OVERLAY_TOP_LEVEL_LOCALS:
        raise ValueError(
            f"{BIS_OVERLAY.relative_to(REPO_ROOT)}: top-level local count "
            f"{bis_top_level_locals} exceeds safe budget {MAX_BIS_OVERLAY_TOP_LEVEL_LOCALS}; "
            "WoW Lua chunks fail when the main function crosses the 200-local limit"
        )

    require_contains(
        bis_overlay,
        "tooltip.isShopping = true",
        BIS_OVERLAY,
        "addon-owned non-M+ Blizzard hyperlink tooltips must skip MoneyFrame sell-price rendering",
    )
    require_contains(
        bis_overlay,
        "tooltip.SetHyperlink",
        BIS_OVERLAY,
        "raid/crafted/tier BIS hover can still use Blizzard's hyperlink tooltip renderer",
    )
    require_contains(
        bis_overlay,
        "resetBISTooltipState",
        BIS_OVERLAY,
        "addon-owned BIS tooltips must clear transient Blizzard tooltip flags when hidden",
    )
    require_contains(
        bis_overlay,
        "tryShowSnapshotTooltip",
        BIS_OVERLAY,
        "M+ Myth preview hover must render verified snapshot lines without re-feeding Myth links to GameTooltip",
    )
    require_absent(
        bis_overlay,
        'GameTooltip:HookScript("OnShow", hideBISTooltip)',
        BIS_OVERLAY,
        "global GameTooltip script hooks can taint Blizzard item tooltip MoneyFrame execution",
    )
    require_contains(
        bis_overlay,
        "pcall(EncounterJournal_OpenJournal, difficultyID, instanceID, encounterID, nil, nil, nil, tier)",
        BIS_OVERLAY,
        "Encounter Journal landing must not focus an itemID from the addon click path",
    )
    require_absent(
        bis_overlay,
        "pcall(EncounterJournal_OpenJournal, difficultyID, instanceID, encounterID, nil, nil, itemID, tier)",
        BIS_OVERLAY,
        "itemID-focused Encounter Journal landing can taint Blizzard loot item tooltip MoneyFrame execution",
    )
    require_contains(
        bis_overlay,
        "areContainerFramesShown() or not C_Timer",
        BIS_OVERLAY,
        "automatic Myth preview scans must not run while container frames are visible",
    )
    require_contains(
        bis_overlay,
        "not snapshot and not areContainerFramesShown() and resolveMythPreviewSnapshot(entry)",
        BIS_OVERLAY,
        "hover-triggered Myth preview scans must not run while bags are open",
    )
    require_contains(
        bis_overlay,
        "tooltipDataHasMythOneOfSix",
        BIS_OVERLAY,
        "Myth 1/6 preview links must be verified before caching",
    )
    require_contains(
        bis_overlay,
        "snapshot.trackVerified == true",
        BIS_OVERLAY,
        "cached Myth snapshots must carry a verified-track marker",
    )
    require_contains(
        bis_overlay,
        "DEFAULT_ITEM_TOOLTIP_LINK_CACHE",
        BIS_OVERLAY,
        "raid/crafted/tier default Blizzard item links must be cached after loading",
    )
    require_contains(
        bis_overlay,
        'sourceType == "raid" or sourceType == "crafted" or sourceType == "tier"',
        BIS_OVERLAY,
        "raid/crafted/tier rows must be allowed to use base Blizzard item tooltips",
    )
    require_contains(
        bis_overlay,
        "if useDefaultTooltip and tryShowBlizzardItemTooltip(bareLink) then",
        BIS_OVERLAY,
        "tier/base itemID rows must attempt a bare item link before falling back",
    )
    require_contains(
        bis_overlay,
        "getVerifiedSourcePreviewItemLink(itemID, sourceType)",
        BIS_OVERLAY,
        "raid/crafted/tier rows must attempt verified season preview links before base item links",
    )
    require_contains(
        bis_overlay,
        "tooltipDataHasMythText",
        BIS_OVERLAY,
        "raid/tier season preview links must be checked for Myth tooltip text",
    )
    require_contains(
        db,
        "settings.bisOverlay.itemTooltip = true",
        DB,
        "BIS overlay item tooltip checkbox must default to enabled",
    )
    require_contains(
        db,
        "settings._itemTooltipUserConfiguredV1 = true",
        DB,
        "BIS overlay item tooltip user choices must be remembered after toggling",
    )
    require_contains(
        defaults,
        "itemTooltip = true",
        DEFAULTS,
        "new SavedVariables defaults must enable the BIS overlay item tooltip checkbox",
    )
    require_absent(
        bis_overlay,
        "renderTooltipSnapshot",
        BIS_OVERLAY,
        "manual snapshot hover rendering must not replace Blizzard item tooltips",
    )
    require_absent(
        bis_overlay,
        "renderTooltipDataWithoutMoney",
        BIS_OVERLAY,
        "manual tooltip-data hover rendering must not replace Blizzard item tooltips",
    )
    require_absent(
        bis_overlay,
        "tryShowBlizzardItemTooltip(snapshot.itemLink)",
        BIS_OVERLAY,
        "M+ Myth preview links must not be passed to GameTooltip display after snapshot validation",
    )
    require_absent(
        bis_overlay,
        "cacheMythPreviewSnapshot(targetRow._entry, itemLink)",
        BIS_OVERLAY,
        "actual owned bag item links must not be promoted into Myth preview snapshot cache",
    )
    require_absent(
        bis_overlay,
        "_runtimeScore",
        BIS_OVERLAY,
        "the old checkbox-gated runtime ranking field must stay removed",
    )
    require_contains(
        bis_overlay,
        "ScoreItemSnapshotSecondaryPriority",
        BIS_OVERLAY,
        "verified Myth 1/6 snapshots should drive secondary-stat-priority preview ranking",
    )
    require_contains(
        runtime_scoring,
        "function Scoring:ScoreItemSnapshotSecondaryPriority",
        RUNTIME_SCORING,
        "secondary-stat-only snapshot scoring must be available to the overlay",
    )
    require_contains(
        runtime_scoring,
        "secondaryOnly = true",
        RUNTIME_SCORING,
        "secondary-stat ranking evidence must mark that primary stat and item level were excluded",
    )
    require_absent(
        bis_overlay,
        "ScoreItemSnapshot(specID",
        BIS_OVERLAY,
        "BIS overlay ranking should use secondary-stat-only preview scoring",
    )
    require_contains(
        bis_overlay,
        "BISRuntimeScoring",
        BIS_OVERLAY,
        "BIS overlay ranking must use the shared stat-priority scoring helper",
    )
    require_contains(
        bis_overlay,
        "PREVIEW_RANKING_SCORE_CACHE",
        BIS_OVERLAY,
        "preview ranking scores should be cached independently from tooltip rendering",
    )
    require_absent(
        bis_overlay,
        'if not isOverlayItemTooltipEnabled() or getEntrySourceType(entry) ~= "mythicplus" then',
        BIS_OVERLAY,
        "preview ranking score calculation must not depend on the item tooltip checkbox",
    )
    require_absent(
        bis_overlay,
        "if not isOverlayItemTooltipEnabled() or not C_Timer",
        BIS_OVERLAY,
        "preview ranking snapshot queue must not depend on the item tooltip checkbox",
    )
    require_absent(
        bis_overlay,
        "or not isOverlayItemTooltipEnabled()\n        or not BISOverlay.frame",
        BIS_OVERLAY,
        "preview ranking queue processing must not stop when tooltip rendering is disabled",
    )

    require_absent(
        stats_overlay,
        "PaperDollFrame_Set",
        STATS_OVERLAY,
        "StatsOverlay must not invoke Blizzard PaperDoll tooltip setters directly",
    )
    require_absent(
        stats_overlay,
        "PreparePaperDollTooltip",
        STATS_OVERLAY,
        "the removed direct PaperDoll tooltip preparation path must stay removed",
    )

    safe_number_body = get_safe_number_body(utils)
    if re.search(r"\breturn\s+value\b", safe_number_body):
        raise ValueError(
            "ABProfileManager/Utils.lua: Utils.SafeNumber must not return the original "
            "value when plain-number conversion fails"
        )
    if re.search(r"\bor\s+value\b", safe_number_body):
        raise ValueError(
            "ABProfileManager/Utils.lua: Utils.SafeNumber must not use the original "
            "value as a conversion fallback"
        )
    if not re.search(r"\breturn\s+0\b", safe_number_body):
        raise ValueError(
            "ABProfileManager/Utils.lua: Utils.SafeNumber must fall back to return 0 "
            "when plain-number conversion fails"
        )

    print(
        "ok: BIS tooltip contract uses Blizzard SetHyperlink rendering, "
        "requires verified Myth 1/6 snapshots, allows raid/crafted/tier base itemLink and bare itemID cache, "
        "tries verified raid/crafted/tier season preview links first, "
        "defaults the BIS item tooltip checkbox on, "
        "blocks removed manual renderers, "
        "renders M+ snapshots without re-feeding Myth links to GameTooltip, "
        "pauses Myth preview scans while bags are open, "
        "keeps secondary-stat preview ranking independent from the checkbox, "
        f"keeps BISOverlay top-level locals at {bis_top_level_locals}, "
        "and keeps SafeNumber fallback taint-safe"
    )


if __name__ == "__main__":
    main()
