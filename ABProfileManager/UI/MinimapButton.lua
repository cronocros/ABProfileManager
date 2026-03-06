local _, ns = ...

local MinimapButton = {}
ns.UI.MinimapButton = MinimapButton

local function updatePosition(button)
    if not button or not Minimap then
        return
    end

    local config = ns.DB:GetMinimapConfig()
    local angle = math.rad(config.angle or 220)
    local radius = math.floor(((Minimap:GetWidth() or 140) * 0.5) + 4)
    local x = math.cos(angle) * radius
    local y = math.sin(angle) * radius

    button:ClearAllPoints()
    button:SetPoint("CENTER", Minimap, "CENTER", x, y)
end

local function setTooltip(button)
    GameTooltip:SetOwner(button, "ANCHOR_LEFT")
    GameTooltip:SetText(ns.L("minimap_tooltip_title"))
    GameTooltip:AddLine(ns.L("minimap_tooltip_line1"), 1, 0.82, 0, true)
    GameTooltip:AddLine(ns.L("minimap_tooltip_line2"), 1, 0.82, 0, true)
    GameTooltip:AddLine(ns.L("minimap_tooltip_line3", ns.Constants.AUTHOR), 0.7, 0.9, 1, true)
    GameTooltip:Show()
end

function MinimapButton:Initialize()
    if self.button or not Minimap then
        return
    end

    local button = CreateFrame("Button", "ABPM_MinimapButton", Minimap)
    button:SetSize(28, 28)
    button:SetFrameStrata("MEDIUM")
    button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    button:RegisterForDrag("RightButton")

    button.fill = button:CreateTexture(nil, "BACKGROUND")
    button.fill:SetAllPoints()
    button.fill:SetTexture("Interface\\Buttons\\WHITE8X8")
    button.fill:SetVertexColor(0.09, 0.13, 0.18, 0.96)

    button.ring = button:CreateTexture(nil, "ARTWORK")
    button.ring:SetPoint("TOPLEFT", 2, -2)
    button.ring:SetPoint("BOTTOMRIGHT", -2, 2)
    button.ring:SetTexture("Interface\\Buttons\\WHITE8X8")
    button.ring:SetVertexColor(0.72, 0.58, 0.24, 0.95)

    button.inner = button:CreateTexture(nil, "ARTWORK")
    button.inner:SetPoint("TOPLEFT", 4, -4)
    button.inner:SetPoint("BOTTOMRIGHT", -4, 4)
    button.inner:SetTexture("Interface\\Buttons\\WHITE8X8")
    button.inner:SetVertexColor(0.10, 0.16, 0.22, 0.98)

    button.label = button:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    button.label:SetPoint("CENTER", 0, -1)
    button.label:SetText("AB")
    button.label:SetTextColor(1, 0.84, 0.32, 1)
    button.label:SetFont(STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF", 10, "")

    button:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
    button:SetHitRectInsets(-10, -10, -10, -10)

    button:SetScript("OnClick", function(_, mouseButton)
        if mouseButton == "LeftButton" then
            ns.UI.MainWindow:Toggle()
        end
    end)

    button:SetScript("OnDragStart", function(currentButton)
        currentButton:SetScript("OnUpdate", function()
            local cursorX, cursorY = GetCursorPosition()
            local scale = Minimap:GetEffectiveScale()
            local centerX, centerY = Minimap:GetCenter()
            local offsetX = (cursorX / scale) - centerX
            local offsetY = (cursorY / scale) - centerY
            local angle = math.deg(math.atan2(offsetY, offsetX))
            ns.DB:SetMinimapAngle(angle)
            updatePosition(currentButton)
        end)
    end)

    button:SetScript("OnDragStop", function(currentButton)
        currentButton:SetScript("OnUpdate", nil)
    end)

    button:SetScript("OnEnter", setTooltip)
    button:SetScript("OnLeave", GameTooltip_Hide)

    self.button = button
    self:Refresh()
end

function MinimapButton:Refresh()
    if not self.button then
        return
    end

    if ns.DB:GetMinimapConfig().hide then
        self.button:Hide()
        return
    end

    updatePosition(self.button)
    self.button:Show()
end
