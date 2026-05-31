# ABProfileManager v1.7.7 -> v1.11.0 Major Update Announcement

Release baseline: `2026-06-01`

Since the `v1.7.7` baseline, ABProfileManager has received a major BIS recommendation update. This announcement summarizes the cumulative changes delivered from `v1.8.0` through `v1.11.0`.

Latest version: `v1.11.0`
Direct download: `https://github.com/cronocros/ABProfileManager/releases/download/v1.11.0/ABProfileManager-v1.11.0.zip`

## Major Changes

### 1. Refreshed Midnight Season 1 BIS Recommendations

The BIS recommendation catalog has been regenerated from the latest Midnight Season 1 offline inputs.

- Mythic+ and tier candidates were refreshed for all `40 specializations`.
- Existing raid `285` rows and crafted `91` rows were preserved so that data absent from the new source was not lost.
- The current BIS catalog contains `3130` rows.
  - Mythic+: `2554`
  - Raid: `285`
  - Crafted: `91`
  - Tier: `200`
- At runtime, the addon reads only `Data/BISCatalog.lua`. It does not perform web lookups, runtime merging, or runtime normalization.

The same Mythic+ `itemID` can have different upgrade tracks and stats depending on how the item was obtained. The catalog therefore no longer guesses static item links or bonusIDs.

- End-of-dungeon candidate: `Hero 3/6`, item level `266`
- Great Vault/Voidcore candidate: `Myth 1/6`, item level `272`
- An `itemID` alone does not prove final BIS status, Hero/Myth track, or final stats.
- Final decisions should be checked against the real item link and simulation results.

### 2. Redesigned BIS Overlay with Validation Context

The BIS Overlay has moved from a simple recommendation list to a compact list that shows source and validation context.

- Select a specialization and filter `Mythic+ / Raid / Crafted / Tier` sources from the header.
- The header shows the selected specialization's stat priority and validation summary.
- Each row shows icon, item name, slot, source, reward track, validation state, and filtered rank.
- Changing filters recalculates `Rank 1 / Rank 2 / Rank 3+` from the currently visible list.
- Tooltips separate Base ItemID, reward profile, runtime-link requirement, Myth-track candidate/verification state, and simulation guidance.

Existing safety behavior remains in place.

- The overlay does not call `GameTooltip:SetHyperlink()` directly.
- Mythic+ and raid rows land on Encounter Journal loot when possible.
- Crafted and tier rows do not trigger Encounter Journal landing.
- Item-info events refresh only currently visible rows.

### 3. Favorite and Owned Gear Tracking

The BIS list can now be used as a practical farming checklist.

- Each item row has `Favorite` and `Owned` checkboxes before the item icon.
- Favorite items move into a top `Favorites` section above `Weapon`.
- Owned item names are displayed with a strikethrough.
- Favorite and owned state is stored `per character and specialization`.
- State persists across relogging and `/reload`.
- Checkmarks now use Blizzard's standard checkbox texture instead of small text markers.
- Owned-name strikethrough renders on a foreground layer for clearer visibility.

### 4. Improved Mythic+ Item Preview

Hovering a Mythic+ BIS row uses the Encounter Journal Mythic dungeon preview context.

- Encounter Journal Mythic dungeon/M0 context
- `Champion 1/6`
- Item level `246`

This shows the dungeon-journal item information without inventing a static item link.

### 5. Updated Stat Priorities for All 40 Specializations

The stat overlay and stat-priority table have also been updated.

- One representative stat priority is available for all `40 specializations`.
- The same priority is attached to BIS policy metadata.
- The hidden M+-specific priority branch was removed.
- SavedVariables compatibility keys remain available, so no settings reset is required.
- When the addon language is English, the stat-priority table displays English text.
- Korean BIS reward-track labels are localized as `영웅 / 신화`.

### 6. Runtime Score Ordering from Real Owned itemLinks

Starting with v1.11.0, the static candidate pool and real-link scoring are separate layers.

- The static pool remains `3130` rows.
- Candidates with links found in equipped slots or bags are ordered against each other by real item-level and stat scores from the v1.7 core.
- Candidates without a real link retain the existing static order.
- Equipped slots and bags are indexed once per overlay rebuild.
- Final BIS decisions still require tier, trinket/weapon effect, SimC, QE, or log review.

## Version Summary

### v1.8.0

- Regenerated Midnight Season 1 Mythic+/tier BIS candidates
- Preserved existing raid and crafted data
- Introduced runtime-link validation and no-static-final-BIS policy
- Redesigned BIS Overlay header, rows, and tooltip information structure

### v1.9.0

- Added per-character, per-spec favorite and owned checks
- Added the top Favorites section
- Added owned-name strikethrough
- Added Mythic+ M0 `Champion 1/6 246` tooltip preview

### v1.10.0

- Applied the latest BIS v1.3 offline inputs
- Updated one representative stat priority for all 40 specializations
- Localized the stat-priority table when English is selected
- Improved favorite/owned checkbox and strikethrough legibility
- Localized Korean BIS `Hero / Myth` track labels
- Simplified regular BIS hover tooltips to focus on slot, source, and current rank
- Made owned rows prefer the real item tooltip found in equipped slots or bags

### v1.11.0

- Connected the MidnightS1 M+ Addon v1.7 compact runtime scoring core
- Applied real stat/item-level scores to slot ordering when a real owned `itemLink` is available
- Kept deterministic static fallback for candidates without a link
- Limited equipped-slot and bag scanning to once per rebuild
- Updated all 40 stat priorities and the validation scripts

## Recommended Checks After Updating

- Open and close the BIS Overlay, then switch specializations.
- Try `Mythic+ / Raid / Crafted / Tier` filter combinations.
- Disable raid and leave only Mythic+ enabled; confirm Mythic+ rows and dungeon names remain visible.
- Check favorite/owned state, then relog or run `/reload`.
- Confirm favorites move to the top and owned names use strikethrough.
- Hover Mythic+ items and confirm the M0 `Champion 1/6 246` preview.
- Click Mythic+/raid sources and confirm Encounter Journal landing.
- Click crafted/tier rows and confirm they do not trigger landing.
- Switch between Korean and English and verify BIS and stat-priority labels.

## Updating

- No settings reset is required.
- Favorite and owned state saved since `v1.9.0` remains available.
- Replace the addon folder with the latest version, then run `/reload` or reconnect.
