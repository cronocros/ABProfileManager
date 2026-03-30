local _, ns = ...

local MythicPlusRecordOverlay = {}
ns.UI.MythicPlusRecordOverlay = MythicPlusRecordOverlay

local FONT_PATH = UNIT_NAME_FONT or STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF"
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

local function getBestDuration(mapID)
    if not mapID or not C_MythicPlus or not C_MythicPlus.GetSeasonBestAffixScoreInfoForMap then
        return nil
    end

    local affixScores = C_MythicPlus.GetSeasonBestAffixScoreInfoForMap(mapID)
    local bestDuration
    for _, info in ipairs(affixScores or {}) do
        local duration = tonumber(info and info.durationSec)
        if duration and duration > 0 and (not bestDuration or duration < bestDuration) then
            bestDuration = duration
        end
    end
    return bestDuration
end

local function ensureDisplay(iconFrame)
    if iconFrame.ABPMRecordOverlay then
        iconFrame.ABPMRecordOverlay:SetFrameLevel((iconFrame:GetFrameLevel() or 1) + 8)
        return iconFrame.ABPMRecordOverlay
    end

    local holder = CreateFrame("Frame", nil, iconFrame)
    holder:SetFrameStrata(iconFrame:GetFrameStrata())
    holder:SetFrameLevel((iconFrame:GetFrameLevel() or 1) + 8)
    holder:SetPoint("BOTTOMLEFT", iconFrame, "BOTTOMLEFT", 2, 4)
    holder:SetPoint("BOTTOMRIGHT", iconFrame, "BOTTOMRIGHT", -2, 4)
    holder:SetHeight(24)

    holder.levelScore = holder:CreateFontString(nil, "OVERLAY")
    holder.levelScore:SetPoint("BOTTOM", holder, "BOTTOM", 0, 9)
    holder.levelScore:SetFont(FONT_PATH, 12, FONT_FLAGS)
    holder.levelScore:SetTextColor(1.00, 1.00, 1.00, 1)
    if holder.levelScore.SetShadowOffset then
        holder.levelScore:SetShadowOffset(1, -1)
        holder.levelScore:SetShadowColor(0, 0, 0, 0.95)
    end

    holder.timeText = holder:CreateFontString(nil, "OVERLAY")
    holder.timeText:SetPoint("TOP", holder.levelScore, "BOTTOM", 0, -1)
    holder.timeText:SetFont(FONT_PATH, 9, FONT_FLAGS)
    holder.timeText:SetTextColor(0.92, 0.96, 1.00, 1)
    if holder.timeText.SetShadowOffset then
        holder.timeText:SetShadowOffset(1, -1)
        holder.timeText:SetShadowColor(0, 0, 0, 0.95)
    end

    iconFrame.ABPMRecordOverlay = holder
    return holder
end

function MythicPlusRecordOverlay:RefreshIcon(icon)
    if not icon then
        return
    end

    local overlay = icon.ABPMRecordOverlay
    if not ns.DB or not ns.DB:IsMythicPlusRecordOverlayEnabled() or not icon.mapID then
        if overlay then
            overlay:Hide()
        end
        return
    end

    local bestInfo = getSeasonBestInfo(icon.mapID)
    local bestDuration = getBestDuration(icon.mapID)
    overlay = ensureDisplay(icon)
    if bestInfo and (bestInfo.level or 0) > 0 then
        local score = math.floor((bestInfo.dungeonScore or 0) + 0.5)
        overlay.levelScore:SetText(tostring(score))
        overlay.timeText:SetText((ns.L("mplus_record_best_time") or "최고기록") .. " " .. formatDuration(bestDuration or bestInfo.durationSec))
        overlay:Show()
    else
        overlay:Hide()
    end
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
        if icon then
            self:RefreshIcon(icon)
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

        if ChallengesDungeonIconMixin and type(ChallengesDungeonIconMixin.SetUp) == "function" then
            hooksecurefunc(ChallengesDungeonIconMixin, "SetUp", function(icon)
                MythicPlusRecordOverlay:RefreshIcon(icon)
            end)
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
