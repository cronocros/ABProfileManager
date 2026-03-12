local _, ns = ...

local ConfigPanel = {}
ns.UI.ConfigPanel = ConfigPanel
local STATS_OVERLAY_SCALE_OPTIONS = {
    { value = 0.80, labelKey = "overlay_size_xsmall", buttonText = "XS" },
    { value = 0.90, labelKey = "overlay_size_small", buttonText = "S" },
    { value = 1.00, labelKey = "overlay_size_default", buttonText = "M" },
    { value = 1.15, labelKey = "overlay_size_large", buttonText = "L" },
    { value = 1.30, labelKey = "overlay_size_xlarge", buttonText = "XL" },
}
local MAP_FILTER_OPTIONS = {
    { key = "facilities", labelKey = "config_silvermoon_filter_facilities" },
    { key = "portals", labelKey = "config_silvermoon_filter_portals" },
    { key = "professions", labelKey = "config_silvermoon_filter_professions" },
    { key = "dungeons", labelKey = "config_silvermoon_filter_dungeons" },
    { key = "delves", labelKey = "config_silvermoon_filter_delves" },
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
        ns.L("config_overview_profession_scan", lastScan),
        ns.L("config_overview_debug", getStateLabel(ns.DB:IsDebugEnabled())),
        ns.L("config_overview_storage"),
        "",
        ns.L("config_overview_guide_header"),
        ns.L("config_overview_hint_window"),
        ns.L("config_overview_hint_drag"),
        ns.L("config_overview_hint_map"),
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

function ConfigPanel:ApplyStatsOverlayScale(scale, refs, labelKey)
    ns.DB:SetStatsOverlayScale(scale)
    ns:RefreshUI()
    setStatus(refs, ns.L("config_saved_stats_overlay_scale", ns.L(labelKey)))
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

function ConfigPanel:ApplySilvermoonMapFilter(filterKey, enabled, refs, labelKey)
    ns.DB:SetSilvermoonMapCategoryEnabled(filterKey, enabled)
    ns:RefreshUI()
    setStatus(refs, ns.L("config_saved_silvermoon_filter", ns.L(labelKey), enabled and ns.L("state_enabled") or ns.L("state_disabled")))
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

    for index, option in ipairs(STATS_OVERLAY_SCALE_OPTIONS) do
        local optionValue = option.value
        local optionLabelKey = option.labelKey
        refs.statsScaleButtons[index]:SetScript("OnClick", function()
            self:ApplyStatsOverlayScale(optionValue, refs, optionLabelKey)
        end)
    end

    refs.professionOverlayCheck:SetScript("OnClick", function(currentCheck)
        self:ApplyProfessionOverlayEnabled(currentCheck:GetChecked(), refs)
    end)

    refs.silvermoonMapCheck:SetScript("OnClick", function(currentCheck)
        self:ApplySilvermoonMapEnabled(currentCheck:GetChecked(), refs)
    end)

    for index, option in ipairs(MAP_FILTER_OPTIONS) do
        local filterKey = option.key
        local filterLabelKey = option.labelKey
        refs.mapFilterChecks[index]:SetScript("OnClick", function(currentCheck)
            self:ApplySilvermoonMapFilter(filterKey, currentCheck:GetChecked(), refs, filterLabelKey)
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
    refs.professionOverlayLabel:SetText(ns.L("config_profession_overlay"))
    refs.professionOverlayCheck.Text:SetText(ns.L("config_profession_overlay_show"))
    refs.statsOverlayLabel:SetText(ns.L("config_stats_overlay"))
    refs.statsOverlayCheck.Text:SetText(ns.L("config_stats_overlay_show"))
    refs.statsScaleLabel:SetText(ns.L("overlay_size_label"))
    local currentScale = ns.DB:GetStatsOverlayScale()
    local selectedScaleIndex = 1
    local selectedScaleDiff = nil
    for index, option in ipairs(STATS_OVERLAY_SCALE_OPTIONS) do
        local diff = math.abs(currentScale - option.value)
        if not selectedScaleDiff or diff < selectedScaleDiff then
            selectedScaleDiff = diff
            selectedScaleIndex = index
        end
    end
    for index, option in ipairs(STATS_OVERLAY_SCALE_OPTIONS) do
        refs.statsScaleButtons[index]:SetText(option.buttonText or ns.L(option.labelKey))
        ns.UI.Widgets.SetButtonSelected(refs.statsScaleButtons[index], index == selectedScaleIndex)
    end
    refs.silvermoonMapLabel:SetText(ns.L("config_silvermoon_map"))
    refs.silvermoonMapCheck.Text:SetText(ns.L("config_silvermoon_map_show"))
    refs.mapFiltersLabel:SetText(ns.L("config_silvermoon_filters"))
    for index, option in ipairs(MAP_FILTER_OPTIONS) do
        refs.mapFilterChecks[index].Text:SetText(ns.L(option.labelKey))
        refs.mapFilterChecks[index]:SetChecked(ns.DB:IsSilvermoonMapCategoryEnabled(option.key))
    end
    refs.overviewText:SetText(buildOverviewText())

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

    local settingsBoxHeight = 382

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
    refs.professionOverlayLabel = widgets.CreateLabel(languageBox, "", refs.debugCheck, 4, -16, "GameFontHighlight")
    refs.professionOverlayCheck = widgets.CreateCheckButton(languageBox, "")
    refs.professionOverlayCheck:SetPoint("TOPLEFT", refs.professionOverlayLabel, "BOTTOMLEFT", -4, -10)

    local overlayBox = widgets.CreatePanelBox(parent, columnWidth, settingsBoxHeight, nil)
    overlayBox:SetPoint("LEFT", languageBox, "RIGHT", columnGap, 0)
    refs.statsOverlayLabel = widgets.CreateLabel(overlayBox, "", nil, 12, -14, "GameFontHighlight")
    refs.statsOverlayCheck = widgets.CreateCheckButton(overlayBox, "")
    refs.statsOverlayCheck:SetPoint("TOPLEFT", refs.statsOverlayLabel, "BOTTOMLEFT", -4, -10)
    refs.statsScaleLabel = widgets.CreateLabel(overlayBox, "", refs.statsOverlayCheck, 4, -10, "GameFontHighlight")
    refs.statsScaleButtons = {}
    local previousScaleButton = nil
    for index, option in ipairs(STATS_OVERLAY_SCALE_OPTIONS) do
        local button = widgets.CreateButton(overlayBox, "", 44, 20)
        if previousScaleButton then
            button:SetPoint("LEFT", previousScaleButton, "RIGHT", 4, 0)
        else
            button:SetPoint("TOPLEFT", refs.statsScaleLabel, "BOTTOMLEFT", 0, -8)
        end
        refs.statsScaleButtons[index] = button
        previousScaleButton = button
    end
    refs.silvermoonMapLabel = widgets.CreateLabel(overlayBox, "", refs.statsScaleButtons[1], 0, -18, "GameFontHighlight")
    refs.silvermoonMapCheck = widgets.CreateCheckButton(overlayBox, "")
    refs.silvermoonMapCheck:SetPoint("TOPLEFT", refs.silvermoonMapLabel, "BOTTOMLEFT", -4, -8)
    refs.mapFiltersLabel = widgets.CreateLabel(overlayBox, "", refs.silvermoonMapCheck, 4, -12, "GameFontHighlight")
    refs.mapFilterChecks = {}
    local mapFilterTextWidth = math.floor((columnWidth - 68) / 2)
    local mapFilterColumnOffset = math.floor(columnWidth / 2) - 6
    local lastLeftCheck = nil
    local lastRightCheck = nil
    for index, option in ipairs(MAP_FILTER_OPTIONS) do
        local check = widgets.CreateCheckButton(overlayBox, "")
        local column = ((index - 1) % 2)
        if index <= 2 then
            check:SetPoint("TOPLEFT", refs.mapFiltersLabel, "BOTTOMLEFT", (column * mapFilterColumnOffset) - 4, -6)
        else
            local anchor = column == 0 and lastLeftCheck or lastRightCheck
            check:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -4)
        end
        check.Text:SetWidth(mapFilterTextWidth)
        check.Text:SetJustifyH("LEFT")
        if check.Text.SetWordWrap then
            check.Text:SetWordWrap(true)
        end
        refs.mapFilterChecks[index] = check
        if column == 0 then
            lastLeftCheck = check
        else
            lastRightCheck = check
        end
    end

    refs.minimapCheck.Text:SetWidth(textWidth)
    refs.minimapCheck.Text:SetJustifyH("LEFT")
    refs.confirmCheck.Text:SetWidth(textWidth)
    refs.confirmCheck.Text:SetJustifyH("LEFT")
    refs.debugCheck.Text:SetWidth(textWidth)
    refs.debugCheck.Text:SetJustifyH("LEFT")
    refs.professionOverlayCheck.Text:SetWidth(textWidth)
    refs.professionOverlayCheck.Text:SetJustifyH("LEFT")
    refs.statsOverlayCheck.Text:SetWidth(textWidth)
    refs.statsOverlayCheck.Text:SetJustifyH("LEFT")
    refs.silvermoonMapCheck.Text:SetWidth(textWidth)
    refs.silvermoonMapCheck.Text:SetJustifyH("LEFT")

    local helpBoxHeight = options.showOpenButton and 208 or 180
    local helpBox = widgets.CreatePanelBox(parent, helpWidth, helpBoxHeight, nil)
    helpBox:SetPoint("TOPLEFT", languageBox, "BOTTOMLEFT", 0, -20)
    refs.overviewText = widgets.CreateScrollTextBox(helpBox, helpWidth - 28, options.showOpenButton and 136 or 144)
    refs.overviewText:SetPoint("TOPLEFT", 12, -14)

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
