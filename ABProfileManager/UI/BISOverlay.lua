local _, ns = ...

local BISOverlay = {}
ns.UI.BISOverlay = BISOverlay

-- ============================================================
-- 레이아웃 상수
-- ============================================================

local FRAME_W      = 560
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
local SHARED_BIS_LIMIT_BY_SLOT = {
    ["반지"] = 2,
    ["장신구"] = 2,
}

-- 커스텀 스크롤바 치수
local SB_W   = 7    -- 스크롤바 폭
local SB_GAP = 5    -- 스크롤바와 컨텐츠 사이 간격

-- 헤더 총 높이
local HEADER_H  = TITLE_H + 8 + TABS_H + 12

-- 컨텐츠 폭: 스크롤바(+갭+오른쪽 패딩) 제외
local CONTENT_W = FRAME_W - PADDING - (PADDING + SB_W + SB_GAP)  -- = 536

-- 아이템 행 컬럼 레이아웃
local ITEM_INDENT = 1
local ITEM_W      = CONTENT_W - ITEM_INDENT
local CHECK_SIZE  = 14
local COL_FAVORITE = 16
local COL_OWNED    = 16
local COL_CONTROLS = COL_FAVORITE + COL_OWNED
local COL_ICON    = ICON_SIZE + 5
local COL_NAME    = 198
local COL_SLOT    = 145
local COL_TYPE    = 90
local COL_NOTE    = 42
local SPEC_PICKER_W = 162
local SPEC_PICKER_BTN_H = 22
local SPEC_PICKER_ROW_H = 20
local SPEC_PICKER_MAX_VISIBLE = 12
local FILTER_BTN_W = 44
local FILTER_BTN_H = 18
local TITLE_TOGGLE_W = 56
local TITLE_TOGGLE_H = 18
local SCROLL_TOOLTIP_SUPPRESS_SECONDS = 0.20

local BIS_SOURCE_ORDER = { "mythicplus", "raid", "crafted", "tier" }
-- table.sort 보조 — sourceGroup → 정렬 우선순위 (낮을수록 먼저)
local SOURCE_GROUP_ORDER = {
    mythicplus = 1,
    raid       = 2,
    tier       = 3,
    crafted    = 4,
}
local BIS_SOURCE_DEFAULTS = {
    mythicplus = true,
    raid = true,
    crafted = true,
    tier = true,
}
local BIS_SOURCE_LABEL_KEYS = {
    mythicplus = "bis_source_mplus",
    raid = "bis_source_raid",
    crafted = "bis_source_crafted",
    tier = "bis_source_tier",
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
local QUALITY_COLOR_CACHE = {}

local function getSeasonDisplayQuality(itemQuality)
    -- 시즌 M+ 드랍은 구던 원본 품질이 파템이어도 최소 에픽으로 보정해서 보여준다.
    local ok, quality = pcall(function()
        return math.max(tonumber(itemQuality) or 4, 4)
    end)
    return ok and quality or 4
end

local function getQualityColor(itemQuality)
    local effectiveQ = getSeasonDisplayQuality(itemQuality)
    if not QUALITY_COLOR_CACHE[effectiveQ] then
        local fallback = QC[effectiveQ] or QC[4]
        local color = ITEM_QUALITY_COLORS and ITEM_QUALITY_COLORS[effectiveQ]
        local r, g, b = color and color.r, color and color.g, color and color.b
        if C_Item and type(C_Item.GetItemQualityColor) == "function" then
            local ok, apiR, apiG, apiB = pcall(C_Item.GetItemQualityColor, effectiveQ)
            if ok and apiR and apiG and apiB then
                r, g, b = apiR, apiG, apiB
            end
        end
        QUALITY_COLOR_CACHE[effectiveQ] = { r or fallback[1], g or fallback[2], b or fallback[3] }
    end
    return QUALITY_COLOR_CACHE[effectiveQ], effectiveQ
end

local function getBISTooltip()
    if BISOverlay._hoverTooltip then
        return BISOverlay._hoverTooltip
    end
    if not CreateFrame or not UIParent then
        return nil
    end

    local tooltip = CreateFrame("GameTooltip", "ABProfileManagerBISTooltip", UIParent, "GameTooltipTemplate")
    tooltip:SetFrameStrata("TOOLTIP")
    BISOverlay._hoverTooltip = tooltip
    return tooltip
end

local function hideBISTooltip()
    local tooltip = BISOverlay and BISOverlay._hoverTooltip
    if tooltip and tooltip.Hide then
        tooltip:Hide()
    end
end

local function markScrollActivity()
    local now = type(GetTime) == "function" and GetTime() or 0
    BISOverlay._tooltipSuppressedUntil = now + SCROLL_TOOLTIP_SUPPRESS_SECONDS
    hideBISTooltip()
    if ns.UI and ns.UI.Widgets and ns.UI.Widgets.HideTooltip then
        ns.UI.Widgets.HideTooltip()
    end
end

local function isScrollTooltipSuppressed()
    local now = type(GetTime) == "function" and GetTime() or 0
    return now < (BISOverlay._tooltipSuppressedUntil or 0)
end

local function safeTooltipString(value)
    if value == nil then
        return nil
    end

    local ok, text = pcall(string.format, "%s", value)
    if not ok or type(text) ~= "string" or text == "" then
        return nil
    end
    return text
end

local function getTooltipDataField(data, key)
    if type(data) ~= "table" then
        return nil, false
    end

    local ok, value = pcall(function()
        return data[key]
    end)
    if not ok then
        return nil, true
    end
    return value, false
end

local function tooltipLineHasField(line, key)
    local value, blocked = getTooltipDataField(line, key)
    if blocked then
        return true
    end

    local ok, hasValue = pcall(function()
        return value ~= nil
    end)
    return (not ok) or hasValue
end

local function isTooltipMoneyLine(line)
    if type(line) ~= "table" then
        return true
    end

    local lineType, blocked = getTooltipDataField(line, "type")
    if blocked then
        return true
    end

    local sellPriceType = Enum
        and Enum.TooltipDataLineType
        and Enum.TooltipDataLineType.SellPrice
        or nil
    if sellPriceType ~= nil then
        local ok, isSellPrice = pcall(function()
            return lineType == sellPriceType
        end)
        if not ok or isSellPrice then
            return true
        end
    end

    for _, key in ipairs({ "price", "money", "coinage", "currencyID" }) do
        if tooltipLineHasField(line, key) then
            return true
        end
    end

    local leftText = safeTooltipString(getTooltipDataField(line, "leftText"))
        or safeTooltipString(getTooltipDataField(line, "text"))
    local sellPriceLabel = type(SELL_PRICE) == "string" and SELL_PRICE or nil
    return leftText == "Sell Price" or leftText == "판매 가격" or (sellPriceLabel and leftText == sellPriceLabel) or false
end

local function safePlainNumber(value)
    local ok, numeric = pcall(tonumber, value)
    if not ok or numeric == nil then
        return nil
    end
    local arithmeticOK, plain = pcall(function()
        return numeric + 0
    end)
    return arithmeticOK and plain or nil
end

local function getTooltipLineColor(line, key, fallbackR, fallbackG, fallbackB)
    local color = getTooltipDataField(line, key)
    if type(color) ~= "table" then
        return fallbackR, fallbackG, fallbackB
    end
    if type(color.GetRGB) == "function" then
        local ok, r, g, b = pcall(color.GetRGB, color)
        if ok and r and g and b then
            return r, g, b
        end
    end
    local ok, r, g, b = pcall(function()
        return color.r, color.g, color.b
    end)
    if ok and r and g and b then
        return r, g, b
    end
    return fallbackR, fallbackG, fallbackB
end

local function renderTooltipDataWithoutMoney(tooltip, tooltipData, itemQuality)
    local lines = getTooltipDataField(tooltipData, "lines")
    if not tooltip or type(tooltipData) ~= "table" or type(lines) ~= "table" then
        return false
    end

    tooltip:ClearLines()
    local qc = getQualityColor(itemQuality)
    local rendered = 0

    for _, line in ipairs(lines) do
        if type(line) == "table" and not isTooltipMoneyLine(line) then
            local leftText = safeTooltipString(getTooltipDataField(line, "leftText"))
                or safeTooltipString(getTooltipDataField(line, "text"))
            local rightText = safeTooltipString(getTooltipDataField(line, "rightText"))
            if leftText or rightText then
                rendered = rendered + 1
                local fallbackR = rendered == 1 and qc[1] or 0.90
                local fallbackG = rendered == 1 and qc[2] or 0.90
                local fallbackB = rendered == 1 and qc[3] or 0.90
                local leftR, leftG, leftB = getTooltipLineColor(line, "leftColor", fallbackR, fallbackG, fallbackB)
                if rightText and tooltip.AddDoubleLine then
                    local rightR, rightG, rightB = getTooltipLineColor(line, "rightColor", 0.90, 0.90, 0.90)
                    pcall(tooltip.AddDoubleLine, tooltip, leftText or " ", rightText, leftR, leftG, leftB, rightR, rightG, rightB)
                else
                    pcall(tooltip.AddLine, tooltip, leftText or rightText or " ", leftR, leftG, leftB, true)
                end
            end
        end
    end

    return rendered > 0 and tooltip:NumLines() > 0
end

local function renderTooltipSnapshot(tooltip, snapshot, itemQuality)
    local lines = type(snapshot) == "table" and snapshot.lines or nil
    if not tooltip or type(lines) ~= "table" then
        return false
    end

    tooltip:ClearLines()
    local qc = getQualityColor(itemQuality)
    local rendered = 0
    for _, line in ipairs(lines) do
        if type(line) == "table" then
            local leftText = safeTooltipString(line.leftText)
            local rightText = safeTooltipString(line.rightText)
            if leftText or rightText then
                rendered = rendered + 1
                local fallback = rendered == 1 and qc or { 0.90, 0.90, 0.90 }
                local left = type(line.leftColor) == "table" and line.leftColor or fallback
                local right = type(line.rightColor) == "table" and line.rightColor or { 0.90, 0.90, 0.90 }
                if rightText and tooltip.AddDoubleLine then
                    pcall(
                        tooltip.AddDoubleLine,
                        tooltip,
                        leftText or " ",
                        rightText,
                        safePlainNumber(left[1]) or fallback[1],
                        safePlainNumber(left[2]) or fallback[2],
                        safePlainNumber(left[3]) or fallback[3],
                        safePlainNumber(right[1]) or 0.90,
                        safePlainNumber(right[2]) or 0.90,
                        safePlainNumber(right[3]) or 0.90
                    )
                else
                    pcall(
                        tooltip.AddLine,
                        tooltip,
                        leftText or rightText or " ",
                        safePlainNumber(left[1]) or fallback[1],
                        safePlainNumber(left[2]) or fallback[2],
                        safePlainNumber(left[3]) or fallback[3],
                        true
                    )
                end
            end
        end
    end
    return rendered > 0 and tooltip:NumLines() > 0
end

local FAVORITES_SLOT = "__favorites"
local SLOT_ORDER = {
    "무기", "보조장비", "방패", "머리", "목", "어깨", "망토", "가슴",
    "손목", "손", "허리", "다리", "발", "반지", "장신구",
}

local SLOT_SORT_ORDER = {}
for i, slotName in ipairs(SLOT_ORDER) do
    SLOT_SORT_ORDER[slotName] = i
end

local SLOT_LOCALE_KEYS = {
    [FAVORITES_SLOT] = "bis_slot_favorites",
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
    ["제나스 지점"] = "bis_dungeon_nexus_point_xenas",
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
    tier = { 0.88, 0.58, 1.00 },
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
local EJ_ENCOUNTER_CACHE = {}
local PENDING_ITEM_DATA = {}
local PENDING_ROW_REFRESH_ITEM_IDS = {}
local normalizeCompareText
local getEntrySourceType
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

    return EncounterJournal ~= nil or type(EncounterJournal_OpenJournal) == "function"
end

local function getEnglishLocaleText(key)
    local enUS = ns.Locale and ns.Locale.strings and ns.Locale.strings.enUS
    return enUS and enUS[key] or nil
end

local function isKoreanLanguageSelected()
    return ns.DB and ns.DB.GetLanguage and ns.Constants
        and ns.DB:GetLanguage() == ns.Constants.LANGUAGE.KOREAN
        or false
end

local function getEntryLocalizedName(entry)
    if not entry then
        return nil
    end
    if isKoreanLanguageSelected() then
        return entry.nameKoKR or entry.nameEnUS or nil
    end
    return entry.nameEnUS or entry.nameKoKR or nil
end

local function getEntryIconTexture(entry)
    local icon = entry and entry.icon
    if type(icon) == "number" then
        return icon > 0 and icon or nil
    end
    if type(icon) ~= "string" or icon == "" then
        return nil
    end
    local fileID = tonumber(icon)
    if fileID and fileID > 0 then
        return fileID
    end
    if icon:find("\\", 1, true) or icon:find("/", 1, true) then
        return icon
    end
    return "Interface\\Icons\\" .. icon
end

local function getEntryQuality(entry)
    local quality = entry and tonumber(entry.quality) or nil
    return quality or 4
end

local function getSeasonPreviewKeyLevel()
    return 10
end

local function getMythicPlusVaultPreviewItemLevel(entry)
    local profiles = entry and entry.rewardProfiles
    local profile = profiles and profiles.mplus_great_vault_voidcore
    local itemLevel = profile and tonumber(profile.itemLevel)
    if itemLevel then
        return itemLevel
    end
    local rewardProfiles = ns.Data and ns.Data.BISRewardProfiles
    profile = rewardProfiles and rewardProfiles.mythicplus and rewardProfiles.mythicplus.mplus_great_vault_voidcore
    return profile and tonumber(profile.itemLevel) or 272
end

local function getRaidPreviewDifficultyID()
    if DifficultyUtil and DifficultyUtil.ID then
        return DifficultyUtil.ID.PrimaryRaidHeroic
            or DifficultyUtil.ID.RaidHeroic
            or DifficultyUtil.ID.PrimaryRaidNormal
            or DifficultyUtil.ID.RaidNormal
            or DifficultyUtil.ID.Raid25Heroic
    end
    return 15
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
                    name = ns.SpecL(specID, specName) or specName,
                    icon = icon,
                    classID = classID,
                    className = ns.ClassL(classFile) or className,
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
        local instanceID = dungeonName and DUNGEON_EJ_IDS[dungeonName] or nil
        if not instanceID then
            return {
                difficulty = 23,
            }
        end
        return {
            instanceID = instanceID,
            tier = dungeonName and DUNGEON_EJ_TIERS[dungeonName] or nil,
            difficulty = 23,
            encounterID = findEncounterIDInInstance(instanceID, encounterHints),
        }
    end

    if sourceType == "raid" then
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
    if sourceType == "crafted" or sourceType == "tier" or hasRaidMetaLabel(sourceLabel) then
        return
    end

    local target = resolveFallbackJournalTarget(entry) or {}
    local instanceID = target.instanceID
    local tier = target.tier
    local encounterID = target.encounterID
    local difficultyID = target.difficulty
        or (sourceType == "raid" and getRaidPreviewDifficultyID() or 23)

    pcall(function()
        if not ensureEncounterJournalLoaded() then
            return
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
                pcall(EncounterJournal_OpenJournal, difficultyID, instanceID, encounterID, nil, nil, itemID, tier)
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

local function getOverlayConfig()
    return ns.DB and ns.DB.GetBISOverlayConfig and ns.DB:GetBISOverlayConfig()
        or (ns.Data and ns.Data.Defaults and ns.Data.Defaults.ui and ns.Data.Defaults.ui.bisOverlay)
        or {
            point = "CENTER",
            relativePoint = "CENTER",
            x = 806,
            y = -100,
            scale = 1,
            collapsed = false,
            anchorMode = "itemlevel",
        }
end

local function getOverlayScale()
    return ns.DB and ns.DB.GetBISOverlayScale and ns.DB:GetBISOverlayScale() or _bisScale or 1
end

local function setOverlayScale(frame, delta)
    local oldScale = getOverlayScale()
    local nextScale = oldScale + delta
    if ns.DB and ns.DB.SetBISOverlayScale then
        nextScale = ns.DB:SetBISOverlayScale(nextScale)
    else
        nextScale = math.max(SCALE_MIN, math.min(SCALE_MAX, nextScale))
    end
    _bisScale = nextScale
    if frame and oldScale ~= nextScale then
        local left = frame:GetLeft()
        local top = frame:GetTop()
        if left and top then
            frame:SetScale(nextScale)
            frame:ClearAllPoints()
            frame:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT",
                left * oldScale / nextScale,
                top * oldScale / nextScale)
            local config = getOverlayConfig()
            if config then
                config.anchorMode = "overlay"
            end
            if ns.DB and ns.DB.SaveBISOverlayPosition then
                ns.DB:SaveBISOverlayPosition(frame)
            end
        else
            frame:SetScale(nextScale)
        end
    end
    return nextScale
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
    local stateVersion = ns.DB and ns.DB.GetBISOverlayItemStateVersion
        and ns.DB:GetBISOverlayItemStateVersion(specID)
        or 0
    return table.concat({
        tostring(specID or 0),
        isKoreanLanguageSelected() and "koKR" or "enUS",
        filters.mythicplus and "1" or "0",
        filters.raid and "1" or "0",
        filters.crafted and "1" or "0",
        filters.tier and "1" or "0",
        tostring(stateVersion),
    }, ":")
end

local function isOverlayItemTooltipEnabled()
    return ns.DB and ns.DB.IsBISOverlayItemTooltipEnabled and ns.DB:IsBISOverlayItemTooltipEnabled() or false
end

local function isBISItemOwned(specID, itemID)
    return ns.DB and ns.DB.IsBISOverlayItemOwned and ns.DB:IsBISOverlayItemOwned(specID, itemID) or false
end

local function isBISItemFavorite(specID, itemID)
    return ns.DB and ns.DB.IsBISOverlayItemFavorite and ns.DB:IsBISOverlayItemFavorite(specID, itemID) or false
end

getEntrySourceType = function(entry)
    local sourceType = entry and (entry.sourceGroup or entry.sourceType)
    local sourceLabel = entry and (entry.sourceLabel or entry.dungeon or entry.boss) or nil
    local resolvedDungeon = resolveSeasonDungeonName(entry and entry.dungeon or sourceLabel)

    if sourceType == "tier" then
        return "tier"
    end
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

local STAT_POLICY_EN_REPLACEMENTS = {
    { "치명타 및 극대화", "Critical Strike" },
    { "아이템레벨", "item level" },
    { "치명타", "Critical Strike" },
    { "가속", "Haste" },
    { "특화", "Mastery" },
    { "유연성", "Versatility" },
    { "유연", "Versatility" },
    { "힘", "Strength" },
    { "민첩", "Agility" },
    { "지능", "Intellect" },
    { "우선", "priority" },
    { "균형", "balanced" },
}

local function hasHangul(text)
    return type(text) == "string" and text:find("[가-힣]") ~= nil
end

local function localizeStatPolicyText(text)
    if not text or text == "" then
        return nil
    end
    if isKoreanLanguageSelected() then
        return text
    end

    local localized = tostring(text)
    for _, pair in ipairs(STAT_POLICY_EN_REPLACEMENTS) do
        localized = localized:gsub(pair[1], pair[2])
    end
    localized = localized
        :gsub("·", " / ")
        :gsub(" 및 ", " and ")
        :gsub("이상", "+")
        :gsub("%s+", " ")
        :match("^%s*(.-)%s*$")

    if hasHangul(localized) then
        return ns.L("bis_stat_policy_contextual_summary")
    end
    return localized
end

local function getSpecPolicy(specID)
    return specID and ns.Data and ns.Data.BISSpecPolicies and ns.Data.BISSpecPolicies[specID] or nil
end

local function getSpecPolicySummary(specID)
    local policy = getSpecPolicy(specID)
    local statSummary = localizeStatPolicyText(policy and policy.secondaryPriority)
    if statSummary and statSummary ~= "" then
        return ns.L("bis_overlay_policy_summary", statSummary)
    end
    return ns.L("bis_overlay_policy_summary_empty")
end

local function getEntryTrackStatusLabel(entry)
    local sourceType = getEntrySourceType(entry)
    if sourceType == "mythicplus" then
        return ns.L("bis_track_mplus_myth_baseline", getMythicPlusVaultPreviewItemLevel(entry))
    end
    if sourceType == "tier" then
        return ns.L("bis_status_tier_candidate")
    end
    if sourceType == "raid" then
        return ns.L("bis_status_raid_preserved")
    end
    if sourceType == "crafted" then
        return ns.L("bis_status_crafted_preserved")
    end
    return localizeSourceType(sourceType)
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
        local entry = nil
        if entries then
            for _, candidate in ipairs(entries) do
                if candidate.grade == "hero" then
                    entry = candidate
                    break
                end
            end
            entry = entry or entries[1]
        end
        if entry and entry.key and entry.ilvl then
            return string.format("+%d %d", entry.key, entry.ilvl)
        end
        return ns.L("bis_basis_mplus")
    end
    if sourceType == "raid" then
        local heroic = tbl and tbl.raid and tbl.raid.heroic
        if heroic and heroic.min and heroic.max then
            return string.format("%d~%d", heroic.min, heroic.max)
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
    if sourceType == "tier" then
        return ns.L("bis_basis_tier")
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

    local preferred = isKoreanLanguageSelected() and entry.displaySourceKoKR or entry.displaySourceEnUS
    if preferred and preferred ~= "" then
        return preferred
    end

    local sourceType = getEntrySourceType(entry)
    if sourceType == "mythicplus" then
        local dungeonName = resolveSeasonDungeonName(
            (isKoreanLanguageSelected() and entry.dungeon) or entry.dungeonEnUS or entry.dungeon or entry.sourceLabel
        )
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
    if (not isKoreanLanguageSelected()) and type(localized) == "string" and localized:find("[가-힣]") then
        return entry.displaySourceEnUS or entry.dungeonEnUS or localizeSourceType(sourceType)
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
    [normalizeCompareText("Nexus-Point")] = "제나스 지점",
    [normalizeCompareText("Nexus-Point Xenas")] = "제나스 지점",
    [normalizeCompareText("Nexus-Point Xenas Belo'ren")] = "제나스 지점",
    [normalizeCompareText("공결점 제나스")] = "제나스 지점",
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
    [normalizeCompareText("Imperator Averzian")] = "전제군주 아베르지안",
    [normalizeCompareText("Belo'ren")] = "벨로렌",
    [normalizeCompareText("Belo’ren")] = "벨로렌",
    [normalizeCompareText("Belo’ren (Raid)")] = "벨로렌",
    [normalizeCompareText("Belo'ren, Child of Al'ar")] = "벨로렌",
    [normalizeCompareText("Belo’ren, Child of Al’ar")] = "벨로렌",
    [normalizeCompareText("Vaelgor")] = "바엘고어",
    [normalizeCompareText("Vaelgor & Ezzorak")] = "바엘고어 & 에조라크",
    [normalizeCompareText("Vaelgor & Ezzorak (Raid)")] = "바엘고어 & 에조라크",
    [normalizeCompareText("Vaelgor and Ezzorak")] = "바엘고어 & 에조라크",
    [normalizeCompareText("Vorasius")] = "보라시우스",
    [normalizeCompareText("Chimaerus")] = "카이메루스",
    [normalizeCompareText("Chimaerus (Raid)")] = "카이메루스",
    [normalizeCompareText("Chimaerus the Undreamt God")] = "카이메루스",
    [normalizeCompareText("Chimareus, the Undreamt God")] = "카이메루스",
    [normalizeCompareText("War Chaplain Senn")] = "전투전도사 센",
    [normalizeCompareText("L’ura")] = "꿈의균열",
    [normalizeCompareText("Alleria Windrunner")] = "쿠엘다나스 진격로",
}

local SOURCE_LABEL_ENUS = {
    [normalizeCompareText("제작")] = "Crafting",
    [normalizeCompareText("연금술")] = "Alchemy",
    [normalizeCompareText("대장기술")] = "Blacksmithing",
    [normalizeCompareText("마법부여")] = "Enchanting",
    [normalizeCompareText("기계공학")] = "Engineering",
    [normalizeCompareText("주문각인")] = "Inscription",
    [normalizeCompareText("보석세공")] = "Jewelcrafting",
    [normalizeCompareText("가죽세공")] = "Leatherworking",
    [normalizeCompareText("재봉")] = "Tailoring",
    [normalizeCompareText("촉매")] = "Catalyst",
    [normalizeCompareText("촉매 충전")] = "Catalyst Charge",
    [normalizeCompareText("티어")] = "Tier",
    [normalizeCompareText("티어 세트")] = "Tier Set",
    [normalizeCompareText("티어 아이템")] = "Tier Item",
    [normalizeCompareText("티어 가슴")] = "Tier Chest",
    [normalizeCompareText("티어 장갑")] = "Tier Gloves",
    [normalizeCompareText("티어 머리")] = "Tier Helmet",
    [normalizeCompareText("티어 다리")] = "Tier Legs",
    [normalizeCompareText("촉매 / 티어")] = "Catalyst / Tier",
    [normalizeCompareText("촉매 / 레이드")] = "Catalyst / Raid",
    [normalizeCompareText("촉매 / 레이드 / 금고")] = "Catalyst / Raid / Vault",
    [normalizeCompareText("레이드 / 촉매")] = "Raid / Catalyst",
    [normalizeCompareText("레이드 / 촉매 / 금고")] = "Raid / Catalyst / Vault",
    [normalizeCompareText("한밤 폭포")] = "Midnight Falls",
    [normalizeCompareText("공허 첨탑")] = "The Voidspire",
    [normalizeCompareText("꿈의균열")] = "Dreamrift",
    [normalizeCompareText("공허흉터 투기장")] = "Voidscar Arena",
    [normalizeCompareText("죽음의 골목")] = "Murder Row",
    [normalizeCompareText("날로라크의 소굴")] = "Den of Nalorakk",
    [normalizeCompareText("윈드러너 첨탑")] = "Windrunner Spire",
    [normalizeCompareText("삼두정의 권좌")] = "Seat of the Triumvirate",
    [normalizeCompareText("마법학자의 정원")] = "Magisters' Terrace",
    [normalizeCompareText("마이사라 동굴")] = "Maisara Caverns",
    [normalizeCompareText("제나스 지점")] = "Nexus-Point Xenas",
    [normalizeCompareText("사론의 구덩이")] = "Pit of Saron",
    [normalizeCompareText("알게타르 대학")] = "Algeth'ar Academy",
    [normalizeCompareText("알게타르 아카데미")] = "Algeth'ar Academy",
    [normalizeCompareText("하늘탑")] = "Skyreach",
    [normalizeCompareText("전제군주 아베르지안")] = "Imperator Averzian",
    [normalizeCompareText("벨로렌")] = "Belo'ren",
    [normalizeCompareText("바엘고어")] = "Vaelgor",
    [normalizeCompareText("바엘고어 & 에조라크")] = "Vaelgor & Ezzorak",
    [normalizeCompareText("보라시우스")] = "Vorasius",
    [normalizeCompareText("카이메루스")] = "Chimaerus",
    [normalizeCompareText("전투전도사 센")] = "War Chaplain Senn",
    [normalizeCompareText("쿠엘다나스 진격로")] = "March on Quel'Danas",
    [normalizeCompareText("란지트")] = "Ranjit",
    [normalizeCompareText("크롤룩 사령관")] = "Commander Kruluk",
    [normalizeCompareText("코어수호자 니사라")] = "Corewarden Nysarra",
    [normalizeCompareText("데젠트리우스")] = "Degentrius",
    [normalizeCompareText("보르다자")] = "Bordaja",
    [normalizeCompareText("대현자 비릭스")] = "High Sage Viryx",
    [normalizeCompareText("엠버던")] = "Emberdon",
    [normalizeCompareText("로스라시온")] = "Losthrasion",
    [normalizeCompareText("게멜루스")] = "Gemellus",
    [normalizeCompareText("도라고사의 메아리")] = "Echo of Doragosa",
    [normalizeCompareText("사프리시")] = "Saprishi",
    [normalizeCompareText("이크와 크릭")] = "Ick and Krick",
    [normalizeCompareText("부왕 네즈하르")] = "Viceroy Nezhar",
    [normalizeCompareText("락툴")] = "Raktul",
    [normalizeCompareText("무로진과 네크락스")] = "Murozin and Nekrax",
    [normalizeCompareText("루라")] = "L'ura",
    [normalizeCompareText("세라넬 선래시")] = "Seranel Sunlash",
    [normalizeCompareText("아르카노트론 쿠스토스")] = "Arcanotron Custos",
    [normalizeCompareText("아라크나스")] = "Arachnas",
    [normalizeCompareText("루크란")] = "Rukhran",
    [normalizeCompareText("안식 없는 심장")] = "Restless Heart",
    [normalizeCompareText("크로스")] = "Crawth",
    [normalizeCompareText("벡사무스")] = "Vexamus",
    [normalizeCompareText("잔해 듀오")] = "Wreckage Duo",
}

localizeSourceLabel = function(label)
    if not label or label == "" then
        return label
    end
    local normalized = normalizeCompareText(label)
    if isKoreanLanguageSelected() then
        local localized = SOURCE_LABEL_KOKR[normalized]
        if localized and localized ~= "" then
            return localized
        end
    else
        local localized = SOURCE_LABEL_ENUS[normalized]
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

    local overrideItemLevel = tonumber(safeTooltipString(getTooltipDataField(tooltipData, "overrideItemLevel")))
    if overrideItemLevel and overrideItemLevel > 0 then
        return math.floor(overrideItemLevel + 0.5)
    end

    local lines = getTooltipDataField(tooltipData, "lines")
    for _, line in ipairs(type(lines) == "table" and lines or {}) do
        for _, key in ipairs({ "leftText", "rightText", "text" }) do
            local field = getTooltipDataField(line, key)
            local text = safeTooltipString(field)
            local ok, normalized = pcall(normalizeCompareText, text or "")
            if ok and normalized ~= "" and normalized:find(ITEM_LEVEL_TOKEN, 1, true) then
                local matchOk, itemLevel = pcall(function()
                    return tonumber((text or ""):match("(%d+)"))
                end)
                if matchOk and itemLevel then
                    return itemLevel
                end
            end
        end
    end

    return nil
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
    local label = index and ns.L("bis_note_rank", index) or ""
    local color = NOTE_BADGE_COLOR[kind] or NOTE_BADGE_COLOR.rank
    return label ~= "" and ("|c" .. color .. label .. "|r") or ""
end

local function notePlain(kind, index)
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

getSeasonalRaidRange = function()
    local tbl = ns.Data and ns.Data.ItemLevelTable
    local raid = tbl and tbl.raid
    if not raid or not raid.normal or not raid.mythic then
        return nil, nil
    end
    return raid.normal.min, raid.mythic.max
end

local function slotSortValue(slotName)
    return SLOT_SORT_ORDER[slotName] or 999
end

local findPlayerItemLink
local getMythPreviewSnapshot
local getAutomaticRuntimeScore
local scheduleAutomaticRuntimeScores

local function refreshEntryRuntimeScore(entry, specID)
    entry._runtimeScore = nil
    local score = getAutomaticRuntimeScore and getAutomaticRuntimeScore(entry, specID)
    if score then
        entry._runtimeScore = score
    end
end

local function compareSlotEntries(a, b)
    local ap = tonumber(a.overallRank) or notePriority(a.note)
    local bp = tonumber(b.overallRank) or notePriority(b.note)
    if ap ~= bp then
        return ap < bp
    end
    local aGroup = SOURCE_GROUP_ORDER[getEntrySourceType(a)] or 99
    local bGroup = SOURCE_GROUP_ORDER[getEntrySourceType(b)] or 99
    if aGroup ~= bGroup then
        return aGroup < bGroup
    end
    local aSourceRank = tonumber(a.sourceRank) or 99
    local bSourceRank = tonumber(b.sourceRank) or 99
    if aSourceRank ~= bSourceRank then
        return aSourceRank < bSourceRank
    end
    return (a.itemID or 0) < (b.itemID or 0)
end

local function applyRuntimeScoreOrdering(entries)
    local scoredPositions, scoredEntries = {}, {}
    for index, entry in ipairs(entries) do
        if tonumber(entry._runtimeScore) then
            scoredPositions[#scoredPositions + 1] = index
            scoredEntries[#scoredEntries + 1] = entry
        end
    end
    if #scoredEntries < 2 then
        return
    end
    table.sort(scoredEntries, function(a, b)
        local aRuntimeScore = tonumber(a._runtimeScore) or 0
        local bRuntimeScore = tonumber(b._runtimeScore) or 0
        if aRuntimeScore ~= bRuntimeScore then
            return aRuntimeScore > bRuntimeScore
        end
        return compareSlotEntries(a, b)
    end)
    for index, position in ipairs(scoredPositions) do
        entries[position] = scoredEntries[index]
    end
end

local function applySlotDisplayRanks(slotName, entries)
    for index, entry in ipairs(entries) do
        local bisLimit = SHARED_BIS_LIMIT_BY_SLOT[slotName] or 1
        if index <= bisLimit then
            entry._displayNoteKind = "bis"
            entry._displayNoteIndex = index
        elseif index == bisLimit + 1 then
            entry._displayNoteKind = "alt"
            entry._displayNoteIndex = index
        elseif index == bisLimit + 2 then
            entry._displayNoteKind = "third"
            entry._displayNoteIndex = index
        else
            entry._displayNoteKind = "rank"
            entry._displayNoteIndex = index
        end
    end
end

local function groupBySlot(items, specID)
    local allSlots, slotOrder = {}, {}
    for _, item in ipairs(items) do
        local slotName = item.slot or "기타"
        if not allSlots[slotName] then
            allSlots[slotName] = {}
            slotOrder[#slotOrder + 1] = slotName
        end
        allSlots[slotName][#allSlots[slotName] + 1] = item
    end

    table.sort(slotOrder, function(a, b)
        local av, bv = slotSortValue(a), slotSortValue(b)
        if av ~= bv then
            return av < bv
        end
        return tostring(a) < tostring(b)
    end)

    local slots, order, favorites = {}, {}, {}
    for _, slotName in ipairs(slotOrder) do
        local entries = allSlots[slotName]
        for _, entry in ipairs(entries) do
            refreshEntryRuntimeScore(entry, specID)
        end
        table.sort(entries, compareSlotEntries)
        applyRuntimeScoreOrdering(entries)
        applySlotDisplayRanks(slotName, entries)
        for _, entry in ipairs(entries) do
            if isBISItemFavorite(specID, entry.itemID) then
                favorites[#favorites + 1] = entry
            else
                slots[slotName] = slots[slotName] or {}
                slots[slotName][#slots[slotName] + 1] = entry
            end
        end
        if slots[slotName] and #slots[slotName] > 0 then
            applySlotDisplayRanks(slotName, slots[slotName])
            order[#order + 1] = slotName
        end
    end

    if #favorites > 0 then
        table.sort(favorites, function(a, b)
            local av, bv = slotSortValue(a.slot), slotSortValue(b.slot)
            if av ~= bv then
                return av < bv
            end
            return compareSlotEntries(a, b)
        end)
        slots[FAVORITES_SLOT] = favorites
        table.insert(order, 1, FAVORITES_SLOT)
    end

    return slots, order
end

-- ============================================================
-- 아이템 정보 로드 이벤트 → 디바운스 재빌드
-- ============================================================

local _rebuildPending = false
local _fullRebuildPending = false
local function scheduleRebuild(itemID, fullRebuild)
    if itemID then
        PENDING_ROW_REFRESH_ITEM_IDS[tonumber(itemID) or itemID] = true
    end
    _fullRebuildPending = _fullRebuildPending or fullRebuild == true
    if _rebuildPending then return end
    _rebuildPending = true
    C_Timer.After(0.3, function()
        _rebuildPending = false
        if BISOverlay.frame and BISOverlay.frame:IsShown() then
            pcall(function()
                if _fullRebuildPending
                or (BISOverlay._automaticScoreNeedsRetry and isOverlayItemTooltipEnabled()) then
                    BISOverlay._automaticScoreNeedsRetry = false
                    BISOverlay._isItemLoadRebuild = true
                    BISOverlay:RebuildContent()
                else
                    BISOverlay:RefreshVisibleItemRows(PENDING_ROW_REFRESH_ITEM_IDS)
                end
            end)
        end
        wipe(PENDING_ROW_REFRESH_ITEM_IDS)
        _fullRebuildPending = false
    end)
end

local function updateRowCheckButtonVisual(button, checked)
    if not button then
        return
    end
    if button.SetBackdropBorderColor then
        button:SetBackdropBorderColor(
            checked and 0.34 or 0.30,
            checked and 0.82 or 0.36,
            checked and 1.00 or 0.50,
            0.95
        )
    end
    if button.checkFill then
        button.checkFill:SetColorTexture(
            checked and 0.12 or 0.04,
            checked and 0.42 or 0.06,
            checked and 0.68 or 0.10,
            checked and 0.98 or 0.88
        )
    end
    if button.checkMark then
        if checked then
            button.checkMark:Show()
        else
            button.checkMark:Hide()
        end
    end
end

local function updateRowItemStateVisual(row)
    if not row or not row._entry or not row.itemID then
        return
    end

    local specID = row._specID or BISOverlay.selectedSpecID or getPlayerSpecID()
    local favorite = isBISItemFavorite(specID, row.itemID)
    local owned = isBISItemOwned(specID, row.itemID)
    updateRowCheckButtonVisual(row.favoriteBtn, favorite)
    updateRowCheckButtonVisual(row.ownedBtn, owned)

    if row.nameStrike then
        row.nameStrike:ClearAllPoints()
        row.nameStrike:SetPoint("LEFT", row.nameLabel, "LEFT", 0, 0)
        local stringWidth = row.nameLabel.GetStringWidth and row.nameLabel:GetStringWidth() or 0
        row.nameStrike:SetWidth(math.min(row._nameLabelWidth or COL_NAME, math.max(0, stringWidth)))
        if owned and stringWidth > 0 then
            row.nameStrike:Show()
        else
            row.nameStrike:Hide()
        end
    end
end

local function refreshItemRowDisplay(row)
    if not row or not row.nameLabel then
        return false
    end

    local entry = row._entry
    row.nameLabel:ClearAllPoints()
    row.nameLabel:SetFont(FONT_PATH, 11, FONT_FLAGS)

    local displayName = getEntryLocalizedName(entry)
    local displayTexture = getEntryIconTexture(entry)
    local displayQuality = getEntryQuality(entry)

    if row.itemID and row.itemID > 0 then
        local ok, itemName, _, quality, _, _, _, _, _, _, texture = pcall(GetItemInfo, row.itemID)
        if ok then
            displayName = displayName or itemName
            displayQuality = quality or displayQuality
            displayTexture = texture or displayTexture
        end
        if not itemName then
            requestItemData(row.itemID)
        end
    end

    if displayTexture then
        row.icon:SetTexture(displayTexture)
        row.icon:ClearAllPoints()
        row.icon:SetPoint("LEFT", row, "LEFT", COL_CONTROLS, 0)
        row.icon:Show()
    else
        row.icon:Hide()
    end

    local nameX = COL_CONTROLS + (displayTexture and COL_ICON or 0)
    local nameW = COL_NAME + (displayTexture and 0 or COL_ICON)
    row.nameLabel:SetPoint("LEFT", row, "LEFT", nameX, 0)
    row.nameLabel:SetWidth(nameW)
    row._nameLabelWidth = nameW

    if displayName and displayName ~= "" then
        local qc = getQualityColor(displayQuality)
        row.nameLabel:SetTextColor(qc[1], qc[2], qc[3], 1)
        row.nameLabel:SetText(displayName)
        updateRowItemStateVisual(row)
        return true
    end

    row.nameLabel:SetTextColor(QC[4][1], QC[4][2], QC[4][3], 0.50)
    row.nameLabel:SetText("...")
    updateRowItemStateVisual(row)
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
    local config = getOverlayConfig()
    config.collapsed = self._collapsed and true or false
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

    local config = getOverlayConfig()
    _bisScale = tonumber(config.scale) or getOverlayScale() or 1
    local frame = CreateFrame("Frame", "ABPMBISOverlay", UIParent, "BackdropTemplate")
    frame:SetFrameStrata("MEDIUM")
    frame:SetFrameLevel(100)
    frame:SetClampedToScreen(true)
    frame:SetSize(FRAME_W, HEADER_H + 60)
    frame:SetScale(_bisScale)

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
        setOverlayScale(f, delta * SCALE_STEP)
    end)
    frame:SetScript("OnDragStart", function(f)
        if ns.DB and ns.DB:IsBISOverlayLocked() then return end
        f:StartMoving()
    end)
    frame:SetScript("OnDragStop", function(f)
        f:StopMovingOrSizing()
        local currentConfig = getOverlayConfig()
        currentConfig.anchorMode = "overlay"
        if ns.DB and ns.DB.SaveBISOverlayPosition then
            ns.DB:SaveBISOverlayPosition(f)
        end
    end)
    frame:SetScript("OnHide",      function(f)
        f:StopMovingOrSizing()
        BISOverlay._automaticScoreQueueToken = (BISOverlay._automaticScoreQueueToken or 0) + 1
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
    frame.noticeText:SetPoint("TOPLEFT", frame.titleText, "BOTTOMLEFT", 0, -2)
    frame.noticeText:SetWidth(CONTENT_W - 170)
    frame.noticeText:SetJustifyH("LEFT")
    frame.noticeText:SetTextColor(1.00, 0.82, 0.46, 1)
    if frame.noticeText.SetWordWrap then
        frame.noticeText:SetWordWrap(false)
    end
    if frame.noticeText.SetMaxLines then
        frame.noticeText:SetMaxLines(1)
    end
    frame.noticeText:SetText(getSpecPolicySummary(getPlayerSpecID()))

    frame.avgLabel = frame:CreateFontString(nil, "OVERLAY")
    frame.avgLabel:SetFont(FONT_PATH, 9, FONT_FLAGS)
    frame.avgLabel:SetPoint("RIGHT", titleBar, "RIGHT", -(PADDING + 124), 0)
    frame.avgLabel:SetJustifyH("RIGHT")
    frame.avgLabel:SetTextColor(0.82, 0.86, 0.94, 1)
    frame.avgLabel:SetText(ns.L("bis_overlay_avg_label", "?"))

    local function attachHeaderButtonTooltip(button, titleKey, bodyProvider)
        if not button then
            return
        end
        button:SetScript("OnEnter", function(self2)
            local tooltip = ns.UI.Widgets.GetTooltip()
            if not tooltip then
                return
            end

            tooltip:SetOwner(self2, "ANCHOR_BOTTOM")
            tooltip:ClearLines()
            tooltip:AddLine(ns.L(titleKey), 1.00, 0.82, 0.44, true)
            local body = type(bodyProvider) == "function" and bodyProvider() or bodyProvider
            if body and body ~= "" then
                tooltip:AddLine(body, 0.90, 0.92, 0.98, true)
            end
            tooltip:Show()
        end)
        button:SetScript("OnLeave", ns.UI.Widgets.HideTooltip)
    end

    local itemTooltipBtn = CreateFrame("Button", nil, frame, "BackdropTemplate")
    itemTooltipBtn:SetSize(TITLE_TOGGLE_W, TITLE_TOGGLE_H)
    itemTooltipBtn:SetPoint("RIGHT", frame.avgLabel, "LEFT", -8, 0)
    if itemTooltipBtn.SetBackdrop then
        itemTooltipBtn:SetBackdrop({
            bgFile   = "Interface\\Tooltips\\UI-Tooltip-Background",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true, tileSize = 8, edgeSize = 8,
            insets = { left = 2, right = 2, top = 2, bottom = 2 },
        })
    end
    itemTooltipBtn.fill = itemTooltipBtn:CreateTexture(nil, "BACKGROUND")
    itemTooltipBtn.fill:SetPoint("TOPLEFT", itemTooltipBtn, "TOPLEFT", 3, -3)
    itemTooltipBtn.fill:SetPoint("BOTTOMRIGHT", itemTooltipBtn, "BOTTOMRIGHT", -3, 3)
    itemTooltipBtn.checkBox = CreateFrame("Frame", nil, itemTooltipBtn, "BackdropTemplate")
    itemTooltipBtn.checkBox:SetSize(10, 10)
    itemTooltipBtn.checkBox:SetPoint("LEFT", itemTooltipBtn, "LEFT", 5, 0)
    if itemTooltipBtn.checkBox.SetBackdrop then
        itemTooltipBtn.checkBox:SetBackdrop({
            bgFile   = "Interface\\Tooltips\\UI-Tooltip-Background",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true, tileSize = 8, edgeSize = 8,
            insets = { left = 2, right = 2, top = 2, bottom = 2 },
        })
    end
    itemTooltipBtn.checkFill = itemTooltipBtn.checkBox:CreateTexture(nil, "BACKGROUND")
    itemTooltipBtn.checkFill:SetPoint("TOPLEFT", itemTooltipBtn.checkBox, "TOPLEFT", 2, -2)
    itemTooltipBtn.checkFill:SetPoint("BOTTOMRIGHT", itemTooltipBtn.checkBox, "BOTTOMRIGHT", -2, 2)
    itemTooltipBtn.checkMark = itemTooltipBtn.checkBox:CreateFontString(nil, "OVERLAY")
    itemTooltipBtn.checkMark:SetFont(FONT_PATH, 8, FONT_FLAGS)
    itemTooltipBtn.checkMark:SetAllPoints()
    itemTooltipBtn.checkMark:SetJustifyH("CENTER")
    itemTooltipBtn.checkMark:SetJustifyV("MIDDLE")
    itemTooltipBtn.label = itemTooltipBtn:CreateFontString(nil, "OVERLAY")
    itemTooltipBtn.label:SetFont(FONT_PATH, 8, FONT_FLAGS)
    itemTooltipBtn.label:SetPoint("LEFT", itemTooltipBtn.checkBox, "RIGHT", 3, 0)
    itemTooltipBtn.label:SetPoint("RIGHT", itemTooltipBtn, "RIGHT", -3, 0)
    itemTooltipBtn.label:SetJustifyH("LEFT")
    itemTooltipBtn.label:SetJustifyV("MIDDLE")
    itemTooltipBtn:SetScript("OnEnter", function(self2)
        local tooltip = ns.UI.Widgets.GetTooltip()
        if not tooltip then
            return
        end

        tooltip:SetOwner(self2, "ANCHOR_BOTTOM")
        tooltip:SetText(ns.L("bis_overlay_item_tooltip"), 1, 1, 1, 1, true)
        tooltip:AddLine(ns.L("bis_overlay_item_tooltip_hint"), 0.70, 0.78, 0.90, true)
        ns.UI.Widgets.ApplyTooltip(tooltip, 13, 12)
        tooltip:Show()
    end)
    itemTooltipBtn:SetScript("OnLeave", ns.UI.Widgets.HideTooltip)
    local function updateBISItemTooltipVisual()
        local enabled = isOverlayItemTooltipEnabled()
        itemTooltipBtn.label:SetText(ns.L("bis_overlay_item_tooltip"))
        if itemTooltipBtn.SetBackdropColor then
            itemTooltipBtn:SetBackdropColor(enabled and 0.10 or 0.06, enabled and 0.17 or 0.09, enabled and 0.24 or 0.14, 0.98)
        end
        if itemTooltipBtn.SetBackdropBorderColor then
            itemTooltipBtn:SetBackdropBorderColor(enabled and 0.34 or 0.24, enabled and 0.78 or 0.34, enabled and 1.00 or 0.52, 0.92)
        end
        itemTooltipBtn.fill:SetColorTexture(enabled and 0.12 or 0.09, enabled and 0.16 or 0.11, enabled and 0.24 or 0.17, 0.94)
        itemTooltipBtn.checkFill:SetColorTexture(enabled and 0.18 or 0.04, enabled and 0.42 or 0.05, enabled and 0.68 or 0.10, 0.98)
        if itemTooltipBtn.checkBox and itemTooltipBtn.checkBox.SetBackdropBorderColor then
            itemTooltipBtn.checkBox:SetBackdropBorderColor(enabled and 0.38 or 0.32, enabled and 0.82 or 0.38, enabled and 1.00 or 0.52, 0.95)
        end
        itemTooltipBtn.checkMark:SetText(enabled and "X" or "")
        itemTooltipBtn.checkMark:SetTextColor(1, 1, 1, enabled and 1 or 0.80)
        itemTooltipBtn.label:SetTextColor(enabled and 0.92 or 0.82, enabled and 0.96 or 0.86, enabled and 1.00 or 0.94, 1)
    end
    itemTooltipBtn:SetScript("OnClick", function()
        if ns.DB and ns.DB.SetBISOverlayItemTooltipEnabled then
            ns.DB:SetBISOverlayItemTooltipEnabled(not isOverlayItemTooltipEnabled())
        end
        updateBISItemTooltipVisual()
        BISOverlay._isItemLoadRebuild = true
        BISOverlay:RebuildContent()
    end)
    frame.itemTooltipBtn = itemTooltipBtn
    frame.updateBISItemTooltipVisual = updateBISItemTooltipVisual
    updateBISItemTooltipVisual()

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
    attachHeaderButtonTooltip(collapseBtn, "overlay_button_collapse_title", function()
        return BISOverlay._collapsed and ns.L("overlay_button_collapse_body_collapsed")
            or ns.L("overlay_button_collapse_body_expanded")
    end)
    frame.collapseBtn = collapseBtn

    -- ─── 잠금 버튼 (드래그 잠금/해제) ─────────────────────────
    local lockBtn = CreateFrame("Button", nil, frame)
    lockBtn:SetSize(18, 18)
    lockBtn:SetPoint("RIGHT", collapseBtn, "LEFT", -2, 0)
    lockBtn.label = lockBtn:CreateFontString(nil, "OVERLAY")
    lockBtn.label:SetFont(FONT_PATH, 10, FONT_FLAGS)
    lockBtn.label:SetAllPoints()
    lockBtn.label:SetJustifyH("CENTER")
    lockBtn.label:SetJustifyV("MIDDLE")
    local function updateBISLockVisual()
        local locked = ns.DB and ns.DB:IsBISOverlayLocked()
        lockBtn.label:SetText(locked and "L" or "U")
        lockBtn.label:SetTextColor(locked and 1 or 0.70, locked and 0.60 or 0.70, locked and 0.60 or 0.80, 1)
    end
    updateBISLockVisual()
    lockBtn:SetScript("OnClick", function()
        if ns.DB then
            ns.DB:SetBISOverlayLocked(not ns.DB:IsBISOverlayLocked())
        end
        updateBISLockVisual()
    end)
    attachHeaderButtonTooltip(lockBtn, "overlay_button_lock_title", function()
        return (ns.DB and ns.DB:IsBISOverlayLocked())
            and ns.L("overlay_button_lock_body_locked")
            or ns.L("overlay_button_lock_body_unlocked")
    end)
    frame.lockBtn = lockBtn

    -- ─── 위치 초기화 버튼 ─────────────────────────────────────
    local resetBtn = CreateFrame("Button", nil, frame)
    resetBtn:SetSize(18, 18)
    resetBtn:SetPoint("RIGHT", lockBtn, "LEFT", -2, 0)
    resetBtn.label = resetBtn:CreateFontString(nil, "OVERLAY")
    resetBtn.label:SetFont(FONT_PATH, 10, FONT_FLAGS)
    resetBtn.label:SetAllPoints()
    resetBtn.label:SetJustifyH("CENTER")
    resetBtn.label:SetJustifyV("MIDDLE")
    resetBtn.label:SetText("R")
    resetBtn.label:SetTextColor(0.70, 0.70, 0.80, 1)
    resetBtn:SetScript("OnClick", function()
        local defaults = ns.Data and ns.Data.Defaults and ns.Data.Defaults.ui and ns.Data.Defaults.ui.bisOverlay
        if not defaults then return end
        local config = getOverlayConfig()
        config.anchorMode = defaults.anchorMode or "itemlevel"
        config.point = defaults.point
        config.relativePoint = defaults.relativePoint
        config.x = defaults.x
        config.y = defaults.y
        BISOverlay._lastAnchorTarget = nil
        BISOverlay._lastAnchorMode = nil
        BISOverlay:Refresh()
    end)
    attachHeaderButtonTooltip(resetBtn, "overlay_button_reset_title", ns.L("overlay_button_reset_body"))
    frame.resetBtn = resetBtn

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
        local tooltip = ns.UI.Widgets.GetTooltip()
        if not tooltip then
            return
        end

        tooltip:SetOwner(self2, "ANCHOR_BOTTOM")
        tooltip:SetText(ns.L("bis_all_specs"), 1, 1, 1, 1, true)
        tooltip:AddLine(ns.L("bis_all_specs_hint"), 0.70, 0.78, 0.90, true)
        tooltip:Show()
    end)
    frame.specPickerBtn:SetScript("OnLeave", function()
        if not (frame.specPicker and frame.specPicker:IsShown()) then
            ns.UI.Widgets.HideTooltip()
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
        markScrollActivity()
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
    local function updateThumbDrag()
        if not _dragging then return end
        markScrollActivity()
        local curY    = select(2, GetCursorPosition()) / UIParent:GetEffectiveScale()
        local dy      = _dragY - curY
        local trackH  = math.max(1, frame.scrollBarTrack:GetHeight())
        local thumbH  = math.max(1, frame.scrollBarThumb:GetHeight())
        local maxS    = frame.scrollFrame:GetVerticalScrollRange()
        local frac    = dy / (trackH - thumbH)
        local newS    = math.max(0, math.min(maxS, _dragScroll + frac * maxS))
        frame.scrollFrame:SetVerticalScroll(newS)
        self:UpdateScrollThumb()
    end
    frame.scrollBarThumb:EnableMouse(true)
    frame.scrollBarThumb:SetScript("OnMouseDown", function(_, button)
        if button ~= "LeftButton" then return end
        markScrollActivity()
        _dragging  = true
        _dragY     = select(2, GetCursorPosition()) / UIParent:GetEffectiveScale()
        _dragScroll = frame.scrollFrame:GetVerticalScroll()
        frame.scrollBarThumb:SetScript("OnUpdate", updateThumbDrag)
    end)
    frame.scrollBarThumb:SetScript("OnMouseUp", function()
        _dragging = false
        frame.scrollBarThumb:SetScript("OnUpdate", nil)
    end)

    -- GET_ITEM_INFO_RECEIVED 이벤트
    local evFrame = CreateFrame("Frame")
    evFrame:RegisterEvent("GET_ITEM_INFO_RECEIVED")
    evFrame:SetScript("OnEvent", function(_, _, itemID, success)
        local numericID = tonumber(itemID)
        local requested = numericID and PENDING_ITEM_DATA[numericID]
        if numericID then
            PENDING_ITEM_DATA[numericID] = nil
        end
        if success and requested then scheduleRebuild(numericID) end
    end)

    frame.rows = {}
    self._collapsed = config.collapsed and true or false
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
            local tooltip = ns.UI.Widgets.GetTooltip()
            if not tooltip then
                return
            end

            tooltip:SetOwner(self2, "ANCHOR_BOTTOM")
            tooltip:SetText(spec.name, 1, 1, 1, 1, true)
            tooltip:Show()
        end)
        tab:SetScript("OnLeave", ns.UI.Widgets.HideTooltip)
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
    itemID = tonumber(itemID)
    if not itemID or itemID <= 0 or PENDING_ITEM_DATA[itemID] then return end
    if C_Item and C_Item.RequestLoadItemDataByID then
        PENDING_ITEM_DATA[itemID] = true
        local ok = pcall(C_Item.RequestLoadItemDataByID, itemID)
        if not ok then
            PENDING_ITEM_DATA[itemID] = nil
        end
    end
end

local function isItemHyperlink(link)
    return type(link) == "string"
        and (link:find("|Hitem:", 1, true) ~= nil or link:find("^item:") ~= nil)
end

local function getTooltipDataForHyperlink(link)
    if not isItemHyperlink(link) or not C_TooltipInfo or not C_TooltipInfo.GetHyperlink then
        return nil
    end
    local ok, tooltipData = pcall(C_TooltipInfo.GetHyperlink, link)
    if ok and type(tooltipData) == "table" then
        return tooltipData
    end
    return nil
end

local function isTimewalkingInstance()
    local inInstance, instanceType = IsInInstance()
    if not inInstance or instanceType ~= "party" then return false end
    -- difficulty 24 = Timewalking Dungeon
    local _, _, difficulty = GetInstanceInfo()
    return difficulty == 24
end

local function isValidPreviewItemLevel(sourceType, itemLevel)
    if not itemLevel or itemLevel <= 0 then
        return false
    end
    -- 시간여행 던전에서는 아이템이 스케일다운된 ilvl로 표시되므로 범위 검증을 우회
    if isTimewalkingInstance() then
        return true
    end
    if sourceType == "raid" or sourceType == "tier" then
        local minRaid, maxRaid = getSeasonalRaidRange()
        local tbl = ns.Data and ns.Data.ItemLevelTable
        local mythicVault = tbl and tbl.raid and tbl.raid.mythic and tbl.raid.mythic.vault or maxRaid
        return minRaid and mythicVault and itemLevel >= minRaid and itemLevel <= mythicVault
    end
    if sourceType == "crafted" then
        local tbl = ns.Data and ns.Data.ItemLevelTable
        local crafted = tbl and tbl.crafted
        local minCraft = crafted and crafted.base and crafted.base.ilvl or nil
        local maxCraft = crafted and crafted.r5 and crafted.r5.ilvl or nil
        return minCraft and maxCraft and itemLevel >= minCraft and itemLevel <= maxCraft
    end
    return true
end

local function isValidTooltipLinkForSource(link, sourceType)
    if not isItemHyperlink(link) then
        return false
    end
    local tooltipData = getTooltipDataForHyperlink(link)
    local itemLevel = extractTooltipItemLevel(tooltipData)
    return isValidPreviewItemLevel(sourceType, itemLevel)
end

local function getItemIDFromLink(link)
    if type(link) ~= "string" or link == "" then
        return nil
    end
    if GetItemInfoInstant then
        local ok, itemID = pcall(GetItemInfoInstant, link)
        if ok and tonumber(itemID) then
            return tonumber(itemID)
        end
    end
    return tonumber(link:match("item:(%d+)"))
end

local function isMatchingItemLink(link, itemID)
    return isItemHyperlink(link) and getItemIDFromLink(link) == tonumber(itemID)
end

local function getMythPreviewBaselineItemLevel()
    local curated = ns.Data and ns.Data.BISMythicVaultLinks
    return tonumber(curated and curated.baselineItemLevel) or 272
end

local function isValidMythPreviewSnapshot(snapshot, itemID)
    return type(snapshot) == "table"
        and safePlainNumber(snapshot.itemID) == tonumber(itemID)
        and safePlainNumber(snapshot.itemLevel) == getMythPreviewBaselineItemLevel()
        and type(snapshot.lines) == "table"
        and #snapshot.lines > 0
end

getMythPreviewSnapshot = function(itemID)
    local snapshot = ns.DB and ns.DB.GetBISOverlayMythPreviewSnapshot
        and ns.DB:GetBISOverlayMythPreviewSnapshot(itemID)
        or nil
    if isValidMythPreviewSnapshot(snapshot, itemID) then
        return snapshot
    end

    local curated = ns.Data and ns.Data.BISMythicVaultLinks
    snapshot = curated and curated.snapshotsByItemID and curated.snapshotsByItemID[tonumber(itemID)] or nil
    if isValidMythPreviewSnapshot(snapshot, itemID) then
        if ns.DB and ns.DB.SetBISOverlayMythPreviewSnapshot then
            ns.DB:SetBISOverlayMythPreviewSnapshot(itemID, snapshot)
        end
        return snapshot
    end
    return nil
end

local function sanitizeTooltipLine(line, rendered)
    if type(line) ~= "table" or isTooltipMoneyLine(line) then
        return nil
    end
    local leftText = safeTooltipString(getTooltipDataField(line, "leftText"))
        or safeTooltipString(getTooltipDataField(line, "text"))
    local rightText = safeTooltipString(getTooltipDataField(line, "rightText"))
    if not leftText and not rightText then
        return nil
    end

    local fallbackR, fallbackG, fallbackB = 0.90, 0.90, 0.90
    if rendered == 0 then
        fallbackR, fallbackG, fallbackB = 0.80, 0.35, 1.00
    end
    local leftR, leftG, leftB = getTooltipLineColor(line, "leftColor", fallbackR, fallbackG, fallbackB)
    local rightR, rightG, rightB = getTooltipLineColor(line, "rightColor", 0.90, 0.90, 0.90)
    return {
        leftText = leftText,
        rightText = rightText,
        leftColor = {
            safePlainNumber(leftR) or fallbackR,
            safePlainNumber(leftG) or fallbackG,
            safePlainNumber(leftB) or fallbackB,
        },
        rightColor = {
            safePlainNumber(rightR) or 0.90,
            safePlainNumber(rightG) or 0.90,
            safePlainNumber(rightB) or 0.90,
        },
    }
end

local function buildMythPreviewSnapshot(entry, link)
    local itemID = tonumber(entry and entry.itemID)
    if not itemID or not isMatchingItemLink(link, itemID) then
        return nil
    end
    local tooltipData = getTooltipDataForHyperlink(link)
    local itemLevel = extractTooltipItemLevel(tooltipData)
    if itemLevel ~= getMythPreviewBaselineItemLevel() then
        return nil
    end

    local lines = {}
    for _, line in ipairs(type(tooltipData.lines) == "table" and tooltipData.lines or {}) do
        local sanitized = sanitizeTooltipLine(line, #lines)
        if sanitized then
            lines[#lines + 1] = sanitized
        end
    end
    if #lines == 0 then
        return nil
    end

    local rawStats = {}
    if C_Item and type(C_Item.GetItemStats) == "function" then
        local ok, stats = pcall(C_Item.GetItemStats, link)
        if ok and type(stats) == "table" then
            for key, value in pairs(stats) do
                local numeric = safePlainNumber(value)
                if type(key) == "string" and numeric then
                    rawStats[key] = numeric
                end
            end
        end
    end

    local itemName, _, quality, _, _, _, _, _, _, icon = GetItemInfo(link)
    return {
        itemID = itemID,
        itemLevel = itemLevel,
        itemLink = safeTooltipString(link),
        name = safeTooltipString(itemName),
        quality = safePlainNumber(quality) or getEntryQuality(entry),
        icon = safePlainNumber(icon) or safeTooltipString(icon),
        lines = lines,
        rawStats = rawStats,
        scannedAt = type(time) == "function" and safePlainNumber(time()) or nil,
    }
end

local AUTOMATIC_SCORE_CACHE = {}

local function clearAutomaticScoreCache()
    wipe(AUTOMATIC_SCORE_CACHE)
end

local function cacheMythPreviewSnapshot(entry, link)
    local snapshot = buildMythPreviewSnapshot(entry, link)
    if not snapshot or not ns.DB or not ns.DB.SetBISOverlayMythPreviewSnapshot then
        return false
    end
    ns.DB:SetBISOverlayMythPreviewSnapshot(entry.itemID, snapshot)
    clearAutomaticScoreCache()
    return true
end

findPlayerItemLink = function(itemID)
    itemID = tonumber(itemID)
    if not itemID or itemID <= 0 then
        return nil
    end
    local function findMatching(link)
        return isMatchingItemLink(link, itemID) and link or nil
    end
    if GetInventoryItemLink then
        for slotID = 1, (INVSLOT_LAST_EQUIPPED or 19) do
            local link = findMatching(GetInventoryItemLink("player", slotID))
            if link then
                return link
            end
        end
    end

    local getNumSlots = C_Container and C_Container.GetContainerNumSlots or GetContainerNumSlots
    local getItemLink = C_Container and C_Container.GetContainerItemLink or GetContainerItemLink
    if not getNumSlots or not getItemLink then
        return nil
    end

    local lastBagID = NUM_BAG_SLOTS or 4
    local reagentBagID = tonumber(Enum and Enum.BagIndex and Enum.BagIndex.ReagentBag or REAGENTBAG_CONTAINER)
    if reagentBagID and reagentBagID > lastBagID then
        lastBagID = reagentBagID
    end
    for bagID = 0, lastBagID do
        local ok, numSlots = pcall(getNumSlots, bagID)
        if ok then
            for slotID = 1, (numSlots or 0) do
                local linkOK, link = pcall(getItemLink, bagID, slotID)
                if linkOK then
                    link = findMatching(link)
                    if link then
                        return link
                    end
                end
            end
        end
    end
    return nil
end

local AUTOMATIC_SCORE_DELAY = 0.03

local function getAutomaticScoreCacheKey(entry, specID)
    return table.concat({
        tostring(specID or 0),
        tostring(entry and entry.slot or ""),
        tostring(entry and entry.itemID or 0),
    }, ":")
end

getAutomaticRuntimeScore = function(entry, specID)
    if not isOverlayItemTooltipEnabled() or getEntrySourceType(entry) ~= "mythicplus" then
        return nil
    end
    local cacheKey = getAutomaticScoreCacheKey(entry, specID)
    local cached = AUTOMATIC_SCORE_CACHE[cacheKey]
    if cached ~= nil then
        return type(cached) == "number" and cached or nil
    end
    local snapshot = getMythPreviewSnapshot(entry.itemID)
    local scoring = ns.Data and ns.Data.BISRuntimeScoring
    if not snapshot or not scoring or type(scoring.ScoreItemSnapshot) ~= "function" then
        return nil
    end
    local score = scoring:ScoreItemSnapshot(specID, entry.slot, snapshot, "mythicplus", {
        sourceKey = "MPLUS_GREAT_VAULT",
        keyLevel = getSeasonPreviewKeyLevel(),
    })
    AUTOMATIC_SCORE_CACHE[cacheKey] = score or false
    return score
end

local REJECTED_MYTH_PREVIEW_LINKS = {}

local function getConfiguredMythicVaultItemLinks(entry)
    local profiles = entry and entry.rewardProfiles
    local profile = profiles and profiles.mplus_great_vault_voidcore
    local curated = ns.Data and ns.Data.BISMythicVaultLinks
    local linksByItemID = curated and curated.linksByItemID
    local generatedPreviewBonusListID = tonumber(curated and curated.generatedPreviewBonusListID)
    local generatedPreviewItemStringTemplate = curated and curated.generatedPreviewItemStringTemplate
    local itemID = tonumber(entry and entry.itemID)
    local links, seen = {}, {}
    local function addLink(link)
        if type(link) == "string"
        and link ~= ""
        and not seen[link]
        and not REJECTED_MYTH_PREVIEW_LINKS[link] then
            seen[link] = true
            links[#links + 1] = link
        end
    end
    addLink(profile and profile.itemLink)
    addLink(profile and profile.itemString)
    addLink(linksByItemID and linksByItemID[itemID])
    if itemID and generatedPreviewBonusListID and type(generatedPreviewItemStringTemplate) == "string" then
        -- Retail ItemLink fields before numBonusIDs:
        -- enchant, four gems, suffix, unique, link level, spec, mask, context.
        local ok, generatedLink = pcall(
            string.format,
            generatedPreviewItemStringTemplate,
            itemID,
            generatedPreviewBonusListID
        )
        if ok then
            addLink(generatedLink)
        end
    end
    return links
end

local function getExactMythicVaultItemLink(entry)
    local baselineItemLevel = getMythicPlusVaultPreviewItemLevel(entry)
    local pending = false
    local links = getConfiguredMythicVaultItemLinks(entry)
    for _, link in ipairs(links) do
        if isMatchingItemLink(link, entry.itemID) then
            local tooltipData = getTooltipDataForHyperlink(link)
            local itemLevel = extractTooltipItemLevel(tooltipData)
            if itemLevel == baselineItemLevel then
                return link, false
            end
            if not tooltipData or not itemLevel then
                pending = true
                BISOverlay._automaticScoreNeedsRetry = true
                requestItemData(entry.itemID)
            elseif itemLevel ~= baselineItemLevel then
                REJECTED_MYTH_PREVIEW_LINKS[link] = true
            end
        end
    end
    return nil, pending
end

local function resolveMythPreviewSnapshot(entry)
    if getMythPreviewSnapshot(entry.itemID) then
        return false
    end
    local previewLink, pending = getExactMythicVaultItemLink(entry)
    if not previewLink then
        return nil
    end
    local cached = cacheMythPreviewSnapshot(entry, previewLink)
    if not cached and pending then
        BISOverlay._automaticScoreNeedsRetry = true
    end
    return cached
end

scheduleAutomaticRuntimeScores = function(items, specID)
    BISOverlay._automaticScoreQueueToken = (BISOverlay._automaticScoreQueueToken or 0) + 1
    local queueToken = BISOverlay._automaticScoreQueueToken
    if not isOverlayItemTooltipEnabled() or not C_Timer or type(C_Timer.After) ~= "function" then
        return
    end

    local queue, seen = {}, {}
    for _, entry in ipairs(items or {}) do
        if getEntrySourceType(entry) == "mythicplus"
        and not getMythPreviewSnapshot(entry.itemID)
        and #getConfiguredMythicVaultItemLinks(entry) > 0 then
            local itemID = tonumber(entry.itemID)
            if itemID and not seen[itemID] then
                seen[itemID] = true
                queue[#queue + 1] = entry
            end
        end
    end
    if #queue == 0 then
        return
    end

    local index, changed = 0, false
    local function processNext()
        if queueToken ~= BISOverlay._automaticScoreQueueToken
        or not isOverlayItemTooltipEnabled()
        or not BISOverlay.frame
        or not BISOverlay.frame:IsShown() then
            return
        end

        index = index + 1
        if resolveMythPreviewSnapshot(queue[index]) then
            changed = true
        end
        if index < #queue then
            C_Timer.After(AUTOMATIC_SCORE_DELAY, processNext)
        elseif changed then
            BISOverlay._isItemLoadRebuild = true
            BISOverlay:RebuildContent()
        end
    end
    C_Timer.After(0, processNext)
end

local showSeasonItemTooltip

showSeasonItemTooltip = function(owner, row)
    if isScrollTooltipSuppressed() or not row or not row.itemID or row.itemID <= 0 then return end

    local tooltip = getBISTooltip()
    if not tooltip then
        return
    end

    local entry = row._entry or {}

    local function getTooltipFontColorRGB(fontColor, fallbackR, fallbackG, fallbackB)
        if type(fontColor) == "table" then
            if type(fontColor.GetRGB) == "function" then
                local r, g, b = fontColor:GetRGB()
                return r or fallbackR, g or fallbackG, b or fallbackB
            end
            return fontColor.r or fallbackR, fontColor.g or fallbackG, fontColor.b or fallbackB
        end
        return fallbackR, fallbackG, fallbackB
    end

    local function wrapTooltipTextColor(text, r, g, b)
        local function toByte(value)
            value = tonumber(value) or 1
            value = math.max(0, math.min(1, value))
            return math.floor(value * 255 + 0.5)
        end
        return string.format("|cff%02x%02x%02x%s|r", toByte(r), toByte(g), toByte(b), tostring(text or ""))
    end

    local labelR, labelG, labelB = getTooltipFontColorRGB(DISABLED_FONT_COLOR, 0.62, 0.68, 0.78)
    local valueR, valueG, valueB = getTooltipFontColorRGB(HIGHLIGHT_FONT_COLOR, 0.96, 0.96, 0.96)
    local accentR, accentG, accentB = 1.00, 0.82, 0.44

    local function addStyledTooltipLine(label, value, vr, vg, vb)
        local text = wrapTooltipTextColor((label or "") .. ":", labelR, labelG, labelB)
        local valueText = tostring(value or "")
        if valueText ~= "" then
            text = text .. " " .. wrapTooltipTextColor(valueText, vr or valueR, vg or valueG, vb or valueB)
        end
        tooltip:AddLine(text, 1, 1, 1, true)
    end

    local function isRaidLocationLabel(label)
        local normalized = normalizeCompareText(label)
        if normalized == "" then
            return false
        end
        for _, candidate in ipairs({
            "한밤 폭포", "Midnight Falls",
            "공허 첨탑", "The Voidspire",
            "꿈의균열", "Dreamrift", "The Dreamrift",
            "쿠엘다나스 진격로", "March on Quel'danas", "March on Quel’danas",
        }) do
            if normalized == normalizeCompareText(candidate) then
                return true
            end
        end
        return false
    end

    local function getTooltipDungeonLabel()
        local dungeonName = resolveSeasonDungeonName(
            (isKoreanLanguageSelected() and entry.dungeon) or entry.dungeonEnUS or entry.dungeon or entry.sourceLabel
        )
        return dungeonName and localizeDungeon(dungeonName) or nil
    end

    local function getTooltipRaidLabel()
        local display = getDisplaySourceLabel(entry)
        if display and display ~= "" and isRaidLocationLabel(display) then
            return display
        end
        return nil
    end

    local function getTooltipBossLabel(sourceType)
        if entry.boss and entry.boss ~= "" then
            local bossLabel = localizeSourceLabel(entry.boss)
            if (not isKoreanLanguageSelected()) and type(bossLabel) == "string" and bossLabel:find("[가-힣]") then
                return nil
            end
            return bossLabel
        end

        if sourceType == "raid" then
            local display = getDisplaySourceLabel(entry)
            if display and display ~= "" and not isRaidLocationLabel(display) and not hasRaidMetaLabel(display) then
                return display
            end
        end

        return nil
    end

    local function getTooltipMethodLabel(sourceType)
        if sourceType == "crafted" then
            local label = localizeSourceLabel(entry.sourceLabel)
            if not label or label == "" or isCraftingSourceLabel(entry.sourceLabel) then
                return localizeSourceType(sourceType)
            end
            return label
        end
        if sourceType == "tier" then
            local label = localizeSourceLabel(entry.sourceLabel)
            if not label or label == "" or label == localizeSourceType(sourceType) then
                return ns.L("bis_basis_tier")
            end
            return label
        end
        return nil
    end

    local function appendSeasonTooltipDetails(sourceType, sourceR, sourceG, sourceB)
        addStyledTooltipLine(ns.L("bis_tooltip_acquisition"), localizeSourceType(sourceType), sourceR, sourceG, sourceB)

        if sourceType == "mythicplus" then
            local dungeonLabel = getTooltipDungeonLabel()
            local bossLabel = getTooltipBossLabel(sourceType)
            if dungeonLabel then
                addStyledTooltipLine(ns.L("bis_tooltip_dungeon"), dungeonLabel, sourceR, sourceG, sourceB)
            end
            if bossLabel then
                addStyledTooltipLine(ns.L("bis_tooltip_boss"), bossLabel, accentR, accentG, accentB)
            end
            return
        end

        if sourceType == "raid" then
            local raidLabel = getTooltipRaidLabel()
            local bossLabel = getTooltipBossLabel(sourceType)
            if raidLabel then
                addStyledTooltipLine(ns.L("bis_tooltip_raid"), raidLabel, sourceR, sourceG, sourceB)
            end
            if bossLabel then
                addStyledTooltipLine(ns.L("bis_tooltip_boss"), bossLabel, accentR, accentG, accentB)
            end
            if not raidLabel and not bossLabel then
                addStyledTooltipLine(ns.L("bis_tooltip_source"), getDisplaySourceLabel(entry), sourceR, sourceG, sourceB)
            end
            return
        end

        if sourceType == "crafted" or sourceType == "tier" then
            local methodLabel = getTooltipMethodLabel(sourceType)
            if methodLabel and methodLabel ~= "" then
                addStyledTooltipLine(ns.L("bis_tooltip_method"), methodLabel, sourceR, sourceG, sourceB)
            else
                addStyledTooltipLine(ns.L("bis_tooltip_source"), getDisplaySourceLabel(entry), sourceR, sourceG, sourceB)
            end
            local raidLabel = getTooltipRaidLabel()
            if raidLabel then
                addStyledTooltipLine(ns.L("bis_tooltip_raid"), raidLabel, sourceR, sourceG, sourceB)
            end
        end
    end

    local function appendCompactSeasonTooltipMeta()
        local sourceType = getEntrySourceType(entry)
        local noteKind = row._displayNoteKind or canonicalNote(entry.note)
        local noteIndex = row._displayNoteIndex or 3
        local sr, sg, sb = getSourceTypeColor(sourceType)

        addStyledTooltipLine(ns.L("bis_tooltip_slot"), localizeSlot(entry.slot))
        if sourceType == "mythicplus" then
            addStyledTooltipLine(
                ns.L("bis_tooltip_myth_baseline"),
                ns.L("bis_track_mplus_myth_baseline", getMythicPlusVaultPreviewItemLevel(entry)),
                sr, sg, sb
            )
        end
        appendSeasonTooltipDetails(sourceType, sr, sg, sb)
        addStyledTooltipLine(ns.L("bis_tooltip_rank"), notePlain(noteKind, noteIndex))
        return sourceType
    end

    local function showSeasonFallbackTooltip()
        local itemName, _, quality = GetItemInfo(row.itemID)
        if not itemName then
            requestItemData(row.itemID)
        end
        local displayName = getEntryLocalizedName(entry) or itemName or ("Item #" .. tostring(row.itemID))
        local qc = getQualityColor(quality or getEntryQuality(entry))
        local fallbackSourceType

        tooltip:SetOwner(owner, "ANCHOR_CURSOR_RIGHT")
        tooltip:ClearLines()
        tooltip:AddLine(displayName, qc[1], qc[2], qc[3], 1)
        fallbackSourceType = appendCompactSeasonTooltipMeta()
        if isOverlayItemTooltipEnabled() and fallbackSourceType == "mythicplus" then
            tooltip:AddLine(" ")
            tooltip:AddLine(ns.L("bis_tooltip_myth_snapshot_unavailable"), 1.00, 0.72, 0.38, true)
        end
        if fallbackSourceType == "mythicplus" or fallbackSourceType == "raid" then
            tooltip:AddLine(" ")
            tooltip:AddLine(ns.L("bis_tooltip_open_journal"), 0.35, 0.85, 1.00, true)
        end
        tooltip:Show()
    end

    local function tryRenderTooltipHyperlink(link)
        if type(link) ~= "string" or link == "" then
            return false
        end
        local tooltipData = getTooltipDataForHyperlink(link)
        return renderTooltipDataWithoutMoney(tooltip, tooltipData, getEntryQuality(entry))
    end

    local function tryRenderTooltipSnapshot(snapshot)
        return renderTooltipSnapshot(tooltip, snapshot, getEntryQuality(entry))
    end

    local function tryShowTooltipItemID(itemID, sourceType)
        if not itemID or itemID <= 0 then
            return false
        end
        if sourceType == "mythicplus" then
            requestItemData(itemID)
            return false
        end
        local _, itemLink = GetItemInfo(itemID)
        if itemLink and isValidTooltipLinkForSource(itemLink, sourceType) and tryRenderTooltipHyperlink(itemLink) then
            return true
        end
        local bareLink = "item:" .. tostring(itemID)
        if isValidTooltipLinkForSource(bareLink, sourceType) and tryRenderTooltipHyperlink(bareLink) then
            return true
        end
        requestItemData(itemID)
        return false
    end

    local sourceType = getEntrySourceType(entry)
    local specID = row._specID or BISOverlay.selectedSpecID or getPlayerSpecID()
    if isOverlayItemTooltipEnabled() and sourceType == "mythicplus" then
        tooltip:SetOwner(owner, "ANCHOR_CURSOR_RIGHT")
        local snapshot = getMythPreviewSnapshot(row.itemID)
        if snapshot and tryRenderTooltipSnapshot(snapshot) then
            tooltip:AddLine(" ")
            appendCompactSeasonTooltipMeta()
            tooltip:AddLine(" ")
            tooltip:AddLine(ns.L("bis_tooltip_open_journal"), 0.35, 0.85, 1.00, true)
            ns.UI.Widgets.ApplyTooltip(tooltip, 13, 12, { preserveColors = true })
            tooltip:Show()
            return
        end
        showSeasonFallbackTooltip()
        return
    end

    if isBISItemOwned(specID, row.itemID) then
        local ownedItemLink = ns.DB and ns.DB.GetBISOverlayOwnedItemLink
            and ns.DB:GetBISOverlayOwnedItemLink(specID, row.itemID)
            or nil
        tooltip:SetOwner(owner, "ANCHOR_CURSOR_RIGHT")
        if isMatchingItemLink(ownedItemLink, row.itemID) and tryRenderTooltipHyperlink(ownedItemLink) then
            ns.UI.Widgets.ApplyTooltip(tooltip, 13, 12, { preserveColors = true })
            tooltip:Show()
            return
        end
    end

    if not isOverlayItemTooltipEnabled() then
        showSeasonFallbackTooltip()
        return
    end

    tooltip:SetOwner(owner, "ANCHOR_CURSOR_RIGHT")

    local shown = tryShowTooltipItemID(row.itemID, sourceType)
    if not shown then
        showSeasonFallbackTooltip()
        return
    end

    tooltip:AddLine(" ")
    appendCompactSeasonTooltipMeta()
    if sourceType == "mythicplus" or sourceType == "raid" then
        tooltip:AddLine(" ")
        tooltip:AddLine(ns.L("bis_tooltip_open_journal"), 0.35, 0.85, 1.00, true)
    end
    ns.UI.Widgets.ApplyTooltip(tooltip, 13, 12, { preserveColors = true })
    tooltip:Show()
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
    local sourceLeft = COL_CONTROLS + COL_ICON + COL_NAME
    local sourceRight = sourceLeft + COL_SLOT
    return localX >= sourceLeft and localX <= sourceRight
end

local function rebuildContentPreservingScroll()
    BISOverlay._isItemLoadRebuild = true
    BISOverlay:RebuildContent()
end

local function createRowCheckButton(row, xOffset, titleKey, hintKey, toggleHandler)
    local button = CreateFrame("Button", nil, row, "BackdropTemplate")
    button:SetSize(CHECK_SIZE, CHECK_SIZE)
    button:SetPoint("LEFT", row, "LEFT", xOffset, 0)
    button:SetFrameLevel(row:GetFrameLevel() + 3)
    if button.SetBackdrop then
        button:SetBackdrop({
            bgFile   = "Interface\\Tooltips\\UI-Tooltip-Background",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true, tileSize = 8, edgeSize = 8,
            insets = { left = 2, right = 2, top = 2, bottom = 2 },
        })
        button:SetBackdropColor(0.04, 0.06, 0.10, 0.95)
    end
    button.checkFill = button:CreateTexture(nil, "BACKGROUND")
    button.checkFill:SetPoint("TOPLEFT", button, "TOPLEFT", 2, -2)
    button.checkFill:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -2, 2)
    button.checkMark = button:CreateTexture(nil, "OVERLAY", nil, 7)
    button.checkMark:SetTexture("Interface\\Buttons\\UI-CheckBox-Check")
    button.checkMark:SetSize(20, 20)
    button.checkMark:SetPoint("CENTER")
    button.checkMark:Hide()
    button:SetScript("OnClick", function()
        if row._entry and row.itemID then
            toggleHandler(row)
            rebuildContentPreservingScroll()
        end
    end)
    button:SetScript("OnEnter", function(self2)
        if isScrollTooltipSuppressed() then
            return
        end
        local tooltip = ns.UI.Widgets.GetTooltip()
        if not tooltip then
            return
        end
        tooltip:SetOwner(self2, "ANCHOR_RIGHT")
        tooltip:ClearLines()
        tooltip:AddLine(ns.L(titleKey), 1.00, 0.82, 0.44, true)
        tooltip:AddLine(ns.L(hintKey), 0.90, 0.92, 0.98, true)
        tooltip:Show()
    end)
    button:SetScript("OnLeave", ns.UI.Widgets.HideTooltip)
    updateRowCheckButtonVisual(button, false)
    button:Hide()
    return button
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

    row.nameStrike = row:CreateTexture(nil, "OVERLAY", nil, 7)
    row.nameStrike:SetHeight(2)
    row.nameStrike:SetColorTexture(0.92, 0.96, 1.00, 1.00)
    row.nameStrike:Hide()

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

    row.favoriteBtn = createRowCheckButton(
        row,
        0,
        "bis_row_favorite",
        "bis_row_favorite_hint",
        function(targetRow)
            local specID = targetRow._specID or BISOverlay.selectedSpecID or getPlayerSpecID()
            if ns.DB and ns.DB.SetBISOverlayItemFavorite then
                ns.DB:SetBISOverlayItemFavorite(specID, targetRow.itemID, not isBISItemFavorite(specID, targetRow.itemID))
            end
        end
    )
    row.ownedBtn = createRowCheckButton(
        row,
        COL_FAVORITE,
        "bis_row_owned",
        "bis_row_owned_hint",
        function(targetRow)
            local specID = targetRow._specID or BISOverlay.selectedSpecID or getPlayerSpecID()
            if ns.DB and ns.DB.SetBISOverlayItemOwned then
                local owned = not isBISItemOwned(specID, targetRow.itemID)
                local itemLink = owned and findPlayerItemLink(targetRow.itemID) or nil
                ns.DB:SetBISOverlayItemOwned(specID, targetRow.itemID, owned, itemLink)
                if owned and itemLink then
                    cacheMythPreviewSnapshot(targetRow._entry, itemLink)
                end
            end
        end
    )

    row.tooltipRegion = CreateFrame("Button", nil, row)
    row.tooltipRegion:SetAllPoints(row)
    row.tooltipRegion:SetFrameLevel(row:GetFrameLevel() + 1)
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
    row.tooltipRegion:SetScript("OnEnter", function(self2)
        if row._entry and not isScrollTooltipSuppressed() then
            showSeasonItemTooltip(self2, row)
        end
    end)
    row.tooltipRegion:SetScript("OnLeave", hideBISTooltip)

    frame.rows[index] = row
    return row
end

local function resetRow(row)
    row.bg:SetColorTexture(0, 0, 0, 0)
    row.accent:SetColorTexture(0, 0, 0, 0)
    row.icon:Hide()
    row.nameStrike:Hide()
    row.slotLabel:Hide()
    row.noteLabel:Hide()
    row.typeLabel:Hide()
    row.favoriteBtn:Hide()
    row.ownedBtn:Hide()
    row.itemID = nil
    row._entry = nil
    row._specID = nil
    row._sectionDungeon = nil
    row._displayNoteKind = nil
    row._displayNoteIndex = nil
end

function BISOverlay:RefreshVisibleItemRows(itemIDs)
    local frame = self.frame
    if not frame or not frame.rows then
        return false
    end

    local refreshed = false
    for _, row in ipairs(frame.rows) do
        if row:IsShown() and row.itemID and row.itemID > 0
        and (not itemIDs or itemIDs[row.itemID]) then
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
        frame.noticeText:SetText(getSpecPolicySummary(specID))
    end
    if frame.avgLabel then
        frame.avgLabel:SetText(ns.L("bis_overlay_avg_label", avgIlvl > 0 and tostring(avgIlvl) or "?"))
    end
    if frame.updateBISItemTooltipVisual then
        frame.updateBISItemTooltipVisual()
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
        local slots, order = groupBySlot(filteredData, specID)
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
                iRow._specID = specID
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
                iRow.favoriteBtn:Show()
                iRow.ownedBtn:Show()

                -- 출처 라벨
                local sourceLabel = getDisplaySourceLabel(entry)
                if slotName == FAVORITES_SLOT and sourceLabel and sourceLabel ~= "" then
                    sourceLabel = localizeSlot(entry.slot) .. " · " .. sourceLabel
                end
                if sourceLabel and sourceLabel ~= "" then
                    iRow.slotLabel:ClearAllPoints()
                    iRow.slotLabel:SetPoint("LEFT", iRow, "LEFT", COL_CONTROLS + COL_ICON + COL_NAME, 0)
                    iRow.slotLabel:SetWidth(COL_SLOT)
                    iRow.slotLabel:SetFont(FONT_PATH, 10, FONT_FLAGS)
                    iRow.slotLabel:SetTextColor(0.72, 0.72, 0.72, 1)
                    iRow.slotLabel:SetText(sourceLabel)
                    iRow.slotLabel:Show()
                end

                local sourceType = getEntrySourceType(entry)
                local sr, sg, sb = getSourceTypeColor(sourceType)
                iRow.typeLabel:ClearAllPoints()
                iRow.typeLabel:SetPoint("LEFT", iRow, "LEFT", COL_CONTROLS + COL_ICON + COL_NAME + COL_SLOT, 0)
                iRow.typeLabel:SetWidth(COL_TYPE)
                iRow.typeLabel:SetFont(FONT_PATH, 9, FONT_FLAGS)
                iRow.typeLabel:SetTextColor(sr, sg, sb, 1)
                iRow.typeLabel:SetText(getEntryTrackStatusLabel(entry))
                iRow.typeLabel:Show()

                -- note 배지
                local noteTxt = noteBadge(entry._displayNoteKind, entry._displayNoteIndex)
                if noteTxt and noteTxt ~= "" then
                    iRow.noteLabel:ClearAllPoints()
                    iRow.noteLabel:SetPoint("LEFT", iRow, "LEFT",
                        COL_CONTROLS + COL_ICON + COL_NAME + COL_SLOT + COL_TYPE, 0)
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
    if scheduleAutomaticRuntimeScores then
        scheduleAutomaticRuntimeScores(filteredData, specID)
    end

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
    self.frame:SetScale(getOverlayScale())
    self:ApplyCollapse()

    -- 앵커 대상이 바뀌었을 때만 ClearAllPoints/SetPoint 호출 (깜박임 방지)
    local config = getOverlayConfig()
    local ilFrame = ns.UI.ItemLevelOverlay and ns.UI.ItemLevelOverlay.frame
    local useStoredPoint = (config.anchorMode or "itemlevel") == "overlay"
    local anchorTarget = (ilFrame and ilFrame:IsShown()) and ilFrame or pve
    if useStoredPoint then
        anchorTarget = nil
    end
    if self._lastAnchorTarget ~= anchorTarget or self._lastAnchorMode ~= (config.anchorMode or "itemlevel") then
        self._lastAnchorTarget = anchorTarget
        self._lastAnchorMode = config.anchorMode or "itemlevel"
        self.frame:ClearAllPoints()
        if useStoredPoint then
            self.frame:SetPoint(
                config.point or "CENTER",
                UIParent,
                config.relativePoint or "CENTER",
                config.x or 806,
                config.y or -100
            )
        elseif anchorTarget == ilFrame then
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
            self.frame.noticeText:SetText(getSpecPolicySummary(specID))
        end
        if self.frame.avgLabel then
            local avgIlvl = getAverageItemLevel()
            self.frame.avgLabel:SetText(ns.L("bis_overlay_avg_label", avgIlvl > 0 and tostring(avgIlvl) or "?"))
        end
        if self.frame.updateBISItemTooltipVisual then
            self.frame.updateBISItemTooltipVisual()
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
    if self._collapsed then
        self:ApplyCollapse()
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
