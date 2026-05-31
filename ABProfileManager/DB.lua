local _, ns = ...

local DB = {}
ns.DB = DB

local function clampOverlayScale(value)
    local numeric = tonumber(value)
    if not numeric then
        return 1
    end

    return math.max(0.75, math.min(1.35, numeric))
end

local TYPOGRAPHY_BOUNDS = {
    ui = { min = -2, max = 6, default = 0 },
    tooltip = { min = -2, max = 6, default = 0 },
    statsOverlay = { min = -2, max = 6, default = 0 },
    professionOverlay = { min = -3, max = 6, default = 0 },
    mapOverlay = { min = -6, max = 20, default = 0 },
}

local function clampTypographyOffset(domain, value)
    local bounds = TYPOGRAPHY_BOUNDS[domain] or TYPOGRAPHY_BOUNDS.ui
    local numeric = tonumber(value)
    if not numeric then
        return bounds.default
    end

    return math.max(bounds.min, math.min(bounds.max, math.floor(numeric + 0.5)))
end

local function getSpecializationID()
    local specIndex = GetSpecialization and GetSpecialization()
    if not specIndex then
        return 0
    end

    local specID = GetSpecializationInfo(specIndex)
    return specID or 0
end

local function getClientDefaultLanguage()
    local constants = ns.Constants or {}
    local language = constants.LANGUAGE or {}
    local locale = type(GetLocale) == "function" and GetLocale() or nil
    local mapped = constants.CLIENT_LOCALE_LANGUAGE and constants.CLIENT_LOCALE_LANGUAGE[locale]
    return mapped or constants.DEFAULT_FALLBACK_LANGUAGE or language.ENGLISH or "enUS"
end

local function isSupportedLanguage(language)
    local constants = ns.Constants or {}
    local supported = constants.LANGUAGE or {}
    return language == supported.KOREAN or language == supported.ENGLISH
end

local function normalizeLanguage(language)
    if isSupportedLanguage(language) then
        return language
    end

    return getClientDefaultLanguage()
end

local function getLanguageLabelKey(language)
    if language == ns.Constants.LANGUAGE.KOREAN then
        return "config_language_korean"
    end

    return "config_language_english"
end

function DB:Initialize()
    ABPM_DB = ns.Utils.MergeDefaults(ABPM_DB, ns.Data.Defaults)
    ns.db = ABPM_DB
    self:MigrateLanguageSettings()
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
        language = getClientDefaultLanguage(),
        languageUserSelected = false,
        languageMigrationVersion = ns.Constants.LANGUAGE_MIGRATION_VERSION,
            confirmActions = true,
            typography = {
                ui = 0,
                tooltip = 0,
                statsOverlay = 0,
                professionOverlay = 0,
                mapOverlay = 0,
            },
            minimap = {
                hide = false,
                angle = 220,
        },
        statsOverlay = {
            enabled = false,
        },
        professionKnowledgeOverlay = {
            enabled = false,
            tooltips = true,
        },
        silvermoonMapOverlay = {
            enabled = false,
            filters = {
                facilities = true,
                portals = true,
                professions = true,
                renown = true,
                dungeons = true,
                delves = true,
            },
        },
        mouseMoveRestore = {
            enabled = false,
        },
        blizzardFrames = {
            enabled = false,
            layoutVersion = 1,
            movable = {},
            positions = {},
        },
        merchantHelper = {
            enabled = false,
        },
        mailHistory = {
            enabled = true,
        },
        itemLevelOverlay = {
            enabled = false,
        },
        mythicPlusRecordOverlay = {
            enabled = false,
        },
        worldEventOverlay = {
            enabled = false,
        },
    }
    return ns.db.global.settings
end

function DB:GetClientDefaultLanguage()
    return getClientDefaultLanguage()
end

function DB:NormalizeLanguage(language)
    return normalizeLanguage(language)
end

function DB:MigrateLanguageSettings()
    local settings = self:GetGlobalSettings()
    local migrationVersion = ns.Constants.LANGUAGE_MIGRATION_VERSION or 1
    local clientDefault = getClientDefaultLanguage()

    if settings.languageMigrationVersion ~= migrationVersion then
        if settings.language == ns.Constants.LANGUAGE.KOREAN
            and settings.languageUserSelected ~= true
            and clientDefault == ns.Constants.LANGUAGE.ENGLISH then
            settings.language = ns.Constants.LANGUAGE.ENGLISH
        else
            settings.language = normalizeLanguage(settings.language)
        end
        settings.languageMigrationVersion = migrationVersion
    else
        settings.language = normalizeLanguage(settings.language)
    end

    if type(settings.languageUserSelected) ~= "boolean" then
        settings.languageUserSelected = false
    end

    return settings.language
end

function DB:GetLanguage()
    return normalizeLanguage(self:GetGlobalSettings().language)
end

function DB:SetLanguage(language, userSelected)
    language = normalizeLanguage(language)

    local settings = self:GetGlobalSettings()
    settings.language = language
    if userSelected ~= false then
        settings.languageUserSelected = true
    end
    settings.languageMigrationVersion = ns.Constants.LANGUAGE_MIGRATION_VERSION or 1
    return language
end

function DB:GetLanguageLabelKey(language)
    return getLanguageLabelKey(normalizeLanguage(language))
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

function DB:GetTypographySettings()
    local settings = self:GetGlobalSettings()
    settings.typography = settings.typography or {}

    for domain, bounds in pairs(TYPOGRAPHY_BOUNDS) do
        settings.typography[domain] = clampTypographyOffset(domain, settings.typography[domain] or bounds.default)
    end

    return settings.typography
end

function DB:GetTypographyOffset(domain)
    local settings = self:GetTypographySettings()
    domain = TYPOGRAPHY_BOUNDS[domain] and domain or "ui"
    return settings[domain]
end

function DB:SetTypographyOffset(domain, value)
    domain = TYPOGRAPHY_BOUNDS[domain] and domain or "ui"
    self:GetTypographySettings()[domain] = clampTypographyOffset(domain, value)
    return self:GetTypographyOffset(domain)
end

function DB:GetTypographyRange(domain)
    local bounds = TYPOGRAPHY_BOUNDS[domain] or TYPOGRAPHY_BOUNDS.ui
    return bounds.min, bounds.max, bounds.default
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
    settings.statsOverlay = settings.statsOverlay or {}
    local s = settings.statsOverlay
    if s.enabled == nil then s.enabled = false end
    if s.showTankStats == nil then s.showTankStats = true end
    if s.mythicPlusMode == nil then s.mythicPlusMode = false end
    return s
end

function DB:IsStatsOverlayEnabled()
    return self:GetStatsOverlaySettings().enabled and true or false
end

function DB:SetStatsOverlayEnabled(enabled)
    self:GetStatsOverlaySettings().enabled = enabled and true or false
    return self:IsStatsOverlayEnabled()
end

function DB:IsStatsOverlayLocked()
    return self:GetStatsOverlaySettings().locked and true or false
end

function DB:SetStatsOverlayLocked(locked)
    self:GetStatsOverlaySettings().locked = locked and true or false
    return self:IsStatsOverlayLocked()
end

function DB:IsStatsOverlayTankStatsEnabled()
    return self:GetStatsOverlaySettings().showTankStats and true or false
end

function DB:SetStatsOverlayTankStatsEnabled(enabled)
    self:GetStatsOverlaySettings().showTankStats = enabled and true or false
    return self:IsStatsOverlayTankStatsEnabled()
end

function DB:IsStatsOverlayMythicPlusMode()
    return self:GetStatsOverlaySettings().mythicPlusMode and true or false
end

function DB:SetStatsOverlayMythicPlusMode(enabled)
    self:GetStatsOverlaySettings().mythicPlusMode = enabled and true or false
    return self:IsStatsOverlayMythicPlusMode()
end

function DB:GetProfessionKnowledgeOverlaySettings()
    local settings = self:GetGlobalSettings()
    settings.professionKnowledgeOverlay = settings.professionKnowledgeOverlay or {
        enabled = false,
        tooltips = true,
    }
    if type(settings.professionKnowledgeOverlay.tooltips) ~= "boolean" then
        settings.professionKnowledgeOverlay.tooltips = true
    end

    return settings.professionKnowledgeOverlay
end

function DB:IsProfessionKnowledgeOverlayEnabled()
    return self:GetProfessionKnowledgeOverlaySettings().enabled and true or false
end

function DB:SetProfessionKnowledgeOverlayEnabled(enabled)
    self:GetProfessionKnowledgeOverlaySettings().enabled = enabled and true or false
    return self:IsProfessionKnowledgeOverlayEnabled()
end

function DB:IsProfessionKnowledgeOverlayLocked()
    return self:GetProfessionKnowledgeOverlaySettings().locked and true or false
end

function DB:SetProfessionKnowledgeOverlayLocked(locked)
    self:GetProfessionKnowledgeOverlaySettings().locked = locked and true or false
    return self:IsProfessionKnowledgeOverlayLocked()
end

function DB:IsProfessionKnowledgeOverlayTooltipEnabled()
    return self:GetProfessionKnowledgeOverlaySettings().tooltips ~= false
end

function DB:SetProfessionKnowledgeOverlayTooltipEnabled(enabled)
    self:GetProfessionKnowledgeOverlaySettings().tooltips = enabled and true or false
    return self:IsProfessionKnowledgeOverlayTooltipEnabled()
end

function DB:GetSilvermoonMapOverlaySettings()
    local settings = self:GetGlobalSettings()
    settings.silvermoonMapOverlay = settings.silvermoonMapOverlay or {
        enabled = false,
        filters = {
            facilities = true,
            portals = true,
            professions = true,
            renown = true,
            dungeons = true,
            delves = true,
        },
    }
    settings.silvermoonMapOverlay.filters = settings.silvermoonMapOverlay.filters or {
        facilities = true,
        portals = true,
        professions = true,
        renown = true,
        dungeons = true,
        delves = true,
    }

    return settings.silvermoonMapOverlay
end

function DB:IsSilvermoonMapOverlayEnabled()
    return self:GetSilvermoonMapOverlaySettings().enabled and true or false
end

function DB:SetSilvermoonMapOverlayEnabled(enabled)
    self:GetSilvermoonMapOverlaySettings().enabled = enabled and true or false
    return self:IsSilvermoonMapOverlayEnabled()
end

function DB:IsSilvermoonMapCategoryEnabled(filterKey)
    local filters = self:GetSilvermoonMapOverlaySettings().filters
    if type(filters[filterKey]) ~= "boolean" then
        filters[filterKey] = true
    end

    return filters[filterKey]
end

function DB:SetSilvermoonMapCategoryEnabled(filterKey, enabled)
    local filters = self:GetSilvermoonMapOverlaySettings().filters
    filters[filterKey] = enabled and true or false
    return self:IsSilvermoonMapCategoryEnabled(filterKey)
end

function DB:GetMouseMoveRestoreSettings()
    local settings = self:GetGlobalSettings()
    settings.mouseMoveRestore = settings.mouseMoveRestore or {
        enabled = false,
    }

    return settings.mouseMoveRestore
end

function DB:IsMouseMoveRestoreEnabled()
    return self:GetMouseMoveRestoreSettings().enabled and true or false
end

function DB:SetMouseMoveRestoreEnabled(enabled)
    self:GetMouseMoveRestoreSettings().enabled = enabled and true or false
    return self:IsMouseMoveRestoreEnabled()
end

function DB:GetCombatTextSettings()
    local settings = self:GetGlobalSettings()
    settings.combatText = settings.combatText or {
        managed = false,
        enabled = true,
        damage = true,
        healing = true,
        floatMode = 3,
        directionalDamage = true,
        initialized = false,
    }

    local combatText = settings.combatText
    if combatText.initialized ~= true then
        local manager = ns.Modules and ns.Modules.CombatTextManager
        local current = manager and manager.ReadCurrentSettings and manager:ReadCurrentSettings() or nil
        if current then
            combatText.enabled = current.enabled ~= false
            combatText.damage = current.damage ~= false
            combatText.healing = current.healing ~= false
            combatText.floatMode = current.floatMode or combatText.floatMode or 3
            combatText.directionalDamage = current.directionalDamage ~= false
        else
            combatText.enabled = combatText.enabled ~= false
            combatText.damage = combatText.damage ~= false
            combatText.healing = combatText.healing ~= false
            combatText.floatMode = combatText.floatMode or 3
            combatText.directionalDamage = combatText.directionalDamage ~= false
        end
        combatText.managed = combatText.managed and true or false
        combatText.initialized = true
    end

    return combatText
end

function DB:IsCombatTextManaged()
    return self:GetCombatTextSettings().managed and true or false
end

function DB:SetCombatTextManaged(enabled)
    self:GetCombatTextSettings().managed = enabled and true or false
    return self:IsCombatTextManaged()
end

function DB:IsCombatTextEnabled()
    return self:GetCombatTextSettings().enabled ~= false
end

function DB:SetCombatTextEnabled(enabled)
    self:GetCombatTextSettings().enabled = enabled and true or false
    return self:IsCombatTextEnabled()
end

function DB:IsCombatTextDamageEnabled()
    return self:GetCombatTextSettings().damage ~= false
end

function DB:SetCombatTextDamageEnabled(enabled)
    self:GetCombatTextSettings().damage = enabled and true or false
    return self:IsCombatTextDamageEnabled()
end

function DB:IsCombatTextHealingEnabled()
    return self:GetCombatTextSettings().healing ~= false
end

function DB:SetCombatTextHealingEnabled(enabled)
    self:GetCombatTextSettings().healing = enabled and true or false
    return self:IsCombatTextHealingEnabled()
end

function DB:GetCombatTextFloatMode()
    local manager = ns.Modules and ns.Modules.CombatTextManager
    local value = self:GetCombatTextSettings().floatMode
    if manager and manager.NormalizeFloatMode then
        value = manager:NormalizeFloatMode(value)
        self:GetCombatTextSettings().floatMode = value
    end

    return value or 3
end

function DB:SetCombatTextFloatMode(mode)
    local manager = ns.Modules and ns.Modules.CombatTextManager
    local value = mode
    if manager and manager.NormalizeFloatMode then
        value = manager:NormalizeFloatMode(mode)
    end

    self:GetCombatTextSettings().floatMode = value or 3
    return self:GetCombatTextFloatMode()
end

function DB:IsCombatTextDirectionalDamageEnabled()
    return self:GetCombatTextSettings().directionalDamage ~= false
end

function DB:SetCombatTextDirectionalDamageEnabled(enabled)
    self:GetCombatTextSettings().directionalDamage = enabled and true or false
    return self:IsCombatTextDirectionalDamageEnabled()
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
    ns.db.ui.statsOverlay.scale = clampOverlayScale(ns.db.ui.statsOverlay.scale)
    return ns.db.ui.statsOverlay
end

function DB:GetProfessionKnowledgeOverlayConfig()
    if not ns.db then
        return ns.Data.Defaults.ui.professionKnowledgeOverlay
    end

    ns.db.ui = ns.db.ui or {}
    ns.db.ui.professionKnowledgeOverlay =
        ns.db.ui.professionKnowledgeOverlay or ns.Utils.DeepCopy(ns.Data.Defaults.ui.professionKnowledgeOverlay)
    ns.db.ui.professionKnowledgeOverlay.scale = clampOverlayScale(ns.db.ui.professionKnowledgeOverlay.scale)
    return ns.db.ui.professionKnowledgeOverlay
end

function DB:GetStatsOverlayScale()
    return clampOverlayScale(self:GetStatsOverlayConfig().scale)
end

function DB:SetStatsOverlayScale(scale)
    local config = self:GetStatsOverlayConfig()
    config.scale = clampOverlayScale(scale)
    return config.scale
end

function DB:GetProfessionKnowledgeOverlayScale()
    return clampOverlayScale(self:GetProfessionKnowledgeOverlayConfig().scale)
end

function DB:SetProfessionKnowledgeOverlayScale(scale)
    local config = self:GetProfessionKnowledgeOverlayConfig()
    config.scale = clampOverlayScale(scale)
    return config.scale
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

function DB:SaveProfessionKnowledgeOverlayPosition(frame)
    if not frame or not frame.GetPoint then
        return
    end

    local point, _, relativePoint, x, y = frame:GetPoint(1)
    local config = self:GetProfessionKnowledgeOverlayConfig()
    config.point = point or config.point
    config.relativePoint = relativePoint or config.relativePoint
    config.x = x or 0
    config.y = y or 0
end

-- ============================================================
-- BlizzardFrameManager
-- ============================================================

function DB:GetBlizzardFrameSettings()
    local settings = self:GetGlobalSettings()
    settings.blizzardFrames = settings.blizzardFrames or {
        enabled = false,
        layoutVersion = 1,
        movable = {},
        positions = {},
    }
    settings.blizzardFrames.movable = settings.blizzardFrames.movable or {}
    settings.blizzardFrames.positions = settings.blizzardFrames.positions or {}
    if (settings.blizzardFrames.layoutVersion or 0) < 2 then
        settings.blizzardFrames.positions = {}
        settings.blizzardFrames.layoutVersion = 2
    end
    return settings.blizzardFrames
end

function DB:IsBlizzardFrameManagerEnabled()
    return self:GetBlizzardFrameSettings().enabled and true or false
end

function DB:SetBlizzardFrameManagerEnabled(enabled)
    self:GetBlizzardFrameSettings().enabled = enabled and true or false
    return self:IsBlizzardFrameManagerEnabled()
end

function DB:IsBlizzardFrameMovable(key)
    local bfs = self:GetBlizzardFrameSettings()
    if not bfs.enabled then
        return false
    end

    local movable = bfs.movable or {}
    if movable[key] == nil then
        return true  -- 기본적으로 모두 이동 가능
    end

    return movable[key] and true or false
end

function DB:SetBlizzardFrameMovable(key, enabled)
    self:GetBlizzardFrameSettings().movable[key] = enabled and true or false
end

function DB:GetBlizzardFramePosition(key)
    return self:GetBlizzardFrameSettings().positions[key]
end

function DB:SaveBlizzardFramePosition(key, frame)
    if not frame or not frame.GetPoint then
        return
    end

    local ok, point, _, relativePoint, x, y = pcall(function()
        return frame:GetPoint(1)
    end)

    if not ok then
        return
    end

    self:GetBlizzardFrameSettings().positions[key] = {
        point = point or "CENTER",
        relativePoint = relativePoint or "CENTER",
        x = x or 0,
        y = y or 0,
    }
end

function DB:ResetBlizzardFramePosition(key)
    local positions = self:GetBlizzardFrameSettings().positions
    positions[key] = nil
end

function DB:ResetAllBlizzardFramePositions()
    self:GetBlizzardFrameSettings().positions = {}
end

-- ============================================================
-- MerchantHelper
-- ============================================================

function DB:GetMerchantHelperSettings()
    local settings = self:GetGlobalSettings()
    settings.merchantHelper = settings.merchantHelper or { enabled = false }
    return settings.merchantHelper
end

function DB:IsMerchantHelperEnabled()
    return self:GetMerchantHelperSettings().enabled and true or false
end

function DB:SetMerchantHelperEnabled(enabled)
    self:GetMerchantHelperSettings().enabled = enabled and true or false
    return self:IsMerchantHelperEnabled()
end

-- ============================================================
-- MailHistory
-- ============================================================

function DB:GetMailHistorySettings()
    local settings = self:GetGlobalSettings()
    settings.mailHistory = settings.mailHistory or { enabled = true }
    return settings.mailHistory
end

function DB:IsMailHistoryEnabled()
    return self:GetMailHistorySettings().enabled ~= false
end

function DB:SetMailHistoryEnabled(enabled)
    self:GetMailHistorySettings().enabled = enabled and true or false
    return self:IsMailHistoryEnabled()
end

-- ============================================================
-- ItemLevelOverlay
-- ============================================================

function DB:GetItemLevelOverlaySettings()
    local settings = self:GetGlobalSettings()
    settings.itemLevelOverlay = settings.itemLevelOverlay or { enabled = false }
    return settings.itemLevelOverlay
end

function DB:IsItemLevelOverlayEnabled()
    return self:GetItemLevelOverlaySettings().enabled and true or false
end

function DB:SetItemLevelOverlayEnabled(enabled)
    self:GetItemLevelOverlaySettings().enabled = enabled and true or false
    return self:IsItemLevelOverlayEnabled()
end

function DB:IsItemLevelOverlayLocked()
    return self:GetItemLevelOverlaySettings().locked and true or false
end

function DB:SetItemLevelOverlayLocked(locked)
    self:GetItemLevelOverlaySettings().locked = locked and true or false
    return self:IsItemLevelOverlayLocked()
end

function DB:GetItemLevelOverlayConfig()
    if not ns.db then
        return ns.Data.Defaults.ui.itemLevelOverlay
    end

    ns.db.ui = ns.db.ui or {}
    ns.db.ui.itemLevelOverlay = ns.db.ui.itemLevelOverlay
        or ns.Utils.DeepCopy(ns.Data.Defaults.ui.itemLevelOverlay)
    return ns.db.ui.itemLevelOverlay
end

function DB:SaveItemLevelOverlayPosition(frame)
    if not frame or not frame.GetPoint then
        return
    end

    local point, _, relativePoint, x, y = frame:GetPoint(1)
    local config = self:GetItemLevelOverlayConfig()
    config.point = point or config.point
    config.relativePoint = relativePoint or config.relativePoint
    config.x = x or 0
    config.y = y or 0
end

function DB:GetBISOverlayConfig()
    if not ns.db then
        return ns.Data.Defaults.ui.bisOverlay
    end

    ns.db.ui = ns.db.ui or {}
    ns.db.ui.bisOverlay = ns.db.ui.bisOverlay
        or ns.Utils.DeepCopy(ns.Data.Defaults.ui.bisOverlay)
    ns.db.ui.bisOverlay.scale = clampOverlayScale(ns.db.ui.bisOverlay.scale)
    return ns.db.ui.bisOverlay
end

function DB:GetBISOverlayScale()
    return clampOverlayScale(self:GetBISOverlayConfig().scale)
end

function DB:SetBISOverlayScale(scale)
    local config = self:GetBISOverlayConfig()
    config.scale = clampOverlayScale(scale)
    return config.scale
end

function DB:SaveBISOverlayPosition(frame)
    if not frame or not frame.GetPoint then
        return
    end

    local point, _, relativePoint, x, y = frame:GetPoint(1)
    local config = self:GetBISOverlayConfig()
    config.point = point or config.point
    config.relativePoint = relativePoint or config.relativePoint
    config.x = x or 0
    config.y = y or 0
end

-- ============================================================
-- WorldEventOverlay
-- ============================================================

function DB:GetWorldEventOverlaySettings()
    local settings = self:GetGlobalSettings()
    settings.worldEventOverlay = settings.worldEventOverlay or { enabled = false }
    return settings.worldEventOverlay
end

function DB:IsWorldEventOverlayEnabled()
    return self:GetWorldEventOverlaySettings().enabled and true or false
end

function DB:SetWorldEventOverlayEnabled(enabled)
    self:GetWorldEventOverlaySettings().enabled = enabled and true or false
    return self:IsWorldEventOverlayEnabled()
end

function DB:GetWorldEventOverlayConfig()
    if not ns.db then
        return ns.Data.Defaults.ui.worldEventOverlay
    end

    ns.db.ui = ns.db.ui or {}
    ns.db.ui.worldEventOverlay = ns.db.ui.worldEventOverlay
        or ns.Utils.DeepCopy(ns.Data.Defaults.ui.worldEventOverlay)
    return ns.db.ui.worldEventOverlay
end

function DB:SaveWorldEventOverlayPosition(frame)
    if not frame or not frame.GetPoint then
        return
    end

    local point, _, relativePoint, x, y = frame:GetPoint(1)
    local config = self:GetWorldEventOverlayConfig()
    config.point = point or config.point
    config.relativePoint = relativePoint or config.relativePoint
    config.x = x or 0
    config.y = y or 0
end

function DB:GetWorldEventCompletions()
    local settings = self:GetGlobalSettings()
    settings.worldEventCompletions = settings.worldEventCompletions or {}
    return settings.worldEventCompletions
end

function DB:IsWorldEventCompleted(eventKey)
    if not eventKey then return false end
    local dateStr = date and date("%Y-%m-%d") or "unknown"
    return self:GetWorldEventCompletions()[eventKey.."_"..dateStr] == true
end

function DB:SetWorldEventCompleted(eventKey, completed)
    if not eventKey then return end
    local dateStr = date and date("%Y-%m-%d") or "unknown"
    local key = eventKey.."_"..dateStr
    self:GetWorldEventCompletions()[key] = completed or nil
end

-- ============================================================
-- BISOverlay
-- ============================================================

function DB:GetBISOverlaySettings()
    local settings = self:GetGlobalSettings()
    settings.bisOverlay = settings.bisOverlay or { enabled = false }
    settings.bisOverlay.sources = settings.bisOverlay.sources or {
        mythicplus = true,
        raid = true,
        crafted = true,
        tier = true,
    }
    if settings.bisOverlay._allSourcesMigrationV1 ~= true then
        local sources = settings.bisOverlay.sources
        if sources
            and sources.mythicplus == true
            and sources.raid == false
            and sources.crafted == false then
            sources.raid = true
            sources.crafted = true
        end
        settings.bisOverlay._allSourcesMigrationV1 = true
    end
    if settings.bisOverlay._allSourcesMigrationV2 ~= true then
        local sources = settings.bisOverlay.sources
        if type(sources.tier) ~= "boolean" then
            sources.tier = true
        end
        settings.bisOverlay._allSourcesMigrationV2 = true
    end
    if type(settings.bisOverlay.itemTooltip) ~= "boolean" then
        settings.bisOverlay.itemTooltip = false
    end
    return settings.bisOverlay
end

function DB:IsBISOverlayEnabled()
    return self:GetBISOverlaySettings().enabled and true or false
end

function DB:SetBISOverlayEnabled(enabled)
    self:GetBISOverlaySettings().enabled = enabled and true or false
    return self:IsBISOverlayEnabled()
end

function DB:IsBISOverlayLocked()
    return self:GetBISOverlaySettings().locked and true or false
end

function DB:SetBISOverlayLocked(locked)
    self:GetBISOverlaySettings().locked = locked and true or false
    return self:IsBISOverlayLocked()
end

function DB:IsBISOverlayItemTooltipEnabled()
    return self:GetBISOverlaySettings().itemTooltip == true
end

function DB:SetBISOverlayItemTooltipEnabled(enabled)
    self:GetBISOverlaySettings().itemTooltip = enabled and true or false
    return self:IsBISOverlayItemTooltipEnabled()
end

local function normalizeBISOverlayItemKey(itemID)
    local numeric = tonumber(itemID)
    if not numeric or numeric <= 0 then
        return nil
    end
    return tostring(math.floor(numeric))
end

local function normalizeBISOverlaySpecKey(specID)
    local numeric = tonumber(specID)
    if not numeric or numeric <= 0 then
        return nil
    end
    return tostring(math.floor(numeric))
end

function DB:GetBISOverlayCharacterState()
    local record = self:GetCharacterRecord()
    if not record then
        return nil
    end

    record.bisOverlay = record.bisOverlay or {}
    record.bisOverlay.itemsBySpec = record.bisOverlay.itemsBySpec or {}
    record.bisOverlay.stateVersionBySpec = record.bisOverlay.stateVersionBySpec or {}
    return record.bisOverlay
end

function DB:GetBISOverlaySpecItems(specID)
    local state = self:GetBISOverlayCharacterState()
    local specKey = normalizeBISOverlaySpecKey(specID)
    if not state or not specKey then
        return nil
    end

    state.itemsBySpec[specKey] = state.itemsBySpec[specKey] or {}
    return state.itemsBySpec[specKey], specKey, state
end

function DB:GetBISOverlayItemState(specID, itemID)
    local items = self:GetBISOverlaySpecItems(specID)
    local itemKey = normalizeBISOverlayItemKey(itemID)
    return items and itemKey and items[itemKey] or nil
end

function DB:GetBISOverlayItemStateVersion(specID)
    local state = self:GetBISOverlayCharacterState()
    local specKey = normalizeBISOverlaySpecKey(specID)
    return state and specKey and tonumber(state.stateVersionBySpec[specKey]) or 0
end

function DB:SetBISOverlayItemState(specID, itemID, field, enabled)
    if field ~= "owned" and field ~= "favorite" then
        return false
    end

    local items, specKey, state = self:GetBISOverlaySpecItems(specID)
    local itemKey = normalizeBISOverlayItemKey(itemID)
    if not items or not itemKey then
        return false
    end

    local itemState = items[itemKey] or {}
    itemState[field] = enabled and true or nil
    if itemState.owned or itemState.favorite then
        items[itemKey] = itemState
    else
        items[itemKey] = nil
    end
    state.stateVersionBySpec[specKey] = (tonumber(state.stateVersionBySpec[specKey]) or 0) + 1
    return enabled and true or false
end

function DB:IsBISOverlayItemOwned(specID, itemID)
    local state = self:GetBISOverlayItemState(specID, itemID)
    return state and state.owned == true or false
end

function DB:GetBISOverlayOwnedItemLink(specID, itemID)
    local state = self:GetBISOverlayItemState(specID, itemID)
    return state and state.ownedItemLink or nil
end

function DB:SetBISOverlayItemOwned(specID, itemID, enabled, itemLink)
    local owned = self:SetBISOverlayItemState(specID, itemID, "owned", enabled)
    local state = self:GetBISOverlayItemState(specID, itemID)
    if state then
        if not owned then
            state.ownedItemLink = nil
        elseif type(itemLink) == "string" and itemLink ~= "" then
            state.ownedItemLink = itemLink
        end
    end
    return owned
end

function DB:IsBISOverlayItemFavorite(specID, itemID)
    local state = self:GetBISOverlayItemState(specID, itemID)
    return state and state.favorite == true or false
end

function DB:SetBISOverlayItemFavorite(specID, itemID, enabled)
    return self:SetBISOverlayItemState(specID, itemID, "favorite", enabled)
end

-- ============================================================
-- MythicPlusRecordOverlay
-- ============================================================

function DB:GetMythicPlusRecordOverlaySettings()
    local settings = self:GetGlobalSettings()
    settings.mythicPlusRecordOverlay = settings.mythicPlusRecordOverlay or { enabled = false }
    return settings.mythicPlusRecordOverlay
end

function DB:IsMythicPlusRecordOverlayEnabled()
    return self:GetMythicPlusRecordOverlaySettings().enabled and true or false
end

function DB:SetMythicPlusRecordOverlayEnabled(enabled)
    self:GetMythicPlusRecordOverlaySettings().enabled = enabled and true or false
    return self:IsMythicPlusRecordOverlayEnabled()
end
