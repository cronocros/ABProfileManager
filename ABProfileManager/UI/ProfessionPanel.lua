local _, ns = ...

local ProfessionPanel = {}
ns.UI.ProfessionPanel = ProfessionPanel

local HEADER_HINT_WIDTH = 540
local CONTROL_FRAME_WIDTH = 252
local CARD_WIDTH = 420
local CARD_HEIGHT = 560
local ROW_HEIGHT = 44
local ROW_RIGHT_PADDING = 12
local ROW_VALUE_WIDTH = 58
local ROW_TEXT_WIDTH = CARD_WIDTH - 28 - ROW_VALUE_WIDTH - ROW_RIGHT_PADDING - 18
local MAX_ROWS = 8
local OVERLAY_SCALE_OPTIONS = {
    { value = 0.80, labelKey = "overlay_size_xsmall", buttonText = "XS" },
    { value = 0.90, labelKey = "overlay_size_small", buttonText = "S" },
    { value = 1.00, labelKey = "overlay_size_default", buttonText = "M" },
    { value = 1.15, labelKey = "overlay_size_large", buttonText = "L" },
    { value = 1.30, labelKey = "overlay_size_xlarge", buttonText = "XL" },
}

local function setStatus(message)
    ns:SafeCall(ns.UI.MainWindow, "SetStatus", message)
end

local function applyProfessionOverlayEnabled(enabled)
    if not ns.DB then
        return
    end

    ns.DB:SetProfessionKnowledgeOverlayEnabled(enabled)
    ns:RefreshUI()
    setStatus(ns.L("config_saved_profession_overlay", enabled and ns.L("state_enabled") or ns.L("state_disabled")))
end

local function applyProfessionOverlayScale(scale, labelKey)
    if not ns.DB then
        return
    end

    ns.DB:SetProfessionKnowledgeOverlayScale(scale)
    ns:RefreshUI()
    setStatus(ns.L("config_saved_profession_overlay_scale", ns.L(labelKey)))
end

local function applyText(fontString, size, r, g, b, wrap)
    fontString:SetFont(STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF", size, "")
    fontString:SetTextColor(r, g, b, 1)
    fontString:SetJustifyH("LEFT")
    fontString:SetJustifyV("TOP")
    if fontString.SetWordWrap then
        fontString:SetWordWrap(wrap and true or false)
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
    row.title:SetWidth(ROW_TEXT_WIDTH)
    applyText(row.title, 13, 0.95, 0.95, 0.92, true)

    row.note = row:CreateFontString(nil, "OVERLAY")
    row.note:SetPoint("TOPLEFT", row.title, "BOTTOMLEFT", 0, -1)
    row.note:SetWidth(ROW_TEXT_WIDTH)
    applyText(row.note, 11, 0.68, 0.80, 0.92, true)

    row.valueBlock = CreateFrame("Frame", nil, row)
    row.valueBlock:SetPoint("TOPRIGHT", row, "TOPRIGHT", -ROW_RIGHT_PADDING, 0)
    row.valueBlock:SetSize(ROW_VALUE_WIDTH, ROW_HEIGHT - 2)

    row.valueBackground = row.valueBlock:CreateTexture(nil, "BACKGROUND")
    row.valueBackground:SetAllPoints()
    row.valueBackground:SetColorTexture(0.12, 0.16, 0.22, 0.84)

    row.valueLabel = row.valueBlock:CreateFontString(nil, "OVERLAY")
    row.valueLabel:SetPoint("TOP", row.valueBlock, "TOP", 0, -1)
    row.valueLabel:SetWidth(ROW_VALUE_WIDTH)
    applyText(row.valueLabel, 10, 0.88, 0.86, 0.72, false)
    row.valueLabel:SetJustifyH("CENTER")

    row.valueAmount = row.valueBlock:CreateFontString(nil, "OVERLAY")
    row.valueAmount:SetPoint("TOP", row.valueLabel, "BOTTOM", 0, -1)
    row.valueAmount:SetWidth(ROW_VALUE_WIDTH)
    applyText(row.valueAmount, 12, 1.00, 0.86, 0.42, false)
    row.valueAmount:SetJustifyH("CENTER")

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
    card.icon:SetPoint("TOPRIGHT", -14, -10)

    card.title = card:CreateFontString(nil, "OVERLAY")
    card.title:SetPoint("TOPLEFT", card, "TOPLEFT", 14, -11)
    card.title:SetPoint("RIGHT", card.icon, "LEFT", -8, 0)
    applyText(card.title, 14, 1, 0.86, 0.42)

    card.summary = card:CreateFontString(nil, "OVERLAY")
    card.summary:SetPoint("TOPLEFT", card, "TOPLEFT", 14, -40)
    card.summary:SetWidth(CARD_WIDTH - 28)
    applyText(card.summary, 12, 0.92, 0.95, 1.00, true)
    if card.summary.SetSpacing then
        card.summary:SetSpacing(2)
    end

    card.note = card:CreateFontString(nil, "OVERLAY")
    card.note:SetPoint("TOPLEFT", card.summary, "BOTTOMLEFT", 0, -8)
    card.note:SetWidth(CARD_WIDTH - 28)
    card.note:SetJustifyH("LEFT")
    card.note:SetJustifyV("TOP")
    applyText(card.note, 11, 0.74, 0.84, 0.94, true)
    if card.note.SetSpacing then
        card.note:SetSpacing(2)
    end

    card.weeklyTitle = card:CreateFontString(nil, "OVERLAY")
    card.weeklyTitle:SetPoint("TOPLEFT", card.note, "BOTTOMLEFT", 0, -14)
    applyText(card.weeklyTitle, 12, 1, 0.86, 0.42)

    card.oneTimeTitle = card:CreateFontString(nil, "OVERLAY")
    applyText(card.oneTimeTitle, 12, 1, 0.86, 0.42)

    card.rows = {}
    local startOffset = -138
    for index = 1, MAX_ROWS do
        local row = self:CreateRow(card, startOffset - ((index - 1) * 40))
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
    hint:SetWidth(HEADER_HINT_WIDTH)
    hint:SetJustifyH("LEFT")
    if hint.SetWordWrap then
        hint:SetWordWrap(true)
    end

    local controlsFrame = CreateFrame("Frame", nil, frame)
    controlsFrame:SetSize(CONTROL_FRAME_WIDTH, 86)
    controlsFrame:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -18, -18)

    local overlayCheck = ns.UI.Widgets.CreateCheckButton(controlsFrame, "")
    overlayCheck:SetPoint("TOPLEFT", controlsFrame, "TOPLEFT", 0, 0)
    overlayCheck.Text:SetWidth(CONTROL_FRAME_WIDTH - 32)
    overlayCheck.Text:SetJustifyH("LEFT")

    local overlaySizeLabel = ns.UI.Widgets.CreateLabel(controlsFrame, "", overlayCheck, 4, -8, "GameFontHighlight")
    local overlayScaleButtons = {}
    local previousButton = nil
    for index, option in ipairs(OVERLAY_SCALE_OPTIONS) do
        local optionValue = option.value
        local optionLabelKey = option.labelKey
        local button = ns.UI.Widgets.CreateButton(controlsFrame, "", 44, 20)
        if previousButton then
            button:SetPoint("LEFT", previousButton, "RIGHT", 6, 0)
        else
            button:SetPoint("TOPLEFT", overlaySizeLabel, "BOTTOMLEFT", 0, -8)
        end
        button:SetScript("OnClick", function()
            applyProfessionOverlayScale(optionValue, optionLabelKey)
        end)
        overlayScaleButtons[index] = button
        previousButton = button
    end

    local leftCard = self:CreateCard(frame, "TOPLEFT", nil)
    leftCard:ClearAllPoints()
    leftCard:SetPoint("TOPLEFT", frame, "TOPLEFT", 16, -122)
    local rightCard = self:CreateCard(frame, "TOPLEFT", leftCard)
    rightCard:ClearAllPoints()
    rightCard:SetPoint("TOPLEFT", leftCard, "TOPRIGHT", 12, 0)

    local emptyText = frame:CreateFontString(nil, "OVERLAY")
    emptyText:SetPoint("TOPLEFT", frame, "TOPLEFT", 16, -128)
    emptyText:SetWidth(852)
    emptyText:SetJustifyH("LEFT")
    emptyText:SetJustifyV("TOP")
    applyText(emptyText, 13, 0.90, 0.94, 1.00, true)

    self.frame = frame
    self.title = title
    self.hint = hint
    self.controlsFrame = controlsFrame
    self.overlayCheck = overlayCheck
    self.overlaySizeLabel = overlaySizeLabel
    self.overlayScaleButtons = overlayScaleButtons
    self.cards = { leftCard, rightCard }
    self.emptyText = emptyText

    overlayCheck:SetScript("OnClick", function(currentCheck)
        applyProfessionOverlayEnabled(currentCheck:GetChecked())
    end)

    return frame
end

function ProfessionPanel:RefreshLocale()
    if not self.frame then
        return
    end

    self.title:SetText(ns.L("professions_title"))
    self.hint:SetText(ns.L("professions_hint"))
    self.overlayCheck.Text:SetText(ns.L("professions_overlay_toggle"))
    self.overlaySizeLabel:SetText(ns.L("overlay_size_label"))
    for index, option in ipairs(OVERLAY_SCALE_OPTIONS) do
        self.overlayScaleButtons[index]:SetText(option.buttonText or ns.L(option.labelKey))
    end
    for _, card in ipairs(self.cards or {}) do
        card.weeklyTitle:SetText(ns.L("professions_weekly"))
        card.oneTimeTitle:SetText(ns.L("professions_one_time"))
        card.rescanButton:SetText(ns.L("professions_rescan"))
    end
end

function ProfessionPanel:BindCardRow(row, rowData)
    row.rowData = rowData
    if rowData.complete then
        row.title:SetText(string.format("✓ %s", rowData.title or ""))
    else
        row.title:SetText(rowData.title or "")
    end
    row.note:SetText(ns.L("pk_progress_compact_format", rowData.current, rowData.max))
    row.valueLabel:SetText(ns.L(rowData.complete and "pk_value_label_done" or "pk_value_label"))
    row.valueAmount:SetText(ns.L("pk_points_value_compact_format", rowData.earned, rowData.maxPoints))

    local leftHeight = math.ceil(row.title:GetStringHeight() or 0) + 2 + math.ceil(row.note:GetStringHeight() or 0)
    local rightHeight = math.ceil(row.valueLabel:GetStringHeight() or 0) + 1 + math.ceil(row.valueAmount:GetStringHeight() or 0)
    row:SetHeight(math.max(ROW_HEIGHT, leftHeight, rightHeight))

    if rowData.complete then
        row.title:SetTextColor(0.72, 1.00, 0.78, 1)
        row.note:SetTextColor(0.62, 0.95, 0.74, 1)
        row.valueLabel:SetTextColor(0.62, 0.95, 0.74, 1)
        row.valueAmount:SetTextColor(0.55, 1.00, 0.70, 1)
        row.valueBackground:SetColorTexture(0.10, 0.24, 0.16, 0.90)
    else
        row.title:SetTextColor(0.95, 0.95, 0.92, 1)
        row.note:SetTextColor(0.68, 0.80, 0.92, 1)
        row.valueLabel:SetTextColor(0.88, 0.86, 0.72, 1)
        row.valueAmount:SetTextColor(1.00, 0.86, 0.42, 1)
        row.valueBackground:SetColorTexture(0.12, 0.16, 0.22, 0.84)
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
    card.summary:SetText(string.format(
        "%s\n%s",
        ns.L(
            "professions_summary",
            summary and summary.weeklyEarned or 0,
            summary and summary.weeklyMax or 0,
            summary and summary.oneTimeEarned or 0,
            summary and summary.oneTimeMax or 0
        ),
        ns.L("professions_last_scan", ns.Modules.ProfessionKnowledgeTracker:GetLastScanLabel())
    ))
    card.note:SetText(definition and ns.L(definition.noteKey) or "")

    card.weeklyTitle:ClearAllPoints()
    card.weeklyTitle:SetPoint("TOPLEFT", card.note, "BOTTOMLEFT", 0, -14)
    card.weeklyTitle:SetText(ns.L("professions_section_summary", ns.L("professions_weekly"), summary and summary.weeklyEarned or 0, summary and summary.weeklyMax or 0))

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
    card.oneTimeTitle:SetText(ns.L("professions_section_summary", ns.L("professions_one_time"), summary and summary.oneTimeEarned or 0, summary and summary.oneTimeMax or 0))

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
    local currentScale = ns.DB and ns.DB:GetProfessionKnowledgeOverlayScale() or 1
    local selectedScaleIndex = 1
    local selectedScaleDiff = nil
    for index, option in ipairs(OVERLAY_SCALE_OPTIONS) do
        local diff = math.abs(currentScale - option.value)
        if not selectedScaleDiff or diff < selectedScaleDiff then
            selectedScaleDiff = diff
            selectedScaleIndex = index
        end
    end
    self.overlayCheck:SetChecked(ns.DB and ns.DB:IsProfessionKnowledgeOverlayEnabled() or false)
    for index, option in ipairs(OVERLAY_SCALE_OPTIONS) do
        ns.UI.Widgets.SetButtonSelected(self.overlayScaleButtons[index], index == selectedScaleIndex)
    end
    self.emptyText:SetShown(#professions == 0)
    self.emptyText:SetText(#professions == 0 and ns.L("professions_empty") or "")

    self:RefreshCard(self.cards[1], professions[1])
    self:RefreshCard(self.cards[2], professions[2])
end
