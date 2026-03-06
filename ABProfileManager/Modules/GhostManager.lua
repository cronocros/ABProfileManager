local _, ns = ...

local GhostManager = {}
ns.Modules.GhostManager = GhostManager

local function resolveButtonAction(button, fallbackSlot)
    if not button then
        return fallbackSlot
    end

    if button.action and type(button.action) == "number" then
        return button.action
    end

    if button.CalculateAction and type(button.CalculateAction) == "function" then
        return button:CalculateAction()
    end

    if ActionButton_CalculateAction then
        return ActionButton_CalculateAction(button)
    end

    return fallbackSlot
end

local function createOverlay(button)
    local overlay = CreateFrame("Button", nil, button)
    overlay:SetAllPoints(button)
    overlay:SetFrameLevel(button:GetFrameLevel() + 15)
    overlay:EnableMouse(true)

    overlay.icon = overlay:CreateTexture(nil, "OVERLAY")
    overlay.icon:SetAllPoints()
    overlay.icon:SetDesaturated(true)
    overlay.icon:SetAlpha(0.45)

    overlay.border = overlay:CreateTexture(nil, "ARTWORK")
    overlay.border:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
    overlay.border:SetBlendMode("ADD")
    overlay.border:SetAllPoints()
    overlay.border:SetVertexColor(1, 0.2, 0.2, 0.8)

    overlay.marker = overlay:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    overlay.marker:SetPoint("BOTTOMRIGHT", -2, 2)
    overlay.marker:SetText("?")
    overlay.marker:SetTextColor(1, 0.2, 0.2)

    overlay:SetScript("OnEnter", function(currentOverlay)
        GameTooltip:SetOwner(currentOverlay, "ANCHOR_RIGHT")
        GameTooltip:SetText(currentOverlay.title or ns.L("ghost_unavailable_action"))
        GameTooltip:AddLine(currentOverlay.message or ns.L("ghost_reason_default"), 1, 0.82, 0, true)
        GameTooltip:Show()
    end)
    overlay:SetScript("OnLeave", GameTooltip_Hide)
    overlay:SetScript("OnMouseUp", function(currentOverlay)
        ns.Utils.Print(currentOverlay.message or ns.L("ghost_reason_default"))
    end)

    return overlay
end

function GhostManager:Initialize()
    self.ghostsBySlot = {}
end

function GhostManager:ClearAll()
    for logicalSlot, overlay in pairs(self.ghostsBySlot) do
        overlay:Hide()
        self.ghostsBySlot[logicalSlot] = nil
    end
end

function GhostManager:GetButtonIndex()
    local buttonIndex = {}

    for _, layout in pairs(ns.Modules.SlotMapper:GetVisibleButtonDescriptors()) do
        for index, fallbackSlot in ipairs(layout.slots) do
            local buttonName = string.format("%s%d", layout.buttonPrefix, index)
            local button = _G[buttonName]
            if button then
                local logicalSlot = resolveButtonAction(button, fallbackSlot)
                if logicalSlot then
                    buttonIndex[logicalSlot] = button
                end
            end
        end
    end

    return buttonIndex
end

function GhostManager:RefreshGhosts()
    local pendingGhosts = ns.Modules.ActionBarApplier and ns.Modules.ActionBarApplier:GetPendingGhosts() or {}
    local buttonIndex = self:GetButtonIndex()
    ns.Utils.Debug(string.format("Refreshing ghost overlays: %d tracked", ns.Utils.TableCount(pendingGhosts)))

    for logicalSlot, overlay in pairs(self.ghostsBySlot) do
        if not pendingGhosts[logicalSlot] then
            overlay:Hide()
            self.ghostsBySlot[logicalSlot] = nil
        end
    end

    for logicalSlot, ghostEntry in pairs(pendingGhosts) do
        local button = buttonIndex[logicalSlot]
        local slotRecord = ghostEntry.slotRecord
        if button and slotRecord then
            local overlay = self.ghostsBySlot[logicalSlot] or createOverlay(button)
            overlay:SetParent(button)
            overlay:ClearAllPoints()
            overlay:SetAllPoints(button)
            overlay.icon:SetTexture(slotRecord.icon or ns.Constants.DEFAULT_ICON)
            overlay.title = slotRecord.name or ns.L("ghost_fallback_slot", logicalSlot)
            overlay.message = ghostEntry.reason or ns.L("ghost_reason_default")
            overlay:Show()
            self.ghostsBySlot[logicalSlot] = overlay
        elseif self.ghostsBySlot[logicalSlot] then
            self.ghostsBySlot[logicalSlot]:Hide()
        end
    end
end
