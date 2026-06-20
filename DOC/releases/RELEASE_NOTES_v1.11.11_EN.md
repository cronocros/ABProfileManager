# ABProfileManager v1.11.11 Local Patch

Patch baseline date: `2026-06-21`

These notes describe the local patch package.

- Local package: `dist/ABProfileManager-v1.11.11.zip`
- Latest public GitHub release: `v1.11.0`
- Public GitHub direct download: `https://github.com/cronocros/ABProfileManager/releases/download/v1.11.0/ABProfileManager-v1.11.0.zip`

## Changes

- **Added Sporefall BIS candidates.**
  Added 11 raid drops from the WoW 12.0.7 single-boss raid `Sporefall`, boss `Rotmire`, to the BIS overlay candidate pool.
- **Re-ranked new raid candidates.**
  New rows were placed by armor eligibility, shared neck/ring/trinket slots, and the v1.7 stat-priority policy.
- **Expanded the catalog.**
  The BIS catalog now contains `3330` rows: `mythicplus 2554`, `raid 485`, `crafted 91`, and `tier 200`.
- **Added Sporefall preview and locale support.**
  Raid Myth preview validation now allows item level `298`, and BIS hover/source labels include `Sporefall / Rotmire`.
- **Hardened 12.0.7 compatibility.**
  Checked and strengthened StatsOverlay secret-number conversion, Encounter Journal tier fallback, Warband Bank session detection, action-bar cursor mutation, and Delve/PVE refresh guards.

## Distribution Boundary

- Local distribution stops after creating `dist/ABProfileManager-v1.11.11.zip` inside the workspace.
- The addon is not copied automatically into a WoW installation folder.
- The latest public GitHub release and direct download remain `v1.11.0`.

## In-Game Regression Checklist

- Confirm the BIS overlay shows `Sporefall / Rotmire` candidates with the Raid filter enabled.
- Confirm filtered visible ranks are recalculated as `Rank 1 / Rank 2 / Rank 3+`.
- Confirm Sporefall raid hover uses the seasonal preview path or a normal item tooltip fallback.
- Confirm BIS source clicks during combat do not trigger protected-function popup warnings.
- Confirm StatsOverlay, Warband Bank handling, action-bar apply, and the Delves tab still work on the 12.0.7 client.
