local addonName, ns = ...

ns.Data = ns.Data or {}

-- Season preview links for non-M+ BIS sources.
--
-- These are not used for sorting and are never trusted blindly. BISOverlay
-- validates the resolved Blizzard tooltip item level, and raid/tier links must
-- also carry Myth/Mythic tooltip text before they are shown.
ns.Data.BISSeasonPreviewLinks = {
    schemaVersion = 1,
    verifiedDB2Build = "12.0.1.66838",
    sourceProfiles = {
        raid = {
            label = "Raid Mythic",
            minItemLevel = 272,
            maxItemLevel = 298,
            requireMythText = true,
            itemStringTemplates = {
                "item:%d::::::::::::3:6652:13335:12806",
                "item:%d::::::::::::3:6652:13335:12805",
                "item:%d::::::::::::3:6652:13335:12804",
                "item:%d::::::::::::3:6652:13335:12803",
                "item:%d::::::::::::3:6652:13335:12802",
                "item:%d::::::::::::3:6652:13335:12801",
            },
        },
        tier = {
            label = "Tier Mythic",
            minItemLevel = 272,
            maxItemLevel = 289,
            requireMythText = true,
            itemStringTemplates = {
                "item:%d::::::::::::5:13340:13440:6652:13574:12806",
                "item:%d::::::::::::5:13340:13440:6652:13574:12805",
                "item:%d::::::::::::5:13340:13440:6652:13574:12804",
                "item:%d::::::::::::6:13574:6652:13440:13340:13574:12806",
                "item:%d::::::::::::6:13574:6652:13440:13340:13574:12805",
                "item:%d::::::::::::6:13574:6652:13440:13340:13574:12804",
            },
        },
        crafted = {
            label = "Crafted R5",
            targetItemLevel = 285,
            itemStringTemplates = {
                "item:%d::::::::::::6:12214:12497:12066:8960:12384:13622",
                "item:%d::::::::::::7:12214:12497:12066:8960:12384:13622:13667",
                "item:%d::::::::::::7:12214:12497:12066:8960:12384:8790:13622",
                "item:%d::::::::::::8:12214:12497:12066:8960:12384:8790:13622:13667",
                "item:%d::::::::::::8:12214:12497:12066:12693:8960:8791:13622:13667",
                "item:%d::::::::::::9:12214:12497:12066:8960:12384:8793:13622:13667:12666",
            },
        },
    },
    linksBySourceAndItemID = {
        raid = {
            -- Optional observed full-link overrides:
            -- [249343] = "item:249343:...",
        },
        tier = {
            -- Optional observed full-link overrides:
            -- [250058] = "item:250058:...",
        },
        crafted = {
            -- Optional observed full-link overrides:
            -- [239656] = "item:239656:...",
        },
    },
}
