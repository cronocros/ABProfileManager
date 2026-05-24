local _, ns = ...

local StatsOverlay = {}
ns.UI.StatsOverlay = StatsOverlay

local CRIT_RATING_INDEX = CR_CRIT_MELEE or CR_CRIT_SPELL or 11
local HASTE_RATING_INDEX = CR_HASTE_MELEE or CR_HASTE_SPELL or 18
local MASTERY_RATING_INDEX = CR_MASTERY or 26
local VERSATILITY_RATING_INDEX = CR_VERSATILITY_DAMAGE_DONE or 29

local BASE_ROW_GAP = 4
local HEADER_ROW_GAP = 8
local PRIORITY_ROW_GAP = 6
local FRAME_PADDING_X = 2
local FRAME_PADDING_Y = 2
local VALUE_GAP = 4
local MIN_LABEL_WIDTH = 38
local MIN_FRAME_WIDTH = 96
local MIN_FRAME_HEIGHT = 28
local FONT_PATH = UNIT_NAME_FONT or STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF"

-- BuildSnapshotSignature 재사용 버퍼: 매 호출마다 table 생성 방지
local _snapshotParts = {}
local _stateSignatureParts = {}
local _buffHashParts = {}
-- BuildSnapshot 재사용 버퍼: 매 Refresh 마다 snapshot/entry 테이블 생성 방지
local _snapshot = {}
local _entryPool = {}
local _entryPoolSize = 0
-- buildPriorityText 재사용 버퍼: 매 Refresh마다 labels/segments 테이블 생성 방지
local _priorityLabels = {}
local _prioritySegments = {}
-- getDisplayClassName 지연 캐시: 로케일 로드 후 첫 호출 시 1회만 생성
local _classLabels = nil

local function acquireEntry()
    _entryPoolSize = _entryPoolSize + 1
    local entry = _entryPool[_entryPoolSize]
    if entry then
        wipe(entry)
    else
        entry = {}
        _entryPool[_entryPoolSize] = entry
    end
    return entry
end
local HEADER_VALUE_SIZE = 15
local NORMAL_LABEL_SIZE = 16
local NORMAL_VALUE_SIZE = 16
local PRIORITY_LABEL_SIZE = 15
local PRIORITY_VALUE_SIZE = 15
local FONT_FLAGS = "OUTLINE"
local SECONDARY_DR_THRESHOLDS = { 30, 39, 47, 54, 66 }
local VALUE_PART_GAP = 4
local PAPERDOLL_TOOLTIP_SETTERS = {
    crit = "PaperDollFrame_SetCritChance",
    haste = "PaperDollFrame_SetHaste",
    mastery = "PaperDollFrame_SetMastery",
    versatility = "PaperDollFrame_SetVersatility",
    dodge = "PaperDollFrame_SetDodge",
    parry = "PaperDollFrame_SetParry",
    block = "PaperDollFrame_SetBlock",
}

local function getOverlayScale()
    return ns.DB and ns.DB:GetStatsOverlayScale() or 1
end

local function safeNumber(value)
    -- ns.Utils.SafeNumber 로 위임. fallback chain 으로 secret number 가 0 으로
    -- 깎이지 않도록 보호한다(전투 중 PaperDoll API 등이 secret 반환 시 부작용).
    if ns.Utils and ns.Utils.SafeNumber then
        return ns.Utils.SafeNumber(value)
    end
    -- Utils 미로드 시 폴백 (Core.lua 가 SafeCall 정의 시 호출되는 경우 등)
    local stripped = tonumber(tostring(value))
    if stripped then return stripped end
    if type(value) == "number" then return value end
    return tonumber(value) or 0
end

local function roundToInteger(value)
    return math.floor(safeNumber(value) + 0.5)
end

local function formatRating(value)
    local numeric = roundToInteger(value)
    if type(BreakUpLargeNumbers) == "function" then
        return BreakUpLargeNumbers(numeric)
    end

    return tostring(numeric)
end

local function formatPercent(value)
    return string.format("%.2f%%", safeNumber(value))
end

local function signaturePercent(value)
    return math.floor((safeNumber(value) * 100) + 0.5)
end

local function formatSplitStatPercent(value)
    local formatted = string.format("%.2f", safeNumber(value))
    local wholePart, decimalPart = formatted:match("^(%d+)%.(%d%d)$")
    return "(" .. (wholePart or "0"), "." .. (decimalPart or "00") .. "%)"
end

local function formatStatValueParts(rating)
    return formatRating(rating)
end

local function getCurrentSpecIndex()
    if type(GetSpecialization) ~= "function" then
        return nil
    end

    return GetSpecialization()
end

local function getCurrentSpecName(specIndex)
    if not specIndex or type(GetSpecializationInfo) ~= "function" then
        return nil
    end

    local specID, specName = GetSpecializationInfo(specIndex)
    return ns.SpecL(specID, specName)
end

local function getCurrentSpecRole(specIndex)
    if not specIndex or type(GetSpecializationRole) ~= "function" then
        return nil
    end

    return GetSpecializationRole(specIndex)
end

local function getCurrentCharacterName()
    if type(UnitName) ~= "function" then
        return nil
    end

    return UnitName("player")
end

local function getCurrentClassName()
    if type(UnitClass) ~= "function" then
        return nil
    end

    local _, classTag = UnitClass("player")
    return ns.ClassL(classTag)
end

local function getDisplayClassName(classTag)
    if not _classLabels then
        _classLabels = {
            DEATHKNIGHT = ns.L("stats_overlay_class_deathknight"),
            DEMONHUNTER = ns.L("stats_overlay_class_demonhunter"),
            DRUID       = ns.L("stats_overlay_class_druid"),
            EVOKER      = ns.L("stats_overlay_class_evoker"),
            HUNTER      = ns.L("stats_overlay_class_hunter"),
            MAGE        = ns.L("stats_overlay_class_mage"),
            MONK        = ns.L("stats_overlay_class_monk"),
            PALADIN     = ns.L("stats_overlay_class_paladin"),
            PRIEST      = ns.L("stats_overlay_class_priest"),
            ROGUE       = ns.L("stats_overlay_class_rogue"),
            SHAMAN      = ns.L("stats_overlay_class_shaman"),
            WARLOCK     = ns.L("stats_overlay_class_warlock"),
            WARRIOR     = ns.L("stats_overlay_class_warrior"),
        }
    end
    return _classLabels[classTag or ""] or getCurrentClassName() or "?"
end

local function getEquippedItemLevel()
    if type(GetAverageItemLevel) ~= "function" then
        return nil
    end

    local _, equippedItemLevel = GetAverageItemLevel()
    if not equippedItemLevel then
        return nil
    end

    return math.floor(safeNumber(equippedItemLevel) + 0.5)
end

local function getCurrentClassTag()
    if type(UnitClass) ~= "function" then
        return nil
    end

    local _, classTag = UnitClass("player")
    return classTag
end

local function buildIdentityText()
    local characterName = getCurrentCharacterName() or "?"
    local classTag = getCurrentClassTag()
    local className = getDisplayClassName(classTag)
    local specName = getCurrentSpecName(getCurrentSpecIndex()) or ns.L("stats_overlay_unknown_spec")
    local itemLevel = getEquippedItemLevel() or 0
    return ns.L("stats_overlay_identity_line", characterName, className, specName, itemLevel)
end

local function buildPriorityText(orderGroups)
    wipe(_prioritySegments)
    for _, group in ipairs(orderGroups or {}) do
        wipe(_priorityLabels)
        for _, statKey in ipairs(group) do
            _priorityLabels[#_priorityLabels + 1] = ns.L("stats_overlay_short_" .. statKey)
        end
        if #_priorityLabels > 0 then
            _prioritySegments[#_prioritySegments + 1] = table.concat(_priorityLabels, " = ")
        end
    end
    return table.concat(_prioritySegments, " > ")
end

local function getPriorityDisplay(specName, orderGroups)
    local label = specName or ns.L("stats_overlay_unknown_spec")
    local priority = orderGroups and buildPriorityText(orderGroups) or ns.L("stats_overlay_priority_unknown")
    return label, priority
end

local function getCombatRating(index)
    if type(GetCombatRating) ~= "function" then
        return 0
    end

    return safeNumber(GetCombatRating(index))
end

local function getCombatRatingBonus(index)
    if type(GetCombatRatingBonus) ~= "function" then
        return 0
    end

    return safeNumber(GetCombatRatingBonus(index))
end

local function getHastePercent()
    if type(GetHaste) == "function" then
        return safeNumber(GetHaste())
    end

    if type(GetMeleeHaste) == "function" then
        return safeNumber(GetMeleeHaste())
    end

    return 0
end

local function getMasteryPercent()
    if type(GetMasteryEffect) ~= "function" then
        return 0
    end

    return safeNumber(GetMasteryEffect())
end

local function getVersatilityPercent()
    local ratingBonus = getCombatRatingBonus(VERSATILITY_RATING_INDEX)

    if type(GetVersatilityBonus) ~= "function" then
        return ratingBonus
    end

    return ratingBonus + safeNumber(GetVersatilityBonus(VERSATILITY_RATING_INDEX))
end

local function getDodgePercent()
    if type(GetDodgeChance) ~= "function" then
        return 0
    end

    return safeNumber(GetDodgeChance())
end

local function getParryPercent()
    if type(GetParryChance) ~= "function" then
        return 0
    end

    return safeNumber(GetParryChance())
end

local function getBlockPercent()
    if type(GetBlockChance) ~= "function" then
        return 0
    end

    return safeNumber(GetBlockChance())
end

local function shouldShowTankDefensiveStats(specIndex)
    local tankStatsEnabled = not ns.DB or ns.DB:IsStatsOverlayTankStatsEnabled()
    return tankStatsEnabled and getCurrentSpecRole(specIndex) == "TANK"
end

-- 활성 버프 hash: 트링킷/사용효과/소모품 등 절대값 stat 변동을 signature에 포함시켜
-- BuildStateSignature 가 동일하더라도 buff state 가 바뀌면 즉시 갱신되도록 한다.
local function getPlayerBuffHash()
    wipe(_buffHashParts)
    if not C_UnitAuras or type(C_UnitAuras.GetAuraDataByIndex) ~= "function" then
        return ""
    end

    for index = 1, 40 do
        local fetchOk, data = pcall(C_UnitAuras.GetAuraDataByIndex, "player", index, "HELPFUL")
        if not fetchOk or not data then break end
        -- WoW 12.0.5+ 의 C_UnitAuras 반환 테이블은 secret number 로 표시되어
        -- 직접 산술 연산(*, math.floor 등) 시 taint 오류가 발생한다.
        -- safeNumber(tostring→tonumber)로 secret 플래그를 제거한 뒤 사용한다.
        -- 산술/포맷 자체도 pcall 로 감싸 한 aura 가 실패해도 다음 aura 처리는
        -- 계속되도록 격리한다.
        local formatOk, line = pcall(string.format,
            "%d:%d:%d",
            safeNumber(data.spellId),
            math.floor(safeNumber(data.expirationTime) * 10),
            safeNumber(data.applications)
        )
        if formatOk and line then
            _buffHashParts[#_buffHashParts + 1] = line
        end
    end

    return table.concat(_buffHashParts, "|")
end

local function isInsideInstanceContext()
    if type(IsInInstance) ~= "function" then
        return 0, ""
    end
    local ok, inInstance, instanceType = pcall(IsInInstance)
    if not ok then return 0, "" end
    return inInstance and 1 or 0, instanceType or ""
end

local function getSecondaryStatDRTier(percentFromRating)
    local normalized = safeNumber(percentFromRating)

    for index = #SECONDARY_DR_THRESHOLDS, 1, -1 do
        if normalized >= SECONDARY_DR_THRESHOLDS[index] then
            return index
        end
    end

    return 0
end

local function addRatedStat(snapshot, key, label, rating, percent, ratingPercent)
    local entry = acquireEntry()
    entry.key = key
    entry.label = label
    entry.primaryText = formatStatValueParts(rating)
    entry.style = "stat"
    entry.percentValue = safeNumber(percent)
    entry.ratingPercent = safeNumber(ratingPercent)
    entry.drTier = getSecondaryStatDRTier(ratingPercent)
    snapshot[#snapshot + 1] = entry
end

local function addPercentStat(snapshot, key, label, percent)
    if safeNumber(percent) <= 0 then
        return
    end

    local entry = acquireEntry()
    entry.key = key
    entry.label = label
    entry.secondaryText = formatPercent(percent)
    entry.style = "defense"
    snapshot[#snapshot + 1] = entry
end

-- applyTextStyle 옵션 테이블 사전 생성: 매 호출마다 3개 테이블 생성 방지
local _textStyleOptions = {
    domain = "statsOverlay",
    flags = FONT_FLAGS,
    shadowOffset = { 1, -1 },
    shadowColor = { 0, 0, 0, 0.9 },
}

local function applyTextStyle(fontString, size, r, g, b)
    ns.UI.Typography:ApplyFont(fontString, size, _textStyleOptions)
    fontString:SetTextColor(r, g, b, 1)
    fontString:SetJustifyH("LEFT")
    fontString:SetJustifyV("TOP")
    if fontString.SetWordWrap then
        fontString:SetWordWrap(false)
    end
end

local function applyPercentTextStyle(row, size, r, g, b)
    applyTextStyle(row.secondaryValue, size, r, g, b)
    applyTextStyle(row.percentTailValue, size, r, g, b)
    row.secondaryValue:SetJustifyH("RIGHT")
    row.percentTailValue:SetJustifyH("LEFT")
end

local function applyTooltipProxyFont(fontString, fontObject)
    if not fontString then
        return
    end

    local baseSize = fontObject == GameFontHighlight and 13 or 12
    ns.UI.Typography:ApplyFont(fontString, baseSize, { domain = "tooltip", transient = true })

    fontString:SetJustifyH("LEFT")
    fontString:SetJustifyV("TOP")
end

function StatsOverlay:CreateRow()
    local row = CreateFrame("Frame", nil, self.frame)
    row:SetSize(MIN_FRAME_WIDTH, 20)

    row.label = row:CreateFontString(nil, "OVERLAY")
    row.label:SetPoint("TOPLEFT", row, "TOPLEFT", 0, 0)

    row.primaryValue = row:CreateFontString(nil, "OVERLAY")
    row.primaryValue:SetPoint("TOPLEFT", row.label, "TOPRIGHT", VALUE_GAP, 0)

    row.secondaryValue = row:CreateFontString(nil, "OVERLAY")
    row.secondaryValue:SetPoint("TOPLEFT", row.primaryValue, "TOPRIGHT", VALUE_PART_GAP, 0)

    row.percentTailValue = row:CreateFontString(nil, "OVERLAY")
    row.percentTailValue:SetPoint("TOPLEFT", row.secondaryValue, "TOPRIGHT", 0, 0)

    row.tooltipRegion = CreateFrame("Frame", nil, row)
    row.tooltipRegion.ownerRow = row
    row.tooltipRegion:EnableMouse(true)
    row.tooltipRegion:RegisterForDrag("LeftButton")
    row.tooltipRegion:SetScript("OnDragStart", function()
        if self.frame and not (ns.DB and ns.DB:IsStatsOverlayLocked()) then
            self.frame:StartMoving()
        end
    end)
    row.tooltipRegion:SetScript("OnDragStop", function()
        if not self.frame then
            return
        end

        self.frame:StopMovingOrSizing()
        if ns.DB then
            ns.DB:SaveStatsOverlayPosition(self.frame)
        end
    end)

    row.tooltipRegion:SetScript("OnEnter", function(currentRegion)
        self:ShowRowTooltip(currentRegion.ownerRow or currentRegion)
    end)
    row.tooltipRegion:SetScript("OnLeave", ns.UI.Widgets.HideTooltip)

    return row
end

function StatsOverlay:EnsureRowCount(count)
    self.rows = self.rows or {}

    while #self.rows < count do
        self.rows[#self.rows + 1] = self:CreateRow()
    end
end

function StatsOverlay:ApplyRowStyle(row, style, drTier)
    row.label:Show()
    applyTextStyle(row.label, NORMAL_LABEL_SIZE, 0.92, 0.93, 0.95)
    applyTextStyle(row.primaryValue, NORMAL_VALUE_SIZE, 0.98, 0.97, 0.92)
    applyPercentTextStyle(row, NORMAL_VALUE_SIZE, 0.98, 0.97, 0.92)
    row.primaryValue:SetJustifyH("RIGHT")

    if style == "header" then
        row.label:Hide()
        applyTextStyle(row.secondaryValue, HEADER_VALUE_SIZE, 0.80, 0.97, 1.00)
        row.secondaryValue:SetJustifyH("LEFT")
        return
    end

    if style == "priority" then
        applyTextStyle(row.label, PRIORITY_LABEL_SIZE, 0.78, 0.96, 0.92)
        applyTextStyle(row.secondaryValue, PRIORITY_VALUE_SIZE, 0.62, 0.94, 0.78)
        row.secondaryValue:SetJustifyH("LEFT")
        return
    end

    if style == "defense" then
        applyTextStyle(row.secondaryValue, NORMAL_VALUE_SIZE, 0.95, 0.98, 1.00)
        row.secondaryValue:SetJustifyH("LEFT")
        return
    end

    if drTier == 1 then
        applyPercentTextStyle(row, NORMAL_VALUE_SIZE, 1.00, 0.68, 0.20)
        return
    end

    if drTier == 2 then
        applyPercentTextStyle(row, NORMAL_VALUE_SIZE, 1.00, 0.56, 0.16)
        return
    end

    if drTier == 3 then
        applyPercentTextStyle(row, NORMAL_VALUE_SIZE, 1.00, 0.44, 0.14)
        return
    end

    if drTier == 4 then
        applyPercentTextStyle(row, NORMAL_VALUE_SIZE, 1.00, 0.32, 0.16)
        return
    end

    if (drTier or 0) >= 5 then
        applyPercentTextStyle(row, NORMAL_VALUE_SIZE, 1.00, 0.20, 0.20)
        return
    end

    applyPercentTextStyle(row, NORMAL_VALUE_SIZE, 0.96, 0.76, 0.14)
end

function StatsOverlay:GetTooltipBody(entry)
    if not entry or not entry.key then
        return nil
    end

    local key = "stats_overlay_tooltip_" .. entry.key .. "_body"
    local text = ns.Locale:GetString(key)
    if text == key then
        return nil
    end

    return text
end

function StatsOverlay:GetTooltipProxyFrame()
    if self.tooltipProxyFrame then
        return self.tooltipProxyFrame
    end

    local frame = CreateFrame("Frame", nil, self.frame or UIParent)
    frame:SetSize(1, 1)
    frame:Hide()

    frame.Label = frame:CreateFontString(nil, "OVERLAY")
    frame.Value = frame:CreateFontString(nil, "OVERLAY")
    applyTooltipProxyFont(frame.Label, GameFontNormal)
    applyTooltipProxyFont(frame.Value, GameFontHighlight)

    self.tooltipProxyFrame = frame
    return frame
end

function StatsOverlay:GetMeasurementFontString()
    if self.measurementFontString then
        return self.measurementFontString
    end

    local measure = (self.frame or UIParent):CreateFontString(nil, "OVERLAY")
    measure:Hide()
    self.measurementFontString = measure
    return measure
end

function StatsOverlay:MeasureTextWidth(text, size)
    local measure = self:GetMeasurementFontString()
    ns.UI.Typography:ApplyFont(measure, size or NORMAL_VALUE_SIZE, {
        domain = "statsOverlay",
        flags = FONT_FLAGS,
        transient = true,
    })
    measure:SetText(text or "")
    return math.ceil(measure:GetStringWidth() or 0)
end

function StatsOverlay:PreparePaperDollTooltip(entry, owner)
    local setterName = entry and entry.key and PAPERDOLL_TOOLTIP_SETTERS[entry.key]
    local setter = setterName and _G[setterName]
    if type(setter) ~= "function" then
        return nil
    end

    local proxy = self:GetTooltipProxyFrame()
    proxy:ClearAllPoints()
    if owner then
        proxy:SetParent(owner)
        proxy:SetAllPoints(owner)
    else
        proxy:SetParent(self.frame or UIParent)
    end

    proxy.tooltip = nil
    proxy.tooltip2 = nil
    proxy.tooltip3 = nil
    proxy.onEnterFunc = nil
    proxy.UpdateTooltip = nil
    proxy.numericValue = nil
    applyTooltipProxyFont(proxy.Label, GameFontNormal)
    applyTooltipProxyFont(proxy.Value, GameFontHighlight)

    local ok = pcall(setter, proxy, "player")
    if not ok then
        return nil
    end
    return proxy
end

function StatsOverlay:GetTooltipTitle(entry)
    if not entry or not entry.key then
        return entry and entry.label or nil
    end

    local key = "stats_overlay_tooltip_" .. entry.key .. "_title"
    local text = ns.Locale:GetString(key)
    if text == key then
        return entry.label
    end

    return text
end

function StatsOverlay:ShowRowTooltip(row)
    local tooltip = ns.UI.Widgets.GetTooltip()
    if not row or not row.entry or not row.entry.key or not tooltip then
        return
    end

    self:PreparePaperDollTooltip(row.entry, row.tooltipRegion)

    local tooltipTitle = self:GetTooltipTitle(row.entry) or row.entry.label or ""
    if row.entry.key == "priority" then
        local modeLabel = row.entry.isMplus and ns.L("stats_priority_mode_mplus") or ns.L("stats_priority_mode_pve")
        tooltipTitle = tooltipTitle .. "  [" .. modeLabel .. "]"
    end

    tooltip:SetOwner(row.tooltipRegion or row, "ANCHOR_RIGHT")
    tooltip:SetText(tooltipTitle, 0.96, 0.82, 0.30)

    local body = self:GetTooltipBody(row.entry)
    if body then
        tooltip:AddLine(body, 1, 1, 1, true)
    end

    if row.entry.style == "stat" then
        local drKey = "stats_overlay_dr_tier_" .. tostring(row.entry.drTier or 0)
        local drText = ns.Locale:GetString(drKey)
        if drText ~= drKey then
            tooltip:AddLine(" ")
            tooltip:AddLine(ns.L("stats_overlay_tooltip_dr_line", drText, formatPercent(row.entry.ratingPercent or 0)), 0.84, 0.92, 1, true)
        end
    end

    ns.UI.Widgets.ApplyTooltip(tooltip, 13, 12)
    tooltip:Show()
end

function StatsOverlay:Initialize()
    if self.frame then
        return
    end

    local config = ns.DB and ns.DB:GetStatsOverlayConfig() or ns.Data.Defaults.ui.statsOverlay
    local frame = CreateFrame("Frame", "ABPM_StatsOverlay", UIParent)
    frame:SetPoint(config.point or "CENTER", UIParent, config.relativePoint or "CENTER", config.x or 0, config.y or 0)
    frame:SetSize(MIN_FRAME_WIDTH, MIN_FRAME_HEIGHT)
    frame:SetScale(getOverlayScale())
    frame:SetFrameStrata("MEDIUM")
    if frame.SetToplevel then
        frame:SetToplevel(false)
    end
    frame:SetClampedToScreen(true)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:EnableMouseWheel(true)
    frame:RegisterForDrag("LeftButton")
    if frame.SetHitRectInsets then
        frame:SetHitRectInsets(0, 0, 0, 0)
    end
    frame:SetScript("OnMouseWheel", function(currentFrame, delta)
        if not ns.DB then
            return
        end
        local newScale = ns.DB:SetStatsOverlayScale((ns.DB:GetStatsOverlayScale() or 1) + (delta * 0.05))
        currentFrame:SetScale(newScale)
    end)
    frame:SetScript("OnDragStart", function(currentFrame)
        if ns.DB and ns.DB:IsStatsOverlayLocked() then return end
        currentFrame:StartMoving()
    end)
    frame:SetScript("OnDragStop", function(currentFrame)
        currentFrame:StopMovingOrSizing()
        if ns.DB then
            ns.DB:SaveStatsOverlayPosition(currentFrame)
        end
    end)
    frame:SetScript("OnHide", function(currentFrame)
        currentFrame:StopMovingOrSizing()
    end)

    self.frame = frame
    self.rows = {}
    frame:Hide()
end

function StatsOverlay:BuildSnapshot()
    _entryPoolSize = 0
    wipe(_snapshot)
    local snapshot = _snapshot

    local headerEntry = acquireEntry()
    headerEntry.label = ""
    headerEntry.secondaryText = buildIdentityText()
    headerEntry.style = "header"
    snapshot[1] = headerEntry

    addRatedStat(
        snapshot,
        "crit",
        ns.L("stats_overlay_crit"),
        getCombatRating(CRIT_RATING_INDEX),
        type(GetCritChance) == "function" and safeNumber(GetCritChance()) or 0,
        getCombatRatingBonus(CRIT_RATING_INDEX)
    )
    addRatedStat(
        snapshot,
        "haste",
        ns.L("stats_overlay_haste"),
        getCombatRating(HASTE_RATING_INDEX),
        getHastePercent(),
        getCombatRatingBonus(HASTE_RATING_INDEX)
    )
    addRatedStat(
        snapshot,
        "mastery",
        ns.L("stats_overlay_mastery"),
        getCombatRating(MASTERY_RATING_INDEX),
        getMasteryPercent(),
        getCombatRatingBonus(MASTERY_RATING_INDEX)
    )
    addRatedStat(
        snapshot,
        "versatility",
        ns.L("stats_overlay_versatility"),
        getCombatRating(VERSATILITY_RATING_INDEX),
        getVersatilityPercent(),
        getCombatRatingBonus(VERSATILITY_RATING_INDEX)
    )

    for _, entry in ipairs(snapshot) do
        if entry.style == "stat" then
            entry.secondaryText, entry.percentTailText = formatSplitStatPercent(entry.percentValue)
        end
    end

    local classTag = getCurrentClassTag()
    local specIndex = getCurrentSpecIndex()
    local specName = getCurrentSpecName(specIndex)

    if shouldShowTankDefensiveStats(specIndex) then
        addPercentStat(snapshot, "dodge", ns.L("stats_overlay_dodge"), getDodgePercent())
        addPercentStat(snapshot, "parry", ns.L("stats_overlay_parry"), getParryPercent())
        addPercentStat(snapshot, "block", ns.L("stats_overlay_block"), getBlockPercent())
    end

    local manualMplus = ns.DB and ns.DB:IsStatsOverlayMythicPlusMode()
    local inChallengeMode = type(C_ChallengeMode) == "table"
        and type(C_ChallengeMode.IsChallengeModeActive) == "function"
        and C_ChallengeMode.IsChallengeModeActive()
    local isMplus = manualMplus or (inChallengeMode and true or false)
    local mplusBucket = isMplus and classTag and ns.Data and ns.Data.StatPrioritiesMythicPlus and ns.Data.StatPrioritiesMythicPlus[classTag]
    local classBucket = classTag and ns.Data and ns.Data.StatPriorities and ns.Data.StatPriorities[classTag]
    local orderGroups = (mplusBucket and mplusBucket[specIndex]) or (classBucket and classBucket[specIndex]) or nil
    local priorityLabel, priorityText = getPriorityDisplay(specName or ns.L("stats_overlay_unknown_spec"), orderGroups)

    local priorityEntry = acquireEntry()
    priorityEntry.label = priorityLabel
    priorityEntry.key = "priority"
    priorityEntry.value = priorityText
    priorityEntry.style = "priority"
    priorityEntry.spacingBefore = PRIORITY_ROW_GAP
    priorityEntry.isMplus = isMplus and true or false
    snapshot[#snapshot + 1] = priorityEntry

    for index = 2, #snapshot do
        if snapshot[index].style == "stat" then
            snapshot[index].spacingBefore = snapshot[index].spacingBefore or HEADER_ROW_GAP
            break
        end
    end

    return snapshot
end

function StatsOverlay:BuildStateSignature()
    wipe(_stateSignatureParts)

    local specIndex = getCurrentSpecIndex()
    local classTag = getCurrentClassTag() or ""
    local showTankStats = shouldShowTankDefensiveStats(specIndex)
    local typographyOffset = ns.DB and ns.DB.GetTypographyOffset and ns.DB:GetTypographyOffset("statsOverlay") or 0
    local language = ns.DB and ns.DB.GetLanguage and ns.DB:GetLanguage() or ""
    local _manualMplus = ns.DB and ns.DB.IsStatsOverlayMythicPlusMode and ns.DB:IsStatsOverlayMythicPlusMode()
    local _inChallengeMode = type(C_ChallengeMode) == "table"
        and type(C_ChallengeMode.IsChallengeModeActive) == "function"
        and C_ChallengeMode.IsChallengeModeActive()
    local isMplus = (_manualMplus or _inChallengeMode) and 1 or 0

    _stateSignatureParts[#_stateSignatureParts + 1] = tostring(language)
    _stateSignatureParts[#_stateSignatureParts + 1] = tostring(typographyOffset)
    _stateSignatureParts[#_stateSignatureParts + 1] = tostring(classTag)
    _stateSignatureParts[#_stateSignatureParts + 1] = tostring(specIndex or 0)
    _stateSignatureParts[#_stateSignatureParts + 1] = tostring(isMplus)
    _stateSignatureParts[#_stateSignatureParts + 1] = tostring(getEquippedItemLevel() or 0)
    _stateSignatureParts[#_stateSignatureParts + 1] = tostring(getCombatRating(CRIT_RATING_INDEX))
    _stateSignatureParts[#_stateSignatureParts + 1] = tostring(signaturePercent(GetCritChance and GetCritChance() or 0))
    _stateSignatureParts[#_stateSignatureParts + 1] = tostring(signaturePercent(getCombatRatingBonus(CRIT_RATING_INDEX)))
    _stateSignatureParts[#_stateSignatureParts + 1] = tostring(getCombatRating(HASTE_RATING_INDEX))
    _stateSignatureParts[#_stateSignatureParts + 1] = tostring(signaturePercent(getHastePercent()))
    _stateSignatureParts[#_stateSignatureParts + 1] = tostring(signaturePercent(getCombatRatingBonus(HASTE_RATING_INDEX)))
    _stateSignatureParts[#_stateSignatureParts + 1] = tostring(getCombatRating(MASTERY_RATING_INDEX))
    _stateSignatureParts[#_stateSignatureParts + 1] = tostring(signaturePercent(getMasteryPercent()))
    _stateSignatureParts[#_stateSignatureParts + 1] = tostring(signaturePercent(getCombatRatingBonus(MASTERY_RATING_INDEX)))
    _stateSignatureParts[#_stateSignatureParts + 1] = tostring(getCombatRating(VERSATILITY_RATING_INDEX))
    _stateSignatureParts[#_stateSignatureParts + 1] = tostring(signaturePercent(getVersatilityPercent()))
    _stateSignatureParts[#_stateSignatureParts + 1] = tostring(signaturePercent(getCombatRatingBonus(VERSATILITY_RATING_INDEX)))
    _stateSignatureParts[#_stateSignatureParts + 1] = tostring(showTankStats and signaturePercent(getDodgePercent()) or 0)
    _stateSignatureParts[#_stateSignatureParts + 1] = tostring(showTankStats and signaturePercent(getParryPercent()) or 0)
    _stateSignatureParts[#_stateSignatureParts + 1] = tostring(showTankStats and signaturePercent(getBlockPercent()) or 0)

    -- 인스턴스 컨텍스트(none/party/raid/pvp/scenario): 인던 진입/이탈 시 stale signature 방지
    local inInstance, instanceType = isInsideInstanceContext()
    _stateSignatureParts[#_stateSignatureParts + 1] = tostring(inInstance)
    _stateSignatureParts[#_stateSignatureParts + 1] = tostring(instanceType)

    -- 활성 버프 hash: 트링킷 사용효과/물약/외부 버프가 stat 절대값에 영향 줘도 즉시 갱신
    _stateSignatureParts[#_stateSignatureParts + 1] = getPlayerBuffHash()

    return table.concat(_stateSignatureParts, "\030")
end

-- 외부에서 캐시 무효화: 인던 진입/특성 변경/장비 교체 등 critical 시점에서 호출
function StatsOverlay:InvalidateState()
    self.lastStateSignature = nil
    self.lastSnapshotSignature = nil
end

function StatsOverlay:BuildSnapshotSignature(snapshot)
    wipe(_snapshotParts)

    for _, entry in ipairs(snapshot or {}) do
        _snapshotParts[#_snapshotParts + 1] = tostring(entry.style or "") .. "\030"
            .. tostring(entry.key or "") .. "\030"
            .. tostring(entry.label or "") .. "\030"
            .. tostring(entry.primaryText or "") .. "\030"
            .. tostring(entry.secondaryText or entry.value or "") .. "\030"
            .. tostring(entry.percentTailText or "") .. "\030"
            .. tostring(entry.drTier or "")
    end

    return table.concat(_snapshotParts, "\031")
end

function StatsOverlay:UpdateFrameSize(snapshot)
    if not self.frame or not self.rows then
        return
    end

    local labelWidth = MIN_LABEL_WIDTH
    local primaryColumnWidth = 0
    local secondaryColumnWidth = self:MeasureTextWidth("(100", NORMAL_VALUE_SIZE)
    local percentTailColumnWidth = self:MeasureTextWidth(".00%)", NORMAL_VALUE_SIZE)
    for index, entry in ipairs(snapshot) do
        local row = self.rows[index]
        if entry and entry.style ~= "header" then
            labelWidth = math.max(labelWidth, math.ceil(row.label:GetStringWidth() or 0))
        end
        if entry and entry.style == "stat" then
            primaryColumnWidth = math.max(primaryColumnWidth, math.ceil(row.primaryValue:GetStringWidth() or 0))
            secondaryColumnWidth = math.max(secondaryColumnWidth, math.ceil(row.secondaryValue:GetStringWidth() or 0))
            percentTailColumnWidth = math.max(percentTailColumnWidth, math.ceil(row.percentTailValue:GetStringWidth() or 0))
        end
        if entry and entry.style == "priority" then
            labelWidth = math.max(labelWidth, math.ceil(row.label:GetStringWidth() or 0))
        end
    end

    local maxWidth = 0
    local totalHeight = FRAME_PADDING_Y * 2
    for index, entry in ipairs(snapshot) do
        local row = self.rows[index]
        row.label:SetWidth(labelWidth)
        row.primaryValue:ClearAllPoints()
        row.secondaryValue:ClearAllPoints()
        row.percentTailValue:ClearAllPoints()

        local primaryWidth = 0
        local secondaryWidth = 0
        local rowWidth = 0

        if entry.style == "header" then
            row.label:SetWidth(0)
            row.primaryValue:Hide()
            row.primaryValue:SetWidth(0)
            row.percentTailValue:Hide()
            row.percentTailValue:SetWidth(0)
            row.secondaryValue:Show()
            row.secondaryValue:SetPoint("TOPLEFT", row, "TOPLEFT", 0, 0)
            row.secondaryValue:SetJustifyH("LEFT")
            secondaryWidth = math.ceil(row.secondaryValue:GetStringWidth() or 0)
            row.secondaryValue:SetWidth(math.max(secondaryWidth, 1))
            rowWidth = secondaryWidth
        elseif entry.style == "stat" then
            row.label:SetWidth(labelWidth)
            row.primaryValue:Show()
            row.secondaryValue:Show()
            row.percentTailValue:Show()
            row.primaryValue:SetPoint("TOPLEFT", row.label, "TOPRIGHT", VALUE_GAP, 0)
            row.secondaryValue:SetPoint("TOPLEFT", row.primaryValue, "TOPRIGHT", VALUE_PART_GAP, 0)
            row.percentTailValue:SetPoint("TOPLEFT", row.secondaryValue, "TOPRIGHT", 0, 0)
            row.primaryValue:SetWidth(primaryColumnWidth)
            row.secondaryValue:SetWidth(secondaryColumnWidth)
            row.percentTailValue:SetWidth(percentTailColumnWidth)
            row.primaryValue:SetJustifyH("RIGHT")
            row.secondaryValue:SetJustifyH("RIGHT")
            row.percentTailValue:SetJustifyH("LEFT")
            primaryWidth = primaryColumnWidth
            secondaryWidth = secondaryColumnWidth + percentTailColumnWidth
            rowWidth = labelWidth + VALUE_GAP + primaryWidth + VALUE_PART_GAP + secondaryWidth
        else
            row.label:SetWidth(labelWidth)
            row.primaryValue:Hide()
            row.primaryValue:SetWidth(0)
            row.secondaryValue:Show()
            row.percentTailValue:Hide()
            row.percentTailValue:SetWidth(0)
            row.secondaryValue:SetPoint("TOPLEFT", row.label, "TOPRIGHT", VALUE_GAP, 0)
            row.secondaryValue:SetJustifyH("LEFT")
            secondaryWidth = math.ceil(row.secondaryValue:GetStringWidth() or 0)
            row.secondaryValue:SetWidth(math.max(secondaryWidth, 1))
            rowWidth = labelWidth + VALUE_GAP + secondaryWidth
        end

        local rowHeight = math.max(
            math.ceil(row.label:GetStringHeight() or 0),
            math.ceil(row.primaryValue:GetStringHeight() or 0),
            math.ceil(row.secondaryValue:GetStringHeight() or 0),
            math.ceil(row.percentTailValue:GetStringHeight() or 0),
            18
        )

        row.tooltipRegion:ClearAllPoints()
        if entry.style == "header" or not entry.key then
            row.tooltipRegion:SetSize(0, 0)
            row.tooltipRegion:Hide()
        else
            row.tooltipRegion:SetPoint("TOPLEFT", row, "TOPLEFT", -1, 1)
            row.tooltipRegion:SetSize(math.max(rowWidth + 2, 1), rowHeight)
            row.tooltipRegion:Show()
        end

        row:SetSize(rowWidth, rowHeight)
        maxWidth = math.max(maxWidth, rowWidth)
        if index > 1 then
            totalHeight = totalHeight + (entry.spacingBefore or BASE_ROW_GAP)
        end
        totalHeight = totalHeight + rowHeight
    end

    self.frame:SetSize(math.max(MIN_FRAME_WIDTH, maxWidth + (FRAME_PADDING_X * 2)), math.max(MIN_FRAME_HEIGHT, totalHeight))
end

function StatsOverlay:LayoutRows(snapshot)
    local previousRow = nil

    for index, entry in ipairs(snapshot) do
        local row = self.rows[index]
        row:ClearAllPoints()
        if previousRow then
            row:SetPoint("TOPLEFT", previousRow, "BOTTOMLEFT", 0, -(entry.spacingBefore or BASE_ROW_GAP))
        else
            row:SetPoint("TOPLEFT", self.frame, "TOPLEFT", FRAME_PADDING_X, -FRAME_PADDING_Y)
        end

        row:Show()
        previousRow = row
    end

    for index = #snapshot + 1, #self.rows do
        self.rows[index]:Hide()
    end
end

function StatsOverlay:RefreshStats(force)
    if not self.frame then
        return
    end

    local stateSignature = self:BuildStateSignature()
    if not force and stateSignature == self.lastStateSignature then
        return
    end

    local snapshot = self:BuildSnapshot()
    local snapshotSignature = self:BuildSnapshotSignature(snapshot)
    if not force and snapshotSignature == self.lastSnapshotSignature then
        self.lastStateSignature = stateSignature
        return
    end

    self:EnsureRowCount(#snapshot)

    for index, entry in ipairs(snapshot) do
        local row = self.rows[index]
        self:ApplyRowStyle(row, entry.style, entry.drTier)
        row.entry = entry
        row.label:SetText(entry.label or "")
        row.primaryValue:SetText(entry.primaryText or "")
        row.secondaryValue:SetText(entry.secondaryText or entry.value or "")
        row.percentTailValue:SetText(entry.percentTailText or "")
    end

    self:UpdateFrameSize(snapshot)
    self:LayoutRows(snapshot)

    for index = #snapshot + 1, #self.rows do
        self.rows[index].entry = nil
        self.rows[index].percentTailValue:SetText("")
    end

    self.lastSnapshotSignature = snapshotSignature
    self.lastStateSignature = stateSignature
end

function StatsOverlay:Refresh(options)
    if not self.frame then
        self:Initialize()
    end

    local force = options and options.force or false
    if force then
        self:InvalidateState()
    end

    if not self.frame or not ns.DB or not ns.DB:IsStatsOverlayEnabled() then
        if self.frame then
            self.frame:Hide()
        end
        return
    end

    self.frame:SetScale(getOverlayScale())
    self:RefreshStats(force)
    self.frame:Show()
end
