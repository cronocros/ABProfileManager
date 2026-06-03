# ABProfileManager v1.10.0 -> v1.11.10 Update Announcement

Announcement baseline: `2026-06-03`

This announcement summarizes the English update notes for changes after `v1.10.0`, covering `v1.11.0` through `v1.11.10`.

Latest local version: `v1.11.10`
Local package: `dist/ABProfileManager-v1.11.10.zip`
Latest public GitHub release: `v1.11.0`
Public direct download: `https://github.com/cronocros/ABProfileManager/releases/download/v1.11.0/ABProfileManager-v1.11.0.zip`

## Major Changes Since v1.10.0

### 1. BIS Runtime Scoring from Real itemLinks

ABProfileManager now separates the static BIS candidate pool from runtime scoring.

- The static BIS catalog remains stable at `3130` rows.
- Mythic+ candidates: `2554`
- Raid candidates: `285`
- Crafted candidates: `91`
- Tier candidates: `200`
- When a real equipped or bag `itemLink` is available, ABPM scores it using actual item level and actual item stats.
- Candidates without a verified runtime link keep their deterministic static order.
- Final BIS decisions still require class context, tier effects, trinket/weapon effects, SimC, QE, or log review.

### 2. Mythic+ Myth 1/6 272 Preview and Snapshot Cache

The BIS overlay can now show Mythic+ recommendations using a verified seasonal preview path.

- M+ Great Vault / Voidcore preview target: `Myth 1/6`, item level `272`.
- The preview selector is stored locally in `Data/BISMythicVaultLinks.lua`.
- ABPM verifies that the generated or overridden link resolves to `Myth 1/6 272`.
- Verified tooltip lines, item level, and stats are stored in the account SavedVariables snapshot cache.
- Once cached, the overlay reuses the snapshot instead of scanning repeatedly.
- Wrong item-level previews are rejected for the session to reduce repeated loading.

### 3. Original Blizzard Item Tooltips for BIS Hover

BIS item hover has been moved back to Blizzard's original item tooltip renderer where possible.

- Verified M+ snapshots are passed to an addon-owned Blizzard item tooltip through `SetHyperlink()`.
- The tooltip uses the original Blizzard item display, including secondary stats.
- The BIS tooltip uses a shopping-tooltip path to suppress sell-price `MoneyFrame` rendering.
- This keeps the original item tooltip experience while reducing the `MoneyFrame.lua secret number` taint path.

### 4. Raid, Tier, and Crafted Preview Support

Raid, tier, and crafted BIS rows now try seasonal preview links before falling back to base links.

- Raid and tier previews must resolve to the seasonal Myth range, item level `272~289`.
- Raid and tier previews must also include `Myth` or Korean `신화` text in the resolved tooltip.
- Crafted previews target crafted R5 item level `285`.
- If preview validation fails, ABPM falls back to Blizzard's normal `itemLink` or `item:<itemID>` tooltip path.
- The preview templates are managed in `Data/BISSeasonPreviewLinks.lua`.

### 5. BIS Item Tooltip Toggle Defaults On

The top BIS overlay item-tooltip checkbox is now enabled by default.

- New SavedVariables default to item tooltips enabled.
- Existing settings are migrated on once.
- If the user turns the checkbox off manually, that choice is preserved.

### 6. Safer Encounter Journal Landing

Mythic+ Encounter Journal landing has been hardened.

- ABPM uses verified Midnight Season 1 `JournalInstanceID` values.
- It preselects the current season tier before landing.
- It does not call protected `C_EncounterJournal.SetTab` directly.
- Combat lockdown skips automatic landing to avoid Blizzard protected-function popup warnings.
- Crafted and tier rows remain non-landing rows.

### 7. Scroll and Rebuild Throttling Improvements

The BIS overlay received several performance-focused changes.

- Hover tooltip rendering is suppressed briefly during scrolling.
- Item requests are deduplicated.
- Rebuilds are debounced and visible-row updates are preferred.
- Equipped and bag links are not rescanned during sorting or hover.
- Bag/equipment links are only used for owned-state storage when requested.

### 8. Taint and Load-Failure Fixes

Several defensive fixes were added for WoW 12.0.5+ tooltip and secret-number behavior.

- Unused `PaperDollFrame_Set*` tooltip setter paths were removed from the Stats Overlay.
- `SafeNumber()` no longer returns original secret values when conversion fails.
- BIS item tooltips avoid sell-price `MoneyFrame` rendering.
- `v1.11.10` fixes the `main function has more than 200 local variables` BISOverlay load error.
- Tooltip contract validation now checks the BISOverlay top-level local count to prevent regression.

## Version Summary

### v1.11.0

- Connected the Midnight Season 1 v1.7 runtime scoring core.
- Added real item-level and stat scoring when a real owned `itemLink` is available.
- Kept deterministic static ordering for candidates without links.
- Preserved the `3130` row BIS catalog.
- Limited equipped-slot and bag scanning to once per overlay rebuild.

### v1.11.1

- Improved BIS tooltip color preservation.
- Added verified Myth 1/6 272 link handling for automatic scoring.
- Reduced hidden Encounter Journal and MoneyFrame taint paths.
- Added rebuild throttling and item-request deduplication around BIS scoring.

### v1.11.2

- Suppressed row hover tooltip rendering during scroll.
- Reused SavedVariables tooltip/stat snapshots instead of rescanning every hover.
- Removed highest-bag-link sorting priority.
- Removed bag/equipment events that caused full BIS rebuilds.

### v1.11.3

- Added automatic M+ Myth 1/6 272 preview item string generation from the reviewed selector.
- Added selector-template cache invalidation.
- Rejected previews that resolved to the wrong item level.

### v1.11.4

- Fixed M+ Encounter Journal landing with verified current-season instance IDs.
- Added season-tier preselection and availability guards.
- Retried unloaded preview links through bounded async item loading.

### v1.11.5

- Removed direct protected `C_EncounterJournal.SetTab` usage.
- Skipped automatic Encounter Journal landing during combat to prevent protected-function popup warnings.

### v1.11.6

- Switched M+ BIS hover to addon-owned Blizzard item tooltips with verified `Myth 1/6 272` snapshots.
- Blocked sell-price `MoneyFrame` rendering on BIS item tooltips.
- Removed unused StatsOverlay PaperDoll setter paths.
- Hardened `SafeNumber()` fallback behavior.

### v1.11.7

- Extended Blizzard item tooltip support to raid, crafted, and tier rows.
- Reused loaded base item links in a session cache.
- Kept M+ snapshot behavior unchanged.

### v1.11.8

- Enabled the BIS item tooltip checkbox by default.
- Added migration for existing SavedVariables.
- Added bare `item:<itemID>` fallback for first-hover tier and base item tooltip cases.

### v1.11.9

- Added `Data/BISSeasonPreviewLinks.lua`.
- Added seasonal preview support for raid Myth, tier Myth, and crafted R5 285 tooltips.
- Required raid/tier previews to verify Myth text and seasonal item-level range.
- Required crafted previews to verify item level `285`.

### v1.11.10

- Fixed the BISOverlay load failure caused by crossing WoW Lua's main-function local variable limit.
- Moved season-preview state and helpers into the `SourcePreview` table.
- Added validation for the BISOverlay top-level local count.

## Recommended Checks After Updating

- Open the BIS overlay and switch specializations.
- Try all `Mythic+ / Raid / Crafted / Tier` filter combinations.
- Hover M+ BIS items and confirm the `Myth 1/6 272` Blizzard tooltip appears after validation.
- Hover raid, tier, and crafted rows and confirm seasonal previews or fallback tooltips display correctly.
- Confirm the top item-tooltip checkbox is enabled by default.
- Scroll the BIS list and confirm hover tooltips no longer cause heavy stutter.
- Click Mythic+ sources outside combat and confirm Encounter Journal landing works.
- Click during combat and confirm no Blizzard protected-function popup appears.
- Confirm crafted and tier rows do not trigger Encounter Journal landing.
- After BIS hover, inspect action-bar and Encounter Journal item tooltips and confirm the `MoneyFrame.lua secret number` error does not recur.

## Updating

- No settings reset is required.
- Favorite and owned state saved since `v1.9.0` remains available.
- Replace the addon folder with the latest package, then run `/reload` or reconnect.
