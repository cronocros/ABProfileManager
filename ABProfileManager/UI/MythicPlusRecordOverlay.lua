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

local function safeCall(fn, ...)
    if type(fn) ~= "function" then
        return nil
    end

    local ok, first, second = pcall(fn, ...)
    if not ok then
        return nil
    end

    return first, second
end

local lastMapInfoRequest = 0

local function requestMapInfo(force)
    if not C_MythicPlus then
        return false
    end

    local now = (type(GetTime) == "function" and GetTime()) or 0
    if (not force) and lastMapInfoRequest > 0 and (now - lastMapInfoRequest) < 5 then
        return false
    end
    lastMapInfoRequest = now

    safeCall(C_MythicPlus.RequestMapInfo)
    safeCall(C_MythicPlus.RequestCurrentAffixes)
    return true
end

local refreshScheduled = false
local refreshRetries = 0
local MAX_REFRESH_RETRIES = 8

local function resetRefreshRetries()
    refreshRetries = 0
end

local function scheduleRefresh(delay)
    if refreshScheduled or refreshRetries >= MAX_REFRESH_RETRIES then
        return
    end
    if type(C_Timer) ~= "table" or type(C_Timer.After) ~= "function" then
        return
    end

    refreshRetries = refreshRetries + 1
    refreshScheduled = true
    C_Timer.After(delay or 0.5, function()
        refreshScheduled = false
        MythicPlusRecordOverlay:Refresh()
    end)
end

local function pickHigherRun(current, candidate)
    if type(candidate) ~= "table" then
        return current
    end
    local candidateLevel = tonumber(candidate.level) or 0
    if candidateLevel <= 0 then
        return current
    end
    if (not current) or candidateLevel > (tonumber(current.level) or 0) then
        return candidate
    end
    return current
end

local function getAffixBestInfo(mapID)
    local affixScores = safeCall(C_MythicPlus.GetSeasonBestAffixScoreInfoForMap, mapID)
    if type(affixScores) ~= "table" then
        return nil
    end

    local best
    for _, info in ipairs(affixScores) do
        best = pickHigherRun(best, info)
    end
    return best
end

local function getRunHistoryBestInfo(mapID)
    local history = safeCall(C_MythicPlus.GetRunHistory, true, true)
    if type(history) ~= "table" then
        return nil
    end

    local best
    for _, run in ipairs(history) do
        if type(run) == "table" and tonumber(run.mapChallengeModeID) == tonumber(mapID) then
            best = pickHigherRun(best, run)
        end
    end
    return best
end

local function getSeasonBestInfo(mapID)
    if not mapID or not C_MythicPlus then
        return nil
    end

    local inTimeInfo, overtimeInfo = safeCall(C_MythicPlus.GetSeasonBestForMap, mapID)
    local bestInfo = pickHigherRun(nil, inTimeInfo)
    bestInfo = pickHigherRun(bestInfo, overtimeInfo)

    if not bestInfo then
        bestInfo = getAffixBestInfo(mapID)
    end

    if not bestInfo then
        bestInfo = getRunHistoryBestInfo(mapID)
    end

    if type(bestInfo) ~= "table" then
        return nil
    end

    return {
        level = tonumber(bestInfo.level),
        dungeonScore = tonumber(bestInfo.dungeonScore) or tonumber(bestInfo.score),
        durationSec = tonumber(bestInfo.durationSec),
    }
end

local function getBestDuration(mapID)
    if not mapID or not C_MythicPlus then
        return nil
    end

    local affixScores = safeCall(C_MythicPlus.GetSeasonBestAffixScoreInfoForMap, mapID)
    local bestDuration
    for _, info in ipairs(affixScores or {}) do
        local duration = tonumber(info and info.durationSec)
        if duration and duration > 0 and (not bestDuration or duration < bestDuration) then
            bestDuration = duration
        end
    end
    return bestDuration
end

local isKoreanLanguageSelected = ns.Utils.IsKoreanLanguageSelected

local DUNGEON_NAME_OVERRIDES = {
    ["송곳니의제단"] = { koKR = "송곳니의 제단", enUS = "Altar of Fangs" },
    ["altaroffangs"] = { koKR = "송곳니의 제단", enUS = "Altar of Fangs" },
    ["날로라크의소굴"] = { koKR = "날로라크의 소굴", enUS = "Den of Nalorakk" },
    ["denofnalorakk"] = { koKR = "날로라크의 소굴", enUS = "Den of Nalorakk" },
    ["죽음의골목"] = { koKR = "죽음의 골목", enUS = "Murder Row" },
    ["murderrow"] = { koKR = "죽음의 골목", enUS = "Murder Row" },
    ["눈부신골짜기"] = { koKR = "눈부신 골짜기", enUS = "The Blinding Vale" },
    ["theblindingvale"] = { koKR = "눈부신 골짜기", enUS = "The Blinding Vale" },
    ["공허흉터투기장"] = { koKR = "공허흉터 투기장", enUS = "Voidscar Arena" },
    ["voidscararena"] = { koKR = "공허흉터 투기장", enUS = "Voidscar Arena" },
    ["왕들의안식처"] = { koKR = "왕들의 안식처", enUS = "Kings' Rest" },
    ["kingsrest"] = { koKR = "왕들의 안식처", enUS = "Kings' Rest" },
    ["세스랄리스사원"] = { koKR = "세스랄리스 사원", enUS = "Temple of Sethraliss" },
    ["templeofsethraliss"] = { koKR = "세스랄리스 사원", enUS = "Temple of Sethraliss" },
    ["루비생명의웅덩이"] = { koKR = "루비 생명의 웅덩이", enUS = "Ruby Life Pools" },
    ["rubylifepools"] = { koKR = "루비 생명의 웅덩이", enUS = "Ruby Life Pools" },
}

local function normalizeDungeonKey(name)
    local value = tostring(name or ""):lower()
    return value:gsub("[%s%p%c]+", "")
end

local function balanceTwoLines(text)
    local words = {}
    for word in string.gmatch(tostring(text or ""), "%S+") do
        words[#words + 1] = word
    end

    if #words <= 1 then
        return tostring(text or "")
    end

    local total = 0
    for _, word in ipairs(words) do
        total = total + #word
    end

    local bestSplit = 1
    local bestDiff = nil
    local head = 0
    for index = 1, #words - 1 do
        head = head + #words[index]
        local diff = math.abs((total - head) - head)
        if bestDiff == nil or diff < bestDiff then
            bestDiff = diff
            bestSplit = index
        end
    end

    local first = {}
    local second = {}
    for index, word in ipairs(words) do
        if index <= bestSplit then
            first[#first + 1] = word
        else
            second[#second + 1] = word
        end
    end

    return table.concat(first, " ") .. "\n" .. table.concat(second, " ")
end

local function formatDungeonDisplayName(name)
    local raw = tostring(name or "")
    local compact = normalizeDungeonKey(raw)
    if compact == "" then
        return ""
    end

    local override = DUNGEON_NAME_OVERRIDES[compact]
    if override then
        raw = isKoreanLanguageSelected() and override.koKR or override.enUS
    end

    local normalized = raw:gsub("%s*/%s*", " ")
    return balanceTwoLines(normalized)
end

local OVERLAY_FRAME_LEVEL_OFFSET = 10

local function ensureDisplay(iconFrame)
    if iconFrame.ABPMRecordOverlay then
        local existing = iconFrame.ABPMRecordOverlay
        pcall(existing.SetFrameStrata, existing, iconFrame:GetFrameStrata())
        pcall(existing.SetFrameLevel, existing, (iconFrame:GetFrameLevel() or 1) + OVERLAY_FRAME_LEVEL_OFFSET)
        return existing
    end

    local holder = CreateFrame("Frame", nil, iconFrame)
    holder:SetFrameStrata(iconFrame:GetFrameStrata())
    holder:SetFrameLevel((iconFrame:GetFrameLevel() or 1) + OVERLAY_FRAME_LEVEL_OFFSET)
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
    holder.dungeonName:SetFont(FONT_PATH, 10, FONT_FLAGS)
    holder.dungeonName:SetJustifyH("CENTER")
    holder.dungeonName:SetWordWrap(true)
    if holder.dungeonName.SetMaxLines then
        holder.dungeonName:SetMaxLines(2)
    end
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
        return false
    end

    local overlay = icon.ABPMRecordOverlay
    if not ns.DB or not ns.DB:IsMythicPlusRecordOverlayEnabled() or not icon.mapID then
        if overlay then
            overlay:Hide()
        end
        return false
    end

    local bestInfo = getSeasonBestInfo(icon.mapID)
    overlay = ensureDisplay(icon)

    local mapName
    if C_ChallengeMode then
        local resolvedName = safeCall(C_ChallengeMode.GetMapUIInfo, icon.mapID)
        if type(resolvedName) == "string" and resolvedName ~= "" then
            mapName = formatDungeonDisplayName(resolvedName)
        end
    end

    if mapName and mapName ~= "" then
        overlay.dungeonName:SetText(mapName)
        overlay.dungeonName:Show()
    else
        overlay.dungeonName:SetText("")
        overlay.dungeonName:Hide()
    end

    local level = bestInfo and (tonumber(bestInfo.level) or 0) or 0
    if level > 0 then
        local rawScore = tonumber(bestInfo.dungeonScore) or 0
        local score = math.floor(rawScore + 0.5)
        local r, g, b = getScoreColor(rawScore, level)
        if score > 0 then
            overlay.levelScore:SetText(string.format("+%d  %d", level, score))
        else
            overlay.levelScore:SetText(string.format("+%d", level))
        end
        overlay.levelScore:SetTextColor(r, g, b, 1)
        overlay.levelScore:Show()
    else
        overlay.levelScore:SetText("")
        overlay.levelScore:Hide()
    end

    overlay.timeText:Hide()

    if (mapName and mapName ~= "") or level > 0 then
        overlay:Show()
        return true
    end

    overlay:Hide()
    return false
end

local ICON_CONTAINER_FIELDS = { "DungeonIcons", "MapIcons", "Icons" }
local MAX_ICON_SCAN_DEPTH = 3

local function appendIconsFromTable(list, seen, source)
    if type(source) ~= "table" then
        return
    end

    local ok = pcall(function()
        for _, entry in pairs(source) do
            if type(entry) == "table" and entry.mapID and not seen[entry] then
                seen[entry] = true
                list[#list + 1] = entry
            end
        end
    end)

    return ok
end

local function scanIconChildren(list, seen, frame, depth)
    if not frame or depth > MAX_ICON_SCAN_DEPTH or type(frame.GetChildren) ~= "function" then
        return
    end

    local ok, children = pcall(function() return { frame:GetChildren() } end)
    if not ok or type(children) ~= "table" then
        return
    end

    for _, child in ipairs(children) do
        if type(child) == "table" then
            if child.mapID and not seen[child] then
                seen[child] = true
                list[#list + 1] = child
            end
            scanIconChildren(list, seen, child, depth + 1)
        end
    end
end

local function collectDungeonIcons()
    local frame = ChallengesFrame
    if not frame then
        return nil, nil
    end

    local list = {}
    local seen = {}

    for _, field in ipairs(ICON_CONTAINER_FIELDS) do
        local ok, container = pcall(function() return frame[field] end)
        if ok then
            appendIconsFromTable(list, seen, container)
        end
    end

    if #list == 0 then
        scanIconChildren(list, seen, frame, 1)
    end

    if #list > 0 then
        return frame, list
    end

    return frame, nil
end

local mixinSetUpHooked = false

local function hookIcon(icon)
    if mixinSetUpHooked then
        return
    end
    if type(icon) ~= "table" or icon.ABPMRecordOverlayHooked or type(icon.SetUp) ~= "function" then
        return
    end

    icon.ABPMRecordOverlayHooked = true
    local ok = pcall(hooksecurefunc, icon, "SetUp", function(hookedIcon)
        MythicPlusRecordOverlay:RefreshIcon(hookedIcon)
    end)
    if not ok then
        icon.ABPMRecordOverlayHooked = nil
    end
end

function MythicPlusRecordOverlay:HideAll()
    local _, icons = collectDungeonIcons()
    if not icons then
        return
    end

    for _, icon in ipairs(icons) do
        if icon and icon.ABPMRecordOverlay then
            icon.ABPMRecordOverlay:Hide()
        end
    end
end

local lastDebugMessage = nil
local lastDebugTime = 0

local function debugLine(message)
    if not ns.Utils or type(ns.Utils.Debug) ~= "function" then
        return
    end

    local now = (type(GetTime) == "function" and GetTime()) or 0
    if message == lastDebugMessage and (now - lastDebugTime) < 10 then
        return
    end

    lastDebugMessage = message
    lastDebugTime = now
    ns.Utils.Debug(message)
end

function MythicPlusRecordOverlay:Refresh()
    if not ns.DB or not ns.DB:IsMythicPlusRecordOverlayEnabled() then
        self:HideAll()
        return
    end

    local frame, icons = collectDungeonIcons()
    if not frame or not frame:IsShown() then
        self:HideAll()
        debugLine(string.format("MythicPlusRecordOverlay: frame=%s shown=%s", tostring(frame ~= nil), tostring(frame and frame:IsShown() or false)))
        return
    end

    requestMapInfo(false)

    if not icons then
        self:HideAll()
        debugLine("MythicPlusRecordOverlay: icons=0 (retry scheduled)")
        scheduleRefresh(0.5)
        return
    end

    local drawn = 0
    for _, icon in ipairs(icons) do
        if icon then
            hookIcon(icon)
            if self:RefreshIcon(icon) then
                drawn = drawn + 1
            end
        end
    end

    debugLine(string.format("MythicPlusRecordOverlay: icons=%d drawn=%d", #icons, drawn))

    if drawn == 0 then
        scheduleRefresh(1)
    end
end

local DATA_EVENTS = {
    CHALLENGE_MODE_MAPS_UPDATE = true,
    MYTHIC_PLUS_CURRENT_AFFIX_UPDATE = true,
    CHALLENGE_MODE_COMPLETED = true,
    MYTHIC_PLUS_NEW_WEEKLY_RECORD = true,
    CHALLENGE_MODE_LEADERS_UPDATE = true,
}

local WATCHED_EVENTS = {
    "ADDON_LOADED",
    "PLAYER_ENTERING_WORLD",
    "CHALLENGE_MODE_MAPS_UPDATE",
    "MYTHIC_PLUS_CURRENT_AFFIX_UPDATE",
    "CHALLENGE_MODE_COMPLETED",
    "MYTHIC_PLUS_NEW_WEEKLY_RECORD",
    "CHALLENGE_MODE_LEADERS_UPDATE",
}

function MythicPlusRecordOverlay:SetupHooks()
    if self._hooksReady then
        return true
    end
    if not ChallengesFrame then
        return false
    end

    if ChallengesDungeonIconMixin and type(ChallengesDungeonIconMixin.SetUp) == "function" then
        local hooked = pcall(hooksecurefunc, ChallengesDungeonIconMixin, "SetUp", function(icon)
            MythicPlusRecordOverlay:RefreshIcon(icon)
        end)
        if hooked then
            mixinSetUpHooked = true
        end
    end

    pcall(ChallengesFrame.HookScript, ChallengesFrame, "OnShow", function()
        resetRefreshRetries()
        requestMapInfo(true)
        MythicPlusRecordOverlay:Refresh()
        scheduleRefresh(0.5)
    end)
    pcall(ChallengesFrame.HookScript, ChallengesFrame, "OnHide", function()
        MythicPlusRecordOverlay:HideAll()
    end)

    if type(ChallengesFrame.Update) == "function" then
        pcall(hooksecurefunc, ChallengesFrame, "Update", function()
            MythicPlusRecordOverlay:Refresh()
        end)
    end

    self._hooksReady = true
    debugLine("MythicPlusRecordOverlay: hooks ready")

    if ChallengesFrame:IsShown() then
        resetRefreshRetries()
        requestMapInfo(true)
        self:Refresh()
        scheduleRefresh(0.5)
    end

    return true
end

function MythicPlusRecordOverlay:Diagnose(sink)
    local out = sink or (ns.Utils and ns.Utils.Print)
    if type(out) ~= "function" then
        return
    end

    local enabled = (ns.DB and ns.DB:IsMythicPlusRecordOverlayEnabled()) and true or false
    out(string.format("[쐐기오버레이] 설정 enabled=%s / 훅 준비=%s", tostring(enabled), tostring(self._hooksReady and true or false)))
    out(string.format("[쐐기오버레이] API RequestMapInfo=%s / GetSeasonBestForMap=%s / GetMapUIInfo=%s",
        tostring(C_MythicPlus ~= nil and type(C_MythicPlus.RequestMapInfo) == "function"),
        tostring(C_MythicPlus ~= nil and type(C_MythicPlus.GetSeasonBestForMap) == "function"),
        tostring(C_ChallengeMode ~= nil and type(C_ChallengeMode.GetMapUIInfo) == "function")))

    out(string.format("[쐐기오버레이] API AffixScoreInfo=%s / GetRunHistory=%s",
        tostring(C_MythicPlus ~= nil and type(C_MythicPlus.GetSeasonBestAffixScoreInfoForMap) == "function"),
        tostring(C_MythicPlus ~= nil and type(C_MythicPlus.GetRunHistory) == "function")))

    local seasonHistory = C_MythicPlus and safeCall(C_MythicPlus.GetRunHistory, true, true)
    local weekHistory = C_MythicPlus and safeCall(C_MythicPlus.GetRunHistory, false, true)
    out(string.format("[쐐기오버레이] 시즌 전체 기록=%s건 / 이번 주 기록=%s건 / 시즌ID=%s",
        tostring(type(seasonHistory) == "table" and #seasonHistory or "조회실패"),
        tostring(type(weekHistory) == "table" and #weekHistory or "조회실패"),
        tostring(C_MythicPlus and safeCall(C_MythicPlus.GetCurrentSeason) or "?")))

    if not ChallengesFrame then
        out("[쐐기오버레이] ChallengesFrame 없음 - 던전 찾기 창의 신화+ 탭을 한 번 연 뒤 다시 실행하세요.")
        return
    end

    self:SetupHooks()
    requestMapInfo(true)

    local frame, icons = collectDungeonIcons()
    out(string.format("[쐐기오버레이] ChallengesFrame 존재 / IsShown=%s", tostring(frame and frame:IsShown() and true or false)))

    if not icons then
        out("[쐐기오버레이] 수집된 던전 아이콘 0개 - DungeonIcons 필드와 자식 프레임 스캔이 모두 실패했습니다.")
        return
    end

    out(string.format("[쐐기오버레이] 수집된 던전 아이콘 %d개", #icons))

    for index, icon in ipairs(icons) do
        local mapID = icon and icon.mapID
        local mapName
        if C_ChallengeMode then
            mapName = safeCall(C_ChallengeMode.GetMapUIInfo, mapID)
        end
        local bestInfo = getSeasonBestInfo(mapID)
        local overlay = icon and icon.ABPMRecordOverlay
        local overlayState = "미생성"
        if overlay then
            overlayState = overlay:IsShown() and "표시" or "숨김"
        end

        out(string.format("[쐐기오버레이] #%d mapID=%s 이름=%s 최고레벨=%s 점수=%s 오버레이=%s",
            index,
            tostring(mapID),
            tostring(mapName or "?"),
            tostring(bestInfo and bestInfo.level or "없음"),
            tostring(bestInfo and bestInfo.dungeonScore or "없음"),
            overlayState))
    end
end

function MythicPlusRecordOverlay:Initialize()
    if self._initialized then
        return
    end
    self._initialized = true

    if not self:SetupHooks() then
        debugLine("MythicPlusRecordOverlay: ChallengesFrame not loaded yet")
    end

    local watcher = CreateFrame("Frame")
    for _, event in ipairs(WATCHED_EVENTS) do
        pcall(watcher.RegisterEvent, watcher, event)
    end

    watcher:SetScript("OnEvent", function(_, event)
        MythicPlusRecordOverlay:SetupHooks()

        if event == "PLAYER_ENTERING_WORLD" then
            requestMapInfo(true)
            return
        end

        if DATA_EVENTS[event] then
            MythicPlusRecordOverlay:Refresh()
        end
    end)

    self._watcher = watcher
end
