# ABProfileManager v1.7.2

WoW Patch 12.0.5 — Secret Number Compatibility Hotfix.

Direct download: `https://github.com/cronocros/ABProfileManager/releases/download/v1.7.2/ABProfileManager-v1.7.2.zip`
Local package: `dist/ABProfileManager-v1.7.2.zip`

## Changes

### Bug Fixes

- **StatsOverlay: PaperDoll setter taint crash fixed**
  `PreparePaperDollTooltip` now wraps Blizzard's `PaperDollFrame_Set*` setter calls in `pcall`. In WoW 12.0.5+, calling these functions from addon execution context causes a "attempt to perform arithmetic on a secret number value (execution tainted by 'ABProfileManager')" error. On failure the overlay falls back to its own custom tooltip, so stat rows remain fully functional.

- **StatsOverlay: Secret number safe conversion**
  `safeNumber()` now uses `tonumber(tostring(value))` instead of a bare `tonumber()`. The `tostring` pass strips the WoW 12.0.5+ secret-number flag before any arithmetic or comparison, preventing taint propagation from numeric API return values.

## Technical Details

WoW Patch 12.0.5 (Midnight) introduced a "secret number" security mechanism: certain API return values carry an internal flag that forbids their direct use as table keys or arithmetic operands in addon-tainted execution contexts. Both fixes above are defensive responses to this engine change.

## Upgrading from a Previous Version

- Existing saved data (`ABPM_DB`) is preserved.
- No settings reconfiguration required.
