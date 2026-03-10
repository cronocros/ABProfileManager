local _, ns = ...

local StatsOverlay = {}
ns.UI.StatsOverlay = StatsOverlay

local CRIT_RATING_INDEX = CR_CRIT_MELEE or CR_CRIT_SPELL or 11
local HASTE_RATING_INDEX = CR_HASTE_MELEE or CR_HASTE_SPELL or 18
local MASTERY_RATING_INDEX = CR_MASTERY or 26
local VERSATILITY_RATING_INDEX = CR_VERSATILITY_DAMAGE_DONE or 29

local BASE_ROW_GAP = 4
local PRIORITY_ROW_GAP = 6
local FRAME_PADDING_X = 2
local FRAME_PADDING_Y = 2
local VALUE_GAP = 4
local MIN_LABEL_WIDTH = 38
local MIN_FRAME_WIDTH = 220
local MIN_FRAME_HEIGHT = 82
local FONT_PATH = UNIT_NAME_FONT or STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF"
local NORMAL_LABEL_SIZE = 16
local NORMAL_VALUE_SIZE = 16
local PRIORITY_LABEL_SIZE = 15
local PRIORITY_VALUE_SIZE = 15
local FONT_FLAGS = "OUTLINE"
local SECONDARY_DR_THRESHOLDS = { 30, 39, 47, 54, 66 }
local VALUE_PART_GAP = 4

local function safeNumber(value)
    local numeric = tonumber(value) or 0
    if numeric < 0 then
        return 0
    end

    return numeric
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

local function formatStatValueParts(rating, percent)
    return formatRating(rating), string.format("(%s)", formatPercent(percent))
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

    local _, specName = GetSpecializationInfo(specIndex)
    return specName
end

local function getCurrentSpecRole(specIndex)
    if not specIndex or type(GetSpecializationRole) ~= "function" then
        return nil
    end

    return GetSpecializationRole(specIndex)
end

local function getCurrentClassTag()
    if type(UnitClass) ~= "function" then
        return nil
    end

    local _, classTag = UnitClass("player")
    return classTag
end

local function buildPriorityText(orderGroups)
    local segments = {}

    for _, group in ipairs(orderGroups or {}) do
        local labels = {}
        for _, statKey in ipairs(group) do
            labels[#labels + 1] = ns.L("stats_overlay_short_" .. statKey)
        end

        if #labels > 0 then
            segments[#segments + 1] = table.concat(labels, " = ")
        end
    end

    return table.concat(segments, " > ")
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
    return getCurrentSpecRole(specIndex) == "TANK"
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
    local ratingText, percentText = formatStatValueParts(rating, percent)
    snapshot[#snapshot + 1] = {
        key = key,
        label = label,
        primaryText = ratingText,
        secondaryText = percentText,
        style = "stat",
        ratingPercent = safeNumber(ratingPercent),
        drTier = getSecondaryStatDRTier(ratingPercent),
    }
end

local function addPercentStat(snapshot, key, label, percent)
    if safeNumber(percent) <= 0 then
        return
    end

    snapshot[#snapshot + 1] = {
        key = key,
        label = label,
        secondaryText = formatPercent(percent),
        style = "defense",
    }
end

local function applyTextStyle(fontString, size, r, g, b)
    fontString:SetFont(FONT_PATH, size, FONT_FLAGS)
    fontString:SetTextColor(r, g, b, 1)
    fontString:SetJustifyH("LEFT")
    fontString:SetJustifyV("TOP")
    if fontString.SetWordWrap then
        fontString:SetWordWrap(false)
    end
    if fontString.SetShadowOffset then
        fontString:SetShadowOffset(1, -1)
        fontString:SetShadowColor(0, 0, 0, 0.9)
    end
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

    row.tooltipRegion = CreateFrame("Frame", nil, row)
    row.tooltipRegion.ownerRow = row
    row.tooltipRegion:EnableMouse(true)
    row.tooltipRegion:RegisterForDrag("LeftButton")
    row.tooltipRegion:SetScript("OnDragStart", function()
        if self.frame then
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
    row.tooltipRegion:SetScript("OnLeave", function(currentRow)
        if GameTooltip and GameTooltip:IsOwned(currentRow) then
            GameTooltip:Hide()
        end
    end)

    return row
end

function StatsOverlay:EnsureRowCount(count)
    self.rows = self.rows or {}

    while #self.rows < count do
        self.rows[#self.rows + 1] = self:CreateRow()
    end
end

function StatsOverlay:ApplyRowStyle(row, style, drTier)
    applyTextStyle(row.label, NORMAL_LABEL_SIZE, 0.92, 0.93, 0.95)
    applyTextStyle(row.primaryValue, NORMAL_VALUE_SIZE, 0.98, 0.97, 0.92)
    applyTextStyle(row.secondaryValue, NORMAL_VALUE_SIZE, 0.98, 0.97, 0.92)
    row.primaryValue:SetJustifyH("RIGHT")
    row.secondaryValue:SetJustifyH("LEFT")

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
        applyTextStyle(row.secondaryValue, NORMAL_VALUE_SIZE, 1.00, 0.68, 0.20)
        return
    end

    if drTier == 2 then
        applyTextStyle(row.secondaryValue, NORMAL_VALUE_SIZE, 1.00, 0.56, 0.16)
        return
    end

    if drTier == 3 then
        applyTextStyle(row.secondaryValue, NORMAL_VALUE_SIZE, 1.00, 0.44, 0.14)
        return
    end

    if drTier == 4 then
        applyTextStyle(row.secondaryValue, NORMAL_VALUE_SIZE, 1.00, 0.32, 0.16)
        return
    end

    if (drTier or 0) >= 5 then
        applyTextStyle(row.secondaryValue, NORMAL_VALUE_SIZE, 1.00, 0.20, 0.20)
        return
    end

    applyTextStyle(row.secondaryValue, NORMAL_VALUE_SIZE, 0.96, 0.76, 0.14)
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
    if not row or not row.entry or not row.entry.key or not GameTooltip then
        return
    end

    GameTooltip:SetOwner(row.tooltipRegion or row, "ANCHOR_RIGHT")
    GameTooltip:SetText(self:GetTooltipTitle(row.entry) or row.entry.label or "", 0.96, 0.82, 0.30)

    local body = self:GetTooltipBody(row.entry)
    if body then
        GameTooltip:AddLine(body, 1, 1, 1, true)
    end

    if row.entry.style == "stat" then
        local drKey = "stats_overlay_dr_tier_" .. tostring(row.entry.drTier or 0)
        local drText = ns.Locale:GetString(drKey)
        if drText ~= drKey then
            GameTooltip:AddLine(" ")
            GameTooltip:AddLine(ns.L("stats_overlay_tooltip_dr_line", drText, formatPercent(row.entry.ratingPercent or 0)), 0.84, 0.92, 1, true)
        end
    end

    GameTooltip:Show()
end

function StatsOverlay:Initialize()
    if self.frame then
        return
    end

    local config = ns.DB and ns.DB:GetStatsOverlayConfig() or ns.Data.Defaults.ui.statsOverlay
    local frame = CreateFrame("Frame", "ABPM_StatsOverlay", UIParent)
    frame:SetPoint(config.point or "CENTER", UIParent, config.relativePoint or "CENTER", config.x or 0, config.y or 0)
    frame:SetSize(MIN_FRAME_WIDTH, MIN_FRAME_HEIGHT)
    frame:SetFrameStrata("HIGH")
    frame:SetClampedToScreen(true)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    if frame.SetHitRectInsets then
        frame:SetHitRectInsets(-8, -8, -6, -6)
    end
    frame:SetScript("OnDragStart", function(currentFrame)
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
    local snapshot = {}

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

    local classTag = getCurrentClassTag()
    local specIndex = getCurrentSpecIndex()
    local specName = getCurrentSpecName(specIndex)

    if shouldShowTankDefensiveStats(specIndex) then
        addPercentStat(snapshot, "dodge", ns.L("stats_overlay_dodge"), getDodgePercent())
        addPercentStat(snapshot, "parry", ns.L("stats_overlay_parry"), getParryPercent())
        addPercentStat(snapshot, "block", ns.L("stats_overlay_block"), getBlockPercent())
    end

    local classBucket = classTag and ns.Data and ns.Data.StatPriorities and ns.Data.StatPriorities[classTag]
    local orderGroups = classBucket and specIndex and classBucket[specIndex] or nil
    local priorityLabel, priorityText = getPriorityDisplay(specName, orderGroups)

    snapshot[#snapshot + 1] = {
        label = priorityLabel,
        key = "priority",
        value = priorityText,
        style = "priority",
        spacingBefore = PRIORITY_ROW_GAP,
    }

    return snapshot
end

function StatsOverlay:UpdateFrameSize(snapshot)
    if not self.frame or not self.rows then
        return
    end

    local labelWidth = MIN_LABEL_WIDTH
    local primaryColumnWidth = 0
    for index, entry in ipairs(snapshot) do
        local row = self.rows[index]
        labelWidth = math.max(labelWidth, math.ceil(row.label:GetStringWidth() or 0))
        if entry and entry.style == "stat" then
            primaryColumnWidth = math.max(primaryColumnWidth, math.ceil(row.primaryValue:GetStringWidth() or 0))
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

        local primaryWidth = 0
        local secondaryWidth = 0

        if entry.style == "stat" then
            row.primaryValue:Show()
            row.secondaryValue:Show()
            row.primaryValue:SetPoint("TOPLEFT", row.label, "TOPRIGHT", VALUE_GAP, 0)
            row.secondaryValue:SetPoint("TOPLEFT", row.primaryValue, "TOPRIGHT", VALUE_PART_GAP, 0)
            row.primaryValue:SetWidth(primaryColumnWidth)
            row.primaryValue:SetJustifyH("RIGHT")
            primaryWidth = primaryColumnWidth
            secondaryWidth = math.ceil(row.secondaryValue:GetStringWidth() or 0)
        else
            row.primaryValue:Hide()
            row.primaryValue:SetWidth(0)
            row.secondaryValue:Show()
            row.secondaryValue:SetPoint("TOPLEFT", row.label, "TOPRIGHT", VALUE_GAP, 0)
            secondaryWidth = math.ceil(row.secondaryValue:GetStringWidth() or 0)
        end

        local valueWidth = secondaryWidth
        if entry.style == "stat" then
            valueWidth = primaryWidth + VALUE_PART_GAP + secondaryWidth
        end

        local rowWidth = labelWidth + VALUE_GAP + valueWidth
        local rowHeight = math.max(
            math.ceil(row.label:GetStringHeight() or 0),
            math.ceil(row.primaryValue:GetStringHeight() or 0),
            math.ceil(row.secondaryValue:GetStringHeight() or 0),
            18
        )

        row.tooltipRegion:ClearAllPoints()
        if entry.style == "stat" then
            row.tooltipRegion:SetPoint("TOPLEFT", row.primaryValue, "TOPLEFT", -2, 1)
        else
            row.tooltipRegion:SetPoint("TOPLEFT", row.secondaryValue, "TOPLEFT", -2, 1)
        end
        row.tooltipRegion:SetSize(math.max(secondaryWidth, valueWidth) + 4, rowHeight)

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

function StatsOverlay:RefreshStats()
    if not self.frame then
        return
    end

    local snapshot = self:BuildSnapshot()
    self:EnsureRowCount(#snapshot)

    for index, entry in ipairs(snapshot) do
        local row = self.rows[index]
        self:ApplyRowStyle(row, entry.style, entry.drTier)
        row.entry = entry
        row.label:SetText(entry.label or "")
        row.primaryValue:SetText(entry.primaryText or "")
        row.secondaryValue:SetText(entry.secondaryText or entry.value or "")
    end

    self:UpdateFrameSize(snapshot)
    self:LayoutRows(snapshot)

    for index = #snapshot + 1, #self.rows do
        self.rows[index].entry = nil
    end
end

function StatsOverlay:Refresh()
    if not self.frame then
        self:Initialize()
    end

    if not self.frame or not ns.DB or not ns.DB:IsStatsOverlayEnabled() then
        if self.frame then
            self.frame:Hide()
        end
        return
    end

    self:RefreshStats()
    self.frame:Show()
end
