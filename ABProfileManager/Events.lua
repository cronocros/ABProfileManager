local addonName, ns = ...

local Events = {}
ns.Events = Events

local frame = CreateFrame("Frame")
Events.frame = frame
local PROFESSION_REFRESH_DELAY = 0.05
local PROFESSION_FOLLOWUP_DELAYS = { 0.35, 1.10 }
local professionRefreshPending = false
local professionRefreshForceScan = false
local professionRefreshReason = nil
local professionFollowUpToken = 0

local function refreshGhostsAndRetries()
    ns.Utils.Debug("Refreshing ghost overlays and retry queue")
    ns:SafeCall(ns.Modules.ActionBarApplier, "ReconcilePendingGhosts")
    ns:SafeCall(ns.Modules.ActionBarApplier, "RetryPendingGhosts")
    ns:SafeCall(ns.Modules.GhostManager, "RefreshGhosts")
end

local function refreshStatsOverlay()
    ns:SafeCall(ns.UI.StatsOverlay, "Refresh")
end

local function runProfessionKnowledgeRefresh(forceScan, reason)
    local ok, err = pcall(function()
        if forceScan then
            ns:SafeCall(ns.Modules.ProfessionKnowledgeTracker, "RefreshQuestCache", true)
        else
            ns:SafeCall(ns.Modules.ProfessionKnowledgeTracker, "MarkDirty")
        end

        ns:SafeCall(ns.UI.ProfessionPanel, "Refresh")
        ns:SafeCall(ns.UI.ProfessionKnowledgeOverlay, "Refresh")
    end)

    if not ok then
        if ns.Utils and ns.Utils.Debug then
            ns.Utils.Debug(string.format("Profession refresh failed (%s): %s", tostring(reason or "unknown"), tostring(err)))
        end
        ns:SafeCall(ns.UI.MainWindow, "SetStatus", ns.L("status_profession_refresh_failed"))
    end
end

local function refreshProfessionKnowledgeViews(forceScan, reason)
    if not C_Timer or type(C_Timer.After) ~= "function" then
        runProfessionKnowledgeRefresh(forceScan, reason)
        return
    end

    professionRefreshForceScan = professionRefreshForceScan or (forceScan and true or false)
    professionRefreshReason = reason or professionRefreshReason
    if professionRefreshPending then
        return
    end

    professionRefreshPending = true
    C_Timer.After(PROFESSION_REFRESH_DELAY, function()
        professionRefreshPending = false
        local pendingForceScan = professionRefreshForceScan
        local pendingReason = professionRefreshReason
        professionRefreshForceScan = false
        professionRefreshReason = nil
        runProfessionKnowledgeRefresh(pendingForceScan, pendingReason)
    end)
end

local function scheduleProfessionFollowUpRefresh(reason)
    if not C_Timer or type(C_Timer.After) ~= "function" then
        return
    end

    professionFollowUpToken = professionFollowUpToken + 1
    local token = professionFollowUpToken
    for _, delay in ipairs(PROFESSION_FOLLOWUP_DELAYS) do
        C_Timer.After(delay, function()
            if token ~= professionFollowUpToken then
                return
            end

            runProfessionKnowledgeRefresh(true, string.format("%s:followup", tostring(reason or "unknown")))
        end)
    end
end

local function applyAuctionHouseExpansionFilter()
    if not AuctionHouseFrame or not AuctionHouseFrame:IsVisible() then
        return
    end

    local expLevel = GetExpansionLevel and GetExpansionLevel() or 0

    local sidebar = AuctionHouseFrame.BrowseSidebar
        or (AuctionHouseFrame.BrowseResultsFrame and AuctionHouseFrame.BrowseResultsFrame.Sidebar)
    if not sidebar then
        return
    end

    local scrollBox = sidebar.ScrollBox
    if not scrollBox or type(scrollBox.ForEachFrame) ~= "function" then
        return
    end

    scrollBox:ForEachFrame(function(elementFrame)
        local data = elementFrame and elementFrame.GetElementData and elementFrame:GetElementData()
        if data and data.expansionLevel == expLevel then
            if type(elementFrame.Click) == "function" then
                elementFrame:Click()
            end
        end
    end)
end

local function ensureAuctionHouseFilter()
    if not ns.DB or not ns.DB:IsAuctionHouseFilterEnabled() then
        return
    end

    if not C_Timer or type(C_Timer.After) ~= "function" then
        return
    end

    C_Timer.After(0.2, function()
        pcall(applyAuctionHouseExpansionFilter)
    end)
end

local function ensureMouseMoveSetting()
    if not ns.DB or not ns.DB:IsMouseMoveRestoreEnabled() then
        return
    end

    if type(GetCVarBool) == "function" then
        local ok, enabled = pcall(GetCVarBool, "autoInteract")
        if ok and enabled then
            return
        end
    end

    if type(GetCVar) == "function" then
        local ok, value = pcall(GetCVar, "autoInteract")
        if ok and tostring(value) == "1" then
            return
        end
    end

    if type(SetCVar) == "function" then
        pcall(SetCVar, "autoInteract", "1")
    end
end

local function ensureCombatTextSettings()
    local manager = ns.Modules and ns.Modules.CombatTextManager
    if manager and manager.ApplyConfiguredSettings then
        local ok, applied = pcall(function()
            return manager:ApplyConfiguredSettings()
        end)
        if not ok or applied == false then
            if ns.Utils and ns.Utils.Debug then
                ns.Utils.Debug(string.format("Combat text CVar apply failed: %s", tostring(applied)))
            end
            ns:SafeCall(ns.UI.MainWindow, "SetStatus", ns.L("config_saved_combat_text_apply_failed"))
        elseif manager.QueueReapply and ns.DB and ns.DB:IsCombatTextManaged() then
            manager:QueueReapply({ 0.35, 1.50 })
        end
    end
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
    frame:RegisterEvent("LOOT_CLOSED")
    frame:RegisterEvent("AUCTION_HOUSE_SHOW")
end

function Events:PLAYER_LOGIN()
    ns.State.playerLoggedIn = true
    ns:SafeCall(ns.DB, "SetDebugEnabled", false)
    ns:SafeCall(ns.DB, "RefreshCharacterRecord")
    ensureMouseMoveSetting()
    ensureCombatTextSettings()
    ns:SafeCall(ns.UI.MainWindow, "OnPlayerLogin")
    refreshStatsOverlay()
    runProfessionKnowledgeRefresh(true, "PLAYER_LOGIN")
    ns.Utils.Print(ns.L("loaded_window_hint"))
end

function Events:PLAYER_LOGOUT()
    ns:SafeCall(ns.DB, "SetDebugEnabled", false)
end

function Events:PLAYER_ENTERING_WORLD()
    ns:SafeCall(ns.DB, "RefreshCharacterRecord")
    ensureMouseMoveSetting()
    ensureCombatTextSettings()
    refreshGhostsAndRetries()
    runProfessionKnowledgeRefresh(true, "PLAYER_ENTERING_WORLD")
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
    refreshProfessionKnowledgeViews(true, "PLAYER_SPECIALIZATION_CHANGED")
    ns:RefreshUI()
end

function Events:SKILL_LINES_CHANGED()
    refreshProfessionKnowledgeViews(true, "SKILL_LINES_CHANGED")
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
    refreshProfessionKnowledgeViews(false, "QUEST_LOG_UPDATE")
end

function Events:QUEST_TURNED_IN()
    refreshProfessionKnowledgeViews(true, "QUEST_TURNED_IN")
    scheduleProfessionFollowUpRefresh("QUEST_TURNED_IN")
end

function Events:BAG_UPDATE_DELAYED()
    refreshProfessionKnowledgeViews(true, "BAG_UPDATE_DELAYED")
    scheduleProfessionFollowUpRefresh("BAG_UPDATE_DELAYED")
end

function Events:BAG_NEW_ITEMS_UPDATED()
    refreshProfessionKnowledgeViews(true, "BAG_NEW_ITEMS_UPDATED")
    scheduleProfessionFollowUpRefresh("BAG_NEW_ITEMS_UPDATED")
end

function Events:LOOT_CLOSED()
    refreshProfessionKnowledgeViews(true, "LOOT_CLOSED")
    scheduleProfessionFollowUpRefresh("LOOT_CLOSED")
end

function Events:AUCTION_HOUSE_SHOW()
    ensureAuctionHouseFilter()
end

Events:Initialize()
