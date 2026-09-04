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
local ITEM_LEVEL_OVERLAY_REFRESH_DELAY = 0.15
local itemLevelOverlayRefreshPending = false

local STATS_REFRESH_DELAY = 0.15
local STATS_SLOW_REFRESH_DELAY = 0.45
local statsRefreshPending = false
local statsRefreshDelay = nil
local statsRefreshToken = 0

local QUEST_PANEL_REFRESH_DELAY = 0.15
local questPanelRefreshPending = false

local abpmBankSessionActive = false
local abpmBankPanelHooksInstalled = false

local abpmBankCleanupInProgress = false

local lootSessionActive = false
local lootSessionToken = 0

local function abpmCloseBankSessions()

    if abpmBankCleanupInProgress then return end
    abpmBankCleanupInProgress = true
    if BankFrame and BankFrame:IsShown() then
        pcall(CloseBankFrame)
    end
    if C_Bank and type(C_Bank.CloseBankFrame) == "function" then
        pcall(C_Bank.CloseBankFrame, Enum.BankType.Account)
    end
    if AccountBankPanel and AccountBankPanel.Hide then
        pcall(function() AccountBankPanel:Hide() end)
    end
    abpmBankSessionActive = false
    abpmBankCleanupInProgress = false
end

local function abpmIsAccountBankShown()
    if not AccountBankPanel or type(AccountBankPanel.IsShown) ~= "function" then
        return false
    end

    local ok, shown = pcall(function()
        return AccountBankPanel:IsShown()
    end)
    return ok and shown and true or false
end

local function abpmRefreshBankSessionState()
    if abpmIsAccountBankShown() then
        abpmBankSessionActive = true
    end
end

local function abpmInstallBankPanelHooks()
    if abpmBankPanelHooksInstalled or not AccountBankPanel or type(AccountBankPanel.HookScript) ~= "function" then
        return
    end

    abpmBankPanelHooksInstalled = true
    AccountBankPanel:HookScript("OnShow", function()
        abpmBankSessionActive = true
    end)
    AccountBankPanel:HookScript("OnHide", function()
        if not (BankFrame and BankFrame:IsShown()) then
            abpmBankSessionActive = false
        end
    end)
end

local function refreshGhostsAndRetries()
    ns:SafeCall(ns.Modules.ActionBarApplier, "ReconcilePendingGhosts")
    ns:SafeCall(ns.Modules.ActionBarApplier, "RetryPendingGhosts")
    ns:SafeCall(ns.Modules.GhostManager, "RefreshGhosts")
end

local function _questPanelRefreshCallback()
    questPanelRefreshPending = false
    ns:SafeCall(ns.UI.QuestPanel, "Refresh", true)
end

local function _itemLevelOverlayRefreshCallback()
    itemLevelOverlayRefreshPending = false
    ns:SafeCall(ns.UI.ItemLevelOverlay, "Refresh")
end

local function refreshQuestPanel()
    if questPanelRefreshPending then return end
    questPanelRefreshPending = true
    C_Timer.After(QUEST_PANEL_REFRESH_DELAY, _questPanelRefreshCallback)
end

local statsRefreshForcePending = false

local function _doStatsOverlayRefresh(forceRequested)

    if forceRequested then
        ns:SafeCall(ns.UI.StatsOverlay, "Refresh", { force = true })
    else
        ns:SafeCall(ns.UI.StatsOverlay, "Refresh")
    end
end

local function scheduleStatsOverlayRefresh(delay, force)
    if not ns.DB or not ns.DB:IsStatsOverlayEnabled() then
        return
    end
    delay = delay or STATS_REFRESH_DELAY
    if force then
        statsRefreshForcePending = true
    end
    if statsRefreshPending and statsRefreshDelay and statsRefreshDelay <= delay then
        return
    end

    statsRefreshToken = statsRefreshToken + 1
    local token = statsRefreshToken
    statsRefreshPending = true
    statsRefreshDelay = delay

    if not C_Timer or type(C_Timer.After) ~= "function" then
        if token ~= statsRefreshToken then
            return
        end
        local wantForce = statsRefreshForcePending
        statsRefreshPending = false
        statsRefreshDelay = nil
        statsRefreshForcePending = false
        _doStatsOverlayRefresh(wantForce)
        return
    end

    C_Timer.After(delay, function()
        if token ~= statsRefreshToken then
            return
        end
        local wantForce = statsRefreshForcePending
        statsRefreshPending = false
        statsRefreshDelay = nil
        statsRefreshForcePending = false
        _doStatsOverlayRefresh(wantForce)
    end)
end

local function refreshStatsOverlay()
    scheduleStatsOverlayRefresh(STATS_REFRESH_DELAY, false)
end

local function refreshStatsOverlaySlow()
    scheduleStatsOverlayRefresh(STATS_SLOW_REFRESH_DELAY, false)
end

local function refreshStatsOverlayForce(delay)
    scheduleStatsOverlayRefresh(delay or STATS_REFRESH_DELAY, true)
end

local function refreshItemLevelOverlay()
    if itemLevelOverlayRefreshPending then
        return
    end

    itemLevelOverlayRefreshPending = true
    C_Timer.After(ITEM_LEVEL_OVERLAY_REFRESH_DELAY, _itemLevelOverlayRefreshCallback)
end

local function refreshCharacterContextUI()

    ns:SafeCall(ns.UI.StatsOverlay, "Refresh", { force = true })
    ns:SafeCall(ns.UI.ItemLevelOverlay, "Refresh")
    ns:SafeCall(ns.UI.BISOverlay, "Refresh")
    ns:SafeCall(ns.UI.MythicPlusRecordOverlay, "Refresh")

    local mainWindow = ns.UI and ns.UI.MainWindow
    if mainWindow and mainWindow.frame and mainWindow.frame:IsShown() then
        ns:SafeCall(ns.UI.ProfilePanel, "Refresh")
        ns:SafeCall(ns.UI.ProfessionPanel, "Refresh")
        ns:SafeCall(ns.UI.UtilityPanel, "Refresh")
        ns:SafeCall(ns.UI.MainWindow, "RefreshStatus")
    end

    local configPanel = ns.UI and ns.UI.ConfigPanel
    if configPanel and configPanel.settingsFrame and configPanel.settingsFrame:IsShown() then
        ns:SafeCall(ns.UI.ConfigPanel, "Refresh")
    end
end

local function refreshWorldEntryUI()
    refreshCharacterContextUI()
    ns:SafeCall(ns.UI.MinimapButton, "Refresh")
    ns:SafeCall(ns.UI.SilvermoonMapOverlay, "Refresh")
end

local function professionViewsNeedEagerScan()
    if ns.DB and ns.DB.IsProfessionKnowledgeOverlayEnabled and ns.DB:IsProfessionKnowledgeOverlayEnabled() then
        return true
    end

    local panel = ns.UI and ns.UI.ProfessionPanel
    local frame = panel and panel.frame
    if frame and frame.IsVisible and frame:IsVisible() then
        return true
    end

    return false
end

local function runProfessionKnowledgeRefresh(forceScan, reason)
    local ok, err = pcall(function()
        if forceScan and professionViewsNeedEagerScan() then
            ns:SafeCall(ns.Modules.ProfessionKnowledgeTracker, "RefreshQuestCache", true)
        else
            ns:SafeCall(ns.Modules.ProfessionKnowledgeTracker, "MarkDirty")
        end

        ns:SafeCall(ns.UI.ProfessionPanel, "Refresh")
        ns:SafeCall(ns.UI.ProfessionKnowledgeOverlay, "Refresh")
    end)

    if not ok then
        if ns.Utils and ns.Utils.RecordCaughtError then
            ns.Utils.RecordCaughtError("ProfessionRefresh:" .. tostring(reason or "unknown"), err, 3)
        end
        if ns.Utils and ns.Utils.Debug then
            ns.Utils.Debug(string.format("Profession refresh failed (%s): %s", tostring(reason or "unknown"), tostring(err)))
        end
        ns:SafeCall(ns.UI.MainWindow, "SetStatus", ns.L("status_profession_refresh_failed"))
    end
end

local function _professionRefreshCallback()
    professionRefreshPending = false
    local pendingForceScan = professionRefreshForceScan
    local pendingReason = professionRefreshReason
    professionRefreshForceScan = false
    professionRefreshReason = nil
    runProfessionKnowledgeRefresh(pendingForceScan, pendingReason)
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
    C_Timer.After(PROFESSION_REFRESH_DELAY, _professionRefreshCallback)
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
            if not ok and ns.Utils and ns.Utils.RecordCaughtError then
                ns.Utils.RecordCaughtError("CombatTextApply", applied, 3)
            end
            if ns.Utils and ns.Utils.Debug then
                ns.Utils.Debug(string.format("Combat text CVar apply failed: %s", tostring(applied)))
            end
            ns:SafeCall(ns.UI.MainWindow, "SetStatus", ns.L("config_saved_combat_text_apply_failed"))
        elseif manager.QueueReapply and ns.DB and ns.DB:IsCombatTextManaged() then
            manager:QueueReapply({ 0.35, 1.50 })
        end
    end
end

function ns.ABPM_CanUseWarbandBank()
    if not C_Bank then
        ns.Utils.Print(ns.L("bank_api_missing"))
        return false
    end
    local hasBankType = false
    if type(C_Bank.HasBankType) == "function" then
        local ok, result = pcall(C_Bank.HasBankType, Enum.BankType.Account)
        if ok then hasBankType = result end
    end
    if not hasBankType then
        ns.Utils.Print(ns.L("bank_not_enabled"))
        return false
    end
    local canUse = false
    if type(C_Bank.CanUseBank) == "function" then
        local ok, result = pcall(C_Bank.CanUseBank, Enum.BankType.Account)
        if ok then canUse = result end
    end
    if not canUse then
        ns.Utils.Print(ns.L("bank_unavailable"))
        return false
    end
    return true
end

function ns.ABPM_ResetBankSession()
    abpmCloseBankSessions()
    ns.Utils.Print(ns.L("bank_session_reset"))
end

function Events:Initialize()
    frame:SetScript("OnEvent", function(_, event, ...)
        if type(self[event]) == "function" then
            ns:SafeCall(self, event, ...)
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
    frame:RegisterUnitEvent("UNIT_ATTACK_POWER", "player")
    frame:RegisterUnitEvent("UNIT_STATS", "player")
    frame:RegisterUnitEvent("UNIT_AURA", "player")
    frame:RegisterEvent("QUEST_LOG_UPDATE")
    frame:RegisterEvent("QUEST_TURNED_IN")
    frame:RegisterEvent("BAG_UPDATE_DELAYED")
    frame:RegisterEvent("BAG_NEW_ITEMS_UPDATED")
    frame:RegisterEvent("LOOT_CLOSED")
    frame:RegisterEvent("CURRENCY_DISPLAY_UPDATE")
    frame:RegisterEvent("ACTIVE_DELVE_DATA_UPDATE")
    frame:RegisterEvent("AREA_POIS_UPDATED")

    frame:RegisterEvent("PLAYER_LEAVING_WORLD")
    frame:RegisterEvent("BANKFRAME_OPENED")
    frame:RegisterEvent("BANKFRAME_CLOSED")
    frame:RegisterEvent("UI_ERROR_MESSAGE")

    frame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
    frame:RegisterEvent("PLAYER_ENTER_COMBAT")
    frame:RegisterEvent("PLAYER_LEAVE_COMBAT")

end

function Events:PLAYER_LOGIN()
    ns.State.playerLoggedIn = true
    abpmInstallBankPanelHooks()
    ns:SafeCall(ns.DB, "SetDebugEnabled", false)
    ns:SafeCall(ns.DB, "RefreshCharacterRecord")
    ns:SafeCall(ns.UI.ItemLevelOverlay, "InvalidateBountifulDelveNamesCache")
    ns:SafeCall(ns.Modules.ProfessionKnowledgeTracker, "InvalidateProfessionCache")
    ensureMouseMoveSetting()
    ensureCombatTextSettings()
    ns:SafeCall(ns.UI.MainWindow, "OnPlayerLogin")

    ns:SafeCall(ns.UI.StatsOverlay, "InvalidateState")
    refreshStatsOverlayForce(STATS_REFRESH_DELAY)
    if C_Timer and type(C_Timer.After) == "function" then
        C_Timer.After(1.5, function() refreshStatsOverlayForce(0) end)
    end
    runProfessionKnowledgeRefresh(true, "PLAYER_LOGIN")
    ns:SafeCall(ns.Modules.BlizzardFrameManager, "Apply")
    ns.Utils.Print(ns.L("loaded_window_hint"))
end

function Events:PLAYER_LOGOUT()
    abpmCloseBankSessions()
    ns:SafeCall(ns.DB, "SetDebugEnabled", false)
end

function Events:PLAYER_ENTERING_WORLD()
    abpmInstallBankPanelHooks()
    ns:SafeCall(ns.DB, "RefreshCharacterRecord")
    ns:SafeCall(ns.UI.ItemLevelOverlay, "InvalidateBountifulDelveNamesCache")
    ns:SafeCall(ns.Modules.ProfessionKnowledgeTracker, "InvalidateProfessionCache")
    ensureMouseMoveSetting()
    ensureCombatTextSettings()
    refreshGhostsAndRetries()
    runProfessionKnowledgeRefresh(true, "PLAYER_ENTERING_WORLD")

    ns:SafeCall(ns.UI.StatsOverlay, "InvalidateState")
    refreshStatsOverlayForce(STATS_REFRESH_DELAY)
    if C_Timer and type(C_Timer.After) == "function" then
        C_Timer.After(1.0, function() refreshStatsOverlayForce(0) end)
    end
    refreshWorldEntryUI()
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
    ns:SafeCall(ns.Modules.ProfessionKnowledgeTracker, "InvalidateProfessionCache")
    refreshProfessionKnowledgeViews(true, "PLAYER_SPECIALIZATION_CHANGED")
    refreshCharacterContextUI()
end

function Events:SKILL_LINES_CHANGED()
    ns:SafeCall(ns.Modules.ProfessionKnowledgeTracker, "InvalidateProfessionCache")
    refreshProfessionKnowledgeViews(true, "SKILL_LINES_CHANGED")
    refreshCharacterContextUI()
end

function Events:PLAYER_EQUIPMENT_CHANGED()

    refreshStatsOverlayForce(STATS_REFRESH_DELAY)
    refreshItemLevelOverlay()
end

function Events:COMBAT_RATING_UPDATE()
    refreshStatsOverlaySlow()
end

function Events:MASTERY_UPDATE()
    refreshStatsOverlaySlow()
end

function Events:PLAYER_DAMAGE_DONE_MODS()
    refreshStatsOverlaySlow()
end

function Events:SPELL_POWER_CHANGED()
    refreshStatsOverlaySlow()
end

function Events:UNIT_ATTACK_POWER(unitToken)
    if unitToken ~= "player" then
        return
    end

    refreshStatsOverlaySlow()
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

    refreshStatsOverlaySlow()
end

function Events:QUEST_LOG_UPDATE()
    ns:SafeCall(ns.Modules.QuestManager, "Invalidate")
    refreshQuestPanel()
    refreshProfessionKnowledgeViews(false, "QUEST_LOG_UPDATE")
end

function Events:QUEST_TURNED_IN()
    refreshProfessionKnowledgeViews(true, "QUEST_TURNED_IN")
    scheduleProfessionFollowUpRefresh("QUEST_TURNED_IN")

end

function Events:BAG_UPDATE_DELAYED()
    refreshProfessionKnowledgeViews(true, "BAG_UPDATE_DELAYED")
    if not lootSessionActive then
        scheduleProfessionFollowUpRefresh("BAG_UPDATE_DELAYED")
    end
end

function Events:BAG_NEW_ITEMS_UPDATED()
    refreshProfessionKnowledgeViews(true, "BAG_NEW_ITEMS_UPDATED")
    lootSessionActive = true
    lootSessionToken = lootSessionToken + 1
    local token = lootSessionToken
    scheduleProfessionFollowUpRefresh("BAG_NEW_ITEMS_UPDATED")
    C_Timer.After(1.5, function()
        if token == lootSessionToken then
            lootSessionActive = false
        end
    end)
end

function Events:LOOT_CLOSED()
    refreshProfessionKnowledgeViews(true, "LOOT_CLOSED")
    if not lootSessionActive then
        scheduleProfessionFollowUpRefresh("LOOT_CLOSED")
    end
end

function Events:CURRENCY_DISPLAY_UPDATE()
    refreshItemLevelOverlay()
end

function Events:ACTIVE_DELVE_DATA_UPDATE()
    ns:SafeCall(ns.UI.ItemLevelOverlay, "InvalidateBountifulDelveNamesCache")
    refreshItemLevelOverlay()
end

function Events:AREA_POIS_UPDATED()
    ns:SafeCall(ns.UI.ItemLevelOverlay, "InvalidateBountifulDelveNamesCache")
    refreshItemLevelOverlay()
end

function Events:PLAYER_LEAVING_WORLD()
    abpmCloseBankSessions()
end

function Events:BANKFRAME_OPENED()
    abpmInstallBankPanelHooks()
    abpmBankSessionActive = true
end

function Events:BANKFRAME_CLOSED()

    abpmBankSessionActive = abpmIsAccountBankShown()
end

function Events:UI_ERROR_MESSAGE(messageType, message)
    if not message then return end
    abpmInstallBankPanelHooks()
    abpmRefreshBankSessionState()
    local isBankError = false

    if _G["ERR_BANK_IN_USE"] and message == _G["ERR_BANK_IN_USE"] then
        isBankError = true
    end

    if not isBankError then
        local ok, found = pcall(string.find, string.lower(message), "bank", 1, true)
        if ok and found then isBankError = true end
    end
    if isBankError and (abpmBankSessionActive or abpmIsAccountBankShown()) then
        abpmCloseBankSessions()
        ns.Utils.Print(ns.L("bank_session_closed_external"))
    end
end

function Events:ZONE_CHANGED_NEW_AREA()
    ns:SafeCall(ns.UI.StatsOverlay, "InvalidateState")
    refreshStatsOverlayForce(STATS_REFRESH_DELAY)
end

function Events:PLAYER_ENTER_COMBAT()
    refreshStatsOverlay()
end

function Events:PLAYER_LEAVE_COMBAT()
    refreshStatsOverlay()
end

Events:Initialize()
