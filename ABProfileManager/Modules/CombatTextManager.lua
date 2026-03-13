local _, ns = ...

local CombatTextManager = {}
ns.Modules.CombatTextManager = CombatTextManager

local CVAR_KEYS = {
    enabled = { "enableFloatingCombatText" },
    damage = { "floatingCombatTextCombatDamage_v2", "floatingCombatTextCombatDamage" },
    healing = { "floatingCombatTextCombatHealing_v2", "floatingCombatTextCombatHealing" },
    floatMode = { "floatingCombatTextFloatMode_v2", "floatingCombatTextFloatMode" },
    directionalDamage = {
        "floatingCombatTextCombatDamageDirectionalScale_v2",
        "floatingCombatTextCombatDamageDirectionalScale",
    },
}

CombatTextManager.FLOAT_MODES = {
    up = 1,
    down = 2,
    arc = 3,
}

local function getCVarValue(names)
    if type(GetCVar) ~= "function" then
        return nil, names and names[1] or nil
    end

    for _, name in ipairs(names or {}) do
        local ok, value = pcall(GetCVar, name)
        if ok and value ~= nil and value ~= "" then
            return tostring(value), name
        end
    end

    return nil, names and names[1] or nil
end

local function setCVarValue(names, value)
    if type(SetCVar) ~= "function" then
        return false
    end

    local _, preferredName = getCVarValue(names)
    if not preferredName then
        return false
    end

    return pcall(SetCVar, preferredName, tostring(value))
end

local function toBooleanString(value)
    return value and "1" or "0"
end

local function parseBoolean(value, defaultValue)
    if value == nil then
        return defaultValue and true or false
    end

    local normalized = tostring(value)
    if normalized == "1" or normalized == "true" then
        return true
    end
    if normalized == "0" or normalized == "false" then
        return false
    end

    return defaultValue and true or false
end

function CombatTextManager:NormalizeFloatMode(value)
    local numeric = tonumber(value)
    if numeric ~= self.FLOAT_MODES.up and numeric ~= self.FLOAT_MODES.down and numeric ~= self.FLOAT_MODES.arc then
        numeric = self.FLOAT_MODES.arc
    end

    return numeric
end

function CombatTextManager:ReadCurrentSettings()
    local enabledValue = getCVarValue(CVAR_KEYS.enabled)
    local damageValue = getCVarValue(CVAR_KEYS.damage)
    local healingValue = getCVarValue(CVAR_KEYS.healing)
    local floatModeValue = getCVarValue(CVAR_KEYS.floatMode)
    local directionalValue = getCVarValue(CVAR_KEYS.directionalDamage)

    return {
        enabled = parseBoolean(enabledValue, true),
        damage = parseBoolean(damageValue, true),
        healing = parseBoolean(healingValue, true),
        floatMode = self:NormalizeFloatMode(floatModeValue),
        directionalDamage = tonumber(directionalValue or "1") ~= 0,
    }
end

function CombatTextManager:ApplySettings(settings)
    if type(settings) ~= "table" then
        return false
    end

    local ok = true
    ok = setCVarValue(CVAR_KEYS.enabled, toBooleanString(settings.enabled ~= false)) and ok
    ok = setCVarValue(CVAR_KEYS.damage, toBooleanString(settings.damage ~= false)) and ok
    ok = setCVarValue(CVAR_KEYS.healing, toBooleanString(settings.healing ~= false)) and ok
    ok = setCVarValue(CVAR_KEYS.floatMode, tostring(self:NormalizeFloatMode(settings.floatMode))) and ok
    ok = setCVarValue(CVAR_KEYS.directionalDamage, settings.directionalDamage == false and "0" or "1") and ok
    return ok
end

function CombatTextManager:ApplyConfiguredSettings()
    if not ns.DB or not ns.DB:IsCombatTextManaged() then
        return true
    end

    return self:ApplySettings(ns.DB:GetCombatTextSettings())
end

function CombatTextManager:Initialize()
end
