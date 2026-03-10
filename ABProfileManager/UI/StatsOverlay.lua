local _, ns = ...

local StatsOverlay = {}
ns.UI.StatsOverlay = StatsOverlay

local CRIT_RATING_INDEX = CR_CRIT_MELEE or CR_CRIT_SPELL or 11
local HASTE_RATING_INDEX = CR_HASTE_MELEE or CR_HASTE_SPELL or 18
local MASTERY_RATING_INDEX = CR_MASTERY or 26
local VERSATILITY_RATING_INDEX = CR_VERSATILITY_DAMAGE_DONE or 29

local BASE_ROW_GAP = 3
local PRIORITY_ROW_GAP = 5
local FRAME_PADDING_X = 2
local FRAME_PADDING_Y = 2
local VALUE_GAP = 6
local MIN_LABEL_WIDTH = 40
local MIN_FRAME_WIDTH = 220
local MIN_FRAME_HEIGHT = 82
local FONT_PATH = UNIT_NAME_FONT or STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF"
local NORMAL_LABEL_SIZE = 16
local NORMAL_VALUE_SIZE = 16
local PRIORITY_LABEL_SIZE = 15
local PRIORITY_VALUE_SIZE = 15
local FONT_FLAGS = "OUTLINE"
local SECONDARY_DR_FIRST_THRESHOLD = 30

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

local function formatStatValue(rating, percent)
    return string.format("%s(%s)", formatRating(rating), formatPercent(percent))
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
    if safeNumber(percentFromRating) >= SECONDARY_DR_FIRST_THRESHOLD then
        return 1
    end

    return 0
end

local function addRatedStat(snapshot, label, rating, percent, ratingPercent)
    snapshot[#snapshot + 1] = {
        label = label,
        value = formatStatValue(rating, percent),
        style = "stat",
        drTier = getSecondaryStatDRTier(ratingPercent),
    }
end

local function addPercentStat(snapshot, label, percent)
    if safeNumber(percent) <= 0 then
        return
    end

    snapshot[#snapshot + 1] = {
        label = label,
        value = formatPercent(percent),
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

    row.value = row:CreateFontString(nil, "OVERLAY")
    row.value:SetPoint("TOPLEFT", row.label, "TOPRIGHT", VALUE_GAP, 0)

    return row
end

function StatsOverlay:EnsureRowCount(count)
    self.rows = self.rows or {}

    while #self.rows < count do
        self.rows[#self.rows + 1] = self:CreateRow()
    end
end

function StatsOverlay:ApplyRowStyle(row, style, drTier)
    if style == "priority" then
        applyTextStyle(row.label, PRIORITY_LABEL_SIZE, 0.76, 0.94, 0.90)
        applyTextStyle(row.value, PRIORITY_VALUE_SIZE, 0.64, 0.96, 0.76)
        return
    end

    if style == "defense" then
        applyTextStyle(row.label, NORMAL_LABEL_SIZE, 0.78, 0.89, 1.00)
        applyTextStyle(row.value, NORMAL_VALUE_SIZE, 0.95, 0.98, 1.00)
        return
    end

    if (drTier or 0) > 0 then
        applyTextStyle(row.label, NORMAL_LABEL_SIZE, 1.00, 0.70, 0.70)
        applyTextStyle(row.value, NORMAL_VALUE_SIZE, 1.00, 0.38, 0.38)
        return
    end

    applyTextStyle(row.label, NORMAL_LABEL_SIZE, 0.92, 0.93, 0.95)
    applyTextStyle(row.value, NORMAL_VALUE_SIZE, 0.98, 0.97, 0.92)
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
        ns.L("stats_overlay_crit"),
        getCombatRating(CRIT_RATING_INDEX),
        type(GetCritChance) == "function" and safeNumber(GetCritChance()) or 0,
        getCombatRatingBonus(CRIT_RATING_INDEX)
    )
    addRatedStat(
        snapshot,
        ns.L("stats_overlay_haste"),
        getCombatRating(HASTE_RATING_INDEX),
        getHastePercent(),
        getCombatRatingBonus(HASTE_RATING_INDEX)
    )
    addRatedStat(
        snapshot,
        ns.L("stats_overlay_mastery"),
        getCombatRating(MASTERY_RATING_INDEX),
        getMasteryPercent(),
        getCombatRatingBonus(MASTERY_RATING_INDEX)
    )
    addRatedStat(
        snapshot,
        ns.L("stats_overlay_versatility"),
        getCombatRating(VERSATILITY_RATING_INDEX),
        getVersatilityPercent(),
        getCombatRatingBonus(VERSATILITY_RATING_INDEX)
    )

    local classTag = getCurrentClassTag()
    local specIndex = getCurrentSpecIndex()
    local specName = getCurrentSpecName(specIndex)

    if shouldShowTankDefensiveStats(specIndex) then
        addPercentStat(snapshot, ns.L("stats_overlay_dodge"), getDodgePercent())
        addPercentStat(snapshot, ns.L("stats_overlay_parry"), getParryPercent())
        addPercentStat(snapshot, ns.L("stats_overlay_block"), getBlockPercent())
    end

    local classBucket = classTag and ns.Data and ns.Data.StatPriorities and ns.Data.StatPriorities[classTag]
    local orderGroups = classBucket and specIndex and classBucket[specIndex] or nil
    local priorityLabel, priorityText = getPriorityDisplay(specName, orderGroups)

    snapshot[#snapshot + 1] = {
        label = priorityLabel,
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
    for index, entry in ipairs(snapshot) do
        local row = self.rows[index]
        labelWidth = math.max(labelWidth, math.ceil(row.label:GetStringWidth() or 0))
        if entry and entry.style == "priority" then
            labelWidth = math.max(labelWidth, math.ceil(row.label:GetStringWidth() or 0))
        end
    end

    local maxWidth = 0
    local totalHeight = FRAME_PADDING_Y * 2
    for index, entry in ipairs(snapshot) do
        local row = self.rows[index]
        row.label:SetWidth(labelWidth)
        row.value:ClearAllPoints()
        row.value:SetPoint("TOPLEFT", row.label, "TOPRIGHT", VALUE_GAP, 0)

        local rowWidth = labelWidth + VALUE_GAP + math.ceil(row.value:GetStringWidth() or 0)
        local rowHeight = math.max(
            math.ceil(row.label:GetStringHeight() or 0),
            math.ceil(row.value:GetStringHeight() or 0),
            18
        )

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
        row.label:SetText(entry.label or "")
        row.value:SetText(entry.value or "")
    end

    self:UpdateFrameSize(snapshot)
    self:LayoutRows(snapshot)
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
