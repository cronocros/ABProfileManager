# ABProfileManager v1.11.2 Local Patch

Patch baseline date: `2026-06-02`

These notes describe the local patch package.

- Local package: `dist/ABProfileManager-v1.11.2.zip`
- Latest public GitHub release: `v1.11.0`
- Public GitHub direct download: `https://github.com/cronocros/ABProfileManager/releases/download/v1.11.0/ABProfileManager-v1.11.0.zip`

## Changes

- **Suppresses tooltip rendering while scrolling.**
  Row-hover tooltips pause briefly while the BIS list is scrolled with the wheel or thumb, reducing repeated render work.
- **Persists Myth 1/6 272 snapshots.**
  With the top item toggle enabled, each verified 272 full link is read once and its tooltip lines, colors, and real stats are stored in account SavedVariables.
- **Uses snapshots for tooltip rendering and scoring.**
  Once cached, hover and automatic scoring read the snapshot only. They no longer rescan links, bags, or Encounter Journal state on each hover.
- **Removes highest-bag-link priority.**
  Bag links no longer control slot ordering or hover display. A matching link is searched once only when marking an item as owned.
- **Removes bag-event full rebuilds.**
  `BAG_UPDATE_DELAYED` and `PLAYER_EQUIPMENT_CHANGED` no longer trigger full BIS-list rebuilds.
- **Keeps the accuracy boundary explicit.**
  Candidates without an exact 272 full link show an unverified notice instead of guessed itemLink or bonusID data.
- **Removes obsolete BIS preview helpers.**
  Unused Encounter Journal preview helpers and rebuild-time bag indexing were deleted.

## Data Update Boundary

- Add or replace verified Myth 1/6 272 full links only in `Data/BISMythicVaultLinks.lua`.
- Registered links are persisted as SavedVariables snapshots only after the client verifies the actual 272 item level.
- Maintain the M+/tier candidate pool in the v1.3 files and scoring policy in the v1.7 files.
- Do not guess 272 bonusIDs.

## In-Game Regression Checklist

- Scroll the BIS list quickly and confirm row-hover tooltip churn no longer causes noticeable stalls.
- Enable the top item toggle, cache a verified full link, relog, and confirm the stored snapshot is reused.
- Confirm uncached rows show the unverified notice only.
- Recheck owned-item toggles and favorite ordering.
- Hover Encounter Journal items after BIS hovers and confirm no `MoneyFrame.lua secret number` error appears.
