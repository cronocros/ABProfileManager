# ABProfileManager v1.11.6 Local Patch

Patch baseline date: `2026-06-03`

These notes describe the local patch package.

- Local package: `dist/ABProfileManager-v1.11.6.zip`
- Latest public GitHub release: `v1.11.0`
- Public GitHub direct download: `https://github.com/cronocros/ABProfileManager/releases/download/v1.11.0/ABProfileManager-v1.11.0.zip`

## Changes

- **Reviewed Myth 1/6 272 selector.**
  Midnight season selector `12801` was reviewed against extracted ItemBonus DB2 build `12.0.1.66838`.
- **Account-wide snapshot schema v3.**
  When the top item toggle is enabled, each verified `Myth 1/6 272` full item link is stored once in account SavedVariables snapshot schema v3. Hover and automatic scoring then reuse the saved result.
- **Original Blizzard item tooltip.**
  M+ BIS hover passes the cached full item link to an addon-owned Blizzard `GameTooltip:SetHyperlink()` renderer so Blizzard renders the original secondary stats.
- **MoneyFrame sell-price suppression.**
  The BIS item tooltip uses the shopping-tooltip path to suppress sell-price `MoneyFrame` rendering.
- **Reduced secret-number exposure.**
  The unused `PaperDollFrame_Set*` setters were removed from `StatsOverlay`. If `SafeNumber()` cannot normalize a secret value into a plain number, it now falls back to `0` instead of propagating the original value.

## Distribution Boundary

- Local distribution stops after creating `dist/ABProfileManager-v1.11.6.zip` inside the workspace.
- The addon is not copied automatically into a WoW installation folder.
- The latest public GitHub release and direct download remain `v1.11.0`.

## In-Game Regression Checklist

- Enable the top item toggle and confirm M+ BIS hover shows the original Blizzard secondary stats at the `Myth 1/6 272` baseline.
- Hover the same item again and scroll the list to confirm the stored snapshot is reused without excessive stutter.
- After BIS hover, inspect action-bar and Encounter Journal item tooltips and confirm the `MoneyFrame.lua secret number` error does not recur.
- Inspect StatsOverlay hover and in-combat stat refresh behavior and confirm secret-number errors do not recur.
