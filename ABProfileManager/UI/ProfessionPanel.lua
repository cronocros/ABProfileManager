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
    row.value:SetPoint("RIGHT", row, "RIGHT", -58, 0)
    row.value:SetWidth(96)
    row.value:SetJustifyH("RIGHT")
    applyText(row.value, 12, 1.00, 0.86, 0.42)

    row.minusButton = ns.UI.Widgets.CreateButton(row, "-", 22, 20)
    row.minusButton:SetPoint("RIGHT", row.value, "LEFT", -4, 0)

    row.plusButton = ns.UI.Widgets.CreateButton(row, "+", 22, 20)
    row.plusButton:SetPoint("LEFT", row.value, "RIGHT", 4, 0)

    return row
end

function ProfessionPanel:CreateCard(parent, point, relativeTo)
    local card = ns.UI.Widgets.CreatePanelBox(parent, CARD_WIDTH, CARD_HEIGHT, nil)
    if relativeTo then
        card:SetPoint(point, relativeTo, "TOPRIGHT", 12, 0)
    else
        card:SetPoint(point, parent, "TOPLEFT", 0, 0)
    end

    card.title = card:CreateFontString(nil, "OVERLAY")
    card.title:SetPoint("TOPLEFT", 14, -12)
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

    card.resetButton = ns.UI.Widgets.CreateButton(card, "", 108, 22)
    card.resetButton:SetPoint("BOTTOMRIGHT", card, "BOTTOMRIGHT", -14, 14)

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
        card.resetButton:SetText(ns.L("professions_reset_weekly"))
    end
end

function ProfessionPanel:BindCardRow(card, row, professionEntry, rowData)
    row.rowData = rowData
    row.professionEntry = professionEntry
    row.title:SetText(rowData.title or "")
    row.note:SetText(rowData.note or "")
    row.value:SetText(ns.L("pk_value_format", rowData.current, rowData.max, rowData.earned, rowData.maxPoints))
    row:Show()

    row.minusButton:SetEnabled((rowData.current or 0) > 0)
    row.minusButton:SetAlpha((rowData.current or 0) > 0 and 1 or 0.45)
    row.plusButton:SetEnabled((rowData.current or 0) < (rowData.max or 0))
    row.plusButton:SetAlpha((rowData.current or 0) < (rowData.max or 0) and 1 or 0.45)

    row.minusButton:SetScript("OnClick", function()
        local newValue = ns.Modules.ProfessionKnowledgeTracker:AdjustSourceValue(professionEntry.key, rowData.key, -1)
        if newValue == nil then
            return
        end
        setStatus(ns.L(
            "professions_status_adjusted",
            ns.Modules.ProfessionKnowledgeTracker:GetProfessionDisplayName(professionEntry),
            rowData.title,
            newValue,
            rowData.max or 0
        ))
        ns:RefreshUI()
    end)

    row.plusButton:SetScript("OnClick", function()
        local newValue = ns.Modules.ProfessionKnowledgeTracker:AdjustSourceValue(professionEntry.key, rowData.key, 1)
        if newValue == nil then
            return
        end
        setStatus(ns.L(
            "professions_status_adjusted",
            ns.Modules.ProfessionKnowledgeTracker:GetProfessionDisplayName(professionEntry),
            rowData.title,
            newValue,
            rowData.max or 0
        ))
        ns:RefreshUI()
    end)
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
    card.title:SetText(ns.Modules.ProfessionKnowledgeTracker:GetProfessionDisplayName(professionEntry))
    card.summary:SetText(ns.L(
        "professions_summary",
        summary and summary.weeklyEarned or 0,
        summary and summary.weeklyMax or 0,
        summary and summary.oneTimeEarned or 0,
        summary and summary.oneTimeMax or 0
    ))
    card.note:SetText(definition and ns.L(definition.noteKey) or "")

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
            self:BindCardRow(card, row, professionEntry, rowData)
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
            self:BindCardRow(card, row, professionEntry, rowData)
            currentAnchor = row
            rowIndex = rowIndex + 1
        end
    end

    for index = rowIndex, #card.rows do
        card.rows[index]:Hide()
    end

    card.resetButton:SetScript("OnClick", function()
        local currentSummary = ns.Modules.ProfessionKnowledgeTracker:GetProfessionSummary(professionEntry.key)
        ns.UI.ConfirmDialogs:ShowConfirm(
            ns.L("professions_reset_weekly_confirm", ns.Modules.ProfessionKnowledgeTracker:GetProfessionDisplayName(professionEntry)),
            function()
                ns.Modules.ProfessionKnowledgeTracker:ResetWeeklyForProfession(professionEntry.key)
                setStatus(ns.L(
                    "professions_status_adjusted",
                    ns.Modules.ProfessionKnowledgeTracker:GetProfessionDisplayName(professionEntry),
                    ns.L("professions_weekly"),
                    0,
                    currentSummary and currentSummary.weeklyMax or 0
                ))
                ns:RefreshUI()
            end
        )
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
