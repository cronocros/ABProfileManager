local _, ns = ...

local ProfilePanel = {}
ns.UI.ProfilePanel = ProfilePanel

local ROW_COUNT = 11

local function setStatus(panel, message)
    local formatted = ns.Utils.FormatStatusMessage(message)
    if panel and panel.statusText then
        panel.statusText:SetText("")
        panel.statusText:SetText(formatted or "")
    end

    ns:SafeCall(ns.UI.MainWindow, "SetStatus", message)
end

local function refreshOtherPanel()
    ns:SafeCall(ns.UI.ActionBarPanel, "Refresh")
end

local function setTooltip(owner, text)
    GameTooltip:SetOwner(owner, "ANCHOR_RIGHT")
    GameTooltip:SetText(text)
    GameTooltip:Show()
end

local function getSetSpecializationFunc()
    if C_SpecializationInfo and C_SpecializationInfo.SetSpecialization then
        return C_SpecializationInfo.SetSpecialization
    end

    return SetSpecialization
end

function ProfilePanel:GetListOffset()
    self.listOffset = self.listOffset or 0
    return self.listOffset
end

function ProfilePanel:SetListOffset(offset)
    self.listOffset = math.max(0, offset or 0)
end

function ProfilePanel:ClampListOffset()
    local maxOffset = math.max(0, #(self.templateNames or {}) - #self.templateRows)
    local offset = math.min(self:GetListOffset(), maxOffset)
    self:SetListOffset(offset)
    return offset
end

function ProfilePanel:EnsureTemplateVisible(index)
    if not index then
        return
    end

    local offset = self:ClampListOffset()
    local visibleCount = #self.templateRows
    if index <= offset then
        self:SetListOffset(index - 1)
    elseif index > (offset + visibleCount) then
        self:SetListOffset(index - visibleCount)
    end
end

function ProfilePanel:MoveTemplateSelection(delta)
    local names = self.templateNames or ns.Modules.ProfileManager:ListTemplates()
    if #names == 0 then
        setStatus(self, ns.L("source_none"))
        return
    end

    local selectedSource = ns:GetSelectedSource()
    local currentIndex = nil
    if selectedSource and selectedSource.kind == ns.Constants.SOURCE_KIND.TEMPLATE then
        for index, templateName in ipairs(names) do
            if templateName == selectedSource.key then
                currentIndex = index
                break
            end
        end
    end

    if not currentIndex then
        currentIndex = delta >= 0 and 1 or #names
    else
        currentIndex = math.max(1, math.min(#names, currentIndex + delta))
    end

    self:EnsureTemplateVisible(currentIndex)
    self:SelectTemplate(names[currentIndex])
end

function ProfilePanel:UpdateScrollButtons()
    local selectedSource = ns:GetSelectedSource()
    local selectedIndex = nil
    if selectedSource and selectedSource.kind == ns.Constants.SOURCE_KIND.TEMPLATE then
        for index, templateName in ipairs(self.templateNames or {}) do
            if templateName == selectedSource.key then
                selectedIndex = index
                break
            end
        end
    end

    local totalCount = #(self.templateNames or {})
    local canMoveUp = totalCount > 0 and (selectedIndex == nil or selectedIndex > 1)
    local canMoveDown = totalCount > 0 and (selectedIndex == nil or selectedIndex < totalCount)

    if self.upButton then
        self.upButton:SetEnabled(canMoveUp)
        self.upButton:SetAlpha(canMoveUp and 1 or 0.4)
    end

    if self.downButton then
        self.downButton:SetEnabled(canMoveDown)
        self.downButton:SetAlpha(canMoveDown and 1 or 0.4)
    end
end

function ProfilePanel:SelectTemplate(templateName)
    ns:SetSelectedSource(ns.Constants.SOURCE_KIND.TEMPLATE, templateName)
    if self.templateInput then
        self.templateInput:SetText(templateName or "")
    end
    self:Refresh()
    refreshOtherPanel()
end

function ProfilePanel:DeleteSelectedTemplate()
    local selectedSource = ns:GetSelectedSource()
    if not selectedSource or selectedSource.kind ~= ns.Constants.SOURCE_KIND.TEMPLATE then
        setStatus(self, ns.L("error_delete_source_first"))
        return
    end

    ns.UI.ConfirmDialogs:ShowDeleteConfirm(
        ns.L("confirm_delete_text", ns.Utils.FormatSourceLabel(selectedSource.kind, selectedSource.key)),
        function()
            local deleted, err = ns.Modules.ProfileManager:DeleteSource(selectedSource.kind, selectedSource.key)
            if not deleted then
                setStatus(self, err)
                ns.Utils.Print(err)
                return
            end

            ns:SetSelectedSource(nil, nil)
            local statusMessage = ns.L("deleted_source", ns.Utils.FormatSourceLabel(selectedSource.kind, selectedSource.key))
            setStatus(self, statusMessage)
            ns.Utils.Print(statusMessage)
            self:Refresh()
            refreshOtherPanel()
        end
    )
end

function ProfilePanel:SwitchSpecialization(specIndex, specName)
    if InCombatLockdown and InCombatLockdown() then
        setStatus(self, ns.L("spec_switch_combat"))
        return
    end

    local setSpecialization = getSetSpecializationFunc()
    if type(setSpecialization) ~= "function" then
        setStatus(self, ns.L("spec_switch_unavailable"))
        return
    end

    local currentSpec = GetSpecialization and GetSpecialization() or 0
    if currentSpec == specIndex then
        setStatus(self, ns.L("spec_switch_already", specName))
        return
    end

    setSpecialization(specIndex)
    setStatus(self, ns.L("spec_switch_requested", specName))
end

function ProfilePanel:RefreshSpecButtons()
    if not self.specButtons then
        return
    end

    local currentSpec = GetSpecialization and GetSpecialization() or 0
    local count = GetNumSpecializations and GetNumSpecializations() or 0

    for index, button in ipairs(self.specButtons) do
        if index <= count then
            local _, name = GetSpecializationInfo(index)
            local label = name or ("Spec " .. index)
            if currentSpec == index then
                label = "▶ " .. label
            end
            button:SetText(label)
            button:Show()
            ns.UI.Widgets.SetButtonSelected(button, currentSpec == index)
            button.specIndex = index
            button.specName = name or ("Spec " .. index)
        else
            button:Hide()
        end
    end
end

function ProfilePanel:CreateRows(parent)
    local rows = {}
    local previous = nil

    for rowIndex = 1, ROW_COUNT do
        local row = ns.UI.Widgets.CreateListButton(parent, 284, 24)
        if rowIndex == 1 then
            row:SetPoint("TOPLEFT", parent, "TOPLEFT", 10, -34)
        else
            row:SetPoint("TOPLEFT", previous, "BOTTOMLEFT", 0, -4)
        end

        row:SetScript("OnClick", function(currentRow)
            if currentRow.templateName then
                self:SelectTemplate(currentRow.templateName)
            end
        end)

        rows[#rows + 1] = row
        previous = row
    end

    return rows
end

function ProfilePanel:PopulateRows()
    local selectedSource = ns:GetSelectedSource()
    local offset = self:ClampListOffset()

    for index, row in ipairs(self.templateRows) do
        local templateName = self.templateNames[offset + index]
        row.templateName = templateName

        if templateName then
            local isSelected =
                selectedSource
                and selectedSource.kind == ns.Constants.SOURCE_KIND.TEMPLATE
                and selectedSource.key == templateName
            row:SetText((isSelected and "▶ " or "  ") .. templateName)
            row:Show()
        else
            row:SetText("")
            row:Hide()
        end

        ns.UI.Widgets.SetButtonSelected(
            row,
            templateName
                and selectedSource
                and selectedSource.kind == ns.Constants.SOURCE_KIND.TEMPLATE
                and selectedSource.key == templateName
        )
    end

    self:UpdateScrollButtons()
end

function ProfilePanel:RefreshLocale()
    if not self.frame then
        return
    end

    self.title:SetText(ns.L("profiles_title"))
    self.specLabel:SetText(ns.L("spec_switch_title"))
    self.templateNameLabel:SetText(ns.L("template_name"))
    self.saveTemplateButton:SetText(ns.L("save_template"))
    self.duplicateButton:SetText(ns.L("duplicate_template"))
    self.refreshButton:SetText(ns.L("refresh_lists"))
    self.templatesBox.title:SetText(ns.L("templates"))
    self.actionsBox.title:SetText(ns.L("selected_source_actions"))
    self.applyButton:SetText(ns.L("apply_selected"))
    self.clearAllButton:SetText(ns.L("clear_all_bars"))
    self.undoButton:SetText(ns.L("undo_button"))
    self.exportButton:SetText(ns.L("transfer_export_button"))
    self.importButton:SetText(ns.L("transfer_import_button"))
    self.deleteButton:SetText(ns.L("delete_selected"))
    self.scrollHint:SetText(ns.L("template_scroll_hint"))
    if self.scrollHint.SetWordWrap then
        self.scrollHint:SetWordWrap(false)
    end
    self.upButton:SetText("▲")
    self.downButton:SetText("▼")

    self.hintText:SetText(ns.L("hint_set_range_in_action_bars"))
end

function ProfilePanel:Create(parent)
    if self.frame then
        return self.frame
    end

    local frame = CreateFrame("Frame", nil, parent)
    frame:SetAllPoints()

    local widgets = ns.UI.Widgets
    local title = widgets.CreateLabel(frame, "", nil, 16, -18, "GameFontHighlightLarge")

    local classIcon = frame:CreateTexture(nil, "ARTWORK")
    classIcon:SetSize(18, 18)
    classIcon:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -16)

    local specIcon = frame:CreateTexture(nil, "ARTWORK")
    specIcon:SetSize(18, 18)
    specIcon:SetPoint("LEFT", classIcon, "RIGHT", 6, 0)

    local characterInfo = widgets.CreateLabel(frame, "", nil, 0, 0)
    characterInfo:ClearAllPoints()
    characterInfo:SetPoint("LEFT", specIcon, "RIGHT", 8, 0)
    characterInfo:SetWidth(796)
    characterInfo:SetJustifyH("LEFT")

    local specLabel = widgets.CreateLabel(frame, "", nil, 16, -74, "GameFontHighlight")
    local specButtons = {}
    local previousSpecButton = nil
    for index = 1, 4 do
        local specButton = widgets.CreateButton(frame, "", 96, 24)
        if index == 1 then
            specButton:SetPoint("TOPLEFT", specLabel, "BOTTOMLEFT", 0, -8)
        else
            specButton:SetPoint("LEFT", previousSpecButton, "RIGHT", 8, 0)
        end
        specButton:SetScript("OnClick", function(currentButton)
            self:SwitchSpecialization(currentButton.specIndex, currentButton.specName)
        end)
        specButtons[#specButtons + 1] = specButton
        previousSpecButton = specButton
    end

    local templateNameLabel = widgets.CreateLabel(frame, "", specLabel, 0, -38, "GameFontHighlight")
    local templateInput = widgets.CreateEditBox(frame, 248, 24)
    templateInput:SetPoint("TOPLEFT", templateNameLabel, "BOTTOMLEFT", 0, -8)

    local saveTemplateButton = widgets.CreateButton(frame, "", 104, 24)
    saveTemplateButton:SetPoint("LEFT", templateInput, "RIGHT", 8, 0)

    local duplicateButton = widgets.CreateButton(frame, "", 104, 24)
    duplicateButton:SetPoint("LEFT", saveTemplateButton, "RIGHT", 8, 0)

    local refreshButton = widgets.CreateButton(frame, "", 104, 24)
    refreshButton:SetPoint("LEFT", duplicateButton, "RIGHT", 8, 0)

    local deleteButton = widgets.CreateButton(frame, "", 104, 24)
    deleteButton:SetPoint("LEFT", refreshButton, "RIGHT", 8, 0)

    local selectedTemplateText = widgets.CreateLabel(frame, "", templateInput, 0, -24)
    selectedTemplateText:SetWidth(804)
    selectedTemplateText:SetJustifyH("LEFT")

    local templatesBox = widgets.CreatePanelBox(frame, 312, 404, "")
    templatesBox:SetPoint("TOPLEFT", selectedTemplateText, "BOTTOMLEFT", 0, -12)

    local actionsBox = widgets.CreatePanelBox(frame, 524, 404, "")
    actionsBox:SetPoint("LEFT", templatesBox, "RIGHT", 16, 0)

    local sourceDetailsText = widgets.CreateScrollTextBox(actionsBox, 300, 280)
    sourceDetailsText:SetPoint("TOPLEFT", 18, -30)

    local applyButton = widgets.CreateButton(actionsBox, "", 174, 30)
    applyButton:SetPoint("TOPRIGHT", actionsBox, "TOPRIGHT", -18, -30)

    local clearAllButton = widgets.CreateButton(actionsBox, "", 174, 30)
    clearAllButton:SetPoint("TOPLEFT", applyButton, "BOTTOMLEFT", 0, -10)

    local undoButton = widgets.CreateButton(actionsBox, "", 174, 30)
    undoButton:SetPoint("TOPLEFT", clearAllButton, "BOTTOMLEFT", 0, -10)

    local exportButton = widgets.CreateButton(actionsBox, "", 174, 30)
    exportButton:SetPoint("TOPLEFT", undoButton, "BOTTOMLEFT", 0, -10)

    local importButton = widgets.CreateButton(actionsBox, "", 174, 30)
    importButton:SetPoint("TOPLEFT", exportButton, "BOTTOMLEFT", 0, -10)

    local hintText = widgets.CreateLabel(actionsBox, "", sourceDetailsText, 0, -14)
    hintText:SetWidth(300)
    hintText:SetJustifyH("LEFT")

    local scrollHint = widgets.CreateLabel(templatesBox, "", nil, 198, -10, "GameFontHighlight")
    scrollHint:ClearAllPoints()
    scrollHint:SetPoint("TOPRIGHT", templatesBox, "TOPRIGHT", -66, -10)
    scrollHint:SetWidth(72)
    scrollHint:SetJustifyH("RIGHT")

    local upButton = widgets.CreateButton(templatesBox, "", 24, 20)
    upButton:SetPoint("TOPRIGHT", templatesBox, "TOPRIGHT", -34, -7)
    upButton:SetScript("OnClick", function()
        self:MoveTemplateSelection(-1)
    end)
    upButton:SetScript("OnEnter", function(currentButton)
        setTooltip(currentButton, ns.L("template_scroll_up"))
    end)
    upButton:SetScript("OnLeave", GameTooltip_Hide)

    local downButton = widgets.CreateButton(templatesBox, "", 24, 20)
    downButton:SetPoint("TOPRIGHT", templatesBox, "TOPRIGHT", -8, -7)
    downButton:SetScript("OnClick", function()
        self:MoveTemplateSelection(1)
    end)
    downButton:SetScript("OnEnter", function(currentButton)
        setTooltip(currentButton, ns.L("template_scroll_down"))
    end)
    downButton:SetScript("OnLeave", GameTooltip_Hide)

    self.frame = frame
    self.title = title
    self.classIcon = classIcon
    self.specIcon = specIcon
    self.characterInfo = characterInfo
    self.specLabel = specLabel
    self.specButtons = specButtons
    self.templateNameLabel = templateNameLabel
    self.templateInput = templateInput
    self.saveTemplateButton = saveTemplateButton
    self.duplicateButton = duplicateButton
    self.refreshButton = refreshButton
    self.selectedTemplateText = selectedTemplateText
    self.templatesBox = templatesBox
    self.actionsBox = actionsBox
    self.sourceDetailsText = sourceDetailsText
    self.applyButton = applyButton
    self.clearAllButton = clearAllButton
    self.undoButton = undoButton
    self.exportButton = exportButton
    self.importButton = importButton
    self.deleteButton = deleteButton
    self.hintText = hintText
    self.scrollHint = scrollHint
    self.upButton = upButton
    self.downButton = downButton
    self.templateRows = self:CreateRows(templatesBox)

    saveTemplateButton:SetScript("OnClick", function()
        ns.Modules.ProfileManager:RequestSaveTemplate(templateInput:GetText(), {
            onComplete = function(snapshot, err)
                if not snapshot then
                    setStatus(self, err)
                    if err then
                        ns.Utils.Print(err)
                    end
                    return
                end

                ns:SetSelectedSource(ns.Constants.SOURCE_KIND.TEMPLATE, snapshot.sourceKey)
                templateInput:SetText(snapshot.sourceKey or "")
                local statusMessage = ns.L("saved_template", snapshot.sourceKey)
                setStatus(self, statusMessage)
                ns.Utils.Print(statusMessage)
                self:Refresh()
                refreshOtherPanel()
            end,
        })
    end)

    duplicateButton:SetScript("OnClick", function()
        local selectedSource = ns:GetSelectedSource()
        if not selectedSource or selectedSource.kind ~= ns.Constants.SOURCE_KIND.TEMPLATE then
            setStatus(self, ns.L("error_duplicate_source_first"))
            return
        end

        local snapshot, err = ns.Modules.ProfileManager:DuplicateTemplate(selectedSource.key, templateInput:GetText())
        if not snapshot then
            setStatus(self, err)
            ns.Utils.Print(err)
            return
        end

        ns:SetSelectedSource(ns.Constants.SOURCE_KIND.TEMPLATE, snapshot.sourceKey)
        templateInput:SetText(snapshot.sourceKey or "")
        local statusMessage = ns.L("duplicated_template", snapshot.sourceKey)
        setStatus(self, statusMessage)
        ns.Utils.Print(statusMessage)
        self:Refresh()
        refreshOtherPanel()
    end)

    refreshButton:SetScript("OnClick", function()
        self:Refresh()
        refreshOtherPanel()
        setStatus(self, ns.L("status_lists_refreshed"))
    end)

    applyButton:SetScript("OnClick", function()
        local selectedSource = ns:GetSelectedSource()
        if not selectedSource then
            setStatus(self, ns.L("error_select_source_first"))
            return
        end

        local selection, err = ns.UI.ActionBarPanel:GetSelection()
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

                setStatus(self, result.message)
            end,
        })
    end)

    clearAllButton:SetScript("OnClick", function()
        local selection, err = ns.Modules.RangeCopyManager:NormalizeSelection({
            mode = ns.Constants.APPLY_MODE.FULL,
            clearBeforeApply = true,
        })
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

                setStatus(self, result.message)
                self:Refresh()
                refreshOtherPanel()
            end,
        })
    end)

    exportButton:SetScript("OnClick", function()
        local selectedSource = ns:GetSelectedSource()
        if not selectedSource then
            setStatus(self, ns.L("error_select_source_first"))
            return
        end

        ns.UI.TransferDialog:ShowExport(selectedSource.key)
    end)

    importButton:SetScript("OnClick", function()
        ns.UI.TransferDialog:ShowImport(function(snapshot)
            templateInput:SetText(snapshot.sourceKey or "")
            self:Refresh()
            refreshOtherPanel()
        end)
    end)

    deleteButton:SetScript("OnClick", function()
        self:DeleteSelectedTemplate()
    end)

    return frame
end

function ProfilePanel:Refresh()
    if not self.characterInfo or not ns.DB then
        return
    end

    self:RefreshLocale()

    local record = ns.DB:RefreshCharacterRecord()
    local key = ns.DB:GetCharacterKey()
    local classTag = record and record.class or "UNKNOWN"
    local className = ns.ClassL(classTag)
    local specID = record and record.specID or 0
    self.characterInfo:SetText(ns.L("current_character", key, className, specID))

    if self.classIcon and CLASS_ICON_TCOORDS and CLASS_ICON_TCOORDS[classTag] then
        local coords = CLASS_ICON_TCOORDS[classTag]
        self.classIcon:SetTexture("Interface\\GLUES\\CHARACTERCREATE\\UI-CHARACTERCREATE-CLASSES")
        self.classIcon:SetTexCoord(coords[1], coords[2], coords[3], coords[4])
        self.classIcon:Show()
    elseif self.classIcon then
        self.classIcon:Hide()
    end

    if self.specIcon then
        local currentSpecIndex = GetSpecialization and GetSpecialization() or 0
        if currentSpecIndex and currentSpecIndex > 0 then
            local _, _, _, specIconTexture = GetSpecializationInfo(currentSpecIndex)
            if specIconTexture then
                self.specIcon:SetTexture(specIconTexture)
                self.specIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
                self.specIcon:Show()
            else
                self.specIcon:Hide()
            end
        else
            self.specIcon:Hide()
        end
    end

    self:RefreshSpecButtons()

    local selectedSource = ns:GetSelectedSource()
    if selectedSource and selectedSource.kind == ns.Constants.SOURCE_KIND.TEMPLATE and not ns.DB:GetTemplate(selectedSource.key) then
        ns:SetSelectedSource(nil, nil)
        selectedSource = nil
    end

    if selectedSource then
        self.selectedTemplateText:SetText(ns.L("selected_source", selectedSource.key))
    else
        self.selectedTemplateText:SetText(ns.L("source_none"))
    end

    self.templateNames = ns.Modules.ProfileManager:ListTemplates()
    if selectedSource and selectedSource.kind == ns.Constants.SOURCE_KIND.TEMPLATE then
        for index, templateName in ipairs(self.templateNames) do
            if templateName == selectedSource.key then
                self:EnsureTemplateVisible(index)
                break
            end
        end
    end
    self:PopulateRows()

    local selection = ns:GetSelectionState()
    local detailsText = ns.L("source_details_none")
    if selectedSource and selectedSource.kind == ns.Constants.SOURCE_KIND.TEMPLATE then
        local details = ns.Modules.ProfileManager:GetSourceDetails(selectedSource.kind, selectedSource.key)
        if details then
            detailsText = table.concat({
                ns.L("section_template_info"),
                ns.L("source_details_name_bullet", details.key),
                ns.L("source_details_saved_at_bullet", details.savedAt or "-"),
                ns.L("source_details_character_bullet", details.characterKey or "-"),
                ns.L("source_details_class_bullet", ns.ClassL(details.class or "UNKNOWN")),
                ns.L("source_details_spec_bullet", details.specID or 0),
                ns.L("source_details_spec_name_bullet", details.specName or "-"),
                ns.L(
                    "source_details_recorded_actions_bullet",
                    details.stats and details.stats.recordedActions or 0,
                    details.stats and details.stats.trackedSlots or 0
                ),
                ns.L("source_details_empty_slots_bullet", details.stats and details.stats.emptySlots or 0),
                ns.L("source_details_spells_bullet", details.stats and details.stats.spells or 0),
                ns.L("source_details_macros_bullet", details.stats and details.stats.macros or 0),
                ns.L("source_details_items_bullet", details.stats and details.stats.items or 0),
                ns.L("source_details_other_actions_bullet", details.stats and details.stats.other or 0),
                "",
                ns.L("section_apply_info"),
                ns.L("source_details_scope_bullet", ns.Modules.SlotMapper:DescribeSelection(selection.mode, selection)),
                ns.L(
                    "source_details_clear_bullet",
                    selection.clearBeforeApply and ns.L("source_details_yes") or ns.L("source_details_no")
                ),
            }, "\n")
        end
    end

    self.sourceDetailsText:SetText(detailsText)

    local canUndo = ns.Modules.UndoManager and ns.Modules.UndoManager:HasUndo()
    if self.undoButton then
        self.undoButton:SetEnabled(canUndo and true or false)
        self.undoButton:SetAlpha(canUndo and 1 or 0.45)
    end

    local hasTemplateSelection =
        selectedSource
        and selectedSource.kind == ns.Constants.SOURCE_KIND.TEMPLATE
        and ns.DB:GetTemplate(selectedSource.key)
    if self.deleteButton then
        self.deleteButton:SetEnabled(hasTemplateSelection and true or false)
        self.deleteButton:SetAlpha(hasTemplateSelection and 1 or 0.45)
    end
end
