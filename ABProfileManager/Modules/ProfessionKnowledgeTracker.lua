local _, ns = ...

local Tracker = {}
ns.Modules.ProfessionKnowledgeTracker = Tracker

local KNOWN_SKILL_LINES = {}

local function getDefinitions()
    return ns.Data and ns.Data.ProfessionKnowledge and ns.Data.ProfessionKnowledge.professions or {}
end

local function getWeeklyResetKey()
    local serverTime = (type(GetServerTime) == "function" and GetServerTime()) or time()
    local resetSeconds = C_DateAndTime and C_DateAndTime.GetSecondsUntilWeeklyReset and C_DateAndTime.GetSecondsUntilWeeklyReset()
    if type(resetSeconds) == "number" and resetSeconds >= 0 then
        return tostring(math.floor((serverTime + resetSeconds + 30) / 60))
    end

    return date("!%Y-%W", serverTime)
end

local function getProfessionStore()
    local character = ns.DB and ns.DB:GetCharacterRecord()
    if not character then
        return nil
    end

    character.professionKnowledge = character.professionKnowledge or {
        weeklyResetKey = getWeeklyResetKey(),
        professions = {},
    }
    character.professionKnowledge.professions = character.professionKnowledge.professions or {}
    return character.professionKnowledge
end

local function clampValue(value, minValue, maxValue)
    value = math.floor(tonumber(value) or 0)
    minValue = tonumber(minValue) or 0
    maxValue = tonumber(maxValue) or 0
    if value < minValue then
        return minValue
    end
    if value > maxValue then
        return maxValue
    end
    return value
end

function Tracker:Initialize()
    wipe(KNOWN_SKILL_LINES)
    for _, definition in ipairs(getDefinitions()) do
        KNOWN_SKILL_LINES[definition.skillLine] = definition
    end
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

function Tracker:EnsureWeeklyReset()
    local store = getProfessionStore()
    if not store then
        return
    end

    local resetKey = getWeeklyResetKey()
    if store.weeklyResetKey == resetKey then
        return
    end

    for _, definition in ipairs(getDefinitions()) do
        local professionState = store.professions[definition.key]
        if professionState then
            professionState.values = professionState.values or {}
            for _, source in ipairs(definition.weekly or {}) do
                professionState.values[source.key] = 0
            end
        end
    end

    store.weeklyResetKey = resetKey
end

function Tracker:GetKnownProfessions()
    self:EnsureWeeklyReset()

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
        local order = ns.Data and ns.Data.ProfessionKnowledge and ns.Data.ProfessionKnowledge.order or {}
        local leftIndex = 999
        local rightIndex = 999
        for index, key in ipairs(order) do
            if key == left.key then
                leftIndex = index
            end
            if key == right.key then
                rightIndex = index
            end
        end
        if leftIndex == rightIndex then
            return (left.name or left.key) < (right.name or right.key)
        end
        return leftIndex < rightIndex
    end)

    return results
end

function Tracker:GetProfessionState(professionKey)
    self:EnsureWeeklyReset()

    local store = getProfessionStore()
    if not store or not professionKey then
        return nil
    end

    store.professions[professionKey] = store.professions[professionKey] or {
        values = {},
    }
    store.professions[professionKey].values = store.professions[professionKey].values or {}
    return store.professions[professionKey]
end

function Tracker:GetSourceDefinition(professionKey, sourceKey)
    local definition = self:GetDefinitionByKey(professionKey)
    if not definition then
        return nil
    end

    for _, source in ipairs(definition.weekly or {}) do
        if source.key == sourceKey then
            return source, "weekly"
        end
    end

    for _, source in ipairs(definition.oneTime or {}) do
        if source.key == sourceKey then
            return source, "oneTime"
        end
    end

    return nil
end

function Tracker:GetSourceValue(professionKey, sourceKey)
    local state = self:GetProfessionState(professionKey)
    if not state then
        return 0
    end

    return tonumber(state.values[sourceKey]) or 0
end

function Tracker:SetSourceValue(professionKey, sourceKey, value)
    local state = self:GetProfessionState(professionKey)
    local source = self:GetSourceDefinition(professionKey, sourceKey)
    if not state or not source then
        return nil
    end

    local bounded = clampValue(value, 0, source.max or 0)
    state.values[sourceKey] = bounded
    return bounded, source
end

function Tracker:AdjustSourceValue(professionKey, sourceKey, delta)
    return self:SetSourceValue(professionKey, sourceKey, self:GetSourceValue(professionKey, sourceKey) + (delta or 0))
end

function Tracker:ResetWeeklyForProfession(professionKey)
    local definition = self:GetDefinitionByKey(professionKey)
    local state = self:GetProfessionState(professionKey)
    if not definition or not state then
        return false
    end

    for _, source in ipairs(definition.weekly or {}) do
        state.values[source.key] = 0
    end

    local store = getProfessionStore()
    if store then
        store.weeklyResetKey = getWeeklyResetKey()
    end

    return true
end

function Tracker:GetSectionSummary(professionKey, sectionName)
    local definition = self:GetDefinitionByKey(professionKey)
    if not definition or not definition[sectionName] then
        return 0, 0
    end

    local earned = 0
    local maximum = 0
    for _, source in ipairs(definition[sectionName]) do
        local current = self:GetSourceValue(professionKey, source.key)
        earned = earned + (current * (source.pointsPerStep or 0))
        maximum = maximum + ((source.max or 0) * (source.pointsPerStep or 0))
    end

    return earned, maximum
end

function Tracker:GetProfessionSummary(professionKey)
    local definition = self:GetDefinitionByKey(professionKey)
    if not definition then
        return nil
    end

    local weeklyEarned, weeklyMax = self:GetSectionSummary(professionKey, "weekly")
    local oneTimeEarned, oneTimeMax = self:GetSectionSummary(professionKey, "oneTime")

    return {
        professionKey = professionKey,
        definition = definition,
        weeklyEarned = weeklyEarned,
        weeklyMax = weeklyMax,
        oneTimeEarned = oneTimeEarned,
        oneTimeMax = oneTimeMax,
    }
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
            local current = self:GetSourceValue(professionKey, source.key)
            rows[#rows + 1] = {
                sectionKey = sectionInfo.key,
                key = source.key,
                title = ns.L(source.labelKey),
                note = ns.L(source.noteKey),
                current = current,
                max = source.max or 0,
                earned = current * (source.pointsPerStep or 0),
                maxPoints = (source.max or 0) * (source.pointsPerStep or 0),
            }
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
