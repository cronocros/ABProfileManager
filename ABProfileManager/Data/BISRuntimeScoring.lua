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

local SCORE_CACHE = {}

local function cacheValue(value)
    if value == nil then
        return "nil"
    end
    return type(value) .. ":" .. tostring(value)
end

local function buildCacheKey(specID, slotName, itemLink, sourceGroup, options)
    return table.concat({
        cacheValue(specID),
        cacheValue(slotName),
        cacheValue(itemLink),
        cacheValue(sourceGroup),
        cacheValue(options.actualItemLevel),
        cacheValue(options.keyLevel),
        cacheValue(options.tierSetPiece),
        cacheValue(options.sourceKey),
    }, "\031")
end

local function getRuntimeContext(specID, slotName, sourceGroup, options)
    local specKey = SPEC_KEY_BY_ID[tonumber(specID)]
    local slotKey = SLOT_KEY_BY_NAME[slotName] or tostring(slotName or "UNKNOWN")
    local sourceKey = SOURCE_KEY_BY_GROUP[sourceGroup] or "UNKNOWN"
    local runtimeOptions = {
        keyLevel = sourceGroup == "mythicplus" and 10 or nil,
        tierSetPiece = sourceGroup == "tier",
    }
    if type(options) == "table" then
        for _, key in ipairs({ "actualItemLevel", "baseItemId", "keyLevel", "rawStats", "sourceKey", "tierSetPiece" }) do
            if options[key] ~= nil then
                runtimeOptions[key] = options[key]
            end
        end
        sourceKey = runtimeOptions.sourceKey or sourceKey
    end
    runtimeOptions.sourceKey = sourceKey
    return specKey, slotKey, runtimeOptions
end

local function buildRawStatsKey(rawStats)
    local parts = {}
    for key, value in pairs(type(rawStats) == "table" and rawStats or {}) do
        local numeric = tonumber(value)
        if numeric then
            parts[#parts + 1] = tostring(key) .. "=" .. tostring(numeric)
        end
    end
    table.sort(parts)
    return table.concat(parts, ",")
end

function Scoring:ScoreItemLink(specID, slotName, itemLink, sourceGroup, options)
    local core = _G.MidnightS1MPlusDB
    local specKey, slotKey, runtimeOptions = getRuntimeContext(specID, slotName, sourceGroup, options)
    if not core or not specKey or type(itemLink) ~= "string" or itemLink == "" then
        return nil
    end
    if type(core.BuildRuntimeItemRecord) ~= "function" or type(core.ScoreItemRecord) ~= "function" then
        return nil
    end

    local cacheKey = buildCacheKey(specID, slotName, itemLink, sourceGroup, runtimeOptions)
    local cached = SCORE_CACHE[cacheKey]
    if cached ~= nil then
        if cached == false then
            return nil
        end
        return cached.score, cached.evidence
    end

    local ok, record = pcall(core.BuildRuntimeItemRecord, itemLink, specKey, runtimeOptions.sourceKey, runtimeOptions, slotKey)
    if not ok or type(record) ~= "table" then
        SCORE_CACHE[cacheKey] = false
        return nil
    end
    if type(record.rawStats) ~= "table" or not next(record.rawStats) then
        return nil
    end
    local scoreOK, score, evidence = pcall(core.ScoreItemRecord, record, specKey, slotKey)
    if not scoreOK then
        SCORE_CACHE[cacheKey] = false
        return nil
    end
    local numericScore = tonumber(score)
    SCORE_CACHE[cacheKey] = {
        score = numericScore,
        evidence = evidence,
    }
    return numericScore, evidence
end

function Scoring:ScoreItemSnapshot(specID, slotName, snapshot, sourceGroup, options)
    local core = _G.MidnightS1MPlusDB
    local itemID = type(snapshot) == "table" and tonumber(snapshot.itemID) or nil
    local rawStats = type(snapshot) == "table" and snapshot.rawStats or nil
    local actualItemLevel = type(snapshot) == "table" and tonumber(snapshot.itemLevel) or nil
    local specKey, slotKey, runtimeOptions = getRuntimeContext(specID, slotName, sourceGroup, options)
    if not core or not specKey or not itemID or not actualItemLevel or type(rawStats) ~= "table" or not next(rawStats) then
        return nil
    end
    if type(core.BuildRuntimeItemRecord) ~= "function" or type(core.ScoreItemRecord) ~= "function" then
        return nil
    end

    runtimeOptions.actualItemLevel = actualItemLevel
    runtimeOptions.baseItemId = itemID
    runtimeOptions.rawStats = rawStats
    local snapshotKey = table.concat({
        "snapshot",
        tostring(itemID),
        tostring(actualItemLevel),
        buildRawStatsKey(rawStats),
    }, ":")
    local cacheKey = buildCacheKey(specID, slotName, snapshotKey, sourceGroup, runtimeOptions)
    local cached = SCORE_CACHE[cacheKey]
    if cached ~= nil then
        if cached == false then
            return nil
        end
        return cached.score, cached.evidence
    end

    local ok, record = pcall(
        core.BuildRuntimeItemRecord,
        "item:" .. tostring(itemID),
        specKey,
        runtimeOptions.sourceKey,
        runtimeOptions,
        slotKey
    )
    if not ok or type(record) ~= "table" or type(record.rawStats) ~= "table" or not next(record.rawStats) then
        SCORE_CACHE[cacheKey] = false
        return nil
    end
    local scoreOK, score, evidence = pcall(core.ScoreItemRecord, record, specKey, slotKey)
    if not scoreOK then
        SCORE_CACHE[cacheKey] = false
        return nil
    end
    local numericScore = tonumber(score)
    SCORE_CACHE[cacheKey] = {
        score = numericScore,
        evidence = evidence,
    }
    return numericScore, evidence
end

function Scoring:ScoreItemSnapshotSecondaryPriority(specID, slotName, snapshot)
    local core = _G.MidnightS1MPlusDB
    local itemID = type(snapshot) == "table" and tonumber(snapshot.itemID) or nil
    local rawStats = type(snapshot) == "table" and snapshot.rawStats or nil
    local actualItemLevel = type(snapshot) == "table" and tonumber(snapshot.itemLevel) or nil
    local specKey, slotKey = getRuntimeContext(specID, slotName, "mythicplus", nil)
    local spec = core and core.SPECS and core.SPECS[specKey]
    if not core or not spec or not itemID or type(rawStats) ~= "table" or not next(rawStats) then
        return nil
    end
    if type(core.NormalizeStats) ~= "function" then
        return nil
    end

    local snapshotKey = table.concat({
        "secondary-snapshot",
        tostring(itemID),
        tostring(actualItemLevel),
        buildRawStatsKey(rawStats),
    }, ":")
    local cacheKey = buildCacheKey(specID, slotKey, snapshotKey, "secondary", {})
    local cached = SCORE_CACHE[cacheKey]
    if cached ~= nil then
        if cached == false then
            return nil
        end
        return cached.score, cached.evidence
    end

    local stats = core.NormalizeStats(rawStats)
    local score = 0
    local evidence = { notes = {}, specKey = specKey, priority = spec.priority, secondaryOnly = true }
    for statKo, weight in pairs(spec.weights or {}) do
        local value = tonumber(stats[statKo] or 0) or 0
        if value > 0 then
            score = score + value * weight
            evidence.notes[#evidence.notes + 1] = statKo .. "=" .. value .. "*" .. weight
        end
    end
    if score <= 0 then
        SCORE_CACHE[cacheKey] = false
        return nil
    end

    evidence.score = score
    SCORE_CACHE[cacheKey] = {
        score = score,
        evidence = evidence,
    }
    return score, evidence
end
