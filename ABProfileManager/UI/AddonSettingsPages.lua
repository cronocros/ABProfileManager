local _, ns = ...

local AddonSettingsPages = {}
ns.UI.AddonSettingsPages = AddonSettingsPages

local function openTab(tabName)
    ns:SafeCall(ns.UI.MainWindow, "OpenToTab", tabName)
end

local function getTemplateCount()
    return ns.Utils.TableCount(ns.DB and ns.DB:GetTemplates() or {})
end

local function getSelectionSummary()
    local selection = ns:GetSelectionState()
    local normalized = ns.Modules.RangeCopyManager and ns.Modules.RangeCopyManager:NormalizeSelection(selection)
    if normalized and normalized.summary then
        return normalized.summary
    end

    return ns.L("selection_mode_full")
end

local function getProfessionSummary()
    local tracker = ns.Modules and ns.Modules.ProfessionKnowledgeTracker
    local count = tracker and #(tracker:GetKnownProfessions()) or 0
    local lastScan = tracker and tracker:GetLastScanLabel() or ""
    if lastScan == "" then
        lastScan = ns.L("config_overview_not_scanned")
    end

    return count, lastScan
end

function AddonSettingsPages:CreatePanel(panelKey, tabName, titleKey, bodyKey, buttonKey, summaryBuilder)
    local frame = CreateFrame("Frame", nil, UIParent)
    frame.name = ns.Constants.TITLE .. "_" .. panelKey
    frame:SetSize(660, 560)

    frame.title = ns.UI.Widgets.CreateLabel(frame, "", nil, 18, -18, "GameFontHighlightLarge")

    frame.bodyBox = ns.UI.Widgets.CreatePanelBox(frame, 612, 148, nil)
    frame.bodyBox:SetPoint("TOPLEFT", frame.title, "BOTTOMLEFT", 0, -18)

    frame.bodyText = ns.UI.Widgets.CreateLabel(frame.bodyBox, "", nil, 14, -16)
    frame.bodyText:SetWidth(582)
    frame.bodyText:SetJustifyH("LEFT")
    if frame.bodyText.SetWordWrap then
        frame.bodyText:SetWordWrap(true)
    end

    frame.summaryBox = ns.UI.Widgets.CreatePanelBox(frame, 612, 136, nil)
    frame.summaryBox:SetPoint("TOPLEFT", frame.bodyBox, "BOTTOMLEFT", 0, -18)

    frame.summaryText = ns.UI.Widgets.CreateLabel(frame.summaryBox, "", nil, 14, -16)
    frame.summaryText:SetWidth(582)
    frame.summaryText:SetJustifyH("LEFT")
    if frame.summaryText.SetWordWrap then
        frame.summaryText:SetWordWrap(true)
    end

    frame.openButton = ns.UI.Widgets.CreateButton(frame, "", 176, 28)
    frame.openButton:SetPoint("TOPLEFT", frame.summaryBox, "BOTTOMLEFT", 0, -18)
    frame.openButton:SetScript("OnClick", function()
        openTab(tabName)
    end)

    frame.refreshPanel = function(currentFrame)
        currentFrame.title:SetText(ns.L(titleKey))
        currentFrame.bodyText:SetText(ns.L(bodyKey))
        currentFrame.openButton:SetText(ns.L(buttonKey))
        currentFrame.summaryText:SetText(summaryBuilder())
    end

    frame:SetScript("OnShow", function(currentFrame)
        currentFrame:refreshPanel()
    end)

    return frame
end

function AddonSettingsPages:CreatePanels()
    if self.panels then
        return self.panels
    end

    self.panels = {
        templates = self:CreatePanel(
            "Templates",
            "profiles",
            "settings_subpanel_templates_title",
            "settings_subpanel_templates_body",
            "settings_subpanel_button_templates",
            function()
                return ns.L("settings_subpanel_templates_summary", getTemplateCount())
            end
        ),
        actionBars = self:CreatePanel(
            "ActionBars",
            "action_bars",
            "settings_subpanel_action_bars_title",
            "settings_subpanel_action_bars_body",
            "settings_subpanel_button_action_bars",
            function()
                return ns.L("settings_subpanel_action_bars_summary", getSelectionSummary())
            end
        ),
        professions = self:CreatePanel(
            "Professions",
            "professions",
            "settings_subpanel_professions_title",
            "settings_subpanel_professions_body",
            "settings_subpanel_button_professions",
            function()
                local count, lastScan = getProfessionSummary()
                return ns.L("settings_subpanel_professions_summary", count, lastScan)
            end
        ),
        quests = self:CreatePanel(
            "Quests",
            "quests",
            "settings_subpanel_quests_title",
            "settings_subpanel_quests_body",
            "settings_subpanel_button_quests",
            function()
                return ns.L("settings_subpanel_quests_summary")
            end
        ),
    }

    return self.panels
end

function AddonSettingsPages:Register(parentCategory)
    if self.registered or not parentCategory or not Settings or not Settings.RegisterCanvasLayoutSubcategory then
        return
    end

    local panels = self:CreatePanels()
    local definitions = {
        { key = "templates", label = ns.L("settings_category_templates") },
        { key = "actionBars", label = ns.L("settings_category_action_bars") },
        { key = "professions", label = ns.L("settings_category_professions") },
        { key = "quests", label = ns.L("settings_category_quests") },
    }

    self.categories = {}

    for _, definition in ipairs(definitions) do
        local panel = panels[definition.key]
        if panel then
            local ok, category = pcall(
                Settings.RegisterCanvasLayoutSubcategory,
                parentCategory,
                panel,
                definition.label,
                definition.label
            )
            if (not ok or not category) then
                ok, category = pcall(Settings.RegisterCanvasLayoutSubcategory, parentCategory, panel, definition.label)
            end
            if ok and category then
                self.categories[#self.categories + 1] = category
            end
        end
    end

    self.registered = true
end

function AddonSettingsPages:Refresh()
    for _, panel in pairs(self.panels or {}) do
        if panel.refreshPanel then
            panel:refreshPanel()
        end
    end
end
