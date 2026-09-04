local addonName, ns = ...

_G[addonName] = ns

ns.name = addonName
ns.Constants = ns.Constants or {}
ns.Utils = ns.Utils or {}
ns.Data = ns.Data or {}
ns.Modules = ns.Modules or {}
ns.UI = ns.UI or {}
ns.State = ns.State or {
    addonLoaded = false,
    playerLoggedIn = false,
    debugEnabled = false,
}

local function buildDefaultSelection()
    return {
        mode = ns.Constants.APPLY_MODE and ns.Constants.APPLY_MODE.FULL or "full",
        barIndex = 1,
        startBar = 1,
        endBar = 2,
        selectedBars = { 1, 2 },
        barSetText = "1, 2",
        startSlot = 1,
        endSlot = ns.Constants.LOGICAL_SLOT_MAX or 196,
        clearBeforeApply = true,
    }
end

local function initializeModule(module)
    if not module or module._initialized or type(module.Initialize) ~= "function" then
        return
    end

    local ok, err = pcall(module.Initialize, module)
    if ok then
        module._initialized = true
    else
        if ns.Utils and ns.Utils.RecordCaughtError then
            ns.Utils.RecordCaughtError("ModuleInit", err, 3)
        end
        if ns.Utils and ns.Utils.Debug then
            ns.Utils.Debug(string.format("Module init failed: %s", tostring(err)))
        end
    end
end

function ns:InitializeStartupModules()
    local startupModules = {
        self.Modules.SlotMapper,
        self.Modules.ActionBarScanner,
        self.Modules.UndoManager,
        self.Modules.RangeCopyManager,
        self.Modules.ActionBarApplier,
        self.Modules.TemplateSyncManager,
        self.Modules.TemplateTransfer,
        self.Modules.GhostManager,
        self.Modules.ProfileManager,
        self.Modules.QuestManager,
        self.Modules.ProfessionKnowledgeTracker,
        self.Modules.TomTomBridge,
        self.Modules.CombatTextManager,
        self.Modules.BlizzardFrameManager,
        self.Modules.PrivateAurasGuard,

        self.Commands,
        self.UI.ConfirmDialogs,
        self.UI.MinimapButton,
        self.UI.StatsOverlay,
        self.UI.ProfessionKnowledgeOverlay,
        self.UI.ItemLevelOverlay,
        self.UI.BISOverlay,
        self.UI.MythicPlusRecordOverlay,

        self.UI.TransferDialog,
        self.UI.ConfigPanel,
        self.UI.UtilityPanel,
        self.UI.MapPanel,
        self.UI.SilvermoonMapOverlay,
        self.UI.MainWindow,
    }

    for _, module in ipairs(startupModules) do
        initializeModule(module)
    end
end

function ns:SafeCall(target, methodName, ...)
    if not target or type(target[methodName]) ~= "function" then
        return nil
    end

    local ok, result = pcall(target[methodName], target, ...)
    if not ok then
        if ns.Utils and ns.Utils.RecordCaughtError then
            ns.Utils.RecordCaughtError("SafeCall:" .. tostring(methodName), result, 3)
        end
        if ns.Utils and ns.Utils.Debug then
            ns.Utils.Debug(string.format("SafeCall(%s) failed: %s", tostring(methodName), tostring(result)))
        end
        return nil
    end

    return result
end

function ns:GetSelectionState()
    if type(self.State.selection) ~= "table" then
        self.State.selection = buildDefaultSelection()
    end

    return self.State.selection
end

function ns:SetSelectionState(patch)
    local selection = self:GetSelectionState()
    if type(patch) ~= "table" then
        return selection
    end

    for key, value in pairs(patch) do
        selection[key] = value
    end

    return selection
end

function ns:GetSelectedSource()
    return self.State.selectedSource
end

function ns:SetSelectedSource(kind, key)
    if not kind or not key then
        self.State.selectedSource = nil
        return
    end

    self.State.selectedSource = {
        kind = kind,
        key = key,
    }
end

local function isMainWindowVisible(self)
    local mainWindow = self and self.UI and self.UI.MainWindow
    return mainWindow and mainWindow.frame and mainWindow.frame:IsShown()
end

function ns.IsBlizzardSettingsShown()
    if not SettingsPanel or type(SettingsPanel.IsShown) ~= "function" then
        return false
    end

    local ok, shown = pcall(SettingsPanel.IsShown, SettingsPanel)
    return ok and shown and true or false
end

local function isSettingsPanelVisible()
    return ns.IsBlizzardSettingsShown()
end

local PANEL_BY_TAB = {
    profiles    = "ProfilePanel",
    action_bars = "ActionBarPanel",
    professions = "ProfessionPanel",
    map         = "MapPanel",
    quests      = "QuestPanel",
    config      = "ConfigPanel",
    utility     = "UtilityPanel",
}

local function currentTabPanelName(self)
    local mainWindow = self and self.UI and self.UI.MainWindow
    local frame = mainWindow and mainWindow.frame
    return frame and PANEL_BY_TAB[frame.currentTab] or nil
end

function ns:RefreshUI()
    self:SafeCall(self.UI.Typography, "RefreshRegistered")

    if isMainWindowVisible(self) then
        local panelName = currentTabPanelName(self)
        if panelName then
            self:SafeCall(self.UI[panelName], "Refresh")
        else
            self:SafeCall(self.UI.ProfilePanel, "Refresh")
        end
        if panelName ~= "ConfigPanel" and isSettingsPanelVisible() then
            self:SafeCall(self.UI.ConfigPanel, "Refresh")
        end
    elseif isSettingsPanelVisible() then
        self:SafeCall(self.UI.ConfigPanel, "Refresh")
    end

    self:SafeCall(self.UI.MinimapButton, "Refresh")
    self:SafeCall(self.UI.StatsOverlay, "Refresh")
    self:SafeCall(self.UI.ProfessionKnowledgeOverlay, "Refresh")
    self:SafeCall(self.UI.ItemLevelOverlay, "Refresh")
    self:SafeCall(self.UI.BISOverlay, "Refresh")
    self:SafeCall(self.UI.MythicPlusRecordOverlay, "Refresh")

    self:SafeCall(self.UI.SilvermoonMapOverlay, "Refresh")
    if isMainWindowVisible(self) then
        self:SafeCall(self.UI.MainWindow, "RefreshStatus")
    end
end
