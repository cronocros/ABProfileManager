local _, ns = ...

local MythicPlusRecordOverlay = {}
ns.UI.MythicPlusRecordOverlay = MythicPlusRecordOverlay

local FONT_PATH = "Fonts\\2002.TTF"
local FONT_FLAGS = "OUTLINE"

local function formatDuration(seconds)
    seconds = tonumber(seconds) or 0
    if seconds <= 0 then
        return "--:--"
    end

    local total = math.floor(seconds + 0.5)
    local hours = math.floor(total / 3600)
    local minutes = math.floor((total % 3600) / 60)
    local secs = total % 60
    if hours > 0 then
        return string.format("%d:%02d:%02d", hours, minutes, secs)
    end
    return string.format("%02d:%02d", minutes, secs)
end

local function getSeasonBestInfo(mapID)
    if not mapID or not C_MythicPlus or not C_MythicPlus.GetSeasonBestForMap then
        return nil
    end

    local inTimeInfo, overtimeInfo = C_MythicPlus.GetSeasonBestForMap(mapID)
    local bestInfo = inTimeInfo
    if overtimeInfo and ((not bestInfo) or ((overtimeInfo.level or 0) > (bestInfo.level or 0))) then
        bestInfo = overtimeInfo
    end

    return bestInfo
end

local function ensureDisplay(iconFrame)
    if iconFrame.ABPMRecordOverlay then
        return iconFrame.ABPMRecordOverlay
    end

    local holder = CreateFrame("Frame", nil, iconFrame, "BackdropTemplate")
    holder:SetPoint("BOTTOMLEFT", iconFrame, "BOTTOMLEFT", 3, 3)
    holder:SetPoint("BOTTOMRIGHT", iconFrame, "BOTTOMRIGHT", -3, 3)
    holder:SetHeight(24)
    if holder.SetBackdrop then
        holder:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Buttons\\WHITE8X8",
            tile = false,
            edgeSize = 1,
            insets = { left = 0, right = 0, top = 0, bottom = 0 },
        })
        holder:SetBackdropColor(0.03, 0.05, 0.09, 0.88)
        holder:SetBackdropBorderColor(0.22, 0.30, 0.42, 0.92)
    end

    holder.levelScore = holder:CreateFontString(nil, "OVERLAY")
    holder.levelScore:SetPoint("TOP", holder, "TOP", 0, -2)
    holder.levelScore:SetFont(FONT_PATH, 9, FONT_FLAGS)
    holder.levelScore:SetTextColor(1.00, 0.86, 0.48, 1)

    holder.timeText = holder:CreateFontString(nil, "OVERLAY")
    holder.timeText:SetPoint("TOP", holder.levelScore, "BOTTOM", 0, -1)
    holder.timeText:SetFont(FONT_PATH, 8, FONT_FLAGS)
    holder.timeText:SetTextColor(0.72, 0.88, 1.00, 1)

    iconFrame.ABPMRecordOverlay = holder
    return holder
end

function MythicPlusRecordOverlay:HideAll()
    local frame = ChallengesFrame
    if not frame or not frame.DungeonIcons then
        return
    end

    for _, icon in ipairs(frame.DungeonIcons) do
        if icon and icon.ABPMRecordOverlay then
            icon.ABPMRecordOverlay:Hide()
        end
    end
end

function MythicPlusRecordOverlay:Refresh()
    if not ns.DB or not ns.DB:IsMythicPlusRecordOverlayEnabled() then
        self:HideAll()
        return
    end

    local frame = ChallengesFrame
    if not frame or not frame:IsShown() or not frame.DungeonIcons then
        self:HideAll()
        return
    end

    for _, icon in ipairs(frame.DungeonIcons) do
        if icon and icon:IsShown() and icon.mapID then
            local bestInfo = getSeasonBestInfo(icon.mapID)
            local overlay = ensureDisplay(icon)
            if bestInfo and (bestInfo.level or 0) > 0 then
                local score = math.floor((bestInfo.dungeonScore or 0) + 0.5)
                overlay.levelScore:SetText(string.format("+%d  %d", bestInfo.level or 0, score))
                overlay.timeText:SetText(formatDuration(bestInfo.durationSec))
                overlay:Show()
            else
                overlay:Hide()
            end
        elseif icon and icon.ABPMRecordOverlay then
            icon.ABPMRecordOverlay:Hide()
        end
    end
end

function MythicPlusRecordOverlay:Initialize()
    if self._initialized then
        return
    end
    self._initialized = true

    local function setupHooks()
        if self._hooksReady or not ChallengesFrame then
            return self._hooksReady and true or false
        end

        ChallengesFrame:HookScript("OnShow", function()
            MythicPlusRecordOverlay:Refresh()
        end)
        ChallengesFrame:HookScript("OnHide", function()
            MythicPlusRecordOverlay:HideAll()
        end)
        if type(ChallengesFrame.Update) == "function" then
            hooksecurefunc(ChallengesFrame, "Update", function()
                MythicPlusRecordOverlay:Refresh()
            end)
        end
        self._hooksReady = true
        if ChallengesFrame:IsShown() then
            MythicPlusRecordOverlay:Refresh()
        end
        return true
    end

    if not setupHooks() then
        local watcher = CreateFrame("Frame")
        watcher:RegisterEvent("ADDON_LOADED")
        watcher:SetScript("OnEvent", function(frame, _, addonName)
            if addonName == "Blizzard_ChallengesUI" or addonName == "Blizzard_LookingForGroup" then
                if setupHooks() then
                    frame:UnregisterEvent("ADDON_LOADED")
                    frame:SetScript("OnEvent", nil)
                end
            end
        end)
    end
end
