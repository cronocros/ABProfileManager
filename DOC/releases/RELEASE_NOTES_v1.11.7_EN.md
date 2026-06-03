# ABProfileManager v1.11.7 Local Patch

Patch baseline date: `2026-06-03`

These notes describe the local patch package.

- Local package: `dist/ABProfileManager-v1.11.7.zip`
- Latest public GitHub release: `v1.11.0`
- Public GitHub direct download: `https://github.com/cronocros/ABProfileManager/releases/download/v1.11.0/ABProfileManager-v1.11.0.zip`

## Changes

- **Raid / crafted / tier base item tooltips.**
  With the top item toggle enabled, raid/crafted/tier BIS hover now shows the addon-owned Blizzard `GameTooltip:SetHyperlink()` base item tooltip.
- **No arbitrary bonusID assembly.**
  These sources are static `itemID` candidates without verified seasonal full links, so the addon does not guess seasonal upgrade links and uses only the client-loaded base `itemLink`.
- **Session cache reuse.**
  Successfully loaded base `itemLink` values are stored in a session cache to reduce repeated hover loading.
- **M+ path preserved.**
  The M+ verified `Myth 1/6 272` snapshot path, original Blizzard tooltip renderer, and shopping-tooltip `MoneyFrame` suppression remain unchanged.
- **Expanded contract validation.**
  `scripts/validate_bis_tooltip_contract.py` now checks the raid/crafted/tier base Blizzard tooltip path.

## Distribution Boundary

- Local distribution stops after creating `dist/ABProfileManager-v1.11.7.zip` inside the workspace.
- The addon is not copied automatically into a WoW installation folder.
- The latest public GitHub release and direct download remain `v1.11.0`.

## In-Game Regression Checklist

- Enable the top item toggle and confirm raid / crafted / tier BIS hover shows Blizzard base item tooltips.
- Hover the same raid / crafted / tier item again and confirm the session cache avoids repeated loading.
- Confirm M+ BIS hover still shows the `Myth 1/6 272` baseline.
- After BIS hover, inspect action-bar and Encounter Journal item tooltips and confirm the `MoneyFrame.lua secret number` error does not recur.
