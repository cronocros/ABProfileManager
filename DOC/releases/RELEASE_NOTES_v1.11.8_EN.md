# ABProfileManager v1.11.8 Local Patch

Patch baseline date: `2026-06-03`

These notes describe the local patch package.

- Local package: `dist/ABProfileManager-v1.11.8.zip`
- Latest public GitHub release: `v1.11.0`
- Public GitHub direct download: `https://github.com/cronocros/ABProfileManager/releases/download/v1.11.0/ABProfileManager-v1.11.0.zip`

## Changes

- **Item tooltip checkbox defaults on.**
  The top BIS overlay item-tooltip checkbox now starts selected by default. Existing stored values are migrated on once, and a user-disabled choice is preserved after the user toggles it off.
- **Stronger first-hover tier tooltips.**
  When the client has not returned a full `itemLink` yet, tier BIS hover now tries the base `item:<itemID>` link through the addon-owned Blizzard `GameTooltip:SetHyperlink()` path.
- **Raid / crafted / tier base path preserved.**
  Raid/crafted/tier candidates are static `itemID` candidates without verified seasonal full links, so the addon does not assemble arbitrary bonusIDs and uses only Blizzard base item tooltip rendering.
- **Session cache reuse.**
  Successfully shown base itemID links are stored in a session cache to reduce repeated hover loading.
- **M+ path preserved.**
  The M+ verified `Myth 1/6 272` snapshot path, original Blizzard tooltip renderer, and shopping-tooltip `MoneyFrame` suppression remain unchanged.
- **Expanded contract validation.**
  `scripts/validate_bis_tooltip_contract.py` now checks both the base `itemLink` and bare `item:<itemID>` fallback contracts for raid/crafted/tier rows.

## Distribution Boundary

- Local distribution stops after creating `dist/ABProfileManager-v1.11.8.zip` inside the workspace.
- The addon is not copied automatically into a WoW installation folder.
- The latest public GitHub release and direct download remain `v1.11.0`.

## In-Game Regression Checklist

- Enable the top item toggle and confirm tier BIS hover shows Blizzard base item tooltips.
- Confirm the top item-tooltip checkbox is selected by default, and that disabling it remains disabled after reopening.
- Hover the same tier item again and confirm the session cache avoids repeated loading.
- Confirm raid / crafted BIS hover still shows Blizzard base item tooltips.
- Confirm M+ BIS hover still shows the `Myth 1/6 272` baseline.
- After BIS hover, inspect action-bar and Encounter Journal item tooltips and confirm the `MoneyFrame.lua secret number` error does not recur.
