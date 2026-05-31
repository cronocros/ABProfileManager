# ABProfileManager v1.11.0

Release date: `2026-06-01`

This release connects the Midnight Season 1 v1.7 compact runtime scoring core to the BIS overlay.

Direct download: `https://github.com/cronocros/ABProfileManager/releases/download/v1.11.0/ABProfileManager-v1.11.0.zip`
Local package: `dist/ABProfileManager-v1.11.0.zip`

## Changes

- **Connected the v1.7 runtime scoring core.**
  `DOC/MidnightS1_MPlus_Addon_DB_v1.7.lua` is installed as the runtime core and loaded through an ABPM adapter.
- **Real itemLink scoring.**
  Candidates with links found in equipped slots or bags are ordered against each other by the v1.7 score calculated from the real item level and stats.
- **Deterministic static fallback.**
  Candidates without a real link keep the existing static order. Filters, favorites, owned state, and preserved raid/crafted rows remain compatible.
- **3130 BIS rows retained.**
  The static candidate pool remains `mythicplus 2554`, `raid 285`, `crafted 91`, and `tier 200`.
- **Bounded inventory scan cost.**
  Equipped slots and bags are indexed once per overlay rebuild.
- **Updated priorities for all 40 specializations.**
  The stat overlay, stat-priority table, and BIS policy metadata now use the v1.7 policy.
- **Separated generation and validation.**
  `scripts/build_bis_runtime_scoring.py` was added, and validation now checks the v1.3 static pool and v1.7 runtime core independently.

## In-Game Regression Checklist

- Open the BIS overlay, switch specs, and try every source-filter combination.
- Disable raid and keep Mythic+ enabled, then confirm Mythic+ rows and dungeon names remain visible.
- Confirm favorite and owned state persistence, the Favorites section, and owned-name strikethrough.
- Confirm ordering and hover tooltips for slots with real owned items.
- Confirm crafted/tier rows do not land in Encounter Journal and M+/raid landing remains guarded.
- Confirm the stat-priority table displays all 40 specializations.

## Upgrading

- No settings reset is required.
- Favorites and owned state saved since v1.9.0 remain available.
- The static candidate pool is retained. Runtime scoring is added only when a real link is available.
