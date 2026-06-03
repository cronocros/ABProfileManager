# ABProfileManager v1.11.9 Local Patch

Patch baseline date: `2026-06-03`

These notes describe the local patch package.

- Local package: `dist/ABProfileManager-v1.11.9.zip`
- Latest public GitHub release: `v1.11.0`
- Public GitHub direct download: `https://github.com/cronocros/ABProfileManager/releases/download/v1.11.0/ABProfileManager-v1.11.0.zip`

## Changes

- **Raid / tier Myth preview support.**
  Raid and tier BIS hover now tries reviewed seasonal preview item strings first. The preview is shown through the original Blizzard item tooltip only when the client tooltip resolves to item level `272~289` and includes `Myth` or Korean `신화` text.
- **Crafted R5 285 preview support.**
  Crafted BIS hover now tries R5 `285` crafted preview item strings first. The preview is shown through the original Blizzard item tooltip only when the client tooltip resolves to item level `285`.
- **Fallback remains intact.**
  If a preview is not loaded or does not pass validation, the overlay falls back to the normal Blizzard `itemLink` or `item:<itemID>` tooltip path.
- **Season preview DB added.**
  `Data/BISSeasonPreviewLinks.lua` now manages raid Myth, tier Myth, crafted R5 preview templates and optional full-link override slots.
- **Validation added.**
  Added `scripts/validate_bis_season_preview_links.py` and wired it into `scripts/rebuild_bis_database.ps1`.
- **M+ path preserved.**
  The M+ verified `Myth 1/6 272` snapshot path, default-on top item tooltip checkbox, and shopping-tooltip `MoneyFrame` suppression remain unchanged.

## Distribution Boundary

- Local distribution stops after creating `dist/ABProfileManager-v1.11.9.zip` inside the workspace.
- The addon is not copied automatically into a WoW installation folder.
- The latest public GitHub release and direct download remain `v1.11.0`.

## In-Game Regression Checklist

- Confirm raid/tier BIS hover shows the original Blizzard tooltip after Myth preview validation.
- Confirm crafted BIS hover shows the original Blizzard tooltip after R5 `285` preview validation.
- Confirm failed previews still fall back to the normal `itemLink` or `item:<itemID>` path.
- Confirm M+ BIS hover still uses the `Myth 1/6 272` snapshot baseline.
- After BIS hover, inspect action-bar and Encounter Journal item tooltips and confirm the `MoneyFrame.lua secret number` error does not recur.
