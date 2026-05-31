# ABProfileManager v1.10.0

Release date: `2026-05-31`

This release adds the Midnight Season 1 BIS v1.3 offline inputs and one representative stat priority for each of the 40 specializations.

Direct download: `https://github.com/cronocros/ABProfileManager/releases/download/v1.10.0/ABProfileManager-v1.10.0.zip`
Local package: `dist/ABProfileManager-v1.10.0.zip`

## Changes

- **v1.3 offline generation inputs.**
  `DOC/MidnightS1_MPlus_Addon_Master_v1.3.md` and `DOC/MidnightS1_MPlus_Addon_DB_v1.3.lua` are now the offline BIS catalog generation inputs.
- **Normalized DB return placement.**
  The intermediate `return DB` was removed from the v1.3 DB. The file keeps one final `return DB` at EOF.
- **One representative priority for each specialization.**
  The stat overlay, stat-priority table, and BIS policy metadata now use one representative priority for each of the 40 specializations.
- **Localized English stat-priority table.**
  When the addon language is English, the stat-priority table now displays English priority text.
- **Single-policy cleanup.**
  The hidden M+-specific priority toggle no longer affects runtime selection or the overview. Its saved-variable compatibility key remains available.
- **3130 BIS rows retained.**
  The catalog retains `3130` rows: `mythicplus 2554`, `raid 285`, `crafted 91`, and `tier 200`.
- **Runtime score-policy scope separated.**
  v1.3 score policy is emitted as catalog metadata only. Connecting the real `itemLink`-based scoring engine remains follow-up design work.
- **v1.9.0 behavior retained.**
  Per-character, per-spec favorites and owned state, the top Favorites section, and owned-name strikethrough remain available.

## In-Game Regression Checklist

- Confirm the stat overlay and stat-priority table show one representative priority for all 40 specializations.
- Try every BIS source-filter combination and confirm visible ranks are recalculated.
- Disable raid and keep Mythic+ enabled, then confirm Mythic+ rows and dungeon names remain visible.
- Confirm favorite and owned state persists, favorites move to the top section, and owned names use strikethrough.
- Hover M+ items and confirm the M0 Champion 1/6 `246` preview.
- Confirm crafted and tier rows do not land in Encounter Journal and M+/raid landing remains guarded.
- Hover BIS items, then action-bar, Encounter Journal, and Pawn items, and confirm no `MoneyFrame.lua` error appears.

## Upgrading from a Previous Version

- No settings reset is required.
- Favorite and owned state saved by v1.9.0 remains available.
- The real link-based scoring engine is not connected in this release.
