local _, ns = ...

local ProfessionKnowledgeOverlay = {}
ns.UI.ProfessionKnowledgeOverlay = ProfessionKnowledgeOverlay

local FONT_PATH = UNIT_NAME_FONT or STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF"
local TITLE_SIZE = 15
local SUMMARY_SIZE = 13
local DETAIL_SIZE = 12
local MIN_WIDTH = 240
local MIN_HEIGHT = 56
local PADDING_X = 6
local PADDING_Y = 6
local ROW_GAP = 8
local ICON_SIZE = 18

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

local function isCollapsed()
    local config = getOverlayConfig()
    return config.collapsed and true or false
end

local function setCollapsed(collapsed)
    local config = getOverlayConfig()
    config.collapsed = collapsed and true or false
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
        setCollapsed(not isCollapsed())
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

function ProfessionKnowledgeOverlay:RefreshRow(row, professionEntry, collapsed, contentWidth)
    local tracker = ns.Modules.ProfessionKnowledgeTracker
    local summary = tracker:GetProfessionSummary(professionEntry.key)
    local sections = tracker:GetProfessionSections(professionEntry.key)
    local weeklyRows = sections[1] and sections[1].rows or {}
    local oneTimeRows = sections[2] and sections[2].rows or {}

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

    row.summary:SetText(collapsed and compactLine ~= "" and compactLine or totalSummary)

    row.weeklyDetails:SetWidth(math.max(contentWidth - ICON_SIZE - 8, 120))
    row.oneTimeDetails:SetWidth(math.max(contentWidth - ICON_SIZE - 8, 120))
    row.weeklyDetails:SetText(ns.L("professions_overlay_detail_weekly", weeklyLine ~= "" and weeklyLine or ns.L("no_items")))
    row.oneTimeDetails:SetText(ns.L("professions_overlay_detail_onetime", oneTimeLine ~= "" and oneTimeLine or ns.L("no_items")))

    row.weeklyDetails:SetShown(not collapsed)
    row.oneTimeDetails:SetShown(not collapsed)
    row.lineBreak:SetShown(not collapsed)

    local rowHeight = math.max(
        ICON_SIZE,
        math.ceil(row.title:GetStringHeight() or SUMMARY_SIZE) +
            2 +
            math.ceil(row.summary:GetStringHeight() or SUMMARY_SIZE)
    )

    if not collapsed then
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

    local collapsed = isCollapsed()
    self.frame.title:SetText(ns.L("professions_overlay_title"))
    self.frame.toggleButton:SetText(ns.L(collapsed and "professions_overlay_expand" or "professions_overlay_collapse"))

    self:EnsureRowCount(#professions)

    local contentWidth = 860
    local maxWidth = math.ceil(self.frame.title:GetStringWidth() or 0) + 72
    local previous = self.frame.title
    local totalHeight = (PADDING_Y * 2) + math.ceil(self.frame.title:GetStringHeight() or TITLE_SIZE)

    for index, professionEntry in ipairs(professions) do
        local row = self.rows[index]
        row:ClearAllPoints()
        row:SetPoint("TOPLEFT", previous, "BOTTOMLEFT", 0, -ROW_GAP)
        self:RefreshRow(row, professionEntry, collapsed, contentWidth)

        local widest = math.max(
            math.ceil(row.title:GetStringWidth() or 0) + ICON_SIZE + 8,
            math.ceil(row.summary:GetStringWidth() or 0) + ICON_SIZE + 8
        )
        if not collapsed then
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

    local width = math.max(MIN_WIDTH, math.min(maxWidth + (PADDING_X * 2) + 18, collapsed and 760 or 920))
    self.frame:SetSize(width, math.max(MIN_HEIGHT, totalHeight))
    self.frame:Show()
end
