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

-- UNIT_AURA / UNIT_STATS / COMBAT_RATING_UPDATE 등 고주기 이벤트 디바운싱
-- 0.15초 내 중복 발화를 하나로 합침
local STATS_REFRESH_DELAY = 0.15
local statsRefreshPending = false

-- QUEST_LOG_UPDATE 디바운싱: 퀘스트 진행 중 고빈도 발화를 하나로 합침
-- QuestManager:Scan 은 퀘스트당 5+ WoW API 호출 → 디바운스 없이 초당 수백 번 호출 가능
local QUEST_PANEL_REFRESH_DELAY = 0.15
local questPanelRefreshPending = false

local function refreshGhostsAndRetries()
    ns:SafeCall(ns.Modules.ActionBarApplier, "ReconcilePendingGhosts")
    ns:SafeCall(ns.Modules.ActionBarApplier, "RetryPendingGhosts")
    ns:SafeCall(ns.Modules.GhostManager, "RefreshGhosts")
end

-- 디바운스 콜백 사전 생성: 매 이벤트마다 클로저 생성 방지 (GC 압력 감소)
local function _questPanelRefreshCallback()
    questPanelRefreshPending = false
    ns:SafeCall(ns.UI.QuestPanel, "Refresh", true)
end

local function _statsRefreshCallback()
    statsRefreshPending = false
    ns:SafeCall(ns.UI.StatsOverlay, "Refresh")
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

local function refreshStatsOverlay()
    if not ns.DB or not ns.DB:IsStatsOverlayEnabled() then
        return
    end
    if statsRefreshPending then return end
    statsRefreshPending = true
    C_Timer.After(STATS_REFRESH_DELAY, _statsRefreshCallback)
end

local function refreshItemLevelOverlay()
    if itemLevelOverlayRefreshPending then
        return
    end

    itemLevelOverlayRefreshPending = true
    C_Timer.After(ITEM_LEVEL_OVERLAY_REFRESH_DELAY, _itemLevelOverlayRefreshCallback)
end

local function refreshCharacterContextUI()
    ns:SafeCall(ns.UI.StatsOverlay, "Refresh")
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
    frame:RegisterEvent("CURRENCY_DISPLAY_UPDATE")
    frame:RegisterEvent("ACTIVE_DELVE_DATA_UPDATE")
    frame:RegisterEvent("AREA_POIS_UPDATED")
    -- [비활성] MerchantHelper: 도안 감지 미동작 (Midnight API 미확인)
    -- frame:RegisterEvent("MERCHANT_SHOW")
    -- frame:RegisterEvent("MERCHANT_UPDATE")
    -- [비활성] MailHistory: 우편 자동완성 미구현
    -- frame:RegisterEvent("MAIL_SEND_SUCCESS")
end

function Events:PLAYER_LOGIN()
    ns.State.playerLoggedIn = true
    ns:SafeCall(ns.DB, "SetDebugEnabled", false)
    ns:SafeCall(ns.DB, "RefreshCharacterRecord")
    ns:SafeCall(ns.UI.ItemLevelOverlay, "InvalidateBountifulDelveNamesCache")
    ns:SafeCall(ns.Modules.ProfessionKnowledgeTracker, "InvalidateProfessionCache")
    ensureMouseMoveSetting()
    ensureCombatTextSettings()
    ns:SafeCall(ns.UI.MainWindow, "OnPlayerLogin")
    refreshStatsOverlay()
    runProfessionKnowledgeRefresh(true, "PLAYER_LOGIN")
    ns:SafeCall(ns.Modules.BlizzardFrameManager, "Apply")
    ns.Utils.Print(ns.L("loaded_window_hint"))
end

function Events:PLAYER_LOGOUT()
    ns:SafeCall(ns.DB, "SetDebugEnabled", false)
end

function Events:PLAYER_ENTERING_WORLD()
    ns:SafeCall(ns.DB, "RefreshCharacterRecord")
    ns:SafeCall(ns.UI.ItemLevelOverlay, "InvalidateBountifulDelveNamesCache")
    ns:SafeCall(ns.Modules.ProfessionKnowledgeTracker, "InvalidateProfessionCache")
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
    refreshStatsOverlay()
    refreshItemLevelOverlay()
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
    refreshQuestPanel()  -- 디바운스: 고빈도 발화 시 0.15s 내 1회로 합산
    refreshProfessionKnowledgeViews(false, "QUEST_LOG_UPDATE")
end

function Events:QUEST_TURNED_IN()
    refreshProfessionKnowledgeViews(true, "QUEST_TURNED_IN")
    scheduleProfessionFollowUpRefresh("QUEST_TURNED_IN")
    -- [비활성] WorldEventOverlay 자동감지: 퀘스트 기반 완료 감지 미동작
    -- ns:SafeCall(ns.UI.WorldEventOverlay, "OnQuestTurnedIn")
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

-- [비활성] MerchantHelper: 도안 감지 미동작 (Midnight spellID API 부정확)
-- function Events:MERCHANT_SHOW()
--     ns:SafeCall(ns.Modules.MerchantHelper, "ScanAndMark")
-- end
--
-- function Events:MERCHANT_UPDATE()
--     ns:SafeCall(ns.Modules.MerchantHelper, "ScanAndMark")
-- end

-- [비활성] MailHistory: 우편 자동완성 미구현
-- function Events:MAIL_SEND_SUCCESS()
--     if not ns.DB or not ns.DB:IsMailHistoryEnabled() then
--         return
--     end
--
--     local recipientName = nil
--     if SendMailNameEditBox then
--         local ok, name = pcall(function() return SendMailNameEditBox:GetText() end)
--         if ok then
--             recipientName = name
--         end
--     end
--
--     if recipientName and recipientName ~= "" then
--         ns:SafeCall(ns.Modules.MailHistory, "RecordSend", recipientName)
--     end
-- end

Events:Initialize()
