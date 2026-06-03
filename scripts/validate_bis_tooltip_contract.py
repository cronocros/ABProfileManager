"""Validate static contracts for BIS hover tooltips and taint-safe number handling."""

from __future__ import annotations

import re
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[1]
BIS_OVERLAY = REPO_ROOT / "ABProfileManager" / "UI" / "BISOverlay.lua"
STATS_OVERLAY = REPO_ROOT / "ABProfileManager" / "UI" / "StatsOverlay.lua"
UTILS = REPO_ROOT / "ABProfileManager" / "Utils.lua"
DB = REPO_ROOT / "ABProfileManager" / "DB.lua"
DEFAULTS = REPO_ROOT / "ABProfileManager" / "Data" / "Defaults.lua"


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


def main() -> None:
    bis_overlay = BIS_OVERLAY.read_text(encoding="utf-8")
    stats_overlay = STATS_OVERLAY.read_text(encoding="utf-8")
    utils = UTILS.read_text(encoding="utf-8")
    db = DB.read_text(encoding="utf-8")
    defaults = DEFAULTS.read_text(encoding="utf-8")

    require_contains(
        bis_overlay,
        "tooltip.isShopping = true",
        BIS_OVERLAY,
        "addon-owned Blizzard tooltips must skip MoneyFrame sell-price rendering",
    )
    require_contains(
        bis_overlay,
        "tooltip.SetHyperlink",
        BIS_OVERLAY,
        "BIS hover must use Blizzard's hyperlink tooltip renderer",
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
        "and keeps SafeNumber fallback taint-safe"
    )


if __name__ == "__main__":
    main()
