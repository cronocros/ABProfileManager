local _, ns = ...

local MapPanel = {}
ns.UI.MapPanel = MapPanel

local MAP_FILTER_OPTIONS = {
    { key = "facilities", labelKey = "config_silvermoon_filter_facilities" },
    { key = "portals", labelKey = "config_silvermoon_filter_portals" },
    { key = "professions", labelKey = "config_silvermoon_filter_professions" },
    { key = "renown", labelKey = "config_silvermoon_filter_renown" },
    { key = "dungeons", labelKey = "config_silvermoon_filter_dungeons" },
    { key = "delves", labelKey = "config_silvermoon_filter_delves" },
    { key = "beasts", labelKey = "config_silvermoon_filter_beasts" },
}

local function setStatus(panel, message)
    local formatted = ns.Utils.FormatStatusMessage(message)
    if panel and panel.statusText then
        panel.statusText:SetText("")
        panel.statusText:SetText(formatted or "")
    end

    ns:SafeCall(ns.UI.MainWindow, "SetStatus", message)
end

local function formatOffsetValue(value)
    value = math.floor((tonumber(value) or 0) + 0.5)
    if value > 0 then
        return string.format("+%dpt", value)
    end
    return string.format("%dpt", value)
end

function MapPanel:ApplyEnabled(enabled)
    ns.DB:SetSilvermoonMapOverlayEnabled(enabled)
    ns:RefreshUI()
    setStatus(self, ns.L("config_saved_silvermoon_map", enabled and ns.L("state_enabled") or ns.L("state_disabled")))
end

function MapPanel:ApplyFilter(filterKey, enabled, labelKey)
    ns.DB:SetSilvermoonMapCategoryEnabled(filterKey, enabled)
    ns:RefreshUI()
    setStatus(self, ns.L("config_saved_silvermoon_filter", ns.L(labelKey), enabled and ns.L("state_enabled") or ns.L("state_disabled")))
end

function MapPanel:ApplyFontOffset(value)
    value = ns.DB:SetTypographyOffset("mapOverlay", value)
    ns:RefreshUI()
    setStatus(self, ns.L("config_saved_map_overlay_font_size", formatOffsetValue(value)))
end

function MapPanel:RefreshLocale()
    if not self.frame then
        return
    end

    self.title:SetText(ns.L("map_title"))
    self.hint:SetText(ns.L("map_hint"))
    self.overlayBox.title:SetText(ns.L("config_silvermoon_map"))
    self.overlayCheck.Text:SetText(ns.L("config_silvermoon_map_show"))
    self.fontSlider:SetLabel(ns.L("map_font_size_label"))
    self.filterBox.title:SetText(ns.L("map_filters_title"))
    self.summaryBox.title:SetText(ns.L("map_supported_maps_title"))
    self.summaryText:SetText(ns.L("map_supported_maps_body"))

    for index, option in ipairs(MAP_FILTER_OPTIONS) do
        self.filterChecks[index].Text:SetText(ns.L(option.labelKey))
    end
end

function MapPanel:Create(parent)
    if self.frame then
        return self.frame
    end

    local widgets = ns.UI.Widgets
    local frame = CreateFrame("Frame", nil, parent)
    frame:SetAllPoints()

    local title = widgets.CreateLabel(frame, "", nil, 16, -14, "GameFontHighlightLarge")
    local hint = widgets.CreateLabel(frame, "", title, 0, -10)
    hint:SetWidth(852)
    hint:SetJustifyH("LEFT")
    if hint.SetWordWrap then
        hint:SetWordWrap(true)
    end

    local overlayBox = widgets.CreatePanelBox(frame, 420, 224, "")
    overlayBox:SetPoint("TOPLEFT", frame, "TOPLEFT", 16, -88)

    local overlayCheck = widgets.CreateCheckButton(overlayBox, "")
    overlayCheck:SetPoint("TOPLEFT", overlayBox, "TOPLEFT", 12, -34)
    overlayCheck.Text:SetWidth(376)
    overlayCheck.Text:SetJustifyH("LEFT")
    if overlayCheck.Text.SetWordWrap then
        overlayCheck.Text:SetWordWrap(true)
    end

    local minValue, maxValue = ns.DB:GetTypographyRange("mapOverlay")
    local fontSlider = widgets.CreateValueSlider(overlayBox, 360, minValue, maxValue, 1)
    fontSlider:SetPoint("TOPLEFT", overlayCheck, "BOTTOMLEFT", 4, -18)
    fontSlider:SetValueFormatter(formatOffsetValue)
    fontSlider.slider:SetScript("OnValueChanged", function(_, value)
        fontSlider:SetValueText(value)
    end)

    local filterBox = widgets.CreatePanelBox(frame, 420, 224, "")
    filterBox:SetPoint("TOPLEFT", overlayBox, "TOPRIGHT", 12, 0)

    local filterChecks = {}
    local lastLeft = nil
    local lastRight = nil
    local columnOffset = 202
    for index, option in ipairs(MAP_FILTER_OPTIONS) do
        local check = widgets.CreateCheckButton(filterBox, "")
        local column = (index - 1) % 2
        if index <= 2 then
            check:SetPoint("TOPLEFT", filterBox, "TOPLEFT", 12 + (column * columnOffset), -34)
        else
            local anchor = column == 0 and lastLeft or lastRight
            check:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -8)
        end
        check.Text:SetWidth(168)
        check.Text:SetJustifyH("LEFT")
        if check.Text.SetWordWrap then
            check.Text:SetWordWrap(true)
        end
        filterChecks[index] = check
        if column == 0 then
            lastLeft = check
        else
            lastRight = check
        end
    end

    local summaryBox = widgets.CreatePanelBox(frame, 852, 208, "")
    summaryBox:SetPoint("TOPLEFT", overlayBox, "BOTTOMLEFT", 0, -14)
    local summaryText = widgets.CreateScrollTextBox(summaryBox, 822, 160)
    summaryText:SetPoint("TOPLEFT", 14, -30)

    local statusText = widgets.CreateLabel(frame, "", summaryBox, 0, -18)
    statusText:SetWidth(852)
    statusText:SetJustifyH("LEFT")

    overlayCheck:SetScript("OnClick", function(currentCheck)
        self:ApplyEnabled(currentCheck:GetChecked())
    end)

    fontSlider.slider:SetScript("OnValueChanged", function(currentSlider, value)
        fontSlider:SetValueText(value)
        local rounded = math.floor((tonumber(value) or 0) + 0.5)
        if ns.DB:GetTypographyOffset("mapOverlay") ~= rounded then
            self:ApplyFontOffset(rounded)
        end
    end)

    for index, option in ipairs(MAP_FILTER_OPTIONS) do
        filterChecks[index]:SetScript("OnClick", function(currentCheck)
            self:ApplyFilter(option.key, currentCheck:GetChecked(), option.labelKey)
        end)
    end

    self.frame = frame
    self.title = title
    self.hint = hint
    self.overlayBox = overlayBox
    self.overlayCheck = overlayCheck
    self.fontSlider = fontSlider
    self.filterBox = filterBox
    self.filterChecks = filterChecks
    self.summaryBox = summaryBox
    self.summaryText = summaryText
    self.statusText = statusText

    self:Refresh()
    return frame
end

function MapPanel:Refresh()
    if not self.frame then
        return
    end

    self:RefreshLocale()
    self.overlayCheck:SetChecked(ns.DB:IsSilvermoonMapOverlayEnabled())
    self.fontSlider.slider:SetValue(ns.DB:GetTypographyOffset("mapOverlay"))
    self.fontSlider:SetValueText(ns.DB:GetTypographyOffset("mapOverlay"))

    for index, option in ipairs(MAP_FILTER_OPTIONS) do
        self.filterChecks[index]:SetChecked(ns.DB:IsSilvermoonMapCategoryEnabled(option.key))
    end
end
