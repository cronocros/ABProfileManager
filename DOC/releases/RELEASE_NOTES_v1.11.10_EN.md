# ABProfileManager v1.11.10 Local Patch

Patch baseline date: `2026-06-03`

These notes describe the local patch package.

- Local package: `dist/ABProfileManager-v1.11.10.zip`
- Latest public GitHub release: `v1.11.0`
- Public GitHub direct download: `https://github.com/cronocros/ABProfileManager/releases/download/v1.11.0/ABProfileManager-v1.11.0.zip`

## Changes

- **Fixed BISOverlay load failure.**
  Fixed the `UI/BISOverlay.lua` load error: `main function has more than 200 local variables`.
- **Reduced local-variable pressure.**
  Moved raid/tier/crafted season-preview state and helpers into the `SourcePreview` table, bringing the BISOverlay top-level local count down to `194`.
- **Strengthened validation.**
  `scripts/validate_bis_tooltip_contract.py` now checks the BISOverlay top-level local budget.
- **Existing behavior preserved.**
  Raid/tier/crafted season previews, the M+ verified `Myth 1/6 272` snapshot path, the default-on item tooltip checkbox, and shopping-tooltip `MoneyFrame` suppression remain unchanged.

## Distribution Boundary

- Local distribution stops after creating `dist/ABProfileManager-v1.11.10.zip` inside the workspace.
- The addon is not copied automatically into a WoW installation folder.
- The latest public GitHub release and direct download remain `v1.11.0`.

## In-Game Regression Checklist

- Confirm the addon no longer reports `main function has more than 200 local variables` during load.
- Confirm the BIS overlay opens normally.
- Confirm raid/tier/crafted hover still uses the seasonal preview or fallback path.
- Confirm M+ BIS hover still uses the `Myth 1/6 272` snapshot baseline.
