local _, ns = ...

local QuestManager = {}
ns.Modules.QuestManager = QuestManager

local function makeEmptyScan()
    return {
        supported = false,
        questCount = 0,
        abandonableCount = 0,
        safeCandidates = {},
        allCandidates = {},
        keptQuests = {},
    }
end

local function sortByTitle(left, right)
    local leftTitle = string.lower(left.title or "")
    local rightTitle = string.lower(right.title or "")
    if leftTitle == rightTitle then
        return (left.questID or 0) < (right.questID or 0)
    end

    return leftTitle < rightTitle
end

local function addBulletLine(lines, text)
    lines[#lines + 1] = "• " .. tostring(text or "")
end

local function colorize(text, colorHex)
    return string.format("|cff%s%s|r", tostring(colorHex or "ffffffff"), tostring(text or ""))
end

local QUEST_TITLE_COLOR = "fff4e2a0"
local QUEST_INFO_COLOR = "ff8fcfff"
local QUEST_REASON_COLOR = "ffa9d89e"
local QUEST_PROGRESS_COLOR = "ff9ad9ff"

local function buildQuestRowText(entry, reasonText)
    local title = colorize(entry and entry.title or "", QUEST_TITLE_COLOR)
    if reasonText then
        return string.format("%s  [%s]", title, colorize(reasonText, QUEST_REASON_COLOR))
    end

    return string.format(
        "%s  [%s]",
        title,
        colorize(ns.L("quest_list_id_format", entry and entry.questID or 0), QUEST_INFO_COLOR)
    )
end

local function shouldTrackInfo(info)
    if type(info) ~= "table" then
        return false
    end

    if info.isHeader or not info.questID then
        return false
    end

    -- Exclude hidden/task style entries so the panel reflects the normal quest log.
    if info.isTask or info.isHidden or info.isBounty then
        return false
    end

    return true
end

local function callQuestFlag(func, primaryArg, secondaryArg)
    if type(func) ~= "function" then
        return false
    end

    local ok, result = pcall(func, primaryArg)
    if ok and result ~= nil then
        return result and true or false
    end

    if secondaryArg ~= nil then
        ok, result = pcall(func, secondaryArg)
        if ok and result ~= nil then
            return result and true or false
        end
    end

    return false
end

function QuestManager:Initialize()
    self.lastScan = nil
end

function QuestManager:Invalidate()
    self.lastScan = nil
end

function QuestManager:IsSupported()
    return C_QuestLog
        and type(C_QuestLog.GetNumQuestLogEntries) == "function"
        and type(C_QuestLog.GetInfo) == "function"
        and type(C_QuestLog.GetQuestObjectives) == "function"
        and type(C_QuestLog.CanAbandonQuest) == "function"
        and (type(C_QuestLog.SetSelectedQuest) == "function" or type(SelectQuestLogEntry) == "function")
        and (type(C_QuestLog.SetAbandonQuest) == "function" or type(SetAbandonQuest) == "function")
        and type(C_QuestLog.AbandonQuest) == "function"
end

function QuestManager:HasProgress(questID)
    if not questID or not C_QuestLog or type(C_QuestLog.GetQuestObjectives) ~= "function" then
        return false
    end

    local ok, objectives = pcall(C_QuestLog.GetQuestObjectives, questID)
    if not ok then
        return false
    end

    if type(objectives) ~= "table" then
        return false
    end

    for _, objective in ipairs(objectives) do
        local fulfilled = tonumber(objective.numFulfilled) or 0
        local required = tonumber(objective.numRequired) or 0
        if objective.finished or fulfilled > 0 or (required > 0 and fulfilled >= required) then
            return true
        end
    end

    return false
end

function QuestManager:BuildObjectiveProgress(questID)
    if not questID or not C_QuestLog or type(C_QuestLog.GetQuestObjectives) ~= "function" then
        return nil, {}
    end

    local ok, objectives = pcall(C_QuestLog.GetQuestObjectives, questID)
    if not ok then
        return nil, {}
    end

    if type(objectives) ~= "table" then
        return nil, {}
    end

    local objectiveLines = {}
    for _, objective in ipairs(objectives) do
        local description = objective.text or objective.description or objective.objectiveText
        if description and description ~= "" then
            local fulfilled = tonumber(objective.numFulfilled) or 0
            local required = tonumber(objective.numRequired) or 0
            local lineText = description

            if required > 0 then
                lineText = string.format("%s %d/%d", description, fulfilled, required)
            elseif objective.finished then
                lineText = string.format("%s 1/1", description)
            end

            objectiveLines[#objectiveLines + 1] = lineText
        end
    end

    if #objectiveLines == 0 then
        return nil, {}
    end

    local preview = {}
    for index = 1, math.min(2, #objectiveLines) do
        preview[#preview + 1] = objectiveLines[index]
    end

    return table.concat(preview, " / "), objectiveLines
end

function QuestManager:BuildQuestEntry(info, logIndex)
    if not shouldTrackInfo(info) then
        return nil
    end

    local questID = info.questID
    local title = info.title or (ns.L("quest_unknown_title", questID))
    local abandonable = callQuestFlag(C_QuestLog.CanAbandonQuest, questID, logIndex)
    local isComplete = callQuestFlag(C_QuestLog.IsComplete, questID, logIndex)
    local readyForTurnIn = callQuestFlag(C_QuestLog.ReadyForTurnIn, questID, logIndex)
    local hasProgress = self:HasProgress(questID)
    local objectiveSummary, objectiveLines = self:BuildObjectiveProgress(questID)

    local keepReason = nil
    if not abandonable then
        keepReason = ns.L("quest_keep_not_abandonable")
    elseif readyForTurnIn then
        keepReason = ns.L("quest_keep_ready_for_turnin")
    elseif isComplete then
        keepReason = ns.L("quest_keep_complete")
    elseif hasProgress then
        keepReason = ns.L("quest_keep_in_progress")
    end

    return {
        questID = questID,
        title = title,
        abandonable = abandonable,
        isComplete = isComplete,
        readyForTurnIn = readyForTurnIn,
        hasProgress = hasProgress,
        objectiveSummary = objectiveSummary,
        objectiveLines = objectiveLines,
        keepReason = keepReason,
        safeCandidate = abandonable and not readyForTurnIn and not isComplete and not hasProgress,
    }
end

function QuestManager:Scan(forceRefresh)
    if not forceRefresh and self.lastScan then
        return self.lastScan
    end

    local scan = makeEmptyScan()
    scan.supported = self:IsSupported()
    if not scan.supported then
        self.lastScan = scan
        return scan
    end

    local entryCount = C_QuestLog.GetNumQuestLogEntries() or 0
    for index = 1, entryCount do
        local info = C_QuestLog.GetInfo(index)
        local entry = self:BuildQuestEntry(info, index)
        if entry then
            scan.questCount = scan.questCount + 1
            if entry.abandonable then
                scan.abandonableCount = scan.abandonableCount + 1
                scan.allCandidates[#scan.allCandidates + 1] = entry
            end

            if entry.safeCandidate then
                scan.safeCandidates[#scan.safeCandidates + 1] = entry
            else
                scan.keptQuests[#scan.keptQuests + 1] = entry
            end
        end
    end

    table.sort(scan.safeCandidates, sortByTitle)
    table.sort(scan.allCandidates, sortByTitle)
    table.sort(scan.keptQuests, sortByTitle)

    self.lastScan = scan
    return scan
end

function QuestManager:BuildSummaryText(scan)
    scan = scan or self:Scan(false)
    if not scan.supported then
        return ns.L("quest_support_unavailable")
    end

    return table.concat({
        ns.L("quest_summary_header"),
        ns.L("quest_summary_rule_safe"),
        ns.L("quest_summary_rule_safe_keep"),
        ns.L("quest_summary_rule_all"),
        "",
        ns.L("quest_summary_counts"),
        ns.L("quest_summary_total", scan.questCount),
        ns.L("quest_summary_abandonable", scan.abandonableCount),
        ns.L("quest_summary_safe", #scan.safeCandidates),
        ns.L("quest_summary_all", #scan.allCandidates),
        ns.L("quest_summary_kept", #scan.keptQuests),
    }, "\n")
end

function QuestManager:BuildCandidateListText(scan)
    scan = scan or self:Scan(false)
    if not scan.supported then
        return ns.L("quest_support_unavailable")
    end

    local lines = {}
    lines[#lines + 1] = ns.L("quest_list_safe_header", #scan.safeCandidates)
    if #scan.safeCandidates == 0 then
        addBulletLine(lines, ns.L("quest_list_none"))
    else
        for _, entry in ipairs(scan.safeCandidates) do
            addBulletLine(lines, buildQuestRowText(entry))
        end
    end

    lines[#lines + 1] = ""
    lines[#lines + 1] = ns.L("quest_list_keep_header", #scan.keptQuests)
    if #scan.keptQuests == 0 then
        addBulletLine(lines, ns.L("quest_list_none"))
    else
        for _, entry in ipairs(scan.keptQuests) do
            addBulletLine(lines, buildQuestRowText(entry, entry.keepReason or ns.L("quest_keep_unknown")))
            if entry.objectiveSummary and entry.objectiveSummary ~= "" then
                lines[#lines + 1] = "    " .. colorize(ns.L("quest_list_progress", entry.objectiveSummary), QUEST_PROGRESS_COLOR)
            end
        end
    end

    lines[#lines + 1] = ""
    lines[#lines + 1] = ns.L("quest_list_all_header", #scan.allCandidates)
    if #scan.allCandidates == 0 then
        addBulletLine(lines, ns.L("quest_list_none"))
    else
        for _, entry in ipairs(scan.allCandidates) do
            addBulletLine(lines, buildQuestRowText(entry))
            if entry.objectiveSummary and entry.objectiveSummary ~= "" then
                lines[#lines + 1] = "    " .. colorize(ns.L("quest_list_progress", entry.objectiveSummary), QUEST_PROGRESS_COLOR)
            end
        end
    end

    return table.concat(lines, "\n")
end

function QuestManager:BuildSectionText(entries, rowLabelKey, includeProgress, reasonLabelKey, addBlankLineBetween)
    local lines = {}
    if #(entries or {}) == 0 then
        addBulletLine(lines, ns.L("quest_list_none"))
        return table.concat(lines, "\n")
    end

    for index, entry in ipairs(entries or {}) do
        if reasonLabelKey then
            addBulletLine(lines, buildQuestRowText(entry, entry.keepReason or ns.L(reasonLabelKey)))
        else
            addBulletLine(lines, buildQuestRowText(entry))
        end

        if includeProgress and entry.objectiveSummary and entry.objectiveSummary ~= "" then
            lines[#lines + 1] = "    " .. colorize(ns.L("quest_list_progress", entry.objectiveSummary), QUEST_PROGRESS_COLOR)
        end

        if addBlankLineBetween and index < #(entries or {}) then
            lines[#lines + 1] = ""
        end
    end

    return table.concat(lines, "\n")
end

function QuestManager:BuildSafeSectionText(scan)
    scan = scan or self:Scan(false)
    return self:BuildSectionText(scan.safeCandidates or {}, "quest_list_safe_row", false, nil, true)
end

function QuestManager:BuildKeepSectionText(scan)
    scan = scan or self:Scan(false)
    return self:BuildSectionText(scan.keptQuests or {}, "quest_list_keep_row", true, "quest_keep_unknown", true)
end

function QuestManager:BuildAllSectionText(scan)
    scan = scan or self:Scan(false)
    return self:BuildSectionText(scan.allCandidates or {}, "quest_list_all_row", true, nil, true)
end

function QuestManager:GetSafeCandidates()
    return (self:Scan(false) or makeEmptyScan()).safeCandidates
end

function QuestManager:GetAllCandidates()
    return (self:Scan(false) or makeEmptyScan()).allCandidates
end

function QuestManager:AbandonEntries(entries)
    local abandoned = 0
    local skipped = 0
    local failed = 0

    for _, entry in ipairs(entries or {}) do
        local questID = entry.questID
        local logIndex = C_QuestLog.GetLogIndexForQuestID and C_QuestLog.GetLogIndexForQuestID(questID)
        local canSelectByQuestID = C_QuestLog.SetSelectedQuest and questID
        local canSelectByLogIndex = logIndex and logIndex > 0 and SelectQuestLogEntry

        if not questID or not canSelectByQuestID and not canSelectByLogIndex then
            skipped = skipped + 1
        elseif not callQuestFlag(C_QuestLog.CanAbandonQuest, questID, logIndex) then
            skipped = skipped + 1
        else
            local ok = true

            if canSelectByQuestID then
                ok = pcall(C_QuestLog.SetSelectedQuest, questID)
            end

            if not ok and canSelectByLogIndex then
                ok = pcall(SelectQuestLogEntry, logIndex)
            end

            if ok then
                if C_QuestLog.SetAbandonQuest then
                    ok = pcall(C_QuestLog.SetAbandonQuest)
                elseif SetAbandonQuest then
                    ok = pcall(SetAbandonQuest)
                end
            end

            if ok then
                if C_QuestLog.AbandonQuest then
                    ok = pcall(C_QuestLog.AbandonQuest)
                elseif AbandonQuest then
                    ok = pcall(AbandonQuest)
                end
            end

            if ok then
                abandoned = abandoned + 1
            else
                failed = failed + 1
            end
        end
    end

    self:Invalidate()
    local scan = self:Scan(true)
    return abandoned, skipped, failed, scan
end

function QuestManager:RunSafeCleanup()
    local scan = self:Scan(true)
    if not scan.supported then
        return nil, ns.L("quest_support_unavailable")
    end

    if #scan.safeCandidates == 0 then
        return nil, ns.L("quest_cleanup_nothing")
    end

    local abandoned, skipped, failed, refreshed = self:AbandonEntries(scan.safeCandidates)
    return {
        abandoned = abandoned,
        skipped = skipped,
        failed = failed,
        scan = refreshed,
        message = ns.L("quest_cleanup_done", abandoned, skipped, failed),
    }
end

function QuestManager:RunAbandonAll()
    local scan = self:Scan(true)
    if not scan.supported then
        return nil, ns.L("quest_support_unavailable")
    end

    if #scan.allCandidates == 0 then
        return nil, ns.L("quest_abandon_all_nothing")
    end

    local abandoned, skipped, failed, refreshed = self:AbandonEntries(scan.allCandidates)
    return {
        abandoned = abandoned,
        skipped = skipped,
        failed = failed,
        scan = refreshed,
        message = ns.L("quest_abandon_all_done", abandoned, skipped, failed),
    }
end

function QuestManager:RequestSafeCleanup(callbacks)
    local scan = self:Scan(true)
    if not scan.supported then
        if callbacks and callbacks.onComplete then
            callbacks.onComplete(nil, ns.L("quest_support_unavailable"))
        end
        return
    end

    if #scan.safeCandidates == 0 then
        if callbacks and callbacks.onComplete then
            callbacks.onComplete(nil, ns.L("quest_cleanup_nothing"))
        end
        return
    end

    local function execute()
        local result, err = self:RunSafeCleanup()
        if callbacks and callbacks.onComplete then
            callbacks.onComplete(result, err)
        end
    end

    if ns.DB and ns.DB.ShouldConfirmActions and ns.DB:ShouldConfirmActions() then
        ns.UI.ConfirmDialogs:ShowConfirm(ns.L("quest_cleanup_confirm", #scan.safeCandidates), execute)
        return
    end

    execute()
end

function QuestManager:RequestAbandonAll(callbacks)
    local scan = self:Scan(true)
    if not scan.supported then
        if callbacks and callbacks.onComplete then
            callbacks.onComplete(nil, ns.L("quest_support_unavailable"))
        end
        return
    end

    if #scan.allCandidates == 0 then
        if callbacks and callbacks.onComplete then
            callbacks.onComplete(nil, ns.L("quest_abandon_all_nothing"))
        end
        return
    end

    local function execute()
        local result, err = self:RunAbandonAll()
        if callbacks and callbacks.onComplete then
            callbacks.onComplete(result, err)
        end
    end

    ns.UI.ConfirmDialogs:ShowConfirm(ns.L("quest_abandon_all_confirm", #scan.allCandidates), execute)
end
