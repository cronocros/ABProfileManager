local addonName, ns = ...

ns.Data = ns.Data or {}

-- Curated Myth 1/6 links only. Keep this separate from the generated catalog:
-- itemID identifies the candidate, while the full link proves the 272 variant.
-- The overlay verifies the resolved item level again before using a link.
ns.Data.BISMythicVaultLinks = {
    schemaVersion = 1,
    baselineItemLevel = 272,
    linksByItemID = {
        -- [251111] = "item:251111:...",
    },
}
