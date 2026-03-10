local _, ns = ...

local DB = {}
ns.DB = DB

local function getSpecializationID()
    local specIndex = GetSpecialization and GetSpecialization()
    if not specIndex then
        return 0
    end

    local specID = GetSpecializationInfo(specIndex)
    return specID or 0
end

function DB:Initialize()
    ABPM_DB = ns.Utils.MergeDefaults(ABPM_DB, ns.Data.Defaults)
    ns.db = ABPM_DB
    if ns.db and ns.db.ui and ns.db.ui.mainWindow then
        ns.db.ui.mainWindow.width = math.max(ns.db.ui.mainWindow.width or 0, ns.Constants.WINDOW_WIDTH)
        ns.db.ui.mainWindow.height = math.max(ns.db.ui.mainWindow.height or 0, ns.Constants.WINDOW_HEIGHT)
    end
    ns.State.debugEnabled = false
end

function DB:GetCharacterKey()
    local characterName = UnitName and UnitName("player") or "Unknown"
    local realmName = GetRealmName and GetRealmName() or "UnknownRealm"

    return string.format("%s-%s", realmName, characterName)
end

function DB:EnsureCharacterRecord(characterKey)
    if not ns.db then
        return nil
    end

    characterKey = characterKey or self:GetCharacterKey()
    ns.db.characters[characterKey] = ns.db.characters[characterKey] or {
        class = "UNKNOWN",
        specID = 0,
        meta = {},
    }

    local record = ns.db.characters[characterKey]
    record.meta = record.meta or {}
    return record
end

function DB:GetCharacterRecord()
    return self:EnsureCharacterRecord(self:GetCharacterKey())
end

function DB:RefreshCharacterRecord()
    local record = self:GetCharacterRecord()
    if not record then
        return nil
    end

    local _, classTag = UnitClass("player")
    record.class = classTag or record.class
    record.specID = getSpecializationID()
    record.meta.lastSeen = date("%Y-%m-%d %H:%M:%S")

    return record
end

function DB:GetTemplates()
    if not ns.db then
        return {}
    end

    ns.db.global.templates = ns.db.global.templates or {}
    return ns.db and ns.db.global.templates or {}
end

function DB:GetGlobalSettings()
    if not ns.db then
        return ns.Data.Defaults.global.settings
    end

    ns.db.global.settings = ns.db.global.settings or {
        language = ns.Constants.LANGUAGE.KOREAN,
        confirmActions = true,
        minimap = {
            hide = false,
            angle = 220,
        },
        statsOverlay = {
            enabled = false,
        },
    }
    return ns.db.global.settings
end

function DB:GetLanguage()
    return self:GetGlobalSettings().language or ns.Constants.LANGUAGE.KOREAN
end

function DB:SetLanguage(language)
    if language ~= ns.Constants.LANGUAGE.KOREAN and language ~= ns.Constants.LANGUAGE.ENGLISH then
        language = ns.Constants.LANGUAGE.KOREAN
    end

    self:GetGlobalSettings().language = language
    return language
end

function DB:IsDebugEnabled()
    return ns.State.debugEnabled and true or false
end

function DB:SetDebugEnabled(enabled)
    ns.State.debugEnabled = enabled and true or false
    return self:IsDebugEnabled()
end

function DB:ShouldConfirmActions()
    return self:GetGlobalSettings().confirmActions ~= false
end

function DB:SetConfirmActions(enabled)
    self:GetGlobalSettings().confirmActions = enabled and true or false
    return self:ShouldConfirmActions()
end

function DB:GetMinimapConfig()
    local settings = self:GetGlobalSettings()
    settings.minimap = settings.minimap or {
        hide = false,
        angle = 220,
    }

    return settings.minimap
end

function DB:SetMinimapHidden(hidden)
    self:GetMinimapConfig().hide = hidden and true or false
    return self:GetMinimapConfig().hide
end

function DB:SetMinimapAngle(angle)
    self:GetMinimapConfig().angle = angle
    return angle
end

function DB:GetStatsOverlaySettings()
    local settings = self:GetGlobalSettings()
    settings.statsOverlay = settings.statsOverlay or {
        enabled = false,
    }

    return settings.statsOverlay
end

function DB:IsStatsOverlayEnabled()
    return self:GetStatsOverlaySettings().enabled and true or false
end

function DB:SetStatsOverlayEnabled(enabled)
    self:GetStatsOverlaySettings().enabled = enabled and true or false
    return self:IsStatsOverlayEnabled()
end

function DB:GetTemplate(templateName)
    templateName = ns.Utils.SanitizeSingleLine(templateName or "")
    if not templateName or templateName == "" then
        return nil
    end

    return self:GetTemplates()[templateName]
end

function DB:SetTemplate(templateName, snapshot)
    templateName = ns.Utils.SanitizeSingleLine(templateName or "")
    if not templateName or templateName == "" then
        return nil, ns.L("error_template_name_required")
    end

    self:GetTemplates()[templateName] = snapshot
    return snapshot
end

function DB:HasTemplate(templateName)
    return self:GetTemplate(templateName) ~= nil
end

function DB:DeleteTemplate(templateName)
    templateName = ns.Utils.SanitizeSingleLine(templateName or "")
    if not self:GetTemplate(templateName) then
        return nil, ns.L("error_delete_template_not_found", templateName or "unknown")
    end

    self:GetTemplates()[templateName] = nil
    return true
end

function DB:GetMainWindowConfig()
    return ns.db and ns.db.ui and ns.db.ui.mainWindow or ns.Data.Defaults.ui.mainWindow
end

function DB:GetStatsOverlayConfig()
    if not ns.db then
        return ns.Data.Defaults.ui.statsOverlay
    end

    ns.db.ui = ns.db.ui or {}
    ns.db.ui.statsOverlay = ns.db.ui.statsOverlay or ns.Utils.DeepCopy(ns.Data.Defaults.ui.statsOverlay)
    return ns.db.ui.statsOverlay
end

function DB:SaveMainWindowPosition(frame)
    if not frame or not frame.GetPoint then
        return
    end

    local point, _, relativePoint, x, y = frame:GetPoint(1)
    local config = self:GetMainWindowConfig()
    config.point = point or config.point
    config.relativePoint = relativePoint or config.relativePoint
    config.x = x or 0
    config.y = y or 0
    config.width = frame:GetWidth() or config.width
    config.height = frame:GetHeight() or config.height
end

function DB:SaveStatsOverlayPosition(frame)
    if not frame or not frame.GetPoint then
        return
    end

    local point, _, relativePoint, x, y = frame:GetPoint(1)
    local config = self:GetStatsOverlayConfig()
    config.point = point or config.point
    config.relativePoint = relativePoint or config.relativePoint
    config.x = x or 0
    config.y = y or 0
end
