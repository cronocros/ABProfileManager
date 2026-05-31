local _, ns = ...

local Scoring = {}
ns.Data.BISRuntimeScoring = Scoring

local SPEC_KEY_BY_ID = {
    [62] = "MAGE_ARCANE", [63] = "MAGE_FIRE", [64] = "MAGE_FROST",
    [65] = "PALADIN_HOLY", [66] = "PALADIN_PROTECTION", [70] = "PALADIN_RETRIBUTION",
    [71] = "WARRIOR_ARMS", [72] = "WARRIOR_FURY", [73] = "WARRIOR_PROTECTION",
    [102] = "DRUID_BALANCE", [103] = "DRUID_FERAL", [104] = "DRUID_GUARDIAN", [105] = "DRUID_RESTO",
    [250] = "DEATHKNIGHT_BLOOD", [251] = "DEATHKNIGHT_FROST", [252] = "DEATHKNIGHT_UNHOLY",
    [253] = "HUNTER_BEASTMASTERY", [254] = "HUNTER_MARKSMANSHIP", [255] = "HUNTER_SURVIVAL",
    [256] = "PRIEST_DISC", [257] = "PRIEST_HOLY", [258] = "PRIEST_SHADOW",
    [259] = "ROGUE_ASSASSINATION", [260] = "ROGUE_OUTLAW", [261] = "ROGUE_SUBTLETY",
    [262] = "SHAMAN_ELEMENTAL", [263] = "SHAMAN_ENHANCEMENT", [264] = "SHAMAN_RESTORATION",
    [265] = "WARLOCK_AFFLICTION", [266] = "WARLOCK_DEMONOLOGY", [267] = "WARLOCK_DESTRUCTION",
    [268] = "MONK_BREWMASTER", [269] = "MONK_WINDWALKER", [270] = "MONK_MISTWEAVER",
    [577] = "DEMONHUNTER_HAVOC", [581] = "DEMONHUNTER_VENGEANCE", [1382] = "DEMONHUNTER_DEVOURER",
    [1467] = "EVOKER_DEVASTATION", [1468] = "EVOKER_PRESERVATION", [1473] = "EVOKER_AUGMENTATION",
}

local SLOT_KEY_BY_NAME = {
    ["무기"] = "MAIN_HAND",
    ["보조장비"] = "OFF_HAND",
    ["방패"] = "OFF_HAND",
    ["머리"] = "HEAD",
    ["목"] = "NECK",
    ["어깨"] = "SHOULDER",
    ["망토"] = "BACK",
    ["가슴"] = "CHEST",
    ["손목"] = "WRIST",
    ["손"] = "HANDS",
    ["허리"] = "WAIST",
    ["다리"] = "LEGS",
    ["발"] = "FEET",
    ["반지"] = "FINGER",
    ["장신구"] = "TRINKET",
}

local SOURCE_KEY_BY_GROUP = {
    mythicplus = "MPLUS_END_DUNGEON",
    raid = "RAID_NORMAL",
    crafted = "UNKNOWN",
    tier = "CATALYST",
}

function Scoring:ScoreItemLink(specID, slotName, itemLink, sourceGroup)
    local core = _G.MidnightS1MPlusDB
    local specKey = SPEC_KEY_BY_ID[tonumber(specID)]
    if not core or not specKey or type(itemLink) ~= "string" or itemLink == "" then
        return nil
    end
    if type(core.BuildRuntimeItemRecord) ~= "function" or type(core.ScoreItemRecord) ~= "function" then
        return nil
    end

    local slotKey = SLOT_KEY_BY_NAME[slotName] or tostring(slotName or "UNKNOWN")
    local sourceKey = SOURCE_KEY_BY_GROUP[sourceGroup] or "UNKNOWN"
    local options = {
        keyLevel = sourceGroup == "mythicplus" and 10 or nil,
        tierSetPiece = sourceGroup == "tier",
    }
    local ok, record = pcall(core.BuildRuntimeItemRecord, itemLink, specKey, sourceKey, options, slotKey)
    if not ok or type(record) ~= "table" then
        return nil
    end
    local scoreOK, score, evidence = pcall(core.ScoreItemRecord, record, specKey, slotKey)
    if not scoreOK then
        return nil
    end
    return tonumber(score), evidence
end
