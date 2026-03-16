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

-- Text labels for AH filter button and expansion-only option (koKR / enUS)
local AH_FILTER_BUTTON_LABELS = {
    ["필터"] = true,
    ["Filter"] = true,
}

local function getAnyFrameText(f)
    local ok, result = pcall(function()
        if type(f.GetText) == "function" then
            local t = f:GetText()
            if t and t ~= "" then return t end
        end
        for _, r in ipairs({ f:GetRegions() }) do
            if r and type(r.GetText) == "function" then
                local t = r:GetText()
                if t and t ~= "" then return t end
            end
        end
        return nil
    end)
    return ok and result or nil
end

local function findFrameByLabel(root, labelTable, depth)
    if depth > 8 or not root then return nil end
    local text = getAnyFrameText(root)
    if text then
        local ok, matched = pcall(function() return labelTable[text] end)
        if ok and matched then return root end
    end
    local ok, children = pcall(function() return { root:GetChildren() } end)
    if not ok then return nil end
    for _, child in ipairs(children) do
        local found = findFrameByLabel(child, labelTable, depth + 1)
        if found then return found end
    end
    return nil
end

-- Find a visible CheckButton in root that is NOT inside an Auctionator sub-frame
local function findExpansionCheckButton(root, depth)
    if depth > 8 or not root then return nil end

    -- Skip Auctionator child frames by name
    local okn, name = pcall(function() return root:GetName() end)
    if okn and name and depth > 0 then
        if string.find(name, "Auctionator", 1, true) then
            return nil
        end
    end

    local ftype = root.GetObjectType and root:GetObjectType() or ""
    if ftype == "CheckButton" then
        local okv, vis = pcall(function() return root:IsVisible() end)
        if okv and vis then
            return root
        end
    end

    local ok, children = pcall(function() return { root:GetChildren() } end)
    if not ok then return nil end
    for _, child in ipairs(children) do
        local found = findExpansionCheckButton(child, depth + 1)
        if found then return found end
    end
    return nil
end

local function clickFrame(f)
    local ok, onClick = pcall(function() return f:GetScript("OnClick") end)
    if ok and type(onClick) == "function" then
        pcall(onClick, f, "LeftButton")
    else
        pcall(function() f:Click() end)
    end
end

local function applyAuctionHouseExpansionFilter()
    if not AuctionHouseFrame or not AuctionHouseFrame:IsVisible() then
        return
    end

    -- Step 1: find and click the "필터" / "Filter" button (by text — not tainted)
    local filterBtn = findFrameByLabel(AuctionHouseFrame, AH_FILTER_BUTTON_LABELS, 0)
    if not filterBtn then
        ns.Utils.Debug("[AH Filter] 필터 버튼을 찾지 못했습니다.")
        return
    end
    pcall(clickFrame, filterBtn)

    -- Step 2: after panel opens, find the visible non-Auctionator CheckButton
    if not C_Timer or type(C_Timer.After) ~= "function" then return end
    C_Timer.After(0.35, function()
        local expansionCheck = findExpansionCheckButton(AuctionHouseFrame, 0)
        if not expansionCheck then
            ns.Utils.Debug("[AH Filter] 확장팩 체크박스를 찾지 못했습니다.")
            return
        end
        -- If already checked, just close the panel
        local okc, isChecked = pcall(function() return expansionCheck:GetChecked() end)
        if okc and isChecked then
            pcall(clickFrame, filterBtn)
            return
        end
        pcall(clickFrame, expansionCheck)
        -- Close the filter panel
        C_Timer.After(0.15, function()
            pcall(clickFrame, filterBtn)
        end)
    end)
end

local function ensureAuctionHouseFilter()
    if not ns.DB or not ns.DB:IsAuctionHouseFilterEnabled() then
        return
    end

    if not C_Timer or type(C_Timer.After) ~= "function" then
        return
    end

    C_Timer.After(0.5, function()
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
