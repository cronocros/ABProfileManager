# ABProfileManager v1.10.0 -> v1.11.11 Update Announcement

Announcement baseline: `2026-06-21`

This announcement summarizes the English update notes for changes after `v1.10.0`, covering `v1.11.0` through `v1.11.11`.

Latest local version: `v1.11.11`
Local package: `dist/ABProfileManager-v1.11.11.zip`
Latest public GitHub release: `v1.11.0`
Public direct download: `https://github.com/cronocros/ABProfileManager/releases/download/v1.11.0/ABProfileManager-v1.11.0.zip`

## Latest v1.11.11 Changes

- Added WoW 12.0.7 `Sporefall` raid BIS candidates from `Rotmire`.
- Expanded the static BIS catalog to `3330` rows: `mythicplus 2554`, `raid 485`, `crafted 91`, and `tier 200`.
- Re-ranked new raid candidates by armor eligibility, shared jewelry/trinket slots, and v1.7 stat-priority policy.
- Extended raid Myth preview validation through item level `298`.
- Added `Sporefall / Rotmire` locale labels for BIS source and hover display.
- Hardened 12.0.7 compatibility around secret-number conversion, Encounter Journal tier fallback, Warband Bank session detection, action-bar cursor mutations, and Delve/PVE refresh calls.

## Major Changes Since v1.10.0

### 1. BIS Runtime Scoring from Real itemLinks

ABProfileManager separates the static BIS candidate pool from runtime scoring.

- The static BIS catalog now contains `3330` rows.
- Mythic+ candidates: `2554`
- Raid candidates: `485`
- Crafted candidates: `91`
- Tier candidates: `200`
- When a real equipped or bag `itemLink` is available, ABPM scores it using actual item level and actual item stats.
- Candidates without a verified runtime link keep their deterministic static order.
- Final BIS decisions still require class context, tier effects, trinket/weapon effects, SimC, QE, or log review.

### 2. Mythic+ Myth 1/6 272 Preview and Snapshot Cache

- M+ Great Vault / Voidcore preview target: `Myth 1/6`, item level `272`.
- The preview selector is stored locally in `Data/BISMythicVaultLinks.lua`.
- Verified tooltip lines, item level, and stats are stored in the account SavedVariables snapshot cache.
- Once cached, the overlay reuses the snapshot instead of scanning repeatedly.

### 3. Raid, Tier, and Crafted Preview Support

- Raid previews must resolve to the seasonal Myth range, now allowing item level `272~298`.
- Tier previews keep the existing seasonal Myth range, item level `272~289`.
- Raid and tier previews must include `Myth` or Korean `신화` text in the resolved tooltip.
- Crafted previews target crafted R5 item level `285`.
- If preview validation fails, ABPM falls back to Blizzard's normal `itemLink` or `item:<itemID>` tooltip path.

### 4. Safer Tooltip and Encounter Journal Behavior

- Verified M+ snapshots are passed to an addon-owned Blizzard item tooltip through `SetHyperlink()`.
- BIS item tooltips use a shopping-tooltip path to suppress sell-price `MoneyFrame` rendering.
- M+ Encounter Journal landing uses verified Midnight Season 1 instance IDs.
- Combat lockdown skips automatic landing to avoid Blizzard protected-function popup warnings.
- Crafted and tier rows remain non-landing rows.

## Version Summary

### v1.11.11

- Added Sporefall / Rotmire raid BIS candidates for WoW 12.0.7.
- Expanded the BIS catalog to `3330` rows.
- Added raid Myth item level `298` preview support.
- Hardened several 12.0.7 client API paths.

### v1.11.10

- Fixed the BISOverlay load failure caused by crossing WoW Lua's main-function local variable limit.
- Moved season-preview state and helpers into the `SourcePreview` table.
- Added validation for the BISOverlay top-level local count.

### v1.11.9

- Added `Data/BISSeasonPreviewLinks.lua`.
- Added seasonal preview support for raid Myth, tier Myth, and crafted R5 285 tooltips.
- Required raid/tier previews to verify Myth text and seasonal item-level range.
- Required crafted previews to verify item level `285`.

### v1.11.0 - v1.11.8

- Connected the Midnight Season 1 v1.7 runtime scoring core.
- Added verified M+ `Myth 1/6 272` preview snapshots.
- Added Favorite / Owned BIS state and safer item tooltip behavior.
- Hardened Encounter Journal landing and scroll/rebuild throttling.

## Recommended Checks After Updating

- Open the BIS overlay and switch specializations.
- Try all `Mythic+ / Raid / Crafted / Tier` filter combinations.
- Confirm `Sporefall / Rotmire` appears under Raid candidates.
- Hover M+ BIS items and confirm the `Myth 1/6 272` Blizzard tooltip appears after validation.
- Hover raid, tier, and crafted rows and confirm seasonal previews or fallback tooltips display correctly.
- Click Mythic+ sources outside combat and confirm Encounter Journal landing works.
- Click during combat and confirm no Blizzard protected-function popup appears.
- Confirm StatsOverlay, Warband Bank handling, action-bar apply, and Delve/PVE overlays still work on the 12.0.7 client.

## Updating

- No settings reset is required.
- Favorite and owned state saved since `v1.9.0` remains available.
- Replace the addon folder with the latest package, then run `/reload` or reconnect.
