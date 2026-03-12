local _, ns = ...

local ProfessionKnowledgeOverlay = {}
ns.UI.ProfessionKnowledgeOverlay = ProfessionKnowledgeOverlay

local FONT_PATH = UNIT_NAME_FONT or STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF"
local TITLE_SIZE = 15
local SUMMARY_SIZE = 13
local DETAIL_SIZE = 12
local MIN_WIDTH = 240
local MIN_HEIGHT = 56
local MINI_WIDTH = 190
local MINI_HEIGHT = 34
local PADDING_X = 6
local PADDING_Y = 6
local ROW_GAP = 8
local ICON_SIZE = 18
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

local function getButtonTextWidth(button)
    if not button or type(button.GetFontString) ~= "function" then
        return 0
    end

    local fontString = button:GetFontString()
    return fontString and math.ceil(fontString:GetStringWidth() or 0) or 0
end

local function getOverlayConfig()
    return ns.DB and ns.DB:GetProfessionKnowledgeOverlayConfig() or ns.Data.Defaults.ui.professionKnowledgeOverlay
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

local function getSourceShortLabel(row)
    local key = row and row.key and OVERLAY_LABEL_KEYS[row.key]
    if key then
        return ns.L(key)
    end

    return row and row.title or ""
end

local function buildRowFragments(rows, limit)
    local fragments = {}
    local maxRows = math.min(#(rows or {}), limit or #(rows or {}))
    for index = 1, maxRows do
        local row = rows[index]
        fragments[#fragments + 1] = string.format("%s %d/%d", getSourceShortLabel(row), row.earned or 0, row.maxPoints or 0)
    end

    return table.concat(fragments, "  |  ")
end

function ProfessionKnowledgeOverlay:Initialize()
    if self.frame then
        return
    end

    local config = getOverlayConfig()
    local frame = CreateFrame("Frame", "ABPM_ProfessionKnowledgeOverlay", UIParent)
    frame:SetPoint(config.point or "CENTER", UIParent, config.relativePoint or "CENTER", config.x or 0, config.y or 0)
    frame:SetSize(MIN_WIDTH, MIN_HEIGHT)
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
    frame.toggleButton:SetSize(62, 20)
    frame.toggleButton:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -PADDING_X, -PADDING_Y + 1)
    frame.toggleButton:SetScript("OnClick", function()
        setDisplayMode(getNextDisplayMode(getDisplayMode()))
        self:Refresh()
    end)

    self.rows = {}
    self.frame = frame
    frame:Hide()
end

function ProfessionKnowledgeOverlay:CreateRow()
    local row = CreateFrame("Frame", nil, self.frame)
    row:SetSize(MIN_WIDTH - (PADDING_X * 2), 24)

    row.icon = row:CreateTexture(nil, "OVERLAY")
    row.icon:SetSize(ICON_SIZE, ICON_SIZE)
    row.icon:SetPoint("TOPLEFT", row, "TOPLEFT", 0, 0)

    row.title = row:CreateFontString(nil, "OVERLAY")
    row.title:SetPoint("TOPLEFT", row.icon, "TOPRIGHT", 6, 0)
    applyTextStyle(row.title, SUMMARY_SIZE, 1.00, 0.86, 0.42)

    row.summary = row:CreateFontString(nil, "OVERLAY")
    row.summary:SetPoint("TOPLEFT", row.title, "BOTTOMLEFT", 0, -2)
    applyTextStyle(row.summary, SUMMARY_SIZE, 0.90, 0.96, 1.00)

    row.weeklyDetails = row:CreateFontString(nil, "OVERLAY")
    row.weeklyDetails:SetPoint("TOPLEFT", row.summary, "BOTTOMLEFT", 0, -3)
    applyTextStyle(row.weeklyDetails, DETAIL_SIZE, 0.70, 0.92, 1.00)

    row.oneTimeDetails = row:CreateFontString(nil, "OVERLAY")
    row.oneTimeDetails:SetPoint("TOPLEFT", row.weeklyDetails, "BOTTOMLEFT", 0, -2)
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

        compactLine = table.concat(parts, "  |  ")
    end

    row.summary:SetText(displayMode == OVERLAY_MODE_COMPACT and compactLine ~= "" and compactLine or totalSummary)

    row.weeklyDetails:SetWidth(math.max(contentWidth - ICON_SIZE - 8, 120))
    row.oneTimeDetails:SetWidth(math.max(contentWidth - ICON_SIZE - 8, 120))
    row.weeklyDetails:SetText(ns.L("professions_overlay_detail_weekly", weeklyLine ~= "" and weeklyLine or ns.L("no_items")))
    row.oneTimeDetails:SetText(ns.L("professions_overlay_detail_onetime", oneTimeLine ~= "" and oneTimeLine or ns.L("no_items")))

    row.weeklyDetails:SetShown(expanded)
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
    self.frame.title:SetText(ns.L("professions_overlay_title"))
    self.frame.toggleButton:SetText(ns.L(getModeButtonLabelKey(displayMode)))

    if displayMode == OVERLAY_MODE_MINI then
        for _, row in ipairs(self.rows or {}) do
            row:Hide()
        end

        local titleWidth = math.ceil(self.frame.title:GetStringWidth() or 0)
        local buttonWidth = math.max(62, getButtonTextWidth(self.frame.toggleButton) + 18)
        self.frame.toggleButton:SetWidth(buttonWidth)
        self.frame:SetSize(math.max(MINI_WIDTH, titleWidth + buttonWidth + (PADDING_X * 4)), MINI_HEIGHT)
        self.frame:Show()
        return
    end

    self:EnsureRowCount(#professions)

    local contentWidth = 860
    local buttonWidth = math.max(62, getButtonTextWidth(self.frame.toggleButton) + 18)
    self.frame.toggleButton:SetWidth(buttonWidth)
    local maxWidth = math.ceil(self.frame.title:GetStringWidth() or 0) + buttonWidth + 18
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
                math.ceil(row.weeklyDetails:GetStringWidth() or 0) + ICON_SIZE + 8,
                math.ceil(row.oneTimeDetails:GetStringWidth() or 0) + ICON_SIZE + 8
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
