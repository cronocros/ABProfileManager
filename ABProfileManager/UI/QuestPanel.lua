local _, ns = ...

local QuestPanel = {}
ns.UI.QuestPanel = QuestPanel

local function setStatus(message)
    ns:SafeCall(ns.UI.MainWindow, "SetStatus", message)
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

local function openQuestFromLink(link)
    local questID = tonumber(tostring(link or ""):match("^abpmquest:(%d+)$"))
    if not questID or questID <= 0 then
        return false
    end

    if C_QuestLog and type(C_QuestLog.SetSelectedQuest) == "function" then
        pcall(C_QuestLog.SetSelectedQuest, questID)
    elseif C_QuestLog and type(C_QuestLog.GetLogIndexForQuestID) == "function" and type(SelectQuestLogEntry) == "function" then
        local logIndex = C_QuestLog.GetLogIndexForQuestID(questID)
        if logIndex and logIndex > 0 then
            pcall(SelectQuestLogEntry, logIndex)
        end
    end

    if C_QuestLog and type(C_QuestLog.OpenToQuestDetails) == "function" then
        local ok = pcall(C_QuestLog.OpenToQuestDetails, questID)
        if ok then
            return true
        end
    end

    if type(QuestMapFrame_OpenToQuestDetails) == "function" then
        local ok = pcall(QuestMapFrame_OpenToQuestDetails, questID)
        if ok then
            return true
        end
    end

    if type(WorldMapFrame_ShowQuestDetails) == "function" then
        local ok = pcall(WorldMapFrame_ShowQuestDetails, questID)
        if ok then
            return true
        end
    end

    return false
end

local function configureQuestListBox(listBox)
    if not listBox or not listBox.editBox then
        return
    end

    local editBox = listBox.editBox
    if editBox.SetHyperlinksEnabled then
        editBox:SetHyperlinksEnabled(true)
    end
    editBox:SetScript("OnHyperlinkClick", function(_, link)
        if openQuestFromLink(link) then
            ns:SafeCall(ns.UI.MainWindow, "SetStatus", ns.L("quest_refresh_done"))
        end
    end)
    editBox:SetScript("OnHyperlinkEnter", function(currentBox)
        if currentBox and currentBox.SetCursorPosition then
            currentBox:SetCursorPosition(0)
        end
    end)
    editBox:SetScript("OnMouseDown", nil)
    editBox:SetScript("OnEditFocusGained", function(currentBox)
        currentBox:ClearFocus()
    end)
end

local function queueRefresh(panel)
    if not panel then
        return
    end

    if ns.Modules.QuestManager then
        ns.Modules.QuestManager:Invalidate()
    end

    panel:Refresh(true)
    if C_Timer and C_Timer.After then
        C_Timer.After(0.15, function()
            if panel.frame then
                panel:Refresh(true)
            end
        end)
        C_Timer.After(0.45, function()
            if panel.frame then
                panel:Refresh(true)
            end
        end)
    end
end

function QuestPanel:RefreshLocale()
    if not self.frame then
        return
    end

    self.title:SetText(ns.L("quests_title"))
    self.summaryBox.title:SetText(ns.L("quest_summary_title"))
    self.actionsBox.title:SetText(ns.L("quest_actions_title"))
    self.listBox.title:SetText(ns.L("quest_candidates_title"))
    self.hint:SetText(ns.L("quest_actions_hint"))
    self.refreshButton:SetText(ns.L("quest_refresh"))
    self.safeCleanupButton:SetText(ns.L("quest_safe_cleanup"))
    self.abandonAllButton:SetText(ns.L("quest_abandon_all"))
end

function QuestPanel:RefreshInternal(forceScan)
    if not self.frame or not ns.Modules.QuestManager then
        return
    end

    self:RefreshLocale()

    local scan = ns.Modules.QuestManager:Scan(forceScan and true or false)
    self.summaryText:SetText(ns.Modules.QuestManager:BuildSummaryText(scan))
    self.safeListTitle:SetText(ns.L("quest_list_safe_header", #(scan.safeCandidates or {})))
    self.keepListTitle:SetText(ns.L("quest_list_keep_header", #(scan.keptQuests or {})))
    self.allListTitle:SetText(ns.L("quest_list_all_header", #(scan.allCandidates or {})))
    self.safeListText:SetText(ns.Modules.QuestManager:BuildSafeSectionText(scan))
    self.keepListText:SetText(ns.Modules.QuestManager:BuildKeepSectionText(scan))
    self.allListText:SetText(ns.Modules.QuestManager:BuildAllSectionText(scan))

    local supported = scan and scan.supported
    local safeCount = supported and #(scan.safeCandidates or {}) or 0
    local allCount = supported and #(scan.allCandidates or {}) or 0

    self.refreshButton:SetEnabled(true)
    self.safeCleanupButton:SetEnabled(supported and safeCount > 0)
    self.abandonAllButton:SetEnabled(supported and allCount > 0)
    self.safeCleanupButton:SetAlpha((supported and safeCount > 0) and 1 or 0.45)
    self.abandonAllButton:SetAlpha((supported and allCount > 0) and 1 or 0.45)
end

function QuestPanel:Refresh(forceScan)
    if self.isRefreshing then
        return
    end

    self.isRefreshing = true
    local ok, err = pcall(function()
        self:RefreshInternal(forceScan)
    end)
    self.isRefreshing = false

    if not ok then
        if ns.Utils and ns.Utils.Debug then
            ns.Utils.Debug("QuestPanel refresh failed: " .. tostring(err))
        end
        ns:SafeCall(ns.UI.MainWindow, "SetStatus", ns.L("status_quest_refresh_failed"))
    end
end

function QuestPanel:Create(parent)
    if self.frame then
        return self.frame
    end

    local widgets = ns.UI.Widgets
    local frame = CreateFrame("Frame", nil, parent)
    frame:SetAllPoints()

    local title = widgets.CreateLabel(frame, "", nil, 16, -14, "GameFontHighlightLarge")

    local summaryBox = widgets.CreatePanelBox(frame, 420, 214, "")
    summaryBox:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -10)
    local summaryText = widgets.CreateScrollTextBox(summaryBox, 384, 170)
    summaryText:SetPoint("TOPLEFT", 14, -28)

    local actionsBox = widgets.CreatePanelBox(frame, 420, 214, "")
    actionsBox:SetPoint("TOPLEFT", summaryBox, "TOPRIGHT", 12, 0)

    local hint = widgets.CreateLabel(actionsBox, "", nil, 14, -28)
    hint:SetWidth(382)
    hint:SetJustifyH("LEFT")
    if hint.SetWordWrap then
        hint:SetWordWrap(true)
    end

    local refreshButton = widgets.CreateButton(actionsBox, "", 382, 30)
    refreshButton:SetPoint("TOPLEFT", hint, "BOTTOMLEFT", 0, -14)

    local safeCleanupButton = widgets.CreateButton(actionsBox, "", 382, 42)
    safeCleanupButton:SetPoint("TOPLEFT", refreshButton, "BOTTOMLEFT", 0, -12)

    local abandonAllButton = widgets.CreateButton(actionsBox, "", 382, 42)
    abandonAllButton:SetPoint("TOPLEFT", safeCleanupButton, "BOTTOMLEFT", 0, -10)

    local listBox = widgets.CreatePanelBox(frame, 852, 408, "")
    listBox:SetPoint("TOPLEFT", summaryBox, "BOTTOMLEFT", 0, -12)

    local sectionWidth = 254
    local sectionGap = 13
    local sectionTitleY = -34
    local sectionTextY = -66
    local sectionTextHeight = 310
    local safeListTitle = widgets.CreateLabel(listBox, "", nil, 14, sectionTitleY, "GameFontHighlightLarge")
    local safeListText = widgets.CreateScrollEditBox(listBox, sectionWidth, sectionTextHeight, true)
    safeListText:SetPoint("TOPLEFT", 14, sectionTextY)

    local keepListTitle = widgets.CreateLabel(listBox, "", nil, 14 + sectionWidth + sectionGap, sectionTitleY, "GameFontHighlightLarge")
    local keepListText = widgets.CreateScrollEditBox(listBox, sectionWidth, sectionTextHeight, true)
    keepListText:SetPoint("TOPLEFT", 14 + sectionWidth + sectionGap, sectionTextY)

    local allListTitle = widgets.CreateLabel(listBox, "", nil, 14 + ((sectionWidth + sectionGap) * 2), sectionTitleY, "GameFontHighlightLarge")
    local allListText = widgets.CreateScrollEditBox(listBox, sectionWidth, sectionTextHeight, true)
    allListText:SetPoint("TOPLEFT", 14 + ((sectionWidth + sectionGap) * 2), sectionTextY)

    configureQuestListBox(safeListText)
    configureQuestListBox(keepListText)
    configureQuestListBox(allListText)

    refreshButton:SetScript("OnClick", function()
        queueRefresh(self)
        setStatus(ns.L("quest_refresh_done"))
    end)
    refreshButton:SetScript("OnEnter", function(currentButton)
        setTooltip(currentButton, ns.L("quest_refresh_tooltip"))
    end)
    refreshButton:SetScript("OnLeave", GameTooltip_Hide)

    safeCleanupButton:SetScript("OnClick", function()
        ns.Modules.QuestManager:RequestSafeCleanup({
            onComplete = function(result, err)
                if not result then
                    setStatus(err)
                    queueRefresh(self)
                    return
                end

                queueRefresh(self)
                setStatus(result.message)
            end,
        })
    end)
    safeCleanupButton:SetScript("OnEnter", function(currentButton)
        setTooltip(currentButton, ns.L("quest_safe_cleanup_tooltip"))
    end)
    safeCleanupButton:SetScript("OnLeave", GameTooltip_Hide)

    abandonAllButton:SetScript("OnClick", function()
        ns.Modules.QuestManager:RequestAbandonAll({
            onComplete = function(result, err)
                if not result then
                    setStatus(err)
                    queueRefresh(self)
                    return
                end

                queueRefresh(self)
                setStatus(result.message)
            end,
        })
    end)
    abandonAllButton:SetScript("OnEnter", function(currentButton)
        setTooltip(currentButton, ns.L("quest_abandon_all_tooltip"))
    end)
    abandonAllButton:SetScript("OnLeave", GameTooltip_Hide)

    self.frame = frame
    self.title = title
    self.summaryBox = summaryBox
    self.summaryText = summaryText
    self.actionsBox = actionsBox
    self.hint = hint
    self.refreshButton = refreshButton
    self.safeCleanupButton = safeCleanupButton
    self.abandonAllButton = abandonAllButton
    self.listBox = listBox
    self.safeListTitle = safeListTitle
    self.keepListTitle = keepListTitle
    self.allListTitle = allListTitle
    self.safeListText = safeListText
    self.keepListText = keepListText
    self.allListText = allListText

    self:Refresh(true)
    return frame
end
