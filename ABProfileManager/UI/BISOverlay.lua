local _, ns = ...

local BISOverlay = {}
ns.UI.BISOverlay = BISOverlay

-- ============================================================
-- 레이아웃 상수
-- ============================================================

local FRAME_W      = 434
local PADDING      = 6
local ROW_H        = 19
local SECTION_H    = 24
local ICON_SIZE    = 15
local TAB_SIZE     = 24
local TABS_H       = 30              -- spec tabs + source filter row
local TITLE_H      = 26
local MAX_SCROLL_H = 340
local FONT_PATH    = "Fonts\\2002.TTF"
local FONT_FLAGS   = "OUTLINE"

-- 스케일 조절 (헤더 영역 마우스 휠)
local SCALE_STEP = 0.05
local SCALE_MIN  = 0.50
local SCALE_MAX  = 2.00
local _bisScale  = 1.0

-- 커스텀 스크롤바 치수
local SB_W   = 7    -- 스크롤바 폭
local SB_GAP = 5    -- 스크롤바와 컨텐츠 사이 간격

-- 헤더 총 높이
local HEADER_H  = TITLE_H + 8 + TABS_H + 12

-- 컨텐츠 폭: 스크롤바(+갭+오른쪽 패딩) 제외
local CONTENT_W = FRAME_W - PADDING - (PADDING + SB_W + SB_GAP)  -- = 430

-- 아이템 행 컬럼 레이아웃
local ITEM_INDENT = 1
local ITEM_W      = CONTENT_W - ITEM_INDENT
local COL_ICON    = ICON_SIZE + 5
local COL_NAME    = 210
local COL_SLOT    = 96
local COL_TYPE    = 34
local COL_NOTE    = 40
local SPEC_PICKER_W = 154
local SPEC_PICKER_BTN_H = 22
local SPEC_PICKER_ROW_H = 20
local SPEC_PICKER_MAX_VISIBLE = 12
local FILTER_BTN_W = 48
local FILTER_BTN_H = 18

local BIS_SOURCE_ORDER = { "mythicplus", "raid", "crafted" }
local BIS_SOURCE_DEFAULTS = {
    mythicplus = true,
    raid = true,
    crafted = true,
}
local BIS_SOURCE_LABEL_KEYS = {
    mythicplus = "bis_source_mplus",
    raid = "bis_source_raid",
    crafted = "bis_source_crafted",
}

-- 아이템 품질 색상
local QC = {
    [0] = { 0.55, 0.55, 0.55 },
    [1] = { 0.85, 0.85, 0.85 },
    [2] = { 0.12, 1.00, 0.00 },
    [3] = { 0.20, 0.65, 1.00 },
    [4] = { 0.80, 0.35, 1.00 },
    [5] = { 1.00, 0.55, 0.00 },
}

local function getSeasonDisplayQuality(itemQuality)
    -- 시즌 M+ 드랍은 구던 원본 품질이 파템이어도 최소 에픽으로 보정해서 보여준다.
    return math.max(itemQuality or 4, 4)
end

local function getQualityColor(itemQuality)
    local effectiveQ = getSeasonDisplayQuality(itemQuality)
    return QC[effectiveQ] or QC[4], effectiveQ
end

local SLOT_ORDER = {
    "무기", "보조장비", "방패", "머리", "목", "어깨", "망토", "가슴",
    "손목", "손", "허리", "다리", "발", "반지", "장신구",
}

local SLOT_SORT_ORDER = {}
for i, slotName in ipairs(SLOT_ORDER) do
    SLOT_SORT_ORDER[slotName] = i
end

local SLOT_LOCALE_KEYS = {
    ["무기"] = "bis_slot_weapon",
    ["보조장비"] = "bis_slot_offhand",
    ["방패"] = "bis_slot_shield",
    ["머리"] = "bis_slot_head",
    ["목"] = "bis_slot_neck",
    ["어깨"] = "bis_slot_shoulders",
    ["망토"] = "bis_slot_cloak",
    ["가슴"] = "bis_slot_chest",
    ["손목"] = "bis_slot_wrist",
    ["손"] = "bis_slot_hands",
    ["허리"] = "bis_slot_waist",
    ["다리"] = "bis_slot_legs",
    ["발"] = "bis_slot_feet",
    ["반지"] = "bis_slot_ring",
    ["장신구"] = "bis_slot_trinket",
}

local DUNGEON_LOCALE_KEYS = {
    ["마법학자의 정원"] = "bis_dungeon_magisters_terrace",
    ["마이사라 동굴"] = "bis_dungeon_maisara_caverns",
    ["공결점 제나스"] = "bis_dungeon_nexus_point_xenas",
    ["공결탑 제나스"] = "bis_dungeon_nexus_point_xenas",
    ["윈드러너 첨탑"] = "bis_dungeon_windrunner_spire",
    ["알게타르 아카데미"] = "bis_dungeon_algethar_academy",
    ["알게타르 대학"] = "bis_dungeon_algethar_academy",
    ["삼두정의 권좌"] = "bis_dungeon_seat_of_the_triumvirate",
    ["하늘탑"] = "bis_dungeon_skyreach",
    ["사론의 구덩이"] = "bis_dungeon_pit_of_saron",
}

local RAID_META_LABEL_PATTERNS = {
    "raid",
    "tier",
    "catalyst",
    "촉매",
    "vault",
}

local NOTE_BADGE_COLOR = {
    bis   = "ffffc000",
    alt   = "ff44aaff",
    third = "ff66cc66",
    rank  = "ff888888",
}

local SOURCE_TYPE_COLOR = {
    mythicplus = { 0.35, 0.78, 1.00 },
    raid = { 1.00, 0.82, 0.44 },
    crafted = { 0.48, 0.88, 0.58 },
}

-- 던전 → 모험 안내서 instanceID 매핑 (returning 던전 확인값, Midnight 신규 던전은 미확인)
local DUNGEON_EJ_IDS = {
    ["공결점 제나스"] = 1314,
    ["공결탑 제나스"] = 1314,
    ["알게타르 아카데미"] = 2526,
    ["알게타르 대학"] = 2526,
}
local DUNGEON_EJ_TIERS = {
    ["공결점 제나스"] = 13,
    ["공결탑 제나스"] = 13,
}
local EJ_INSTANCE_CACHE = {}
local EJ_CANDIDATE_CACHE = {}
local EJ_RAID_CANDIDATES_CACHE = nil
local EJ_ENCOUNTER_CACHE = {}
local EJ_PREVIEW_LINK_CACHE = {}
local EJ_PREVIEW_CONTEXT_CACHE = {}
local _journalNavigationToken = 0
local normalizeCompareText
local getEntrySourceType
local getSeasonalMythicPlusRange
local getSeasonalRaidRange
local requestItemData
local hasRaidMetaLabel
local isCraftingSourceLabel
local isEnglishOnlyLabel
local localizeSourceLabel
local resolveSeasonDungeonName

-- ============================================================
-- Helper 함수들
-- ============================================================

local function getPlayerClassID()
    if not UnitClass then return nil end
    local _, _, classID = UnitClass("player")
    return classID
end

local function ensureEncounterJournalLoaded()
    if EncounterJournal_LoadUI then
        pcall(EncounterJournal_LoadUI)
    elseif UIParentLoadAddOn then
        pcall(UIParentLoadAddOn, "Blizzard_EncounterJournal")
    end

    return type(EJ_SelectInstance) == "function"
        and type(EJ_GetInstanceByIndex) == "function"
end

local function getEnglishLocaleText(key)
    local enUS = ns.Locale and ns.Locale.strings and ns.Locale.strings.enUS
    return enUS and enUS[key] or nil
end

local function getNow()
    if type(GetTime) == "function" then
        return GetTime()
    end
    return 0
end

local function isJournalPreviewSuspended()
    local untilTime = BISOverlay and BISOverlay._journalPreviewSuspendUntil
    return untilTime and untilTime > getNow() or false
end

local function getSeasonPreviewKeyLevel()
    local tbl = ns.Data and ns.Data.ItemLevelTable
    local entries = tbl and tbl.mythicPlus and tbl.mythicPlus.endOfDungeon
    if entries then
        for _, entry in ipairs(entries) do
            if entry.key == 2 then
                return 2
            end
        end
        if entries[#entries] and entries[#entries].key then
            return entries[1].key
        end
    end
    return 2
end

local function getRaidPreviewDifficultyID()
    if DifficultyUtil and DifficultyUtil.ID then
        return DifficultyUtil.ID.PrimaryRaidNormal
            or DifficultyUtil.ID.RaidNormal
            or DifficultyUtil.ID.PrimaryRaidMythic
            or DifficultyUtil.ID.RaidMythic
            or DifficultyUtil.ID.Raid25Heroic
    end
    return 14
end

local function getDungeonCandidates(dungeonName)
    if not dungeonName then return nil end
    if EJ_CANDIDATE_CACHE[dungeonName] ~= nil then
        return EJ_CANDIDATE_CACHE[dungeonName] or {}
    end
    if not ensureEncounterJournalLoaded() then
        EJ_CANDIDATE_CACHE[dungeonName] = false
        EJ_INSTANCE_CACHE[dungeonName] = false
        return {}
    end

    local savedTier = EJ_GetCurrentTier and EJ_GetCurrentTier() or nil
    local tierCount = EJ_GetNumTiers and (EJ_GetNumTiers() or 0) or 0
    local found = {}
    local seen = {}

    local function addCandidate(instanceID, tier)
        if not instanceID or seen[instanceID] then
            return
        end
        seen[instanceID] = true
        found[#found + 1] = {
            instanceID = instanceID,
            tier = tier,
        }
    end

    local normalizedDungeonName = normalizeCompareText and normalizeCompareText(dungeonName) or string.lower(tostring(dungeonName or ""))
    local localeKey = DUNGEON_LOCALE_KEYS[dungeonName]
    local localizedDungeonName = localeKey and ns.L(localeKey) or nil
    local englishDungeonName = localeKey and getEnglishLocaleText(localeKey) or nil
    local normalizedLocalizedName = normalizeCompareText and normalizeCompareText(localizedDungeonName)
        or string.lower(tostring(localizedDungeonName or ""))
    local normalizedEnglishName = normalizeCompareText and normalizeCompareText(englishDungeonName)
        or string.lower(tostring(englishDungeonName or ""))

    local function matchesDungeonName(instanceName)
        if not instanceName or not dungeonName then
            return false
        end
        if instanceName == dungeonName
            or (localizedDungeonName and instanceName == localizedDungeonName)
            or (englishDungeonName and instanceName == englishDungeonName) then
            return true
        end
        local normalizedInstanceName = normalizeCompareText and normalizeCompareText(instanceName)
            or string.lower(tostring(instanceName or ""))
        return normalizedInstanceName == normalizedDungeonName
            or (normalizedLocalizedName ~= "" and normalizedInstanceName == normalizedLocalizedName)
            or (normalizedEnglishName ~= "" and normalizedInstanceName == normalizedEnglishName)
    end

    for tier = tierCount, 1, -1 do
        pcall(EJ_SelectTier, tier)
        local index = 1
        while true do
            local instanceID, instanceName = EJ_GetInstanceByIndex(index, false)
            if not instanceID then
                break
            end
            if matchesDungeonName(instanceName) then
                addCandidate(instanceID, tier)
            end
            index = index + 1
        end
    end

    if savedTier then
        pcall(EJ_SelectTier, savedTier)
    end

    EJ_CANDIDATE_CACHE[dungeonName] = #found > 0 and found or false
    EJ_INSTANCE_CACHE[dungeonName] = found[1] and found[1].instanceID or false
    if found[1] then
        DUNGEON_EJ_IDS[dungeonName] = found[1].instanceID
    end
    return found
end

local function getRaidCandidates()
    if EJ_RAID_CANDIDATES_CACHE ~= nil then
        return EJ_RAID_CANDIDATES_CACHE or {}
    end
    if not ensureEncounterJournalLoaded() then
        EJ_RAID_CANDIDATES_CACHE = false
        return {}
    end

    local savedTier = EJ_GetCurrentTier and EJ_GetCurrentTier() or nil
    local tierCount = EJ_GetNumTiers and (EJ_GetNumTiers() or 0) or 0
    local found = {}
    local seen = {}

    for tier = tierCount, 1, -1 do
        pcall(EJ_SelectTier, tier)
        local index = 1
        while true do
            local instanceID, instanceName = EJ_GetInstanceByIndex(index, true)
            if not instanceID then
                break
            end
            if not seen[instanceID] then
                seen[instanceID] = true
                found[#found + 1] = {
                    instanceID = instanceID,
                    tier = tier,
                    name = instanceName,
                }
            end
            index = index + 1
        end
    end

    if savedTier then
        pcall(EJ_SelectTier, savedTier)
    end

    EJ_RAID_CANDIDATES_CACHE = #found > 0 and found or false
    return found
end

local function getDungeonInstanceID(dungeonName)
    local candidates = getDungeonCandidates(dungeonName)
    if not candidates or #candidates == 0 then
        return nil
    end
    return candidates[1] and candidates[1].instanceID or nil
end

local function getPreviewMythicPlusLootContext(dungeonName, itemID, fallbackName)
    if not dungeonName or (not itemID and not fallbackName) then return nil end

    local previewLevel = getSeasonPreviewKeyLevel()
    local targetName = fallbackName
    if (not targetName or targetName == "") and itemID then
        targetName = select(1, GetItemInfo(itemID))
    end
    local normalizedTargetName = normalizeCompareText(targetName)
    local cacheKey = string.format(
        "%s:%s:%s:%d",
        dungeonName,
        tostring(itemID or 0),
        normalizedTargetName,
        previewLevel
    )
    if EJ_PREVIEW_CONTEXT_CACHE[cacheKey] ~= nil then
        return EJ_PREVIEW_CONTEXT_CACHE[cacheKey] or nil
    end
    if not BISOverlay._allowLiveJournalScan then
        local journalVisible = EncounterJournal and EncounterJournal.IsShown and EncounterJournal:IsShown()
        if journalVisible or isJournalPreviewSuspended() then
            return nil
        end
    end
    if not ensureEncounterJournalLoaded() then
        EJ_PREVIEW_CONTEXT_CACHE[cacheKey] = false
        EJ_PREVIEW_LINK_CACHE[cacheKey] = false
        return nil
    end

    local candidates = getDungeonCandidates(dungeonName)
    if not candidates or #candidates == 0 then
        EJ_PREVIEW_CONTEXT_CACHE[cacheKey] = false
        EJ_PREVIEW_LINK_CACHE[cacheKey] = false
        return nil
    end

    local savedTier = EJ_GetCurrentTier and EJ_GetCurrentTier() or nil
    local savedInstance = EJ_GetCurrentInstance and EJ_GetCurrentInstance() or nil
    local savedDifficulty = EJ_GetDifficulty and EJ_GetDifficulty() or nil
    local savedPreviewLevel = C_EncounterJournal
        and C_EncounterJournal.GetPreviewMythicPlusLevel
        and C_EncounterJournal.GetPreviewMythicPlusLevel()
        or nil

    local foundContext
    for _, candidate in ipairs(candidates) do
        if candidate.tier then
            pcall(EJ_SelectTier, candidate.tier)
        end
        if EJ_SetDifficulty then
            pcall(EJ_SetDifficulty, 23)
        end
        if C_EncounterJournal and C_EncounterJournal.SetPreviewMythicPlusLevel then
            pcall(C_EncounterJournal.SetPreviewMythicPlusLevel, previewLevel)
        end
        if pcall(EJ_SelectInstance, candidate.instanceID)
        and C_EncounterJournal and C_EncounterJournal.GetLootInfoByIndex then
            local lootCount = EJ_GetNumLoot and (EJ_GetNumLoot() or 0) or 0
            for i = 1, lootCount do
                local ok, info = pcall(C_EncounterJournal.GetLootInfoByIndex, i)
                local matched = false
                if ok and info then
                    if itemID and info.itemID == itemID then
                        matched = true
                    elseif normalizedTargetName ~= "" then
                        local previewName = info.name or select(1, GetItemInfo(info.link or info.itemLink or info.itemID or 0))
                        matched = normalizeCompareText(previewName) == normalizedTargetName
                    end
                end
                if matched then
                    local foundLink = info.link or info.itemLink or info.hyperlink
                    if foundLink then
                        foundContext = {
                            link = foundLink,
                            itemID = info.itemID,
                            instanceID = candidate.instanceID,
                            tier = candidate.tier,
                            difficulty = 23,
                            encounterID = info.encounterID,
                            displaySeasonID = info.displaySeasonID,
                            itemQuality = info.itemQuality,
                        }
                        break
                    end
                end
            end
        end
        if foundContext then
            break
        end
    end

    if savedTier then
        pcall(EJ_SelectTier, savedTier)
    end
    if savedInstance then
        pcall(EJ_SelectInstance, savedInstance)
    end
    if savedDifficulty and EJ_SetDifficulty then
        pcall(EJ_SetDifficulty, savedDifficulty)
    end
    if savedPreviewLevel and C_EncounterJournal and C_EncounterJournal.SetPreviewMythicPlusLevel then
        pcall(C_EncounterJournal.SetPreviewMythicPlusLevel, savedPreviewLevel)
    end

    EJ_PREVIEW_CONTEXT_CACHE[cacheKey] = foundContext or false
    EJ_PREVIEW_LINK_CACHE[cacheKey] = foundContext and foundContext.link or false
    return foundContext
end

local function getPreviewMythicPlusLootLink(dungeonName, itemID)
    local context = getPreviewMythicPlusLootContext(dungeonName, itemID)
    return context and context.link or nil
end

local function getPreviewRaidLootContext(itemID, fallbackName)
    if (not itemID or itemID <= 0) and (not fallbackName or fallbackName == "") then
        return nil
    end

    local targetName = fallbackName
    if (not targetName or targetName == "") and itemID then
        targetName = select(1, GetItemInfo(itemID))
    end
    local normalizedTargetName = normalizeCompareText(targetName)
    local cacheKey = string.format("raid:%s:%s", tostring(itemID or 0), normalizedTargetName)
    if EJ_PREVIEW_CONTEXT_CACHE[cacheKey] ~= nil then
        return EJ_PREVIEW_CONTEXT_CACHE[cacheKey] or nil
    end
    if not BISOverlay._allowLiveJournalScan then
        local journalVisible = EncounterJournal and EncounterJournal.IsShown and EncounterJournal:IsShown()
        if journalVisible or isJournalPreviewSuspended() then
            return nil
        end
    end
    if not ensureEncounterJournalLoaded() then
        EJ_PREVIEW_CONTEXT_CACHE[cacheKey] = false
        EJ_PREVIEW_LINK_CACHE[cacheKey] = false
        return nil
    end

    local candidates = getRaidCandidates()
    if not candidates or #candidates == 0 then
        EJ_PREVIEW_CONTEXT_CACHE[cacheKey] = false
        EJ_PREVIEW_LINK_CACHE[cacheKey] = false
        return nil
    end

    local savedTier = EJ_GetCurrentTier and EJ_GetCurrentTier() or nil
    local savedInstance = EJ_GetCurrentInstance and EJ_GetCurrentInstance() or nil
    local savedDifficulty = EJ_GetDifficulty and EJ_GetDifficulty() or nil
    local difficultyID = getRaidPreviewDifficultyID()
    local foundContext

    for _, candidate in ipairs(candidates) do
        if candidate.tier then
            pcall(EJ_SelectTier, candidate.tier)
        end
        if EJ_SetDifficulty then
            pcall(EJ_SetDifficulty, difficultyID)
        end
        if pcall(EJ_SelectInstance, candidate.instanceID)
        and C_EncounterJournal and C_EncounterJournal.GetLootInfoByIndex then
            local lootCount = EJ_GetNumLoot and (EJ_GetNumLoot() or 0) or 0
            for i = 1, lootCount do
                local ok, info = pcall(C_EncounterJournal.GetLootInfoByIndex, i)
                local matched = false
                if ok and info then
                    if itemID and info.itemID == itemID then
                        matched = true
                    elseif normalizedTargetName ~= "" then
                        local previewName = info.name or select(1, GetItemInfo(info.link or info.itemLink or info.itemID or 0))
                        matched = normalizeCompareText(previewName) == normalizedTargetName
                    end
                end
                if matched then
                    local foundLink = info.link or info.itemLink or info.hyperlink
                    if foundLink then
                        foundContext = {
                            link = foundLink,
                            itemID = info.itemID,
                            instanceID = candidate.instanceID,
                            tier = candidate.tier,
                            difficulty = difficultyID,
                            encounterID = info.encounterID,
                            itemQuality = info.itemQuality,
                        }
                        break
                    end
                end
            end
        end
        if foundContext then
            break
        end
    end

    if savedTier then
        pcall(EJ_SelectTier, savedTier)
    end
    if savedInstance then
        pcall(EJ_SelectInstance, savedInstance)
    end
    if savedDifficulty and EJ_SetDifficulty then
        pcall(EJ_SetDifficulty, savedDifficulty)
    end

    EJ_PREVIEW_CONTEXT_CACHE[cacheKey] = foundContext or false
    EJ_PREVIEW_LINK_CACHE[cacheKey] = foundContext and foundContext.link or false
    return foundContext
end

local function getTooltipCompareFilter(useSpec)
    local classID, specID
    if useSpec then
        if EJ_GetLootFilter then
            classID, specID = EJ_GetLootFilter()
        end
        if specID == 0 and C_SpecializationInfo and C_SpecializationInfo.GetSpecialization then
            local spec = C_SpecializationInfo.GetSpecialization()
            if spec and classID == select(3, UnitClass("player")) then
                specID = C_SpecializationInfo.GetSpecializationInfo(spec, nil, nil, nil, UnitSex("player"))
            else
                specID = -1
            end
        end
    end
    return classID, specID
end

local function processEncounterJournalTooltip(tooltip, link, useSpec)
    if not tooltip or not link then
        return false
    end

    if type(CreateBaseTooltipInfo) == "function" and type(tooltip.ProcessInfo) == "function" then
        local classID, specID = getTooltipCompareFilter(useSpec)
        local ok, tooltipInfo = pcall(CreateBaseTooltipInfo, "GetHyperlink", link, classID, specID)
        if ok and tooltipInfo then
            tooltipInfo.compareItem = true
            local processed = pcall(tooltip.ProcessInfo, tooltip, tooltipInfo)
            if processed then
                return true
            end
        end
    end

    if type(EncounterJournal_SetTooltipWithCompare) == "function" then
        local ok = pcall(EncounterJournal_SetTooltipWithCompare, tooltip, link, useSpec)
        if ok then
            return true
        end
    end

    if tooltip.SetHyperlink then
        local ok = pcall(tooltip.SetHyperlink, tooltip, link)
        if ok then
            return true
        end
    end

    return false
end

local function getClassColorRGB(classFile)
    local color = classFile and C_ClassColor and C_ClassColor.GetClassColor and C_ClassColor.GetClassColor(classFile)
    if color then
        return color.r or 0.78, color.g or 0.78, color.b or 0.90
    end
    color = classFile and RAID_CLASS_COLORS and RAID_CLASS_COLORS[classFile]
    if color then
        return color.r or 0.78, color.g or 0.78, color.b or 0.90
    end
    return 0.78, 0.78, 0.90
end

local function getAllSpecs()
    if not GetNumClasses or not GetClassInfo
    or not GetNumSpecializationsForClassID
    or not GetSpecializationInfoForClassID then
        return {}
    end

    local specs = {}
    local playerClassID = getPlayerClassID()
    local numClasses = GetNumClasses() or 0

    for classID = 1, numClasses do
        local className, classFile = GetClassInfo(classID)
        local specCount = GetNumSpecializationsForClassID(classID) or 0
        for specIndex = 1, specCount do
            local ok, specID, specName, _, icon = pcall(
                GetSpecializationInfoForClassID, classID, specIndex
            )
            if ok and specID and specName then
                specs[#specs + 1] = {
                    specID = specID,
                    name = specName,
                    icon = icon,
                    classID = classID,
                    className = className,
                    classFile = classFile,
                    specIndex = specIndex,
                    isPlayerClass = classID == playerClassID,
                }
            end
        end
    end

    table.sort(specs, function(a, b)
        local ap = a.isPlayerClass and 0 or 1
        local bp = b.isPlayerClass and 0 or 1
        if ap ~= bp then
            return ap < bp
        end
        if a.classID ~= b.classID then
            return a.classID < b.classID
        end
        if a.specIndex ~= b.specIndex then
            return a.specIndex < b.specIndex
        end
        return tostring(a.name) < tostring(b.name)
    end)

    return specs
end

local function getSpecInfo(specID)
    if not specID then return nil end
    for _, spec in ipairs(getAllSpecs()) do
        if spec.specID == specID then
            return spec
        end
    end
    return nil
end

local function getClassSpecs()
    local specs = {}
    local classID = getPlayerClassID()
    if not classID then return specs end

    for _, spec in ipairs(getAllSpecs()) do
        if spec.classID == classID then
            specs[#specs + 1] = spec
        end
    end
    return specs
end

local function getPlayerSpecID()
    if not GetSpecialization or not GetSpecializationInfo then return nil end
    local idx = GetSpecialization()
    if not idx then return nil end
    local ok, specID = pcall(GetSpecializationInfo, idx)
    if ok and specID then return specID end
    return nil
end

local function getEncounterJournalContextForEntry(entry, itemID)
    if not entry then
        return nil
    end

    local sourceType = getEntrySourceType(entry)
    local fallbackName = itemID and select(1, GetItemInfo(itemID)) or nil
    if sourceType == "mythicplus" then
        local dungeonName = resolveSeasonDungeonName(entry.dungeon or entry.sourceLabel)
        if not dungeonName then
            return nil
        end
        return getPreviewMythicPlusLootContext(dungeonName, itemID, fallbackName)
    end
    if sourceType == "raid" then
        return getPreviewRaidLootContext(itemID, fallbackName)
    end
    return nil
end

local function buildEncounterHints(entry)
    local hints, seen = {}, {}

    local function addHint(value)
        local text = type(value) == "string" and value:match("^%s*(.-)%s*$") or nil
        if not text or text == "" then
            return
        end
        local normalized = normalizeCompareText(text)
        if normalized == "" or seen[normalized] then
            return
        end
        seen[normalized] = true
        hints[#hints + 1] = {
            raw = text,
            normalized = normalized,
        }
    end

    addHint(entry and entry.boss)
    addHint(entry and entry.sourceLabel)
    addHint(localizeSourceLabel(entry and entry.sourceLabel))
    addHint(entry and entry.dungeon)

    local rawLabel = entry and entry.sourceLabel
    if type(rawLabel) == "string" then
        for token in string.gmatch(rawLabel, "[^,/|]+") do
            local trimmed = token:match("^%s*(.-)%s*$")
            addHint(trimmed)
            addHint(localizeSourceLabel(trimmed))
        end
    end

    return hints
end

local function findEncounterIDInInstance(instanceID, encounterHints)
    if not instanceID or not encounterHints or #encounterHints == 0
        or type(EJ_GetEncounterInfoByIndex) ~= "function" then
        return nil
    end

    for _, hint in ipairs(encounterHints) do
        local cacheKey = string.format("%s:%s", tostring(instanceID), hint.normalized)
        local cached = EJ_ENCOUNTER_CACHE[cacheKey]
        if cached ~= nil then
            if cached ~= false then
                return cached
            end
        else
            local foundEncounterID = nil
            local index = 1
            while true do
                local ok, encounterName, _, encounterID = pcall(EJ_GetEncounterInfoByIndex, index, instanceID)
                if not ok or not encounterName then
                    break
                end
                if normalizeCompareText(encounterName) == hint.normalized then
                    foundEncounterID = encounterID
                    break
                end
                index = index + 1
            end

            EJ_ENCOUNTER_CACHE[cacheKey] = foundEncounterID or false
            if foundEncounterID then
                return foundEncounterID
            end
        end
    end

    return nil
end

local function resolveFallbackJournalTarget(entry)
    if not entry then
        return nil
    end

    local sourceType = getEntrySourceType(entry)
    local encounterHints = buildEncounterHints(entry)

    if sourceType == "mythicplus" then
        local dungeonName = resolveSeasonDungeonName(entry.dungeon or entry.sourceLabel)
        local candidates = dungeonName and getDungeonCandidates(dungeonName) or nil
        local candidate = candidates and candidates[1] or nil
        local instanceID = candidate and candidate.instanceID or (dungeonName and getDungeonInstanceID(dungeonName)) or nil
        if not instanceID then
            return nil
        end
        return {
            instanceID = instanceID,
            tier = candidate and candidate.tier or (dungeonName and DUNGEON_EJ_TIERS[dungeonName]) or nil,
            difficulty = 23,
            encounterID = findEncounterIDInInstance(instanceID, encounterHints),
        }
    end

    if sourceType == "raid" then
        local candidates = getRaidCandidates()
        if not candidates or #candidates == 0 then
            return nil
        end

        for _, candidate in ipairs(candidates) do
            local candidateName = normalizeCompareText(candidate.name)
            for _, hint in ipairs(encounterHints) do
                if hint.normalized == candidateName then
                    return {
                        instanceID = candidate.instanceID,
                        tier = candidate.tier,
                        difficulty = getRaidPreviewDifficultyID(),
                    }
                end
            end
        end

        for _, candidate in ipairs(candidates) do
            local encounterID = findEncounterIDInInstance(candidate.instanceID, encounterHints)
            if encounterID then
                return {
                    instanceID = candidate.instanceID,
                    tier = candidate.tier,
                    difficulty = getRaidPreviewDifficultyID(),
                    encounterID = encounterID,
                }
            end
        end

        return {
            difficulty = getRaidPreviewDifficultyID(),
        }
    end

    return nil
end

-- 모험 안내서 열기 (safe — pcall 보호)
local function openEncounterJournalForEntry(entry, itemID)
    if not entry then
        return
    end

    local sourceType = getEntrySourceType(entry)
    local sourceLabel = entry and (entry.sourceLabel or entry.boss or "")
    if sourceType == "crafted" or hasRaidMetaLabel(sourceLabel) then
        return
    end

    _journalNavigationToken = _journalNavigationToken + 1
    local navigationToken = _journalNavigationToken
    BISOverlay._journalPreviewSuspendUntil = getNow() + 1.0

    local target = resolveFallbackJournalTarget(entry) or {}
    local context
    if not target.instanceID then
        local ok, resolvedContext
        BISOverlay._allowLiveJournalScan = true
        ok, resolvedContext = pcall(getEncounterJournalContextForEntry, entry, itemID)
        BISOverlay._allowLiveJournalScan = false
        if ok then
            context = resolvedContext
        end
    end

    local instanceID = target.instanceID or (context and context.instanceID) or nil
    local tier = target.tier or (context and context.tier) or nil
    local journalItemID = (context and context.itemID) or itemID
    local encounterID = target.encounterID or (context and context.encounterID) or nil
    local difficultyID = target.difficulty or (context and context.difficulty)
        or (sourceType == "raid" and getRaidPreviewDifficultyID() or 23)

    pcall(function()
        if not ensureEncounterJournalLoaded() then
            return
        end
        if tier then
            pcall(EJ_SelectTier, tier)
        end
        if EJ_SetDifficulty then
            pcall(EJ_SetDifficulty, difficultyID)
        end
        if sourceType == "mythicplus"
        and C_EncounterJournal and C_EncounterJournal.SetPreviewMythicPlusLevel then
            pcall(C_EncounterJournal.SetPreviewMythicPlusLevel, getSeasonPreviewKeyLevel())
        end
        if EncounterJournal then
            if not EncounterJournal:IsShown() then
                if ShowUIPanel then
                    ShowUIPanel(EncounterJournal)
                elseif ToggleEncounterJournal then
                    ToggleEncounterJournal()
                end
            end
            if instanceID and type(EncounterJournal_OpenJournal) == "function" then
                pcall(EncounterJournal_OpenJournal, difficultyID, instanceID, encounterID, nil, nil, journalItemID, tier)
            end
            if instanceID then
                C_Timer.After(0.1, function()
                    if navigationToken ~= _journalNavigationToken then
                        return
                    end
                    if tier then
                        pcall(EJ_SelectTier, tier)
                    end
                    if EJ_SetDifficulty then
                        pcall(EJ_SetDifficulty, difficultyID)
                    end
                    if sourceType == "mythicplus"
                    and C_EncounterJournal and C_EncounterJournal.SetPreviewMythicPlusLevel then
                        pcall(C_EncounterJournal.SetPreviewMythicPlusLevel, getSeasonPreviewKeyLevel())
                    end
                    pcall(EJ_SelectInstance, instanceID)
                    if encounterID and EJ_SelectEncounter then
                        pcall(EJ_SelectEncounter, encounterID)
                    end
                    local lootTab = EncounterJournal
                        and EncounterJournal.encounter
                        and EncounterJournal.encounter.info
                        and EncounterJournal.encounter.info.lootTab
                    if lootTab and lootTab.Click then
                        pcall(lootTab.Click, lootTab)
                    end
                end)
            end
        end
    end)
end

local function getAverageItemLevel()
    if type(GetAverageItemLevel) == "function" then
        return math.floor((GetAverageItemLevel() or 0) + 0.5)
    end
    return 0
end

local function getSourceFilters()
    local settings = ns.DB and ns.DB:GetBISOverlaySettings()
    if not settings then
        return BIS_SOURCE_DEFAULTS
    end
    settings.sources = settings.sources or {}
    for sourceType, defaultValue in pairs(BIS_SOURCE_DEFAULTS) do
        if type(settings.sources[sourceType]) ~= "boolean" then
            settings.sources[sourceType] = defaultValue
        end
    end
    return settings.sources
end

local function getRenderSignature(specID)
    local filters = getSourceFilters()
    return table.concat({
        tostring(specID or 0),
        filters.mythicplus and "1" or "0",
        filters.raid and "1" or "0",
        filters.crafted and "1" or "0",
    }, ":")
end

getEntrySourceType = function(entry)
    local sourceType = entry and entry.sourceType
    local sourceLabel = entry and (entry.sourceLabel or entry.dungeon or entry.boss) or nil
    local resolvedDungeon = resolveSeasonDungeonName(entry and entry.dungeon or sourceLabel)

    if sourceType == "crafted" or isCraftingSourceLabel(sourceLabel) then
        return "crafted"
    end
    if resolvedDungeon and sourceType == "raid" and not hasRaidMetaLabel(sourceLabel) then
        return "mythicplus"
    end
    if sourceType == "raid" then
        return "raid"
    end
    if sourceType == "mythicplus" then
        return "mythicplus"
    end
    if resolvedDungeon then
        return "mythicplus"
    end
    return sourceType or "mythicplus"
end

local function isSourceEnabled(sourceType)
    local filters = getSourceFilters()
    local value = filters[sourceType]
    if value == nil then
        value = BIS_SOURCE_DEFAULTS[sourceType]
    end
    return value and true or false
end

local function localizeSlot(slotName)
    local key = slotName and SLOT_LOCALE_KEYS[slotName]
    return key and ns.L(key) or slotName or "?"
end

local function localizeDungeon(dungeonName)
    local key = dungeonName and DUNGEON_LOCALE_KEYS[dungeonName]
    return key and ns.L(key) or dungeonName or "?"
end

local function localizeSourceType(sourceType)
    local key = BIS_SOURCE_LABEL_KEYS[sourceType or "mythicplus"] or BIS_SOURCE_LABEL_KEYS.mythicplus
    return ns.L(key)
end

hasRaidMetaLabel = function(label)
    local normalized = normalizeCompareText(label)
    if normalized == "" then
        return false
    end
    for _, token in ipairs(RAID_META_LABEL_PATTERNS) do
        if normalized:find(token, 1, true) then
            return true
        end
    end
    return false
end

local function getSourceBasisLabel(sourceType)
    local tbl = ns.Data and ns.Data.ItemLevelTable
    if sourceType == "mythicplus" then
        local entries = tbl and tbl.mythicPlus and tbl.mythicPlus.endOfDungeon
        local entry = entries and entries[1]
        if entry and entry.key and entry.ilvl then
            return string.format("+%d %d", entry.key, entry.ilvl)
        end
        return ns.L("bis_basis_mplus")
    end
    if sourceType == "raid" then
        local normal = tbl and tbl.raid and tbl.raid.normal
        if normal and normal.min and normal.max then
            return string.format("%d~%d", normal.min, normal.max)
        end
        return ns.L("bis_basis_raid")
    end
    if sourceType == "crafted" then
        local crafted = tbl and tbl.crafted
        if crafted and crafted.base and crafted.base.ilvl and crafted.r5 and crafted.r5.ilvl then
            return string.format("%d/%d", crafted.base.ilvl, crafted.r5.ilvl)
        end
        return ns.L("bis_basis_crafted")
    end
    return localizeSourceType(sourceType)
end

local function getSourceTypeColor(sourceType)
    local color = SOURCE_TYPE_COLOR[sourceType or "mythicplus"] or SOURCE_TYPE_COLOR.mythicplus
    return color[1], color[2], color[3]
end

local function getDisplaySourceLabel(entry)
    if not entry then
        return "?"
    end

    local sourceType = getEntrySourceType(entry)
    if sourceType == "mythicplus" then
        local dungeonName = resolveSeasonDungeonName(entry.dungeon or entry.sourceLabel)
        return localizeDungeon(dungeonName or entry.dungeon or entry.sourceLabel)
    end
    if sourceType == "crafted" then
        local label = entry.sourceLabel
        if not label or label == "" or isCraftingSourceLabel(label) then
            return ns.L("bis_source_crafted")
        end
        return localizeSourceLabel(label)
    end
    local rawLabel = entry.sourceLabel or entry.boss or localizeSourceType(sourceType)
    local localized = localizeSourceLabel(rawLabel)
    if isEnglishOnlyLabel(localized) and type(rawLabel) == "string" then
        for token in string.gmatch(rawLabel, "[^,/|]+") do
            local trimmed = token:match("^%s*(.-)%s*$")
            local partial = localizeSourceLabel(trimmed)
            if partial and partial ~= "" and not isEnglishOnlyLabel(partial) then
                return partial
            end
        end
    end
    if isEnglishOnlyLabel(localized) then
        return localizeSourceType(sourceType)
    end
    return localized
end

normalizeCompareText = function(text)
    text = string.lower(tostring(text or ""))
    text = text:gsub("|c%x%x%x%x%x%x%x%x", "")
    text = text:gsub("|r", "")
    text = text:gsub("[%s%p%c]+", "")
    return text
end

local ITEM_LEVEL_TOKEN = normalizeCompareText(ITEM_LEVEL or "Item Level")

local SOURCE_LABEL_KOKR = {
    [normalizeCompareText("Crafting")] = "제작",
    [normalizeCompareText("Alchemy")] = "연금술",
    [normalizeCompareText("Blacksmithing")] = "대장기술",
    [normalizeCompareText("Enchanting")] = "마법부여",
    [normalizeCompareText("Engineering")] = "기계공학",
    [normalizeCompareText("Inscription")] = "주문각인",
    [normalizeCompareText("Jewelcrafting")] = "보석세공",
    [normalizeCompareText("Leatherworking")] = "가죽세공",
    [normalizeCompareText("Tailoring")] = "재봉",
    [normalizeCompareText("Catalyst")] = "촉매",
    [normalizeCompareText("Catalyse charge")] = "촉매 충전",
    [normalizeCompareText("Tier")] = "티어",
    [normalizeCompareText("Tier Set")] = "티어 세트",
    [normalizeCompareText("Tier item")] = "티어 아이템",
    [normalizeCompareText("Tier set")] = "티어 세트",
    [normalizeCompareText("Tier Chest")] = "티어 가슴",
    [normalizeCompareText("Tier Gloves")] = "티어 장갑",
    [normalizeCompareText("Tier Helmet")] = "티어 머리",
    [normalizeCompareText("Tier Legs")] = "티어 다리",
    [normalizeCompareText("Catalyst/Tier")] = "촉매 / 티어",
    [normalizeCompareText("Catalyst/Raid")] = "촉매 / 레이드",
    [normalizeCompareText("Catalyst / Raid / Vault")] = "촉매 / 레이드 / 금고",
    [normalizeCompareText("Catalyst / Raid /Vault")] = "촉매 / 레이드 / 금고",
    [normalizeCompareText("Raid / Catalyst")] = "레이드 / 촉매",
    [normalizeCompareText("Raid | Catalyst | Vault")] = "레이드 / 촉매 / 금고",
    [normalizeCompareText("Raid/Vault/Catalyst")] = "레이드 / 금고 / 촉매",
    [normalizeCompareText("Midnight Falls")] = "한밤 폭포",
    [normalizeCompareText("Midnight Falls (Raid)")] = "한밤 폭포",
    [normalizeCompareText("March on Quel’Danas")] = "쿠엘다나스 진격로",
    [normalizeCompareText("March on Quel'danas")] = "쿠엘다나스 진격로",
    [normalizeCompareText("March on Quel’danas, Midnight Falls")] = "쿠엘다나스 진격로",
    [normalizeCompareText("The Voidspire")] = "공허 첨탑",
    [normalizeCompareText("The Dreamrift")] = "꿈의균열",
    [normalizeCompareText("Dreamrift")] = "꿈의균열",
    [normalizeCompareText("Voidscar Arena")] = "공허흉터 투기장",
    [normalizeCompareText("Murder Row")] = "죽음의 골목",
    [normalizeCompareText("Den of Nalorakk")] = "날로라크의 소굴",
    [normalizeCompareText("Windrunner Spire (M+)")] = "윈드러너 첨탑",
    [normalizeCompareText("Windrunner Spire")] = "윈드러너 첨탑",
    [normalizeCompareText("Seat of the Triumvirate (M+)")] = "삼두정의 권좌",
    [normalizeCompareText("Seat of the Triumvirate")] = "삼두정의 권좌",
    [normalizeCompareText("Magister Terrace")] = "마법학자의 정원",
    [normalizeCompareText("Magisters' Terrace")] = "마법학자의 정원",
    [normalizeCompareText("Magisters’ Terrace (Degentrius)")] = "마법학자의 정원",
    [normalizeCompareText("Maisara Caverns")] = "마이사라 동굴",
    [normalizeCompareText("Nexus-Point")] = "공결탑 제나스",
    [normalizeCompareText("Nexus-Point Xenas")] = "공결탑 제나스",
    [normalizeCompareText("Nexus-Point Xenas Belo'ren")] = "공결탑 제나스",
    [normalizeCompareText("공결점 제나스")] = "공결탑 제나스",
    [normalizeCompareText("Pit of Saron")] = "사론의 구덩이",
    [normalizeCompareText("Algeth'ar Academy")] = "알게타르 대학",
    [normalizeCompareText("Algeth’ar Academy")] = "알게타르 대학",
    [normalizeCompareText("Algethar’s Academy")] = "알게타르 대학",
    [normalizeCompareText("Algethar Academy")] = "알게타르 대학",
    [normalizeCompareText("Alhgeth’ar Academy")] = "알게타르 대학",
    [normalizeCompareText("알게타르 아카데미")] = "알게타르 대학",
    [normalizeCompareText("Skyreach")] = "하늘탑",
    [normalizeCompareText("Skyreach / Vaelgor & Ezzorak")] = "하늘탑",
    [normalizeCompareText("Fallen King Salhadaar")] = "공허 첨탑",
    [normalizeCompareText("Fallen-King Salhadaar")] = "공허 첨탑",
    [normalizeCompareText("Lightblinded Vanguard")] = "공허 첨탑",
    [normalizeCompareText("Crown of the Cosmos")] = "공허 첨탑",
    [normalizeCompareText("Crown of the cosmos")] = "공허 첨탑",
    [normalizeCompareText("Imperator Averzian")] = "공허 첨탑",
    [normalizeCompareText("Belo'ren")] = "공허 첨탑",
    [normalizeCompareText("Belo’ren")] = "공허 첨탑",
    [normalizeCompareText("Belo’ren (Raid)")] = "공허 첨탑",
    [normalizeCompareText("Belo'ren, Child of Al'ar")] = "공허 첨탑",
    [normalizeCompareText("Belo’ren, Child of Al’ar")] = "공허 첨탑",
    [normalizeCompareText("Vaelgor")] = "공허 첨탑",
    [normalizeCompareText("Vaelgor & Ezzorak")] = "공허 첨탑",
    [normalizeCompareText("Vaelgor & Ezzorak (Raid)")] = "공허 첨탑",
    [normalizeCompareText("Vaelgor and Ezzorak")] = "공허 첨탑",
    [normalizeCompareText("Vorasius")] = "공허 첨탑",
    [normalizeCompareText("Chimaerus")] = "꿈의균열",
    [normalizeCompareText("Chimaerus (Raid)")] = "꿈의균열",
    [normalizeCompareText("Chimaerus the Undreamt God")] = "꿈의균열",
    [normalizeCompareText("Chimareus, the Undreamt God")] = "꿈의균열",
    [normalizeCompareText("L’ura")] = "꿈의균열",
    [normalizeCompareText("Alleria Windrunner")] = "쿠엘다나스 진격로",
}

localizeSourceLabel = function(label)
    if not label or label == "" then
        return label
    end
    if ns.DB and ns.Constants and ns.DB.GetLanguage
        and ns.DB:GetLanguage() == ns.Constants.LANGUAGE.KOREAN then
        local localized = SOURCE_LABEL_KOKR[normalizeCompareText(label)]
        if localized and localized ~= "" then
            return localized
        end
    end
    return label
end

isEnglishOnlyLabel = function(label)
    return type(label) == "string" and label:find("[A-Za-z]") ~= nil and label:find("[가-힣]") == nil
end

isCraftingSourceLabel = function(label)
    local normalized = normalizeCompareText(label)
    return normalized == normalizeCompareText("Crafting")
        or normalized == normalizeCompareText("Tailoring")
        or normalized == normalizeCompareText("Leatherworking")
        or normalized == normalizeCompareText("Blacksmithing")
        or normalized == normalizeCompareText("Engineering")
        or normalized == normalizeCompareText("Jewelcrafting")
        or normalized == normalizeCompareText("Enchanting")
        or normalized == normalizeCompareText("Inscription")
        or normalized == normalizeCompareText("Alchemy")
end

resolveSeasonDungeonName = function(label)
    if not label or label == "" then
        return nil
    end

    if DUNGEON_LOCALE_KEYS[label] then
        return label
    end

    local localized = localizeSourceLabel(label)
    if localized and DUNGEON_LOCALE_KEYS[localized] then
        return localized
    end

    local normalized = normalizeCompareText(label)
    for dungeonName, localeKey in pairs(DUNGEON_LOCALE_KEYS) do
        if normalized == normalizeCompareText(dungeonName) then
            return dungeonName
        end
        local englishName = getEnglishLocaleText(localeKey)
        if englishName and normalized == normalizeCompareText(englishName) then
            return dungeonName
        end
    end

    return nil
end

local function extractTooltipItemLevel(tooltipData)
    if type(tooltipData) ~= "table" then
        return nil
    end

    local overrideItemLevel = tonumber(tooltipData.overrideItemLevel)
    if overrideItemLevel and overrideItemLevel > 0 then
        return math.floor(overrideItemLevel + 0.5)
    end

    for _, line in ipairs(tooltipData.lines or {}) do
        for _, field in ipairs({ line.leftText, line.rightText, line.text }) do
            local text = tostring(field or "")
            local normalized = normalizeCompareText(text)
            if normalized ~= "" and normalized:find(ITEM_LEVEL_TOKEN, 1, true) then
                local itemLevel = tonumber(text:match("(%d%d%d)"))
                if itemLevel then
                    return itemLevel
                end
            end
        end
    end

    return nil
end

local function validatePreviewTooltip(previewContext)
    if not previewContext or not previewContext.link
        or not C_TooltipInfo or not C_TooltipInfo.GetHyperlink then
        return nil
    end

    local classID, specID = getTooltipCompareFilter(true)
    local ok, tooltipData = pcall(C_TooltipInfo.GetHyperlink, previewContext.link, classID, specID, true)
    if not ok or not tooltipData then
        return nil
    end

    local itemLevel = extractTooltipItemLevel(tooltipData)
    local minIlvl, maxIlvl = getSeasonalMythicPlusRange()
    local trusted = itemLevel ~= nil and minIlvl ~= nil and maxIlvl ~= nil
        and itemLevel >= minIlvl and itemLevel <= maxIlvl

    return {
        trusted = trusted and true or false,
        itemLevel = itemLevel,
        tooltipData = tooltipData,
    }
end

local function validateRaidPreviewTooltip(previewContext)
    if not previewContext or not previewContext.link
        or not C_TooltipInfo or not C_TooltipInfo.GetHyperlink then
        return nil
    end

    local classID, specID = getTooltipCompareFilter(true)
    local ok, tooltipData = pcall(C_TooltipInfo.GetHyperlink, previewContext.link, classID, specID, true)
    if not ok or not tooltipData then
        return nil
    end

    local itemLevel = extractTooltipItemLevel(tooltipData)
    local minIlvl, maxIlvl = getSeasonalRaidRange()
    local trusted = itemLevel ~= nil and minIlvl ~= nil and maxIlvl ~= nil
        and itemLevel >= minIlvl and itemLevel <= maxIlvl

    return {
        trusted = trusted and true or false,
        itemLevel = itemLevel,
        tooltipData = tooltipData,
    }
end

local function canonicalNote(note)
    if note == "BIS" then
        return "bis"
    end
    if note == "대체재" or note == "대체" then
        return "alt"
    end
    if note == "2순위" or note == "3순위" then
        return "third"
    end
    return "rank"
end

local function notePriority(note)
    local canonical = canonicalNote(note)
    if canonical == "bis" then return 1 end
    if canonical == "alt" then return 2 end
    if canonical == "third" then return 3 end
    return 4
end

local function noteBadge(kind, index)
    local key
    if kind == "bis" then
        key = "bis_note_bis"
    elseif kind == "alt" then
        key = "bis_note_alt"
    elseif kind == "third" then
        key = "bis_note_third"
    else
        key = nil
    end

    local label = key and ns.L(key) or (index and ns.L("bis_note_rank", index) or "")
    local color = NOTE_BADGE_COLOR[kind] or NOTE_BADGE_COLOR.rank
    return label ~= "" and ("|c" .. color .. label .. "|r") or ""
end

local function notePlain(kind, index)
    if kind == "bis" then
        return ns.L("bis_note_bis")
    end
    if kind == "alt" then
        return ns.L("bis_note_alt")
    end
    if kind == "third" then
        return ns.L("bis_note_third")
    end
    return ns.L("bis_note_rank", index or 4)
end

local function formatSpecSelection(spec)
    if not spec then
        return ns.L("bis_all_specs") or "All Specs"
    end
    local classLabel = spec.className or "?"
    local specLabel = spec.name or ("Spec " .. tostring(spec.specID))
    return classLabel .. "/" .. specLabel
end

local function formatTrackLabel(grade, rank, rankMax)
    if not grade then return "" end
    local label = ns.L("ilvl_crest_" .. grade) or ns.L("ilvl_grade_" .. grade) or grade
    if rank and rankMax then
        return string.format("%s %d/%d", label, rank, rankMax)
    end
    return label
end

local function trackSummary(grades)
    local tbl = ns.Data and ns.Data.ItemLevelTable
    local gradeMax = tbl and tbl.gradeMax
    if not gradeMax then return "" end

    local parts = {}
    for _, grade in ipairs(grades or {}) do
        local maxIlvl = gradeMax[grade]
        if maxIlvl then
            local label = ns.L("ilvl_crest_" .. grade) or ns.L("ilvl_grade_" .. grade) or grade
            parts[#parts + 1] = label .. " ~" .. tostring(maxIlvl)
        end
    end
    return table.concat(parts, ", ")
end

local function getSeasonalMythicPlusSummary(kind)
    local tbl = ns.Data and ns.Data.ItemLevelTable
    local entries = tbl and tbl.mythicPlus and tbl.mythicPlus.endOfDungeon
    if not entries or #entries == 0 then return "" end

    local first = entries[1]
    local last = entries[#entries]
    if kind == "run" then
        return string.format("%d~%d (%s -> %s)",
            first.ilvl or 0,
            last.ilvl or 0,
            formatTrackLabel(first.grade, first.rank, first.rankMax),
            formatTrackLabel(last.grade, last.rank, last.rankMax)
        )
    end

    return string.format("%d~%d (%s -> %s)",
        first.vault or 0,
        last.vault or 0,
        formatTrackLabel(first.vaultGrade, first.vaultRank, first.vaultMax),
        formatTrackLabel(last.vaultGrade, last.vaultRank, last.vaultMax)
    )
end

getSeasonalMythicPlusRange = function()
    local tbl = ns.Data and ns.Data.ItemLevelTable
    local entries = tbl and tbl.mythicPlus and tbl.mythicPlus.endOfDungeon
    if not entries or #entries == 0 then return nil, nil end
    return entries[1].ilvl, entries[#entries].ilvl
end

getSeasonalRaidRange = function()
    local tbl = ns.Data and ns.Data.ItemLevelTable
    local raid = tbl and tbl.raid
    if not raid or not raid.normal or not raid.mythic then
        return nil, nil
    end
    return raid.normal.min, raid.mythic.max
end

local function getSeasonalRaidSummaryLines()
    local tbl = ns.Data and ns.Data.ItemLevelTable
    local raid = tbl and tbl.raid
    if not raid then
        return {}
    end

    local order = { "normal", "heroic", "mythic" }
    local lines = {}
    for _, key in ipairs(order) do
        local entry = raid[key]
        if entry then
            lines[#lines + 1] = {
                label = ns.L(entry.labelKey) or key,
                text = string.format("%d~%d", entry.min or 0, entry.max or 0),
            }
        end
    end
    return lines
end

local function getSeasonalCraftedSummaryLines()
    local tbl = ns.Data and ns.Data.ItemLevelTable
    local crafted = tbl and tbl.crafted
    if not crafted then
        return {}
    end

    local lines = {}
    if crafted.base and crafted.base.ilvl then
        lines[#lines + 1] = {
            label = ns.L(crafted.base.labelKey) or "Crafted",
            text = tostring(crafted.base.ilvl),
        }
    end
    if crafted.r5 and crafted.r5.ilvl then
        lines[#lines + 1] = {
            label = ns.L(crafted.r5.labelKey) or "Crafted (Max)",
            text = tostring(crafted.r5.ilvl),
        }
    end
    return lines
end

local function slotSortValue(slotName)
    return SLOT_SORT_ORDER[slotName] or 999
end

local function groupBySlot(items)
    local slots, order = {}, {}
    for _, item in ipairs(items) do
        local slotName = item.slot or "기타"
        if not slots[slotName] then
            slots[slotName] = {}
            order[#order + 1] = slotName
        end
        slots[slotName][#slots[slotName] + 1] = item
    end

    table.sort(order, function(a, b)
        local av, bv = slotSortValue(a), slotSortValue(b)
        if av ~= bv then
            return av < bv
        end
        return tostring(a) < tostring(b)
    end)

    for _, slotName in ipairs(order) do
        local entries = slots[slotName]
        table.sort(entries, function(a, b)
            local ap, bp = notePriority(a.note), notePriority(b.note)
            if ap ~= bp then
                return ap < bp
            end
            local aSource = getDisplaySourceLabel(a)
            local bSource = getDisplaySourceLabel(b)
            if aSource ~= bSource then
                return aSource < bSource
            end
            return (a.itemID or 0) < (b.itemID or 0)
        end)

        for index, entry in ipairs(entries) do
            if index == 1 then
                entry._displayNoteKind = "bis"
                entry._displayNoteIndex = 1
            elseif index == 2 then
                entry._displayNoteKind = "alt"
                entry._displayNoteIndex = 2
            elseif index == 3 then
                entry._displayNoteKind = "third"
                entry._displayNoteIndex = 3
            else
                entry._displayNoteKind = "rank"
                entry._displayNoteIndex = index
            end
        end
    end

    return slots, order
end

-- ============================================================
-- 아이템 정보 로드 이벤트 → 디바운스 재빌드
-- ============================================================

local _rebuildPending = false
local function scheduleRebuild()
    if _rebuildPending then return end
    _rebuildPending = true
    C_Timer.After(0.3, function()
        _rebuildPending = false
        if BISOverlay.frame and BISOverlay.frame:IsShown() then
            pcall(function()
                BISOverlay:RefreshVisibleItemRows()
                BISOverlay:UpdateScrollThumb()
            end)
        end
    end)
end

local function refreshItemRowDisplay(row)
    if not row or not row.nameLabel then
        return false
    end

    row.nameLabel:ClearAllPoints()
    row.nameLabel:SetFont(FONT_PATH, 11, FONT_FLAGS)

    if row.itemID and row.itemID > 0 then
        local ok, itemName, _, quality, _, _, _, _, _, _, texture = pcall(GetItemInfo, row.itemID)
        if ok and itemName then
            if texture then
                row.icon:SetTexture(texture)
                row.icon:SetPoint("LEFT", row, "LEFT", 0, 0)
                row.icon:Show()
            else
                row.icon:Hide()
            end

            local nameX = texture and COL_ICON or 0
            local nameW = COL_NAME + (texture and 0 or COL_ICON)
            row.nameLabel:SetPoint("LEFT", row, "LEFT", nameX, 0)
            row.nameLabel:SetWidth(nameW)

            local qc = getQualityColor(quality)
            row.nameLabel:SetTextColor(qc[1], qc[2], qc[3], 1)
            row.nameLabel:SetText(itemName)
            return true
        end

        requestItemData(row.itemID)
    end

    row.icon:Hide()
    row.nameLabel:SetPoint("LEFT", row, "LEFT", 0, 0)
    row.nameLabel:SetWidth(COL_NAME + COL_ICON)
    row.nameLabel:SetTextColor(QC[4][1], QC[4][2], QC[4][3], 0.50)
    row.nameLabel:SetText("...")
    return false
end

-- ============================================================
-- 스크롤바 썸 업데이트
-- ============================================================

function BISOverlay:UpdateScrollThumb()
    local frame = self.frame
    if not frame or not frame.scrollBarThumb then return end
    local sf        = frame.scrollFrame
    local contentH  = frame.content:GetHeight()
    local sfH       = math.max(1, sf:GetHeight())
    local trackH    = math.max(1, frame.scrollBarTrack:GetHeight())

    if contentH <= sfH then
        frame.scrollBarThumb:Hide()
        return
    end

    frame.scrollBarThumb:Show()
    local ratio  = sfH / contentH
    local thumbH = math.max(22, trackH * ratio)
    frame.scrollBarThumb:SetHeight(thumbH)

    local scrollRange = math.max(1, sf:GetVerticalScrollRange())
    local scrollPos   = sf:GetVerticalScroll()
    local thumbTravel = trackH - thumbH
    local thumbY      = -(scrollPos / scrollRange * thumbTravel)
    frame.scrollBarThumb:ClearAllPoints()
    frame.scrollBarThumb:SetPoint("TOPRIGHT", frame.scrollBarTrack, "TOPRIGHT", 0, thumbY)
end

-- ============================================================
-- 접기/펼치기
-- ============================================================

function BISOverlay:ApplyCollapse()
    local frame = self.frame
    if not frame then return end
    if self._collapsed then
        if frame.specPicker then frame.specPicker:Hide() end
        frame.scrollFrame:Hide()
        frame.scrollBarTrack:Hide()
        frame.scrollBarThumb:Hide()
        if frame.collapseBtn then frame.collapseBtn.label:SetText("+") end
        frame:SetHeight(HEADER_H + PADDING)
    else
        frame.scrollFrame:Show()
        frame.scrollBarTrack:Show()
        if frame.collapseBtn then frame.collapseBtn.label:SetText("-") end
        pcall(function() self:RebuildContent() end)
    end
end

function BISOverlay:UpdateSourceFilterButtons()
    local frame = self.frame
    if not frame or not frame.sourceButtons then return end

    for sourceType, button in pairs(frame.sourceButtons) do
        local active = isSourceEnabled(sourceType)
        local label = ns.L(BIS_SOURCE_LABEL_KEYS[sourceType]) or sourceType
        if button.label then
            button.label:SetText(label)
        end
        if button.checkMark then
            button.checkMark:SetText(active and "X" or "")
        end
        if active then
            if button.fill then
                button.fill:SetColorTexture(0.10, 0.16, 0.25, 0.92)
            end
            if button.SetBackdropBorderColor then
                button:SetBackdropBorderColor(0.34, 0.76, 1.00, 0.92)
            end
            if button.checkFill then
                button.checkFill:SetColorTexture(0.18, 0.42, 0.68, 0.98)
            end
            if button.checkBox and button.checkBox.SetBackdropBorderColor then
                button.checkBox:SetBackdropBorderColor(0.38, 0.82, 1.00, 0.95)
            end
            if button.checkMark then
                button.checkMark:SetTextColor(1, 1, 1, 1)
            end
            if button.label then
                button.label:SetTextColor(1, 1, 1, 1)
            end
        else
            if button.fill then
                button.fill:SetColorTexture(0.08, 0.10, 0.18, 0.88)
            end
            if button.SetBackdropBorderColor then
                button:SetBackdropBorderColor(0.26, 0.30, 0.42, 0.78)
            end
            if button.checkFill then
                button.checkFill:SetColorTexture(0.04, 0.05, 0.10, 0.95)
            end
            if button.checkBox and button.checkBox.SetBackdropBorderColor then
                button.checkBox:SetBackdropBorderColor(0.32, 0.38, 0.52, 0.88)
            end
            if button.label then
                button.label:SetTextColor(0.72, 0.78, 0.90, 1)
            end
        end
    end
end

function BISOverlay:ToggleSourceFilter(sourceType)
    local filters = getSourceFilters()
    filters[sourceType] = not isSourceEnabled(sourceType)
    self:UpdateSourceFilterButtons()
    self:RebuildContent()
end

-- ============================================================
-- 프레임 생성
-- ============================================================

function BISOverlay:EnsureFrame()
    if self.frame then return self.frame end

    local frame = CreateFrame("Frame", "ABPMBISOverlay", UIParent, "BackdropTemplate")
    frame:SetFrameStrata("DIALOG")
    frame:SetFrameLevel(100)
    frame:SetClampedToScreen(true)
    frame:SetSize(FRAME_W, HEADER_H + 60)

    if frame.SetBackdrop then
        frame:SetBackdrop({
            bgFile   = "Interface\\Tooltips\\UI-Tooltip-Background",
            edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
            tile = true, tileSize = 8, edgeSize = 18,
            insets = { left = 5, right = 5, top = 5, bottom = 5 },
        })
        frame:SetBackdropColor(0.03, 0.04, 0.10, 0.96)
        frame:SetBackdropBorderColor(0.50, 0.40, 0.80, 0.90)
    end

    -- 드래그 (잠금 상태 확인)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:EnableMouseWheel(true)
    frame:RegisterForDrag("LeftButton")
    -- 헤더 영역(스크롤프레임 밖)에서 마우스 휠 → 스케일 조절
    frame:SetScript("OnMouseWheel", function(f, delta)
        _bisScale = math.max(SCALE_MIN, math.min(SCALE_MAX,
            _bisScale + delta * SCALE_STEP))
        _bisScale = math.floor(_bisScale * 100 + 0.5) / 100
        f:SetScale(_bisScale)
    end)
    frame:SetScript("OnDragStart", function(f)
        if ns.DB and ns.DB:IsBISOverlayLocked() then return end
        f:StartMoving()
    end)
    frame:SetScript("OnDragStop",  function(f) f:StopMovingOrSizing() end)
    frame:SetScript("OnHide",      function(f)
        f:StopMovingOrSizing()
        if f.specPicker then f.specPicker:Hide() end
    end)

    -- ─── 제목 바 배경 ───────────────────────────────────────
    local titleBar = frame:CreateTexture(nil, "BACKGROUND")
    titleBar:SetHeight(TITLE_H + 14)
    titleBar:SetPoint("TOPLEFT",  frame, "TOPLEFT",  5,  -5)
    titleBar:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -5, -5)
    titleBar:SetColorTexture(0.10, 0.07, 0.22, 0.90)

    -- 제목 텍스트
    frame.titleText = frame:CreateFontString(nil, "OVERLAY")
    frame.titleText:SetFont(FONT_PATH, 13, FONT_FLAGS)
    frame.titleText:SetPoint("TOPLEFT", frame, "TOPLEFT", PADDING + 2, -10)
    frame.titleText:SetTextColor(0.92, 0.82, 1.0, 1)
    frame.titleText:SetText(ns.L("bis_overlay_title"))

    frame.hintText = frame:CreateFontString(nil, "OVERLAY")
    frame.hintText:SetFont(FONT_PATH, 9, FONT_FLAGS)
    frame.hintText:SetPoint("LEFT", frame.titleText, "RIGHT", 6, 0)
    frame.hintText:SetTextColor(0.60, 0.72, 0.88, 1)
    frame.hintText:SetText(ns.L("bis_overlay_hint"))

    frame.noticeText = frame:CreateFontString(nil, "OVERLAY")
    frame.noticeText:SetFont(FONT_PATH, 9, FONT_FLAGS)
    frame.noticeText:SetPoint("LEFT", frame.hintText, "RIGHT", 6, 0)
    frame.noticeText:SetTextColor(1.00, 0.82, 0.46, 1)
    frame.noticeText:SetText(ns.L("bis_overlay_notice"))

    frame.avgLabel = frame:CreateFontString(nil, "OVERLAY")
    frame.avgLabel:SetFont(FONT_PATH, 9, FONT_FLAGS)
    frame.avgLabel:SetPoint("RIGHT", titleBar, "RIGHT", -(PADDING + 16), 0)
    frame.avgLabel:SetJustifyH("RIGHT")
    frame.avgLabel:SetTextColor(0.82, 0.86, 0.94, 1)
    frame.avgLabel:SetText(ns.L("bis_overlay_avg_label", "?"))

    -- ─── 접기/펼치기 버튼 ────────────────────────────────────
    local collapseBtn = CreateFrame("Button", nil, frame)
    collapseBtn:SetSize(18, 18)
    collapseBtn:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -PADDING, -9)

    collapseBtn.label = collapseBtn:CreateFontString(nil, "OVERLAY")
    collapseBtn.label:SetFont(FONT_PATH, 11, FONT_FLAGS)
    collapseBtn.label:SetAllPoints()
    collapseBtn.label:SetJustifyH("CENTER")
    collapseBtn.label:SetJustifyV("MIDDLE")
    collapseBtn.label:SetText("-")
    collapseBtn.label:SetTextColor(0.70, 0.70, 0.80, 1)

    collapseBtn:SetScript("OnClick", function()
        BISOverlay._collapsed = not BISOverlay._collapsed
        BISOverlay:ApplyCollapse()
    end)
    frame.collapseBtn = collapseBtn

    -- ─── 구분선 1 ───────────────────────────────────────────
    local sep1 = frame:CreateTexture(nil, "ARTWORK")
    sep1:SetHeight(1)
    sep1:SetPoint("TOPLEFT",  frame, "TOPLEFT",  PADDING,  -(TITLE_H + 10))
    sep1:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -PADDING, -(TITLE_H + 10))
    sep1:SetColorTexture(0.45, 0.35, 0.70, 0.65)

    -- ─── 스펙 탭 영역 ────────────────────────────────────────
    frame.tabsFrame = CreateFrame("Frame", nil, frame)
    frame.tabsFrame:SetPoint("TOPLEFT",  frame, "TOPLEFT",  PADDING,  -(TITLE_H + 12))
    frame.tabsFrame:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -PADDING, -(TITLE_H + 12))
    frame.tabsFrame:SetHeight(TABS_H)
    frame.tabs = {}

    frame.specPickerBtn = CreateFrame("Button", nil, frame.tabsFrame, "BackdropTemplate")
    frame.specPickerBtn:SetSize(SPEC_PICKER_W, SPEC_PICKER_BTN_H)
    frame.specPickerBtn:SetPoint("TOPRIGHT", frame.tabsFrame, "TOPRIGHT", 0, -1)
    if frame.specPickerBtn.SetBackdrop then
        frame.specPickerBtn:SetBackdrop({
            bgFile   = "Interface\\Tooltips\\UI-Tooltip-Background",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true, tileSize = 8, edgeSize = 8,
            insets = { left = 2, right = 2, top = 2, bottom = 2 },
        })
        frame.specPickerBtn:SetBackdropColor(0.07, 0.10, 0.18, 0.97)
        frame.specPickerBtn:SetBackdropBorderColor(0.30, 0.38, 0.56, 0.92)
    end
    frame.specPickerBtn.fill = frame.specPickerBtn:CreateTexture(nil, "BACKGROUND")
    frame.specPickerBtn.fill:SetPoint("TOPLEFT", frame.specPickerBtn, "TOPLEFT", 3, -3)
    frame.specPickerBtn.fill:SetPoint("BOTTOMRIGHT", frame.specPickerBtn, "BOTTOMRIGHT", -3, 3)
    frame.specPickerBtn.fill:SetColorTexture(0.10, 0.14, 0.23, 0.92)
    frame.specPickerBtn.accent = frame.specPickerBtn:CreateTexture(nil, "ARTWORK")
    frame.specPickerBtn.accent:SetWidth(2)
    frame.specPickerBtn.accent:SetPoint("TOPLEFT", frame.specPickerBtn, "TOPLEFT", 4, -4)
    frame.specPickerBtn.accent:SetPoint("BOTTOMLEFT", frame.specPickerBtn, "BOTTOMLEFT", 4, 4)
    frame.specPickerBtn.accent:SetColorTexture(0.34, 0.76, 1.00, 0.85)
    frame.specPickerBtn.icon = frame.specPickerBtn:CreateTexture(nil, "ARTWORK")
    frame.specPickerBtn.icon:SetSize(14, 14)
    frame.specPickerBtn.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    frame.specPickerBtn.icon:SetPoint("LEFT", frame.specPickerBtn, "LEFT", 10, 0)
    frame.specPickerBtn.label = frame.specPickerBtn:CreateFontString(nil, "OVERLAY")
    frame.specPickerBtn.label:SetFont(FONT_PATH, 9, FONT_FLAGS)
    frame.specPickerBtn.label:SetPoint("LEFT", frame.specPickerBtn.icon, "RIGHT", 6, 0)
    frame.specPickerBtn.label:SetPoint("RIGHT", frame.specPickerBtn, "RIGHT", -18, 0)
    frame.specPickerBtn.label:SetJustifyH("LEFT")
    frame.specPickerBtn.label:SetTextColor(0.82, 0.84, 0.94, 1)
    frame.specPickerBtn.arrow = frame.specPickerBtn:CreateFontString(nil, "OVERLAY")
    frame.specPickerBtn.arrow:SetFont(FONT_PATH, 9, FONT_FLAGS)
    frame.specPickerBtn.arrow:SetPoint("RIGHT", frame.specPickerBtn, "RIGHT", -6, 0)
    frame.specPickerBtn.arrow:SetText("v")
    frame.specPickerBtn.arrow:SetTextColor(0.78, 0.80, 0.92, 1)
    frame.specPickerBtn:SetScript("OnEnter", function(self2)
        GameTooltip:SetOwner(self2, "ANCHOR_BOTTOM")
        GameTooltip:SetText(ns.L("bis_all_specs"), 1, 1, 1, 1, true)
        GameTooltip:AddLine(ns.L("bis_all_specs_hint"), 0.70, 0.78, 0.90, true)
        GameTooltip:Show()
    end)
    frame.specPickerBtn:SetScript("OnLeave", function()
        if not (frame.specPicker and frame.specPicker:IsShown()) then
            GameTooltip:Hide()
        end
    end)

    frame.sourceButtons = {}
    local previousSourceButton = nil
    for _, sourceType in ipairs(BIS_SOURCE_ORDER) do
        local button = CreateFrame("Button", nil, frame.tabsFrame, "BackdropTemplate")
        button:SetSize(FILTER_BTN_W, FILTER_BTN_H)
        if previousSourceButton then
            button:SetPoint("RIGHT", previousSourceButton, "LEFT", -2, 0)
        else
            button:SetPoint("RIGHT", frame.specPickerBtn, "LEFT", -4, 0)
        end
        if button.SetBackdrop then
            button:SetBackdrop({
                bgFile   = "Interface\\Tooltips\\UI-Tooltip-Background",
                edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
                tile = true, tileSize = 8, edgeSize = 8,
                insets = { left = 2, right = 2, top = 2, bottom = 2 },
            })
        end
        button.fill = button:CreateTexture(nil, "BACKGROUND")
        button.fill:SetPoint("TOPLEFT", button, "TOPLEFT", 3, -3)
        button.fill:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -3, 3)
        button.checkBox = CreateFrame("Frame", nil, button, "BackdropTemplate")
        button.checkBox:SetSize(10, 10)
        button.checkBox:SetPoint("LEFT", button, "LEFT", 5, 0)
        if button.checkBox.SetBackdrop then
            button.checkBox:SetBackdrop({
                bgFile   = "Interface\\Tooltips\\UI-Tooltip-Background",
                edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
                tile = true, tileSize = 8, edgeSize = 8,
                insets = { left = 2, right = 2, top = 2, bottom = 2 },
            })
        end
        button.checkFill = button.checkBox:CreateTexture(nil, "BACKGROUND")
        button.checkFill:SetPoint("TOPLEFT", button.checkBox, "TOPLEFT", 2, -2)
        button.checkFill:SetPoint("BOTTOMRIGHT", button.checkBox, "BOTTOMRIGHT", -2, 2)
        button.checkMark = button.checkBox:CreateFontString(nil, "OVERLAY")
        button.checkMark:SetFont(FONT_PATH, 8, FONT_FLAGS)
        button.checkMark:SetAllPoints()
        button.checkMark:SetJustifyH("CENTER")
        button.checkMark:SetJustifyV("MIDDLE")
        button.label = button:CreateFontString(nil, "OVERLAY")
        button.label:SetFont(FONT_PATH, 8, FONT_FLAGS)
        button.label:SetPoint("LEFT", button.checkBox, "RIGHT", 3, 0)
        button.label:SetPoint("RIGHT", button, "RIGHT", -3, 0)
        button.label:SetJustifyH("LEFT")
        button.label:SetJustifyV("MIDDLE")
        if button.label.SetWordWrap then
            button.label:SetWordWrap(false)
        end
        if button.label.SetMaxLines then
            button.label:SetMaxLines(1)
        end
        button:SetScript("OnClick", function()
            BISOverlay:ToggleSourceFilter(sourceType)
        end)
        frame.sourceButtons[sourceType] = button
        previousSourceButton = button
    end

    frame.specPicker = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    frame.specPicker:SetFrameStrata("TOOLTIP")
    frame.specPicker:SetFrameLevel(frame:GetFrameLevel() + 20)
    frame.specPicker:SetWidth(SPEC_PICKER_W)
    frame.specPicker:SetClampedToScreen(true)
    frame.specPicker:EnableMouse(true)
    frame.specPicker:EnableMouseWheel(true)
    frame.specPicker:Hide()
    frame.specPicker.rows = {}
    frame.specPicker.items = {}
    frame.specPicker.offset = 0
    if frame.specPicker.SetBackdrop then
        frame.specPicker:SetBackdrop({
            bgFile   = "Interface\\Tooltips\\UI-Tooltip-Background",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true, tileSize = 8, edgeSize = 8,
            insets = { left = 2, right = 2, top = 2, bottom = 2 },
        })
        frame.specPicker:SetBackdropColor(0.04, 0.05, 0.10, 0.97)
        frame.specPicker:SetBackdropBorderColor(0.35, 0.42, 0.60, 0.95)
    end
    frame.specPicker:SetScript("OnMouseWheel", function(self2, delta)
        local total = #self2.items
        local visible = math.min(total, SPEC_PICKER_MAX_VISIBLE)
        if total <= visible then return end
        local maxOffset = total - visible
        self2.offset = math.max(0, math.min(maxOffset, self2.offset - delta))
        BISOverlay:RefreshSpecPickerRows()
    end)

    -- ─── 구분선 2 ───────────────────────────────────────────
    local sep2 = frame:CreateTexture(nil, "ARTWORK")
    sep2:SetHeight(1)
    sep2:SetPoint("TOPLEFT",  frame, "TOPLEFT",  PADDING,  -(TITLE_H + 12 + TABS_H + 4))
    sep2:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -PADDING, -(TITLE_H + 12 + TABS_H + 4))
    sep2:SetColorTexture(0.45, 0.35, 0.70, 0.45)

    -- ─── 스크롤 프레임 ──────────────────────────────────────
    frame.scrollFrame = CreateFrame("ScrollFrame", nil, frame)
    frame.scrollFrame:SetPoint("TOPLEFT",     frame, "TOPLEFT",
        PADDING, -HEADER_H)
    frame.scrollFrame:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT",
        -(PADDING + SB_W + SB_GAP), PADDING)
    frame.scrollFrame:EnableMouseWheel(true)
    frame.scrollFrame:SetScript("OnMouseWheel", function(sf, delta)
        local cur = sf:GetVerticalScroll()
        local max = sf:GetVerticalScrollRange()
        sf:SetVerticalScroll(math.max(0, math.min(max, cur - delta * 24)))
        self:UpdateScrollThumb()
    end)
    frame.scrollFrame:SetScript("OnScrollRangeChanged", function()
        self:UpdateScrollThumb()
    end)

    -- ─── 스크롤 자식 ────────────────────────────────────────
    frame.content = CreateFrame("Frame", nil, frame.scrollFrame)
    frame.content:SetSize(CONTENT_W, 1)
    frame.scrollFrame:SetScrollChild(frame.content)

    -- ─── 커스텀 스크롤바 트랙 ───────────────────────────────
    frame.scrollBarTrack = frame:CreateTexture(nil, "ARTWORK")
    frame.scrollBarTrack:SetWidth(SB_W)
    frame.scrollBarTrack:SetPoint("TOPRIGHT",    frame, "TOPRIGHT",    -PADDING, -HEADER_H)
    frame.scrollBarTrack:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -PADDING,  PADDING)
    frame.scrollBarTrack:SetColorTexture(0.05, 0.05, 0.12, 0.85)

    -- 트랙 좌측 미묘한 하이라이트 선
    local sbEdge = frame:CreateTexture(nil, "ARTWORK")
    sbEdge:SetWidth(1)
    sbEdge:SetPoint("TOPRIGHT",    frame.scrollBarTrack, "TOPLEFT",    0, 0)
    sbEdge:SetPoint("BOTTOMRIGHT", frame.scrollBarTrack, "BOTTOMLEFT", 0, 0)
    sbEdge:SetColorTexture(0.30, 0.20, 0.55, 0.60)

    -- ─── 커스텀 스크롤바 썸 ─────────────────────────────────
    frame.scrollBarThumb = CreateFrame("Frame", nil, frame)
    frame.scrollBarThumb:SetWidth(SB_W)
    frame.scrollBarThumb:SetHeight(40)
    frame.scrollBarThumb:SetPoint("TOPRIGHT", frame.scrollBarTrack, "TOPRIGHT", 0, 0)
    frame.scrollBarThumb:Hide()

    local thumbTex = frame.scrollBarThumb:CreateTexture(nil, "ARTWORK")
    thumbTex:SetAllPoints()
    thumbTex:SetColorTexture(0.55, 0.35, 0.88, 0.88)

    -- 썸 드래그
    local _dragging, _dragY, _dragScroll = false, 0, 0
    frame.scrollBarThumb:EnableMouse(true)
    frame.scrollBarThumb:SetScript("OnMouseDown", function(_, button)
        if button ~= "LeftButton" then return end
        _dragging  = true
        _dragY     = select(2, GetCursorPosition()) / UIParent:GetEffectiveScale()
        _dragScroll = frame.scrollFrame:GetVerticalScroll()
    end)
    frame.scrollBarThumb:SetScript("OnMouseUp", function()
        _dragging = false
    end)
    frame.scrollBarThumb:SetScript("OnUpdate", function()
        if not _dragging then return end
        local curY    = select(2, GetCursorPosition()) / UIParent:GetEffectiveScale()
        local dy      = _dragY - curY
        local trackH  = math.max(1, frame.scrollBarTrack:GetHeight())
        local thumbH  = math.max(1, frame.scrollBarThumb:GetHeight())
        local maxS    = frame.scrollFrame:GetVerticalScrollRange()
        local frac    = dy / (trackH - thumbH)
        local newS    = math.max(0, math.min(maxS, _dragScroll + frac * maxS))
        frame.scrollFrame:SetVerticalScroll(newS)
        self:UpdateScrollThumb()
    end)

    -- GET_ITEM_INFO_RECEIVED 이벤트
    local evFrame = CreateFrame("Frame")
    evFrame:RegisterEvent("GET_ITEM_INFO_RECEIVED")
    evFrame:SetScript("OnEvent", function(_, _, _, success)
        if success then scheduleRebuild() end
    end)

    frame.rows = {}
    self.frame = frame
    return frame
end

-- ============================================================
-- 스펙 탭 생성/업데이트
-- ============================================================

local function ensureSpecPickerRow(frame, index)
    local picker = frame.specPicker
    if picker.rows[index] then return picker.rows[index] end

    local row = CreateFrame("Button", nil, picker)
    row:SetHeight(SPEC_PICKER_ROW_H)
    row:SetPoint("TOPLEFT", picker, "TOPLEFT", 4, -((index - 1) * SPEC_PICKER_ROW_H + 4))
    row:SetPoint("RIGHT", picker, "RIGHT", -4, 0)

    row.bg = row:CreateTexture(nil, "BACKGROUND")
    row.bg:SetAllPoints()
    row.bg:SetColorTexture(0, 0, 0, 0)

    local hl = row:CreateTexture(nil, "HIGHLIGHT")
    hl:SetAllPoints()
    hl:SetColorTexture(1, 1, 1, 0.10)

    row.icon = row:CreateTexture(nil, "ARTWORK")
    row.icon:SetSize(15, 15)
    row.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    row.icon:SetPoint("LEFT", row, "LEFT", 4, 0)

    row.label = row:CreateFontString(nil, "OVERLAY")
    row.label:SetFont(FONT_PATH, 10, FONT_FLAGS)
    row.label:SetPoint("LEFT", row.icon, "RIGHT", 6, 0)
    row.label:SetPoint("RIGHT", row, "RIGHT", -48, 0)
    row.label:SetJustifyH("LEFT")
    row.label:SetTextColor(0.90, 0.92, 1.00, 1)

    row.classLabel = row:CreateFontString(nil, "OVERLAY")
    row.classLabel:SetFont(FONT_PATH, 8, FONT_FLAGS)
    row.classLabel:SetPoint("RIGHT", row, "RIGHT", -5, 0)
    row.classLabel:SetJustifyH("RIGHT")

    row.accent = row:CreateTexture(nil, "ARTWORK")
    row.accent:SetWidth(2)
    row.accent:SetPoint("TOPLEFT", row, "TOPLEFT", 0, 0)
    row.accent:SetPoint("BOTTOMLEFT", row, "BOTTOMLEFT", 0, 0)
    row.accent:SetColorTexture(0, 0, 0, 0)

    picker.rows[index] = row
    return row
end

function BISOverlay:RefreshSpecPickerRows()
    local frame = self.frame
    local picker = frame and frame.specPicker
    if not picker then return end

    local items = picker.items or {}
    local total = #items
    local visible = math.min(total, SPEC_PICKER_MAX_VISIBLE)
    local maxOffset = math.max(0, total - visible)
    picker.offset = math.max(0, math.min(maxOffset, picker.offset or 0))
    picker:SetHeight(visible * SPEC_PICKER_ROW_H + 8)

    local activeID = self.selectedSpecID or getPlayerSpecID()

    for i = 1, visible do
        local row = ensureSpecPickerRow(frame, i)
        local spec = items[picker.offset + i]
        row.specID = spec and spec.specID or nil
        row.label:SetText(spec and (spec.name or "") or "")
        if spec and spec.icon then
            row.icon:SetTexture(spec.icon)
            row.icon:Show()
        else
            row.icon:Hide()
        end
        if spec then
            local cr, cg, cb = getClassColorRGB(spec.classFile)
            row.classLabel:SetText(spec.className or "")
            row.classLabel:SetTextColor(cr, cg, cb, 0.92)
            row.classLabel:Show()
        else
            row.classLabel:SetText("")
            row.classLabel:Hide()
        end

        if spec and spec.specID == activeID then
            row.bg:SetColorTexture(0.18, 0.52, 0.78, 0.28)
            row.accent:SetColorTexture(0.34, 0.76, 1.00, 0.95)
        else
            row.bg:SetColorTexture(0, 0, 0, 0)
            row.accent:SetColorTexture(0, 0, 0, 0)
        end

        row:SetScript("OnClick", function(self2)
            if not self2.specID then return end
            BISOverlay.selectedSpecID = self2.specID
            BISOverlay:UpdateTabHighlight()
            if frame.specPicker then frame.specPicker:Hide() end
            BISOverlay:RebuildContent()
        end)
        row:Show()
    end

    for i = visible + 1, #picker.rows do
        picker.rows[i]:Hide()
    end
end

function BISOverlay:UpdateSpecPickerButton()
    local frame = self.frame
    if not frame or not frame.specPickerBtn then return end

    local playerClassID = getPlayerClassID()
    local activeID = self.selectedSpecID or getPlayerSpecID()
    local activeSpec = getSpecInfo(activeID)
    local showingOtherClass = activeSpec and playerClassID and activeSpec.classID ~= playerClassID

    if showingOtherClass then
        frame.specPickerBtn.label:SetText(formatSpecSelection(activeSpec))
        frame.specPickerBtn.label:SetTextColor(0.38, 0.88, 1.00, 1)
        if frame.specPickerBtn.icon and activeSpec and activeSpec.icon then
            frame.specPickerBtn.icon:SetTexture(activeSpec.icon)
            frame.specPickerBtn.icon:Show()
        end
        if frame.specPickerBtn.SetBackdropBorderColor then
            frame.specPickerBtn:SetBackdropBorderColor(0.26, 0.70, 0.96, 0.95)
        end
        if frame.specPickerBtn.fill then
            frame.specPickerBtn.fill:SetColorTexture(0.09, 0.16, 0.25, 0.94)
        end
    else
        frame.specPickerBtn.label:SetText(ns.L("bis_all_specs"))
        frame.specPickerBtn.label:SetTextColor(0.82, 0.84, 0.94, 1)
        local activePlayerSpec = activeSpec or getSpecInfo(getPlayerSpecID())
        if frame.specPickerBtn.icon and activePlayerSpec and activePlayerSpec.icon then
            frame.specPickerBtn.icon:SetTexture(activePlayerSpec.icon)
            frame.specPickerBtn.icon:Show()
        end
        if frame.specPickerBtn.SetBackdropBorderColor then
            frame.specPickerBtn:SetBackdropBorderColor(0.28, 0.35, 0.52, 0.90)
        end
        if frame.specPickerBtn.fill then
            frame.specPickerBtn.fill:SetColorTexture(0.10, 0.14, 0.23, 0.92)
        end
    end

    if frame.specPicker and frame.specPicker:IsShown() then
        self:RefreshSpecPickerRows()
    end
end

function BISOverlay:ToggleSpecPicker()
    local frame = self.frame
    if not frame or not frame.specPicker or not frame.specPickerBtn then return end

    if frame.specPicker:IsShown() then
        frame.specPicker:Hide()
        return
    end

    frame.specPicker.items = getAllSpecs()
    frame.specPicker:ClearAllPoints()
    frame.specPicker:SetPoint("TOPRIGHT", frame.specPickerBtn, "BOTTOMRIGHT", 0, -4)

    local activeID = self.selectedSpecID or getPlayerSpecID()
    local visible = math.min(#frame.specPicker.items, SPEC_PICKER_MAX_VISIBLE)
    local offset = 0
    for i, spec in ipairs(frame.specPicker.items) do
        if spec.specID == activeID then
            offset = math.max(0, math.min(#frame.specPicker.items - visible, i - 2))
            break
        end
    end
    frame.specPicker.offset = offset
    self:RefreshSpecPickerRows()
    frame.specPicker:Show()
    frame.specPicker:Raise()
end

function BISOverlay:EnsureTabs()
    local frame = self.frame
    if not frame then return end
    local specs = getClassSpecs()
    if #specs == 0 then return end
    if #frame.tabs == #specs then
        self:UpdateTabHighlight()
        self:UpdateSpecPickerButton()
        return
    end

    for _, tab in ipairs(frame.tabs) do tab:Hide() end
    frame.tabs = {}

    for i, spec in ipairs(specs) do
        local tab = CreateFrame("Button", nil, frame.tabsFrame)
        tab:SetSize(TAB_SIZE, TAB_SIZE)
        tab:SetPoint("TOPLEFT", frame.tabsFrame, "TOPLEFT", (i - 1) * (TAB_SIZE + 6), -2)

        -- 아이콘
        tab.icon = tab:CreateTexture(nil, "ARTWORK")
        tab.icon:SetAllPoints()
        if spec.icon then
            tab.icon:SetTexture(spec.icon)
            tab.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
        end

        -- 하단 활성 인디케이터 바 (아이콘 바로 아래 2px 선)
        tab.indicator = tab:CreateTexture(nil, "OVERLAY")
        tab.indicator:SetHeight(2)
        tab.indicator:SetPoint("BOTTOMLEFT",  tab, "BOTTOMLEFT",  0, -3)
        tab.indicator:SetPoint("BOTTOMRIGHT", tab, "BOTTOMRIGHT", 0, -3)
        tab.indicator:SetColorTexture(0, 0, 0, 0)

        -- 마우스 오버 하이라이트
        tab.highlight = tab:CreateTexture(nil, "HIGHLIGHT")
        tab.highlight:SetAllPoints()
        tab.highlight:SetColorTexture(1, 1, 1, 0.12)

        tab.specID   = spec.specID
        tab.specName = spec.name

        tab:SetScript("OnEnter", function(self2)
            GameTooltip:SetOwner(self2, "ANCHOR_BOTTOM")
            GameTooltip:SetText(spec.name, 1, 1, 1, 1, true)
            GameTooltip:Show()
        end)
        tab:SetScript("OnLeave", function() GameTooltip:Hide() end)
        tab:SetScript("OnClick", function()
            BISOverlay.selectedSpecID = spec.specID
            BISOverlay:UpdateTabHighlight()
            BISOverlay:RebuildContent()
        end)

        frame.tabs[i] = tab
    end

    if frame.specPickerBtn then
        frame.specPickerBtn:SetScript("OnClick", function()
            BISOverlay:ToggleSpecPicker()
        end)
    end

    self:UpdateTabHighlight()
    self:UpdateSpecPickerButton()
    self:UpdateSourceFilterButtons()
end

function BISOverlay:UpdateTabHighlight()
    local frame = self.frame
    if not frame then return end
    local activeID = self.selectedSpecID or getPlayerSpecID()
    for _, tab in ipairs(frame.tabs) do
        if tab.specID == activeID then
            tab.icon:SetDesaturated(false)
            tab.icon:SetAlpha(1.0)
            tab.indicator:SetColorTexture(0.20, 0.85, 1.0, 1.0)  -- 밝은 시안
        else
            tab.icon:SetDesaturated(true)
            tab.icon:SetAlpha(0.40)
            tab.indicator:SetColorTexture(0, 0, 0, 0)
        end
    end
    self:UpdateSpecPickerButton()
end

-- ============================================================
-- 행 생성/재사용
-- ============================================================

requestItemData = function(itemID)
    if not itemID or itemID <= 0 then return end
    if C_Item and C_Item.RequestLoadItemDataByID then
        pcall(C_Item.RequestLoadItemDataByID, itemID)
    end
end

local function showSeasonItemTooltip(owner, row)
    if not row or not row.itemID or row.itemID <= 0 then return end

    local entry = row._entry or {}
    local sourceType = getEntrySourceType(entry)
    local sourceLabel = getDisplaySourceLabel(entry)
    local noteKind = row._displayNoteKind or canonicalNote(entry.note)
    local noteIndex = row._displayNoteIndex or 3
    local previewLevel = getSeasonPreviewKeyLevel()
    local fallbackName = select(1, GetItemInfo(row.itemID))
    local previewContext
    if sourceType == "mythicplus" then
        local dungeonName = resolveSeasonDungeonName(entry.dungeon or entry.sourceLabel)
        previewContext = dungeonName and getPreviewMythicPlusLootContext(dungeonName, row.itemID, fallbackName) or nil
    elseif sourceType == "raid" then
        previewContext = getPreviewRaidLootContext(row.itemID, fallbackName)
    end
    local previewLink = previewContext and previewContext.link or nil
    local _, baseTooltipLink, baseQuality = GetItemInfo(row.itemID)
    local previewValidation
    if sourceType == "mythicplus" then
        previewValidation = validatePreviewTooltip(previewContext)
    elseif sourceType == "raid" then
        previewValidation = validateRaidPreviewTooltip(previewContext)
    end
    local tooltipLink = previewLink
    local itemName
    local quality
    if previewLink then
        itemName, _, quality = GetItemInfo(previewLink)
    end
    if not quality then
        itemName = itemName or fallbackName
        tooltipLink = baseTooltipLink
        quality = baseQuality
    end
    tooltipLink = previewLink or tooltipLink
    local scaledMinIlvl, scaledMaxIlvl = getSeasonalMythicPlusRange()

    GameTooltip:SetOwner(owner, "ANCHOR_RIGHT")
    GameTooltip:ClearLines()

    local hasBaseTooltip = false
    local usedBaseTooltipFallback = false

    if (sourceType == "mythicplus" or sourceType == "raid")
    and previewLink and previewValidation and previewValidation.trusted then
        hasBaseTooltip = processEncounterJournalTooltip(GameTooltip, previewLink, true)
        tooltipLink = previewLink
    end

    if not hasBaseTooltip then
        requestItemData(row.itemID)
        if baseTooltipLink and GameTooltip.SetHyperlink then
            local ok = pcall(GameTooltip.SetHyperlink, GameTooltip, baseTooltipLink)
            hasBaseTooltip = ok and true or false
            usedBaseTooltipFallback = hasBaseTooltip
        end
        if not hasBaseTooltip and GameTooltip.SetItemByID then
            local ok = pcall(GameTooltip.SetItemByID, GameTooltip, row.itemID)
            hasBaseTooltip = ok and true or false
            usedBaseTooltipFallback = hasBaseTooltip
        end
        if not hasBaseTooltip then
            local ok, resolvedName, _, fallbackQuality = pcall(GetItemInfo, row.itemID)
            local displayName = itemName or (ok and resolvedName) or ("Item #" .. tostring(row.itemID))
            quality = quality or fallbackQuality
            local qc = getQualityColor(quality)
            GameTooltip:AddLine(displayName, qc[1], qc[2], qc[3], 1)
        end
    else
        local nameFS = _G.GameTooltipTextLeft1
        local qc = getQualityColor(quality)
        if nameFS then
            nameFS:SetTextColor(qc[1], qc[2], qc[3], 1)
        end
    end

    GameTooltip:AddLine(ns.L("bis_tooltip_current_season"), 0.88, 0.70, 1.00, true)
    GameTooltip:AddDoubleLine(ns.L("bis_tooltip_slot"), localizeSlot(entry.slot), 0.70, 0.78, 0.90, 1, 1, 1)
    GameTooltip:AddDoubleLine(ns.L("bis_tooltip_source"), sourceLabel, 0.70, 0.78, 0.90, 1, 1, 1)
    GameTooltip:AddDoubleLine(ns.L("bis_tooltip_basis"), getSourceBasisLabel(sourceType), 0.70, 0.78, 0.90, 1, 1, 1)
    GameTooltip:AddDoubleLine(ns.L("bis_tooltip_rank"), notePlain(noteKind, noteIndex), 0.70, 0.78, 0.90, 1, 1, 1)

    if sourceType == "mythicplus" then
        if previewValidation and previewValidation.trusted then
            GameTooltip:AddLine(ns.L("bis_tooltip_preview_key", previewLevel), 0.38, 0.88, 1.00, true)
        elseif scaledMinIlvl and scaledMaxIlvl then
            GameTooltip:AddLine(ns.L("bis_tooltip_item_level_scaled", scaledMinIlvl, scaledMaxIlvl), 0.38, 0.88, 1.00, true)
            GameTooltip:AddLine(ns.L("bis_tooltip_preview_fallback"), 1.00, 0.72, 0.42, true)
            if usedBaseTooltipFallback then
                GameTooltip:AddLine(ns.L("bis_tooltip_base_item_level_warning"), 1.00, 0.58, 0.30, true)
            end
        end
        local runTrack = getSeasonalMythicPlusSummary("run")
        if runTrack ~= "" then
            GameTooltip:AddDoubleLine(ns.L("bis_tooltip_end_of_run"), runTrack, 0.70, 0.78, 0.90, 0.82, 0.82, 0.92)
        end
        local vaultTrack = getSeasonalMythicPlusSummary("vault")
        if vaultTrack ~= "" then
            GameTooltip:AddDoubleLine(ns.L("bis_tooltip_vault"), vaultTrack, 0.70, 0.78, 0.90, 0.82, 0.82, 0.92)
        end
    elseif sourceType == "raid" then
        if previewValidation and previewValidation.trusted then
            GameTooltip:AddLine(ns.L("bis_tooltip_raid_preview"), 0.38, 0.88, 1.00, true)
        else
            GameTooltip:AddLine(ns.L("bis_tooltip_raid_fallback"), 1.00, 0.72, 0.42, true)
            if usedBaseTooltipFallback then
                GameTooltip:AddLine(ns.L("bis_tooltip_base_item_level_warning"), 1.00, 0.58, 0.30, true)
            end
        end
        for _, line in ipairs(getSeasonalRaidSummaryLines()) do
            GameTooltip:AddDoubleLine(line.label, line.text, 0.70, 0.78, 0.90, 0.82, 0.82, 0.92)
        end
    elseif sourceType == "crafted" then
        GameTooltip:AddLine(ns.L("bis_tooltip_crafted_fallback"), 1.00, 0.72, 0.42, true)
        for _, line in ipairs(getSeasonalCraftedSummaryLines()) do
            GameTooltip:AddDoubleLine(line.label, line.text, 0.70, 0.78, 0.90, 0.82, 0.82, 0.92)
        end
    end

    local canOpenJournal = false
    if sourceType ~= "crafted" then
        canOpenJournal = (previewContext and previewContext.instanceID) and true or false
        if not canOpenJournal and sourceType == "mythicplus" then
            canOpenJournal = getDungeonInstanceID(resolveSeasonDungeonName(entry.dungeon or entry.sourceLabel)) and true or false
        end
    end
    if canOpenJournal then
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine(ns.L("bis_tooltip_open_journal"), 0.35, 0.85, 1.00, true)
    end
    GameTooltip:Show()
end

local function isCursorOverSourceColumn(button)
    if not button or not button.GetLeft or not button.GetEffectiveScale then
        return false
    end
    local left = button:GetLeft()
    if not left then
        return false
    end
    local scale = button:GetEffectiveScale() or 1
    local cursorX = select(1, GetCursorPosition()) / scale
    local localX = cursorX - left
    local sourceLeft = COL_ICON + COL_NAME
    local sourceRight = sourceLeft + COL_SLOT
    return localX >= sourceLeft and localX <= sourceRight
end

local function ensureRow(frame, index)
    if frame.rows[index] then return frame.rows[index] end

    local row = CreateFrame("Frame", nil, frame.content)
    row:SetHeight(ROW_H)

    row.bg = row:CreateTexture(nil, "BACKGROUND")
    row.bg:SetAllPoints()
    row.bg:SetColorTexture(0, 0, 0, 0)

    row.accent = row:CreateTexture(nil, "ARTWORK")
    row.accent:SetWidth(3)
    row.accent:SetPoint("TOPLEFT",    row, "TOPLEFT",    0, 0)
    row.accent:SetPoint("BOTTOMLEFT", row, "BOTTOMLEFT", 0, 0)
    row.accent:SetColorTexture(0, 0, 0, 0)

    row.icon = row:CreateTexture(nil, "ARTWORK")
    row.icon:SetSize(ICON_SIZE, ICON_SIZE)
    row.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    row.icon:Hide()

    row.nameLabel = row:CreateFontString(nil, "OVERLAY")
    row.nameLabel:SetFont(FONT_PATH, 11, FONT_FLAGS)
    row.nameLabel:SetJustifyH("LEFT")
    row.nameLabel:SetJustifyV("MIDDLE")
    row.nameLabel:SetPoint("TOPLEFT", row, "TOPLEFT", 0, -1)
    row.nameLabel:SetWidth(COL_NAME + COL_ICON)
    if row.nameLabel.SetWordWrap then
        row.nameLabel:SetWordWrap(false)
    end
    if row.nameLabel.SetMaxLines then
        row.nameLabel:SetMaxLines(1)
    end

    row.slotLabel = row:CreateFontString(nil, "OVERLAY")
    row.slotLabel:SetFont(FONT_PATH, 10, FONT_FLAGS)
    row.slotLabel:SetJustifyH("LEFT")
    row.slotLabel:SetJustifyV("MIDDLE")
    row.slotLabel:SetWidth(COL_SLOT)
    if row.slotLabel.SetWordWrap then
        row.slotLabel:SetWordWrap(false)
    end
    if row.slotLabel.SetMaxLines then
        row.slotLabel:SetMaxLines(1)
    end
    row.slotLabel:Hide()

    row.noteLabel = row:CreateFontString(nil, "OVERLAY")
    row.noteLabel:SetFont(FONT_PATH, 10, FONT_FLAGS)
    row.noteLabel:SetJustifyH("CENTER")
    row.noteLabel:SetJustifyV("MIDDLE")
    row.noteLabel:SetWidth(COL_NOTE)
    row.noteLabel:Hide()

    row.typeLabel = row:CreateFontString(nil, "OVERLAY")
    row.typeLabel:SetFont(FONT_PATH, 9, FONT_FLAGS)
    row.typeLabel:SetJustifyH("CENTER")
    row.typeLabel:SetJustifyV("MIDDLE")
    row.typeLabel:SetWidth(COL_TYPE)
    row.typeLabel:Hide()

    row.tooltipRegion = CreateFrame("Button", nil, row)
    row.tooltipRegion:SetAllPoints(row)
    row.tooltipRegion:EnableMouse(true)
    row.tooltipRegion:RegisterForClicks("LeftButtonUp")
    row.tooltipRegion:SetScript("OnClick", function(self2)
        if row._sectionDungeon then
            openEncounterJournalForEntry({ dungeon = row._sectionDungeon, sourceType = "mythicplus" })
        elseif row._entry then
            if isCursorOverSourceColumn(self2) then
                openEncounterJournalForEntry(row._entry, nil)
            else
                openEncounterJournalForEntry(row._entry, row.itemID)
            end
        end
    end)
    row.tooltipRegion:SetScript("OnEnter", nil)
    row.tooltipRegion:SetScript("OnLeave", function() GameTooltip:Hide() end)

    frame.rows[index] = row
    return row
end

local function resetRow(row)
    row.bg:SetColorTexture(0, 0, 0, 0)
    row.accent:SetColorTexture(0, 0, 0, 0)
    row.icon:Hide()
    row.slotLabel:Hide()
    row.noteLabel:Hide()
    row.typeLabel:Hide()
    row.itemID = nil
    row._entry = nil
    row._sectionDungeon = nil
    row._displayNoteKind = nil
    row._displayNoteIndex = nil
end

function BISOverlay:RefreshVisibleItemRows()
    local frame = self.frame
    if not frame or not frame.rows then
        return false
    end

    local refreshed = false
    for _, row in ipairs(frame.rows) do
        if row:IsShown() and row.itemID and row.itemID > 0 then
            refreshed = refreshItemRowDisplay(row) or refreshed
        end
    end

    return refreshed
end

-- ============================================================
-- 컨텐츠 빌드
-- ============================================================

function BISOverlay:RebuildContent()
    local frame = self.frame
    if not frame then return end

    -- 스크롤 위치 저장 (아이템 로드 재빌드일 때 복원용)
    local isItemLoadRebuild = self._isItemLoadRebuild
    self._isItemLoadRebuild = false
    local savedScroll = frame.scrollFrame:GetVerticalScroll()

    local specID  = self.selectedSpecID or getPlayerSpecID()
    self._lastRenderSignature = getRenderSignature(specID)
    local bisData = ns.Data and ns.Data.BISItems and ns.Data.BISItems[specID]
    local avgIlvl = getAverageItemLevel()
    if frame.titleText then
        frame.titleText:SetText(ns.L("bis_overlay_title"))
    end
    if frame.hintText then
        frame.hintText:SetText(ns.L("bis_overlay_hint"))
    end
    if frame.noticeText then
        frame.noticeText:SetText(ns.L("bis_overlay_notice"))
    end
    if frame.avgLabel then
        frame.avgLabel:SetText(ns.L("bis_overlay_avg_label", avgIlvl > 0 and tostring(avgIlvl) or "?"))
    end
    self:UpdateSourceFilterButtons()

    ns.Utils.Debug(string.format("[BISOverlay] specID=%s bisData=%s",
        tostring(specID), bisData and (#bisData .. "개") or "nil"))

    for _, row in ipairs(frame.rows) do
        row:Hide()
        resetRow(row)
    end

    local yOffset  = 0
    local rowIndex = 0

    local filteredData = {}
    if bisData then
        for _, entry in ipairs(bisData) do
            if isSourceEnabled(getEntrySourceType(entry)) then
                filteredData[#filteredData + 1] = entry
            end
        end
    end

    if not filteredData or #filteredData == 0 then
        rowIndex = rowIndex + 1
        local row = ensureRow(frame, rowIndex)
        row:ClearAllPoints()
        row:SetPoint("TOPLEFT", frame.content, "TOPLEFT", 0, -yOffset)
        row:SetWidth(CONTENT_W)
        row:SetHeight(ROW_H + 4)
        row.nameLabel:ClearAllPoints()
        row.nameLabel:SetPoint("LEFT", row, "LEFT", 4, 0)
        row.nameLabel:SetWidth(CONTENT_W - 8)
        row.nameLabel:SetFont(FONT_PATH, 11, FONT_FLAGS)
        row.nameLabel:SetTextColor(0.45, 0.45, 0.45, 1)
        row.nameLabel:SetText((ns.L("bis_overlay_no_data") or "no data")
            .. "  (spec " .. tostring(specID) .. ")")
        row:Show()
        yOffset = yOffset + ROW_H + 4
    else
        local slots, order = groupBySlot(filteredData)
        local itemRowCount = 0

        for _, slotName in ipairs(order) do
            rowIndex = rowIndex + 1
            local hdr = ensureRow(frame, rowIndex)
            hdr:ClearAllPoints()
            hdr:SetPoint("TOPLEFT", frame.content, "TOPLEFT", 0, -yOffset)
            hdr:SetWidth(CONTENT_W)
            hdr:SetHeight(SECTION_H)
            hdr.bg:SetColorTexture(0.08, 0.11, 0.20, 0.88)
            hdr.accent:SetColorTexture(0.25, 0.70, 1.0, 1.0)
            hdr.nameLabel:ClearAllPoints()
            hdr.nameLabel:SetPoint("LEFT", hdr, "LEFT", 8, 0)
            hdr.nameLabel:SetWidth(CONTENT_W - 12)
            hdr.nameLabel:SetFont(FONT_PATH, 12, FONT_FLAGS)
            hdr.nameLabel:SetTextColor(0.55, 0.88, 1.0, 1)
            hdr.nameLabel:SetText(localizeSlot(slotName))
            hdr._sectionDungeon = nil
            hdr:Show()
            yOffset = yOffset + SECTION_H + 1

            local items = slots[slotName]

            for _, entry in ipairs(items) do
                rowIndex = rowIndex + 1
                itemRowCount = itemRowCount + 1
                local iRow = ensureRow(frame, rowIndex)
                iRow:ClearAllPoints()
                iRow:SetPoint("TOPLEFT", frame.content, "TOPLEFT", ITEM_INDENT, -yOffset)
                iRow:SetWidth(ITEM_W)
                iRow:SetHeight(ROW_H)
                iRow.itemID = entry.itemID
                iRow._entry = entry
                iRow._displayNoteKind = entry._displayNoteKind
                iRow._displayNoteIndex = entry._displayNoteIndex

                -- 교번 배경
                if itemRowCount % 2 == 0 then
                    iRow.bg:SetColorTexture(0.06, 0.08, 0.14, 0.55)
                else
                    iRow.bg:SetColorTexture(0.04, 0.05, 0.10, 0.28)
                end

                -- 아이템 이름/아이콘은 부분 갱신 가능하도록 별도 처리
                refreshItemRowDisplay(iRow)

                -- 출처 라벨
                local sourceLabel = getDisplaySourceLabel(entry)
                if sourceLabel and sourceLabel ~= "" then
                    iRow.slotLabel:ClearAllPoints()
                    iRow.slotLabel:SetPoint("LEFT", iRow, "LEFT", COL_ICON + COL_NAME, 0)
                    iRow.slotLabel:SetWidth(COL_SLOT)
                    iRow.slotLabel:SetFont(FONT_PATH, 10, FONT_FLAGS)
                    iRow.slotLabel:SetTextColor(0.72, 0.72, 0.72, 1)
                    iRow.slotLabel:SetText(sourceLabel)
                    iRow.slotLabel:Show()
                end

                local sourceType = getEntrySourceType(entry)
                local sr, sg, sb = getSourceTypeColor(sourceType)
                iRow.typeLabel:ClearAllPoints()
                iRow.typeLabel:SetPoint("LEFT", iRow, "LEFT", COL_ICON + COL_NAME + COL_SLOT, 0)
                iRow.typeLabel:SetWidth(COL_TYPE)
                iRow.typeLabel:SetFont(FONT_PATH, 9, FONT_FLAGS)
                iRow.typeLabel:SetTextColor(sr, sg, sb, 1)
                iRow.typeLabel:SetText(localizeSourceType(sourceType))
                iRow.typeLabel:Show()

                -- note 배지
                local noteTxt = noteBadge(entry._displayNoteKind, entry._displayNoteIndex)
                if noteTxt and noteTxt ~= "" then
                    iRow.noteLabel:ClearAllPoints()
                    iRow.noteLabel:SetPoint("LEFT", iRow, "LEFT",
                        COL_ICON + COL_NAME + COL_SLOT + COL_TYPE, 0)
                    iRow.noteLabel:SetWidth(COL_NOTE)
                    iRow.noteLabel:SetFont(FONT_PATH, 10, FONT_FLAGS)
                    iRow.noteLabel:SetTextColor(1, 1, 1, 1)
                    iRow.noteLabel:SetText(noteTxt)
                    iRow.noteLabel:Show()
                end

                iRow:Show()
                yOffset = yOffset + ROW_H + 1
            end

            yOffset = yOffset + 6
        end
    end

    -- 높이 갱신
    frame.content:SetHeight(math.max(1, yOffset))
    local visH   = math.min(MAX_SCROLL_H, yOffset)
    local totalH = HEADER_H + math.max(20, visH) + PADDING
    frame:SetHeight(totalH)

    -- 스크롤 복원(아이템 로드) 또는 초기화(스펙 변경), 썸 업데이트 (레이아웃 확정 후)
    C_Timer.After(0, function()
        if isItemLoadRebuild and savedScroll > 0 then
            local maxScroll = frame.scrollFrame:GetVerticalScrollRange()
            frame.scrollFrame:SetVerticalScroll(math.min(savedScroll, maxScroll))
        else
            frame.scrollFrame:SetVerticalScroll(0)
        end
        self:UpdateScrollThumb()
    end)
end

-- ============================================================
-- Refresh
-- ============================================================

function BISOverlay:Refresh()
    if not ns.DB or not ns.DB:IsBISOverlayEnabled() then
        if self.frame then self.frame:Hide() end
        return
    end

    local pve = PVEFrame or LFGParentFrame
    if not pve or not pve:IsShown() then
        if self.frame then self.frame:Hide() end
        return
    end

    self:EnsureFrame()
    if not self.frame then return end

    self:EnsureTabs()
    self:UpdateSourceFilterButtons()
    self:UpdateSpecPickerButton()

    -- 앵커 대상이 바뀌었을 때만 ClearAllPoints/SetPoint 호출 (깜박임 방지)
    local ilFrame = ns.UI.ItemLevelOverlay and ns.UI.ItemLevelOverlay.frame
    local anchorTarget = (ilFrame and ilFrame:IsShown()) and ilFrame or pve
    if self._lastAnchorTarget ~= anchorTarget then
        self._lastAnchorTarget = anchorTarget
        self.frame:ClearAllPoints()
        if anchorTarget == ilFrame then
            self.frame:SetPoint("TOPLEFT", ilFrame, "TOPRIGHT", 6, 0)
        else
            self.frame:SetPoint("TOPLEFT", pve, "TOPRIGHT", 10, 0)
        end
    end

    local specID = self.selectedSpecID or getPlayerSpecID()
    local renderSignature = getRenderSignature(specID)
    if self.frame:IsShown() and self._lastRenderSignature == renderSignature then
        if self.frame.titleText then
            self.frame.titleText:SetText(ns.L("bis_overlay_title"))
        end
        if self.frame.hintText then
            self.frame.hintText:SetText(ns.L("bis_overlay_hint"))
        end
        if self.frame.noticeText then
            self.frame.noticeText:SetText(ns.L("bis_overlay_notice"))
        end
        if self.frame.avgLabel then
            local avgIlvl = getAverageItemLevel()
            self.frame.avgLabel:SetText(ns.L("bis_overlay_avg_label", avgIlvl > 0 and tostring(avgIlvl) or "?"))
        end
        self:RefreshVisibleItemRows()
        self:UpdateScrollThumb()
        self.frame:Show()
        return
    end

    local ok, err = pcall(function() self:RebuildContent() end)
    if not ok then
        ns.Utils.Debug("[BISOverlay] RebuildContent 오류: " .. tostring(err))
    end
    self.frame:Show()
end

-- ============================================================
-- Initialize
-- ============================================================

function BISOverlay:Initialize()
    if self._initialized then return end
    self._initialized = true

    local function setupPVEHooks()
        local pve = PVEFrame or LFGParentFrame
        if not pve then return false end

        pve:HookScript("OnShow", function()
            if not ns.DB or not ns.DB:IsBISOverlayEnabled() then return end
            self:Refresh()
        end)
        pve:HookScript("OnHide", function()
            if self.frame then self.frame:Hide() end
        end)

        if pve:IsShown() and ns.DB and ns.DB:IsBISOverlayEnabled() then
            self:Refresh()
        end
        return true
    end

    if not setupPVEHooks() then
        local watchFrame = CreateFrame("Frame")
        watchFrame:RegisterEvent("ADDON_LOADED")
        watchFrame:SetScript("OnEvent", function(f, _, name)
            if name == "Blizzard_LookingForGroup" then
                setupPVEHooks()
                f:UnregisterEvent("ADDON_LOADED")
                f:SetScript("OnEvent", nil)
            end
        end)
    end
end
