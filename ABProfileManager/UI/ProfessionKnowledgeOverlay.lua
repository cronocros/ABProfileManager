local _, ns = ...

local ProfessionKnowledgeOverlay = {}
ns.UI.ProfessionKnowledgeOverlay = ProfessionKnowledgeOverlay

local FONT_PATH = UNIT_NAME_FONT or STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF"
local TITLE_SIZE = 16
local SUMMARY_SIZE = 13
local DETAIL_SIZE = 12
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
local DETAIL_PREFIX_WIDTH = 82
local DETAIL_DIVIDER_WIDTH = 12
local TOOLTIP_MIN_WIDTH = 420
local HOVER_PANEL_WIDTH = 276
local HOVER_PANEL_PADDING = 8
local HOVER_PANEL_ROW_HEIGHT = 18
local HOVER_HIDE_DELAY = 0.10
local OVERLAY_MODE_EXPANDED = "expanded"
local OVERLAY_MODE_COMPACT = "compact"
local OVERLAY_MODE_MINI = "mini"
local DETAIL_ROW_SEPARATOR = "  /  "
local TOOLTIP_COLORS = {
    body = { 0.92, 0.92, 0.88, 1 },
    section = { 1.00, 0.86, 0.40, 1 },
    complete = { 0.50, 0.88, 0.50, 1 },
    pending = { 0.47, 0.84, 1.00, 1 },
    tomtom = { 0.84, 0.90, 1.00, 1 },
}

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
    ns.UI.Typography:ApplyFont(fontString, size, {
        domain = "professionOverlay",
        flags = "OUTLINE",
        shadowOffset = { 1, -1 },
        shadowColor = { 0, 0, 0, 0.85 },
    })
    fontString:SetTextColor(r, g, b, 1)
    fontString:SetJustifyH("LEFT")
    fontString:SetJustifyV("TOP")
    if fontString.SetWordWrap then
        fontString:SetWordWrap(false)
    end
end

local function colorize(text, colorHex)
    local hex = tostring(colorHex or "ffffffff"):gsub("^|c", ""):gsub("[^0-9a-fA-F]", "")
    if #hex == 6 then
        hex = "ff" .. hex
    end
    if #hex ~= 8 then
        hex = "ffffffff"
    end
    return string.format("|c%s%s|r", hex, tostring(text or ""))
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

local function getCompleteColorHex()
    return "ff7fd46f"
end

local function getPendingColorHex()
    return "ff78d7ff"
end

local function getWeeklyResetRemainingParts()
    local totalSeconds = nil
    if C_DateAndTime and type(C_DateAndTime.GetSecondsUntilWeeklyReset) == "function" then
        local ok, seconds = pcall(C_DateAndTime.GetSecondsUntilWeeklyReset)
        if ok and type(seconds) == "number" and seconds >= 0 then
            totalSeconds = seconds
        end
    end

    if type(totalSeconds) ~= "number" then
        local now = GetServerTime and GetServerTime() or time()
        local t = date("*t", now)
        local weekday = tonumber(t and t.wday) or 1
        local currentHour = tonumber(t and t.hour) or 0
        local currentMinute = tonumber(t and t.min) or 0
        local currentSecond = tonumber(t and t.sec) or 0
        local targetWeekday = 5
        local deltaDays = (targetWeekday - weekday) % 7
        if deltaDays == 0 and (currentHour > 8 or (currentHour == 8 and (currentMinute > 0 or currentSecond > 0))) then
            deltaDays = 7
        end
        totalSeconds = (deltaDays * 86400) + ((8 - currentHour) * 3600) - (currentMinute * 60) - currentSecond
        if totalSeconds < 0 then
            totalSeconds = totalSeconds + (7 * 86400)
        end
    end

    totalSeconds = math.max(0, math.floor(totalSeconds or 0))
    local days = math.floor(totalSeconds / 86400)
    local hours = math.floor((totalSeconds % 86400) / 3600)
    local minutes = math.floor((totalSeconds % 3600) / 60)
    return days, hours, minutes
end

local function isKoreanOverlay()
    return ns.DB and ns.DB.GetLanguage and ns.DB:GetLanguage() == (ns.Constants and ns.Constants.LANGUAGE and ns.Constants.LANGUAGE.KOREAN)
end

local function getDetailPrefixText(sectionKey)
    if isKoreanOverlay() then
        if sectionKey == "weekly" then
            return "주  간:"
        end
        if sectionKey == "oneTime" then
            return "1회성:"
        end
    end

    if sectionKey == "weekly" then
        return ns.L("professions_overlay_prefix_weekly") .. ":"
    end

    return ns.L("professions_overlay_prefix_onetime") .. ":"
end

local function formatPointProgress(currentValue, maxValue, withSuffix)
    local pattern = withSuffix and "%d/%dP" or "%d/%d"
    return string.format(pattern, currentValue or 0, maxValue or 0)
end

local function buildRowFragments(rows, limit)
    local fragments = {}
    local maxRows = math.min(#(rows or {}), limit or #(rows or {}))
    for index = 1, maxRows do
        local row = rows[index]
        local countText = colorize(
            formatPointProgress(row.earned, row.maxPoints, false),
            row.complete and getCompleteColorHex() or getPendingColorHex()
        )
        fragments[#fragments + 1] = string.format("%s %s", getSourceShortLabel(row), countText)
    end

    return table.concat(fragments, DETAIL_ROW_SEPARATOR)
end

local function buildTooltipLine(text, colorKey, wrap)
    return {
        text = tostring(text or ""),
        color = TOOLTIP_COLORS[colorKey] or TOOLTIP_COLORS.body,
        wrap = wrap ~= false,
    }
end

local function joinObjectiveNames(objectiveRows, complete)
    local names = {}
    for _, objective in ipairs(objectiveRows or {}) do
        if (objective.complete and true or false) == (complete and true or false) then
            names[#names + 1] = objective.name or ""
        end
    end

    return table.concat(names, ", ")
end

local function formatTooltipCounts(row)
    return ns.L("professions_overlay_tooltip_counts", row and row.current or 0, row and row.max or 0, row and row.earned or 0, row and row.maxPoints or 0)
end

local function appendTooltipSection(lines, title, rows, options)
    options = options or {}
    if #(rows or {}) == 0 then
        return
    end

    lines[#lines + 1] = buildTooltipLine(ns.L("professions_overlay_tooltip_section_header", title), "section")
    for index, row in ipairs(rows or {}) do
        local rowColor = row and row.complete and "complete" or "pending"
        lines[#lines + 1] = buildTooltipLine(ns.L("professions_overlay_tooltip_source_line", row.title or "", formatTooltipCounts(row)), rowColor)

        local shouldListObjectives = options.showObjectives == true
        if shouldListObjectives and options.onlyKeys then
            shouldListObjectives = options.onlyKeys[row.key] and true or false
        end

        if shouldListObjectives then
            local doneNames = joinObjectiveNames(row.objectiveRows, true)
            local openNames = joinObjectiveNames(row.objectiveRows, false)
            if doneNames ~= "" then
                lines[#lines + 1] = buildTooltipLine(ns.L("professions_overlay_tooltip_done_named", doneNames), "complete")
            end
            if openNames ~= "" then
                lines[#lines + 1] = buildTooltipLine(ns.L("professions_overlay_tooltip_pending_named", openNames), "pending")
            end
        end

        if index < #(rows or {}) then
            lines[#lines + 1] = ""
        end
    end

    lines[#lines + 1] = ""
end

local function buildOverlayTooltipLines(professionEntry)
    local tracker = ns.Modules and ns.Modules.ProfessionKnowledgeTracker
    if not tracker or not professionEntry then
        return nil
    end

    local summary = tracker:GetProfessionSummary(professionEntry.key)
    local sections = tracker:GetProfessionSections(professionEntry.key)
    local resetDays, resetHours, resetMinutes = getWeeklyResetRemainingParts()
    local lines = {
        tracker:GetProfessionDisplayName(professionEntry),
        buildTooltipLine(ns.L("professions_overlay_tooltip_summary_weekly", summary and summary.weeklyMax or 0, summary and summary.weeklyEarned or 0), "body"),
        buildTooltipLine(ns.L("professions_overlay_tooltip_summary_onetime", summary and summary.oneTimeMax or 0, summary and summary.oneTimeEarned or 0), "body"),
        buildTooltipLine(ns.L("professions_overlay_tooltip_reset_precise", resetDays, resetHours, resetMinutes), "body"),
        "",
        buildTooltipLine(ns.L("professions_overlay_tooltip_legend"), "section"),
        buildTooltipLine(ns.L("professions_overlay_tooltip_done"), "complete", false),
        buildTooltipLine(ns.L("professions_overlay_tooltip_pending"), "pending", false),
        "",
    }

    appendTooltipSection(lines, ns.L("professions_overlay_tooltip_weekly"), sections[1] and sections[1].rows or {}, {
        showObjectives = true,
    })
    appendTooltipSection(lines, ns.L("professions_overlay_tooltip_onetime"), sections[2] and sections[2].rows or {}, {
        showObjectives = true,
        onlyKeys = {
            renown_reward = true,
            abundance_reward = true,
        },
    })

    local tomTom = ns.Modules and ns.Modules.TomTomBridge
    if tracker then
        local waypoint = tracker:GetNextTreasureWaypoint(professionEntry.key)
        if waypoint and tomTom and tomTom:IsAvailable() then
            lines[#lines + 1] = buildTooltipLine(ns.L("professions_overlay_tooltip_tomtom_header_line"), "tomtom", false)
            lines[#lines + 1] = buildTooltipLine(ns.L("professions_overlay_tooltip_tomtom_ready", waypoint.objective and waypoint.objective.name or ""), "body")
        elseif tomTom and tomTom:IsAvailable() then
            lines[#lines + 1] = buildTooltipLine(ns.L("professions_overlay_tooltip_tomtom_header_line"), "tomtom", false)
            lines[#lines + 1] = buildTooltipLine(ns.L("professions_overlay_tooltip_tomtom_none"), "body")
        else
            lines[#lines + 1] = buildTooltipLine(ns.L("professions_overlay_tooltip_tomtom_header_line"), "tomtom", false)
            lines[#lines + 1] = buildTooltipLine(ns.L("professions_overlay_tooltip_tomtom_missing"), "body")
        end
    end

    return lines
end

local function getPendingTreasureWaypoints(professionKey)
    local tracker = ns.Modules and ns.Modules.ProfessionKnowledgeTracker
    if not tracker or not professionKey then
        return {}
    end

    local treasureRow = tracker:EvaluateSource(professionKey, "treasures")
    if not treasureRow then
        return {}
    end

    local results = {}
    for _, objectiveRow in ipairs(treasureRow.objectiveRows or {}) do
        if not objectiveRow.complete then
            local waypoint = tracker:GetTreasureWaypoint(professionKey, objectiveRow)
            if waypoint then
                results[#results + 1] = {
                    title = objectiveRow.name or waypoint.title or "",
                    mapID = waypoint.mapID,
                    x = waypoint.x,
                    y = waypoint.y,
                    objective = objectiveRow,
                    waypointTitle = waypoint.title or objectiveRow.name or "",
                }
            end
        end
    end

    return results
end

local function getWaypointMapName(mapID)
    mapID = tonumber(mapID)
    if not mapID or not C_Map or type(C_Map.GetMapInfo) ~= "function" then
        return tostring(mapID or "")
    end

    local ok, mapInfo = pcall(C_Map.GetMapInfo, mapID)
    if ok and mapInfo and mapInfo.name and mapInfo.name ~= "" then
        return mapInfo.name
    end

    return tostring(mapID)
end

local function showRowTooltip(owner, lines)
    if not GameTooltip or type(lines) ~= "table" or #lines == 0 then
        return
    end

    GameTooltip:SetOwner(owner, "ANCHOR_RIGHT")
    if GameTooltip.SetMinimumWidth then
        GameTooltip:SetMinimumWidth(TOOLTIP_MIN_WIDTH)
    end
    GameTooltip:SetText(lines[1], 1, 0.86, 0.40)
    for index = 2, #lines do
        local line = lines[index]
        if line == "" then
            GameTooltip:AddLine(" ")
        elseif type(line) == "table" then
            local color = line.color or TOOLTIP_COLORS.body
            GameTooltip:AddLine(line.text or "", color[1], color[2], color[3], line.wrap ~= false)
        else
            GameTooltip:AddLine(line, 0.92, 0.92, 0.88, true)
        end
    end
    local headerSize = 13
    local bodySize = 12
    if ns.UI and ns.UI.Typography and ns.UI.Typography.GetSize then
        headerSize = ns.UI.Typography:GetSize(13, { domain = "tooltip", minSize = 9, maxSize = 28 })
        bodySize = ns.UI.Typography:GetSize(12, { domain = "tooltip", minSize = 9, maxSize = 28 })
    end
    if GameTooltip.GetName then
        local tooltipName = GameTooltip:GetName()
        for index = 1, GameTooltip:NumLines() do
            local left = _G[tooltipName .. "TextLeft" .. index]
            local right = _G[tooltipName .. "TextRight" .. index]
            if left and left.SetFont then
                left:SetFont(FONT_PATH, index == 1 and headerSize or bodySize, "OUTLINE")
            end
            if right and right.SetFont then
                right:SetFont(FONT_PATH, bodySize, "OUTLINE")
            end
        end
    end
    GameTooltip:Show()
end

local function isCursorInsideBounds(left, right, top, bottom, scale)
    if not left or not right or not top or not bottom then
        return false
    end

    local cursorX, cursorY = GetCursorPosition()
    scale = scale or (UIParent and UIParent:GetEffectiveScale()) or 1
    cursorX = cursorX / scale
    cursorY = cursorY / scale
    return cursorX >= left and cursorX <= right and cursorY >= bottom and cursorY <= top
end

local function isCursorOverOneTimeArea(row)
    if not row then
        return false
    end

    local left, right, top, bottom
    if row.displayMode == OVERLAY_MODE_COMPACT then
        left = row:GetLeft()
        right = row:GetRight()
        top = row:GetTop()
        bottom = row:GetBottom()
    else
        if not row.oneTimePrefix or not row.oneTimeDetails or not row.oneTimePrefix:IsShown() then
            return false
        end
        left = row:GetLeft()
        right = row:GetRight()
        top = row.oneTimePrefix:GetTop()
        bottom = row.oneTimeDetails:GetBottom()
    end

    local scale = row:GetEffectiveScale() or 1

    return isCursorInsideBounds(left, right, top, bottom, scale)
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
    frame:SetFrameStrata("MEDIUM")
    if frame.SetToplevel then
        frame:SetToplevel(false)
    end
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
            ns.UI.Typography:ApplyFont(fontString, 10, { domain = "professionOverlay", flags = "OUTLINE" })
            fontString:SetJustifyH("CENTER")
            fontString:SetJustifyV("MIDDLE")
        end
    end

    self.rows = {}
    self.frame = frame
    frame:Hide()
end

function ProfessionKnowledgeOverlay:CreateHoverPanel()
    if self.hoverPanel then
        return self.hoverPanel
    end

    local panel = CreateFrame("Frame", nil, self.frame)
    panel:SetFrameStrata(self.frame:GetFrameStrata())
    panel:SetFrameLevel(self.frame:GetFrameLevel() + 30)
    panel:SetSize(HOVER_PANEL_WIDTH, 76)
    panel:EnableMouse(true)
    panel:SetClampedToScreen(true)
    panel:Hide()

    panel.bg = panel:CreateTexture(nil, "BACKGROUND")
    panel.bg:SetAllPoints(panel)
    panel.bg:SetColorTexture(0.05, 0.07, 0.10, 0.95)

    panel.borderTop = panel:CreateTexture(nil, "BORDER")
    panel.borderTop:SetPoint("TOPLEFT", panel, "TOPLEFT", 0, 0)
    panel.borderTop:SetPoint("TOPRIGHT", panel, "TOPRIGHT", 0, 0)
    panel.borderTop:SetHeight(1)
    panel.borderTop:SetColorTexture(1.0, 0.82, 0.40, 0.70)

    panel.borderBottom = panel:CreateTexture(nil, "BORDER")
    panel.borderBottom:SetPoint("BOTTOMLEFT", panel, "BOTTOMLEFT", 0, 0)
    panel.borderBottom:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", 0, 0)
    panel.borderBottom:SetHeight(1)
    panel.borderBottom:SetColorTexture(1.0, 0.82, 0.40, 0.70)

    panel.borderLeft = panel:CreateTexture(nil, "BORDER")
    panel.borderLeft:SetPoint("TOPLEFT", panel, "TOPLEFT", 0, 0)
    panel.borderLeft:SetPoint("BOTTOMLEFT", panel, "BOTTOMLEFT", 0, 0)
    panel.borderLeft:SetWidth(1)
    panel.borderLeft:SetColorTexture(1.0, 0.82, 0.40, 0.70)

    panel.borderRight = panel:CreateTexture(nil, "BORDER")
    panel.borderRight:SetPoint("TOPRIGHT", panel, "TOPRIGHT", 0, 0)
    panel.borderRight:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", 0, 0)
    panel.borderRight:SetWidth(1)
    panel.borderRight:SetColorTexture(1.0, 0.82, 0.40, 0.70)

    panel.title = panel:CreateFontString(nil, "OVERLAY")
    panel.title:SetPoint("TOPLEFT", panel, "TOPLEFT", HOVER_PANEL_PADDING, -HOVER_PANEL_PADDING)
    panel.title:SetWidth(HOVER_PANEL_WIDTH - (HOVER_PANEL_PADDING * 2))
    applyTextStyle(panel.title, 12, 1.00, 0.86, 0.40)
    if panel.title.SetWordWrap then
        panel.title:SetWordWrap(true)
    end

    panel.hint = panel:CreateFontString(nil, "OVERLAY")
    panel.hint:SetPoint("TOPLEFT", panel.title, "BOTTOMLEFT", 0, -4)
    panel.hint:SetWidth(HOVER_PANEL_WIDTH - (HOVER_PANEL_PADDING * 2))
    applyTextStyle(panel.hint, 12, 0.82, 0.90, 1.00)
    if panel.hint.SetWordWrap then
        panel.hint:SetWordWrap(true)
    end

    panel.empty = panel:CreateFontString(nil, "OVERLAY")
    panel.empty:SetPoint("TOPLEFT", panel.hint, "BOTTOMLEFT", 0, -4)
    panel.empty:SetWidth(HOVER_PANEL_WIDTH - (HOVER_PANEL_PADDING * 2))
    applyTextStyle(panel.empty, 11, 0.92, 0.92, 0.88)
    if panel.empty.SetWordWrap then
        panel.empty:SetWordWrap(true)
    end

    panel.buttons = {}
    panel:SetScript("OnEnter", function()
        self.hoverHideToken = (self.hoverHideToken or 0) + 1
    end)
    panel:SetScript("OnLeave", function()
        self:QueueHideHoverPanel()
    end)

    self.hoverPanel = panel
    return panel
end

function ProfessionKnowledgeOverlay:EnsureHoverButtonCount(count)
    local panel = self:CreateHoverPanel()
    while #panel.buttons < count do
        local button = CreateFrame("Button", nil, panel)
        button:SetSize(HOVER_PANEL_WIDTH - (HOVER_PANEL_PADDING * 2), HOVER_PANEL_ROW_HEIGHT)
        button:EnableMouse(true)
        button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
        button:SetHitRectInsets(0, 0, 0, 0)
        button:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight")

        button.text = button:CreateFontString(nil, "OVERLAY")
        button.text:SetPoint("TOPLEFT", button, "TOPLEFT", 0, 0)
        button.text:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", 0, 0)
        applyTextStyle(button.text, 11, 0.94, 0.95, 0.88)
        if button.text.SetWordWrap then
            button.text:SetWordWrap(false)
        end

        button:SetScript("OnClick", function(currentButton)
            local tomTom = ns.Modules and ns.Modules.TomTomBridge
            if not tomTom or not tomTom:IsAvailable() then
                ns:SafeCall(ns.UI.MainWindow, "SetStatus", ns.L("tomtom_missing"))
                return
            end

            local waypoint = currentButton.waypoint
            if not waypoint then
                ns:SafeCall(ns.UI.MainWindow, "SetStatus", ns.L("tomtom_no_pending_treasure"))
                return
            end

            local _, err = tomTom:AddWaypoint(waypoint.mapID, waypoint.x, waypoint.y, waypoint.waypointTitle)
            if err then
                ns:SafeCall(ns.UI.MainWindow, "SetStatus", err)
                return
            end

            ns:SafeCall(ns.UI.MainWindow, "SetStatus", ns.L("tomtom_waypoint_set", waypoint.title or waypoint.waypointTitle or ""))
            self:HideHoverPanel()
        end)

        panel.buttons[#panel.buttons + 1] = button
    end
end

function ProfessionKnowledgeOverlay:HideHoverPanel()
    local panel = self.hoverPanel
    self.hoverHideToken = (self.hoverHideToken or 0) + 1
    if not panel then
        return
    end

    panel.ownerRow = nil
    panel:Hide()
    for _, button in ipairs(panel.buttons or {}) do
        button:Hide()
        button.waypoint = nil
    end
end

function ProfessionKnowledgeOverlay:QueueHideHoverPanel()
    local panel = self.hoverPanel
    if not panel or not panel:IsShown() then
        return
    end

    self.hoverHideToken = (self.hoverHideToken or 0) + 1
    local token = self.hoverHideToken
    if C_Timer and C_Timer.After then
        C_Timer.After(HOVER_HIDE_DELAY, function()
            if self.hoverHideToken ~= token then
                return
            end

            local currentPanel = self.hoverPanel
            local ownerRow = currentPanel and currentPanel.ownerRow or nil
            local panelHovered = currentPanel and currentPanel:IsShown() and currentPanel.IsMouseOver and currentPanel:IsMouseOver()
            local rowHovered = ownerRow and ownerRow:IsShown() and ownerRow.IsMouseOver and ownerRow:IsMouseOver()
            if not panelHovered and not rowHovered then
                self:HideHoverPanel()
            end
        end)
        return
    end

    self:HideHoverPanel()
end

function ProfessionKnowledgeOverlay:ShowHoverPanel(row)
    if not row or not row.professionKey then
        self:HideHoverPanel()
        return
    end

    local panel = self:CreateHoverPanel()
    local tomTom = ns.Modules and ns.Modules.TomTomBridge
    local pendingWaypoints = getPendingTreasureWaypoints(row.professionKey)
    local professionName = row.title and row.title.GetText and row.title:GetText() or ns.L("professions_overlay_title")

    panel.ownerRow = row
    panel:ClearAllPoints()
    panel:SetPoint("TOPLEFT", row, "TOPRIGHT", 10, 0)
    panel.title:SetText(string.format("%s | %s", professionName, ns.L("professions_overlay_panel_title")))

    if not tomTom or not tomTom:IsAvailable() then
        panel.hint:SetText(ns.L("professions_overlay_panel_missing"))
        panel.empty:SetText(ns.L("professions_overlay_tooltip_tomtom_missing"))
        for _, button in ipairs(panel.buttons or {}) do
            button:Hide()
            button.waypoint = nil
        end
        panel:SetHeight(76)
        panel:Show()
        return
    end

    if #pendingWaypoints == 0 then
        panel.hint:SetText(ns.L("professions_overlay_panel_empty"))
        panel.empty:SetText(ns.L("professions_overlay_tooltip_tomtom_none"))
        for _, button in ipairs(panel.buttons or {}) do
            button:Hide()
            button.waypoint = nil
        end
        panel:SetHeight(76)
        panel:Show()
        return
    end

    local hintText = ns.L("professions_overlay_panel_hint")
    if tomTom then
        for _, waypoint in ipairs(pendingWaypoints) do
            local restrictionMessage = tomTom:GetRestrictionMessage(waypoint.mapID)
            if restrictionMessage then
                hintText = hintText .. "\n" .. ns.L("professions_overlay_panel_region_note")
                break
            end
        end
    end
    panel.hint:SetText(hintText)
    panel.empty:SetText("")

    self:EnsureHoverButtonCount(#pendingWaypoints)

    local previous = panel.empty
    for index, waypoint in ipairs(pendingWaypoints) do
        local button = panel.buttons[index]
        button:ClearAllPoints()
        button:SetPoint("TOPLEFT", previous, "BOTTOMLEFT", 0, -4)
        button.waypoint = waypoint
        button.text:SetText(string.format(
            "%s - %s (%d, %d)",
            waypoint.title or waypoint.waypointTitle or "",
            getWaypointMapName(waypoint.mapID),
            math.floor((waypoint.x or 0) + 0.5),
            math.floor((waypoint.y or 0) + 0.5)
        ))
        button:Show()
        previous = button
    end

    for index = #pendingWaypoints + 1, #(panel.buttons or {}) do
        panel.buttons[index]:Hide()
        panel.buttons[index].waypoint = nil
    end

    local height = HOVER_PANEL_PADDING
        + math.ceil(panel.title:GetStringHeight() or 12)
        + 4
        + math.ceil(panel.hint:GetStringHeight() or 11)
        + 4
        + (#pendingWaypoints * (HOVER_PANEL_ROW_HEIGHT + 4))
        + HOVER_PANEL_PADDING
    panel:SetHeight(math.max(78, height))
    panel:Show()
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
        if currentRow.tooltipLines and ns.DB and ns.DB:IsProfessionKnowledgeOverlayTooltipEnabled() then
            showRowTooltip(currentRow, currentRow.tooltipLines)
        end
    end)
    row:SetScript("OnLeave", function()
        GameTooltip_Hide()
        self:QueueHideHoverPanel()
    end)
    row:SetScript("OnMouseUp", function(currentRow, button)
        if button ~= "RightButton" then
            return
        end

        if not isCursorOverOneTimeArea(currentRow) then
            return
        end

        GameTooltip_Hide()
        self:ShowHoverPanel(currentRow)
    end)

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
    row.weeklyPrefix:SetJustifyH("LEFT")

    row.weeklyDivider = row:CreateFontString(nil, "OVERLAY")
    row.weeklyDivider:SetPoint("TOPLEFT", row.weeklyPrefix, "TOPRIGHT", 0, 0)
    row.weeklyDivider:SetWidth(DETAIL_DIVIDER_WIDTH)
    applyTextStyle(row.weeklyDivider, DETAIL_SIZE, 0.92, 0.84, 0.56)
    row.weeklyDivider:SetJustifyH("CENTER")

    row.weeklyDetails = row:CreateFontString(nil, "OVERLAY")
    row.weeklyDetails:SetPoint("TOPLEFT", row.weeklyDivider, "TOPRIGHT", 6, 0)
    applyTextStyle(row.weeklyDetails, DETAIL_SIZE, 0.70, 0.92, 1.00)

    row.oneTimePrefix = row:CreateFontString(nil, "OVERLAY")
    row.oneTimePrefix:SetPoint("TOPLEFT", row.weeklyPrefix, "BOTTOMLEFT", 0, -3)
    row.oneTimePrefix:SetWidth(DETAIL_PREFIX_WIDTH)
    applyTextStyle(row.oneTimePrefix, DETAIL_SIZE, 0.98, 0.88, 0.52)
    row.oneTimePrefix:SetJustifyH("LEFT")

    row.oneTimeDivider = row:CreateFontString(nil, "OVERLAY")
    row.oneTimeDivider:SetPoint("TOPLEFT", row.oneTimePrefix, "TOPRIGHT", 0, 0)
    row.oneTimeDivider:SetWidth(DETAIL_DIVIDER_WIDTH)
    applyTextStyle(row.oneTimeDivider, DETAIL_SIZE, 0.92, 0.84, 0.56)
    row.oneTimeDivider:SetJustifyH("CENTER")

    row.oneTimeDetails = row:CreateFontString(nil, "OVERLAY")
    row.oneTimeDetails:SetPoint("TOPLEFT", row.oneTimeDivider, "TOPRIGHT", 6, 0)
    applyTextStyle(row.oneTimeDetails, DETAIL_SIZE, 0.74, 0.96, 0.80)

    row.lineBreak = row:CreateTexture(nil, "ARTWORK")
    row.lineBreak:SetHeight(1)
    row.lineBreak:SetColorTexture(1, 0.82, 0.40, 0.22)
    row.lineBreak:SetPoint("TOPLEFT", row.oneTimePrefix, "BOTTOMLEFT", 0, -5)
    row.lineBreak:SetPoint("TOPRIGHT", row.oneTimeDetails, "BOTTOMRIGHT", 0, -5)

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
    row.professionKey = professionEntry.key
    row:SetWidth(math.max(contentWidth, MIN_WIDTH - (PADDING_X * 2)))
    row.title:SetText(tracker:GetProfessionDisplayName(professionEntry))
    row.summary:SetWidth(math.max(contentWidth - ICON_SIZE - 8, 120))

    local weeklyLine = buildRowFragments(weeklyRows, 4)
    local oneTimeLine = buildRowFragments(oneTimeRows, 4)
    local weeklySummaryComplete = summary and summary.weeklyMax > 0 and summary.weeklyEarned >= summary.weeklyMax
    local oneTimeSummaryComplete = summary and summary.oneTimeMax > 0 and summary.oneTimeEarned >= summary.oneTimeMax
    local coloredSummary = string.format(
        "%s %s   |   %s %s",
        ns.L("professions_overlay_prefix_weekly"),
        colorize(
            formatPointProgress(summary and summary.weeklyEarned or 0, summary and summary.weeklyMax or 0, true),
            weeklySummaryComplete and getCompleteColorHex() or getPendingColorHex()
        ),
        ns.L("professions_overlay_prefix_onetime"),
        colorize(
            formatPointProgress(summary and summary.oneTimeEarned or 0, summary and summary.oneTimeMax or 0, true),
            oneTimeSummaryComplete and getCompleteColorHex() or getPendingColorHex()
        )
    )

    row.summary:SetText(coloredSummary)
    if fullyComplete then
        row.title:SetTextColor(0.72, 1.00, 0.78, 1)
        row.summary:SetTextColor(0.70, 0.98, 0.80, 1)
    else
        row.title:SetTextColor(1.00, 0.86, 0.42, 1)
        row.summary:SetTextColor(0.90, 0.96, 1.00, 1)
    end

    local detailWidth = math.max(contentWidth - ICON_SIZE - 8 - DETAIL_PREFIX_WIDTH - DETAIL_DIVIDER_WIDTH - 10, 120)
    row.weeklyPrefix:SetText(getDetailPrefixText("weekly"))
    row.weeklyDivider:SetText("|")
    row.weeklyDetails:SetWidth(detailWidth)
    row.weeklyDetails:SetText(weeklyLine ~= "" and weeklyLine or ns.L("no_items"))
    row.oneTimePrefix:SetText(getDetailPrefixText("oneTime"))
    row.oneTimeDivider:SetText("|")
    row.oneTimeDetails:SetWidth(detailWidth)
    row.oneTimeDetails:SetText(oneTimeLine ~= "" and oneTimeLine or ns.L("no_items"))
    row.tooltipLines = buildOverlayTooltipLines(professionEntry)
    row.displayMode = displayMode

    row.weeklyDetails:SetTextColor(0.92, 0.94, 0.95, 1)
    row.oneTimeDetails:SetTextColor(0.92, 0.94, 0.95, 1)

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

function ProfessionKnowledgeOverlay:RefreshInternal()
    if not self.frame then
        self:Initialize()
    end

    self:HideHoverPanel()

    if not self.frame or not ns.DB or not ns.DB:IsProfessionKnowledgeOverlayEnabled() then
        if self.frame then
            self:HideHoverPanel()
            self.frame:Hide()
        end
        return
    end

    local professions = ns.Modules.ProfessionKnowledgeTracker:GetKnownProfessions()
    if #professions == 0 then
        self:HideHoverPanel()
        self.frame:Hide()
        return
    end

    local displayMode = getDisplayMode()
    self.frame:SetScale(getOverlayScale())
    self.frame.title:SetText(ns.L("professions_overlay_title"))
    self.frame.toggleButton:SetText(getModeButtonGlyph(displayMode))

    if displayMode == OVERLAY_MODE_MINI then
        self:HideHoverPanel()
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

function ProfessionKnowledgeOverlay:Refresh()
    if self.isRefreshing then
        return
    end

    self.isRefreshing = true
    local ok, err = pcall(function()
        self:RefreshInternal()
    end)
    self.isRefreshing = false

    if not ok then
        self:HideHoverPanel()
        if self.frame then
            self.frame:Hide()
        end
        if ns.Utils and ns.Utils.Debug then
            ns.Utils.Debug("ProfessionKnowledgeOverlay refresh failed: " .. tostring(err))
        end
        ns:SafeCall(ns.UI.MainWindow, "SetStatus", ns.L("status_profession_refresh_failed"))
    end
end
