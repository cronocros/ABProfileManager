local _, ns = ...

local ConfigPanel = {}
ns.UI.ConfigPanel = ConfigPanel

local function setStatus(target, message)
    local formatted = ns.Utils.FormatStatusMessage(message)
    if target and target.statusText then
        target.statusText:SetText("")
        target.statusText:SetText(formatted or "")
    end

    ns:SafeCall(ns.UI.MainWindow, "SetStatus", message)
end

local function showMainWindow()
    if not ns.UI.MainWindow.frame then
        ns.UI.MainWindow:Initialize()
    end

    if ns.UI.MainWindow.frame then
        ns.UI.MainWindow.frame:Show()
        if ns.UI.MainWindow.frame.Raise then
            ns.UI.MainWindow.frame:Raise()
        end
        ns:RefreshUI()
    end
end

local function getCharacterName()
    if type(UnitName) ~= "function" then
        return "?"
    end

    return UnitName("player") or "?"
end

local function getClassName()
    if type(UnitClass) ~= "function" then
        return "?"
    end

    local className = UnitClass("player")
    return className or "?"
end

local function getSpecName()
    if type(GetSpecialization) ~= "function" or type(GetSpecializationInfo) ~= "function" then
        return ns.L("stats_overlay_unknown_spec")
    end

    local specIndex = GetSpecialization()
    if not specIndex then
        return ns.L("stats_overlay_unknown_spec")
    end

    local _, specName = GetSpecializationInfo(specIndex)
    return specName or ns.L("stats_overlay_unknown_spec")
end

local function getStateLabel(enabled)
    return enabled and ns.L("state_enabled") or ns.L("state_disabled")
end

local function buildOverviewSummary()
    local tracker = ns.Modules and ns.Modules.ProfessionKnowledgeTracker
    local lastScan = tracker and tracker.GetLastScanLabel and tracker:GetLastScanLabel() or ""
    if lastScan == "" then
        lastScan = ns.L("config_overview_not_scanned")
    end

    return table.concat({
        ns.L("config_overview_header"),
        ns.L("config_overview_character", getCharacterName(), getClassName(), getSpecName()),
        ns.L(
            "config_overview_overlays",
            getStateLabel(ns.DB:IsStatsOverlayEnabled()),
            getStateLabel(ns.DB:IsProfessionKnowledgeOverlayEnabled()),
            getStateLabel(ns.DB:IsSilvermoonMapOverlayEnabled())
        ),
        ns.L("config_overview_profession_scan", lastScan),
        ns.L("config_overview_debug", getStateLabel(ns.DB:IsDebugEnabled())),
    }, "\n")
end

local function buildOverviewDetails()
    return table.concat({
        ns.L("config_overview_hint_window"),
        ns.L("config_overview_hint_drag"),
        ns.L("config_overview_hint_map"),
        ns.L("config_overview_hint_debug"),
        ns.L("config_version_info", ns.Constants.VERSION or "?"),
    }, "\n")
end

function ConfigPanel:ApplyLanguage(language, refs)
    ns.DB:SetLanguage(language)
    ns:RefreshUI()
    setStatus(refs, ns.L(
        "config_saved_language",
        language == ns.Constants.LANGUAGE.KOREAN and ns.L("config_language_korean") or ns.L("config_language_english")
    ))
end

function ConfigPanel:ApplyMinimapVisible(visible, refs)
    ns.DB:SetMinimapHidden(not visible)
    ns:RefreshUI()
    setStatus(refs, ns.L("config_saved_minimap", visible and ns.L("state_shown") or ns.L("state_hidden")))
end

function ConfigPanel:ApplyConfirmEnabled(enabled, refs)
    ns.DB:SetConfirmActions(enabled)
    ns:RefreshUI()
    setStatus(refs, ns.L("config_saved_confirm", enabled and ns.L("state_enabled") or ns.L("state_disabled")))
end

function ConfigPanel:ApplyDebugEnabled(enabled, refs)
    ns.DB:SetDebugEnabled(enabled)
    ns:RefreshUI()
    setStatus(refs, ns.L("config_saved_debug", enabled and ns.L("state_enabled") or ns.L("state_disabled")))
end

function ConfigPanel:ApplyStatsOverlayEnabled(enabled, refs)
    ns.DB:SetStatsOverlayEnabled(enabled)
    ns:RefreshUI()
    setStatus(refs, ns.L("config_saved_stats_overlay", enabled and ns.L("state_enabled") or ns.L("state_disabled")))
end

function ConfigPanel:ApplyProfessionOverlayEnabled(enabled, refs)
    ns.DB:SetProfessionKnowledgeOverlayEnabled(enabled)
    ns:RefreshUI()
    setStatus(refs, ns.L("config_saved_profession_overlay", enabled and ns.L("state_enabled") or ns.L("state_disabled")))
end

function ConfigPanel:ApplySilvermoonMapEnabled(enabled, refs)
    ns.DB:SetSilvermoonMapOverlayEnabled(enabled)
    ns:RefreshUI()
    setStatus(refs, ns.L("config_saved_silvermoon_map", enabled and ns.L("state_enabled") or ns.L("state_disabled")))
end

function ConfigPanel:BindControlSet(refs)
    refs.koreanButton:SetScript("OnClick", function()
        self:ApplyLanguage(ns.Constants.LANGUAGE.KOREAN, refs)
    end)

    refs.englishButton:SetScript("OnClick", function()
        self:ApplyLanguage(ns.Constants.LANGUAGE.ENGLISH, refs)
    end)

    refs.minimapCheck:SetScript("OnClick", function(currentCheck)
        self:ApplyMinimapVisible(currentCheck:GetChecked(), refs)
    end)

    refs.confirmCheck:SetScript("OnClick", function(currentCheck)
        self:ApplyConfirmEnabled(currentCheck:GetChecked(), refs)
    end)

    refs.debugCheck:SetScript("OnClick", function(currentCheck)
        self:ApplyDebugEnabled(currentCheck:GetChecked(), refs)
    end)

    refs.statsOverlayCheck:SetScript("OnClick", function(currentCheck)
        self:ApplyStatsOverlayEnabled(currentCheck:GetChecked(), refs)
    end)

    refs.professionOverlayCheck:SetScript("OnClick", function(currentCheck)
        self:ApplyProfessionOverlayEnabled(currentCheck:GetChecked(), refs)
    end)

    refs.silvermoonMapCheck:SetScript("OnClick", function(currentCheck)
        self:ApplySilvermoonMapEnabled(currentCheck:GetChecked(), refs)
    end)

    if refs.openWindowButton then
        refs.openWindowButton:SetScript("OnClick", showMainWindow)
    end
end

function ConfigPanel:RefreshControlSet(refs)
    if not refs or not refs.title then
        return
    end

    refs.title:SetText(ns.L("config_title"))
    refs.languageLabel:SetText(ns.L("config_language"))
    refs.languageHint:SetText(ns.L("config_language_hint"))
    refs.koreanButton:SetText(ns.L("config_language_korean"))
    refs.englishButton:SetText(ns.L("config_language_english"))
    refs.minimapLabel:SetText(ns.L("config_minimap"))
    refs.minimapCheck.Text:SetText(ns.L("config_minimap_show"))
    refs.confirmLabel:SetText(ns.L("config_confirm"))
    refs.confirmCheck.Text:SetText(ns.L("config_confirm_show"))
    refs.debugLabel:SetText(ns.L("config_debug"))
    refs.debugCheck.Text:SetText(ns.L("config_debug_show"))
    refs.statsOverlayLabel:SetText(ns.L("config_stats_overlay"))
    refs.statsOverlayCheck.Text:SetText(ns.L("config_stats_overlay_show"))
    refs.professionOverlayLabel:SetText(ns.L("config_profession_overlay"))
    refs.professionOverlayCheck.Text:SetText(ns.L("config_profession_overlay_show"))
    refs.silvermoonMapLabel:SetText(ns.L("config_silvermoon_map"))
    refs.silvermoonMapCheck.Text:SetText(ns.L("config_silvermoon_map_show"))
    refs.helpText:SetText(buildOverviewSummary())
    refs.infoText:SetText(buildOverviewDetails())

    if refs.openWindowButton then
        refs.openWindowButton:SetText(ns.L("config_open_window"))
    end

    refs.minimapCheck:SetChecked(not ns.DB:GetMinimapConfig().hide)
    refs.confirmCheck:SetChecked(ns.DB:ShouldConfirmActions())
    refs.debugCheck:SetChecked(ns.DB:IsDebugEnabled())
    refs.statsOverlayCheck:SetChecked(ns.DB:IsStatsOverlayEnabled())
    refs.professionOverlayCheck:SetChecked(ns.DB:IsProfessionKnowledgeOverlayEnabled())
    refs.silvermoonMapCheck:SetChecked(ns.DB:IsSilvermoonMapOverlayEnabled())
    ns.UI.Widgets.SetButtonSelected(refs.koreanButton, ns.DB:GetLanguage() == ns.Constants.LANGUAGE.KOREAN)
    ns.UI.Widgets.SetButtonSelected(refs.englishButton, ns.DB:GetLanguage() == ns.Constants.LANGUAGE.ENGLISH)
end

function ConfigPanel:BuildControlSet(parent, options)
    options = options or {}

    local widgets = ns.UI.Widgets
    local refs = {}
    local columnWidth = options.columnWidth or 420
    local columnGap = options.columnGap or 12
    local textWidth = options.textWidth or (columnWidth - 36)
    local helpWidth = options.helpWidth or ((columnWidth * 2) + columnGap)

    refs.title = widgets.CreateLabel(parent, "", nil, 16, options.titleY or -20, "GameFontHighlightLarge")

    local settingsBoxHeight = 338

    local languageBox = widgets.CreatePanelBox(parent, columnWidth, settingsBoxHeight, nil)
    languageBox:SetPoint("TOPLEFT", refs.title, "BOTTOMLEFT", 0, -18)
    refs.languageLabel = widgets.CreateLabel(languageBox, "", nil, 12, -14, "GameFontHighlight")
    refs.languageHint = widgets.CreateLabel(languageBox, "", refs.languageLabel, 0, -12)
    refs.languageHint:SetWidth(textWidth)
    refs.languageHint:SetJustifyH("LEFT")
    refs.koreanButton = widgets.CreateButton(languageBox, "", 110, 26)
    refs.koreanButton:SetPoint("TOPLEFT", refs.languageHint, "BOTTOMLEFT", 0, -16)
    refs.englishButton = widgets.CreateButton(languageBox, "", 110, 26)
    refs.englishButton:SetPoint("LEFT", refs.koreanButton, "RIGHT", 10, 0)
    refs.minimapLabel = widgets.CreateLabel(languageBox, "", refs.koreanButton, 0, -20, "GameFontHighlight")
    refs.minimapCheck = widgets.CreateCheckButton(languageBox, "")
    refs.minimapCheck:SetPoint("TOPLEFT", refs.minimapLabel, "BOTTOMLEFT", -4, -10)
    refs.confirmLabel = widgets.CreateLabel(languageBox, "", refs.minimapCheck, 4, -16, "GameFontHighlight")
    refs.confirmCheck = widgets.CreateCheckButton(languageBox, "")
    refs.confirmCheck:SetPoint("TOPLEFT", refs.confirmLabel, "BOTTOMLEFT", -4, -10)
    refs.debugLabel = widgets.CreateLabel(languageBox, "", refs.confirmCheck, 4, -16, "GameFontHighlight")
    refs.debugCheck = widgets.CreateCheckButton(languageBox, "")
    refs.debugCheck:SetPoint("TOPLEFT", refs.debugLabel, "BOTTOMLEFT", -4, -10)

    local overlayBox = widgets.CreatePanelBox(parent, columnWidth, settingsBoxHeight, nil)
    overlayBox:SetPoint("LEFT", languageBox, "RIGHT", columnGap, 0)
    refs.statsOverlayLabel = widgets.CreateLabel(overlayBox, "", nil, 12, -14, "GameFontHighlight")
    refs.statsOverlayCheck = widgets.CreateCheckButton(overlayBox, "")
    refs.statsOverlayCheck:SetPoint("TOPLEFT", refs.statsOverlayLabel, "BOTTOMLEFT", -4, -10)
    refs.professionOverlayLabel = widgets.CreateLabel(overlayBox, "", refs.statsOverlayCheck, 4, -16, "GameFontHighlight")
    refs.professionOverlayCheck = widgets.CreateCheckButton(overlayBox, "")
    refs.professionOverlayCheck:SetPoint("TOPLEFT", refs.professionOverlayLabel, "BOTTOMLEFT", -4, -10)
    refs.silvermoonMapLabel = widgets.CreateLabel(overlayBox, "", refs.professionOverlayCheck, 4, -16, "GameFontHighlight")
    refs.silvermoonMapCheck = widgets.CreateCheckButton(overlayBox, "")
    refs.silvermoonMapCheck:SetPoint("TOPLEFT", refs.silvermoonMapLabel, "BOTTOMLEFT", -4, -10)

    refs.minimapCheck.Text:SetWidth(textWidth)
    refs.minimapCheck.Text:SetJustifyH("LEFT")
    refs.confirmCheck.Text:SetWidth(textWidth)
    refs.confirmCheck.Text:SetJustifyH("LEFT")
    refs.debugCheck.Text:SetWidth(textWidth)
    refs.debugCheck.Text:SetJustifyH("LEFT")
    refs.statsOverlayCheck.Text:SetWidth(textWidth)
    refs.statsOverlayCheck.Text:SetJustifyH("LEFT")
    refs.professionOverlayCheck.Text:SetWidth(textWidth)
    refs.professionOverlayCheck.Text:SetJustifyH("LEFT")
    refs.silvermoonMapCheck.Text:SetWidth(textWidth)
    refs.silvermoonMapCheck.Text:SetJustifyH("LEFT")

    local helpBox = widgets.CreatePanelBox(parent, helpWidth, options.showOpenButton and 184 or 160, nil)
    helpBox:SetPoint("TOPLEFT", languageBox, "BOTTOMLEFT", 0, -20)
    refs.helpText = widgets.CreateLabel(helpBox, "", nil, 12, -14)
    refs.helpText:SetWidth(helpWidth - 32)
    refs.helpText:SetJustifyH("LEFT")
    refs.infoText = widgets.CreateLabel(helpBox, "", refs.helpText, 0, -14)
    refs.infoText:SetWidth(helpWidth - 32)
    refs.infoText:SetJustifyH("LEFT")

    if options.showOpenButton then
        refs.openWindowButton = widgets.CreateButton(helpBox, "", 150, 28)
        refs.openWindowButton:SetPoint("BOTTOMLEFT", helpBox, "BOTTOMLEFT", 14, 14)
    end

    refs.statusText = widgets.CreateLabel(parent, "", helpBox, 0, -18)
    refs.statusText:SetWidth(options.statusWidth or helpWidth)
    refs.statusText:SetJustifyH("LEFT")

    self:BindControlSet(refs)
    return refs
end

function ConfigPanel:RegisterSettingsCategory()
    if self.settingsRegistered then
        return
    end

    local panel = self.settingsFrame
    if not panel then
        panel = CreateFrame("Frame", "ABPMSettingsCategoryPanel", UIParent)
        panel.name = ns.Constants.TITLE
        panel:SetSize(780, 620)

        self.settingsFrame = panel
        self.settingsRefs = self:BuildControlSet(panel, {
            titleY = -16,
            showOpenButton = true,
            columnWidth = 344,
            columnGap = 16,
            textWidth = 308,
            helpWidth = 704,
            statusWidth = 704,
        })

        panel:SetScript("OnShow", function()
            self:Refresh()
        end)
    end

    if Settings and Settings.RegisterCanvasLayoutCategory and Settings.RegisterAddOnCategory then
        local category = nil

        local ok, result = pcall(Settings.RegisterCanvasLayoutCategory, panel, ns.Constants.TITLE, ns.Constants.TITLE)
        if ok then
            category = result
        end

        if not category then
            ok, result = pcall(Settings.RegisterCanvasLayoutCategory, panel, ns.Constants.TITLE)
            if ok then
                category = result
            end
        end

        if category then
            local addOk = pcall(Settings.RegisterAddOnCategory, category)
            if addOk then
                self.settingsCategory = category
                ns:SafeCall(ns.UI.AddonSettingsPages, "Register", category)
                self.settingsRegistered = true
                return
            end
        end
    end

    if InterfaceOptions_AddCategory then
        InterfaceOptions_AddCategory(panel)
        self.settingsRegistered = true
    end
end

function ConfigPanel:Initialize()
    self:RegisterSettingsCategory()
end

function ConfigPanel:Create(parent)
    if self.frame then
        return self.frame
    end

    local frame = CreateFrame("Frame", nil, parent)
    frame:SetAllPoints()

    self.frame = frame
    self.mainRefs = self:BuildControlSet(frame, {
        titleY = -20,
        showOpenButton = false,
        statusWidth = 852,
    })

    self.title = self.mainRefs.title
    self.statusText = self.mainRefs.statusText

    self:Refresh()
    return frame
end

function ConfigPanel:Refresh()
    if not self.settingsRegistered then
        self:RegisterSettingsCategory()
    end

    self:RefreshControlSet(self.mainRefs)
    self:RefreshControlSet(self.settingsRefs)
    ns:SafeCall(ns.UI.AddonSettingsPages, "Refresh")
end
