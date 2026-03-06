local _, ns = ...

local ActionBarPanel = {}
ns.UI.ActionBarPanel = ActionBarPanel

local MODE_BUTTONS = {
    { key = ns.Constants.APPLY_MODE.FULL, titleKey = "action_mode_full", descKey = "action_mode_full_desc", icon = "12" },
    { key = ns.Constants.APPLY_MODE.BAR, titleKey = "action_mode_bar", descKey = "action_mode_bar_desc", icon = "1" },
    { key = ns.Constants.APPLY_MODE.BAR_RANGE, titleKey = "action_mode_bar_range", descKey = "action_mode_bar_range_desc", icon = "1-3" },
    { key = ns.Constants.APPLY_MODE.BAR_SET, titleKey = "action_mode_bar_set", descKey = "action_mode_bar_set_desc", icon = "1,3" },
    { key = ns.Constants.APPLY_MODE.SLOT_RANGE, titleKey = "action_mode_slot_range", descKey = "action_mode_slot_range_desc", icon = "#" },
}

local SYNC_ACTION = ns.Modules.TemplateSyncManager and ns.Modules.TemplateSyncManager:GetActionKeys() or {
    FILL_EMPTY = "fill_empty",
    CLEAR_EXTRAS = "clear_extras",
    SYNC_DIFF = "sync_diff",
    EXACT = "exact_sync",
}

local function setStatus(panel, message)
    local formatted = ns.Utils.FormatStatusMessage(message)
    if panel and panel.statusText then
        panel.statusText:SetText("")
        panel.statusText:SetText(formatted or "")
    end

    ns:SafeCall(ns.UI.MainWindow, "SetStatus", message)
end

local function getValidTemplateSelection()
    local selectedSource = ns:GetSelectedSource()
    if selectedSource and selectedSource.kind == ns.Constants.SOURCE_KIND.TEMPLATE and ns.DB and ns.DB:GetTemplate(selectedSource.key) then
        return selectedSource
    end

    if selectedSource then
        ns:SetSelectedSource(nil, nil)
    end

    return nil
end

local function setTooltip(owner, text)
    GameTooltip:SetOwner(owner, "ANCHOR_RIGHT")
    text = tostring(text or "")

    local lines = {}
    for line in string.gmatch(text, "([^\n]+)") do
        lines[#lines + 1] = line
    end

    if #lines == 0 then
        GameTooltip:SetText("")
        GameTooltip:Show()
        return
    end

    GameTooltip:SetText(lines[1])
    for index = 2, #lines do
        GameTooltip:AddLine(lines[index], 0.9, 0.9, 0.88, true)
    end
    GameTooltip:Show()
end

function ActionBarPanel:WriteSelectionToInputs()
    local selection = ns:GetSelectionState()
    self.barIndexInput:SetNumber(selection.barIndex or 1)
    self.startBarInput:SetNumber(selection.startBar or 1)
    self.endBarInput:SetNumber(selection.endBar or 2)
    self.barSetInput:SetText(selection.barSetText or "1, 2")
    self.startSlotInput:SetNumber(selection.startSlot or 1)
    self.endSlotInput:SetNumber(selection.endSlot or ns.Constants.LOGICAL_SLOT_MAX)
    self.clearCheck:SetChecked(selection.clearBeforeApply)
end

function ActionBarPanel:BuildSelectionFromInputs()
    local currentSelection = ns:GetSelectionState()
    return {
        mode = currentSelection.mode,
        barIndex = ns.Utils.SafeToNumber(self.barIndexInput:GetText(), currentSelection.barIndex),
        startBar = ns.Utils.SafeToNumber(self.startBarInput:GetText(), currentSelection.startBar),
        endBar = ns.Utils.SafeToNumber(self.endBarInput:GetText(), currentSelection.endBar),
        barSetText = self.barSetInput:GetText(),
        selectedBars = ns.Utils.ParseNumberList(self.barSetInput:GetText()),
        startSlot = ns.Utils.SafeToNumber(self.startSlotInput:GetText(), currentSelection.startSlot),
        endSlot = ns.Utils.SafeToNumber(self.endSlotInput:GetText(), currentSelection.endSlot),
        clearBeforeApply = self.clearCheck:GetChecked() and true or false,
    }
end

function ActionBarPanel:GetSelectionForHelp()
    local normalized = ns.Modules.RangeCopyManager:NormalizeSelection(self:BuildSelectionFromInputs())
    if normalized then
        return normalized
    end

    local fallback = ns.Modules.RangeCopyManager:NormalizeSelection(ns:GetSelectionState())
    if fallback then
        return fallback
    end

    return {
        summary = ns.L("apply_scope_none"),
        logicalSlots = {},
        clearBeforeApply = false,
    }
end

function ActionBarPanel:ReadSelectionFromInputs()
    local normalized, err = ns.Modules.RangeCopyManager:NormalizeSelection(self:BuildSelectionFromInputs())
    if not normalized then
        return nil, err
    end

    ns:SetSelectionState(normalized)
    return normalized
end

function ActionBarPanel:SetMode(mode)
    ns:SetSelectionState({ mode = mode })
    self:Refresh()
end

function ActionBarPanel:GetSelection()
    return self:ReadSelectionFromInputs()
end

function ActionBarPanel:RefreshModeButtons()
    local selection = ns:GetSelectionState()
    for modeKey, button in pairs(self.modeButtons) do
        ns.UI.Widgets.SetButtonSelected(button, selection.mode == modeKey)
    end

    local modeInfo = self.modeInfoByKey[selection.mode]
    if modeInfo then
        self.modeDescription:SetText(ns.L(modeInfo.descKey))
    end
end

function ActionBarPanel:RefreshModeVisibility()
    local mode = ns:GetSelectionState().mode

    self.modeInputHelp:SetShown(mode == ns.Constants.APPLY_MODE.FULL)
    self.barRow:SetShown(mode == ns.Constants.APPLY_MODE.BAR)
    self.barRangeRow:SetShown(mode == ns.Constants.APPLY_MODE.BAR_RANGE)
    self.barSetRow:SetShown(mode == ns.Constants.APPLY_MODE.BAR_SET)
    self.slotRangeRow:SetShown(mode == ns.Constants.APPLY_MODE.SLOT_RANGE)
end

function ActionBarPanel:RefreshLocale()
    if not self.frame then
        return
    end

    self.title:SetText(ns.L("action_bars_title"))
    self.templateBox.title:SetText(ns.L("source_details_title"))
    self.compareBox.title:SetText(ns.L("compare_title"))
    self.scopeBox.title:SetText(ns.L("action_scope_title"))
    self.syncBox.title:SetText(ns.L("sync_actions_title"))
    self.scopeHint:SetText(string.format("%s\n%s", ns.L("action_scope_hint"), ns.L("action_scope_flow")))
    self.modeInputHelp:SetText(ns.L("action_mode_full_inline"))
    self.barIndexLabel:SetText(ns.L("action_bar_number"))
    self.barRangeLabel:SetText(ns.L("action_bar_range"))
    self.barSetLabel:SetText(ns.L("action_bar_set"))
    self.barSetHint:SetText(ns.L("action_bar_set_hint"))
    self.slotRangeLabel:SetText(ns.L("action_slot_range"))
    self.clearCheck.Text:SetText(ns.L("clear_before_apply"))
    self.compareButton:SetText(ns.L("compare_refresh_button"))
    self.fillEmptyButton:SetText(ns.L("sync_fill_empty"))
    self.clearExtraButton:SetText(ns.L("sync_clear_extras"))
    self.syncDiffButton:SetText(ns.L("sync_sync_diff"))
    self.exactSyncButton:SetText(ns.L("sync_exact"))
    self.applyButton:SetText(ns.L("apply_selected_source"))
    self.clearButton:SetText(ns.L("clear_selected_range"))
    self.undoButton:SetText(ns.L("undo_button"))
    self.syncHint:SetText(ns.L("sync_hint"))

    for _, modeInfo in ipairs(MODE_BUTTONS) do
        self.modeButtons[modeInfo.key]:SetCardText(modeInfo.icon, ns.L(modeInfo.titleKey))
    end
end

function ActionBarPanel:BuildTemplateInfo(selectedSource, selection)
    if not selectedSource then
        return ns.L("source_details_none")
    end

    local details = ns.Modules.ProfileManager:GetSourceDetails(selectedSource.kind, selectedSource.key)
    if not details then
        return ns.L("source_details_none")
    end

    return table.concat({
        ns.L("section_template_info"),
        ns.L("source_details_name_bullet", details.key),
        ns.L("source_details_saved_at_bullet", details.savedAt or "-"),
        ns.L("source_details_character_bullet", details.characterKey or "-"),
        ns.L("source_details_class_bullet", ns.ClassL(details.class or "UNKNOWN")),
        ns.L("source_details_spec_bullet", details.specID or 0),
        "",
        ns.L("section_apply_info"),
        ns.L("source_details_scope_bullet", selection.summary),
        ns.L(
            "source_details_clear_bullet",
            selection.clearBeforeApply and ns.L("source_details_yes") or ns.L("source_details_no")
        ),
    }, "\n")
end

function ActionBarPanel:RefreshComparisonBox(selectedSource, selection)
    if not selectedSource then
        self.compareText:SetText(ns.L("compare_none_text"))
        return
    end

    local comparison = ns.Modules.TemplateSyncManager.lastComparison
    if comparison
        and comparison.key == selectedSource.key
        and comparison.kind == selectedSource.kind
        and comparison.selection
        and comparison.selection.summary == selection.summary
    then
        self.compareText:SetText(comparison.message)
        return
    end

    self.compareText:SetText(ns.L("compare_none_text"))
end

function ActionBarPanel:RefreshPreview(selection)
    if not selection then
        self.previewText:SetText(ns.L("error_invalid_range_mode"))
        return
    end

    local mutableCount = 0
    for _, logicalSlot in ipairs(selection.logicalSlots) do
        if ns.Modules.SlotMapper:IsMutableLogicalSlot(logicalSlot) then
            mutableCount = mutableCount + 1
        end
    end

    self.previewText:SetText(ns.L(
        "selection_preview_text",
        selection.summary,
        #selection.logicalSlots,
        mutableCount,
        selection.clearBeforeApply and ns.L("source_details_yes") or ns.L("source_details_no")
    ))
end

function ActionBarPanel:BuildSyncHelpText(actionKey, selection, detailed)
    selection = selection or self:GetSelectionForHelp()
    local summary = selection.summary or ns.L("apply_scope_none")

    if actionKey == "compare" then
        return ns.L("sync_help_compare_tip", summary)
    end

    if actionKey == SYNC_ACTION.FILL_EMPTY then
        return ns.L(detailed and "sync_help_fill_empty_long" or "sync_help_fill_empty_tip", summary, summary)
    end

    if actionKey == SYNC_ACTION.CLEAR_EXTRAS then
        return ns.L(detailed and "sync_help_clear_extras_long" or "sync_help_clear_extras_tip", summary, summary)
    end

    if actionKey == SYNC_ACTION.SYNC_DIFF then
        return ns.L(detailed and "sync_help_sync_diff_long" or "sync_help_sync_diff_tip", summary, summary)
    end

    if actionKey == SYNC_ACTION.EXACT then
        return ns.L(detailed and "sync_help_exact_long" or "sync_help_exact_tip", summary, summary)
    end

    return summary
end

function ActionBarPanel:BindSyncHelp(button, actionKey, showStatusOnClick)
    button:SetScript("OnEnter", function(currentButton)
        setTooltip(currentButton, self:BuildSyncHelpText(actionKey, self:GetSelectionForHelp(), false))
    end)
    button:SetScript("OnLeave", GameTooltip_Hide)

    if showStatusOnClick then
        local originalOnClick = button:GetScript("OnClick")
        button:SetScript("OnClick", function(currentButton, ...)
            setStatus(self, self:BuildSyncHelpText(actionKey, self:GetSelectionForHelp(), true))
            if originalOnClick then
                originalOnClick(currentButton, ...)
            end
        end)
    end
end

function ActionBarPanel:RunSyncAction(actionKey)
    local selectedSource = getValidTemplateSelection()
    if not selectedSource then
        setStatus(self, ns.L("error_select_source_first"))
        return
    end

    local selection, err = self:GetSelection()
    if not selection then
        setStatus(self, err)
        return
    end

    ns.Modules.TemplateSyncManager:RequestSyncAction(selectedSource.kind, selectedSource.key, selection, actionKey, {
        onComplete = function(result, actionErr)
            if not result then
                setStatus(self, actionErr)
                return
            end

            local comparison = ns.Modules.TemplateSyncManager:CompareTemplate(selectedSource.kind, selectedSource.key, selection)
            if comparison then
                self.compareText:SetText(comparison.message)
            end
            setStatus(self, result.message)
        end,
    })
end

function ActionBarPanel:Create(parent)
    if self.frame then
        return self.frame
    end

    local frame = CreateFrame("Frame", nil, parent)
    frame:SetAllPoints()

    local widgets = ns.UI.Widgets
    local title = widgets.CreateLabel(frame, "", nil, 16, -14, "GameFontHighlightLarge")

    local templateBox = widgets.CreatePanelBox(frame, 420, 144, "")
    templateBox:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -10)
    local templateText = widgets.CreateScrollTextBox(templateBox, 384, 100)
    templateText:SetPoint("TOPLEFT", 14, -28)

    local compareBox = widgets.CreatePanelBox(frame, 420, 144, "")
    compareBox:SetPoint("TOPLEFT", templateBox, "TOPRIGHT", 12, 0)
    local compareText = widgets.CreateScrollTextBox(compareBox, 384, 100)
    compareText:SetPoint("TOPLEFT", 14, -28)

    local scopeBox = widgets.CreatePanelBox(frame, 420, 456, "")
    scopeBox:SetPoint("TOPLEFT", templateBox, "BOTTOMLEFT", 0, -12)
    local scopeHint = widgets.CreateLabel(scopeBox, "", nil, 14, -30)
    scopeHint:SetWidth(382)
    scopeHint:SetJustifyH("LEFT")

    self.modeButtons = {}
    self.modeInfoByKey = {}
    local firstButton = nil
    local previousButton = nil
    for _, modeInfo in ipairs(MODE_BUTTONS) do
        local button = widgets.CreateOptionCard(scopeBox, 72, 58, modeInfo.icon, "")
        if not firstButton then
            firstButton = button
            button:SetPoint("TOPLEFT", scopeHint, "BOTTOMLEFT", 0, -10)
        else
            button:SetPoint("LEFT", previousButton, "RIGHT", 4, 0)
        end

        button:SetScript("OnClick", function()
            self:SetMode(modeInfo.key)
        end)

        self.modeButtons[modeInfo.key] = button
        self.modeInfoByKey[modeInfo.key] = modeInfo
        previousButton = button
    end

    local modeDescription = widgets.CreateLabel(scopeBox, "", firstButton, 0, -8)
    modeDescription:SetWidth(382)
    modeDescription:SetJustifyH("LEFT")

    local inputHost = CreateFrame("Frame", nil, scopeBox)
    inputHost:SetPoint("TOPLEFT", modeDescription, "BOTTOMLEFT", 0, -8)
    inputHost:SetSize(382, 82)

    local modeInputHelp = widgets.CreateLabel(inputHost, "", nil, 0, -4)
    modeInputHelp:SetWidth(382)
    modeInputHelp:SetJustifyH("LEFT")

    local barRow = CreateFrame("Frame", nil, inputHost)
    barRow:SetAllPoints(inputHost)
    local barIndexLabel = widgets.CreateLabel(barRow, "", nil, 0, -4, "GameFontHighlight")
    local barIndexInput = widgets.CreateEditBox(barRow, 72, 24, true)
    barIndexInput:SetPoint("LEFT", barIndexLabel, "RIGHT", 12, 0)

    local barRangeRow = CreateFrame("Frame", nil, inputHost)
    barRangeRow:SetAllPoints(inputHost)
    local barRangeLabel = widgets.CreateLabel(barRangeRow, "", nil, 0, -4, "GameFontHighlight")
    local startBarInput = widgets.CreateEditBox(barRangeRow, 72, 24, true)
    startBarInput:SetPoint("LEFT", barRangeLabel, "RIGHT", 12, 0)
    local barRangeDivider = widgets.CreateLabel(barRangeRow, "~", nil, 0, 0)
    barRangeDivider:ClearAllPoints()
    barRangeDivider:SetPoint("LEFT", startBarInput, "RIGHT", 8, 0)
    local endBarInput = widgets.CreateEditBox(barRangeRow, 72, 24, true)
    endBarInput:SetPoint("LEFT", barRangeDivider, "RIGHT", 8, 0)

    local barSetRow = CreateFrame("Frame", nil, inputHost)
    barSetRow:SetAllPoints(inputHost)
    local barSetLabel = widgets.CreateLabel(barSetRow, "", nil, 0, -4, "GameFontHighlight")
    local barSetInput = widgets.CreateEditBox(barSetRow, 160, 24, false)
    barSetInput:SetPoint("LEFT", barSetLabel, "RIGHT", 12, 0)
    local barSetHint = widgets.CreateLabel(barSetRow, "", barSetInput, 0, -14)
    barSetHint:SetWidth(286)
    barSetHint:SetJustifyH("LEFT")

    local slotRangeRow = CreateFrame("Frame", nil, inputHost)
    slotRangeRow:SetAllPoints(inputHost)
    local slotRangeLabel = widgets.CreateLabel(slotRangeRow, "", nil, 0, -4, "GameFontHighlight")
    local startSlotInput = widgets.CreateEditBox(slotRangeRow, 72, 24, true)
    startSlotInput:SetPoint("LEFT", slotRangeLabel, "RIGHT", 12, 0)
    local slotRangeDivider = widgets.CreateLabel(slotRangeRow, "~", nil, 0, 0)
    slotRangeDivider:ClearAllPoints()
    slotRangeDivider:SetPoint("LEFT", startSlotInput, "RIGHT", 8, 0)
    local endSlotInput = widgets.CreateEditBox(slotRangeRow, 72, 24, true)
    endSlotInput:SetPoint("LEFT", slotRangeDivider, "RIGHT", 8, 0)

    local clearCheck = widgets.CreateCheckButton(scopeBox, "")
    clearCheck:SetPoint("TOPLEFT", inputHost, "BOTTOMLEFT", -4, -6)

    local previewText = widgets.CreateScrollTextBox(scopeBox, 384, 132)
    previewText:SetPoint("TOPLEFT", clearCheck, "BOTTOMLEFT", 4, -12)

    local syncBox = widgets.CreatePanelBox(frame, 420, 456, "")
    syncBox:SetPoint("TOPLEFT", compareBox, "BOTTOMLEFT", 0, -12)
    local syncHint = widgets.CreateLabel(syncBox, "", nil, 14, -30)
    syncHint:SetWidth(382)
    syncHint:SetJustifyH("LEFT")

    local compareButton = widgets.CreateButton(syncBox, "", 382, 60)
    compareButton:SetPoint("TOPLEFT", syncHint, "BOTTOMLEFT", 0, -8)

    local fillEmptyButton = widgets.CreateButton(syncBox, "", 185, 60)
    fillEmptyButton:SetPoint("TOPLEFT", compareButton, "BOTTOMLEFT", 0, -8)

    local clearExtraButton = widgets.CreateButton(syncBox, "", 185, 60)
    clearExtraButton:SetPoint("LEFT", fillEmptyButton, "RIGHT", 12, 0)

    local syncDiffButton = widgets.CreateButton(syncBox, "", 185, 60)
    syncDiffButton:SetPoint("TOPLEFT", fillEmptyButton, "BOTTOMLEFT", 0, -8)

    local exactSyncButton = widgets.CreateButton(syncBox, "", 185, 60)
    exactSyncButton:SetPoint("LEFT", syncDiffButton, "RIGHT", 12, 0)

    local applyButton = widgets.CreateButton(syncBox, "", 185, 60)
    applyButton:SetPoint("TOPLEFT", syncDiffButton, "BOTTOMLEFT", 0, -10)

    local clearButton = widgets.CreateButton(syncBox, "", 185, 60)
    clearButton:SetPoint("LEFT", applyButton, "RIGHT", 12, 0)

    local undoButton = widgets.CreateButton(syncBox, "", 382, 34)
    undoButton:SetPoint("TOPLEFT", applyButton, "BOTTOMLEFT", 0, -8)

    local syncButtons = {
        compareButton,
        fillEmptyButton,
        clearExtraButton,
        syncDiffButton,
        exactSyncButton,
        applyButton,
        clearButton,
        undoButton,
    }
    for _, button in ipairs(syncButtons) do
        local fontString = button:GetFontString()
        if fontString then
            fontString:SetFont(STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF", 14, "")
        end
    end

    self.frame = frame
    self.title = title
    self.templateBox = templateBox
    self.templateText = templateText
    self.compareBox = compareBox
    self.compareText = compareText
    self.scopeBox = scopeBox
    self.scopeHint = scopeHint
    self.modeDescription = modeDescription
    self.inputHost = inputHost
    self.modeInputHelp = modeInputHelp
    self.barRow = barRow
    self.barIndexLabel = barIndexLabel
    self.barIndexInput = barIndexInput
    self.barRangeRow = barRangeRow
    self.barRangeLabel = barRangeLabel
    self.startBarInput = startBarInput
    self.endBarInput = endBarInput
    self.barRangeDivider = barRangeDivider
    self.barSetRow = barSetRow
    self.barSetLabel = barSetLabel
    self.barSetInput = barSetInput
    self.barSetHint = barSetHint
    self.slotRangeRow = slotRangeRow
    self.slotRangeLabel = slotRangeLabel
    self.startSlotInput = startSlotInput
    self.endSlotInput = endSlotInput
    self.slotRangeDivider = slotRangeDivider
    self.clearCheck = clearCheck
    self.previewText = previewText
    self.syncBox = syncBox
    self.syncHint = syncHint
    self.compareButton = compareButton
    self.fillEmptyButton = fillEmptyButton
    self.clearExtraButton = clearExtraButton
    self.syncDiffButton = syncDiffButton
    self.exactSyncButton = exactSyncButton
    self.applyButton = applyButton
    self.clearButton = clearButton
    self.undoButton = undoButton

    local function bindInput(box)
        box:SetScript("OnEnterPressed", function(currentBox)
            currentBox:ClearFocus()
            local _, err = self:GetSelection()
            if err then
                setStatus(self, err)
            else
                setStatus(self, ns.L("status_selection_updated"))
                self:Refresh()
            end
        end)

        box:SetScript("OnEditFocusLost", function()
            local _, err = self:GetSelection()
            if err then
                setStatus(self, err)
            else
                self:Refresh()
            end
        end)
    end

    bindInput(barIndexInput)
    bindInput(startBarInput)
    bindInput(endBarInput)
    bindInput(barSetInput)
    bindInput(startSlotInput)
    bindInput(endSlotInput)

    clearCheck:SetScript("OnClick", function()
        local selection, err = self:GetSelection()
        if not selection then
            setStatus(self, err)
            return
        end

        setStatus(self, ns.L("status_selection_updated"))
        self:Refresh()
    end)

    compareButton:SetScript("OnClick", function()
        local selectedSource = getValidTemplateSelection()
        if not selectedSource then
            setStatus(self, ns.L("error_select_source_first"))
            return
        end

        local selection, err = self:GetSelection()
        if not selection then
            setStatus(self, err)
            return
        end

        local comparison, compareErr = ns.Modules.TemplateSyncManager:CompareTemplate(selectedSource.kind, selectedSource.key, selection)
        if not comparison then
            setStatus(self, compareErr)
            return
        end

        self.compareText:SetText(comparison.message)
        setStatus(
            self,
            comparison.different == 0 and ns.L("compare_no_difference") or ns.L("compare_completed", comparison.different)
        )
    end)

    fillEmptyButton:SetScript("OnClick", function()
        self:RunSyncAction(SYNC_ACTION.FILL_EMPTY)
    end)

    clearExtraButton:SetScript("OnClick", function()
        self:RunSyncAction(SYNC_ACTION.CLEAR_EXTRAS)
    end)

    syncDiffButton:SetScript("OnClick", function()
        self:RunSyncAction(SYNC_ACTION.SYNC_DIFF)
    end)

    exactSyncButton:SetScript("OnClick", function()
        self:RunSyncAction(SYNC_ACTION.EXACT)
    end)

    applyButton:SetScript("OnClick", function()
        local selectedSource = getValidTemplateSelection()
        if not selectedSource then
            setStatus(self, ns.L("error_select_source_first"))
            return
        end

        local selection, err = self:GetSelection()
        if not selection then
            setStatus(self, err)
            return
        end

        ns.Modules.ProfileManager:RequestApplySource(selectedSource.kind, selectedSource.key, selection, {
            onComplete = function(result, applyErr)
                if not result then
                    setStatus(self, applyErr)
                    return
                end

                local comparison = ns.Modules.TemplateSyncManager:CompareTemplate(selectedSource.kind, selectedSource.key, selection)
                if comparison then
                    self.compareText:SetText(comparison.message)
                end
                setStatus(self, result.message)
            end,
        })
    end)

    clearButton:SetScript("OnClick", function()
        local selection, err = self:GetSelection()
        if not selection then
            setStatus(self, err)
            return
        end

        ns.Modules.ProfileManager:RequestClearSelection(selection, {
            onComplete = function(result, clearErr)
                if not result then
                    setStatus(self, clearErr)
                    return
                end

                self.compareText:SetText(ns.L("compare_none_text"))
                setStatus(self, result.message)
            end,
        })
    end)

    undoButton:SetScript("OnClick", function()
        ns.Modules.UndoManager:RequestUndo({
            onComplete = function(result, undoErr)
                if not result then
                    setStatus(self, undoErr)
                    return
                end

                self.compareText:SetText(ns.L("compare_none_text"))
                setStatus(self, result.message)
                self:Refresh()
            end,
        })
    end)

    self:BindSyncHelp(compareButton, "compare", false)
    self:BindSyncHelp(fillEmptyButton, SYNC_ACTION.FILL_EMPTY, true)
    self:BindSyncHelp(clearExtraButton, SYNC_ACTION.CLEAR_EXTRAS, true)
    self:BindSyncHelp(syncDiffButton, SYNC_ACTION.SYNC_DIFF, true)
    self:BindSyncHelp(exactSyncButton, SYNC_ACTION.EXACT, true)

    return frame
end

function ActionBarPanel:Refresh()
    if not self.frame then
        return
    end

    local canUndo = ns.Modules.UndoManager and ns.Modules.UndoManager:HasUndo()
    if self.undoButton then
        self.undoButton:SetEnabled(canUndo and true or false)
        self.undoButton:SetAlpha(canUndo and 1 or 0.45)
    end

    self:RefreshLocale()
    self:WriteSelectionToInputs()
    self:RefreshModeButtons()
    self:RefreshModeVisibility()

    local selectedSource = getValidTemplateSelection()
    local selection, err = ns.Modules.RangeCopyManager:NormalizeSelection(ns:GetSelectionState())
    if not selection then
        self.templateText:SetText(err or ns.L("error_invalid_range_mode"))
        self.previewText:SetText(err or ns.L("error_invalid_range_mode"))
        self.compareText:SetText(ns.L("compare_none_text"))
        return
    end

    self.templateText:SetText(self:BuildTemplateInfo(selectedSource, selection))
    self:RefreshPreview(selection)
    self:RefreshComparisonBox(selectedSource, selection)
end
