# ABProfileManager v1.9.0

Release date: `2026-05-31`

This release adds per-character, per-spec BIS favorites and owned state, plus an M+ M0 tooltip preview.

Direct download: `https://github.com/cronocros/ABProfileManager/releases/download/v1.9.0/ABProfileManager-v1.9.0.zip`
Local package: `dist/ABProfileManager-v1.9.0.zip`

## Changes

- **Favorite and owned checkboxes.**
  Checkboxes before each item icon persist state per character and specialization.
- **Favorites section.**
  Favorited items move into a top Favorites section above Weapon.
- **Owned display.**
  Owned item names are shown with a strikethrough.
- **M+ M0 tooltip preview.**
  M+ item hover preview uses the Encounter Journal Mythic dungeon/M0 Champion 1/6 `246` context.
- **Existing safety policy remains.**
  Direct `GameTooltip:SetHyperlink()` calls remain prohibited. Source filters, crafted/tier non-landing, and M+/raid Encounter Journal guards are preserved.

## In-Game Regression Checklist

- Confirm favorite and owned state persists across character and specialization swaps.
- Confirm favorites move to the top section and owned names use strikethrough.
- Hover M+ items and confirm the M0 Champion 1/6 `246` preview.
- Try every source filter combination and confirm crafted/tier rows do not land in Encounter Journal.
- Hover BIS items, then action-bar, Encounter Journal, and Pawn items, and confirm no `MoneyFrame.lua` error appears.

## Upgrading from a Previous Version

- SavedVariables for BIS favorite and owned state are added on demand.
- No settings reset is required.
