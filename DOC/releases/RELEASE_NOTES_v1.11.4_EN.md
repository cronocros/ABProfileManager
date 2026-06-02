# ABProfileManager v1.11.4 Local Patch

Patch baseline date: `2026-06-03`

These notes describe the local patch package.

- Local package: `dist/ABProfileManager-v1.11.4.zip`
- Latest public GitHub release: `v1.11.0`
- Public GitHub direct download: `https://github.com/cronocros/ABProfileManager/releases/download/v1.11.0/ABProfileManager-v1.11.0.zip`

## Changes

- **Corrects M+ Encounter Journal landing.**
  M+ source clicks preselect the current-season tier and open the target dungeon loot tab by verified `JournalInstanceID` only after the availability guard passes.
- **Uses verified Midnight Season 1 dungeon IDs.**
  The IDs are `Magisters' Terrace 1300`, `Maisara Caverns 1315`, `Nexus-Point Xenas 1316`, `Windrunner Spire 1299`, `Algeth'ar Academy 1201`, `Seat of the Triumvirate 945`, `Skyreach 476`, and `Pit of Saron 278`.
- **Retries selector preview hyperlink loads.**
  If the preview hyperlink is not loaded yet and the snapshot is missing, the exact selector link is validated again after the asynchronous item load completes. Failed callbacks are cleared by timeout and each link is retried at most twice per session.
- **Attempts immediate resolution on hover.**
  Hovering an M+ row without a stored snapshot also attempts one immediate selector preview hyperlink resolution.

## Distribution Boundary

- This is a local-only package: `dist/ABProfileManager-v1.11.4.zip`.
- The latest public GitHub release and direct download remain `v1.11.0`.

## In-Game Regression Checklist

- Click sources for all eight M+ dungeons and confirm the correct Encounter Journal loot tab opens after current-season tier preselection.
- Confirm an unavailable season tier does not attempt an invalid dungeon landing.
- Confirm a selector preview that is initially empty can populate its snapshot after the asynchronous item load.
- Hover an M+ row without a snapshot and confirm the tooltip fills immediately when the preview hyperlink can resolve.
