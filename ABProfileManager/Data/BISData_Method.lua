local _, ns = ...

-- Wowhead Midnight Season 1 overall BIS dataset
-- Generated from Wowhead current Overall BiS guides. This file is treated as the
-- authoritative current-season source for BISOverlay.
ns.Data = ns.Data or {}
ns.Data.BISItems = ns.Data.BISItems or {}

local legacyDungeonFallbacks = {}
for specID, entries in pairs(ns.Data.BISItems) do
    local copiedEntries = {}
    for _, entry in ipairs(entries) do
        local copy = {}
        for key, value in pairs(entry) do
            copy[key] = value
        end
        copiedEntries[#copiedEntries + 1] = copy
    end
    legacyDungeonFallbacks[specID] = copiedEntries
end

local function cloneEntry(entry)
    local copy = {}
    for key, value in pairs(entry or {}) do
        copy[key] = value
    end
    copy.sourceType = copy.sourceType or "mythicplus"
    copy.sourceLabel = copy.sourceLabel or copy.dungeon or copy.boss or nil
    return copy
end

local function buildEntryKey(entry)
    return string.format("%s:%s", tostring(entry and entry.slot or ""), tostring(entry and entry.itemID or 0))
end

local function nextFallbackNote(existingCount)
    if existingCount <= 0 then
        return "BIS"
    end
    if existingCount == 1 then
        return "대체재"
    end
    if existingCount == 2 then
        return "2순위"
    end
    return "3순위"
end

local function isBisNote(note)
    return note == "BIS"
end

local function isMythicPlusEntry(entry)
    if not entry then
        return false
    end
    if entry.sourceType then
        return entry.sourceType == "mythicplus"
    end
    return entry.dungeon ~= nil and entry.dungeon ~= ""
end

local overallOverrides = {
    [62] = {
        { dungeon = "하늘탑", boss = nil, itemID = 258218, slot = "무기", note = "BIS", sourceType = "mythicplus", sourceLabel = "Skyreach" },
        { dungeon = "윈드러너 첨탑", boss = nil, itemID = 251094, slot = "보조장비", note = "BIS", sourceType = "mythicplus", sourceLabel = "Windrunner Spire" },
        { dungeon = nil, boss = nil, itemID = 250060, slot = "머리", note = "BIS", sourceType = "raid", sourceLabel = "Tier Set" },
        { dungeon = nil, boss = nil, itemID = 250247, slot = "목", note = "BIS", sourceType = "raid", sourceLabel = "Midnight Falls" },
        { dungeon = nil, boss = nil, itemID = 250058, slot = "어깨", note = "BIS", sourceType = "raid", sourceLabel = "Tier Set" },
        { dungeon = nil, boss = nil, itemID = 239661, slot = "망토", note = "BIS", sourceType = "crafted", sourceLabel = "Crafting" },
        { dungeon = nil, boss = nil, itemID = 250063, slot = "가슴", note = "BIS", sourceType = "raid", sourceLabel = "Tier Set" },
        { dungeon = nil, boss = nil, itemID = 239660, slot = "손목", note = "BIS", sourceType = "crafted", sourceLabel = "Crafting" },
        { dungeon = nil, boss = nil, itemID = 250061, slot = "손", note = "BIS", sourceType = "raid", sourceLabel = "Tier Set" },
        { dungeon = nil, boss = nil, itemID = 249376, slot = "허리", note = "BIS", sourceType = "raid", sourceLabel = "Belo'ren" },
        { dungeon = "윈드러너 첨탑", boss = nil, itemID = 251090, slot = "다리", note = "BIS", sourceType = "mythicplus", sourceLabel = "Windrunner Spire" },
        { dungeon = nil, boss = nil, itemID = 249373, slot = "발", note = "BIS", sourceType = "raid", sourceLabel = "Chimaerus" },
        { dungeon = nil, boss = nil, itemID = 249919, slot = "반지", note = "BIS", sourceType = "raid", sourceLabel = "Belo'ren" },
        { dungeon = nil, boss = nil, itemID = 249920, slot = "반지", note = "BIS", sourceType = "raid", sourceLabel = "Midnight Falls" },
        { dungeon = nil, boss = nil, itemID = 249346, slot = "장신구", note = "BIS", sourceType = "raid", sourceLabel = "Vaelgor & Ezzorak" },
        { dungeon = nil, boss = nil, itemID = 249343, slot = "장신구", note = "BIS", sourceType = "raid", sourceLabel = "Chimaerus" },
    },
    [63] = {
        { dungeon = nil, boss = nil, itemID = 249286, slot = "무기", note = "BIS", sourceType = "raid", sourceLabel = "Midnight Falls" },
        { dungeon = nil, boss = nil, itemID = 250060, slot = "머리", note = "BIS", sourceType = "raid", sourceLabel = "Tier Set" },
        { dungeon = nil, boss = nil, itemID = 250247, slot = "목", note = "BIS", sourceType = "raid", sourceLabel = "Midnight Falls" },
        { dungeon = nil, boss = nil, itemID = 250058, slot = "어깨", note = "BIS", sourceType = "raid", sourceLabel = "Tier Set" },
        { dungeon = nil, boss = nil, itemID = 239656, slot = "망토", note = "BIS", sourceType = "crafted", sourceLabel = "Crafting" },
        { dungeon = nil, boss = nil, itemID = 249912, slot = "가슴", note = "BIS", sourceType = "raid", sourceLabel = "Midnight Falls" },
        { dungeon = nil, boss = nil, itemID = 239648, slot = "손목", note = "BIS", sourceType = "crafted", sourceLabel = "Crafting" },
        { dungeon = nil, boss = nil, itemID = 250061, slot = "손", note = "BIS", sourceType = "raid", sourceLabel = "Tier Set" },
        { dungeon = nil, boss = nil, itemID = 249376, slot = "허리", note = "BIS", sourceType = "raid", sourceLabel = "Belo'ren" },
        { dungeon = nil, boss = nil, itemID = 250059, slot = "다리", note = "BIS", sourceType = "raid", sourceLabel = "Tier Set" },
        { dungeon = "하늘탑", boss = nil, itemID = 258584, slot = "발", note = "BIS", sourceType = "mythicplus", sourceLabel = "Skyreach" },
        { dungeon = nil, boss = nil, itemID = 249920, slot = "반지", note = "BIS", sourceType = "raid", sourceLabel = "Midnight Falls" },
        { dungeon = nil, boss = nil, itemID = 249369, slot = "반지", note = "BIS", sourceType = "raid", sourceLabel = "Lightblinded Vanguard" },
        { dungeon = "윈드러너 첨탑", boss = nil, itemID = 250144, slot = "장신구", note = "BIS", sourceType = "mythicplus", sourceLabel = "Windrunner Spire" },
        { dungeon = nil, boss = nil, itemID = 249809, slot = "장신구", note = "BIS", sourceType = "raid", sourceLabel = "Crown of the Cosmos" },
    },
    [64] = {
        { dungeon = "삼두정의 권좌", boss = nil, itemID = 258514, slot = "무기", note = "BIS", sourceType = "mythicplus", sourceLabel = "Seat of the Triumvirate" },
        { dungeon = nil, boss = nil, itemID = 250060, slot = "머리", note = "BIS", sourceType = "raid", sourceLabel = "Tier Set" },
        { dungeon = nil, boss = nil, itemID = 250247, slot = "목", note = "BIS", sourceType = "raid", sourceLabel = "Midnight Falls" },
        { dungeon = "윈드러너 첨탑", boss = nil, itemID = 251085, slot = "어깨", note = "BIS", sourceType = "mythicplus", sourceLabel = "Windrunner Spire" },
        { dungeon = "하늘탑", boss = nil, itemID = 258575, slot = "망토", note = "BIS", sourceType = "mythicplus", sourceLabel = "Skyreach" },
        { dungeon = nil, boss = nil, itemID = 250063, slot = "가슴", note = "BIS", sourceType = "raid", sourceLabel = "Tier Set" },
        { dungeon = "하늘탑", boss = nil, itemID = 258580, slot = "손목", note = "BIS", sourceType = "mythicplus", sourceLabel = "Skyreach" },
        { dungeon = nil, boss = nil, itemID = 250061, slot = "손", note = "BIS", sourceType = "raid", sourceLabel = "Tier Set" },
        { dungeon = nil, boss = nil, itemID = 250057, slot = "허리", note = "BIS", sourceType = "raid", sourceLabel = "Catalyst" },
        { dungeon = nil, boss = nil, itemID = 250059, slot = "다리", note = "BIS", sourceType = "raid", sourceLabel = "Tier Set" },
        { dungeon = nil, boss = nil, itemID = 249373, slot = "발", note = "BIS", sourceType = "raid", sourceLabel = "Chimaerus" },
        { dungeon = nil, boss = nil, itemID = 249919, slot = "반지", note = "BIS", sourceType = "raid", sourceLabel = "Belo'ren" },
        { dungeon = "알게타르 대학", boss = nil, itemID = 193708, slot = "반지", note = "BIS", sourceType = "mythicplus", sourceLabel = "Algeth'ar Academy" },
        { dungeon = nil, boss = nil, itemID = 249343, slot = "장신구", note = "BIS", sourceType = "raid", sourceLabel = "Chimaerus" },
        { dungeon = nil, boss = nil, itemID = 249346, slot = "장신구", note = "BIS", sourceType = "raid", sourceLabel = "Vaelgor & Ezzorak" },
    },
    [65] = {
        { dungeon = "알게타르 대학", boss = nil, itemID = 193710, slot = "무기", note = "BIS", sourceType = "mythicplus", sourceLabel = "Algeth'ar Academy" },
        { dungeon = "하늘탑", boss = nil, itemID = 258049, slot = "방패", note = "BIS", sourceType = "mythicplus", sourceLabel = "Skyreach" },
        { dungeon = nil, boss = nil, itemID = 249961, slot = "머리", note = "BIS", sourceType = "raid", sourceLabel = "Lightblinded Vanguard" },
        { dungeon = nil, boss = nil, itemID = 250247, slot = "목", note = "BIS", sourceType = "raid", sourceLabel = "Midnight Falls" },
        { dungeon = nil, boss = nil, itemID = 249959, slot = "어깨", note = "BIS", sourceType = "raid", sourceLabel = "Fallen-King Salhadaar" },
        { dungeon = "하늘탑", boss = nil, itemID = 258575, slot = "망토", note = "BIS", sourceType = "mythicplus", sourceLabel = "Skyreach" },
        { dungeon = nil, boss = nil, itemID = 249964, slot = "가슴", note = "BIS", sourceType = "raid", sourceLabel = "Chimaerus" },
        { dungeon = "마이사라 동굴", boss = nil, itemID = 263193, slot = "손목", note = "BIS", sourceType = "mythicplus", sourceLabel = "Maisara Caverns" },
        { dungeon = nil, boss = nil, itemID = 249962, slot = "손", note = "BIS", sourceType = "raid", sourceLabel = "Vorasius" },
        { dungeon = nil, boss = nil, itemID = 249331, slot = "허리", note = "BIS", sourceType = "raid", sourceLabel = "Vaelgor & Ezzorak" },
        { dungeon = nil, boss = nil, itemID = 249915, slot = "다리", note = "BIS", sourceType = "raid", sourceLabel = "Midnight Falls" },
        { dungeon = nil, boss = nil, itemID = 249332, slot = "발", note = "BIS", sourceType = "raid", sourceLabel = "Vorasius" },
        { dungeon = nil, boss = nil, itemID = 249920, slot = "반지", note = "BIS", sourceType = "raid", sourceLabel = "Midnight Falls" },
        { dungeon = nil, boss = nil, itemID = 249919, slot = "반지", note = "BIS", sourceType = "raid", sourceLabel = "Belo'ren" },
        { dungeon = nil, boss = nil, itemID = 249809, slot = "장신구", note = "BIS", sourceType = "raid", sourceLabel = "Crown of the Cosmos" },
        { dungeon = nil, boss = nil, itemID = 249343, slot = "장신구", note = "BIS", sourceType = "raid", sourceLabel = "Chimaerus" },
    },
    [66] = {
        { dungeon = nil, boss = nil, itemID = 249295, slot = "무기", note = "BIS", sourceType = "raid", sourceLabel = "Crown of the Cosmos" },
        { dungeon = nil, boss = nil, itemID = 249921, slot = "보조장비", note = "BIS", sourceType = "raid", sourceLabel = "Belo'ren" },
        { dungeon = nil, boss = nil, itemID = 249961, slot = "머리", note = "BIS", sourceType = "raid", sourceLabel = "Tier Set" },
        { dungeon = nil, boss = nil, itemID = 249368, slot = "목", note = "BIS", sourceType = "raid", sourceLabel = "Crown of the Cosmos" },
        { dungeon = nil, boss = nil, itemID = 249959, slot = "어깨", note = "BIS", sourceType = "raid", sourceLabel = "Tier Set" },
        { dungeon = nil, boss = nil, itemID = 249370, slot = "망토", note = "BIS", sourceType = "raid", sourceLabel = "Vaelgor & Ezzorak" },
        { dungeon = nil, boss = nil, itemID = 249964, slot = "가슴", note = "BIS", sourceType = "raid", sourceLabel = "Tier Set" },
        { dungeon = nil, boss = nil, itemID = 249326, slot = "손목", note = "BIS", sourceType = "raid", sourceLabel = "Imperator Averzian" },
        { dungeon = "삼두정의 권좌", boss = nil, itemID = 151332, slot = "손", note = "BIS", sourceType = "mythicplus", sourceLabel = "Seat of the Triumvirate" },
        { dungeon = nil, boss = nil, itemID = 249331, slot = "허리", note = "BIS", sourceType = "raid", sourceLabel = "Vaelgor & Ezzorak" },
        { dungeon = nil, boss = nil, itemID = 249960, slot = "다리", note = "BIS", sourceType = "raid", sourceLabel = "Tier Set" },
        { dungeon = nil, boss = nil, itemID = 249381, slot = "발", note = "BIS", sourceType = "raid", sourceLabel = "Chimaerus" },
        { dungeon = nil, boss = nil, itemID = 249920, slot = "반지", note = "BIS", sourceType = "raid", sourceLabel = "Midnight Falls" },
        { dungeon = "삼두정의 권좌", boss = nil, itemID = 151311, slot = "반지", note = "BIS", sourceType = "mythicplus", sourceLabel = "Seat of the Triumvirate" },
        { dungeon = nil, boss = nil, itemID = 249343, slot = "장신구", note = "BIS", sourceType = "raid", sourceLabel = "Chimaerus" },
        { dungeon = nil, boss = nil, itemID = 249342, slot = "장신구", note = "BIS", sourceType = "raid", sourceLabel = "Vorasius" },
    },
    [70] = {
        { dungeon = nil, boss = nil, itemID = 249277, slot = "무기", note = "BIS", sourceType = "raid", sourceLabel = "Lightblinded Vanguard" },
        { dungeon = nil, boss = nil, itemID = 249961, slot = "머리", note = "BIS", sourceType = "raid", sourceLabel = "Tier Set" },
        { dungeon = nil, boss = nil, itemID = 250247, slot = "목", note = "BIS", sourceType = "raid", sourceLabel = "Midnight Falls" },
        { dungeon = nil, boss = nil, itemID = 249959, slot = "어깨", note = "BIS", sourceType = "raid", sourceLabel = "Tier Set" },
        { dungeon = nil, boss = nil, itemID = 239656, slot = "망토", note = "BIS", sourceType = "crafted", sourceLabel = "Crafting" },
        { dungeon = nil, boss = nil, itemID = 249964, slot = "가슴", note = "BIS", sourceType = "raid", sourceLabel = "Tier Set" },
        { dungeon = nil, boss = nil, itemID = 237834, slot = "손목", note = "BIS", sourceType = "crafted", sourceLabel = "Crafting" },
        { dungeon = "삼두정의 권좌", boss = nil, itemID = 151332, slot = "손", note = "BIS", sourceType = "mythicplus", sourceLabel = "Seat of the Triumvirate" },
        { dungeon = nil, boss = nil, itemID = 249380, slot = "허리", note = "BIS", sourceType = "raid", sourceLabel = "Crown of the Cosmos" },
        { dungeon = nil, boss = nil, itemID = 249960, slot = "다리", note = "BIS", sourceType = "raid", sourceLabel = "Tier Set" },
        { dungeon = nil, boss = nil, itemID = 249381, slot = "발", note = "BIS", sourceType = "raid", sourceLabel = "Chimaerus" },
        { dungeon = nil, boss = nil, itemID = 249919, slot = "반지", note = "BIS", sourceType = "raid", sourceLabel = "Belo'ren" },
        { dungeon = nil, boss = nil, itemID = 249920, slot = "반지", note = "BIS", sourceType = "raid", sourceLabel = "Midnight Falls" },
        { dungeon = nil, boss = nil, itemID = 260235, slot = "장신구", note = "BIS", sourceType = "raid", sourceLabel = "Belo'ren" },
        { dungeon = "알게타르 대학", boss = nil, itemID = 193701, slot = "장신구", note = "BIS", sourceType = "mythicplus", sourceLabel = "Algeth'ar Academy" },
    },
    [71] = {
        { dungeon = nil, boss = nil, itemID = 249952, slot = "머리", note = "BIS", sourceType = "raid", sourceLabel = "Tier Set" },
        { dungeon = nil, boss = nil, itemID = 249337, slot = "목", note = "BIS", sourceType = "raid", sourceLabel = "Fallen-King Salhadaar" },
        { dungeon = nil, boss = nil, itemID = 249950, slot = "어깨", note = "BIS", sourceType = "raid", sourceLabel = "Tier Set" },
        { dungeon = nil, boss = nil, itemID = 239656, slot = "망토", note = "BIS", sourceType = "crafted", sourceLabel = "Crafting" },
        { dungeon = nil, boss = nil, itemID = 249955, slot = "가슴", note = "BIS", sourceType = "raid", sourceLabel = "Chimaerus" },
        { dungeon = nil, boss = nil, itemID = 237834, slot = "손목", note = "BIS", sourceType = "crafted", sourceLabel = "Crafting" },
        { dungeon = "윈드러너 첨탑", boss = nil, itemID = 251081, slot = "손", note = "BIS", sourceType = "mythicplus", sourceLabel = "Windrunner Spire" },
        { dungeon = nil, boss = nil, itemID = 249949, slot = "허리", note = "BIS", sourceType = "raid", sourceLabel = "Catalyst" },
        { dungeon = nil, boss = nil, itemID = 249951, slot = "다리", note = "BIS", sourceType = "raid", sourceLabel = "Tier Set" },
        { dungeon = nil, boss = nil, itemID = 249381, slot = "발", note = "BIS", sourceType = "raid", sourceLabel = "Chimaerus" },
        { dungeon = nil, boss = nil, itemID = 249920, slot = "반지", note = "BIS", sourceType = "raid", sourceLabel = "Midnight Falls" },
        { dungeon = "공결탑 제나스", boss = nil, itemID = 251217, slot = "반지", note = "BIS", sourceType = "mythicplus", sourceLabel = "Nexus-Point Xenas" },
        { dungeon = nil, boss = nil, itemID = 249343, slot = "장신구", note = "BIS", sourceType = "raid", sourceLabel = "Chimaerus" },
        { dungeon = nil, boss = nil, itemID = 249342, slot = "장신구", note = "BIS", sourceType = "raid", sourceLabel = "Vorasius" },
        { dungeon = nil, boss = nil, itemID = 249296, slot = "무기", note = "BIS", sourceType = "raid", sourceLabel = "Midnight Falls" },
    },
    [72] = {
        { dungeon = nil, boss = nil, itemID = 249952, slot = "머리", note = "BIS", sourceType = "raid", sourceLabel = "Tier Set" },
        { dungeon = nil, boss = nil, itemID = 250247, slot = "목", note = "BIS", sourceType = "raid", sourceLabel = "Midnight Falls" },
        { dungeon = nil, boss = nil, itemID = 249950, slot = "어깨", note = "BIS", sourceType = "raid", sourceLabel = "Tier Set" },
        { dungeon = "하늘탑", boss = nil, itemID = 258575, slot = "망토", note = "BIS", sourceType = "mythicplus", sourceLabel = "Skyreach" },
        { dungeon = nil, boss = nil, itemID = 249955, slot = "가슴", note = "BIS", sourceType = "raid", sourceLabel = "Chimaerus" },
        { dungeon = nil, boss = nil, itemID = 237834, slot = "손목", note = "BIS", sourceType = "crafted", sourceLabel = "Crafting" },
        { dungeon = "삼두정의 권좌", boss = nil, itemID = 151332, slot = "손", note = "BIS", sourceType = "mythicplus", sourceLabel = "Seat of the Triumvirate" },
        { dungeon = nil, boss = nil, itemID = 249949, slot = "허리", note = "BIS", sourceType = "raid", sourceLabel = "Catalyst" },
        { dungeon = nil, boss = nil, itemID = 249951, slot = "다리", note = "BIS", sourceType = "raid", sourceLabel = "Tier Set" },
        { dungeon = nil, boss = nil, itemID = 249954, slot = "발", note = "BIS", sourceType = "raid", sourceLabel = "Catalyst" },
        { dungeon = nil, boss = nil, itemID = 249920, slot = "반지", note = "BIS", sourceType = "raid", sourceLabel = "Midnight Falls" },
        { dungeon = "알게타르 대학", boss = nil, itemID = 193708, slot = "반지", note = "BIS", sourceType = "mythicplus", sourceLabel = "Algeth'ar Academy" },
        { dungeon = nil, boss = nil, itemID = 249343, slot = "장신구", note = "BIS", sourceType = "raid", sourceLabel = "Chimaerus" },
        { dungeon = nil, boss = nil, itemID = 249342, slot = "장신구", note = "BIS", sourceType = "raid", sourceLabel = "Vorasius" },
        { dungeon = nil, boss = nil, itemID = 249277, slot = "무기", note = "BIS", sourceType = "raid", sourceLabel = "Lightblinded Vanguard" },
        { dungeon = nil, boss = nil, itemID = 237846, slot = "보조장비", note = "BIS", sourceType = "crafted", sourceLabel = "Crafting" },
    },
    [73] = {
        { dungeon = nil, boss = nil, itemID = 249295, slot = "무기", note = "BIS", sourceType = "raid", sourceLabel = "Crown of the Cosmos" },
        { dungeon = nil, boss = nil, itemID = 249921, slot = "보조장비", note = "BIS", sourceType = "raid", sourceLabel = "Belo'ren" },
        { dungeon = nil, boss = nil, itemID = 249952, slot = "머리", note = "BIS", sourceType = "raid", sourceLabel = "Tier Set" },
        { dungeon = nil, boss = nil, itemID = 249368, slot = "목", note = "BIS", sourceType = "raid", sourceLabel = "Crown of the Cosmos" },
        { dungeon = nil, boss = nil, itemID = 249950, slot = "어깨", note = "BIS", sourceType = "raid", sourceLabel = "Tier Set" },
        { dungeon = nil, boss = nil, itemID = 249370, slot = "망토", note = "BIS", sourceType = "raid", sourceLabel = "Vaelgor & Ezzorak" },
        { dungeon = nil, boss = nil, itemID = 249955, slot = "가슴", note = "BIS", sourceType = "raid", sourceLabel = "Tier Set" },
        { dungeon = nil, boss = nil, itemID = 249326, slot = "손목", note = "BIS", sourceType = "raid", sourceLabel = "Imperator Averzian" },
        { dungeon = "삼두정의 권좌", boss = nil, itemID = 151332, slot = "손", note = "BIS", sourceType = "mythicplus", sourceLabel = "Seat of the Triumvirate" },
        { dungeon = nil, boss = nil, itemID = 249331, slot = "허리", note = "BIS", sourceType = "raid", sourceLabel = "Vaelgor & Ezzorak" },
        { dungeon = nil, boss = nil, itemID = 249951, slot = "다리", note = "BIS", sourceType = "raid", sourceLabel = "Tier Set" },
        { dungeon = nil, boss = nil, itemID = 249381, slot = "발", note = "BIS", sourceType = "raid", sourceLabel = "Chimaerus" },
        { dungeon = nil, boss = nil, itemID = 249920, slot = "반지", note = "BIS", sourceType = "raid", sourceLabel = "Midnight Falls" },
        { dungeon = "삼두정의 권좌", boss = nil, itemID = 151311, slot = "반지", note = "BIS", sourceType = "mythicplus", sourceLabel = "Seat of the Triumvirate" },
        { dungeon = nil, boss = nil, itemID = 249343, slot = "장신구", note = "BIS", sourceType = "raid", sourceLabel = "Chimaerus" },
        { dungeon = nil, boss = nil, itemID = 249342, slot = "장신구", note = "BIS", sourceType = "raid", sourceLabel = "Vorasius" },
    },
    [102] = {
        { dungeon = nil, boss = nil, itemID = 249283, slot = "무기", note = "BIS", sourceType = "raid", sourceLabel = "Belo'ren" },
        { dungeon = nil, boss = nil, itemID = 245769, slot = "보조장비", note = "BIS", sourceType = "crafted", sourceLabel = "Crafting" },
        { dungeon = nil, boss = nil, itemID = 250024, slot = "머리", note = "BIS", sourceType = "raid", sourceLabel = "Tier Set" },
        { dungeon = nil, boss = nil, itemID = 250247, slot = "목", note = "BIS", sourceType = "raid", sourceLabel = "Midnight Falls" },
        { dungeon = nil, boss = nil, itemID = 250022, slot = "어깨", note = "BIS", sourceType = "raid", sourceLabel = "Tier Set" },
        { dungeon = nil, boss = nil, itemID = 249370, slot = "망토", note = "BIS", sourceType = "raid", sourceLabel = "Vaelgor & Ezzorak" },
        { dungeon = nil, boss = nil, itemID = 250027, slot = "가슴", note = "BIS", sourceType = "raid", sourceLabel = "Tier Set" },
        { dungeon = nil, boss = nil, itemID = 244576, slot = "손목", note = "BIS", sourceType = "crafted", sourceLabel = "Crafting" },
        { dungeon = "마법학자의 정원", boss = nil, itemID = 251113, slot = "손", note = "BIS", sourceType = "mythicplus", sourceLabel = "Magisters' Terrace" },
        { dungeon = "윈드러너 첨탑", boss = nil, itemID = 251082, slot = "허리", note = "BIS", sourceType = "mythicplus", sourceLabel = "Windrunner Spire" },
        { dungeon = nil, boss = nil, itemID = 250023, slot = "다리", note = "BIS", sourceType = "raid", sourceLabel = "Tier Set" },
        { dungeon = nil, boss = nil, itemID = 249382, slot = "발", note = "BIS", sourceType = "raid", sourceLabel = "Crown of the Cosmos" },
        { dungeon = "알게타르 대학", boss = nil, itemID = 193708, slot = "반지", note = "BIS", sourceType = "mythicplus", sourceLabel = "Algeth'ar Academy" },
        { dungeon = "공결탑 제나스", boss = nil, itemID = 251217, slot = "반지", note = "BIS", sourceType = "mythicplus", sourceLabel = "Nexus-Point Xenas" },
        { dungeon = nil, boss = nil, itemID = 249346, slot = "장신구", note = "BIS", sourceType = "raid", sourceLabel = "Vaelgor & Ezzorak" },
        { dungeon = nil, boss = nil, itemID = 249809, slot = "장신구", note = "BIS", sourceType = "raid", sourceLabel = "Crown of the Cosmos" },
    },
    [103] = {
        { dungeon = nil, boss = nil, itemID = 249302, slot = "무기", note = "BIS", sourceType = "raid", sourceLabel = "Vorasius" },
        { dungeon = nil, boss = nil, itemID = 250024, slot = "머리", note = "BIS", sourceType = "raid", sourceLabel = "Tier Set" },
        { dungeon = nil, boss = nil, itemID = 250247, slot = "목", note = "BIS", sourceType = "raid", sourceLabel = "Midnight Falls" },
        { dungeon = nil, boss = nil, itemID = 250022, slot = "어깨", note = "BIS", sourceType = "raid", sourceLabel = "Tier Set" },
        { dungeon = nil, boss = nil, itemID = 249370, slot = "망토", note = "BIS", sourceType = "raid", sourceLabel = "Vaelgor & Ezzorak" },
        { dungeon = nil, boss = nil, itemID = 250027, slot = "가슴", note = "BIS", sourceType = "raid", sourceLabel = "Tier Set" },
        { dungeon = nil, boss = nil, itemID = 244576, slot = "손목", note = "BIS", sourceType = "crafted", sourceLabel = "Crafting" },
        { dungeon = nil, boss = nil, itemID = 244575, slot = "손", note = "BIS", sourceType = "crafted", sourceLabel = "Crafting" },
        { dungeon = "윈드러너 첨탑", boss = nil, itemID = 251082, slot = "허리", note = "BIS", sourceType = "mythicplus", sourceLabel = "Windrunner Spire" },
        { dungeon = nil, boss = nil, itemID = 250023, slot = "다리", note = "BIS", sourceType = "raid", sourceLabel = "Tier Set" },
        { dungeon = nil, boss = nil, itemID = 249382, slot = "발", note = "BIS", sourceType = "raid", sourceLabel = "Crown of the Cosmos" },
        { dungeon = nil, boss = nil, itemID = 249920, slot = "반지", note = "BIS", sourceType = "raid", sourceLabel = "Midnight Falls" },
        { dungeon = "마법학자의 정원", boss = nil, itemID = 251115, slot = "반지", note = "BIS", sourceType = "mythicplus", sourceLabel = "Magisters' Terrace" },
        { dungeon = "알게타르 대학", boss = nil, itemID = 193701, slot = "장신구", note = "BIS", sourceType = "mythicplus", sourceLabel = "Algeth'ar Academy" },
        { dungeon = nil, boss = nil, itemID = 249806, slot = "장신구", note = "BIS", sourceType = "raid", sourceLabel = "Belo'ren" },
    },
    [104] = {
        { dungeon = nil, boss = nil, itemID = 249278, slot = "무기", note = "BIS", sourceType = "raid", sourceLabel = "Chimaerus" },
        { dungeon = nil, boss = nil, itemID = 249913, slot = "머리", note = "BIS", sourceType = "raid", sourceLabel = "Midnight Falls" },
        { dungeon = nil, boss = nil, itemID = 249368, slot = "목", note = "BIS", sourceType = "raid", sourceLabel = "Crown of the Cosmos" },
        { dungeon = nil, boss = nil, itemID = 250022, slot = "어깨", note = "BIS", sourceType = "raid", sourceLabel = "Tier Set" },
        { dungeon = nil, boss = nil, itemID = 249370, slot = "망토", note = "BIS", sourceType = "raid", sourceLabel = "Vaelgor & Ezzorak" },
        { dungeon = nil, boss = nil, itemID = 250027, slot = "가슴", note = "BIS", sourceType = "raid", sourceLabel = "Tier Set" },
        { dungeon = nil, boss = nil, itemID = 249327, slot = "손목", note = "BIS", sourceType = "raid", sourceLabel = "Vorasius" },
        { dungeon = nil, boss = nil, itemID = 250025, slot = "손", note = "BIS", sourceType = "raid", sourceLabel = "Tier Set" },
        { dungeon = nil, boss = nil, itemID = 249374, slot = "허리", note = "BIS", sourceType = "raid", sourceLabel = "Chimaerus" },
        { dungeon = nil, boss = nil, itemID = 250023, slot = "다리", note = "BIS", sourceType = "raid", sourceLabel = "Tier Set" },
        { dungeon = nil, boss = nil, itemID = 249334, slot = "발", note = "BIS", sourceType = "raid", sourceLabel = "Imperator Averzian" },
        { dungeon = "공결탑 제나스", boss = nil, itemID = 251093, slot = "반지", note = "BIS", sourceType = "mythicplus", sourceLabel = "Nexus-Point Xenas" },
        { dungeon = nil, boss = nil, itemID = 249920, slot = "반지", note = "BIS", sourceType = "raid", sourceLabel = "Midnight Falls" },
        { dungeon = nil, boss = nil, itemID = 249343, slot = "장신구", note = "BIS", sourceType = "raid", sourceLabel = "Chimaerus" },
        { dungeon = "알게타르 대학", boss = nil, itemID = 193701, slot = "장신구", note = "BIS", sourceType = "mythicplus", sourceLabel = "Algeth'ar Academy" },
    },
    [105] = {
        { dungeon = nil, boss = nil, itemID = 250024, slot = "머리", note = "BIS", sourceType = "raid", sourceLabel = "Raid" },
        { dungeon = nil, boss = nil, itemID = 250247, slot = "목", note = "BIS", sourceType = "raid", sourceLabel = "Midnight Falls" },
        { dungeon = nil, boss = nil, itemID = 250022, slot = "어깨", note = "BIS", sourceType = "raid", sourceLabel = "Raid" },
        { dungeon = nil, boss = nil, itemID = 249370, slot = "망토", note = "BIS", sourceType = "raid", sourceLabel = "Vaelgor & Ezzorak" },
        { dungeon = "공결탑 제나스", boss = nil, itemID = 251216, slot = "가슴", note = "BIS", sourceType = "mythicplus", sourceLabel = "Nexus-Point Xenas" },
        { dungeon = "알게타르 대학", boss = nil, itemID = 193714, slot = "손목", note = "BIS", sourceType = "mythicplus", sourceLabel = "Algeth'ar Academy" },
        { dungeon = nil, boss = nil, itemID = 250025, slot = "손", note = "BIS", sourceType = "raid", sourceLabel = "Raid" },
        { dungeon = nil, boss = nil, itemID = 249314, slot = "허리", note = "BIS", sourceType = "raid", sourceLabel = "Fallen-King Salhadaar" },
        { dungeon = nil, boss = nil, itemID = 250023, slot = "다리", note = "BIS", sourceType = "raid", sourceLabel = "Raid" },
        { dungeon = "공결탑 제나스", boss = nil, itemID = 251210, slot = "발", note = "BIS", sourceType = "mythicplus", sourceLabel = "Nexus-Point Xenas" },
        { dungeon = nil, boss = nil, itemID = 249920, slot = "반지", note = "BIS", sourceType = "raid", sourceLabel = "Midnight Falls" },
        { dungeon = "마법학자의 정원", boss = nil, itemID = 251115, slot = "반지", note = "BIS", sourceType = "mythicplus", sourceLabel = "Magisters' Terrace" },
        { dungeon = nil, boss = nil, itemID = 249809, slot = "장신구", note = "BIS", sourceType = "raid", sourceLabel = "Crown of the Cosmos" },
        { dungeon = nil, boss = nil, itemID = 249346, slot = "장신구", note = "BIS", sourceType = "raid", sourceLabel = "Vaelgor & Ezzorak" },
        { dungeon = nil, boss = nil, itemID = 249283, slot = "무기", note = "BIS", sourceType = "raid", sourceLabel = "Belo'ren" },
        { dungeon = nil, boss = nil, itemID = 249922, slot = "보조장비", note = "BIS", sourceType = "raid", sourceLabel = "Chimaerus" },
    },
    [250] = {
        { dungeon = "사론의 구덩이", boss = nil, itemID = 49802, slot = "무기", note = "BIS", sourceType = "mythicplus", sourceLabel = "Pit of Saron" },
        { dungeon = nil, boss = nil, itemID = 249970, slot = "머리", note = "BIS", sourceType = "raid", sourceLabel = "Tier Set" },
        { dungeon = nil, boss = nil, itemID = 249368, slot = "목", note = "BIS", sourceType = "raid", sourceLabel = "Crown of the Cosmos" },
        { dungeon = nil, boss = nil, itemID = 249968, slot = "어깨", note = "BIS", sourceType = "raid", sourceLabel = "Tier Set" },
        { dungeon = "마법학자의 정원", boss = nil, itemID = 260312, slot = "망토", note = "BIS", sourceType = "mythicplus", sourceLabel = "Magisters' Terrace" },
        { dungeon = nil, boss = nil, itemID = 249973, slot = "가슴", note = "BIS", sourceType = "crafted", sourceLabel = "Crafting" },
        { dungeon = nil, boss = nil, itemID = 237834, slot = "손목", note = "BIS", sourceType = "crafted", sourceLabel = "Crafting" },
        { dungeon = "삼두정의 권좌", boss = nil, itemID = 151332, slot = "손", note = "BIS", sourceType = "mythicplus", sourceLabel = "Seat of the Triumvirate" },
        { dungeon = "사론의 구덩이", boss = nil, itemID = 49808, slot = "허리", note = "BIS", sourceType = "mythicplus", sourceLabel = "Pit of Saron" },
        { dungeon = nil, boss = nil, itemID = 249969, slot = "다리", note = "BIS", sourceType = "raid", sourceLabel = "Tier Set" },
        { dungeon = nil, boss = nil, itemID = 249381, slot = "발", note = "BIS", sourceType = "raid", sourceLabel = "Chimaerus" },
        { dungeon = nil, boss = nil, itemID = 249920, slot = "반지", note = "BIS", sourceType = "raid", sourceLabel = "Midnight Falls" },
        { dungeon = nil, boss = nil, itemID = 251513, slot = "반지", note = "BIS", sourceType = "crafted", sourceLabel = "Crafting" },
        { dungeon = nil, boss = nil, itemID = 249343, slot = "장신구", note = "BIS", sourceType = "raid", sourceLabel = "Chimaerus" },
        { dungeon = nil, boss = nil, itemID = 249344, slot = "장신구", note = "BIS", sourceType = "raid", sourceLabel = "Imperator Averzian" },
    },
    [251] = {
        { dungeon = nil, boss = nil, itemID = 249277, slot = "무기", note = "BIS", sourceType = "raid", sourceLabel = "Lightblinded Vanguard" },
        { dungeon = nil, boss = nil, itemID = 249281, slot = "무기", note = "BIS", sourceType = "raid", sourceLabel = "Fallen-King Salhadaar" },
        { dungeon = nil, boss = nil, itemID = 249970, slot = "머리", note = "BIS", sourceType = "raid", sourceLabel = "Tier Set" },
        { dungeon = nil, boss = nil, itemID = 250247, slot = "목", note = "BIS", sourceType = "raid", sourceLabel = "Midnight Falls" },
        { dungeon = "사론의 구덩이", boss = nil, itemID = 50234, slot = "어깨", note = "BIS", sourceType = "mythicplus", sourceLabel = "Pit of Saron" },
        { dungeon = nil, boss = nil, itemID = 239656, slot = "망토", note = "BIS", sourceType = "crafted", sourceLabel = "Crafting" },
        { dungeon = nil, boss = nil, itemID = 249973, slot = "가슴", note = "BIS", sourceType = "raid", sourceLabel = "Tier Set" },
        { dungeon = nil, boss = nil, itemID = 237834, slot = "손목", note = "BIS", sourceType = "crafted", sourceLabel = "Crafting" },
        { dungeon = nil, boss = nil, itemID = 249971, slot = "손", note = "BIS", sourceType = "raid", sourceLabel = "Tier Set" },
        { dungeon = nil, boss = nil, itemID = 249380, slot = "허리", note = "BIS", sourceType = "raid", sourceLabel = "Crown of the Cosmos" },
        { dungeon = nil, boss = nil, itemID = 249969, slot = "다리", note = "BIS", sourceType = "raid", sourceLabel = "Tier Set" },
        { dungeon = nil, boss = nil, itemID = 249381, slot = "발", note = "BIS", sourceType = "raid", sourceLabel = "Chimaerus" },
        { dungeon = "알게타르 대학", boss = nil, itemID = 193708, slot = "반지", note = "BIS", sourceType = "mythicplus", sourceLabel = "Algeth'ar Academy" },
        { dungeon = nil, boss = nil, itemID = 249919, slot = "반지", note = "BIS", sourceType = "raid", sourceLabel = "Belo'ren" },
        { dungeon = nil, boss = nil, itemID = 249344, slot = "장신구", note = "BIS", sourceType = "raid", sourceLabel = "Imperator Averzian" },
        { dungeon = nil, boss = nil, itemID = 249343, slot = "장신구", note = "BIS", sourceType = "raid", sourceLabel = "Chimaerus" },
    },
    [252] = {
        { dungeon = nil, boss = nil, itemID = 249277, slot = "무기", note = "BIS", sourceType = "raid", sourceLabel = "Lightblinded Vanguard" },
        { dungeon = nil, boss = nil, itemID = 249970, slot = "머리", note = "BIS", sourceType = "raid", sourceLabel = "Tier Set" },
        { dungeon = nil, boss = nil, itemID = 250247, slot = "목", note = "BIS", sourceType = "raid", sourceLabel = "Midnight Falls" },
        { dungeon = "사론의 구덩이", boss = nil, itemID = 50234, slot = "어깨", note = "BIS", sourceType = "mythicplus", sourceLabel = "Pit of Saron" },
        { dungeon = nil, boss = nil, itemID = 239656, slot = "망토", note = "BIS", sourceType = "crafted", sourceLabel = "Crafting" },
        { dungeon = nil, boss = nil, itemID = 249973, slot = "가슴", note = "BIS", sourceType = "raid", sourceLabel = "Tier Set" },
        { dungeon = nil, boss = nil, itemID = 237834, slot = "손목", note = "BIS", sourceType = "crafted", sourceLabel = "Crafting" },
        { dungeon = nil, boss = nil, itemID = 249971, slot = "손", note = "BIS", sourceType = "raid", sourceLabel = "Tier Set" },
        { dungeon = nil, boss = nil, itemID = 249967, slot = "허리", note = "BIS", sourceType = "raid", sourceLabel = "Catalyst" },
        { dungeon = nil, boss = nil, itemID = 249969, slot = "다리", note = "BIS", sourceType = "raid", sourceLabel = "Tier Set" },
        { dungeon = nil, boss = nil, itemID = 249381, slot = "발", note = "BIS", sourceType = "raid", sourceLabel = "Chimaerus" },
        { dungeon = "알게타르 대학", boss = nil, itemID = 193708, slot = "반지", note = "BIS", sourceType = "mythicplus", sourceLabel = "Algeth'ar Academy" },
        { dungeon = nil, boss = nil, itemID = 249919, slot = "반지", note = "BIS", sourceType = "raid", sourceLabel = "Belo'ren" },
        { dungeon = nil, boss = nil, itemID = 249343, slot = "장신구", note = "BIS", sourceType = "raid", sourceLabel = "Chimaerus" },
        { dungeon = nil, boss = nil, itemID = 249344, slot = "장신구", note = "BIS", sourceType = "raid", sourceLabel = "Imperator Averzian" },
    },
    [253] = {
        { dungeon = "마이사라 동굴", boss = nil, itemID = 251174, slot = "무기", note = "BIS", sourceType = "mythicplus", sourceLabel = "Maisara Caverns" },
        { dungeon = nil, boss = nil, itemID = 249988, slot = "머리", note = "BIS", sourceType = "raid", sourceLabel = "Tier Set" },
        { dungeon = nil, boss = nil, itemID = 250247, slot = "목", note = "BIS", sourceType = "raid", sourceLabel = "Midnight Falls" },
        { dungeon = "삼두정의 권좌", boss = nil, itemID = 151323, slot = "어깨", note = "BIS", sourceType = "mythicplus", sourceLabel = "Seat of the Triumvirate" },
        { dungeon = "하늘탑", boss = nil, itemID = 258575, slot = "망토", note = "BIS", sourceType = "mythicplus", sourceLabel = "Skyreach" },
        { dungeon = nil, boss = nil, itemID = 249991, slot = "가슴", note = "BIS", sourceType = "raid", sourceLabel = "Tier Set" },
        { dungeon = "공결탑 제나스", boss = nil, itemID = 251209, slot = "손목", note = "BIS", sourceType = "mythicplus", sourceLabel = "Nexus-Point Xenas" },
        { dungeon = nil, boss = nil, itemID = 249989, slot = "손", note = "BIS", sourceType = "raid", sourceLabel = "Tier Set" },
        { dungeon = nil, boss = nil, itemID = 244611, slot = "허리", note = "BIS", sourceType = "crafted", sourceLabel = "Leatherworking" },
        { dungeon = nil, boss = nil, itemID = 249987, slot = "다리", note = "BIS", sourceType = "raid", sourceLabel = "Tier Set" },
        { dungeon = nil, boss = nil, itemID = 244610, slot = "발", note = "BIS", sourceType = "crafted", sourceLabel = "Leatherworking" },
        { dungeon = nil, boss = nil, itemID = 249920, slot = "반지", note = "BIS", sourceType = "raid", sourceLabel = "Midnight Falls" },
        { dungeon = nil, boss = nil, itemID = 249369, slot = "반지", note = "BIS", sourceType = "raid", sourceLabel = "Lightblinded Vanguard" },
        { dungeon = nil, boss = nil, itemID = 249806, slot = "장신구", note = "BIS", sourceType = "raid", sourceLabel = "Belo'ren" },
        { dungeon = "알게타르 대학", boss = nil, itemID = 193701, slot = "장신구", note = "BIS", sourceType = "mythicplus", sourceLabel = "Algeth'ar Academy" },
    },
    [254] = {
        { dungeon = nil, boss = nil, itemID = 249288, slot = "무기", note = "BIS", sourceType = "raid", sourceLabel = "Crown of the Cosmos" },
        { dungeon = nil, boss = nil, itemID = 249988, slot = "머리", note = "BIS", sourceType = "raid", sourceLabel = "Tier Set" },
        { dungeon = nil, boss = nil, itemID = 250247, slot = "목", note = "BIS", sourceType = "raid", sourceLabel = "Midnight Falls" },
        { dungeon = "삼두정의 권좌", boss = nil, itemID = 151323, slot = "어깨", note = "BIS", sourceType = "mythicplus", sourceLabel = "Seat of the Triumvirate" },
        { dungeon = nil, boss = nil, itemID = 249335, slot = "망토", note = "BIS", sourceType = "raid", sourceLabel = "Imperator Averzian" },
        { dungeon = nil, boss = nil, itemID = 249991, slot = "가슴", note = "BIS", sourceType = "raid", sourceLabel = "Tier Set" },
        { dungeon = nil, boss = nil, itemID = 249304, slot = "손목", note = "BIS", sourceType = "raid", sourceLabel = "Fallen-King Salhadaar" },
        { dungeon = nil, boss = nil, itemID = 249989, slot = "손", note = "BIS", sourceType = "raid", sourceLabel = "Tier Set" },
        { dungeon = nil, boss = nil, itemID = 244611, slot = "허리", note = "BIS", sourceType = "crafted", sourceLabel = "Crafting" },
        { dungeon = nil, boss = nil, itemID = 249987, slot = "다리", note = "BIS", sourceType = "raid", sourceLabel = "Tier Set" },
        { dungeon = nil, boss = nil, itemID = 244610, slot = "발", note = "BIS", sourceType = "crafted", sourceLabel = "Crafting" },
        { dungeon = nil, boss = nil, itemID = 249919, slot = "반지", note = "BIS", sourceType = "raid", sourceLabel = "Belo'ren" },
        { dungeon = nil, boss = nil, itemID = 249336, slot = "반지", note = "BIS", sourceType = "raid", sourceLabel = "Vorasius" },
        { dungeon = "알게타르 대학", boss = nil, itemID = 193701, slot = "장신구", note = "BIS", sourceType = "mythicplus", sourceLabel = "Algeth'ar Academy" },
        { dungeon = nil, boss = nil, itemID = 260235, slot = "장신구", note = "BIS", sourceType = "raid", sourceLabel = "Belo'ren" },
    },
    [255] = {
        { dungeon = "윈드러너 첨탑", boss = nil, itemID = 251077, slot = "무기", note = "BIS", sourceType = "mythicplus", sourceLabel = "Windrunner Spire" },
        { dungeon = nil, boss = nil, itemID = 249284, slot = "무기", note = "BIS", sourceType = "raid", sourceLabel = "Belo'ren" },
        { dungeon = nil, boss = nil, itemID = 237837, slot = "보조장비", note = "BIS", sourceType = "crafted", sourceLabel = "Crafting" },
        { dungeon = nil, boss = nil, itemID = 249988, slot = "머리", note = "BIS", sourceType = "raid", sourceLabel = "Tier Set" },
        { dungeon = nil, boss = nil, itemID = 250247, slot = "목", note = "BIS", sourceType = "raid", sourceLabel = "March on Quel'Danas" },
        { dungeon = nil, boss = nil, itemID = 151323, slot = "어깨", note = "BIS", sourceType = "crafted", sourceLabel = "Crafting" },
        { dungeon = nil, boss = nil, itemID = 249370, slot = "망토", note = "BIS", sourceType = "raid", sourceLabel = "Vaelgor" },
        { dungeon = nil, boss = nil, itemID = 249991, slot = "가슴", note = "BIS", sourceType = "raid", sourceLabel = "Tier Set" },
        { dungeon = nil, boss = nil, itemID = 249304, slot = "손목", note = "BIS", sourceType = "raid", sourceLabel = "Fallen-King Salhadaar" },
        { dungeon = nil, boss = nil, itemID = 249989, slot = "손", note = "BIS", sourceType = "raid", sourceLabel = "Tier Set" },
        { dungeon = nil, boss = nil, itemID = 249371, slot = "허리", note = "BIS", sourceType = "raid", sourceLabel = "Chimaerus" },
        { dungeon = nil, boss = nil, itemID = 249987, slot = "다리", note = "BIS", sourceType = "raid", sourceLabel = "Tier Set" },
        { dungeon = nil, boss = nil, itemID = 244577, slot = "발", note = "BIS", sourceType = "crafted", sourceLabel = "Crafting" },
        { dungeon = "공결탑 제나스", boss = nil, itemID = 251093, slot = "반지", note = "BIS", sourceType = "mythicplus", sourceLabel = "Nexus-Point Xenas" },
        { dungeon = "공결탑 제나스", boss = nil, itemID = 251217, slot = "반지", note = "BIS", sourceType = "mythicplus", sourceLabel = "Nexus-Point Xenas" },
        { dungeon = nil, boss = nil, itemID = 193701, slot = "장신구", note = "BIS", sourceType = "crafted", sourceLabel = "Crafting" },
        { dungeon = nil, boss = nil, itemID = 249806, slot = "장신구", note = "BIS", sourceType = "raid", sourceLabel = "Belo'ren" },
    },
    [256] = {
        { dungeon = nil, boss = nil, itemID = 250051, slot = "머리", note = "BIS", sourceType = "raid", sourceLabel = "Raid" },
        { dungeon = nil, boss = nil, itemID = 249368, slot = "목", note = "BIS", sourceType = "raid", sourceLabel = "Crown of the Cosmos" },
        { dungeon = nil, boss = nil, itemID = 250049, slot = "어깨", note = "BIS", sourceType = "raid", sourceLabel = "Raid" },
        { dungeon = nil, boss = nil, itemID = 249370, slot = "망토", note = "BIS", sourceType = "raid", sourceLabel = "Vaelgor & Ezzorak" },
        { dungeon = nil, boss = nil, itemID = 249912, slot = "가슴", note = "BIS", sourceType = "raid", sourceLabel = "Midnight Falls" },
        { dungeon = nil, boss = nil, itemID = 249315, slot = "손목", note = "BIS", sourceType = "raid", sourceLabel = "Vorasius" },
        { dungeon = nil, boss = nil, itemID = 250052, slot = "손", note = "BIS", sourceType = "raid", sourceLabel = "Raid" },
        { dungeon = nil, boss = nil, itemID = 239664, slot = "허리", note = "BIS", sourceType = "crafted", sourceLabel = "Crafting" },
        { dungeon = nil, boss = nil, itemID = 250050, slot = "다리", note = "BIS", sourceType = "raid", sourceLabel = "Raid" },
        { dungeon = "하늘탑", boss = nil, itemID = 258584, slot = "발", note = "BIS", sourceType = "mythicplus", sourceLabel = "Skyreach" },
        { dungeon = nil, boss = nil, itemID = 249920, slot = "반지", note = "BIS", sourceType = "raid", sourceLabel = "Midnight Falls" },
        { dungeon = "공결탑 제나스", boss = nil, itemID = 251093, slot = "반지", note = "BIS", sourceType = "mythicplus", sourceLabel = "Nexus-Point Xenas" },
        { dungeon = nil, boss = nil, itemID = 249808, slot = "장신구", note = "BIS", sourceType = "raid", sourceLabel = "War Chaplain Senn" },
        { dungeon = nil, boss = nil, itemID = 249346, slot = "장신구", note = "BIS", sourceType = "raid", sourceLabel = "Vaelgor & Ezzorak" },
        { dungeon = nil, boss = nil, itemID = 249283, slot = "무기", note = "BIS", sourceType = "raid", sourceLabel = "Belo'ren" },
        { dungeon = nil, boss = nil, itemID = 245769, slot = "보조장비", note = "BIS", sourceType = "crafted", sourceLabel = "Crafting" },
    },
    [257] = {
        { dungeon = nil, boss = nil, itemID = 250051, slot = "머리", note = "BIS", sourceType = "raid", sourceLabel = "Raid" },
        { dungeon = nil, boss = nil, itemID = 250247, slot = "목", note = "BIS", sourceType = "raid", sourceLabel = "Midnight Falls" },
        { dungeon = nil, boss = nil, itemID = 250049, slot = "어깨", note = "BIS", sourceType = "raid", sourceLabel = "Raid" },
        { dungeon = nil, boss = nil, itemID = 249335, slot = "망토", note = "BIS", sourceType = "raid", sourceLabel = "Imperator Averzian" },
        { dungeon = nil, boss = nil, itemID = 249912, slot = "가슴", note = "BIS", sourceType = "raid", sourceLabel = "Midnight Falls" },
        { dungeon = nil, boss = nil, itemID = 250047, slot = "손목", note = "BIS", sourceType = "raid", sourceLabel = "Raid" },
        { dungeon = nil, boss = nil, itemID = 250052, slot = "손", note = "BIS", sourceType = "raid", sourceLabel = "Raid" },
        { dungeon = nil, boss = nil, itemID = 239664, slot = "허리", note = "BIS", sourceType = "crafted", sourceLabel = "Crafting" },
        { dungeon = nil, boss = nil, itemID = 250050, slot = "다리", note = "BIS", sourceType = "raid", sourceLabel = "Raid" },
        { dungeon = nil, boss = nil, itemID = 249373, slot = "발", note = "BIS", sourceType = "raid", sourceLabel = "Chimaerus" },
        { dungeon = nil, boss = nil, itemID = 249336, slot = "반지", note = "BIS", sourceType = "raid", sourceLabel = "Vorasius" },
        { dungeon = nil, boss = nil, itemID = 249919, slot = "반지", note = "BIS", sourceType = "raid", sourceLabel = "Belo'ren" },
        { dungeon = nil, boss = nil, itemID = 249809, slot = "장신구", note = "BIS", sourceType = "raid", sourceLabel = "Crown of the Cosmos" },
        { dungeon = nil, boss = nil, itemID = 249808, slot = "장신구", note = "BIS", sourceType = "raid", sourceLabel = "War Chaplain Senn" },
        { dungeon = nil, boss = nil, itemID = 249293, slot = "무기", note = "BIS", sourceType = "raid", sourceLabel = "Imperator Averzian" },
        { dungeon = nil, boss = nil, itemID = 245769, slot = "보조장비", note = "BIS", sourceType = "crafted", sourceLabel = "Crafting" },
    },
    [258] = {
        { dungeon = nil, boss = nil, itemID = 250051, slot = "머리", note = "BIS", sourceType = "raid", sourceLabel = "Raid" },
        { dungeon = nil, boss = nil, itemID = 250247, slot = "목", note = "BIS", sourceType = "raid", sourceLabel = "Midnight Falls" },
        { dungeon = nil, boss = nil, itemID = 250049, slot = "어깨", note = "BIS", sourceType = "raid", sourceLabel = "Raid" },
        { dungeon = nil, boss = nil, itemID = 249370, slot = "망토", note = "BIS", sourceType = "raid", sourceLabel = "Vaelgor & Ezzorak" },
        { dungeon = nil, boss = nil, itemID = 250054, slot = "가슴", note = "BIS", sourceType = "raid", sourceLabel = "Raid" },
        { dungeon = "마법학자의 정원", boss = nil, itemID = 251108, slot = "손목", note = "BIS", sourceType = "mythicplus", sourceLabel = "Magisters' Terrace" },
        { dungeon = nil, boss = nil, itemID = 250052, slot = "손", note = "BIS", sourceType = "raid", sourceLabel = "Raid" },
        { dungeon = nil, boss = nil, itemID = 249376, slot = "허리", note = "BIS", sourceType = "raid", sourceLabel = "Belo'ren" },
        { dungeon = nil, boss = nil, itemID = 250050, slot = "다리", note = "BIS", sourceType = "raid", sourceLabel = "Raid" },
        { dungeon = nil, boss = nil, itemID = 249373, slot = "발", note = "BIS", sourceType = "raid", sourceLabel = "Chimaerus" },
        { dungeon = nil, boss = nil, itemID = 249920, slot = "반지", note = "BIS", sourceType = "raid", sourceLabel = "Midnight Falls" },
        { dungeon = nil, boss = nil, itemID = 249369, slot = "반지", note = "BIS", sourceType = "raid", sourceLabel = "Lightblinded Vanguard" },
        { dungeon = nil, boss = nil, itemID = 249343, slot = "장신구", note = "BIS", sourceType = "raid", sourceLabel = "Chimaerus" },
        { dungeon = nil, boss = nil, itemID = 249346, slot = "장신구", note = "BIS", sourceType = "raid", sourceLabel = "Vaelgor & Ezzorak" },
        { dungeon = nil, boss = nil, itemID = 249283, slot = "무기", note = "BIS", sourceType = "raid", sourceLabel = "Belo'ren" },
        { dungeon = nil, boss = nil, itemID = 249922, slot = "보조장비", note = "BIS", sourceType = "raid", sourceLabel = "Chimaerus" },
    },
    [259] = {
        { dungeon = nil, boss = nil, itemID = 249925, slot = "무기", note = "BIS", sourceType = "raid", sourceLabel = "Vorasius" },
        { dungeon = nil, boss = nil, itemID = 237837, slot = "보조장비", note = "BIS", sourceType = "crafted", sourceLabel = "Crafting" },
        { dungeon = nil, boss = nil, itemID = 250006, slot = "머리", note = "BIS", sourceType = "raid", sourceLabel = "Tier Set" },
        { dungeon = nil, boss = nil, itemID = 249337, slot = "목", note = "BIS", sourceType = "raid", sourceLabel = "Fallen-King Salhadaar" },
        { dungeon = nil, boss = nil, itemID = 250004, slot = "어깨", note = "BIS", sourceType = "raid", sourceLabel = "Tier Set" },
        { dungeon = "마법학자의 정원", boss = nil, itemID = 260312, slot = "망토", note = "BIS", sourceType = "mythicplus", sourceLabel = "Magisters' Terrace" },
        { dungeon = nil, boss = nil, itemID = 250009, slot = "가슴", note = "BIS", sourceType = "raid", sourceLabel = "Tier Set" },
        { dungeon = nil, boss = nil, itemID = 244576, slot = "손목", note = "BIS", sourceType = "crafted", sourceLabel = "Crafting" },
        { dungeon = nil, boss = nil, itemID = 250007, slot = "손", note = "BIS", sourceType = "raid", sourceLabel = "Tier Set" },
        { dungeon = nil, boss = nil, itemID = 249374, slot = "허리", note = "BIS", sourceType = "raid", sourceLabel = "Chimaerus" },
        { dungeon = "윈드러너 첨탑", boss = nil, itemID = 251087, slot = "다리", note = "BIS", sourceType = "mythicplus", sourceLabel = "Windrunner Spire" },
        { dungeon = nil, boss = nil, itemID = 249382, slot = "발", note = "BIS", sourceType = "raid", sourceLabel = "Crown of the Cosmos" },
        { dungeon = nil, boss = nil, itemID = 249919, slot = "반지", note = "BIS", sourceType = "raid", sourceLabel = "Belo'ren" },
        { dungeon = nil, boss = nil, itemID = 249920, slot = "반지", note = "BIS", sourceType = "raid", sourceLabel = "Midnight Falls" },
        { dungeon = nil, boss = nil, itemID = 249343, slot = "장신구", note = "BIS", sourceType = "raid", sourceLabel = "Chimaerus" },
        { dungeon = "알게타르 대학", boss = nil, itemID = 193701, slot = "장신구", note = "BIS", sourceType = "mythicplus", sourceLabel = "Algeth'ar Academy" },
    },
    [260] = {
        { dungeon = nil, boss = nil, itemID = 260423, slot = "무기", note = "BIS", sourceType = "raid", sourceLabel = "Crown of the Cosmos" },
        { dungeon = "사론의 구덩이", boss = nil, itemID = 133491, slot = "보조장비", note = "BIS", sourceType = "mythicplus", sourceLabel = "Pit of Saron" },
        { dungeon = "삼두정의 권좌", boss = nil, itemID = 151336, slot = "머리", note = "BIS", sourceType = "mythicplus", sourceLabel = "Seat of the Triumvirate" },
        { dungeon = "사론의 구덩이", boss = nil, itemID = 50228, slot = "목", note = "BIS", sourceType = "mythicplus", sourceLabel = "Pit of Saron" },
        { dungeon = nil, boss = nil, itemID = 250004, slot = "어깨", note = "BIS", sourceType = "raid", sourceLabel = "Tier Set" },
        { dungeon = nil, boss = nil, itemID = 249335, slot = "망토", note = "BIS", sourceType = "raid", sourceLabel = "Imperator Averzian" },
        { dungeon = nil, boss = nil, itemID = 250009, slot = "가슴", note = "BIS", sourceType = "raid", sourceLabel = "Tier Set" },
        { dungeon = "사론의 구덩이", boss = nil, itemID = 50264, slot = "손목", note = "BIS", sourceType = "mythicplus", sourceLabel = "Pit of Saron" },
        { dungeon = nil, boss = nil, itemID = 250007, slot = "손", note = "BIS", sourceType = "raid", sourceLabel = "Tier Set" },
        { dungeon = nil, boss = nil, itemID = 249374, slot = "허리", note = "BIS", sourceType = "raid", sourceLabel = "Chimaerus" },
        { dungeon = nil, boss = nil, itemID = 250005, slot = "다리", note = "BIS", sourceType = "raid", sourceLabel = "Tier Set" },
        { dungeon = nil, boss = nil, itemID = 244569, slot = "발", note = "BIS", sourceType = "crafted", sourceLabel = "Crafting" },
        { dungeon = nil, boss = nil, itemID = 249336, slot = "반지", note = "BIS", sourceType = "raid", sourceLabel = "Vorasius" },
        { dungeon = nil, boss = nil, itemID = 240949, slot = "반지", note = "BIS", sourceType = "crafted", sourceLabel = "Crafting" },
        { dungeon = nil, boss = nil, itemID = 249343, slot = "장신구", note = "BIS", sourceType = "raid", sourceLabel = "Chimaerus" },
        { dungeon = nil, boss = nil, itemID = 260235, slot = "장신구", note = "BIS", sourceType = "raid", sourceLabel = "Belo'ren" },
    },
    [261] = {
        { dungeon = nil, boss = nil, itemID = 250006, slot = "머리", note = "BIS", sourceType = "raid", sourceLabel = "Tier Set" },
        { dungeon = nil, boss = nil, itemID = 249368, slot = "목", note = "BIS", sourceType = "raid", sourceLabel = "Crown of the Cosmos" },
        { dungeon = nil, boss = nil, itemID = 250004, slot = "어깨", note = "BIS", sourceType = "raid", sourceLabel = "Tier Set" },
        { dungeon = "하늘탑", boss = nil, itemID = 258575, slot = "망토", note = "BIS", sourceType = "mythicplus", sourceLabel = "Skyreach" },
        { dungeon = nil, boss = nil, itemID = 250009, slot = "가슴", note = "BIS", sourceType = "raid", sourceLabel = "Tier Set" },
        { dungeon = nil, boss = nil, itemID = 249327, slot = "손목", note = "BIS", sourceType = "raid", sourceLabel = "Vorasius" },
        { dungeon = nil, boss = nil, itemID = 250007, slot = "손", note = "BIS", sourceType = "raid", sourceLabel = "Tier Set" },
        { dungeon = nil, boss = nil, itemID = 244573, slot = "허리", note = "BIS", sourceType = "crafted", sourceLabel = "Crafting" },
        { dungeon = "사론의 구덩이", boss = nil, itemID = 49817, slot = "다리", note = "BIS", sourceType = "mythicplus", sourceLabel = "Pit of Saron" },
        { dungeon = "하늘탑", boss = nil, itemID = 258577, slot = "발", note = "BIS", sourceType = "mythicplus", sourceLabel = "Skyreach" },
        { dungeon = "알게타르 대학", boss = nil, itemID = 193708, slot = "반지", note = "BIS", sourceType = "mythicplus", sourceLabel = "Algeth'ar Academy" },
        { dungeon = "마법학자의 정원", boss = nil, itemID = 251115, slot = "반지", note = "BIS", sourceType = "mythicplus", sourceLabel = "Magisters' Terrace" },
        { dungeon = nil, boss = nil, itemID = 249344, slot = "장신구", note = "BIS", sourceType = "raid", sourceLabel = "Imperator Averzian" },
        { dungeon = nil, boss = nil, itemID = 249343, slot = "장신구", note = "BIS", sourceType = "raid", sourceLabel = "Chimaerus" },
        { dungeon = nil, boss = nil, itemID = 249925, slot = "무기", note = "BIS", sourceType = "raid", sourceLabel = "Vorasius" },
        { dungeon = nil, boss = nil, itemID = 237837, slot = "보조장비", note = "BIS", sourceType = "crafted", sourceLabel = "Crafting" },
    },
    [262] = {
        { dungeon = "윈드러너 첨탑", boss = nil, itemID = 251083, slot = "무기", note = "BIS", sourceType = "mythicplus", sourceLabel = "Windrunner Spire" },
        { dungeon = "마법학자의 정원", boss = nil, itemID = 251105, slot = "보조장비", note = "BIS", sourceType = "mythicplus", sourceLabel = "Magisters' Terrace" },
        { dungeon = nil, boss = nil, itemID = 249979, slot = "머리", note = "BIS", sourceType = "raid", sourceLabel = "Tier Set" },
        { dungeon = nil, boss = nil, itemID = 250247, slot = "목", note = "BIS", sourceType = "raid", sourceLabel = "Midnight Falls" },
        { dungeon = nil, boss = nil, itemID = 249977, slot = "어깨", note = "BIS", sourceType = "raid", sourceLabel = "Tier Set" },
        { dungeon = nil, boss = nil, itemID = 249974, slot = "망토", note = "BIS", sourceType = "raid", sourceLabel = "Catalyst" },
        { dungeon = nil, boss = nil, itemID = 249982, slot = "가슴", note = "BIS", sourceType = "raid", sourceLabel = "Tier Set" },
        { dungeon = nil, boss = nil, itemID = 249304, slot = "손목", note = "BIS", sourceType = "raid", sourceLabel = "Fallen-King Salhadaar" },
        { dungeon = nil, boss = nil, itemID = 249980, slot = "손", note = "BIS", sourceType = "raid", sourceLabel = "Tier Set" },
        { dungeon = nil, boss = nil, itemID = 244611, slot = "허리", note = "BIS", sourceType = "crafted", sourceLabel = "Crafting" },
        { dungeon = "공결탑 제나스", boss = nil, itemID = 251215, slot = "다리", note = "BIS", sourceType = "mythicplus", sourceLabel = "Nexus-Point Xenas" },
        { dungeon = nil, boss = nil, itemID = 244610, slot = "발", note = "BIS", sourceType = "crafted", sourceLabel = "Crafting" },
        { dungeon = "알게타르 대학", boss = nil, itemID = 193708, slot = "반지", note = "BIS", sourceType = "mythicplus", sourceLabel = "Algeth'ar Academy" },
        { dungeon = nil, boss = nil, itemID = 249919, slot = "반지", note = "BIS", sourceType = "raid", sourceLabel = "Belo'ren" },
        { dungeon = nil, boss = nil, itemID = 249343, slot = "장신구", note = "BIS", sourceType = "raid", sourceLabel = "Chimaerus" },
        { dungeon = "윈드러너 첨탑", boss = nil, itemID = 250144, slot = "장신구", note = "BIS", sourceType = "mythicplus", sourceLabel = "Windrunner Spire" },
    },
    [263] = {
        { dungeon = nil, boss = nil, itemID = 249287, slot = "무기", note = "BIS", sourceType = "raid", sourceLabel = "Vaelgor & Ezzorak" },
        { dungeon = nil, boss = nil, itemID = 237850, slot = "보조장비", note = "BIS", sourceType = "crafted", sourceLabel = "Blacksmithing" },
        { dungeon = nil, boss = nil, itemID = 249979, slot = "머리", note = "BIS", sourceType = "raid", sourceLabel = "Catalyst" },
        { dungeon = nil, boss = nil, itemID = 250247, slot = "목", note = "BIS", sourceType = "raid", sourceLabel = "Midnight Falls" },
        { dungeon = nil, boss = nil, itemID = 249977, slot = "어깨", note = "BIS", sourceType = "raid", sourceLabel = "Catalyst" },
        { dungeon = nil, boss = nil, itemID = 239656, slot = "망토", note = "BIS", sourceType = "crafted", sourceLabel = "Tailoring" },
        { dungeon = nil, boss = nil, itemID = 249982, slot = "가슴", note = "BIS", sourceType = "raid", sourceLabel = "Catalyst" },
        { dungeon = nil, boss = nil, itemID = 249304, slot = "손목", note = "BIS", sourceType = "raid", sourceLabel = "Fallen-King Salhadaar" },
        { dungeon = nil, boss = nil, itemID = 249980, slot = "손", note = "BIS", sourceType = "raid", sourceLabel = "Catalyst" },
        { dungeon = nil, boss = nil, itemID = 249976, slot = "허리", note = "BIS", sourceType = "raid", sourceLabel = "Catalyst" },
        { dungeon = nil, boss = nil, itemID = 249324, slot = "다리", note = "BIS", sourceType = "raid", sourceLabel = "Belo'ren" },
        { dungeon = "윈드러너 첨탑", boss = nil, itemID = 251084, slot = "발", note = "BIS", sourceType = "mythicplus", sourceLabel = "Windrunner Spire" },
        { dungeon = nil, boss = nil, itemID = 249920, slot = "반지", note = "BIS", sourceType = "raid", sourceLabel = "Midnight Falls" },
        { dungeon = "공결탑 제나스", boss = nil, itemID = 251093, slot = "반지", note = "BIS", sourceType = "mythicplus", sourceLabel = "Nexus-Point Xenas" },
        { dungeon = nil, boss = nil, itemID = 249343, slot = "장신구", note = "BIS", sourceType = "raid", sourceLabel = "Raid" },
        { dungeon = "알게타르 대학", boss = nil, itemID = 193701, slot = "장신구", note = "BIS", sourceType = "mythicplus", sourceLabel = "Algeth'ar Academy" },
    },
    [264] = {
        { dungeon = nil, boss = nil, itemID = 249914, slot = "머리", note = "BIS", sourceType = "raid", sourceLabel = "Midnight Falls" },
        { dungeon = nil, boss = nil, itemID = 249337, slot = "목", note = "BIS", sourceType = "raid", sourceLabel = "Fallen-King Salhadaar" },
        { dungeon = nil, boss = nil, itemID = 249977, slot = "어깨", note = "BIS", sourceType = "raid", sourceLabel = "Raid" },
        { dungeon = nil, boss = nil, itemID = 249974, slot = "망토", note = "BIS", sourceType = "raid", sourceLabel = "Catalyst" },
        { dungeon = nil, boss = nil, itemID = 249982, slot = "가슴", note = "BIS", sourceType = "raid", sourceLabel = "Raid" },
        { dungeon = nil, boss = nil, itemID = 249975, slot = "손목", note = "BIS", sourceType = "raid", sourceLabel = "Catalyst" },
        { dungeon = nil, boss = nil, itemID = 249980, slot = "손", note = "BIS", sourceType = "raid", sourceLabel = "Raid" },
        { dungeon = nil, boss = nil, itemID = 249303, slot = "허리", note = "BIS", sourceType = "raid", sourceLabel = "Lightblinded Vanguard" },
        { dungeon = nil, boss = nil, itemID = 249978, slot = "다리", note = "BIS", sourceType = "raid", sourceLabel = "Raid" },
        { dungeon = nil, boss = nil, itemID = 249320, slot = "발", note = "BIS", sourceType = "raid", sourceLabel = "Imperator Averzian" },
        { dungeon = nil, boss = nil, itemID = 249919, slot = "반지", note = "BIS", sourceType = "raid", sourceLabel = "Belo'ren" },
        { dungeon = "알게타르 대학", boss = nil, itemID = 193708, slot = "반지", note = "BIS", sourceType = "mythicplus", sourceLabel = "Algeth'ar Academy" },
        { dungeon = nil, boss = nil, itemID = 249343, slot = "장신구", note = "BIS", sourceType = "raid", sourceLabel = "Chimaerus" },
        { dungeon = nil, boss = nil, itemID = 264507, slot = "장신구", note = "BIS", sourceType = "crafted", sourceLabel = "Crafting" },
        { dungeon = nil, boss = nil, itemID = 249293, slot = "무기", note = "BIS", sourceType = "raid", sourceLabel = "Imperator Averzian" },
        { dungeon = "공결탑 제나스", boss = nil, itemID = 251202, slot = "방패", note = "BIS", sourceType = "mythicplus", sourceLabel = "Nexus-Point Xenas" },
    },
    [265] = {
        { dungeon = nil, boss = nil, itemID = 249283, slot = "무기", note = "BIS", sourceType = "raid", sourceLabel = "Belo'ren" },
        { dungeon = nil, boss = nil, itemID = 249276, slot = "보조장비", note = "BIS", sourceType = "raid", sourceLabel = "Vorasius" },
        { dungeon = nil, boss = nil, itemID = 250042, slot = "머리", note = "BIS", sourceType = "raid", sourceLabel = "Tier Set" },
        { dungeon = nil, boss = nil, itemID = 249368, slot = "목", note = "BIS", sourceType = "raid", sourceLabel = "Crown of the Cosmos" },
        { dungeon = "윈드러너 첨탑", boss = nil, itemID = 251085, slot = "어깨", note = "BIS", sourceType = "mythicplus", sourceLabel = "Windrunner Spire" },
        { dungeon = nil, boss = nil, itemID = 239656, slot = "망토", note = "BIS", sourceType = "crafted", sourceLabel = "Crafting" },
        { dungeon = nil, boss = nil, itemID = 250045, slot = "가슴", note = "BIS", sourceType = "raid", sourceLabel = "Tier Set" },
        { dungeon = nil, boss = nil, itemID = 239648, slot = "손목", note = "BIS", sourceType = "crafted", sourceLabel = "Crafting" },
        { dungeon = nil, boss = nil, itemID = 250043, slot = "손", note = "BIS", sourceType = "raid", sourceLabel = "Tier Set" },
        { dungeon = nil, boss = nil, itemID = 249376, slot = "허리", note = "BIS", sourceType = "raid", sourceLabel = "Belo'ren" },
        { dungeon = nil, boss = nil, itemID = 250041, slot = "다리", note = "BIS", sourceType = "raid", sourceLabel = "Tier Set" },
        { dungeon = nil, boss = nil, itemID = 249305, slot = "발", note = "BIS", sourceType = "raid", sourceLabel = "Vaelgor" },
        { dungeon = nil, boss = nil, itemID = 249920, slot = "반지", note = "BIS", sourceType = "raid", sourceLabel = "Midnight Falls" },
        { dungeon = "공결탑 제나스", boss = nil, itemID = 251217, slot = "반지", note = "BIS", sourceType = "mythicplus", sourceLabel = "Nexus-Point Xenas" },
        { dungeon = nil, boss = nil, itemID = 249343, slot = "장신구", note = "BIS", sourceType = "raid", sourceLabel = "Chimaerus" },
        { dungeon = "윈드러너 첨탑", boss = nil, itemID = 250144, slot = "장신구", note = "BIS", sourceType = "mythicplus", sourceLabel = "Windrunner Spire" },
    },
    [266] = {
        { dungeon = nil, boss = nil, itemID = 249283, slot = "무기", note = "BIS", sourceType = "raid", sourceLabel = "Belo'ren" },
        { dungeon = nil, boss = nil, itemID = 249276, slot = "보조장비", note = "BIS", sourceType = "raid", sourceLabel = "Vorasius" },
        { dungeon = nil, boss = nil, itemID = 250042, slot = "머리", note = "BIS", sourceType = "raid", sourceLabel = "Tier Set" },
        { dungeon = nil, boss = nil, itemID = 249368, slot = "목", note = "BIS", sourceType = "raid", sourceLabel = "Crown of the Cosmos" },
        { dungeon = "윈드러너 첨탑", boss = nil, itemID = 251085, slot = "어깨", note = "BIS", sourceType = "mythicplus", sourceLabel = "Windrunner Spire" },
        { dungeon = nil, boss = nil, itemID = 239656, slot = "망토", note = "BIS", sourceType = "crafted", sourceLabel = "Crafting" },
        { dungeon = nil, boss = nil, itemID = 250045, slot = "가슴", note = "BIS", sourceType = "raid", sourceLabel = "Tier Set" },
        { dungeon = nil, boss = nil, itemID = 239648, slot = "손목", note = "BIS", sourceType = "crafted", sourceLabel = "Crafting" },
        { dungeon = nil, boss = nil, itemID = 250043, slot = "손", note = "BIS", sourceType = "raid", sourceLabel = "Tier Set" },
        { dungeon = nil, boss = nil, itemID = 249376, slot = "허리", note = "BIS", sourceType = "raid", sourceLabel = "Belo'ren" },
        { dungeon = nil, boss = nil, itemID = 250041, slot = "다리", note = "BIS", sourceType = "raid", sourceLabel = "Tier Set" },
        { dungeon = nil, boss = nil, itemID = 249305, slot = "발", note = "BIS", sourceType = "raid", sourceLabel = "Vaelgor" },
        { dungeon = nil, boss = nil, itemID = 249920, slot = "반지", note = "BIS", sourceType = "raid", sourceLabel = "Midnight Falls" },
        { dungeon = "공결탑 제나스", boss = nil, itemID = 251217, slot = "반지", note = "BIS", sourceType = "mythicplus", sourceLabel = "Nexus-Point Xenas" },
        { dungeon = "윈드러너 첨탑", boss = nil, itemID = 250144, slot = "장신구", note = "BIS", sourceType = "mythicplus", sourceLabel = "Windrunner Spire" },
        { dungeon = nil, boss = nil, itemID = 249809, slot = "장신구", note = "BIS", sourceType = "raid", sourceLabel = "Crown of the Cosmos" },
        { dungeon = nil, boss = nil, itemID = 249346, slot = "장신구", note = "BIS", sourceType = "raid", sourceLabel = "Vaelgor" },
    },
    [267] = {
        { dungeon = nil, boss = nil, itemID = 249283, slot = "무기", note = "BIS", sourceType = "raid", sourceLabel = "Belo'ren" },
        { dungeon = nil, boss = nil, itemID = 249276, slot = "보조장비", note = "BIS", sourceType = "raid", sourceLabel = "Vorasius" },
        { dungeon = nil, boss = nil, itemID = 250042, slot = "머리", note = "BIS", sourceType = "raid", sourceLabel = "Tier Set" },
        { dungeon = nil, boss = nil, itemID = 249368, slot = "목", note = "BIS", sourceType = "raid", sourceLabel = "Crown of the Cosmos" },
        { dungeon = "윈드러너 첨탑", boss = nil, itemID = 251085, slot = "어깨", note = "BIS", sourceType = "mythicplus", sourceLabel = "Windrunner Spire" },
        { dungeon = nil, boss = nil, itemID = 239656, slot = "망토", note = "BIS", sourceType = "crafted", sourceLabel = "Crafting" },
        { dungeon = nil, boss = nil, itemID = 250045, slot = "가슴", note = "BIS", sourceType = "raid", sourceLabel = "Tier Set" },
        { dungeon = nil, boss = nil, itemID = 239648, slot = "손목", note = "BIS", sourceType = "crafted", sourceLabel = "Crafting" },
        { dungeon = nil, boss = nil, itemID = 250043, slot = "손", note = "BIS", sourceType = "raid", sourceLabel = "Tier Set" },
        { dungeon = nil, boss = nil, itemID = 249376, slot = "허리", note = "BIS", sourceType = "raid", sourceLabel = "Belo'ren" },
        { dungeon = nil, boss = nil, itemID = 250041, slot = "다리", note = "BIS", sourceType = "raid", sourceLabel = "Tier Set" },
        { dungeon = nil, boss = nil, itemID = 249305, slot = "발", note = "BIS", sourceType = "raid", sourceLabel = "Vaelgor" },
        { dungeon = nil, boss = nil, itemID = 249920, slot = "반지", note = "BIS", sourceType = "raid", sourceLabel = "Midnight Falls" },
        { dungeon = "공결탑 제나스", boss = nil, itemID = 251217, slot = "반지", note = "BIS", sourceType = "mythicplus", sourceLabel = "Nexus-Point Xenas" },
        { dungeon = nil, boss = nil, itemID = 249343, slot = "장신구", note = "BIS", sourceType = "raid", sourceLabel = "Chimaerus" },
        { dungeon = nil, boss = nil, itemID = 249346, slot = "장신구", note = "BIS", sourceType = "raid", sourceLabel = "Vaelgor" },
    },
    [268] = {
        { dungeon = nil, boss = nil, itemID = 249302, slot = "무기", note = "BIS", sourceType = "raid", sourceLabel = "Vorasius" },
        { dungeon = "공결탑 제나스", boss = nil, itemID = 251207, slot = "무기", note = "BIS", sourceType = "mythicplus", sourceLabel = "Nexus-Point Xenas" },
        { dungeon = "마이사라 동굴", boss = nil, itemID = 251175, slot = "무기", note = "BIS", sourceType = "mythicplus", sourceLabel = "Maisara Caverns" },
        { dungeon = nil, boss = nil, itemID = 250015, slot = "머리", note = "BIS", sourceType = "raid", sourceLabel = "Catalyst" },
        { dungeon = nil, boss = nil, itemID = 240950, slot = "목", note = "BIS", sourceType = "crafted", sourceLabel = "Jewelcrafting" },
        { dungeon = nil, boss = nil, itemID = 250013, slot = "어깨", note = "BIS", sourceType = "raid", sourceLabel = "Catalyst" },
        { dungeon = nil, boss = nil, itemID = 249335, slot = "망토", note = "BIS", sourceType = "raid", sourceLabel = "Imperator Averzian" },
        { dungeon = nil, boss = nil, itemID = 250018, slot = "가슴", note = "BIS", sourceType = "raid", sourceLabel = "Catalyst" },
        { dungeon = nil, boss = nil, itemID = 250011, slot = "손목", note = "BIS", sourceType = "raid", sourceLabel = "Catalyst" },
        { dungeon = nil, boss = nil, itemID = 250016, slot = "손", note = "BIS", sourceType = "raid", sourceLabel = "Catalyst" },
        { dungeon = "윈드러너 첨탑", boss = nil, itemID = 251082, slot = "허리", note = "BIS", sourceType = "mythicplus", sourceLabel = "Windrunner Spire" },
        { dungeon = "삼두정의 권좌", boss = nil, itemID = 151314, slot = "다리", note = "BIS", sourceType = "mythicplus", sourceLabel = "Seat of the Triumvirate" },
        { dungeon = "삼두정의 권좌", boss = nil, itemID = 151317, slot = "발", note = "BIS", sourceType = "mythicplus", sourceLabel = "Seat of the Triumvirate" },
        { dungeon = nil, boss = nil, itemID = 249336, slot = "반지", note = "BIS", sourceType = "raid", sourceLabel = "Vorasius" },
        { dungeon = nil, boss = nil, itemID = 251513, slot = "반지", note = "BIS", sourceType = "crafted", sourceLabel = "Jewelcrafting" },
        { dungeon = nil, boss = nil, itemID = 249806, slot = "장신구", note = "BIS", sourceType = "raid", sourceLabel = "Belo'ren" },
        { dungeon = nil, boss = nil, itemID = 249343, slot = "장신구", note = "BIS", sourceType = "raid", sourceLabel = "Chimaerus" },
        { dungeon = nil, boss = nil, itemID = 249339, slot = "장신구", note = "BIS", sourceType = "raid", sourceLabel = "Vaelgor & Ezzorak" },
        { dungeon = "삼두정의 권좌", boss = nil, itemID = 151312, slot = "장신구", note = "BIS", sourceType = "mythicplus", sourceLabel = "Seat of the Triumvirate" },
    },
    [269] = {
        { dungeon = nil, boss = nil, itemID = 250015, slot = "머리", note = "BIS", sourceType = "raid", sourceLabel = "Tier Set" },
        { dungeon = nil, boss = nil, itemID = 250247, slot = "목", note = "BIS", sourceType = "raid", sourceLabel = "Midnight Falls" },
        { dungeon = nil, boss = nil, itemID = 250013, slot = "어깨", note = "BIS", sourceType = "raid", sourceLabel = "Tier Set" },
        { dungeon = nil, boss = nil, itemID = 250010, slot = "망토", note = "BIS", sourceType = "raid", sourceLabel = "Catalyst" },
        { dungeon = nil, boss = nil, itemID = 250018, slot = "가슴", note = "BIS", sourceType = "raid", sourceLabel = "Tier Set" },
        { dungeon = nil, boss = nil, itemID = 249327, slot = "손목", note = "BIS", sourceType = "raid", sourceLabel = "Vorasius" },
        { dungeon = nil, boss = nil, itemID = 249321, slot = "손", note = "BIS", sourceType = "raid", sourceLabel = "Vaelgor & Ezzorak" },
        { dungeon = "윈드러너 첨탑", boss = nil, itemID = 251082, slot = "허리", note = "BIS", sourceType = "mythicplus", sourceLabel = "Windrunner Spire" },
        { dungeon = nil, boss = nil, itemID = 250014, slot = "다리", note = "BIS", sourceType = "raid", sourceLabel = "Tier Set" },
        { dungeon = nil, boss = nil, itemID = 250017, slot = "발", note = "BIS", sourceType = "raid", sourceLabel = "Catalyst" },
        { dungeon = nil, boss = nil, itemID = 251513, slot = "반지", note = "BIS", sourceType = "crafted", sourceLabel = "Crafting" },
        { dungeon = nil, boss = nil, itemID = 249920, slot = "반지", note = "BIS", sourceType = "raid", sourceLabel = "Midnight Falls" },
        { dungeon = "마이사라 동굴", boss = nil, itemID = 251162, slot = "무기", note = "BIS", sourceType = "mythicplus", sourceLabel = "Maisara Caverns" },
        { dungeon = nil, boss = nil, itemID = 260423, slot = "무기", note = "BIS", sourceType = "raid", sourceLabel = "Crown of the Cosmos" },
        { dungeon = nil, boss = nil, itemID = 237845, slot = "무기", note = "BIS", sourceType = "crafted", sourceLabel = "Crafting" },
        { dungeon = nil, boss = nil, itemID = 249343, slot = "장신구", note = "BIS", sourceType = "raid", sourceLabel = "Chimaerus" },
        { dungeon = "알게타르 대학", boss = nil, itemID = 193701, slot = "장신구", note = "BIS", sourceType = "mythicplus", sourceLabel = "Algeth'ar Academy" },
    },
    [270] = {
        { dungeon = "하늘탑", boss = nil, itemID = 258050, slot = "무기", note = "BIS", sourceType = "mythicplus", sourceLabel = "Skyreach" },
        { dungeon = nil, boss = nil, itemID = 249276, slot = "보조장비", note = "BIS", sourceType = "raid", sourceLabel = "Vorasius" },
        { dungeon = nil, boss = nil, itemID = 249913, slot = "머리", note = "BIS", sourceType = "raid", sourceLabel = "Midnight Falls" },
        { dungeon = "사론의 구덩이", boss = nil, itemID = 50228, slot = "목", note = "BIS", sourceType = "mythicplus", sourceLabel = "Pit of Saron" },
        { dungeon = nil, boss = nil, itemID = 250013, slot = "어깨", note = "BIS", sourceType = "raid", sourceLabel = "Raid" },
        { dungeon = "마법학자의 정원", boss = nil, itemID = 260312, slot = "망토", note = "BIS", sourceType = "mythicplus", sourceLabel = "Magisters' Terrace" },
        { dungeon = nil, boss = nil, itemID = 250018, slot = "가슴", note = "BIS", sourceType = "raid", sourceLabel = "Raid" },
        { dungeon = nil, boss = nil, itemID = 249327, slot = "손목", note = "BIS", sourceType = "raid", sourceLabel = "Vorasius" },
        { dungeon = nil, boss = nil, itemID = 250016, slot = "손", note = "BIS", sourceType = "raid", sourceLabel = "Raid" },
        { dungeon = nil, boss = nil, itemID = 249374, slot = "허리", note = "BIS", sourceType = "raid", sourceLabel = "Chimaerus" },
        { dungeon = nil, boss = nil, itemID = 250014, slot = "다리", note = "BIS", sourceType = "raid", sourceLabel = "Raid" },
        { dungeon = nil, boss = nil, itemID = 250017, slot = "발", note = "BIS", sourceType = "raid", sourceLabel = "Catalyst" },
        { dungeon = nil, boss = nil, itemID = 249920, slot = "반지", note = "BIS", sourceType = "raid", sourceLabel = "Midnight Falls" },
        { dungeon = "사론의 구덩이", boss = nil, itemID = 49812, slot = "반지", note = "BIS", sourceType = "mythicplus", sourceLabel = "Pit of Saron" },
        { dungeon = nil, boss = nil, itemID = 249808, slot = "장신구", note = "BIS", sourceType = "raid", sourceLabel = "Lightblinded Vanguard" },
        { dungeon = nil, boss = nil, itemID = 249343, slot = "장신구", note = "BIS", sourceType = "raid", sourceLabel = "Chimaerus" },
    },
    [577] = {
        { dungeon = nil, boss = nil, itemID = 260408, slot = "무기", note = "BIS", sourceType = "raid", sourceLabel = "Midnight Falls" },
        { dungeon = nil, boss = nil, itemID = 249280, slot = "보조장비", note = "BIS", sourceType = "raid", sourceLabel = "Vaelgor & Ezzorak" },
        { dungeon = "마법학자의 정원", boss = nil, itemID = 251109, slot = "머리", note = "BIS", sourceType = "mythicplus", sourceLabel = "Magisters' Terrace" },
        { dungeon = nil, boss = nil, itemID = 250247, slot = "목", note = "BIS", sourceType = "raid", sourceLabel = "Midnight Falls" },
        { dungeon = nil, boss = nil, itemID = 250031, slot = "어깨", note = "BIS", sourceType = "raid", sourceLabel = "Tier Set" },
        { dungeon = nil, boss = nil, itemID = 239656, slot = "망토", note = "BIS", sourceType = "crafted", sourceLabel = "Crafting" },
        { dungeon = nil, boss = nil, itemID = 250036, slot = "가슴", note = "BIS", sourceType = "raid", sourceLabel = "Tier Set" },
        { dungeon = nil, boss = nil, itemID = 244576, slot = "손목", note = "BIS", sourceType = "crafted", sourceLabel = "Crafting" },
        { dungeon = nil, boss = nil, itemID = 250034, slot = "손", note = "BIS", sourceType = "raid", sourceLabel = "Tier Set" },
        { dungeon = "윈드러너 첨탑", boss = nil, itemID = 251082, slot = "허리", note = "BIS", sourceType = "mythicplus", sourceLabel = "Windrunner Spire" },
        { dungeon = nil, boss = nil, itemID = 250032, slot = "다리", note = "BIS", sourceType = "raid", sourceLabel = "Tier Set" },
        { dungeon = "하늘탑", boss = nil, itemID = 258577, slot = "발", note = "BIS", sourceType = "mythicplus", sourceLabel = "Skyreach" },
        { dungeon = nil, boss = nil, itemID = 249919, slot = "반지", note = "BIS", sourceType = "raid", sourceLabel = "Belo'ren" },
        { dungeon = "알게타르 대학", boss = nil, itemID = 193708, slot = "반지", note = "BIS", sourceType = "mythicplus", sourceLabel = "Algeth'ar Academy" },
        { dungeon = "알게타르 대학", boss = nil, itemID = 193701, slot = "장신구", note = "BIS", sourceType = "mythicplus", sourceLabel = "Algeth'ar Academy" },
        { dungeon = nil, boss = nil, itemID = 249343, slot = "장신구", note = "BIS", sourceType = "raid", sourceLabel = "Chimaerus" },
    },
    [581] = {
        { dungeon = nil, boss = nil, itemID = 260408, slot = "무기", note = "BIS", sourceType = "raid", sourceLabel = "Midnight Falls" },
        { dungeon = nil, boss = nil, itemID = 249298, slot = "보조장비", note = "BIS", sourceType = "raid", sourceLabel = "Fallen-King Salhadaar" },
        { dungeon = nil, boss = nil, itemID = 237840, slot = "보조장비", note = "BIS", sourceType = "crafted", sourceLabel = "Crafting" },
        { dungeon = nil, boss = nil, itemID = 250033, slot = "머리", note = "BIS", sourceType = "raid", sourceLabel = "Lightblinded Vanguard" },
        { dungeon = "삼두정의 권좌", boss = nil, itemID = 151309, slot = "목", note = "BIS", sourceType = "mythicplus", sourceLabel = "Seat of the Triumvirate" },
        { dungeon = nil, boss = nil, itemID = 250031, slot = "어깨", note = "BIS", sourceType = "raid", sourceLabel = "Fallen-King Salhadaar" },
        { dungeon = nil, boss = nil, itemID = 239656, slot = "망토", note = "BIS", sourceType = "crafted", sourceLabel = "Crafting" },
        { dungeon = "삼두정의 권좌", boss = nil, itemID = 151313, slot = "가슴", note = "BIS", sourceType = "mythicplus", sourceLabel = "Seat of the Triumvirate" },
        { dungeon = "사론의 구덩이", boss = nil, itemID = 50264, slot = "손목", note = "BIS", sourceType = "mythicplus", sourceLabel = "Pit of Saron" },
        { dungeon = nil, boss = nil, itemID = 250034, slot = "손", note = "BIS", sourceType = "raid", sourceLabel = "Vorasius" },
        { dungeon = "사론의 구덩이", boss = nil, itemID = 49806, slot = "허리", note = "BIS", sourceType = "mythicplus", sourceLabel = "Pit of Saron" },
        { dungeon = nil, boss = nil, itemID = 250032, slot = "다리", note = "BIS", sourceType = "raid", sourceLabel = "Vaelgor & Ezzorak" },
        { dungeon = "공결탑 제나스", boss = nil, itemID = 251210, slot = "발", note = "BIS", sourceType = "mythicplus", sourceLabel = "Nexus-Point Xenas" },
        { dungeon = "공결탑 제나스", boss = nil, itemID = 251093, slot = "반지", note = "BIS", sourceType = "mythicplus", sourceLabel = "Nexus-Point Xenas" },
        { dungeon = nil, boss = nil, itemID = 249920, slot = "반지", note = "BIS", sourceType = "raid", sourceLabel = "Midnight Falls" },
        { dungeon = nil, boss = nil, itemID = 251513, slot = "반지", note = "BIS", sourceType = "crafted", sourceLabel = "Crafting" },
        { dungeon = nil, boss = nil, itemID = 249343, slot = "장신구", note = "BIS", sourceType = "raid", sourceLabel = "Chimaerus" },
        { dungeon = nil, boss = nil, itemID = 249344, slot = "장신구", note = "BIS", sourceType = "raid", sourceLabel = "Imperator Averzian" },
    },
    [1467] = {
        { dungeon = nil, boss = nil, itemID = 249283, slot = "무기", note = "BIS", sourceType = "raid", sourceLabel = "Belo'ren" },
        { dungeon = nil, boss = nil, itemID = 249276, slot = "보조장비", note = "BIS", sourceType = "raid", sourceLabel = "Vorasius" },
        { dungeon = nil, boss = nil, itemID = 249997, slot = "머리", note = "BIS", sourceType = "raid", sourceLabel = "Tier Set" },
        { dungeon = nil, boss = nil, itemID = 250247, slot = "목", note = "BIS", sourceType = "raid", sourceLabel = "Midnight Falls" },
        { dungeon = nil, boss = nil, itemID = 249995, slot = "어깨", note = "BIS", sourceType = "raid", sourceLabel = "Tier Set" },
        { dungeon = nil, boss = nil, itemID = 239656, slot = "망토", note = "BIS", sourceType = "crafted", sourceLabel = "Crafting" },
        { dungeon = nil, boss = nil, itemID = 250000, slot = "가슴", note = "BIS", sourceType = "raid", sourceLabel = "Tier Set" },
        { dungeon = nil, boss = nil, itemID = 244584, slot = "손목", note = "BIS", sourceType = "crafted", sourceLabel = "Crafting" },
        { dungeon = nil, boss = nil, itemID = 249325, slot = "손", note = "BIS", sourceType = "raid", sourceLabel = "Crown of the Cosmos" },
        { dungeon = "사론의 구덩이", boss = nil, itemID = 49810, slot = "허리", note = "BIS", sourceType = "mythicplus", sourceLabel = "Pit of Saron" },
        { dungeon = nil, boss = nil, itemID = 249996, slot = "다리", note = "BIS", sourceType = "raid", sourceLabel = "Tier Set" },
        { dungeon = nil, boss = nil, itemID = 249377, slot = "발", note = "BIS", sourceType = "raid", sourceLabel = "Belo'ren" },
        { dungeon = nil, boss = nil, itemID = 249919, slot = "반지", note = "BIS", sourceType = "raid", sourceLabel = "Belo'ren" },
        { dungeon = nil, boss = nil, itemID = 249920, slot = "반지", note = "BIS", sourceType = "raid", sourceLabel = "Midnight Falls" },
        { dungeon = nil, boss = nil, itemID = 249346, slot = "장신구", note = "BIS", sourceType = "raid", sourceLabel = "Vaelgor & Ezzorak" },
        { dungeon = nil, boss = nil, itemID = 249809, slot = "장신구", note = "BIS", sourceType = "raid", sourceLabel = "Crown of the Cosmos" },
    },
    [1468] = {
        { dungeon = nil, boss = nil, itemID = 249914, slot = "머리", note = "BIS", sourceType = "raid", sourceLabel = "Midnight Falls" },
        { dungeon = nil, boss = nil, itemID = 250247, slot = "목", note = "BIS", sourceType = "raid", sourceLabel = "Midnight Falls" },
        { dungeon = nil, boss = nil, itemID = 249995, slot = "어깨", note = "BIS", sourceType = "raid", sourceLabel = "Raid" },
        { dungeon = "공결탑 제나스", boss = nil, itemID = 251206, slot = "망토", note = "BIS", sourceType = "mythicplus", sourceLabel = "Nexus-Point Xenas" },
        { dungeon = nil, boss = nil, itemID = 250000, slot = "가슴", note = "BIS", sourceType = "raid", sourceLabel = "Raid" },
        { dungeon = "윈드러너 첨탑", boss = nil, itemID = 251079, slot = "손목", note = "BIS", sourceType = "mythicplus", sourceLabel = "Windrunner Spire" },
        { dungeon = nil, boss = nil, itemID = 249998, slot = "손", note = "BIS", sourceType = "raid", sourceLabel = "Raid" },
        { dungeon = "알게타르 대학", boss = nil, itemID = 193722, slot = "허리", note = "BIS", sourceType = "mythicplus", sourceLabel = "Algeth'ar Academy" },
        { dungeon = nil, boss = nil, itemID = 249996, slot = "다리", note = "BIS", sourceType = "raid", sourceLabel = "Raid" },
        { dungeon = "윈드러너 첨탑", boss = nil, itemID = 251084, slot = "발", note = "BIS", sourceType = "mythicplus", sourceLabel = "Windrunner Spire" },
        { dungeon = nil, boss = nil, itemID = 249369, slot = "반지", note = "BIS", sourceType = "raid", sourceLabel = "Lightblinded Vanguard" },
        { dungeon = nil, boss = nil, itemID = 249920, slot = "반지", note = "BIS", sourceType = "raid", sourceLabel = "Midnight Falls" },
        { dungeon = nil, boss = nil, itemID = 249346, slot = "장신구", note = "BIS", sourceType = "raid", sourceLabel = "Vaelgor & Ezzorak" },
        { dungeon = nil, boss = nil, itemID = 249809, slot = "장신구", note = "BIS", sourceType = "raid", sourceLabel = "Crown of the Cosmos" },
        { dungeon = "삼두정의 권좌", boss = nil, itemID = 258514, slot = "무기", note = "BIS", sourceType = "mythicplus", sourceLabel = "Seat of the Triumvirate" },
    },
    [1473] = {
        { dungeon = "마이사라 동굴", boss = nil, itemID = 251178, slot = "무기", note = "BIS", sourceType = "mythicplus", sourceLabel = "Maisara Caverns" },
        { dungeon = nil, boss = nil, itemID = 249276, slot = "보조장비", note = "BIS", sourceType = "raid", sourceLabel = "Vorasius" },
        { dungeon = "사론의 구덩이", boss = nil, itemID = 133506, slot = "머리", note = "BIS", sourceType = "mythicplus", sourceLabel = "Pit of Saron" },
        { dungeon = nil, boss = nil, itemID = 249337, slot = "목", note = "BIS", sourceType = "raid", sourceLabel = "Fallen-King Salhadaar" },
        { dungeon = nil, boss = nil, itemID = 249995, slot = "어깨", note = "BIS", sourceType = "raid", sourceLabel = "Tier Set" },
        { dungeon = nil, boss = nil, itemID = 239656, slot = "망토", note = "BIS", sourceType = "crafted", sourceLabel = "Crafting" },
        { dungeon = nil, boss = nil, itemID = 250000, slot = "가슴", note = "BIS", sourceType = "raid", sourceLabel = "Tier Set" },
        { dungeon = nil, boss = nil, itemID = 244584, slot = "손목", note = "BIS", sourceType = "crafted", sourceLabel = "Crafting" },
        { dungeon = nil, boss = nil, itemID = 249998, slot = "손", note = "BIS", sourceType = "raid", sourceLabel = "Tier Set" },
        { dungeon = "사론의 구덩이", boss = nil, itemID = 49810, slot = "허리", note = "BIS", sourceType = "mythicplus", sourceLabel = "Pit of Saron" },
        { dungeon = nil, boss = nil, itemID = 249996, slot = "다리", note = "BIS", sourceType = "raid", sourceLabel = "Tier Set" },
        { dungeon = nil, boss = nil, itemID = 249999, slot = "발", note = "BIS", sourceType = "raid", sourceLabel = "Catalyst" },
        { dungeon = nil, boss = nil, itemID = 249920, slot = "반지", note = "BIS", sourceType = "raid", sourceLabel = "Midnight Falls" },
        { dungeon = "사론의 구덩이", boss = nil, itemID = 49812, slot = "반지", note = "BIS", sourceType = "mythicplus", sourceLabel = "Pit of Saron" },
        { dungeon = nil, boss = nil, itemID = 249810, slot = "장신구", note = "BIS", sourceType = "raid", sourceLabel = "Midnight Falls" },
        { dungeon = "마이사라 동굴", boss = nil, itemID = 250223, slot = "장신구", note = "BIS", sourceType = "mythicplus", sourceLabel = "Maisara Caverns" },
    },
}

for specID, overallItems in pairs(overallOverrides) do
    local merged = {}
    local seenKeys = {}
    local slotCounts = {}
    local slotFallbackCounts = {}
    local slotHasOverallMythicPlusBis = {}

    for _, entry in ipairs(overallItems) do
        local slotName = entry.slot or "기타"
        if isBisNote(entry.note) and isMythicPlusEntry(entry) then
            slotHasOverallMythicPlusBis[slotName] = true
        end
    end

    local function addEntry(entry, legacyFallback)
        local copy = cloneEntry(entry)
        local slotName = copy.slot or "기타"
        if legacyFallback and slotHasOverallMythicPlusBis[slotName] then
            return
        end
        local entryKey = buildEntryKey(copy)
        if seenKeys[entryKey] then
            return
        end

        local existingCount = slotCounts[slotName] or 0
        local fallbackCount = slotFallbackCounts[slotName] or 0

        if legacyFallback and existingCount > 0 and isBisNote(copy.note) then
            copy.note = nextFallbackNote(fallbackCount + 1)
        elseif not copy.note or copy.note == "" then
            copy.note = nextFallbackNote(existingCount)
        end

        merged[#merged + 1] = copy
        seenKeys[entryKey] = true
        slotCounts[slotName] = existingCount + 1
        if not isBisNote(copy.note) then
            slotFallbackCounts[slotName] = fallbackCount + 1
        end
    end

    for _, entry in ipairs(overallItems) do
        addEntry(entry, false)
    end

    for _, entry in ipairs(legacyDungeonFallbacks[specID] or {}) do
        addEntry(entry, true)
    end

    ns.Data.BISItems[specID] = merged
end

for specID, entries in pairs(legacyDungeonFallbacks) do
    if not ns.Data.BISItems[specID] then
        local copiedEntries = {}
        for _, entry in ipairs(entries) do
            copiedEntries[#copiedEntries + 1] = cloneEntry(entry)
        end
        ns.Data.BISItems[specID] = copiedEntries
    end
end
