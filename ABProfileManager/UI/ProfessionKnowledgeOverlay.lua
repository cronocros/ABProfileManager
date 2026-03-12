local _, ns = ...

local ProfessionKnowledgeOverlay = {}
ns.UI.ProfessionKnowledgeOverlay = ProfessionKnowledgeOverlay

local FONT_PATH = UNIT_NAME_FONT or STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF"
local TITLE_SIZE = 15
local SUMMARY_SIZE = 12
local DETAIL_SIZE = 11
local MIN_WIDTH = 240
local MIN_HEIGHT = 56
local MINI_WIDTH = 190
local MINI_HEIGHT = 34
local TOGGLE_BUTTON_WIDTH = 18
local TOGGLE_BUTTON_HEIGHT = 16
local PADDING_X = 6
local PADDING_Y = 6
local ROW_GAP = 8
local ICON_SIZE = 18
local DETAIL_PREFIX_WIDTH = 46
local DETAIL_DIVIDER_WIDTH = 10
local OVERLAY_MODE_EXPANDED = "expanded"
local OVERLAY_MODE_COMPACT = "compact"
local OVERLAY_MODE_MINI = "mini"

local OVERLAY_LABEL_KEYS = {
    weekly_quest = "professions_overlay_short_weekly_quest",
    trainer_weekly = "professions_overlay_short_weekly_quest",
    weekly_drops = "professions_overlay_short_weekly_drops",
    weekly_gathering_drops = "professions_overlay_short_weekly_drops",
    disenchant_drops = "professions_overlay_short_weekly_drops",
    treatise = "professions_overlay_short_treatise",
    treasures = "professions_overlay_short_treasures",
    renown_reward = "professions_overlay_short_renown",
    abundance_reward = "professions_overlay_short_abundance",
    first_discoveries = "professions_overlay_short_discoveries",
}

local function applyTextStyle(fontString, size, r, g, b)
    fontString:SetFont(FONT_PATH, size, "OUTLINE")
    fontString:SetTextColor(r, g, b, 1)
    fontString:SetJustifyH("LEFT")
    fontString:SetJustifyV("TOP")
    if fontString.SetWordWrap then
        fontString:SetWordWrap(false)
    end
    if fontString.SetShadowOffset then
        fontString:SetShadowOffset(1, -1)
        fontString:SetShadowColor(0, 0, 0, 0.85)
    end
end

local function getOverlayConfig()
    return ns.DB and ns.DB:GetProfessionKnowledgeOverlayConfig() or ns.Data.Defaults.ui.professionKnowledgeOverlay
end

local function getOverlayScale()
    return ns.DB and ns.DB:GetProfessionKnowledgeOverlayScale() or 1
end

local function normalizeDisplayMode(mode, config)
    if mode == OVERLAY_MODE_EXPANDED or mode == OVERLAY_MODE_COMPACT or mode == OVERLAY_MODE_MINI then
        return mode
    end

    if config and config.collapsed then
        return OVERLAY_MODE_COMPACT
    end

    return OVERLAY_MODE_EXPANDED
end

local function getDisplayMode()
    local config = getOverlayConfig()
    return normalizeDisplayMode(config.displayMode, config)
end

local function setDisplayMode(mode)
    local config = getOverlayConfig()
    local normalized = normalizeDisplayMode(mode, config)
    config.displayMode = normalized
    config.collapsed = normalized ~= OVERLAY_MODE_EXPANDED
end

local function getNextDisplayMode(mode)
    if mode == OVERLAY_MODE_EXPANDED then
        return OVERLAY_MODE_COMPACT
    end

    if mode == OVERLAY_MODE_COMPACT then
        return OVERLAY_MODE_MINI
    end

    return OVERLAY_MODE_EXPANDED
end

local function getModeButtonLabelKey(mode)
    if mode == OVERLAY_MODE_EXPANDED then
        return "professions_overlay_mode_compact"
    end

    if mode == OVERLAY_MODE_COMPACT then
        return "professions_overlay_mode_mini"
    end

    return "professions_overlay_mode_expanded"
end

local function getModeButtonGlyph(mode)
    if mode == OVERLAY_MODE_EXPANDED then
        return "-"
    end

    if mode == OVERLAY_MODE_COMPACT then
        return "_"
    end

    return "+"
end

local function getSourceShortLabel(row)
    local key = row and row.key and OVERLAY_LABEL_KEYS[row.key]
    if key then
        return ns.L(key)
    end

    return row and row.title or ""
end

local function buildRowFragments(rows, limit)
    local fragments = {}
    local language = ns.DB and ns.DB.GetLanguage and ns.DB:GetLanguage() or nil
    local isKorean = language == (ns.Constants and ns.Constants.LANGUAGE and ns.Constants.LANGUAGE.KOREAN)
    local maxRows = math.min(#(rows or {}), limit or #(rows or {}))
    for index = 1, maxRows do
        local row = rows[index]
        if isKorean then
            fragments[#fragments + 1] = string.format("%s%d/%d", getSourceShortLabel(row), row.earned or 0, row.maxPoints or 0)
        else
            fragments[#fragments + 1] = string.format("%s %d/%d", getSourceShortLabel(row), row.earned or 0, row.maxPoints or 0)
        end
    end

    return table.concat(fragments, " | ")
end

local function appendTooltipSection(lines, title, rows)
    if #(rows or {}) == 0 then
        return
    end

    lines[#lines + 1] = ""
    lines[#lines + 1] = title
    for _, row in ipairs(rows or {}) do
        lines[#lines + 1] = string.format("• %s %d/%d · %d/%d", row.title or "", row.current or 0, row.max or 0, row.earned or 0, row.maxPoints or 0)
        for _, objective in ipairs(row.objectiveRows or {}) do
            local stateColor = objective.complete and "ff7fd46f" or "ffffd06b"
            local nameColor = objective.complete and "ff8f9aa4" or "ffece9d8"
            local stateLabel = objective.complete and ns.L("professions_overlay_tooltip_done") or ns.L("professions_overlay_tooltip_pending")
            lines[#lines + 1] = string.format(
                "  |cff%s%s|r |cff%s%s|r",
                stateColor,
                stateLabel,
                nameColor,
                objective.name or ""
            )
        end
    end
end

local function buildOverlayTooltipLines(professionEntry)
    local tracker = ns.Modules and ns.Modules.ProfessionKnowledgeTracker
    if not tracker or not professionEntry then
        return nil
    end

    local summary = tracker:GetProfessionSummary(professionEntry.key)
    local sections = tracker:GetProfessionSections(professionEntry.key)
    local lines = {
        tracker:GetProfessionDisplayName(professionEntry),
        ns.L(
            "professions_overlay_row",
            summary and summary.weeklyEarned or 0,
            summary and summary.weeklyMax or 0,
            summary and summary.oneTimeEarned or 0,
            summary and summary.oneTimeMax or 0
        ),
    }

    appendTooltipSection(lines, ns.L("professions_overlay_tooltip_weekly"), sections[1] and sections[1].rows or {})
    appendTooltipSection(lines, ns.L("professions_overlay_tooltip_onetime"), sections[2] and sections[2].rows or {})
    return lines
end

local function showRowTooltip(owner, lines)
    if not GameTooltip or type(lines) ~= "table" or #lines == 0 then
        return
    end

    GameTooltip:SetOwner(owner, "ANCHOR_RIGHT")
    GameTooltip:SetText(lines[1], 1, 0.86, 0.40)
    for index = 2, #lines do
        local line = lines[index]
        if line == "" then
            GameTooltip:AddLine(" ")
        else
            GameTooltip:AddLine(line, 0.92, 0.92, 0.88, true)
        end
    end
    GameTooltip:Show()
end

function ProfessionKnowledgeOverlay:Initialize()
    if self.frame then
        return
    end

    local config = getOverlayConfig()
    local frame = CreateFrame("Frame", "ABPM_ProfessionKnowledgeOverlay", UIParent)
    frame:SetPoint(config.point or "CENTER", UIParent, config.relativePoint or "CENTER", config.x or 0, config.y or 0)
    frame:SetSize(MIN_WIDTH, MIN_HEIGHT)
    frame:SetScale(getOverlayScale())
    frame:SetFrameStrata("HIGH")
    frame:SetClampedToScreen(true)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", function(currentFrame)
        currentFrame:StartMoving()
    end)
    frame:SetScript("OnDragStop", function(currentFrame)
        currentFrame:StopMovingOrSizing()
        if ns.DB then
            ns.DB:SaveProfessionKnowledgeOverlayPosition(currentFrame)
        end
    end)
    frame:SetScript("OnHide", function(currentFrame)
        currentFrame:StopMovingOrSizing()
    end)

    frame.title = frame:CreateFontString(nil, "OVERLAY")
    frame.title:SetPoint("TOPLEFT", frame, "TOPLEFT", PADDING_X, -PADDING_Y)
    applyTextStyle(frame.title, TITLE_SIZE, 1, 0.86, 0.40)

    frame.toggleButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    frame.toggleButton:SetSize(TOGGLE_BUTTON_WIDTH, TOGGLE_BUTTON_HEIGHT)
    frame.toggleButton:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -PADDING_X, -PADDING_Y + 1)
    frame.toggleButton:SetScript("OnClick", function()
        setDisplayMode(getNextDisplayMode(getDisplayMode()))
        self:Refresh()
    end)
    frame.toggleButton:SetScript("OnEnter", function(currentButton)
        if not GameTooltip then
            return
        end

        GameTooltip:SetOwner(currentButton, "ANCHOR_RIGHT")
        GameTooltip:SetText(ns.L("professions_overlay_toggle_tooltip", ns.L(getModeButtonLabelKey(getDisplayMode()))), 1, 0.86, 0.4)
        GameTooltip:Show()
    end)
    frame.toggleButton:SetScript("OnLeave", GameTooltip_Hide)
    if frame.toggleButton.GetFontString then
        local fontString = frame.toggleButton:GetFontString()
        if fontString then
            fontString:SetFont(FONT_PATH, 10, "OUTLINE")
            fontString:SetJustifyH("CENTER")
            fontString:SetJustifyV("MIDDLE")
        end
    end

    self.rows = {}
    self.frame = frame
    frame:Hide()
end

function ProfessionKnowledgeOverlay:CreateRow()
    local row = CreateFrame("Frame", nil, self.frame)
    row:SetSize(MIN_WIDTH - (PADDING_X * 2), 24)
    row:EnableMouse(true)
    row:RegisterForDrag("LeftButton")
    row:SetScript("OnDragStart", function()
        self.frame:StartMoving()
    end)
    row:SetScript("OnDragStop", function()
        self.frame:StopMovingOrSizing()
        if ns.DB then
            ns.DB:SaveProfessionKnowledgeOverlayPosition(self.frame)
        end
    end)
    row:SetScript("OnEnter", function(currentRow)
        if currentRow.tooltipLines then
            showRowTooltip(currentRow, currentRow.tooltipLines)
        end
    end)
    row:SetScript("OnLeave", GameTooltip_Hide)

    row.icon = row:CreateTexture(nil, "OVERLAY")
    row.icon:SetSize(ICON_SIZE, ICON_SIZE)
    row.icon:SetPoint("TOPLEFT", row, "TOPLEFT", 0, 0)

    row.title = row:CreateFontString(nil, "OVERLAY")
    row.title:SetPoint("TOPLEFT", row.icon, "TOPRIGHT", 6, 0)
    applyTextStyle(row.title, 13, 1.00, 0.86, 0.42)

    row.summary = row:CreateFontString(nil, "OVERLAY")
    row.summary:SetPoint("TOPLEFT", row.title, "BOTTOMLEFT", 0, -2)
    applyTextStyle(row.summary, SUMMARY_SIZE, 0.90, 0.96, 1.00)

    row.weeklyPrefix = row:CreateFontString(nil, "OVERLAY")
    row.weeklyPrefix:SetPoint("TOPLEFT", row.summary, "BOTTOMLEFT", 0, -4)
    row.weeklyPrefix:SetWidth(DETAIL_PREFIX_WIDTH)
    applyTextStyle(row.weeklyPrefix, DETAIL_SIZE, 0.98, 0.88, 0.52)
    row.weeklyPrefix:SetJustifyH("RIGHT")

    row.weeklyDivider = row:CreateFontString(nil, "OVERLAY")
    row.weeklyDivider:SetPoint("TOPLEFT", row.weeklyPrefix, "TOPRIGHT", 2, 0)
    row.weeklyDivider:SetWidth(DETAIL_DIVIDER_WIDTH)
    applyTextStyle(row.weeklyDivider, DETAIL_SIZE, 0.92, 0.84, 0.56)
    row.weeklyDivider:SetJustifyH("CENTER")

    row.weeklyDetails = row:CreateFontString(nil, "OVERLAY")
    row.weeklyDetails:SetPoint("TOPLEFT", row.weeklyDivider, "TOPRIGHT", 4, 0)
    applyTextStyle(row.weeklyDetails, DETAIL_SIZE, 0.70, 0.92, 1.00)

    row.oneTimePrefix = row:CreateFontString(nil, "OVERLAY")
    row.oneTimePrefix:SetPoint("TOPLEFT", row.weeklyPrefix, "BOTTOMLEFT", 0, -3)
    row.oneTimePrefix:SetWidth(DETAIL_PREFIX_WIDTH)
    applyTextStyle(row.oneTimePrefix, DETAIL_SIZE, 0.98, 0.88, 0.52)
    row.oneTimePrefix:SetJustifyH("RIGHT")

    row.oneTimeDivider = row:CreateFontString(nil, "OVERLAY")
    row.oneTimeDivider:SetPoint("TOPLEFT", row.oneTimePrefix, "TOPRIGHT", 2, 0)
    row.oneTimeDivider:SetWidth(DETAIL_DIVIDER_WIDTH)
    applyTextStyle(row.oneTimeDivider, DETAIL_SIZE, 0.92, 0.84, 0.56)
    row.oneTimeDivider:SetJustifyH("CENTER")

    row.oneTimeDetails = row:CreateFontString(nil, "OVERLAY")
    row.oneTimeDetails:SetPoint("TOPLEFT", row.oneTimeDivider, "TOPRIGHT", 4, 0)
    applyTextStyle(row.oneTimeDetails, DETAIL_SIZE, 0.74, 0.96, 0.80)

    row.lineBreak = row:CreateTexture(nil, "ARTWORK")
    row.lineBreak:SetHeight(1)
    row.lineBreak:SetColorTexture(1, 0.82, 0.40, 0.22)
    row.lineBreak:SetPoint("TOPLEFT", row.oneTimeDetails, "BOTTOMLEFT", 0, -5)
    row.lineBreak:SetPoint("TOPRIGHT", row, "TOPRIGHT", 0, -5)

    return row
end

function ProfessionKnowledgeOverlay:EnsureRowCount(count)
    while #self.rows < count do
        self.rows[#self.rows + 1] = self:CreateRow()
    end
end

function ProfessionKnowledgeOverlay:RefreshRow(row, professionEntry, displayMode, contentWidth)
    local tracker = ns.Modules.ProfessionKnowledgeTracker
    local summary = tracker:GetProfessionSummary(professionEntry.key)
    local sections = tracker:GetProfessionSections(professionEntry.key)
    local weeklyRows = sections[1] and sections[1].rows or {}
    local oneTimeRows = sections[2] and sections[2].rows or {}
    local expanded = displayMode == OVERLAY_MODE_EXPANDED
    local fullyComplete = summary
        and summary.weeklyMax > 0
        and summary.oneTimeMax > 0
        and summary.weeklyEarned >= summary.weeklyMax
        and summary.oneTimeEarned >= summary.oneTimeMax

    row.icon:SetTexture(professionEntry.icon or ns.Constants.DEFAULT_ICON)
    row.title:SetText(tracker:GetProfessionDisplayName(professionEntry))
    row.summary:SetWidth(math.max(contentWidth - ICON_SIZE - 8, 120))
    local totalSummary = ns.L(
        "professions_overlay_row",
        summary and summary.weeklyEarned or 0,
        summary and summary.weeklyMax or 0,
        summary and summary.oneTimeEarned or 0,
        summary and summary.oneTimeMax or 0
    )

    local weeklyLine = buildRowFragments(weeklyRows, 4)
    local oneTimeLine = buildRowFragments(oneTimeRows, 4)
    local compactLine = buildRowFragments(weeklyRows, 2)
    if oneTimeRows[1] then
        local parts = {}
        if compactLine ~= "" then
            parts[#parts + 1] = compactLine
        end

        local oneTimeCompact = buildRowFragments(oneTimeRows, 2)
        if oneTimeCompact ~= "" then
            parts[#parts + 1] = oneTimeCompact
        end

        compactLine = table.concat(parts, " | ")
    end

    row.summary:SetText(displayMode == OVERLAY_MODE_COMPACT and compactLine ~= "" and compactLine or totalSummary)
    if fullyComplete then
        row.title:SetTextColor(0.72, 1.00, 0.78, 1)
        row.summary:SetTextColor(0.70, 0.98, 0.80, 1)
    else
        row.title:SetTextColor(1.00, 0.86, 0.42, 1)
        row.summary:SetTextColor(0.90, 0.96, 1.00, 1)
    end

    local detailWidth = math.max(contentWidth - ICON_SIZE - 8 - DETAIL_PREFIX_WIDTH - DETAIL_DIVIDER_WIDTH - 6, 120)
    row.weeklyPrefix:SetText(ns.L("professions_weekly"))
    row.weeklyDivider:SetText("|")
    row.weeklyDetails:SetWidth(detailWidth)
    row.weeklyDetails:SetText(weeklyLine ~= "" and weeklyLine or ns.L("no_items"))
    row.oneTimePrefix:SetText(ns.L("professions_one_time"))
    row.oneTimeDivider:SetText("|")
    row.oneTimeDetails:SetWidth(detailWidth)
    row.oneTimeDetails:SetText(oneTimeLine ~= "" and oneTimeLine or ns.L("no_items"))
    row.tooltipLines = buildOverlayTooltipLines(professionEntry)

    row.weeklyPrefix:SetShown(expanded)
    row.weeklyDivider:SetShown(expanded)
    row.weeklyDetails:SetShown(expanded)
    row.oneTimePrefix:SetShown(expanded)
    row.oneTimeDivider:SetShown(expanded)
    row.oneTimeDetails:SetShown(expanded)
    row.lineBreak:SetShown(expanded)

    local rowHeight = math.max(
        ICON_SIZE,
        math.ceil(row.title:GetStringHeight() or SUMMARY_SIZE) +
            2 +
            math.ceil(row.summary:GetStringHeight() or SUMMARY_SIZE)
    )

    if expanded then
        rowHeight = rowHeight +
            3 +
            math.ceil(row.weeklyDetails:GetStringHeight() or DETAIL_SIZE) +
            2 +
            math.ceil(row.oneTimeDetails:GetStringHeight() or DETAIL_SIZE) +
            8
    end

    row:SetHeight(rowHeight)
    row:Show()
end

function ProfessionKnowledgeOverlay:Refresh()
    if not self.frame then
        self:Initialize()
    end

    if not self.frame or not ns.DB or not ns.DB:IsProfessionKnowledgeOverlayEnabled() then
        if self.frame then
            self.frame:Hide()
        end
        return
    end

    local professions = ns.Modules.ProfessionKnowledgeTracker:GetKnownProfessions()
    if #professions == 0 then
        self.frame:Hide()
        return
    end

    local displayMode = getDisplayMode()
    self.frame:SetScale(getOverlayScale())
    self.frame.title:SetText(ns.L("professions_overlay_title"))
    self.frame.toggleButton:SetText(getModeButtonGlyph(displayMode))

    if displayMode == OVERLAY_MODE_MINI then
        for _, row in ipairs(self.rows or {}) do
            row:Hide()
        end

        local titleWidth = math.ceil(self.frame.title:GetStringWidth() or 0)
        self.frame:SetSize(math.max(MINI_WIDTH, titleWidth + TOGGLE_BUTTON_WIDTH + (PADDING_X * 4)), MINI_HEIGHT)
        self.frame:Show()
        return
    end

    self:EnsureRowCount(#professions)

    local contentWidth = 860
    local maxWidth = math.ceil(self.frame.title:GetStringWidth() or 0) + TOGGLE_BUTTON_WIDTH + 18
    local previous = self.frame.title
    local totalHeight = (PADDING_Y * 2) + math.ceil(self.frame.title:GetStringHeight() or TITLE_SIZE)

    for index, professionEntry in ipairs(professions) do
        local row = self.rows[index]
        row:ClearAllPoints()
        row:SetPoint("TOPLEFT", previous, "BOTTOMLEFT", 0, -ROW_GAP)
        self:RefreshRow(row, professionEntry, displayMode, contentWidth)

        local widest = math.max(
            math.ceil(row.title:GetStringWidth() or 0) + ICON_SIZE + 8,
            math.ceil(row.summary:GetStringWidth() or 0) + ICON_SIZE + 8
        )
        if displayMode == OVERLAY_MODE_EXPANDED then
            widest = math.max(
                widest,
                DETAIL_PREFIX_WIDTH + DETAIL_DIVIDER_WIDTH + math.ceil(row.weeklyDetails:GetStringWidth() or 0) + ICON_SIZE + 12,
                DETAIL_PREFIX_WIDTH + DETAIL_DIVIDER_WIDTH + math.ceil(row.oneTimeDetails:GetStringWidth() or 0) + ICON_SIZE + 12
            )
        end

        maxWidth = math.max(maxWidth, widest)
        totalHeight = totalHeight + ROW_GAP + math.ceil(row:GetHeight() or 0)
        previous = row
    end

    for index = #professions + 1, #self.rows do
        self.rows[index]:Hide()
    end

    local width = math.max(
        MIN_WIDTH,
        math.min(maxWidth + (PADDING_X * 2) + 18, displayMode == OVERLAY_MODE_COMPACT and 760 or 920)
    )
    self.frame:SetSize(width, math.max(MIN_HEIGHT, totalHeight))
    self.frame:Show()
end
