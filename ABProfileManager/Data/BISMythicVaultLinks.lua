local addonName, ns = ...

ns.Data = ns.Data or {}

-- Midnight Season 1 M+10 Great Vault Myth 1/6 preview selector plus optional
-- curated overrides. Bonus list 12801 is the reviewed group-612 sequence-1
-- selector. The overlay still verifies the resolved 272 item level, scans each
-- link once, and persists a tooltip/stat snapshot in SavedVariables.
ns.Data.BISMythicVaultLinks = {
    schemaVersion = 2,
    baselineItemLevel = 272,
    generatedPreviewBonusListID = 12801,
    generatedPreviewItemStringTemplate = "item:%d::::::::::::1:%d",
    linksByItemID = {
        -- Optional observed full-link overrides:
        -- [251111] = "item:251111:...",
    },
    snapshotsByItemID = {
        -- Optional pre-scanned tooltip/stat snapshots for offline updates.
    },
}
