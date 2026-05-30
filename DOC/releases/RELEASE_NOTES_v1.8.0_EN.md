# ABProfileManager v1.8.0

Release date: `2026-05-31`

This release refreshes the BIS Overlay data and display policy from the new Midnight Season 1 M+/tier DOC database. Existing raid and crafted rows are preserved from the current catalog, and `Data/BISCatalog.lua` remains the only runtime BIS data source.

Direct download: `https://github.com/cronocros/ABProfileManager/releases/download/v1.8.0/ABProfileManager-v1.8.0.zip`
Local package: `dist/ABProfileManager-v1.8.0.zip`

## Changes

- **Regenerated M+/tier BIS candidates.**
  `DOC/MidnightS1_MPlus_Addon_DB_v1.0.lua` is used as an offline input to regenerate M+/tier candidates for all 40 specs.
- **Preserved raid and crafted data.**
  Raid rows that are not present in the new DOC DB, plus existing crafted rows, are preserved from the current `Data/BISCatalog.lua`.
- **No static Myth link guessing.**
  M+ rows show end-of-dungeon Hero 3/6 266 and Great Vault/Voidcore Myth 1/6 272 candidates, but do not generate static `itemLink`, `itemString`, or bonusID data.
- **Validation metadata is visible.**
  BIS rows and spec policies now carry runtime-link-required, Myth-track-unverified, not-static-final-BIS, and stat-priority validation metadata.
- **Cleaner BIS Overlay list.**
  The header now summarizes the selected spec's stat policy, and rows show source plus track/validation state in a wider compact list.
- **Safe tooltip policy remains.**
  The overlay still avoids direct `GameTooltip:SetHyperlink()` calls. Verified tooltipData is rendered into the addon-owned tooltip; otherwise the tooltip falls back to Base ItemID plus validation warnings.

## Validation

- `scripts/build_bis_catalog.py --addon-db`
- `scripts/validate_bis_catalog.py`
- `scripts/audit_bis_data.py`
- Full Lua static parse
- `git diff --check`
- `scripts/package_release.ps1`

## In-Game Regression Checklist

- Open/close the BIS Overlay and swap specializations.
- Try every source filter combination.
- Confirm `raid off + M+ only` still shows M+ rows and dungeon names.
- Hover items and confirm runtime-link, sim-required, and Myth-track-unverified text.
- Click M+/raid sources and confirm Encounter Journal landing.
- Click crafted/tier rows and confirm they do not land in Encounter Journal.
- Check druid four-spec header/filter spacing.

## Upgrading from a Previous Version

- Saved data is unchanged.
- No settings reset is required.
