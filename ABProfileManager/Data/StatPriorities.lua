local _, ns = ...

-- Compiled from Midnight 12.0.1 live/pre-patch Icy Veins easy-mode and
-- stat-priority pages reviewed on 2026-03-10. Specs with strong content,
-- build, or Hero Talent variance are intentionally collapsed into one
-- general-purpose PvE ordering for compact in-game display.
ns.Data.StatPriorities = {
    WARRIOR = {
        [1] = { { "crit" }, { "haste" }, { "mastery" }, { "versatility" } }, -- Arms
        [2] = { { "mastery" }, { "haste" }, { "versatility" }, { "crit" } }, -- Fury
        [3] = { { "haste" }, { "crit", "versatility" }, { "mastery" } }, -- Protection
    },
    PALADIN = {
        [1] = { { "haste" }, { "mastery" }, { "crit" }, { "versatility" } }, -- Holy
        [2] = { { "haste" }, { "mastery" }, { "versatility", "crit" } }, -- Protection
        [3] = { { "mastery", "haste" }, { "crit" }, { "versatility" } }, -- Retribution
    },
    HUNTER = {
        [1] = { { "crit" }, { "mastery" }, { "haste" }, { "versatility" } }, -- Beast Mastery
        [2] = { { "crit" }, { "mastery" }, { "haste" }, { "versatility" } }, -- Marksmanship
        [3] = { { "mastery" }, { "crit" }, { "haste" }, { "versatility" } }, -- Survival
    },
    ROGUE = {
        [1] = { { "crit" }, { "mastery" }, { "haste" }, { "versatility" } }, -- Assassination
        [2] = { { "versatility" }, { "haste" }, { "crit" }, { "mastery" } }, -- Outlaw
        [3] = { { "haste" }, { "crit" }, { "mastery" }, { "versatility" } }, -- Subtlety
    },
    PRIEST = {
        [1] = { { "haste" }, { "crit", "mastery" }, { "versatility" } }, -- Discipline
        [2] = { { "crit" }, { "versatility", "mastery" }, { "haste" } }, -- Holy
        [3] = { { "haste" }, { "mastery" }, { "crit" }, { "versatility" } }, -- Shadow
    },
    DEATHKNIGHT = {
        [1] = { { "crit", "versatility", "mastery", "haste" } }, -- Blood
        [2] = { { "crit" }, { "mastery" }, { "haste" }, { "versatility" } }, -- Frost
        [3] = { { "mastery" }, { "crit" }, { "haste" }, { "versatility" } }, -- Unholy
    },
    SHAMAN = {
        [1] = { { "mastery" }, { "haste", "crit" }, { "versatility" } }, -- Elemental
        [2] = { { "mastery" }, { "haste" }, { "crit" }, { "versatility" } }, -- Enhancement
        [3] = { { "haste", "crit" }, { "versatility" }, { "mastery" } }, -- Restoration
    },
    MAGE = {
        [1] = { { "mastery" }, { "crit" }, { "versatility" }, { "haste" } }, -- Arcane
        [2] = { { "haste" }, { "mastery" }, { "crit" }, { "versatility" } }, -- Fire
        [3] = { { "mastery" }, { "crit" }, { "haste" }, { "versatility" } }, -- Frost
    },
    WARLOCK = {
        [1] = { { "mastery", "haste" }, { "crit" }, { "versatility" } }, -- Affliction
        [2] = { { "haste" }, { "crit" }, { "mastery", "versatility" } }, -- Demonology
        [3] = { { "haste" }, { "crit" }, { "mastery" }, { "versatility" } }, -- Destruction
    },
    MONK = {
        [1] = { { "crit", "versatility", "mastery" }, { "haste" } }, -- Brewmaster
        [2] = { { "haste" }, { "crit" }, { "versatility" }, { "mastery" } }, -- Mistweaver
        [3] = { { "crit" }, { "haste" }, { "mastery" }, { "versatility" } }, -- Windwalker
    },
    DRUID = {
        [1] = { { "mastery" }, { "haste" }, { "versatility" }, { "crit" } }, -- Balance
        [2] = { { "mastery" }, { "crit" }, { "haste" }, { "versatility" } }, -- Feral
        [3] = { { "haste" }, { "versatility" }, { "mastery" }, { "crit" } }, -- Guardian
        [4] = { { "haste", "mastery" }, { "versatility" }, { "crit" } }, -- Restoration
    },
    DEMONHUNTER = {
        [1] = { { "crit" }, { "mastery" }, { "haste" }, { "versatility" } }, -- Havoc
        [2] = { { "haste" }, { "crit", "versatility" }, { "mastery" } }, -- Vengeance
        [3] = { { "haste" }, { "mastery" }, { "crit" }, { "versatility" } }, -- Devourer
    },
    EVOKER = {
        [1] = { { "haste" }, { "crit" }, { "mastery" }, { "versatility" } }, -- Devastation
        [2] = { { "mastery" }, { "haste" }, { "crit" }, { "versatility" } }, -- Preservation
        [3] = { { "haste" }, { "crit" }, { "mastery", "versatility" } }, -- Augmentation
    },
}
