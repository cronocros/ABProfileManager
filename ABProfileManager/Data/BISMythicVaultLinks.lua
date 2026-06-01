local addonName, ns = ...

ns.Data = ns.Data or {}

-- Curated Myth 1/6 links only. Keep this separate from the generated catalog:
-- itemID identifies the candidate, while the full link proves the 272 variant.
-- The overlay verifies the resolved item level, scans each link once, and
-- persists a tooltip/stat snapshot in SavedVariables for later sessions.
ns.Data.BISMythicVaultLinks = {
    schemaVersion = 1,
    baselineItemLevel = 272,
    linksByItemID = {
        -- [251111] = "item:251111:...",
    },
    snapshotsByItemID = {
        -- Optional pre-scanned tooltip/stat snapshots for offline updates.
    },
}
