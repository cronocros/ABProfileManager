# ABProfileManager v1.7.4

WoW Patch 12.0.7 compatibility repack — TOC Interface 120005/120007, tooltip MoneyFrame hardening, M+ BIS reward tracks, the stat-priority table, and client-based language defaults.

Direct download: `https://github.com/cronocros/ABProfileManager/releases/download/v1.7.4/ABProfileManager-v1.7.4.zip`
Local package: `dist/ABProfileManager-v1.7.4.zip`

## Changes

### WoW 12.0.7 Compatibility

- **Updated the TOC Interface metadata to `120005, 120007`.**
  ABProfileManager now retains 12.0.5 compatibility while adding the 12.0.7 client line, so users do not need to enable out-of-date addons.
- **Reviewed the 12.0.7-sensitive UI/API paths used by ABPM.**
  Tooltip ownership, Encounter Journal landing, PVE/Mythic+ overlays, currency lookups, PaperDoll stat tooltip setters, aura reads, and Warband Bank checks were re-checked statically. No additional code change was required beyond the existing guarded calls and tooltip hardening.
- **Kept stat-priority data at the documented Patch 12.0.5 baseline.**
  This repack updates client compatibility metadata; it does not claim a new 12.0.7 class/stat tuning pass.

### Tooltip / MoneyFrame Fixes

- **Fixed a Blizzard `MoneyFrame.lua` secret-number error path.**
  Action bar item hovers, Encounter Journal item hovers, and Pawn comparison tooltips could surface `attempt to perform arithmetic on a secret number value (execution tainted by 'ABProfileManager')` after ABPM had owned the global tooltip. ABPM hover text now uses addon-owned tooltip frames instead.
- **Removed direct global `GameTooltip` usage from ABPM hover text.**
  Shared UI helpers now provide `ABProfileManagerTooltip`, keeping addon explanations out of Blizzard's normal item tooltip ownership path.
- **Hardened BIS item hover preview.**
  BIS rows no longer call `GameTooltip:SetHyperlink()` for item preview. They read `C_TooltipInfo.GetHyperlink()` data, render text lines into an addon tooltip, and skip sell-price / money / currency lines so `MoneyFrame_Update` is not involved.

### BIS Overlay

- **Added Mythic+ reward profile guidance.**
  M+ BIS rows now show representative reward tracks such as end-of-dungeon Hero 3/6 item level 266 and Great Vault / Voidcore Myth 1/6 item level 272.
- **Regenerated and validated the BIS catalog.**
  `Data/BISCatalog.lua` now carries reward profile references, and the build/validation scripts check those references before release.
- **Cleaned up item/source labels.**
  Korean and English labels were refreshed against the current static data.

### Stat Priority Table

- **Added a main-window `Stat Priority Table` button.**
  The new popup lists primary and secondary stat priorities by class and specialization.
- **Updated Patch 12.0.5 data for all 40 specs.**
  Hero talent, raid/M+, single-target, and AoE branches are shown directly in the table when applicable. The current player's specialization row is highlighted.
- **Updated the short stat-priority line used by the stats overlay.**
  The overlay keeps its compact display, while the new table exposes the full branch detail.

### Language Defaults / Fallback

- **First install now follows the WoW client language when supported.**
  Korean clients still default to Korean. English clients (`enUS`, `enGB`) and currently unsupported locales open in English.
- **Existing affected English users are migrated once.**
  If an older version saved the accidental Korean default on an English client, ABPM switches it to English once unless the user explicitly selected Korean.
- **Fallback order now prefers English before Korean.**
  Locale lookup uses selected language -> English -> Korean -> key.
- **ruRU PR #2 is not merged in this repack.**
  Russian localization remains a separate PR review item and should be integrated into the native locale structure instead of a runtime monkey patch.

### Included Earlier v1.7.4 Stability Work

- Secondary stats no longer collapse to `0` in combat when the client returns secret-protected numeric values.
- Aura hash arithmetic is sanitized so a secret-protected aura entry cannot break stats refresh.
- `ns:SafeCall(...)` wraps optional module dispatch in `pcall`.
- Ghost retry debug logging is state-change based instead of flooding the debug buffer in combat.

## Announcement Summary

ABProfileManager v1.7.4 maintenance update:

- Updated for the WoW Retail 12.0.7 client line while retaining 12.0.5 support (`Interface: 120005, 120007`), so users do not need to enable out-of-date addons.
- Fixed the possible `MoneyFrame.lua secret number` error on action bar / Encounter Journal / Pawn item tooltips.
- Switched BIS item hover preview to a safer addon-owned tooltip renderer.
- Added M+ BIS reward track and item-level guidance.
- Added a Patch 12.0.5 baseline stat-priority table for all 40 specs.
- English clients now open in English by default. Korean clients still default to Korean.
- Existing affected English users are migrated once from the accidental Korean default to English.

## In-Game Regression Checklist

- [ ] Hover BIS item rows.
- [ ] Hover action bar item/equipment buttons after using ABPM UI.
- [ ] Hover Encounter Journal items and Pawn comparison tooltips.
- [ ] Confirm items with sell prices no longer trigger `MoneyFrame.lua` errors.
- [ ] Confirm WoW 12.0.5/12.0.7 clients load ABPM without the out-of-date addon warning.
- [ ] Open the `Stat Priority Table` popup and confirm the current spec row is highlighted.
- [ ] Fresh enUS/enGB clients open ABPM in English.
- [ ] Fresh koKR clients open ABPM in Korean.
- [ ] An enUS user who explicitly selected Korean keeps Korean after reload.
- [ ] Existing v1.7.3/v1.7.4 stability behavior continues to work: stats refresh, ghost cleanup, BIS source labels.

## Upgrading from a Previous Version

- Existing saved data (`ABPM_DB`) is preserved.
- No settings reset is required.
- Existing English-client users affected by the accidental Korean default migrate to English once, unless Korean was explicitly selected.
- This is a same-tag v1.7.4 maintenance repack. If you already downloaded v1.7.4, replace it with the latest ZIP.
