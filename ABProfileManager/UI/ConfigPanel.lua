local _, ns = ...

local ConfigPanel = {}
ns.UI.ConfigPanel = ConfigPanel

local COMBAT_TEXT_MODE_OPTIONS = {
    { value = 1, labelKey = "config_combat_text_mode_up" },
    { value = 2, labelKey = "config_combat_text_mode_down" },
    { value = 3, labelKey = "config_combat_text_mode_arc" },
}

local TYPOGRAPHY_OPTIONS = {
    { domain = "ui", labelKey = "config_typography_ui" },
    { domain = "tooltip", labelKey = "config_typography_tooltip" },
    { domain = "statsOverlay", labelKey = "config_typography_stats_overlay" },
    { domain = "professionOverlay", labelKey = "config_typography_profession_overlay" },
}

local TYPOGRAPHY_LABEL_KEYS = {
    ui = "config_typography_ui",
    tooltip = "config_typography_tooltip",
    statsOverlay = "config_typography_stats_overlay",
    professionOverlay = "config_typography_profession_overlay",
}

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

local function getCombatTextModeLabelKey(mode)
    local numeric = tonumber(mode)
    if numeric == 1 then
        return "config_combat_text_mode_up"
    end
    if numeric == 2 then
        return "config_combat_text_mode_down"
    end

    return "config_combat_text_mode_arc"
end

local function formatOffsetValue(value)
    value = math.floor((tonumber(value) or 0) + 0.5)
    if value > 0 then
        return string.format("+%dpt", value)
    end
    return string.format("%dpt", value)
end

local function buildOverviewText()
    local tracker = ns.Modules and ns.Modules.ProfessionKnowledgeTracker
    local lastScan = tracker and tracker.GetLastScanLabel and tracker:GetLastScanLabel() or ""
    if lastScan == "" then
        lastScan = ns.L("config_overview_not_scanned")
    end

    local authorLine = string.format(
        "%s / %s",
        ns.L("config_overview_author_header"),
        ns.L("config_overview_author", ns.Constants.AUTHOR or "-", ns.Constants.CONTACT_EMAIL or "-")
    )

    return table.concat({
        ns.L("config_overview_header"),
        ns.L("config_overview_character", getCharacterName(), getClassName(), getSpecName()),
        ns.L(
            "config_overview_overlays",
            getStateLabel(ns.DB:IsStatsOverlayEnabled()),
            getStateLabel(ns.DB:IsProfessionKnowledgeOverlayEnabled()),
            getStateLabel(ns.DB:IsSilvermoonMapOverlayEnabled())
        ),
        ns.L(
            "config_overview_combat_text",
            getStateLabel(ns.DB:IsCombatTextManaged()),
            ns.L(getCombatTextModeLabelKey(ns.DB:GetCombatTextFloatMode()))
        ),
        ns.L("config_overview_profession_scan", lastScan),
        ns.L("config_overview_debug", getStateLabel(ns.DB:IsDebugEnabled())),
        ns.L("config_overview_storage"),
        "",
        ns.L("config_overview_guide_header"),
        ns.L("config_overview_hint_window"),
        ns.L("config_overview_hint_drag"),
        ns.L("config_overview_hint_map"),
        ns.L("config_overview_hint_tomtom"),
        ns.L("config_overview_hint_debug"),
        "",
        authorLine,
        "",
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

function ConfigPanel:ApplyMouseMoveRestore(enabled, refs)
    ns.DB:SetMouseMoveRestoreEnabled(enabled)
    if enabled and type(SetCVar) == "function" then
        pcall(SetCVar, "autoInteract", "1")
    end
    ns:RefreshUI()
    setStatus(refs, ns.L("config_saved_mouse_move_restore", enabled and ns.L("state_enabled") or ns.L("state_disabled")))
end

function ConfigPanel:ApplyTypographyOffset(domain, value, refs)
    value = ns.DB:SetTypographyOffset(domain, value)
    ns:RefreshUI()
    setStatus(refs, ns.L("config_saved_typography", ns.L(TYPOGRAPHY_LABEL_KEYS[domain] or "config_typography_ui"), formatOffsetValue(value)))
end

function ConfigPanel:ApplyCombatTextManaged(enabled, refs)
    ns.DB:SetCombatTextManaged(enabled)
    if enabled then
        local manager = ns.Modules and ns.Modules.CombatTextManager
        if not manager or manager:ApplyConfiguredSettings() == false then
            ns:RefreshUI()
            setStatus(refs, ns.L("config_saved_combat_text_apply_failed"))
            return
        end
        if manager.QueueReapply then
            manager:QueueReapply({ 0.25, 1.25 })
        end
    end

    ns:RefreshUI()
    setStatus(refs, ns.L("config_saved_combat_text_managed", enabled and ns.L("state_enabled") or ns.L("state_disabled")))
end

function ConfigPanel:ApplyCombatTextField(refs, statusMessage)
    local manager = ns.Modules and ns.Modules.CombatTextManager
    ns.DB:SetCombatTextManaged(true)
    if not manager or manager:ApplyConfiguredSettings() == false then
        ns:RefreshUI()
        setStatus(refs, ns.L("config_saved_combat_text_apply_failed"))
        return
    end
    if manager.QueueReapply then
        manager:QueueReapply({ 0.25, 1.25 })
    end

    ns:RefreshUI()
    setStatus(refs, statusMessage)
end

function ConfigPanel:ApplyCombatTextEnabled(enabled, refs)
    ns.DB:SetCombatTextEnabled(enabled)
    self:ApplyCombatTextField(refs, ns.L("config_saved_combat_text_enabled", enabled and ns.L("state_enabled") or ns.L("state_disabled")))
end

function ConfigPanel:ApplyCombatTextDamage(enabled, refs)
    ns.DB:SetCombatTextDamageEnabled(enabled)
    self:ApplyCombatTextField(refs, ns.L("config_saved_combat_text_damage", enabled and ns.L("state_enabled") or ns.L("state_disabled")))
end

function ConfigPanel:ApplyCombatTextHealing(enabled, refs)
    ns.DB:SetCombatTextHealingEnabled(enabled)
    self:ApplyCombatTextField(refs, ns.L("config_saved_combat_text_healing", enabled and ns.L("state_enabled") or ns.L("state_disabled")))
end

function ConfigPanel:ApplyCombatTextDirectionalDamage(enabled, refs)
    ns.DB:SetCombatTextDirectionalDamageEnabled(enabled)
    self:ApplyCombatTextField(refs, ns.L("config_saved_combat_text_directional", enabled and ns.L("state_enabled") or ns.L("state_disabled")))
end

function ConfigPanel:ApplyCombatTextMode(mode, refs, labelKey)
    ns.DB:SetCombatTextFloatMode(mode)
    self:ApplyCombatTextField(refs, ns.L("config_saved_combat_text_mode", ns.L(labelKey)))
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

    refs.mouseMoveRestoreCheck:SetScript("OnClick", function(currentCheck)
        self:ApplyMouseMoveRestore(currentCheck:GetChecked(), refs)
    end)

    refs.statsOverlayCheck:SetScript("OnClick", function(currentCheck)
        self:ApplyStatsOverlayEnabled(currentCheck:GetChecked(), refs)
    end)

    refs.professionOverlayCheck:SetScript("OnClick", function(currentCheck)
        self:ApplyProfessionOverlayEnabled(currentCheck:GetChecked(), refs)
    end)

    for _, entry in ipairs(refs.typographySliders or {}) do
        entry.slider.slider:SetScript("OnValueChanged", function(currentSlider, value)
            entry.slider:SetValueText(value)
            local rounded = math.floor((tonumber(value) or 0) + 0.5)
            if ns.DB:GetTypographyOffset(entry.domain) ~= rounded then
                self:ApplyTypographyOffset(entry.domain, rounded, refs)
            end
        end)
    end

    refs.combatTextManageCheck:SetScript("OnClick", function(currentCheck)
        self:ApplyCombatTextManaged(currentCheck:GetChecked(), refs)
    end)

    refs.combatTextDirectionalCheck:SetScript("OnClick", function(currentCheck)
        self:ApplyCombatTextDirectionalDamage(currentCheck:GetChecked(), refs)
    end)

    for index, option in ipairs(COMBAT_TEXT_MODE_OPTIONS) do
        refs.combatTextModeButtons[index]:SetScript("OnClick", function()
            self:ApplyCombatTextMode(option.value, refs, option.labelKey)
        end)
    end

    if refs.openWindowButton then
        refs.openWindowButton:SetScript("OnClick", showMainWindow)
    end
end

function ConfigPanel:RefreshControlSet(refs)
    if not refs or not refs.title then
        return
    end

    refs.title:SetText(ns.L("config_title"))
    refs.generalBox.title:SetText(ns.L("config_general_title"))
    refs.languageHint:SetText(ns.L("config_language_hint"))
    refs.koreanButton:SetText(ns.L("config_language_korean"))
    refs.englishButton:SetText(ns.L("config_language_english"))
    refs.minimapCheck.Text:SetText(ns.L("config_minimap_show"))
    refs.confirmCheck.Text:SetText(ns.L("config_confirm_show"))
    refs.debugCheck.Text:SetText(ns.L("config_debug_show"))
    refs.mouseMoveRestoreCheck.Text:SetText(ns.L("config_mouse_move_restore_show"))
    refs.statsOverlayCheck.Text:SetText(ns.L("config_stats_overlay_show"))
    refs.professionOverlayCheck.Text:SetText(ns.L("config_profession_overlay_show"))

    refs.overlayBox.title:SetText(ns.L("config_typography_title"))
    for _, entry in ipairs(refs.typographySliders or {}) do
        entry.slider:SetLabel(ns.L(entry.labelKey))
        entry.slider.slider:SetValue(ns.DB:GetTypographyOffset(entry.domain))
        entry.slider:SetValueText(ns.DB:GetTypographyOffset(entry.domain))
    end

    refs.combatTextBox.title:SetText(ns.L("config_combat_text"))
    refs.combatTextHint:SetText(ns.L("config_combat_text_hint"))
    refs.combatTextManageCheck.Text:SetText(ns.L("config_combat_text_managed"))
    refs.combatTextDirectionalCheck.Text:SetText(ns.L("config_combat_text_directional"))
    refs.combatTextModeLabel:SetText(ns.L("config_combat_text_mode"))

    local currentCombatTextMode = ns.DB:GetCombatTextFloatMode()
    for index, option in ipairs(COMBAT_TEXT_MODE_OPTIONS) do
        refs.combatTextModeButtons[index]:SetText(ns.L(option.labelKey))
        ns.UI.Widgets.SetButtonSelected(refs.combatTextModeButtons[index], option.value == currentCombatTextMode)
    end

    refs.overviewBox.title:SetText(ns.L("config_overview_panel_title"))
    refs.overviewText:SetText(buildOverviewText())
    if refs.openWindowButton then
        refs.openWindowButton:SetText(ns.L("config_open_window"))
    end

    refs.minimapCheck:SetChecked(not ns.DB:GetMinimapConfig().hide)
    refs.confirmCheck:SetChecked(ns.DB:ShouldConfirmActions())
    refs.debugCheck:SetChecked(ns.DB:IsDebugEnabled())
    refs.mouseMoveRestoreCheck:SetChecked(ns.DB:IsMouseMoveRestoreEnabled())
    refs.statsOverlayCheck:SetChecked(ns.DB:IsStatsOverlayEnabled())
    refs.professionOverlayCheck:SetChecked(ns.DB:IsProfessionKnowledgeOverlayEnabled())
    refs.combatTextManageCheck:SetChecked(ns.DB:IsCombatTextManaged())
    refs.combatTextDirectionalCheck:SetChecked(ns.DB:IsCombatTextDirectionalDamageEnabled())
    ns.UI.Widgets.SetButtonSelected(refs.koreanButton, ns.DB:GetLanguage() == ns.Constants.LANGUAGE.KOREAN)
    ns.UI.Widgets.SetButtonSelected(refs.englishButton, ns.DB:GetLanguage() == ns.Constants.LANGUAGE.ENGLISH)
end

function ConfigPanel:BuildControlSet(parent, options)
    options = options or {}

    local widgets = ns.UI.Widgets
    local refs = {}
    local columnWidth = options.columnWidth or 420
    local columnGap = options.columnGap or 12
    local contentWidth = columnWidth - 28

    refs.title = widgets.CreateLabel(parent, "", nil, 16, options.titleY or -20, "GameFontHighlightLarge")

    refs.generalBox = widgets.CreatePanelBox(parent, columnWidth, options.generalHeight or 360, "")
    refs.generalBox:SetPoint("TOPLEFT", refs.title, "BOTTOMLEFT", 0, -18)

    refs.languageHint = widgets.CreateLabel(refs.generalBox, "", nil, 12, -18)
    refs.languageHint:SetWidth(contentWidth)
    refs.languageHint:SetJustifyH("LEFT")
    if refs.languageHint.SetWordWrap then
        refs.languageHint:SetWordWrap(true)
    end

    refs.koreanButton = widgets.CreateButton(refs.generalBox, "", 110, 26)
    refs.koreanButton:SetPoint("TOPLEFT", refs.languageHint, "BOTTOMLEFT", 0, -12)

    refs.englishButton = widgets.CreateButton(refs.generalBox, "", 110, 26)
    refs.englishButton:SetPoint("LEFT", refs.koreanButton, "RIGHT", 8, 0)

    refs.minimapCheck = widgets.CreateCheckButton(refs.generalBox, "")
    refs.minimapCheck:SetPoint("TOPLEFT", refs.koreanButton, "BOTTOMLEFT", -4, -18)

    refs.confirmCheck = widgets.CreateCheckButton(refs.generalBox, "")
    refs.confirmCheck:SetPoint("TOPLEFT", refs.minimapCheck, "BOTTOMLEFT", 0, -8)

    refs.debugCheck = widgets.CreateCheckButton(refs.generalBox, "")
    refs.debugCheck:SetPoint("TOPLEFT", refs.confirmCheck, "BOTTOMLEFT", 0, -8)

    refs.mouseMoveRestoreCheck = widgets.CreateCheckButton(refs.generalBox, "")
    refs.mouseMoveRestoreCheck:SetPoint("TOPLEFT", refs.debugCheck, "BOTTOMLEFT", 0, -8)

    refs.statsOverlayCheck = widgets.CreateCheckButton(refs.generalBox, "")
    refs.statsOverlayCheck:SetPoint("TOPLEFT", refs.mouseMoveRestoreCheck, "BOTTOMLEFT", 0, -8)

    refs.professionOverlayCheck = widgets.CreateCheckButton(refs.generalBox, "")
    refs.professionOverlayCheck:SetPoint("TOPLEFT", refs.statsOverlayCheck, "BOTTOMLEFT", 0, -8)

    refs.overlayBox = widgets.CreatePanelBox(parent, columnWidth, options.overlayHeight or 360, "")
    refs.overlayBox:SetPoint("TOPLEFT", refs.generalBox, "TOPRIGHT", columnGap, 0)

    refs.typographySliders = {}
    local previousSlider = nil
    for index, entry in ipairs(TYPOGRAPHY_OPTIONS) do
        local minValue, maxValue = ns.DB:GetTypographyRange(entry.domain)
        local slider = widgets.CreateValueSlider(refs.overlayBox, contentWidth - 18, minValue, maxValue, 1)
        if index == 1 then
            slider:SetPoint("TOPLEFT", refs.overlayBox, "TOPLEFT", 12, -36)
        else
            slider:SetPoint("TOPLEFT", previousSlider, "BOTTOMLEFT", 0, -16)
        end
        slider:SetValueFormatter(formatOffsetValue)
        refs.typographySliders[#refs.typographySliders + 1] = {
            domain = entry.domain,
            labelKey = entry.labelKey,
            slider = slider,
        }
        previousSlider = slider
    end

    refs.overviewBox = widgets.CreatePanelBox(parent, columnWidth, options.overviewHeight or 194, "")
    refs.overviewBox:SetPoint("TOPLEFT", refs.generalBox, "BOTTOMLEFT", 0, -18)

    refs.overviewText = widgets.CreateScrollTextBox(refs.overviewBox, columnWidth - 28, options.overviewTextHeight or 128)
    refs.overviewText:SetPoint("TOPLEFT", 12, -30)

    if options.showOpenButton then
        refs.openWindowButton = widgets.CreateButton(refs.overviewBox, "", 150, 28)
        refs.openWindowButton:SetPoint("BOTTOMLEFT", refs.overviewBox, "BOTTOMLEFT", 14, 14)
    end

    refs.combatTextBox = widgets.CreatePanelBox(parent, columnWidth, options.combatTextHeight or (options.overviewHeight or 194), "")
    refs.combatTextBox:SetPoint("TOPLEFT", refs.overlayBox, "BOTTOMLEFT", 0, -18)

    refs.combatTextHint = widgets.CreateLabel(refs.combatTextBox, "", nil, 12, -18)
    refs.combatTextHint:SetWidth(contentWidth)
    refs.combatTextHint:SetJustifyH("LEFT")
    if refs.combatTextHint.SetWordWrap then
        refs.combatTextHint:SetWordWrap(true)
    end

    refs.combatTextManageCheck = widgets.CreateCheckButton(refs.combatTextBox, "")
    refs.combatTextManageCheck:SetPoint("TOPLEFT", refs.combatTextHint, "BOTTOMLEFT", -4, -10)
    refs.combatTextDirectionalCheck = widgets.CreateCheckButton(refs.combatTextBox, "")
    refs.combatTextDirectionalCheck:SetPoint("TOPLEFT", refs.combatTextManageCheck, "BOTTOMLEFT", 0, -8)
    refs.combatTextModeLabel = widgets.CreateLabel(refs.combatTextBox, "", refs.combatTextDirectionalCheck, 4, -12, "GameFontHighlight")

    refs.combatTextModeButtons = {}
    local previousModeButton = nil
    local modeButtonWidth = math.max(72, math.floor((contentWidth - 12) / 3))
    for index, option in ipairs(COMBAT_TEXT_MODE_OPTIONS) do
        local button = widgets.CreateButton(refs.combatTextBox, "", modeButtonWidth, 24)
        if previousModeButton then
            button:SetPoint("LEFT", previousModeButton, "RIGHT", 6, 0)
        else
            button:SetPoint("TOPLEFT", refs.combatTextModeLabel, "BOTTOMLEFT", 0, -8)
        end
        refs.combatTextModeButtons[index] = button
        previousModeButton = button
    end

    refs.statusText = widgets.CreateLabel(parent, "", refs.overviewBox, 0, -18)
    refs.statusText:SetWidth(options.statusWidth or ((columnWidth * 2) + columnGap))
    refs.statusText:SetJustifyH("LEFT")

    local checkboxWidth = contentWidth
    for _, check in ipairs({
        refs.minimapCheck,
        refs.confirmCheck,
        refs.debugCheck,
        refs.mouseMoveRestoreCheck,
        refs.statsOverlayCheck,
        refs.professionOverlayCheck,
        refs.combatTextManageCheck,
        refs.combatTextDirectionalCheck,
    }) do
        if check and check.Text then
            check.Text:SetWidth(checkboxWidth)
            check.Text:SetJustifyH("LEFT")
            if check.Text.SetWordWrap then
                check.Text:SetWordWrap(true)
            end
        end
    end

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
        panel:SetSize(660, 700)

        self.settingsFrame = panel
        self.settingsRefs = self:BuildControlSet(panel, {
            titleY = -16,
            showOpenButton = true,
            columnWidth = 300,
            columnGap = 12,
            helpWidth = 612,
            statusWidth = 612,
            generalHeight = 372,
            overlayHeight = 372,
            overviewHeight = 174,
            overviewTextHeight = 100,
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
        generalHeight = 372,
        overlayHeight = 372,
        overviewHeight = 194,
        overviewTextHeight = 128,
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
