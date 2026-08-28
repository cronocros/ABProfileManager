local addonName, ns = ...

ns.Data = ns.Data or {}

ns.Data.BISSeasonPreviewLinks = {
    schemaVersion = 1,
    verifiedDB2Build = "12.1.0.69465",
    sourceProfiles = {
        raid = {
            label = "Raid Mythic",
            minItemLevel = 318,
            maxItemLevel = 334,
            requireMythText = true,
        },
        tier = {
            label = "Tier Mythic",
            minItemLevel = 318,
            maxItemLevel = 334,
            requireMythText = true,
        },
        crafted = {
            label = "Crafted R5",
            targetItemLevel = 331,
            requireMythText = false,
        },
    },
    linksBySourceAndItemID = {
        raid = {
        },
        tier = {
        },
        crafted = {
        },
    },
}
