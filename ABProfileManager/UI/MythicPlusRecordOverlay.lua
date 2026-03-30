local _, ns = ...

local MythicPlusRecordOverlay = {}
ns.UI.MythicPlusRecordOverlay = MythicPlusRecordOverlay

local FONT_PATH = UNIT_NAME_FONT or STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF"
local FONT_FLAGS = "OUTLINE"

local function unpackColor(color)
    if not color then
        return nil
    end
    if type(color.GetRGB) == "function" then
        return color:GetRGB()
    end
    if color.r and color.g and color.b then
        return color.r, color.g, color.b
    end
    return nil
end

local function getScoreColor(score, level)
    score = tonumber(score) or 0
    level = tonumber(level) or 0

    if C_ChallengeMode then
        local color

        if score > 0 and type(C_ChallengeMode.GetSpecificDungeonOverallScoreRarityColor) == "function" then
            local ok, result = pcall(C_ChallengeMode.GetSpecificDungeonOverallScoreRarityColor, score)
            if ok and result then
                color = result
            end
        end

        if (not color) and score > 0 and type(C_ChallengeMode.GetSpecificDungeonScoreRarityColor) == "function" then
            local ok, result = pcall(C_ChallengeMode.GetSpecificDungeonScoreRarityColor, score)
            if ok and result then
                color = result
            end
        end

        if (not color) and score > 0 and type(C_ChallengeMode.GetDungeonScoreRarityColor) == "function" then
            local ok, result = pcall(C_ChallengeMode.GetDungeonScoreRarityColor, score)
            if ok and result then
                color = result
            end
        end

        if (not color) and level > 0 and type(C_ChallengeMode.GetKeystoneLevelRarityColor) == "function" then
            local ok, result = pcall(C_ChallengeMode.GetKeystoneLevelRarityColor, level)
            if ok and result then
                color = result
            end
        end

        local r, g, b = unpackColor(color)
        if r and g and b then
            return r, g, b
        end
    end

    if level >= 10 then
        return 0.78, 0.45, 1.00
    end
    if level >= 7 then
        return 0.32, 0.72, 1.00
    end
    return 0.38, 0.95, 0.46
end

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

local DUNGEON_NAME_OVERRIDES = {
    ["윈드러너첨탑"] = "윈드러너\n첨탑",
    ["삼두정의권좌"] = "삼두정의\n권좌",
    ["공결탑제나스"] = "공결탑\n제나스",
    ["사론의구덩이"] = "사론의\n구덩이",
    ["마법학자의정원"] = "마법학자의\n정원",
    ["마이사라동굴"] = "마이사라\n동굴",
    ["알게타르대학"] = "알케타르\n대학",
}

local function formatDungeonDisplayName(name)
    local compact = tostring(name or ""):gsub("%s+", "")
    if compact == "" then
        return ""
    end
    return DUNGEON_NAME_OVERRIDES[compact] or compact:gsub("/", "\n")
end

local function ensureDisplay(iconFrame)
    if iconFrame.ABPMRecordOverlay then
        iconFrame.ABPMRecordOverlay:SetFrameLevel((iconFrame:GetFrameLevel() or 1) + 8)
        return iconFrame.ABPMRecordOverlay
    end

    local holder = CreateFrame("Frame", nil, iconFrame)
    holder:SetFrameStrata(iconFrame:GetFrameStrata())
    holder:SetFrameLevel((iconFrame:GetFrameLevel() or 1) + 8)
    holder:SetPoint("BOTTOMLEFT", iconFrame, "BOTTOMLEFT", 2, 1)
    holder:SetPoint("BOTTOMRIGHT", iconFrame, "BOTTOMRIGHT", -2, 1)
    holder:SetHeight(44)

    holder.levelScore = holder:CreateFontString(nil, "OVERLAY")
    holder.levelScore:SetPoint("BOTTOM", holder, "BOTTOM", 0, 24)
    holder.levelScore:SetFont(FONT_PATH, 14, FONT_FLAGS)
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
    holder.timeText:Hide()

    holder.dungeonName = holder:CreateFontString(nil, "OVERLAY")
    holder.dungeonName:SetPoint("BOTTOMLEFT", holder, "BOTTOMLEFT", -2, 0)
    holder.dungeonName:SetPoint("BOTTOMRIGHT", holder, "BOTTOMRIGHT", 2, 0)
    holder.dungeonName:SetFont(FONT_PATH, 11, FONT_FLAGS)
    holder.dungeonName:SetJustifyH("CENTER")
    holder.dungeonName:SetWordWrap(true)
    if holder.dungeonName.SetSpacing then
        holder.dungeonName:SetSpacing(0)
    end
    holder.dungeonName:SetTextColor(0.92, 0.96, 1.00, 1)
    if holder.dungeonName.SetShadowOffset then
        holder.dungeonName:SetShadowOffset(1, -1)
        holder.dungeonName:SetShadowColor(0, 0, 0, 0.95)
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
    overlay = ensureDisplay(icon)
    if bestInfo and (bestInfo.level or 0) > 0 then
        local mapName
        if C_ChallengeMode and type(C_ChallengeMode.GetMapUIInfo) == "function" then
            local ok, resolvedName = pcall(C_ChallengeMode.GetMapUIInfo, icon.mapID)
            if ok and type(resolvedName) == "string" and resolvedName ~= "" then
                mapName = formatDungeonDisplayName(resolvedName)
            end
        end
        local rawScore = tonumber(bestInfo.dungeonScore) or 0
        local score = math.floor(rawScore + 0.5)
        local r, g, b = getScoreColor(rawScore, bestInfo.level)
        overlay.dungeonName:SetText(mapName or "")
        if mapName and mapName ~= "" then
            overlay.dungeonName:Show()
        else
            overlay.dungeonName:Hide()
        end
        overlay.levelScore:SetText(tostring(score))
        overlay.levelScore:SetTextColor(r, g, b, 1)
        overlay.timeText:Hide()
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
