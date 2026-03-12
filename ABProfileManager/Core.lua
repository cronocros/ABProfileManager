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

    module:Initialize()
    module._initialized = true
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
        self.Commands,
        self.UI.ConfirmDialogs,
        self.UI.MinimapButton,
        self.UI.StatsOverlay,
        self.UI.ProfessionKnowledgeOverlay,
        self.UI.TransferDialog,
        self.UI.ConfigPanel,
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

    return target[methodName](target, ...)
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

function ns:RefreshUI()
    self:SafeCall(self.UI.ProfilePanel, "Refresh")
    self:SafeCall(self.UI.ActionBarPanel, "Refresh")
    self:SafeCall(self.UI.ProfessionPanel, "Refresh")
    self:SafeCall(self.UI.QuestPanel, "Refresh")
    self:SafeCall(self.UI.ConfigPanel, "Refresh")
    self:SafeCall(self.UI.MinimapButton, "Refresh")
    self:SafeCall(self.UI.StatsOverlay, "Refresh")
    self:SafeCall(self.UI.ProfessionKnowledgeOverlay, "Refresh")
    self:SafeCall(self.UI.SilvermoonMapOverlay, "Refresh")
    self:SafeCall(self.UI.MainWindow, "RefreshStatus")
end
