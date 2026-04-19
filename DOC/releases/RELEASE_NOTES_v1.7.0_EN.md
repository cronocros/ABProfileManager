# ABProfileManager v1.7.0

Release date: `2026-04-18`

Direct download: `https://github.com/cronocros/ABProfileManager/releases/download/v1.7.0/ABProfileManager-v1.7.0.zip`
Local package: `dist/ABProfileManager-v1.7.0.zip`

## Summary

This release rebuilds the Midnight Season 1 BIS overlay into a source-aware static catalog.

The old `single overall BIS + runtime fallback` model has been replaced with a generated catalog that keeps `Mythic+ / Raid / Crafted / Tier` candidates alive after filtering, then re-numbers the visible recommendations per slot.

This maintenance repack also closes locale leak paths and aligns the overlay header controls.

## Highlights

- Introduced `Data/BISCatalog.lua` as the single runtime BIS data source
- Expanded the pipeline to cover all 40 specs for Midnight Season 1
- Added four default-on filters: `mythicplus / raid / crafted / tier`
- Recomputed `#1 / #2 / #3+` from the visible list after filters are applied
- Kept Mythic+ item rows and dungeon labels visible when `raid` is disabled and only `mythicplus` is enabled
- Stored validated `koKR/enUS` item names and source labels separately to reduce locale leakage
- Preserved Encounter Journal landing only for `mythicplus` and `raid`; `crafted` and `tier` stay non-journal rows
- Added `scripts/build_bis_catalog.py`
- Updated the BIS seed refresh scripts to the 40-spec baseline

## Maintenance Repack (2026-04-19)

- Hardened BIS boss/source/dungeon locale paths so `enUS` no longer falls back to Hangul in the remaining legacy rows
- Switched BIS spec/class labels, StatsOverlay, ProfilePanel, and ConfigPanel to addon-locale class/spec names instead of raw client-locale API strings
- Kept the BIS tooltip cursor-anchored and preserved WoW-style item coloring while retaining the current season source/boss/track summary
- Split Mythic+ and Delve row labels in `ItemLevelOverlay` by locale (`+2`, `Tier 11` / `2단`, `11단계`)
- Updated `MythicPlusRecordOverlay` dungeon line-break rules for both Korean and English display paths
- Added `L / collapse` header controls with hover help to the profession overlay, alongside the existing view-mode toggle
- Synced `README`, `ADDON_INTRO`, `CHANGELOG`, and the Korean release notes to the current maintenance state

## Data Notes

Primary local seeds:

- `DOC/wow_midnight_s1_mplus_bis_final.md`
- `DOC/wow_midnight_s1_mplus_bis_korean_companion.md`

Those documents are treated as seed inputs, not final truth. The final exported catalog prefers verified item IDs and validated names from the external verification path.

## Validation

- Verified 40 specs are present
- Verified required row fields: `itemID, slot, sourceGroup, overallRank, sourceRank`
- Re-checked `koKR` for English leaks and hardened the runtime paths that were still leaking Hangul in `enUS`
- Ran full Lua parsing with `luaparser`
- Ran `git diff --check`
- Built the release package

## Known Notes

- Direct Encounter Journal instance IDs for `Maisara Hills` and `Windrunner Spire` still need additional confirmation.
- `Key Shards` may still display as `-` until Blizzard exposes a stable item ID path.
