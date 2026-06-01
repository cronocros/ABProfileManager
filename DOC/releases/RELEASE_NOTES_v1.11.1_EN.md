# ABProfileManager v1.11.1 Local Patch

Patch baseline date: `2026-06-02`

These notes describe the local patch package.

- Local package: `dist/ABProfileManager-v1.11.1.zip`
- Latest public GitHub release: `v1.11.0`
- Public GitHub direct download: `https://github.com/cronocros/ABProfileManager/releases/download/v1.11.0/ABProfileManager-v1.11.0.zip`

## Changes

- **Preserved BIS tooltip colors.**
  The manual BIS item-tooltip renderer now preserves Blizzard tooltip line colors and item-quality colors.
- **Automatic verified M+ full-link lookup.**
  When the top item toggle is enabled, a distributed queue looks for M+ candidate full links in `Data/BISMythicVaultLinks.lua`.
- **Scores only verified Myth 1/6 272 links.**
  An automatically discovered full link is scored from its real stats and real item level only when that link itself is verified as Great Vault `Myth 1/6 272`.
- **Keeps the 266 end-of-dungeon fallback unverified.**
  If only a `Hero 3/6 266` end-of-dungeon link is available, the UI still displays the 272 baseline label but retains unverified fallback scoring.
- **Does not assemble links from item IDs.**
  The addon does not construct `itemLink` values or bonusIDs from bare item IDs.
- **Reduces rebuild pressure.**
  Real equipped or bag links take priority. Score caches, item-request deduplication, and a distributed queue reduce rebuild throttling pressure.
- **Blocks the MoneyFrame taint path.**
  Hover and automatic scoring no longer mutate Encounter Journal UI state or run hidden loot scans.
- **Adds a BIS rebuild entry point.**
  `scripts/rebuild_bis_database.ps1` runs v1.3 catalog input → v1.7 scoring input → curated Myth link validation → catalog validation → audit.
- **Adds a curated-link validator.**
  `scripts/validate_bis_mythic_vault_links.py` checks the baseline, catalog item IDs, and full item-string format.

## Seed Boundaries

- M+/tier additions can be updated only in the v1.3 files.
- Scoring policy is maintained in the v1.7 files.
- Verified Myth 1/6 272 full-link additions and replacements only require updates to `Data/BISMythicVaultLinks.lua`.
- The curated link database starts empty. It does not guess 272 bonusIDs that the client API does not provide.
- raid/crafted rows still use preserved `BISCatalog.lua` seeds.
- Full single-seed regeneration remains follow-up work.

## In-Game Regression Checklist

- Toggle curated automatic M+ full-link lookup on and off.
- Confirm that only Great Vault `Myth 1/6 272` verified full links receive automatic real-stat and real-item-level scoring.
- Confirm that a `Hero 3/6 266` end-of-dungeon-only link shows the 272 baseline label but remains an unverified fallback.
- Confirm real equipped or bag links take priority.
- Confirm Blizzard tooltip line colors and item-quality colors are preserved.
- Confirm the distributed scoring queue does not cause excessive rebuilds.
- Hover Encounter Journal items after BIS hovers and automatic scoring, then confirm no `MoneyFrame.lua secret number` error appears.
- Recheck raid-off/Mythic+-only, crafted-and-tier-only, and visible-rank recalculation cases.
