local _, ns = ...

local ProfessionPanel = {}
ns.UI.ProfessionPanel = ProfessionPanel

local CARD_WIDTH = 420
local CARD_HEIGHT = 604
local ROW_HEIGHT = 38
local MAX_ROWS = 8

local function setStatus(message)
    ns:SafeCall(ns.UI.MainWindow, "SetStatus", message)
end

local function applyText(fontString, size, r, g, b)
    fontString:SetFont(STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF", size, "")
    fontString:SetTextColor(r, g, b, 1)
    fontString:SetJustifyH("LEFT")
    fontString:SetJustifyV("TOP")
    if fontString.SetWordWrap then
        fontString:SetWordWrap(false)
    end
end

local function setTooltip(owner, text)
    if not GameTooltip then
        return
    end

    GameTooltip:SetOwner(owner, "ANCHOR_RIGHT")
    local lines = {}
    for line in string.gmatch(tostring(text or ""), "([^\n]+)") do
        lines[#lines + 1] = line
    end

    if #lines == 0 then
        GameTooltip:SetText("")
        GameTooltip:Show()
        return
    end

    GameTooltip:SetText(lines[1], 1, 0.86, 0.40)
    for index = 2, #lines do
        GameTooltip:AddLine(lines[index], 0.9, 0.9, 0.88, true)
    end
    GameTooltip:Show()
end

local function buildRowTooltip(rowData)
    local lines = {
        ns.L("pk_tooltip_header", rowData.title, rowData.current, rowData.max, rowData.earned, rowData.maxPoints),
    }

    for _, objective in ipairs(rowData.objectiveRows or {}) do
        lines[#lines + 1] = ns.L(
            objective.complete and "pk_tooltip_complete_row" or "pk_tooltip_pending_row",
            objective.name or ("Objective " .. (objective.index or 0)),
            objective.points or 0
        )
    end

    return table.concat(lines, "\n")
end

function ProfessionPanel:CreateRow(parent, offsetY)
    local row = CreateFrame("Frame", nil, parent)
    row:SetPoint("TOPLEFT", 14, offsetY)
    row:SetSize(CARD_WIDTH - 28, ROW_HEIGHT)

    row.title = row:CreateFontString(nil, "OVERLAY")
    row.title:SetPoint("TOPLEFT", row, "TOPLEFT", 0, 0)
    row.title:SetWidth(208)
    applyText(row.title, 12, 0.95, 0.95, 0.92)

    row.note = row:CreateFontString(nil, "OVERLAY")
    row.note:SetPoint("TOPLEFT", row.title, "BOTTOMLEFT", 0, -2)
    row.note:SetWidth(240)
    applyText(row.note, 11, 0.68, 0.80, 0.92)

    row.value = row:CreateFontString(nil, "OVERLAY")
    row.value:SetPoint("RIGHT", row, "RIGHT", 0, 0)
    row.value:SetWidth(152)
    row.value:SetJustifyH("RIGHT")
    applyText(row.value, 12, 1.00, 0.86, 0.42)

    row:SetScript("OnEnter", function(currentRow)
        if currentRow.rowData then
            setTooltip(currentRow, buildRowTooltip(currentRow.rowData))
        end
    end)
    row:SetScript("OnLeave", GameTooltip_Hide)

    return row
end

function ProfessionPanel:CreateCard(parent, point, relativeTo)
    local card = ns.UI.Widgets.CreatePanelBox(parent, CARD_WIDTH, CARD_HEIGHT, nil)
    if relativeTo then
        card:SetPoint(point, relativeTo, "TOPRIGHT", 12, 0)
    else
        card:SetPoint(point, parent, "TOPLEFT", 0, 0)
    end

    card.icon = card:CreateTexture(nil, "OVERLAY")
    card.icon:SetSize(22, 22)
    card.icon:SetPoint("TOPLEFT", 14, -10)

    card.title = card:CreateFontString(nil, "OVERLAY")
    card.title:SetPoint("LEFT", card.icon, "RIGHT", 8, 0)
    card.title:SetPoint("RIGHT", card, "RIGHT", -14, 0)
    applyText(card.title, 14, 1, 0.86, 0.42)

    card.summary = card:CreateFontString(nil, "OVERLAY")
    card.summary:SetPoint("TOPLEFT", card.title, "BOTTOMLEFT", 0, -8)
    card.summary:SetWidth(CARD_WIDTH - 28)
    applyText(card.summary, 12, 0.92, 0.95, 1.00)

    card.note = card:CreateFontString(nil, "OVERLAY")
    card.note:SetPoint("TOPLEFT", card.summary, "BOTTOMLEFT", 0, -8)
    card.note:SetWidth(CARD_WIDTH - 28)
    card.note:SetJustifyH("LEFT")
    card.note:SetJustifyV("TOP")
    applyText(card.note, 11, 0.74, 0.84, 0.94)
    if card.note.SetWordWrap then
        card.note:SetWordWrap(true)
    end

    card.weeklyTitle = card:CreateFontString(nil, "OVERLAY")
    card.weeklyTitle:SetPoint("TOPLEFT", card.note, "BOTTOMLEFT", 0, -14)
    applyText(card.weeklyTitle, 12, 1, 0.86, 0.42)

    card.oneTimeTitle = card:CreateFontString(nil, "OVERLAY")
    applyText(card.oneTimeTitle, 12, 1, 0.86, 0.42)

    card.rows = {}
    local startOffset = -124
    for index = 1, MAX_ROWS do
        local row = self:CreateRow(card, startOffset - ((index - 1) * 46))
        card.rows[index] = row
    end

    card.rescanButton = ns.UI.Widgets.CreateButton(card, "", 108, 22)
    card.rescanButton:SetPoint("BOTTOMRIGHT", card, "BOTTOMRIGHT", -14, 14)

    return card
end

function ProfessionPanel:Create(parent)
    if self.frame then
        return self.frame
    end

    local frame = CreateFrame("Frame", nil, parent)
    frame:SetAllPoints()

    local title = ns.UI.Widgets.CreateLabel(frame, "", nil, 16, -14, "GameFontHighlightLarge")
    local hint = ns.UI.Widgets.CreateLabel(frame, "", title, 0, -10)
    hint:SetWidth(852)
    hint:SetJustifyH("LEFT")
    if hint.SetWordWrap then
        hint:SetWordWrap(true)
    end

    local leftCard = self:CreateCard(frame, "TOPLEFT", nil)
    leftCard:ClearAllPoints()
    leftCard:SetPoint("TOPLEFT", hint, "BOTTOMLEFT", 0, -12)
    local rightCard = self:CreateCard(frame, "TOPLEFT", leftCard)
    rightCard:ClearAllPoints()
    rightCard:SetPoint("TOPLEFT", leftCard, "TOPRIGHT", 12, 0)

    local emptyText = frame:CreateFontString(nil, "OVERLAY")
    emptyText:SetPoint("TOPLEFT", hint, "BOTTOMLEFT", 0, -18)
    emptyText:SetWidth(852)
    emptyText:SetJustifyH("LEFT")
    emptyText:SetJustifyV("TOP")
    applyText(emptyText, 13, 0.90, 0.94, 1.00)
    if emptyText.SetWordWrap then
        emptyText:SetWordWrap(true)
    end

    self.frame = frame
    self.title = title
    self.hint = hint
    self.cards = { leftCard, rightCard }
    self.emptyText = emptyText

    return frame
end

function ProfessionPanel:RefreshLocale()
    if not self.frame then
        return
    end

    self.title:SetText(ns.L("professions_title"))
    self.hint:SetText(ns.L("professions_hint"))
    for _, card in ipairs(self.cards or {}) do
        card.weeklyTitle:SetText(ns.L("professions_weekly"))
        card.oneTimeTitle:SetText(ns.L("professions_one_time"))
        card.rescanButton:SetText(ns.L("professions_rescan"))
    end
end

function ProfessionPanel:BindCardRow(row, rowData)
    row.rowData = rowData
    row.title:SetText(rowData.title or "")
    row.note:SetText(ns.L("pk_note_auto_progress", rowData.current, rowData.max, rowData.earned, rowData.maxPoints))
    row.value:SetText(ns.L("pk_value_format", rowData.current, rowData.max, rowData.earned, rowData.maxPoints))

    if rowData.complete then
        row.value:SetTextColor(0.55, 1.00, 0.70, 1)
        row.note:SetTextColor(0.62, 0.95, 0.74, 1)
    else
        row.value:SetTextColor(1.00, 0.86, 0.42, 1)
        row.note:SetTextColor(0.68, 0.80, 0.92, 1)
    end

    row:Show()
end

function ProfessionPanel:RefreshCard(card, professionEntry)
    if not professionEntry then
        card:Hide()
        for _, row in ipairs(card.rows or {}) do
            row:Hide()
        end
        return
    end

    local definition = professionEntry.definition
    local summary = ns.Modules.ProfessionKnowledgeTracker:GetProfessionSummary(professionEntry.key)
    local sections = ns.Modules.ProfessionKnowledgeTracker:GetProfessionSections(professionEntry.key)

    card:Show()
    card.icon:SetTexture(professionEntry.icon or ns.Constants.DEFAULT_ICON)
    card.title:SetText(ns.Modules.ProfessionKnowledgeTracker:GetProfessionDisplayName(professionEntry))
    card.summary:SetText(ns.L(
        "professions_summary",
        summary and summary.weeklyEarned or 0,
        summary and summary.weeklyMax or 0,
        summary and summary.oneTimeEarned or 0,
        summary and summary.oneTimeMax or 0
    ))
    card.note:SetText(string.format(
        "%s\n%s",
        definition and ns.L(definition.noteKey) or "",
        ns.L("professions_last_scan", ns.Modules.ProfessionKnowledgeTracker:GetLastScanLabel())
    ))

    card.weeklyTitle:ClearAllPoints()
    card.weeklyTitle:SetPoint("TOPLEFT", card.note, "BOTTOMLEFT", 0, -14)

    local rowIndex = 1
    local currentAnchor = card.weeklyTitle

    local weeklyRows = sections[1] and sections[1].rows or {}
    for _, rowData in ipairs(weeklyRows) do
        local row = card.rows[rowIndex]
        if row then
            row:ClearAllPoints()
            row:SetPoint("TOPLEFT", currentAnchor, "BOTTOMLEFT", 0, -8)
            self:BindCardRow(row, rowData)
            currentAnchor = row
            rowIndex = rowIndex + 1
        end
    end

    card.oneTimeTitle:ClearAllPoints()
    card.oneTimeTitle:SetPoint("TOPLEFT", currentAnchor, "BOTTOMLEFT", 0, -16)

    local oneTimeRows = sections[2] and sections[2].rows or {}
    currentAnchor = card.oneTimeTitle
    for _, rowData in ipairs(oneTimeRows) do
        local row = card.rows[rowIndex]
        if row then
            row:ClearAllPoints()
            row:SetPoint("TOPLEFT", currentAnchor, "BOTTOMLEFT", 0, -8)
            self:BindCardRow(row, rowData)
            currentAnchor = row
            rowIndex = rowIndex + 1
        end
    end

    for index = rowIndex, #card.rows do
        card.rows[index]:Hide()
    end

    card.rescanButton:SetScript("OnClick", function()
        ns.Modules.ProfessionKnowledgeTracker:RefreshQuestCache(true)
        setStatus(ns.L(
            "professions_status_rescanned",
            ns.Modules.ProfessionKnowledgeTracker:GetProfessionDisplayName(professionEntry)
        ))
        ns:RefreshUI()
    end)
end

function ProfessionPanel:Refresh()
    if not self.frame then
        return
    end

    self:RefreshLocale()

    local professions = ns.Modules.ProfessionKnowledgeTracker:GetKnownProfessions()
    self.emptyText:SetShown(#professions == 0)
    self.emptyText:SetText(#professions == 0 and ns.L("professions_empty") or "")

    self:RefreshCard(self.cards[1], professions[1])
    self:RefreshCard(self.cards[2], professions[2])
end
