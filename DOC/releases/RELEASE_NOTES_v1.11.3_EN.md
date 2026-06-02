# ABProfileManager v1.11.3 Local Patch

Patch baseline date: `2026-06-02`

These notes describe the local patch package.

- Local package: `dist/ABProfileManager-v1.11.3.zip`
- Latest public GitHub release: `v1.11.0`
- Public GitHub direct download: `https://github.com/cronocros/ABProfileManager/releases/download/v1.11.0/ABProfileManager-v1.11.0.zip`

## Changes

- **Builds Myth 1/6 272 previews for M+ items that are not in bags.**
  With the top item toggle enabled, each M+ candidate gets a preview item string built from the shipped selector `12801`.
- **Shows secondary stats and standard item tooltip lines.**
  Once the client verifies the generated preview as actual item level `272`, tooltip lines, colors, and real stats are stored as a snapshot.
- **Avoids repeated scans.**
  Snapshots are reused from account SavedVariables. Later hovers and automatic scoring read the stored data.
- **Handles selector changes and rejected previews.**
  A selector or item-string-template change invalidates old snapshots. Previews that resolve to another item level are not retried repeatedly in the same session.
- **Keeps manual DB entries as exception overrides.**
  Only items that cannot use the generated preview need a full-link override in `Data/BISMythicVaultLinks.lua`.
- **Preserves the accuracy boundary.**
  Unreviewed bonusIDs are not assembled dynamically. Generated previews are used only after the client confirms actual item level `272`.

## Data Update Boundary

- On a season change, review the selector in `Data/BISMythicVaultLinks.lua` and update the validator expectation together.
- Add exceptional full-link overrides in the same file.
- Run `python .\scripts\validate_bis_mythic_vault_links.py` to validate the baseline, selector, and override format.

## In-Game Regression Checklist

- Enable the top item toggle and confirm an M+ item that is not in bags shows `Myth 1/6 272`, secondary stats, and quality colors.
- After the initial load, relog and confirm the SavedVariables snapshot is reused.
- Scroll the BIS list quickly and confirm tooltip churn no longer causes noticeable stalls.
- Hover Encounter Journal items after BIS hovers and confirm no `MoneyFrame.lua secret number` error appears.
