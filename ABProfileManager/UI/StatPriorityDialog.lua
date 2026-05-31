local _, ns = ...

local StatPriorityDialog = {}
ns.UI.StatPriorityDialog = StatPriorityDialog

local FRAME_NAME = "ABProfileManagerStatPriorityDialog"

local FRAME_WIDTH = 820
local FRAME_HEIGHT = 580
local CONTENT_LEFT_PAD = 24
local CONTENT_RIGHT_PAD = 24

local COL_CLASS = 96
local COL_SPEC = 100
local COL_PRIMARY = 56
local COL_PRIORITY = 460
local COL_GAP = 8

local ROW_BASE_HEIGHT = 26
local ROW_LINE_HEIGHT = 16
local ROW_VERTICAL_PAD = 8

local PRIMARY_STAT_COLORS = {
    strength  = { 0.95, 0.55, 0.45 },
    agility   = { 0.55, 0.92, 0.55 },
    intellect = { 0.62, 0.78, 1.00 },
}

local PRIMARY_STAT_LOCALE_KEYS = {
    strength  = "stat_priority_primary_strength",
    agility   = "stat_priority_primary_agility",
    intellect = "stat_priority_primary_intellect",
}

local function getClassColor(classTag)
    if RAID_CLASS_COLORS and classTag and RAID_CLASS_COLORS[classTag] then
        local color = RAID_CLASS_COLORS[classTag]
        return color.r or 1, color.g or 1, color.b or 1
    end
    return 1, 1, 1
end

local function getSpecDisplayName(row)
    local idMap = ns.Data and ns.Data.StatPrioritySpecIDs and ns.Data.StatPrioritySpecIDs[row.classTag]
    local specID = idMap and idMap[row.specIndex] or 0
    local fallback = row.specNameOverride or ("Spec " .. tostring(row.specIndex))
    if specID > 0 then
        local localized = ns.SpecL(specID, fallback)
        if localized and localized ~= "" then
            return localized
        end
    end
    return fallback
end

local function getCurrentPlayerKey()
    if type(UnitClass) ~= "function" or type(GetSpecialization) ~= "function" then
        return nil, nil
    end
    local _, classTag = UnitClass("player")
    local specIndex = GetSpecialization()
    return classTag, specIndex
end

local function getPriorityDisplayText(data)
    local language = ns.Locale and ns.Locale.GetCurrentLanguage and ns.Locale:GetCurrentLanguage() or "enUS"
    if language == "koKR" then
        return data.priorityText or data.priorityTextEnUS or ""
    end
    return data.priorityTextEnUS or data.priorityText or ""
end

local function applyHeaderFont(fontString)
    if ns.UI and ns.UI.Widgets and ns.UI.Widgets.ApplyFont then
        ns.UI.Widgets.ApplyFont(fontString, 13, { domain = "ui" })
    end
    fontString:SetTextColor(1, 0.86, 0.45, 1)
end

local function applyBodyFont(fontString)
    if ns.UI and ns.UI.Widgets and ns.UI.Widgets.ApplyFont then
        ns.UI.Widgets.ApplyFont(fontString, 12, { domain = "ui" })
    end
end

local function makeRowBackground(row, alpha)
    local bg = row:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints(row)
    bg:SetColorTexture(1, 1, 1, alpha or 0.04)
    return bg
end

local function makeRowHighlight(row)
    local hl = row:CreateTexture(nil, "ARTWORK")
    hl:SetAllPoints(row)
    hl:SetColorTexture(1, 0.86, 0.42, 0.10)
    hl:Hide()
    return hl
end

local function makeRowMarker(row)
    local marker = row:CreateTexture(nil, "OVERLAY")
    marker:SetSize(3, ROW_BASE_HEIGHT)
    marker:SetPoint("LEFT", row, "LEFT", -10, 0)
    marker:SetColorTexture(1, 0.86, 0.42, 1)
    marker:Hide()
    return marker
end

local function buildHeader(parent)
    local header = CreateFrame("Frame", nil, parent)
    header:SetHeight(28)

    local function makeHeaderLabel(width)
        local fs = header:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        fs:SetWidth(width)
        fs:SetJustifyH("LEFT")
        fs:SetJustifyV("MIDDLE")
        applyHeaderFont(fs)
        return fs
    end

    header.classLabel = makeHeaderLabel(COL_CLASS)
    header.classLabel:SetPoint("LEFT", header, "LEFT", 0, 0)

    header.specLabel = makeHeaderLabel(COL_SPEC)
    header.specLabel:SetPoint("LEFT", header.classLabel, "RIGHT", COL_GAP, 0)

    header.primaryLabel = makeHeaderLabel(COL_PRIMARY)
    header.primaryLabel:SetPoint("LEFT", header.specLabel, "RIGHT", COL_GAP, 0)

    header.priorityLabel = makeHeaderLabel(COL_PRIORITY)
    header.priorityLabel:SetPoint("LEFT", header.primaryLabel, "RIGHT", COL_GAP, 0)

    local divider = header:CreateTexture(nil, "OVERLAY")
    divider:SetPoint("BOTTOMLEFT", header, "BOTTOMLEFT", 0, -2)
    divider:SetPoint("BOTTOMRIGHT", header, "BOTTOMRIGHT", 0, -2)
    divider:SetHeight(1)
    divider:SetColorTexture(0.62, 0.55, 0.32, 0.9)

    return header
end

local function buildRow(parent, rowIndex)
    local row = CreateFrame("Frame", nil, parent)
    row:EnableMouse(true)

    row.background = makeRowBackground(row, rowIndex % 2 == 0 and 0.04 or 0.10)
    row.highlight = makeRowHighlight(row)
    row.marker = makeRowMarker(row)

    local function makeCell(width, anchorTo, offsetX)
        local fs = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        fs:SetWidth(width)
        fs:SetJustifyH("LEFT")
        fs:SetJustifyV("TOP")
        applyBodyFont(fs)
        if anchorTo then
            fs:SetPoint("TOPLEFT", anchorTo, "TOPRIGHT", offsetX or COL_GAP, 0)
        else
            fs:SetPoint("TOPLEFT", row, "TOPLEFT", 0, -ROW_VERTICAL_PAD * 0.5)
        end
        return fs
    end

    row.classText = makeCell(COL_CLASS, nil, 0)
    row.specText = makeCell(COL_SPEC, row.classText, COL_GAP)
    row.primaryText = makeCell(COL_PRIMARY, row.specText, COL_GAP)
    row.priorityText = makeCell(COL_PRIORITY, row.primaryText, COL_GAP)

    row.priorityText:SetWordWrap(true)
    row.priorityText:SetSpacing(2)

    row:SetScript("OnEnter", function(self)
        self.highlight:Show()
    end)
    row:SetScript("OnLeave", function(self)
        self.highlight:Hide()
    end)

    return row
end

local function applyRowData(row, data, isCurrentPlayer)
    local r, g, b = getClassColor(data.classTag)
    row.classText:SetText(ns.ClassL(data.classTag) or data.classTag)
    row.classText:SetTextColor(r, g, b, 1)

    row.specText:SetText(getSpecDisplayName(data))
    row.specText:SetTextColor(0.95, 0.95, 0.92, 1)

    local primaryKey = PRIMARY_STAT_LOCALE_KEYS[data.primaryStat]
    local primaryColor = PRIMARY_STAT_COLORS[data.primaryStat]
    row.primaryText:SetText(primaryKey and ns.L(primaryKey) or "")
    if primaryColor then
        row.primaryText:SetTextColor(primaryColor[1], primaryColor[2], primaryColor[3], 1)
    else
        row.primaryText:SetTextColor(0.95, 0.95, 0.92, 1)
    end

    row.priorityText:SetText(getPriorityDisplayText(data))
    row.priorityText:SetTextColor(0.92, 0.92, 0.86, 1)

    if isCurrentPlayer then
        row.marker:Show()
        row.background:SetColorTexture(1, 0.86, 0.42, 0.13)
    else
        row.marker:Hide()
    end
end

local function measureRowHeight(priorityText)
    if not priorityText or priorityText == "" then
        return ROW_BASE_HEIGHT
    end
    local lines = 1
    for _ in priorityText:gmatch("\n") do
        lines = lines + 1
    end
    return ROW_BASE_HEIGHT + ROW_LINE_HEIGHT * (lines - 1) + ROW_VERTICAL_PAD
end

local function layoutRows(rowsContainer, rows, data, currentClassTag, currentSpecIndex)
    local yOffset = 0
    local totalWidth = COL_CLASS + COL_SPEC + COL_PRIMARY + COL_PRIORITY + COL_GAP * 3

    for i, entry in ipairs(data) do
        local row = rows[i]
        if not row then
            row = buildRow(rowsContainer, i)
            rows[i] = row
        end

        local height = measureRowHeight(getPriorityDisplayText(entry))
        row:ClearAllPoints()
        row:SetPoint("TOPLEFT", rowsContainer, "TOPLEFT", 0, -yOffset)
        row:SetWidth(totalWidth)
        row:SetHeight(height)
        row:Show()

        local isCurrent = currentClassTag == entry.classTag and currentSpecIndex == entry.specIndex
        applyRowData(row, entry, isCurrent)

        yOffset = yOffset + height
    end

    for i = #data + 1, #rows do
        rows[i]:Hide()
    end

    rowsContainer:SetHeight(math.max(1, yOffset))
    rowsContainer:SetWidth(totalWidth)
    return yOffset
end

local function buildFrame()
    local frame = CreateFrame("Frame", FRAME_NAME, UIParent, "BackdropTemplate")
    frame:SetSize(FRAME_WIDTH, FRAME_HEIGHT)
    frame:SetPoint("CENTER")
    frame:SetFrameStrata("DIALOG")
    if frame.SetToplevel then
        frame:SetToplevel(true)
    end
    frame:SetClampedToScreen(true)
    frame:EnableMouse(true)
    frame:EnableKeyboard(true)
    frame:SetMovable(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    frame:SetScript("OnKeyDown", function(self, key)
        if key == "ESCAPE" then
            self:Hide()
        end
    end)
    frame:SetScript("OnMouseDown", function(self)
        if self.Raise then
            self:Raise()
        end
    end)
    frame:SetScript("OnShow", function(self)
        if not self.scrollHost or not self.scrollHost.UpdateScrollBar then
            return
        end
        if C_Timer and C_Timer.After then
            C_Timer.After(0, function()
                if self:IsShown() then
                    self.scrollHost:UpdateScrollBar()
                end
            end)
        else
            self.scrollHost:UpdateScrollBar()
        end
    end)
    frame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true,
        tileSize = 32,
        edgeSize = 32,
        insets = { left = 8, right = 8, top = 8, bottom = 8 },
    })
    frame:SetBackdropColor(0.02, 0.04, 0.07, 0.96)
    frame:Hide()

    if UISpecialFrames then
        local already = false
        for _, name in ipairs(UISpecialFrames) do
            if name == FRAME_NAME then
                already = true
                break
            end
        end
        if not already then
            table.insert(UISpecialFrames, FRAME_NAME)
        end
    end

    frame.title = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
    frame.title:SetPoint("TOPLEFT", CONTENT_LEFT_PAD, -18)
    frame.title:SetTextColor(1, 0.86, 0.42, 1)
    if ns.UI and ns.UI.Widgets and ns.UI.Widgets.ApplyFont then
        ns.UI.Widgets.ApplyFont(frame.title, 15, { domain = "ui" })
    end

    frame.subtitle = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    frame.subtitle:SetPoint("TOPLEFT", frame.title, "BOTTOMLEFT", 0, -8)
    frame.subtitle:SetWidth(FRAME_WIDTH - CONTENT_LEFT_PAD - CONTENT_RIGHT_PAD)
    frame.subtitle:SetHeight(32)
    frame.subtitle:SetJustifyH("LEFT")
    frame.subtitle:SetJustifyV("TOP")
    frame.subtitle:SetWordWrap(true)
    frame.subtitle:SetSpacing(2)
    frame.subtitle:SetTextColor(0.85, 0.85, 0.78, 1)
    if ns.UI and ns.UI.Widgets and ns.UI.Widgets.ApplyFont then
        ns.UI.Widgets.ApplyFont(frame.subtitle, 11, { domain = "ui" })
    end

    local closeButton = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    closeButton:SetPoint("TOPRIGHT", -6, -6)

    frame.header = buildHeader(frame)
    frame.header:SetPoint("TOPLEFT", frame.subtitle, "BOTTOMLEFT", 0, -16)
    frame.header:SetWidth(COL_CLASS + COL_SPEC + COL_PRIMARY + COL_PRIORITY + COL_GAP * 3)

    local scrollHostHeight = FRAME_HEIGHT - 156
    local scrollHostWidth = FRAME_WIDTH - CONTENT_LEFT_PAD - CONTENT_RIGHT_PAD
    local scrollHost = ns.UI.Widgets.CreateScrollHost(frame, scrollHostWidth, scrollHostHeight)
    scrollHost:SetPoint("TOPLEFT", frame.header, "BOTTOMLEFT", 0, -8)
    frame.scrollHost = scrollHost

    local rowsContainer = CreateFrame("Frame", nil, scrollHost.scrollFrame)
    rowsContainer:SetSize(scrollHostWidth - 30, 1)
    scrollHost.scrollFrame:SetScrollChild(rowsContainer)
    frame.rowsContainer = rowsContainer
    frame.rows = {}

    return frame
end

local function getOrCreateFrame(self)
    if not self.frame then
        self.frame = buildFrame()
    end
    return self.frame
end

function StatPriorityDialog:Initialize()
    -- 지연 초기화: Show 호출 시점에 frame 생성.
end

function StatPriorityDialog:RefreshLocale()
    local frame = self.frame
    if not frame then
        return
    end

    frame.title:SetText(ns.L("stat_priority_dialog_title"))
    frame.subtitle:SetText(ns.L("stat_priority_dialog_subtitle"))
    frame.header.classLabel:SetText(ns.L("stat_priority_column_class"))
    frame.header.specLabel:SetText(ns.L("stat_priority_column_spec"))
    frame.header.primaryLabel:SetText(ns.L("stat_priority_column_primary"))
    frame.header.priorityLabel:SetText(ns.L("stat_priority_column_priority"))

    if frame:IsShown() then
        self:Refresh()
    end
end

function StatPriorityDialog:Refresh()
    local frame = self.frame
    if not frame then
        return
    end

    local data = (ns.Data and ns.Data.StatPriorityTable) or {}
    local currentClassTag, currentSpecIndex = getCurrentPlayerKey()
    layoutRows(frame.rowsContainer, frame.rows, data, currentClassTag, currentSpecIndex)
    if frame.scrollHost and frame.scrollHost.UpdateScrollBar then
        frame.scrollHost:UpdateScrollBar()
    end
end

function StatPriorityDialog:Show()
    local frame = getOrCreateFrame(self)
    self:RefreshLocale()
    frame:Show()
    if frame.Raise then
        frame:Raise()
    end
    self:Refresh()
    -- ScrollFrame:GetVerticalScrollRange()가 한 프레임 뒤에야 갱신되는 경우가 있어
    -- 다음 프레임에서 한 번 더 스크롤바를 보정해 준다.
    if C_Timer and C_Timer.After then
        C_Timer.After(0, function()
            if frame.scrollHost and frame.scrollHost.UpdateScrollBar then
                frame.scrollHost:UpdateScrollBar()
            end
        end)
    end
end

function StatPriorityDialog:Hide()
    if self.frame then
        self.frame:Hide()
    end
end

function StatPriorityDialog:Toggle()
    if self.frame and self.frame:IsShown() then
        self:Hide()
    else
        self:Show()
    end
end

function StatPriorityDialog:IsShown()
    return self.frame ~= nil and self.frame:IsShown()
end
