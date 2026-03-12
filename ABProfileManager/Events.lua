local addonName, ns = ...

local Events = {}
ns.Events = Events

local frame = CreateFrame("Frame")
Events.frame = frame

local function refreshGhostsAndRetries()
    ns.Utils.Debug("Refreshing ghost overlays and retry queue")
    ns:SafeCall(ns.Modules.ActionBarApplier, "ReconcilePendingGhosts")
    ns:SafeCall(ns.Modules.ActionBarApplier, "RetryPendingGhosts")
    ns:SafeCall(ns.Modules.GhostManager, "RefreshGhosts")
end

local function refreshStatsOverlay()
    ns:SafeCall(ns.UI.StatsOverlay, "Refresh")
end

local function refreshProfessionKnowledgeViews(forceScan)
    if forceScan then
        ns:SafeCall(ns.Modules.ProfessionKnowledgeTracker, "RefreshQuestCache", true)
    else
        ns:SafeCall(ns.Modules.ProfessionKnowledgeTracker, "MarkDirty")
    end

    ns:SafeCall(ns.UI.ProfessionPanel, "Refresh")
    ns:SafeCall(ns.UI.ProfessionKnowledgeOverlay, "Refresh")
end

function Events:Initialize()
    frame:SetScript("OnEvent", function(_, event, ...)
        if type(self[event]) == "function" then
            self[event](self, ...)
        end
    end)

    frame:RegisterEvent("ADDON_LOADED")
end

function Events:ADDON_LOADED(loadedAddonName)
    if loadedAddonName ~= addonName then
        return
    end

    ns.State.addonLoaded = true

    ns:SafeCall(ns.DB, "Initialize")
    ns:InitializeStartupModules()

    frame:UnregisterEvent("ADDON_LOADED")
    frame:RegisterEvent("PLAYER_LOGIN")
    frame:RegisterEvent("PLAYER_ENTERING_WORLD")
    frame:RegisterEvent("PLAYER_LOGOUT")
    frame:RegisterEvent("SPELLS_CHANGED")
    frame:RegisterEvent("ACTIONBAR_SLOT_CHANGED")
    frame:RegisterEvent("ACTIONBAR_PAGE_CHANGED")
    frame:RegisterEvent("UPDATE_BONUS_ACTIONBAR")
    frame:RegisterEvent("PLAYER_REGEN_DISABLED")
    frame:RegisterEvent("PLAYER_REGEN_ENABLED")
    frame:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
    frame:RegisterEvent("SKILL_LINES_CHANGED")
    frame:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
    frame:RegisterEvent("COMBAT_RATING_UPDATE")
    frame:RegisterEvent("MASTERY_UPDATE")
    frame:RegisterEvent("PLAYER_DAMAGE_DONE_MODS")
    frame:RegisterEvent("SPELL_POWER_CHANGED")
    frame:RegisterEvent("UNIT_ATTACK_POWER")
    frame:RegisterEvent("UNIT_STATS")
    frame:RegisterEvent("UNIT_AURA")
    frame:RegisterEvent("QUEST_LOG_UPDATE")
    frame:RegisterEvent("QUEST_TURNED_IN")
    frame:RegisterEvent("BAG_UPDATE_DELAYED")
    frame:RegisterEvent("BAG_NEW_ITEMS_UPDATED")
end

function Events:PLAYER_LOGIN()
    ns.State.playerLoggedIn = true
    ns:SafeCall(ns.DB, "SetDebugEnabled", false)
    ns:SafeCall(ns.DB, "RefreshCharacterRecord")
    ns:SafeCall(ns.UI.MainWindow, "OnPlayerLogin")
    refreshStatsOverlay()
    refreshProfessionKnowledgeViews(true)
    ns.Utils.Print(ns.L("loaded_window_hint"))
end

function Events:PLAYER_LOGOUT()
    ns:SafeCall(ns.DB, "SetDebugEnabled", false)
end

function Events:PLAYER_ENTERING_WORLD()
    ns:SafeCall(ns.DB, "RefreshCharacterRecord")
    refreshGhostsAndRetries()
    refreshProfessionKnowledgeViews(true)
    ns:RefreshUI()
end

function Events:SPELLS_CHANGED()
    refreshGhostsAndRetries()
    refreshStatsOverlay()
end

function Events:ACTIONBAR_SLOT_CHANGED()
    refreshGhostsAndRetries()
end

function Events:ACTIONBAR_PAGE_CHANGED()
    refreshGhostsAndRetries()
end

function Events:UPDATE_BONUS_ACTIONBAR()
    refreshGhostsAndRetries()
end

function Events:PLAYER_REGEN_DISABLED()
    ns:SafeCall(ns.UI.MainWindow, "SetStatus", ns.L("combat_lockdown_active"))
end

function Events:PLAYER_REGEN_ENABLED()
    ns:SafeCall(ns.Modules.ActionBarApplier, "FlushQueue")
    refreshGhostsAndRetries()
end

function Events:PLAYER_SPECIALIZATION_CHANGED()
    ns:SafeCall(ns.DB, "RefreshCharacterRecord")
    refreshProfessionKnowledgeViews(true)
    ns:RefreshUI()
end

function Events:SKILL_LINES_CHANGED()
    refreshProfessionKnowledgeViews(true)
    ns:RefreshUI()
end

function Events:PLAYER_EQUIPMENT_CHANGED()
    refreshStatsOverlay()
end

function Events:COMBAT_RATING_UPDATE()
    refreshStatsOverlay()
end

function Events:MASTERY_UPDATE()
    refreshStatsOverlay()
end

function Events:PLAYER_DAMAGE_DONE_MODS()
    refreshStatsOverlay()
end

function Events:SPELL_POWER_CHANGED()
    refreshStatsOverlay()
end

function Events:UNIT_ATTACK_POWER(unitToken)
    if unitToken ~= "player" then
        return
    end

    refreshStatsOverlay()
end

function Events:UNIT_AURA(unitToken)
    if unitToken ~= "player" then
        return
    end

    refreshStatsOverlay()
end

function Events:UNIT_STATS(unitToken)
    if unitToken ~= "player" then
        return
    end

    refreshStatsOverlay()
end

function Events:QUEST_LOG_UPDATE()
    ns:SafeCall(ns.Modules.QuestManager, "Invalidate")
    ns:SafeCall(ns.UI.QuestPanel, "Refresh", true)
    refreshProfessionKnowledgeViews(false)
end

function Events:QUEST_TURNED_IN()
    refreshProfessionKnowledgeViews(true)
end

function Events:BAG_UPDATE_DELAYED()
    refreshProfessionKnowledgeViews(false)
end

function Events:BAG_NEW_ITEMS_UPDATED()
    refreshProfessionKnowledgeViews(false)
end

Events:Initialize()
