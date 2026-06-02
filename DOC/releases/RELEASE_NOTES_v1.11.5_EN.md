# ABProfileManager v1.11.5 Local Patch

Patch baseline date: `2026-06-03`

These notes describe the local patch package.

- Local package: `dist/ABProfileManager-v1.11.5.zip`
- Latest public GitHub release: `v1.11.0`
- Public GitHub direct download: `https://github.com/cronocros/ABProfileManager/releases/download/v1.11.0/ABProfileManager-v1.11.0.zip`

## Changes

- **Removes a protected Encounter Journal tab call.**
  BIS source-click landing no longer calls the protected `C_EncounterJournal.SetTab` function directly.
- **Skips automatic landing during combat.**
  Encounter Journal automatic landing is skipped during combat to prevent Blizzard blocked-action popups.
- **Preserves the out-of-combat landing path.**
  Out of combat, M+ source clicks still preselect the current-season tier and open the target dungeon by verified `JournalInstanceID` only after the availability guard passes.

## Distribution Boundary

- Local distribution stops after creating `dist/ABProfileManager-v1.11.5.zip` inside the workspace.
- The addon is not copied automatically into a WoW installation folder.
- The latest public GitHub release and direct download remain `v1.11.0`.

## In-Game Regression Checklist

- Out of combat, click an M+ source and confirm the correct Encounter Journal landing after current-season tier preselection and the availability guard.
- During combat, click a BIS source and confirm automatic landing is skipped without a Blizzard blocked-action popup.
- Confirm crafted and tier rows do not land in Encounter Journal.
