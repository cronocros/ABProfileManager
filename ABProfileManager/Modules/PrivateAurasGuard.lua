local _, ns = ...

ns.Modules = ns.Modules or {}
local PrivateAurasGuard = {}
ns.Modules.PrivateAurasGuard = PrivateAurasGuard

local PATCHED_KEY = "__ABPMPrivateAurasGuardPatched"
local ORIGINAL_KEY = "__ABPMOriginalCheckExistingDispelHasCorrectType"

local function debug(message)
    if ns.Utils and ns.Utils.Debug then
        ns.Utils.Debug("[PrivateAurasGuard] " .. tostring(message))
    end
end

local function isHarmlessPrivateDispelCollision(existingDispel, aura, dispelName)
    if type(existingDispel) ~= "table" or type(aura) ~= "table" then
        return false
    end

    -- Blizzard can reuse auraInstanceID values across private auras and public
    -- helpful buffs. The original assertion is diagnostic; keep both entries.
    return existingDispel.isPrivate
        and aura.isHelpful
        and not aura.isHarmful
        and aura.dispelName ~= dispelName
end

local function shouldSuppressDispelTypeAssert(anchor, aura, auraInstanceID)
    if type(anchor) ~= "table" or type(anchor.dispels) ~= "table" then
        return false
    end

    for dispelName, dispelTable in pairs(anchor.dispels) do
        if type(dispelTable) == "table" then
            local existingDispel = dispelTable[auraInstanceID]
            if existingDispel then
                return isHarmlessPrivateDispelCollision(existingDispel, aura, dispelName)
            end
        end
    end

    return false
end

local function patchPrivateAuraAnchorMixin()
    local mixin = _G.PrivateAuraAnchorContainerMixin
    if type(mixin) ~= "table" then
        return false
    end

    local original = mixin.CheckExistingDispelHasCorrectType
    if type(original) ~= "function" then
        return false
    end

    if mixin[PATCHED_KEY] then
        return true
    end

    mixin[ORIGINAL_KEY] = original
    mixin.CheckExistingDispelHasCorrectType = function(anchor, aura, auraInstanceID)
        if shouldSuppressDispelTypeAssert(anchor, aura, auraInstanceID) then
            debug(string.format(
                "suppressed private dispel/public buff auraInstanceID collision: %s",
                tostring(auraInstanceID)
            ))
            return true
        end

        return original(anchor, aura, auraInstanceID)
    end

    mixin[PATCHED_KEY] = true
    debug("patched Blizzard_PrivateAurasUI dispel type assertion")
    return true
end

function PrivateAurasGuard:Initialize()
    if patchPrivateAuraAnchorMixin() then
        return
    end

    local frame = CreateFrame("Frame")
    self.frame = frame
    frame:RegisterEvent("ADDON_LOADED")
    frame:SetScript("OnEvent", function(currentFrame, _, loadedAddonName)
        if loadedAddonName ~= "Blizzard_PrivateAurasUI" then
            return
        end

        if patchPrivateAuraAnchorMixin() then
            currentFrame:UnregisterEvent("ADDON_LOADED")
            currentFrame:SetScript("OnEvent", nil)
        end
    end)
end
