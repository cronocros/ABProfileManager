# ABProfileManager v1.7.4

WoW Patch 12.0.5 — Stats overlay combat-zero fix + addon-wide secret number hardening.

Direct download: `https://github.com/cronocros/ABProfileManager/releases/download/v1.7.4/ABProfileManager-v1.7.4.zip`
Local package: `dist/ABProfileManager-v1.7.4.zip`

## Changes

### Bug Fixes — Stats Overlay

- **Fixed: secondary stats displaying as `0` while in combat.**
  v1.7.2's `safeNumber()` used `tonumber(tostring(value)) or 0`, which strips the WoW 12.0.5+ secret-number flag for arithmetic safety — but in some combat contexts the engine's `tostring()` does not return a numeric string for secret-protected values, collapsing every PaperDoll readout to `0`. `safeNumber()` is now a fallback chain: try `tostring → tonumber` first; on failure preserve the original value when it is already a `number` (so the displayed value stays intact even if the secret flag could not be stripped); only fall back to `0` for non-numeric inputs.
- **Fixed: residual taint crash from `C_UnitAuras.GetAuraDataByIndex` arithmetic.**
  `getPlayerBuffHash()` now sanitizes `spellId` / `expirationTime` / `applications` through `safeNumber()` before any arithmetic, and wraps the per-aura `string.format` step in `pcall`, so a single secret-protected aura entry can no longer break the buff-hash loop or surface a Lua error to the user.

### Addon-Wide Hardening

- **`ns:SafeCall(...)` now actually pcalls.**
  The helper used by 60+ event/refresh paths (overlays, panels, modules) was previously only doing a `nil` check despite its name. Any unhandled secret-number taint or transient API failure surfaced directly to the user as a Lua error screen. `SafeCall` now wraps the dispatch in `pcall`, recovers silently on the next refresh tick, and emits a `[debug] SafeCall(<method>) failed: ...` line only when `/abpm debug on` is set — making future taint regressions self-diagnosing without breaking the UI.
- **New shared sanitizer `Utils.SafeNumber(value)`.**
  Centralizes the secret-number stripping pattern with the fallback chain described above so other modules (not just `StatsOverlay`) can adopt it without duplicating logic.

### Bug Fixes — Ghost Retry

- **Fixed: ghost retry debug log flooding the buffer in combat.**
  `ActionBarApplier:RetryPendingGhosts()` is invoked from `ACTIONBAR_SLOT_CHANGED`, `ACTIONBAR_PAGE_CHANGED`, `UPDATE_BONUS_ACTIONBAR`, and `SPELLS_CHANGED`. While in combat (or with a busy cursor), it was logging `Skipping ghost retry while in combat` on every fire — observed at ~15 lines/sec, saturating the 200-line debug ring buffer in seconds and pushing real diagnostics out. The retry is now a no-op when `pendingGhosts` is empty, and the skip log is state-change-based: a single line when the skip reason first appears, then suppressed until the reason changes (combat → cursor, or skip → resume).

## Technical Notes

### `safeNumber` fallback chain

```lua
function Utils.SafeNumber(value)
    -- 1. Strip secret-number flag via tostring → tonumber.
    local convertOk, stripped = pcall(function()
        return tonumber(tostring(value))
    end)
    if convertOk and stripped then
        return stripped
    end

    -- 2. tostring couldn't yield a numeric string but the value is already
    --    a number — preserve it so display stays correct (taint risk only
    --    materializes if it is later fed into arithmetic, which the host
    --    SafeCall pcall now contains).
    if type(value) == "number" then
        return value
    end

    -- 3. nil / non-numeric string → 0.
    return tonumber(value) or 0
end
```

This trades a microscopic chance of taint propagation (case 2) against the previous certainty of all-zero readouts in combat. The new addon-wide `SafeCall` pcall absorbs any taint that does propagate.

### State-change ghost-retry logging

```lua
if skipReason ~= self._lastRetrySkipReason then
    ns.Utils.Debug("Ghost retry skipped: " .. skipReason)
    self._lastRetrySkipReason = skipReason
end
```

`_lastRetrySkipReason` is reset to `nil` whenever (a) `pendingGhosts` is empty, or (b) the retry actually proceeds — so the next genuinely new skip event still surfaces a single line.

## In-Game Regression Checklist

- [ ] Enter combat — secondary stats (crit / haste / mastery / versatility) display real values, not `0`.
- [ ] Trinket on-use during combat updates the readout within ~0.2s.
- [ ] No Lua error screen appears during combat / instance entry / spec swap / equipment swap.
- [ ] With `/abpm debug on`, `Skipping ghost retry...` appears at most once per skip-reason change, not per-frame.
- [ ] Existing v1.7.3 behaviors (instance entry refresh, trinket buff hash, bulk ghost cleanup, BIS source labels) continue to work.

## Upgrading from a Previous Version

- Existing saved data (`ABPM_DB`) is preserved.
- No settings reconfiguration required.
- No new locale keys, no new buttons, no UI changes — this is a pure stability hotfix on top of v1.7.3.
