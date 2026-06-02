local addonName, ns = ...

ns.Data = ns.Data or {}

-- Midnight Season 1 M+10 Great Vault Myth 1/6 preview selector plus optional
-- curated overrides. Bonus list 12801 is the reviewed group-612 sequence-1
-- selector. The overlay still verifies the resolved 272 item level, scans each
-- link once, and persists its full item string plus tooltip/stat snapshot in
-- SavedVariables. Hover rendering reuses that cached full string through the
-- Blizzard item tooltip renderer.
ns.Data.BISMythicVaultLinks = {
    schemaVersion = 3,
    verifiedDB2Build = "12.0.1.66838",
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
