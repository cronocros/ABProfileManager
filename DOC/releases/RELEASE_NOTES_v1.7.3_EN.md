# ABProfileManager v1.7.3

WoW Patch 12.0.5 (Midnight .5) — Stats overlay reliability, bulk ghost cleanup, and a 12.0.5 BIS catalog re-verification.

Direct download: `https://github.com/cronocros/ABProfileManager/releases/download/v1.7.3/ABProfileManager-v1.7.3.zip`
Local package: `dist/ABProfileManager-v1.7.3.zip`

## Changes

### Bug Fixes — Stats Overlay

- **Fixed: secondary stats stuck at 0 after entering an instance.**
  On `PLAYER_ENTERING_WORLD` / `ZONE_CHANGED_NEW_AREA` the PaperDoll API can return `0` momentarily; that `0` was being cached as the state signature and the overlay would then refuse to refresh. The overlay now invalidates its cache via `StatsOverlay:InvalidateState()` on those events and schedules a short-delay follow-up force refresh, so values redraw the moment the API populates real numbers.
- **Fixed: trinket on-use / external buff effects not refreshing in real time.**
  `BuildStateSignature` now includes a player buff hash (`spellId:expirationTime:applications` over slots 1..40 of the `HELPFUL` filter). Trinket procs, potions, and outside buffs all flip the hash, which invalidates the cache even when the displayed stats happen to look identical. The `UNIT_AURA` debounce is also tightened from 0.45s (slow) to 0.15s (normal) so on-use procs surface immediately.
- **Forced refresh on equipment / spec changes.**
  `PLAYER_EQUIPMENT_CHANGED` and `PLAYER_SPECIALIZATION_CHANGED` now go through a force-refresh path so swap-in items and spec swaps no longer lag the visible numbers by a beat.
- **New event registrations.**
  `ZONE_CHANGED_NEW_AREA`, `PLAYER_ENTER_COMBAT`, and `PLAYER_LEAVE_COMBAT` are now subscribed to plug the gaps where the overlay previously could miss a refresh.

### New Feature — Bulk Ghost Cleanup

- A new **`Clear All Ghosts`** button has been added at the bottom of the Action Bars tab → sync section.
- A single click dismisses every ghost (unavailable-action) marker on the action bars at once. Real spell / macro / item assignments are not touched.
- Useful when residual ghosts pile up after sync runs or after spec swaps that leave many unavailable actions behind.
- Adds `ActionBarApplier:DismissAllPendingGhosts()`; the overlay is then redrawn via `GhostManager:RefreshGhosts()`.
- Locale keys added in both English and Korean: `ghost_clear_all_button / ghost_clear_all_tip / ghost_clear_all_long / ghost_clear_all_none / ghost_clear_all_done`.

### Data — BIS Catalog 12.0.5 Source Re-verification

- `Data/BISCatalog.lua` source labels were re-checked against external guides (Icy Veins / Method / Wowhead / Maxroll) using the WoW Patch 12.0.5 (Midnight .5, 2026-04-23) hotfix data.
- Resolved a 4-way conflict where every The Voidspire raid boss was being shown as `displaySourceKoKR = "공허 첨탑"` (Korean) — they were indistinguishable in the UI.
  - `Lightblinded Vanguard` → `빛에 눈먼 선봉대`
  - `Crown of the Cosmos` → `우주의 왕관`
  - `Fallen-King Salhadaar` → `몰락한 왕 살하다르`
  - `The Voidspire` (raid umbrella label) → kept as `공허 첨탑`
- Other Midnight Falls raid boss labels (`Belo'ren`, `Vorasius`, `Chimaerus`, `Vaelgor & Ezzorak`, `Midnight Falls`) checked clean.
- The existing BIS runtime contract — single source of truth in `Data/BISCatalog.lua`, four `sourceGroup` filters, re-numbering of priorities against the visible candidate list — is unchanged.

### Adjacent Stability Fixes

- `Modules/ProfessionKnowledgeTracker.lua`: `C_QuestLog.GetAllCompletedQuestIDs` is now called via `pcall`. In some 12.0.5 environments this API can throw and was breaking the profession-knowledge refresh cycle silently.
- `UI/BISOverlay.lua`:
  - Added a `SOURCE_GROUP_ORDER` table so `table.sort` produces a deterministic `mythicplus → raid → tier → crafted` ordering.
  - The BIS preview ilvl range check now bypasses for Timewalking dungeons (instance difficulty `24`), where items are intentionally scaled down and would otherwise be flagged as out-of-range.

### Follow-up — Scheduled for v1.7.4

- Spec-by-spec trinket priority rerolls for items whose value shifted under the 12.0.5 hotfixes (e.g. `Light Company Guidon`, `Shadow of the Empyrean Requiem`, `Light of the Cosmic Crescendo`) will land in v1.7.4 after a SimC re-verification pass.
- Until then, BIS overlay source / boss labels are correctly disambiguated; the actual in-game usefulness of any individual trinket is not affected by this release.

## Technical Notes

### Stats overlay signature

`UI/StatsOverlay.lua` `BuildStateSignature` was extended with two new axes:

- `IsInInstance()` (`inInstance` / `instanceType`) so instance context itself participates in the signature.
- A player buff hash built from `C_UnitAuras.GetAuraDataByIndex("player", index, "HELPFUL")` over slots 1..40, serialized as `spellId:expirationTime*10:applications`. Any change in any helpful aura's expiration timestamp shifts the hash, so trinket / consumable / external buffs invalidate the cache even when the resulting numeric stats happen to be identical.

`Refresh(options)` accepts a new `{ force = true }` option that bypasses both `lastStateSignature` and `lastSnapshotSignature`. `StatsOverlay:InvalidateState()` is also exposed for explicit cache busting from event handlers.

### Bulk ghost dismissal

`ActionBarApplier:DismissAllPendingGhosts()` walks `pendingGhosts`, clears every entry, and asks `GhostManager:RefreshGhosts()` to repaint. It returns the number of ghosts removed so the panel can show "no ghosts to clear" when the count is zero.

## In-Game Regression Checklist

- [ ] `/abpm` → `Action Bars` tab → sync section bottom row shows `Clear All Ghosts`, and a single click dismisses any leftover ghosts.
- [ ] Right after entering an instance, the four secondary stats (crit/haste/mastery/versatility) populate immediately rather than sitting at `0`.
- [ ] Activating a trinket on-use (instant proc style) updates the secondary stat readout within ~0.2s.
- [ ] After a spec change or equipment swap, item level and secondary stat lines follow within one tick.
- [ ] BIS overlay source / boss labels read correctly under Patch 12.0.5.

## Upgrading from a Previous Version

- Existing saved data (`ABPM_DB`) is preserved.
- No settings reconfiguration required.
- One additional button row appears in the Action Bars sync panel.
