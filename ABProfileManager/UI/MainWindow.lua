local _, ns = ...

local MainWindow = {}
ns.UI.MainWindow = MainWindow

local function buildWindowTitle()
    return string.format("%s  v%s", ns.L("window_title"), ns.Constants.VERSION or "?")
end

local function applyTabSelectionStyles(window)
    ns.UI.Widgets.SetButtonSelected(window.profilesTab, window.currentTab == "profiles")
    ns.UI.Widgets.SetButtonSelected(window.actionBarsTab, window.currentTab == "action_bars")
    ns.UI.Widgets.SetButtonSelected(window.professionsTab, window.currentTab == "professions")
    ns.UI.Widgets.SetButtonSelected(window.questsTab, window.currentTab == "quests")
    ns.UI.Widgets.SetButtonSelected(window.configTab, window.currentTab == "config")
end

local function showTab(window, tabName)
    if not window then
        return
    end

    window.currentTab = tabName
    window.profilePanel:SetShown(tabName == "profiles")
    window.actionBarPanel:SetShown(tabName == "action_bars")
    window.professionPanel:SetShown(tabName == "professions")
    window.questPanel:SetShown(tabName == "quests")
    window.configPanel:SetShown(tabName == "config")
    applyTabSelectionStyles(window)
end

function MainWindow:RefreshLocale()
    if not self.frame then
        return
    end

    self.frame.title:SetText(buildWindowTitle())
    self.frame.title:SetTextColor(1, 0.86, 0.42, 1)
    self.frame.profilesTab:SetText(ns.L("tab_profiles"))
    self.frame.actionBarsTab:SetText(ns.L("tab_action_bars"))
    self.frame.professionsTab:SetText(ns.L("tab_professions"))
    self.frame.questsTab:SetText(ns.L("tab_quests"))
    self.frame.configTab:SetText(ns.L("tab_config"))
end

function MainWindow:Initialize()
    if self.frame then
        return
    end

    local config = ns.DB and ns.DB:GetMainWindowConfig() or ns.Data.Defaults.ui.mainWindow
    local windowWidth = math.max(config.width or ns.Constants.WINDOW_WIDTH, ns.Constants.WINDOW_WIDTH)
    local windowHeight = math.max(config.height or ns.Constants.WINDOW_HEIGHT, ns.Constants.WINDOW_HEIGHT)
    local frame = CreateFrame("Frame", "ABProfileManagerMainWindow", UIParent, "BackdropTemplate")
    frame:SetSize(windowWidth, windowHeight)
    frame:SetPoint(config.point, UIParent, config.relativePoint, config.x, config.y)
    frame:SetClampedToScreen(true)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", function(currentFrame)
        currentFrame:StopMovingOrSizing()
        if ns.DB then
            ns.DB:SaveMainWindowPosition(currentFrame)
        end
    end)
    frame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true,
        tileSize = 32,
        edgeSize = 32,
        insets = { left = 8, right = 8, top = 8, bottom = 8 },
    })
    frame:SetBackdropColor(0.02, 0.04, 0.07, 0.95)
    frame:Hide()

    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    title:SetPoint("TOPLEFT", 22, -18)
    title:SetWidth(windowWidth - 120)
    title:SetJustifyH("LEFT")
    title:SetTextColor(1, 0.86, 0.42, 1)
    title:SetText(buildWindowTitle())

    local closeButton = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    closeButton:SetPoint("TOPRIGHT", -6, -6)

    local tabContainer = CreateFrame("Frame", nil, frame)
    tabContainer:SetPoint("TOPLEFT", 16, -42)
    tabContainer:SetPoint("TOPRIGHT", -16, -42)
    tabContainer:SetHeight(28)

    local tabWidth = 102

    local profilesTab = ns.UI.Widgets.CreateButton(tabContainer, "", tabWidth, 24)
    profilesTab:SetPoint("TOPLEFT", 0, 0)

    local actionBarsTab = ns.UI.Widgets.CreateButton(tabContainer, "", tabWidth, 24)
    actionBarsTab:SetPoint("LEFT", profilesTab, "RIGHT", 8, 0)

    local professionsTab = ns.UI.Widgets.CreateButton(tabContainer, "", tabWidth, 24)
    professionsTab:SetPoint("LEFT", actionBarsTab, "RIGHT", 8, 0)

    local questsTab = ns.UI.Widgets.CreateButton(tabContainer, "", tabWidth, 24)
    questsTab:SetPoint("LEFT", professionsTab, "RIGHT", 8, 0)

    local configTab = ns.UI.Widgets.CreateButton(tabContainer, "", tabWidth, 24)
    configTab:SetPoint("LEFT", questsTab, "RIGHT", 8, 0)

    local content = CreateFrame("Frame", nil, frame)
    content:SetPoint("TOPLEFT", 16, -76)
    content:SetPoint("BOTTOMRIGHT", -16, 144)

    frame.profilePanel = ns.UI.ProfilePanel:Create(content)
    frame.actionBarPanel = ns.UI.ActionBarPanel:Create(content)
    frame.professionPanel = ns.UI.ProfessionPanel:Create(content)
    frame.questPanel = ns.UI.QuestPanel:Create(content)
    frame.configPanel = ns.UI.ConfigPanel:Create(content)

    local statusBox = ns.UI.Widgets.CreatePanelBox(frame, windowWidth - 64, 120, nil)
    statusBox:SetPoint("BOTTOMLEFT", 28, 18)
    statusBox:SetPoint("BOTTOMRIGHT", -28, 18)

    local statusText = ns.UI.Widgets.CreateScrollTextBox(statusBox, windowWidth - 92, 90)
    statusText:SetPoint("TOPLEFT", 12, -14)
    if statusText.text then
        statusText.text:SetFont(STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF", 14, "")
        if statusText.text.SetSpacing then
            statusText.text:SetSpacing(5)
        end
    end
    statusText:SetText(ns.L("status_ready"))

    profilesTab:SetScript("OnClick", function()
        showTab(frame, "profiles")
        ns:RefreshUI()
    end)
    actionBarsTab:SetScript("OnClick", function()
        showTab(frame, "action_bars")
        ns:RefreshUI()
    end)
    professionsTab:SetScript("OnClick", function()
        showTab(frame, "professions")
        ns:RefreshUI()
    end)
    questsTab:SetScript("OnClick", function()
        showTab(frame, "quests")
        ns:RefreshUI()
    end)
    configTab:SetScript("OnClick", function()
        showTab(frame, "config")
        ns:RefreshUI()
    end)

    frame.title = title
    frame.statusBox = statusBox
    frame.statusText = statusText
    frame.profilesTab = profilesTab
    frame.actionBarsTab = actionBarsTab
    frame.professionsTab = professionsTab
    frame.questsTab = questsTab
    frame.configTab = configTab

    showTab(frame, "profiles")

    self.frame = frame
    self:RefreshLocale()
end

function MainWindow:SetStatus(message)
    self.lastStatusMessage = ns.Utils.FormatStatusMessage(message or ns.L("status_ready"))
    if self.frame and self.frame.statusText then
        self.frame.statusText:SetText("")
        self.frame.statusText:SetText(self.lastStatusMessage)
    end
end

function MainWindow:RefreshStatus()
    self:RefreshLocale()

    if self.lastStatusMessage and self.lastStatusMessage ~= "" then
        if self.frame and self.frame.statusText then
            self.frame.statusText:SetText("")
            self.frame.statusText:SetText(self.lastStatusMessage)
        end
        return
    end

    local selectedSource = ns:GetSelectedSource()
    if not selectedSource then
        self:SetStatus(ns.L("status_ready_no_source"))
        return
    end

    if selectedSource.kind == ns.Constants.SOURCE_KIND.TEMPLATE and ns.DB and not ns.DB:GetTemplate(selectedSource.key) then
        ns:SetSelectedSource(nil, nil)
        self:SetStatus(ns.L("status_ready_no_source"))
        return
    end

    self:SetStatus(ns.L("selected_source", selectedSource.key))
end

function MainWindow:Toggle()
    if not self.frame then
        self:Initialize()
    end

    if self.frame:IsShown() then
        self.frame:Hide()
        return
    end

    self.frame:Show()
    ns:RefreshUI()
end

function MainWindow:OpenToTab(tabName)
    if not self.frame then
        self:Initialize()
    end

    if not self.frame then
        return
    end

    self.frame:Show()

    local validTabs = {
        profiles = true,
        action_bars = true,
        professions = true,
        quests = true,
        config = true,
    }

    showTab(self.frame, validTabs[tabName] and tabName or "profiles")
    ns:RefreshUI()
end

function MainWindow:OnPlayerLogin()
    ns:RefreshUI()
end
