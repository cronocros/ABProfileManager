local _, ns = ...

-- Compiled from Midnight 12.0.1 Wowhead stat-priority guides reviewed on
-- 2026-04-08. Specs with strong build variance are collapsed into one
-- general-purpose PvE ordering for compact in-game display.
ns.Data.StatPriorities = {
    WARRIOR = {
        [1] = { { "crit" }, { "haste" }, { "mastery" }, { "versatility" } }, -- Arms
        [2] = { { "haste" }, { "mastery" }, { "crit" }, { "versatility" } }, -- Fury
        [3] = { { "haste" }, { "crit" }, { "versatility" }, { "mastery" } }, -- Protection
    },
    PALADIN = {
        [1] = { { "mastery" }, { "haste", "crit" }, { "versatility" } }, -- Holy
        [2] = { { "haste" }, { "versatility" }, { "mastery" }, { "crit" } }, -- Protection
        [3] = { { "mastery" }, { "crit" }, { "haste" }, { "versatility" } }, -- Retribution
    },
    HUNTER = {
        [1] = { { "haste" }, { "crit" }, { "versatility" }, { "mastery" } }, -- Beast Mastery
        [2] = { { "crit" }, { "mastery" }, { "versatility" }, { "haste" } }, -- Marksmanship
        [3] = { { "mastery" }, { "crit" }, { "haste" }, { "versatility" } }, -- Survival
    },
    ROGUE = {
        [1] = { { "crit" }, { "haste" }, { "mastery" }, { "versatility" } }, -- Assassination
        [2] = { { "haste" }, { "crit" }, { "versatility" }, { "mastery" } }, -- Outlaw
        [3] = { { "mastery" }, { "haste" }, { "crit" }, { "versatility" } }, -- Subtlety
    },
    PRIEST = {
        [1] = { { "haste" }, { "crit" }, { "mastery" }, { "versatility" } }, -- Discipline
        [2] = { { "crit" }, { "versatility", "mastery" }, { "haste" } }, -- Holy
        [3] = { { "haste" }, { "mastery" }, { "crit" }, { "versatility" } }, -- Shadow
    },
    DEATHKNIGHT = {
        [1] = { { "haste" }, { "mastery", "crit", "versatility" } }, -- Blood
        [2] = { { "crit" }, { "mastery" }, { "haste" }, { "versatility" } }, -- Frost
        [3] = { { "mastery" }, { "crit" }, { "haste" }, { "versatility" } }, -- Unholy
    },
    SHAMAN = {
        [1] = { { "mastery" }, { "haste", "crit" }, { "versatility" } }, -- Elemental
        [2] = { { "haste" }, { "mastery", "crit" }, { "versatility" } }, -- Enhancement
        [3] = { { "crit" }, { "mastery", "versatility" }, { "haste" } }, -- Restoration
    },
    MAGE = {
        [1] = { { "mastery" }, { "haste" }, { "crit" }, { "versatility" } }, -- Arcane
        [2] = { { "haste" }, { "mastery" }, { "versatility" }, { "crit" } }, -- Fire
        [3] = { { "mastery" }, { "crit" }, { "haste" }, { "versatility" } }, -- Frost
    },
    WARLOCK = {
        [1] = { { "mastery", "crit" }, { "haste" }, { "versatility" } }, -- Affliction
        [2] = { { "haste", "crit" }, { "mastery" }, { "versatility" } }, -- Demonology
        [3] = { { "haste" }, { "mastery" }, { "crit" }, { "versatility" } }, -- Destruction
    },
    MONK = {
        [1] = { { "crit", "versatility", "mastery" }, { "haste" } }, -- Brewmaster
        [2] = { { "haste" }, { "crit" }, { "versatility" }, { "mastery" } }, -- Mistweaver
        [3] = { { "haste" }, { "crit" }, { "mastery" }, { "versatility" } }, -- Windwalker
    },
    DRUID = {
        [1] = { { "mastery" }, { "haste", "crit" }, { "versatility" } }, -- Balance
        [2] = { { "mastery" }, { "crit" }, { "haste" }, { "versatility" } }, -- Feral
        [3] = { { "haste" }, { "versatility" }, { "crit" }, { "mastery" } }, -- Guardian
        [4] = { { "haste" }, { "mastery" }, { "versatility" }, { "crit" } }, -- Restoration
    },
    DEMONHUNTER = {
        [1] = { { "crit" }, { "mastery" }, { "haste" }, { "versatility" } }, -- Havoc
        [2] = { { "haste" }, { "crit" }, { "versatility" }, { "mastery" } }, -- Vengeance
    },
    EVOKER = {
        [1] = { { "crit" }, { "haste" }, { "mastery" }, { "versatility" } }, -- Devastation
        [2] = { { "mastery" }, { "haste" }, { "crit" }, { "versatility" } }, -- Preservation
        [3] = { { "crit" }, { "haste" }, { "mastery" }, { "versatility" } }, -- Augmentation
    },
}

-- M+ priorities. Tanks favor Versatility first for affix damage reduction.
-- Non-tank specs use the same ordering as PvE (omitted = falls back to StatPriorities).
ns.Data.StatPrioritiesMythicPlus = {
    WARRIOR = {
        [3] = { { "versatility" }, { "haste" }, { "crit" }, { "mastery" } }, -- Protection M+
    },
    PALADIN = {
        [2] = { { "versatility" }, { "haste" }, { "mastery" }, { "crit" } }, -- Protection M+
    },
    DEATHKNIGHT = {
        [1] = { { "versatility" }, { "haste" }, { "mastery" }, { "crit" } }, -- Blood M+
    },
    MONK = {
        [1] = { { "versatility" }, { "mastery", "crit" }, { "haste" } }, -- Brewmaster M+
    },
    DRUID = {
        [3] = { { "versatility" }, { "haste" }, { "crit" }, { "mastery" } }, -- Guardian M+
    },
    DEMONHUNTER = {
        [2] = { { "versatility" }, { "haste" }, { "crit" }, { "mastery" } }, -- Vengeance M+
    },
}
