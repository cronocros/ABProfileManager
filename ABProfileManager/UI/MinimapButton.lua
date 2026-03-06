local _, ns = ...

local MinimapButton = {}
ns.UI.MinimapButton = MinimapButton

local ICON_MASK = "Interface\\CHARACTERFRAME\\TempPortraitAlphaMask"

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
    button:SetSize(24, 24)
    button:SetFrameStrata("MEDIUM")
    button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    button:RegisterForDrag("RightButton")

    button.shadow = button:CreateTexture(nil, "BACKGROUND")
    button.shadow:SetPoint("TOPLEFT", 1, -1)
    button.shadow:SetPoint("BOTTOMRIGHT", -1, 1)
    button.shadow:SetTexture("Interface\\Buttons\\WHITE8X8")
    button.shadow:SetVertexColor(0.01, 0.02, 0.04, 0.94)
    button.shadow:SetMask(ICON_MASK)

    button.ring = button:CreateTexture(nil, "BORDER")
    button.ring:SetAllPoints()
    button.ring:SetTexture("Interface\\Buttons\\WHITE8X8")
    button.ring:SetVertexColor(0.76, 0.62, 0.24, 0.98)
    button.ring:SetMask(ICON_MASK)

    button.icon = button:CreateTexture(nil, "ARTWORK")
    button.icon:SetPoint("TOPLEFT", 3, -3)
    button.icon:SetPoint("BOTTOMRIGHT", -3, 3)
    button.icon:SetTexture(ns.Constants.DEFAULT_ICON)
    button.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    button.icon:SetMask(ICON_MASK)

    button.gloss = button:CreateTexture(nil, "OVERLAY")
    button.gloss:SetPoint("TOPLEFT", 5, -5)
    button.gloss:SetPoint("BOTTOMRIGHT", -5, 5)
    button.gloss:SetTexture("Interface\\Buttons\\WHITE8X8")
    button.gloss:SetVertexColor(1, 1, 1, 0.08)
    button.gloss:SetMask(ICON_MASK)

    button.highlight = button:CreateTexture(nil, "HIGHLIGHT")
    button.highlight:SetPoint("TOPLEFT", 1, -1)
    button.highlight:SetPoint("BOTTOMRIGHT", -1, 1)
    button.highlight:SetTexture("Interface\\Buttons\\WHITE8X8")
    button.highlight:SetVertexColor(1, 0.92, 0.55, 0.14)
    button.highlight:SetMask(ICON_MASK)

    button:SetHitRectInsets(-8, -8, -8, -8)

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
