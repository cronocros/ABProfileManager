local _, ns = ...

local Widgets = {}
ns.UI.Widgets = Widgets

local function applyLocalizedFont(target, size)
    local fontPath = STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF"
    if target and target.SetFont then
        target:SetFont(fontPath, size or 12, "")
    end
end

local function getFontSize(fontObject)
    if fontObject == "GameFontHighlightLarge" then
        return 15
    end
    if fontObject == "GameFontHighlight" then
        return 13
    end
    if fontObject == "GameFontNormalSmall" or fontObject == "GameFontDisableSmall" then
        return 11
    end
    return 12
end

local function createScrollHost(parent, width, height)
    local host = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    host:SetSize(width, height)
    host:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = false,
        edgeSize = 12,
        insets = { left = 2, right = 2, top = 2, bottom = 2 },
    })
    host:SetBackdropColor(0.05, 0.08, 0.12, 0.92)
    host:SetBackdropBorderColor(0.43, 0.49, 0.58, 0.88)
    host:EnableMouseWheel(true)

    local scrollFrame = CreateFrame("ScrollFrame", nil, host)
    scrollFrame:SetPoint("TOPLEFT", 8, -8)
    scrollFrame:SetPoint("BOTTOMRIGHT", -22, 8)
    scrollFrame:EnableMouseWheel(true)

    local track = CreateFrame("Frame", nil, host, "BackdropTemplate")
    track:SetPoint("TOPRIGHT", -7, -8)
    track:SetPoint("BOTTOMRIGHT", -7, 8)
    track:SetWidth(10)
    track:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        tile = false,
        edgeSize = 1,
        insets = { left = 0, right = 0, top = 0, bottom = 0 },
    })
    track:SetBackdropColor(0.09, 0.13, 0.18, 0.98)
    track:SetBackdropBorderColor(0.24, 0.31, 0.39, 0.98)

    local slider = CreateFrame("Slider", nil, host)
    slider:SetPoint("TOPLEFT", track, "TOPLEFT", 1, -1)
    slider:SetPoint("BOTTOMRIGHT", track, "BOTTOMRIGHT", -1, 1)
    slider:SetOrientation("VERTICAL")
    slider:SetMinMaxValues(0, 0)
    slider:SetValue(0)
    slider:SetValueStep(1)
    slider:SetThumbTexture("Interface\\Buttons\\WHITE8X8")
    local thumb = slider:GetThumbTexture()
    thumb:SetVertexColor(0.88, 0.76, 0.38, 0.98)
    thumb:SetSize(8, 24)
    slider.thumb = thumb

    local function clampScroll(value)
        local minValue, maxValue = slider:GetMinMaxValues()
        return math.max(minValue or 0, math.min(maxValue or 0, value or 0))
    end

    local function scrollTo(value)
        local clamped = clampScroll(value)
        if host._syncing then
            return
        end

        host._syncing = true
        slider:SetValue(clamped)
        scrollFrame:SetVerticalScroll(clamped)
        host._syncing = nil
    end

    function host:UpdateScrollBar()
        local child = scrollFrame:GetScrollChild()
        local range = scrollFrame:GetVerticalScrollRange() or 0
        local current = clampScroll(scrollFrame:GetVerticalScroll() or 0)
        local trackHeight = math.max(20, track:GetHeight() - 2)
        local childHeight = child and child:GetHeight() or scrollFrame:GetHeight()
        local visibleHeight = math.max(1, scrollFrame:GetHeight())
        local thumbHeight = trackHeight

        if range > 0 and childHeight > 0 then
            thumbHeight = math.max(26, math.floor(trackHeight * (visibleHeight / childHeight)))
            thumbHeight = math.min(trackHeight, thumbHeight)
        end

        thumb:SetHeight(thumbHeight)
        slider:SetMinMaxValues(0, range)
        slider:SetValue(current)
        track:SetShown(range > 0)
        slider:SetShown(range > 0)
    end

    slider:SetScript("OnValueChanged", function(_, value)
        if host._syncing then
            return
        end

        host._syncing = true
        scrollFrame:SetVerticalScroll(clampScroll(value))
        host._syncing = nil
    end)

    scrollFrame:SetScript("OnVerticalScroll", function(_, offset)
        if host._syncing then
            return
        end

        host._syncing = true
        slider:SetValue(clampScroll(offset))
        scrollFrame:SetVerticalScroll(clampScroll(offset))
        host._syncing = nil
    end)

    local function handleWheel(_, delta)
        local step = math.max(18, math.floor((scrollFrame:GetHeight() or height) / 5))
        scrollTo((slider:GetValue() or 0) - (delta * step))
    end

    host:SetScript("OnMouseWheel", handleWheel)
    scrollFrame:SetScript("OnMouseWheel", handleWheel)
    scrollFrame:SetScript("OnSizeChanged", function()
        host:UpdateScrollBar()
    end)

    host.scrollFrame = scrollFrame
    host.scrollTrack = track
    host.scrollBar = slider
    host.innerWidth = width - 30
    return host
end

function Widgets.CreateLabel(parent, text, anchorTo, offsetX, offsetY, fontObject)
    local label = parent:CreateFontString(nil, "OVERLAY", fontObject or "GameFontNormal")
    applyLocalizedFont(label, getFontSize(fontObject))
    label:SetText(text or "")

    if anchorTo then
        label:SetPoint("TOPLEFT", anchorTo, "BOTTOMLEFT", offsetX or 0, offsetY or -8)
    else
        label:SetPoint("TOPLEFT", parent, "TOPLEFT", offsetX or 0, offsetY or 0)
    end

    return label
end

function Widgets.CreateButton(parent, text, width, height)
    local button = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    button:SetSize(width or 120, height or 24)
    button:SetText(text or "Button")
    if button:GetFontString() then
        applyLocalizedFont(button:GetFontString(), 12)
        button:GetFontString():SetWidth((width or 120) - 12)
        button:GetFontString():SetJustifyH("CENTER")
        button:GetFontString():SetJustifyV("MIDDLE")
        if button:GetFontString().SetWordWrap then
            button:GetFontString():SetWordWrap(true)
        end
    end
    return button
end

function Widgets.CreateListButton(parent, width, height)
    local button = Widgets.CreateButton(parent, "", width or 240, height or 22)
    if button:GetFontString() then
        button:GetFontString():SetJustifyH("LEFT")
        if button:GetFontString().SetWordWrap then
            button:GetFontString():SetWordWrap(false)
        end
    end
    return button
end

function Widgets.CreateEditBox(parent, width, height, numeric)
    local box = CreateFrame("EditBox", nil, parent, "InputBoxTemplate")
    box:SetAutoFocus(false)
    box:SetSize(width or 180, height or 24)
    box:SetTextInsets(6, 6, 2, 2)
    box:SetFont(STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF", 12, "")
    box:SetScript("OnEscapePressed", box.ClearFocus)
    box:SetScript("OnEnterPressed", box.ClearFocus)
    if numeric then
        box:SetNumeric(true)
    end
    return box
end

function Widgets.CreateCheckButton(parent, labelText)
    local check = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
    if check.Text then
        applyLocalizedFont(check.Text, 12)
        check.Text:SetText(labelText or "")
        check.Text:SetJustifyH("LEFT")
    else
        local label = check:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        applyLocalizedFont(label, 12)
        label:SetPoint("LEFT", check, "RIGHT", 2, 0)
        label:SetJustifyH("LEFT")
        label:SetText(labelText or "")
        check.Text = label
    end
    return check
end

function Widgets.CreatePanelBox(parent, width, height, title)
    local panel = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    panel:SetSize(width, height)
    panel:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = false,
        edgeSize = 12,
        insets = { left = 3, right = 3, top = 3, bottom = 3 },
    })
    panel:SetBackdropColor(0.06, 0.09, 0.13, 0.94)
    panel:SetBackdropBorderColor(0.62, 0.55, 0.32, 0.9)

    if title then
        panel.title = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        applyLocalizedFont(panel.title, 13)
        panel.title:SetPoint("TOPLEFT", 12, -10)
        panel.title:SetTextColor(1, 0.86, 0.45, 1)
        panel.title:SetText(title)
    end

    return panel
end

function Widgets.CreateScrollTextBox(parent, width, height)
    local host = createScrollHost(parent, width, height)
    local scrollFrame = host.scrollFrame
    local content = CreateFrame("Frame", nil, scrollFrame)
    content:SetPoint("TOPLEFT", 0, 0)
    content:SetSize(host.innerWidth, height)
    scrollFrame:SetScrollChild(content)

    local text = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    applyLocalizedFont(text, 12)
    text:SetPoint("TOPLEFT", 0, 0)
    text:SetWidth(host.innerWidth - 6)
    text:SetJustifyH("LEFT")
    text:SetJustifyV("TOP")
    text:SetTextColor(0.95, 0.95, 0.92, 1)
    if text.SetSpacing then
        text:SetSpacing(4)
    end

    function host:SetText(value)
        text:SetText("")
        text:SetText(value or "")
        content:SetHeight(math.max(height, math.ceil(text:GetStringHeight()) + 10))
        scrollFrame:UpdateScrollChildRect()
        scrollFrame:SetVerticalScroll(0)
        host:UpdateScrollBar()
    end

    host.content = content
    host.text = text
    host:SetText("")
    return host
end

function Widgets.CreateScrollEditBox(parent, width, height, readOnly)
    local host = createScrollHost(parent, width, height)
    local scrollFrame = host.scrollFrame
    local box = CreateFrame("EditBox", nil, scrollFrame)
    local measure = host:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    local textWidth = host.innerWidth - 8

    box:SetMultiLine(true)
    box:SetAutoFocus(false)
    box:SetFont(STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF", 12, "")
    box:SetTextInsets(4, 4, 6, 6)
    box:SetWidth(textWidth)
    box:SetPoint("TOPLEFT", 0, 0)
    box:SetJustifyH("LEFT")
    box:SetTextColor(0.98, 0.96, 0.9, 1)
    if box.SetJustifyV then
        box:SetJustifyV("TOP")
    end
    if box.SetCursorColor then
        box:SetCursorColor(1, 0.82, 0.25)
    end

    measure:SetFont(STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF", 12, "")
    measure:SetWidth(textWidth)
    measure:SetJustifyH("LEFT")
    measure:SetJustifyV("TOP")
    measure:Hide()

    box:SetScript("OnEscapePressed", box.ClearFocus)
    box:SetScript("OnEnterPressed", function() end)
    box:SetScript("OnCursorChanged", function(_, _, y, _, cursorHeight)
        local scrollTop = scrollFrame:GetVerticalScroll() or 0
        local visibleHeight = scrollFrame:GetHeight() or height
        if y < scrollTop then
            scrollFrame:SetVerticalScroll(y)
        elseif (y + cursorHeight) > (scrollTop + visibleHeight) then
            scrollFrame:SetVerticalScroll(y + cursorHeight - visibleHeight)
        end
        host:UpdateScrollBar()
    end)

    box:SetScript("OnTextChanged", function(currentBox, userInput)
        if host.readOnly and userInput then
            currentBox:SetText(host.cachedText or "")
            currentBox:HighlightText()
            return
        end

        host.cachedText = currentBox:GetText() or ""
        measure:SetText(host.cachedText ~= "" and host.cachedText or " ")
        currentBox:SetHeight(math.max(height, math.ceil(measure:GetStringHeight()) + 18))
        scrollFrame:UpdateScrollChildRect()
        host:UpdateScrollBar()
    end)

    box:SetScript("OnEditFocusGained", function(currentBox)
        if host.readOnly then
            currentBox:HighlightText()
        end
    end)

    box:SetScript("OnMouseDown", function(currentBox)
        if host.readOnly then
            currentBox:SetFocus()
            currentBox:HighlightText()
        end
    end)

    box:SetMaxLetters(0)
    box:SetHeight(height)
    scrollFrame:SetScrollChild(box)

    host.editBox = box
    host.measure = measure
    host.readOnly = readOnly and true or false
    host.cachedText = ""

    function host:SetText(value)
        host.cachedText = value or ""
        measure:SetText(host.cachedText ~= "" and host.cachedText or " ")
        box:SetText("")
        box:SetText(host.cachedText)
        box:HighlightText(0, 0)
        box:SetHeight(math.max(height, math.ceil(measure:GetStringHeight()) + 18))
        scrollFrame:UpdateScrollChildRect()
        scrollFrame:SetVerticalScroll(0)
        if box.SetCursorPosition then
            box:SetCursorPosition(0)
        end
        host:UpdateScrollBar()
    end

    function host:GetText()
        return box:GetText() or ""
    end

    function host:SetEditable(editable)
        host.readOnly = not (editable and true or false)
        if host.readOnly then
            box:ClearFocus()
        end
    end

    function host:FocusAndHighlight()
        box:SetFocus()
        box:HighlightText()
    end

    function host:Focus()
        box:SetFocus()
    end

    host:SetEditable(not readOnly)
    host:SetText("")
    return host
end

function Widgets.CreateOptionCard(parent, width, height, iconText, titleText)
    local button = CreateFrame("Button", nil, parent, "BackdropTemplate")
    button:SetSize(width or 76, height or 64)
    button:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = false,
        edgeSize = 12,
        insets = { left = 2, right = 2, top = 2, bottom = 2 },
    })

    button.icon = button:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
    applyLocalizedFont(button.icon, 18)
    button.icon:SetPoint("TOP", 0, -10)
    button.icon:SetText(iconText or "")

    button.label = button:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    applyLocalizedFont(button.label, 11)
    button.label:SetPoint("BOTTOM", 0, 8)
    button.label:SetWidth((width or 76) - 10)
    button.label:SetJustifyH("CENTER")
    button.label:SetText(titleText or "")

    function button:SetCardText(newIconText, newTitleText)
        button.icon:SetText(newIconText or "")
        button.label:SetText(newTitleText or "")
    end

    function button:SetSelected(selected)
        if selected then
            button:SetBackdropColor(0.24, 0.17, 0.05, 0.96)
            button:SetBackdropBorderColor(0.95, 0.79, 0.32, 1)
            button.label:SetTextColor(1, 0.86, 0.38, 1)
            button.icon:SetTextColor(1, 0.9, 0.45, 1)
        else
            button:SetBackdropColor(0.07, 0.1, 0.15, 0.94)
            button:SetBackdropBorderColor(0.4, 0.47, 0.58, 0.88)
            button.label:SetTextColor(0.94, 0.94, 0.92, 1)
            button.icon:SetTextColor(0.78, 0.88, 1, 1)
        end
    end

    button:SetSelected(false)
    return button
end

function Widgets.SetButtonSelected(button, selected)
    if button and type(button.SetSelected) == "function" then
        button:SetSelected(selected)
        return
    end

    local fontString = button:GetFontString()
    if not fontString then
        return
    end

    if selected then
        fontString:SetTextColor(1, 0.84, 0.28, 1)
    else
        fontString:SetTextColor(1, 1, 1, 1)
    end
end
