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

    local _, specName = GetSpecializationInfo(specIndex)
    return specName
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

    local className = UnitClass("player")
    return className
end

local function getDisplayClassName(classTag)
    local classLabels = {
        DEATHKNIGHT = ns.L("stats_overlay_class_deathknight"),
        DEMONHUNTER = ns.L("stats_overlay_class_demonhunter"),
        DRUID = ns.L("stats_overlay_class_druid"),
        EVOKER = ns.L("stats_overlay_class_evoker"),
        HUNTER = ns.L("stats_overlay_class_hunter"),
        MAGE = ns.L("stats_overlay_class_mage"),
        MONK = ns.L("stats_overlay_class_monk"),
        PALADIN = ns.L("stats_overlay_class_paladin"),
        PRIEST = ns.L("stats_overlay_class_priest"),
        ROGUE = ns.L("stats_overlay_class_rogue"),
        SHAMAN = ns.L("stats_overlay_class_shaman"),
        WARLOCK = ns.L("stats_overlay_class_warlock"),
        WARRIOR = ns.L("stats_overlay_class_warrior"),
    }

    return classLabels[classTag or ""] or getCurrentClassName() or "?"
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
    local tankStatsEnabled = not ns.DB or ns.DB:IsStatsOverlayTankStatsEnabled()
    return tankStatsEnabled and getCurrentSpecRole(specIndex) == "TANK"
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
    snapshot[#snapshot + 1] = {
        key = key,
        label = label,
        primaryText = formatStatValueParts(rating),
        style = "stat",
        percentValue = safeNumber(percent),
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
    ns.UI.Typography:ApplyFont(fontString, size, {
        domain = "statsOverlay",
        flags = FONT_FLAGS,
        shadowOffset = { 1, -1 },
        shadowColor = { 0, 0, 0, 0.9 },
    })
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

    setter(proxy, "player")
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
    if not row or not row.entry or not row.entry.key or not GameTooltip then
        return
    end

    local proxy = self:PreparePaperDollTooltip(row.entry, row.tooltipRegion)
    if proxy then
        if type(PaperDollStatTooltip) == "function" and proxy.tooltip then
            PaperDollStatTooltip(proxy)
            return
        end

        if type(proxy.onEnterFunc) == "function" then
            proxy.onEnterFunc(proxy)
            return
        end
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

    ns.UI.Widgets.ApplyTooltip(GameTooltip, 13, 12)
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
    frame:SetScale(getOverlayScale())
    frame:SetFrameStrata("MEDIUM")
    if frame.SetToplevel then
        frame:SetToplevel(false)
    end
    frame:SetClampedToScreen(true)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    if frame.SetHitRectInsets then
        frame:SetHitRectInsets(0, 0, 0, 0)
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

    snapshot[#snapshot + 1] = {
        label = "",
        secondaryText = buildIdentityText(),
        style = "header",
    }

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

    local isMplus = ns.DB and ns.DB:IsStatsOverlayMythicPlusMode()
    local mplusBucket = isMplus and classTag and ns.Data and ns.Data.StatPrioritiesMythicPlus and ns.Data.StatPrioritiesMythicPlus[classTag]
    local classBucket = classTag and ns.Data and ns.Data.StatPriorities and ns.Data.StatPriorities[classTag]
    local orderGroups = (mplusBucket and mplusBucket[specIndex]) or (classBucket and classBucket[specIndex]) or nil
    local modePrefix = isMplus and ("[" .. ns.L("stats_priority_mode_mplus") .. "] ") or ""
    local priorityLabel, priorityText = getPriorityDisplay(modePrefix .. (specName or ns.L("stats_overlay_unknown_spec")), orderGroups)

    snapshot[#snapshot + 1] = {
        label = priorityLabel,
        key = "priority",
        value = priorityText,
        style = "priority",
        spacingBefore = PRIORITY_ROW_GAP,
    }

    for index = 2, #snapshot do
        if snapshot[index].style == "stat" then
            snapshot[index].spacingBefore = snapshot[index].spacingBefore or HEADER_ROW_GAP
            break
        end
    end

    return snapshot
end

function StatsOverlay:BuildSnapshotSignature(snapshot)
    local parts = {}

    for _, entry in ipairs(snapshot or {}) do
        parts[#parts + 1] = table.concat({
            tostring(entry.style or ""),
            tostring(entry.key or ""),
            tostring(entry.label or ""),
            tostring(entry.primaryText or ""),
            tostring(entry.secondaryText or entry.value or ""),
            tostring(entry.percentTailText or ""),
            tostring(entry.drTier or ""),
        }, "\030")
    end

    return table.concat(parts, "\031")
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

function StatsOverlay:RefreshStats()
    if not self.frame then
        return
    end

    local snapshot = self:BuildSnapshot()
    local snapshotSignature = self:BuildSnapshotSignature(snapshot)
    if snapshotSignature == self.lastSnapshotSignature then
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

    self.frame:SetScale(getOverlayScale())
    self:RefreshStats()
    self.frame:Show()
end
