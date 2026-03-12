local _, ns = ...

local Tracker = {}
ns.Modules.ProfessionKnowledgeTracker = Tracker

local KNOWN_SKILL_LINES = {}
local ORDER_INDEX = {}
local OBJECTIVE_BASE_TRANSLATIONS = {
    ["Tranquility Bloom"] = "평온꽃",
    ["Sanguithorn"] = "붉은가시",
    ["Azeroot"] = "아제로뿌리",
    ["Argentleaf"] = "은빛잎새",
    ["Mana Lily"] = "마나 백합",
    ["Refulgent Copper"] = "찬란한 구리",
    ["Umbral Tin"] = "암영 주석",
    ["Brilliant Silver"] = "찬란한 은",
    ["Alchemy"] = "연금술",
    ["Blacksmithing"] = "대장기술",
    ["Engineering"] = "기계공학",
    ["Enchanting"] = "마법부여",
    ["Herbalism"] = "약초채집",
    ["Inscription"] = "주문각인",
    ["Jewelcrafting"] = "보석세공",
    ["Leatherworking"] = "가죽세공",
    ["Mining"] = "채광",
    ["Skinning"] = "무두질",
    ["Tailoring"] = "재봉술",
}
local OBJECTIVE_DIRECT_TRANSLATIONS = {
    ["Weekly Quest"] = "주간 퀘스트",
    ["Trainer Weekly Quest"] = "전문기술 주간 퀘스트",
    ["Treatise"] = "전문기술 논문",
    ["Greater Herb Sample"] = "고급 약초 견본",
    ["Greater Ore Sample"] = "고급 광석 견본",
    ["Greater Skinning Trophy"] = "고급 무두질 전리품",
    ["Greater Disenchant Drop"] = "고급 마력추출 전리품",
}

local function getDefinitions()
    return ns.Data and ns.Data.ProfessionKnowledge and ns.Data.ProfessionKnowledge.professions or {}
end

local function getProfessionStore()
    local character = ns.DB and ns.DB:GetCharacterRecord()
    if not character then
        return nil
    end

    character.professionKnowledge = character.professionKnowledge or {}
    return character.professionKnowledge
end

local function safeDate()
    if type(date) == "function" then
        return date("%Y-%m-%d %H:%M:%S")
    end

    return ""
end

local function resetEvaluationCaches(self)
    self.evaluationCache = {}
    self.sectionSummaryCache = {}
    self.professionSummaryCache = {}
end

local function getQuestTitle(questID)
    questID = tonumber(questID)
    if not questID or questID <= 0 then
        return nil
    end

    if C_QuestLog and type(C_QuestLog.GetTitleForQuestID) == "function" then
        local ok, title = pcall(C_QuestLog.GetTitleForQuestID, questID)
        if ok and type(title) == "string" and title ~= "" then
            return title
        end
    end

    if type(QuestUtils_GetQuestName) == "function" then
        local ok, title = pcall(QuestUtils_GetQuestName, questID)
        if ok and type(title) == "string" and title ~= "" then
            return title
        end
    end

    return nil
end

local function translateObjectiveName(name)
    if type(name) ~= "string" or name == "" then
        return name or ""
    end

    local direct = OBJECTIVE_DIRECT_TRANSLATIONS[name]
    if direct then
        return direct
    end

    local sampleKind, sampleIndex = name:match("^(Gathered Herb Sample) (%d+)$")
    if sampleKind then
        return string.format("약초 견본 %s", sampleIndex)
    end

    sampleKind, sampleIndex = name:match("^(Mined Ore Sample) (%d+)$")
    if sampleKind then
        return string.format("광석 견본 %s", sampleIndex)
    end

    sampleKind, sampleIndex = name:match("^(Skinned Trophy) (%d+)$")
    if sampleKind then
        return string.format("무두질 전리품 %s", sampleIndex)
    end

    sampleKind, sampleIndex = name:match("^(Disenchant Drop) (%d+)$")
    if sampleKind then
        return string.format("마력추출 전리품 %s", sampleIndex)
    end

    local prefixTransforms = {
        { pattern = "^Lush (.+)$", label = "풍성한 %s" },
        { pattern = "^Lightfused (.+)$", label = "빛벼림 %s" },
        { pattern = "^Voidbound (.+)$", label = "공허벼림 %s" },
        { pattern = "^Primal (.+)$", label = "원초의 %s" },
        { pattern = "^Wild (.+)$", label = "야생의 %s" },
        { pattern = "^Rich (.+)$", label = "풍부한 %s" },
        { pattern = "^Beyond the Event Horizon: (.+)$", label = "사건의 지평선 너머: %s" },
        { pattern = "^Skill Issue: (.+)$", label = "기술의 벽: %s" },
        { pattern = "^Whisper of the Loa: (.+)$", label = "로아의 속삭임: %s" },
        { pattern = "^Echo of Abundance: (.+)$", label = "풍요의 메아리: %s" },
        { pattern = "^Traditions of the Haranir: (.+)$", label = "하라니르의 전통: %s" },
    }

    for _, entry in ipairs(prefixTransforms) do
        local baseName = name:match(entry.pattern)
        if baseName then
            local translatedBase = OBJECTIVE_BASE_TRANSLATIONS[baseName]
            if translatedBase then
                return string.format(entry.label, translatedBase)
            end
        end
    end

    local seamBase = name:match("^(.+) Seam$")
    if seamBase then
        local translatedBase = OBJECTIVE_BASE_TRANSLATIONS[seamBase]
        if translatedBase then
            return string.format("%s 광맥", translatedBase)
        end
    end

    local baseTranslation = OBJECTIVE_BASE_TRANSLATIONS[name]
    if baseTranslation then
        return baseTranslation
    end

    return name
end

function Tracker:Initialize()
    wipe(KNOWN_SKILL_LINES)
    wipe(ORDER_INDEX)

    local order = ns.Data and ns.Data.ProfessionKnowledge and ns.Data.ProfessionKnowledge.order or {}
    for index, key in ipairs(order) do
        ORDER_INDEX[key] = index
    end

    for _, definition in ipairs(getDefinitions()) do
        KNOWN_SKILL_LINES[definition.skillLine] = definition
    end

    self.completedQuestLookup = {}
    self.questStatusLookup = {}
    self.questCacheDirty = true
    self.questCacheGeneration = 0
    resetEvaluationCaches(self)
end

function Tracker:MarkDirty()
    self.questCacheDirty = true
    resetEvaluationCaches(self)
end

function Tracker:RefreshQuestCache(force)
    if not force and not self.questCacheDirty and self.completedQuestLookup then
        return self.completedQuestLookup
    end

    local lookup = {}
    if C_QuestLog and type(C_QuestLog.GetAllCompletedQuestIDs) == "function" then
        local completedQuestIDs = C_QuestLog.GetAllCompletedQuestIDs()
        if type(completedQuestIDs) == "table" then
            for _, questID in pairs(completedQuestIDs) do
                questID = tonumber(questID)
                if questID and questID > 0 then
                    lookup[questID] = true
                end
            end
        end
    end

    self.completedQuestLookup = lookup
    self.questStatusLookup = {}
    self.questCacheDirty = false
    self.questCacheGeneration = (self.questCacheGeneration or 0) + 1
    resetEvaluationCaches(self)

    local store = getProfessionStore()
    if store then
        store.lastScanAt = safeDate()
        store.lastCompletedQuestCount = 0
        for _ in pairs(lookup) do
            store.lastCompletedQuestCount = (store.lastCompletedQuestCount or 0) + 1
        end
    end

    ns.Utils.Debug(string.format("Profession knowledge scan refreshed: %d completed quests", ns.Utils.TableCount(lookup)))

    return lookup
end

function Tracker:GetLastScanLabel()
    local store = getProfessionStore()
    return store and store.lastScanAt or ""
end

function Tracker:GetDefinitionByKey(professionKey)
    for _, definition in ipairs(getDefinitions()) do
        if definition.key == professionKey then
            return definition
        end
    end

    return nil
end

function Tracker:GetDefinitionBySkillLine(skillLine)
    return KNOWN_SKILL_LINES[tonumber(skillLine) or 0]
end

function Tracker:GetObjectiveDisplayName(objective)
    if not objective then
        return ""
    end

    local language = ns.DB and ns.DB.GetLanguage and ns.DB:GetLanguage() or nil
    if language ~= (ns.Constants and ns.Constants.LANGUAGE and ns.Constants.LANGUAGE.KOREAN) then
        return objective.name or ""
    end

    for _, questID in ipairs(objective.questIDs or {}) do
        local questTitle = getQuestTitle(questID)
        if questTitle and questTitle ~= "" then
            return questTitle
        end
    end

    return translateObjectiveName(objective.name or "")
end

function Tracker:GetTreasureWaypoint(professionKey, objectiveRow)
    local waypointData = ns.Data and ns.Data.ProfessionKnowledgeWaypoints and ns.Data.ProfessionKnowledgeWaypoints.treasures
    local professionWaypoints = waypointData and waypointData[professionKey]
    if not professionWaypoints or not objectiveRow then
        return nil
    end

    for _, questID in ipairs(objectiveRow.questIDs or {}) do
        local waypoint = professionWaypoints[tonumber(questID) or 0]
        if waypoint then
            return waypoint
        end
    end

    local rawName = objectiveRow.rawName
    if rawName and professionWaypoints[rawName] then
        return professionWaypoints[rawName]
    end

    return nil
end

function Tracker:GetNextTreasureWaypoint(professionKey)
    local treasureRow = self:EvaluateSource(professionKey, "treasures")
    if not treasureRow then
        return nil
    end

    for _, objectiveRow in ipairs(treasureRow.objectiveRows or {}) do
        if not objectiveRow.complete then
            local waypoint = self:GetTreasureWaypoint(professionKey, objectiveRow)
            if waypoint then
                return {
                    professionKey = professionKey,
                    objective = objectiveRow,
                    mapID = waypoint.mapID,
                    x = waypoint.x,
                    y = waypoint.y,
                    title = waypoint.title or objectiveRow.name or "",
                }
            end
        end
    end

    return nil
end

function Tracker:IsQuestComplete(questID)
    questID = tonumber(questID)
    if not questID or questID <= 0 then
        return false
    end

    self:RefreshQuestCache(false)

    if self.questStatusLookup and self.questStatusLookup[questID] ~= nil then
        return self.questStatusLookup[questID] and true or false
    end

    if C_QuestLog and type(C_QuestLog.IsQuestFlaggedCompleted) == "function" then
        local ok, result = pcall(C_QuestLog.IsQuestFlaggedCompleted, questID)
        if ok then
            if result then
                self.completedQuestLookup[questID] = true
            end
            self.questStatusLookup[questID] = result and true or false
            return result and true or false
        end
    end

    local completed = self.completedQuestLookup and self.completedQuestLookup[questID] and true or false
    self.questStatusLookup[questID] = completed
    return completed
end

function Tracker:IsObjectiveComplete(objective)
    if not objective or type(objective.questIDs) ~= "table" or #objective.questIDs == 0 then
        return false
    end

    local matchMode = objective.match == "all" and "all" or "any"
    if matchMode == "all" then
        for _, questID in ipairs(objective.questIDs) do
            if not self:IsQuestComplete(questID) then
                return false
            end
        end
        return true
    end

    for _, questID in ipairs(objective.questIDs) do
        if self:IsQuestComplete(questID) then
            return true
        end
    end

    return false
end

function Tracker:EvaluateSource(professionKey, sourceKey)
    local definition = self:GetDefinitionByKey(professionKey)
    if not definition then
        return nil
    end

    local sourceDefinition = nil
    local sectionKey = nil
    for _, source in ipairs(definition.weekly or {}) do
        if source.key == sourceKey then
            sourceDefinition = source
            sectionKey = "weekly"
            break
        end
    end

    if not sourceDefinition then
        for _, source in ipairs(definition.oneTime or {}) do
            if source.key == sourceKey then
                sourceDefinition = source
                sectionKey = "oneTime"
                break
            end
        end
    end

    if not sourceDefinition then
        return nil
    end

    local cacheKey = string.format("%s:%s", tostring(professionKey), tostring(sourceKey))
    local cached = self.evaluationCache and self.evaluationCache[cacheKey]
    if cached and cached.generation == (self.questCacheGeneration or 0) then
        return cached.value
    end

    local earnedPoints = 0
    local maxPoints = 0
    local completedObjectives = 0
    local objectiveRows = {}
    local language = ns.DB and ns.DB.GetLanguage and ns.DB:GetLanguage() or nil

    for index, objective in ipairs(sourceDefinition.objectives or {}) do
        local isComplete = self:IsObjectiveComplete(objective)
        local points = tonumber(objective.points) or 0
        if isComplete then
            earnedPoints = earnedPoints + points
            completedObjectives = completedObjectives + 1
        end
        maxPoints = maxPoints + points

        local rawName = objective and objective.name or ""
        local objectiveName = self:GetObjectiveDisplayName(objective)
        if language == (ns.Constants and ns.Constants.LANGUAGE and ns.Constants.LANGUAGE.KOREAN) then
            local rawName = objective and objective.name or ""
            if rawName ~= "" and objectiveName == rawName then
                if sectionKey == "oneTime" and sourceDefinition.key == "treasures" then
                    objectiveName = rawName
                else
                    objectiveName = string.format("%s %d", ns.L(sourceDefinition.labelKey), index)
                end
            end
        end

        objectiveRows[#objectiveRows + 1] = {
            index = index,
            name = objectiveName,
            rawName = rawName,
            points = points,
            complete = isComplete,
            questIDs = ns.Utils.DeepCopy(objective.questIDs or {}),
        }
    end

    local result = {
        sectionKey = sectionKey,
        key = sourceDefinition.key,
        labelKey = sourceDefinition.labelKey,
        title = ns.L(sourceDefinition.labelKey),
        current = completedObjectives,
        max = #(sourceDefinition.objectives or {}),
        earned = earnedPoints,
        maxPoints = maxPoints,
        complete = completedObjectives == #(sourceDefinition.objectives or {}),
        objectiveRows = objectiveRows,
    }

    self.evaluationCache[cacheKey] = {
        generation = self.questCacheGeneration or 0,
        value = result,
    }

    return result
end

function Tracker:GetKnownProfessions()
    if type(GetProfessions) ~= "function" or type(GetProfessionInfo) ~= "function" then
        return {}
    end

    local results = {}
    local seen = {}
    local slots = { GetProfessions() }

    for _, professionIndex in ipairs(slots) do
        if professionIndex then
            local name, icon, skillLevel, maxSkillLevel, _, _, skillLine = GetProfessionInfo(professionIndex)
            local definition = self:GetDefinitionBySkillLine(skillLine)
            if definition and not seen[definition.key] then
                results[#results + 1] = {
                    key = definition.key,
                    name = name or ns.L(definition.labelKey),
                    icon = icon,
                    skillLevel = tonumber(skillLevel) or 0,
                    maxSkillLevel = tonumber(maxSkillLevel) or 0,
                    skillLine = skillLine,
                    definition = definition,
                }
                seen[definition.key] = true
            end
        end
    end

    table.sort(results, function(left, right)
        local leftIndex = ORDER_INDEX[left.key] or 999
        local rightIndex = ORDER_INDEX[right.key] or 999
        if leftIndex == rightIndex then
            return (left.name or left.key) < (right.name or right.key)
        end
        return leftIndex < rightIndex
    end)

    return results
end

function Tracker:GetSectionSummary(professionKey, sectionName)
    local definition = self:GetDefinitionByKey(professionKey)
    if not definition or not definition[sectionName] then
        return 0, 0
    end

    local cacheKey = string.format("%s:%s", tostring(professionKey), tostring(sectionName))
    local cached = self.sectionSummaryCache and self.sectionSummaryCache[cacheKey]
    if cached and cached.generation == (self.questCacheGeneration or 0) then
        return cached.earned, cached.maximum
    end

    local earned = 0
    local maximum = 0
    for _, source in ipairs(definition[sectionName]) do
        local row = self:EvaluateSource(professionKey, source.key)
        earned = earned + (row and row.earned or 0)
        maximum = maximum + (row and row.maxPoints or 0)
    end

    self.sectionSummaryCache[cacheKey] = {
        generation = self.questCacheGeneration or 0,
        earned = earned,
        maximum = maximum,
    }

    return earned, maximum
end

function Tracker:GetProfessionSummary(professionKey)
    local definition = self:GetDefinitionByKey(professionKey)
    if not definition then
        return nil
    end

    local cached = self.professionSummaryCache and self.professionSummaryCache[professionKey]
    if cached and cached.generation == (self.questCacheGeneration or 0) then
        return cached.value
    end

    local weeklyEarned, weeklyMax = self:GetSectionSummary(professionKey, "weekly")
    local oneTimeEarned, oneTimeMax = self:GetSectionSummary(professionKey, "oneTime")

    local result = {
        professionKey = professionKey,
        definition = definition,
        weeklyEarned = weeklyEarned,
        weeklyMax = weeklyMax,
        oneTimeEarned = oneTimeEarned,
        oneTimeMax = oneTimeMax,
    }

    self.professionSummaryCache[professionKey] = {
        generation = self.questCacheGeneration or 0,
        value = result,
    }

    return result
end

function Tracker:GetProfessionSections(professionKey)
    local definition = self:GetDefinitionByKey(professionKey)
    if not definition then
        return {}
    end

    local sections = {}
    local sectionOrder = {
        { key = "weekly", title = ns.L("professions_weekly") },
        { key = "oneTime", title = ns.L("professions_one_time") },
    }

    for _, sectionInfo in ipairs(sectionOrder) do
        local rows = {}
        for _, source in ipairs(definition[sectionInfo.key] or {}) do
            local row = self:EvaluateSource(professionKey, source.key)
            if row then
                rows[#rows + 1] = row
            end
        end

        sections[#sections + 1] = {
            key = sectionInfo.key,
            title = sectionInfo.title,
            rows = rows,
        }
    end

    return sections
end

function Tracker:GetProfessionDisplayName(professionEntry)
    if professionEntry and professionEntry.name and professionEntry.name ~= "" then
        return professionEntry.name
    end

    if professionEntry and professionEntry.definition then
        return ns.L(professionEntry.definition.labelKey)
    end

    return ns.L("professions_empty")
end
