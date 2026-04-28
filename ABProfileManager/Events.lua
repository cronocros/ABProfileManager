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
-- 빠른 갱신(장비/주문 변화)과 느린 갱신(오라/전투수치 변화)을 분리한다.
local STATS_REFRESH_DELAY = 0.15
local STATS_SLOW_REFRESH_DELAY = 0.45
local statsRefreshPending = false
local statsRefreshDelay = nil
local statsRefreshToken = 0

-- QUEST_LOG_UPDATE 디바운싱: 퀘스트 진행 중 고빈도 발화를 하나로 합침
-- QuestManager:Scan 은 퀘스트당 5+ WoW API 호출 → 디바운스 없이 초당 수백 번 호출 가능
local QUEST_PANEL_REFRESH_DELAY = 0.15
local questPanelRefreshPending = false

-- 전투부대 은행 세션 상태 추적
local abpmBankSessionActive = false
-- CloseBankFrame → BANKFRAME_CLOSED → abpmCloseBankSessions 재귀 방지 플래그
local abpmBankCleanupInProgress = false

-- 루팅 세션 중 BAG/LOOT 이벤트 동시 발화에 의한 중복 followup 방지
-- token 패턴: 연속 루팅(1.5초 이내 다수 아이템 획득) 시 타이머 누적 방지
local lootSessionActive = false
local lootSessionToken = 0

local function abpmCloseBankSessions()
    -- 재진입 방지: CloseBankFrame 호출이 BANKFRAME_CLOSED를 재발화하여 무한 재귀를 일으킬 수 있음
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
    -- WoW 12.0.5 인던 진입 / 특성 변경 / 장비 교체 등 critical 시점에는
    -- 캐시된 lastStateSignature 가 stale 한 0 값이거나 동일 hash 일 수 있어
    -- force=true 로 강제 갱신해야 0 표시 / 트링킷 발동 미반영 문제를 막을 수 있다.
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
    -- 컨텍스트 변경(존 이동/특성 변경/장비 변경) 시 stats overlay 캐시 무효화
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

-- 전투부대 은행 사용 가능 여부 사전 점검 (외부 모듈/명령어에서 호출)
-- 반환: true = 사용 가능, false = 불가 (채팅 안내 출력)
function ns.ABPM_CanUseWarbandBank()
    if not C_Bank then
        ns.Utils.Print("[ABPM] 전투부대 은행 API(C_Bank)를 찾을 수 없습니다.")
        return false
    end
    local hasBankType = false
    if type(C_Bank.HasBankType) == "function" then
        local ok, result = pcall(C_Bank.HasBankType, Enum.BankType.Account)
        if ok then hasBankType = result end
    end
    if not hasBankType then
        ns.Utils.Print("[ABPM] 전투부대 은행이 활성화되어 있지 않습니다.")
        return false
    end
    local canUse = false
    if type(C_Bank.CanUseBank) == "function" then
        local ok, result = pcall(C_Bank.CanUseBank, Enum.BankType.Account)
        if ok then canUse = result end
    end
    if not canUse then
        ns.Utils.Print("[ABPM] 현재 전투부대 은행을 사용할 수 없는 상태입니다.")
        return false
    end
    return true
end

-- 모든 은행 세션 강제 종료 (수동 호출 또는 상호작용 실패 감지 시)
function ns.ABPM_ResetBankSession()
    abpmCloseBankSessions()
    ns.Utils.Print("[ABPM] 전투부대 은행 세션을 초기화했습니다.")
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
    -- 전투부대 은행 세션 보호 이벤트
    frame:RegisterEvent("PLAYER_LEAVING_WORLD")
    frame:RegisterEvent("BANKFRAME_OPENED")
    frame:RegisterEvent("BANKFRAME_CLOSED")
    frame:RegisterEvent("UI_ERROR_MESSAGE")
    -- 쐐기(M+) 진행 상태 감지 — 스탯 오버레이 M+ 우선순위 자동 전환
    frame:RegisterEvent("CHALLENGE_MODE_START")
    frame:RegisterEvent("CHALLENGE_MODE_COMPLETED")
    frame:RegisterEvent("CHALLENGE_MODE_DEATH_COUNT_UPDATED")
    -- 인던/존 이동: 스탯 오버레이가 stale signature 로 0 표시되는 문제 방지
    frame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
    frame:RegisterEvent("PLAYER_ENTER_COMBAT")
    frame:RegisterEvent("PLAYER_LEAVE_COMBAT")
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
    -- 로그인 직후 PaperDoll API 가 0 일 수 있어 force 후속 갱신 1회 추가
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
    ns:SafeCall(ns.DB, "RefreshCharacterRecord")
    ns:SafeCall(ns.UI.ItemLevelOverlay, "InvalidateBountifulDelveNamesCache")
    ns:SafeCall(ns.Modules.ProfessionKnowledgeTracker, "InvalidateProfessionCache")
    ensureMouseMoveSetting()
    ensureCombatTextSettings()
    refreshGhostsAndRetries()
    runProfessionKnowledgeRefresh(true, "PLAYER_ENTERING_WORLD")
    -- 인던/PvP 진입 직후엔 PaperDoll 통계 API 가 일시적으로 0 을 반환할 수 있어
    -- 짧은 후속 force refresh 두 번을 통해 값이 채워지자마자 갱신되도록 한다.
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
    -- 장비 교체는 stat 절대값을 다시 계산해야 하므로 force 로 캐시 무효화
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

    -- 트링킷 사용 효과 / 물약 / 외부 버프는 buff hash 가 변하면 즉시 반영되어야 한다.
    -- slow(0.45s)는 응답이 너무 느려 발동 효과를 놓치므로 일반 디바운스(0.15s)로 변경.
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

-- 전투부대 은행 세션 보호 핸들러
function Events:PLAYER_LEAVING_WORLD()
    abpmCloseBankSessions()
end

function Events:BANKFRAME_OPENED()
    abpmBankSessionActive = true
end

function Events:BANKFRAME_CLOSED()
    -- 주의: 여기서 CloseBankFrame/abpmCloseBankSessions 호출 금지
    -- BankFrame이 닫히는 도중에 재호출하면 BANKFRAME_CLOSED가 재발화되어 무한 재귀 발생
    abpmBankSessionActive = false
end

function Events:UI_ERROR_MESSAGE(messageType, message)
    if not message then return end
    local isBankError = false
    -- 방법 1: WoW 전역 상수 직접 비교 (영문 클라이언트)
    if _G["ERR_BANK_IN_USE"] and message == _G["ERR_BANK_IN_USE"] then
        isBankError = true
    end
    -- 방법 2: "bank" 부분 문자열 검색 (다국어 클라이언트 보완)
    if not isBankError then
        local ok, found = pcall(string.find, string.lower(message), "bank", 1, true)
        if ok and found then isBankError = true end
    end
    if isBankError and abpmBankSessionActive then
        abpmCloseBankSessions()
        ns.Utils.Print("[ABPM] 은행이 다른 곳에서 사용 중입니다. 전투부대 은행 세션을 닫았습니다.")
    end
end

-- 쐐기(M+) 상태 핸들러 — isMplus 자동 감지 경로
function Events:CHALLENGE_MODE_START()
    refreshStatsOverlayForce(STATS_REFRESH_DELAY)
end

function Events:CHALLENGE_MODE_COMPLETED()
    refreshStatsOverlayForce(STATS_REFRESH_DELAY)
end

function Events:CHALLENGE_MODE_DEATH_COUNT_UPDATED()
    refreshStatsOverlay()
end

-- 존(인던) 이동: 인스턴스 컨텍스트 자체가 signature 의 일부이므로 force 갱신
function Events:ZONE_CHANGED_NEW_AREA()
    ns:SafeCall(ns.UI.StatsOverlay, "InvalidateState")
    refreshStatsOverlayForce(STATS_REFRESH_DELAY)
end

-- 전투 진입/종료 시 발동 효과 / 분노 / 광폭화 등 buff 상태 변동 즉시 반영
function Events:PLAYER_ENTER_COMBAT()
    refreshStatsOverlay()
end

function Events:PLAYER_LEAVE_COMBAT()
    refreshStatsOverlay()
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
