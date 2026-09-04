local addonName, ns = ...

ns.Modules = ns.Modules or {}
local BlizzardFrameManager = {}
ns.Modules.BlizzardFrameManager = BlizzardFrameManager

local MANAGED_FRAMES = {

    {
        key = "CharacterFrame",
        getter = function() return CharacterFrame end,
        hookOnShow = true,
        uiPanel   = true,
    },
    {
        key = "Professions",
        getter = function() return ProfessionsFrame end,
        hookOnShow = true,
        lazyAddon = "Blizzard_Professions",
    },
    {
        key = "SpellBook",
        getter = function() return PlayerSpellsFrame or SpellBookFrame end,
        hookOnShow = true,
        lazyAddon = "Blizzard_PlayerSpells",
    },
    {
        key = "Achievement",
        getter = function() return AchievementFrame end,
        hookOnShow = true,
        lazyAddon = "Blizzard_AchievementUI",
    },
    {
        key = "Talent",
        getter = function() return ClassTalentFrame or TalentFrame end,
        hookOnShow = true,
        lazyAddon = "Blizzard_ClassTalentUI",
    },
    {
        key = "Friends",
        getter = function() return FriendsFrame end,
        hookOnShow = true,
        uiPanel   = true,
    },
    {
        key = "Guild",
        getter = function() return GuildFrame end,
        hookOnShow = true,
        lazyAddon = "Blizzard_GuildUI",
    },
    {
        key = "Bank",
        getter = function() return BankFrame end,
        hookOnShow = true,
        uiPanel   = true,
    },
    {
        key = "Collections",
        getter = function() return CollectionsJournal end,
        hookOnShow = true,
        lazyAddon = "Blizzard_Collections",
    },
    {
        key = "EncounterJournal",
        getter = function() return EncounterJournal end,
        hookOnShow = true,
        lazyAddon = "Blizzard_EncounterJournal",
    },
    {
        key = "LFGParent",
        getter = function() return PVEFrame or LFGParentFrame end,
        hookOnShow = true,
        lazyAddon = "Blizzard_LookingForGroup",
    },
    {
        key = "Trade",
        getter = function() return TradeFrame end,
        hookOnShow = true,
    },
    {
        key = "Merchant",
        getter = function() return MerchantFrame end,
        hookOnShow = true,
    },
    {
        key = "Gossip",
        getter = function() return GossipFrame end,
        hookOnShow = true,
    },
    {
        key = "ItemUpgrade",
        getter = function() return ItemUpgradeFrame end,
        hookOnShow = true,
        lazyAddon = "Blizzard_ItemUpgrade",
    },
    {
        key = "Calendar",
        getter = function() return CalendarFrame end,
        hookOnShow = true,
        lazyAddon = "Blizzard_Calendar",
    },
    {
        key = "Inspect",
        getter = function() return InspectFrame end,
        hookOnShow = true,
    },
}

local function isFrameMaximized(frame)
    if frame and frame.IsMaximized then
        local ok, result = pcall(function() return frame:IsMaximized() end)
        if ok and result then return true end
    end
    return false
end

local function getFrameName(frame)
    if not frame or type(frame.GetName) ~= "function" then
        return nil
    end

    local ok, name = pcall(frame.GetName, frame)
    if ok then
        return name
    end

    return nil
end

local function isRegisteredUIPanel(frame)
    local frameName = getFrameName(frame)
    return frameName
        and type(UIPanelWindows) == "table"
        and UIPanelWindows[frameName] ~= nil
end

local function shouldManageAsUIPanel(entry, frame)
    return (entry and entry.uiPanel) or isRegisteredUIPanel(frame)
end

local function enableWorldMapDrag()
    if not WorldMapFrame then return end
    if WorldMapFrame._abpmDragEnabled then return end
    WorldMapFrame._abpmDragEnabled = true

    pcall(function()
        WorldMapFrame:SetMovable(true)
        WorldMapFrame:RegisterForDrag("LeftButton")
        WorldMapFrame:SetClampedToScreen(true)
    end)

    local hasExisting = false
    pcall(function()
        hasExisting = WorldMapFrame:GetScript("OnDragStart") ~= nil
    end)

    if not hasExisting then
        pcall(function()
            WorldMapFrame:SetScript("OnDragStart", function(f)
                if InCombatLockdown() then return end
                if isFrameMaximized(f) then return end
                f:StartMoving()
            end)
            WorldMapFrame:SetScript("OnDragStop", function(f)
                f:StopMovingOrSizing()

                if f.SetUserPlaced then f:SetUserPlaced(false) end
            end)
        end)
    else
        pcall(function()
            WorldMapFrame:HookScript("OnDragStop", function(f)
                if f.SetUserPlaced then f:SetUserPlaced(false) end
            end)
        end)
    end

    ns.Utils.Debug("[BlizzardFrameManager] WorldMapFrame 드래그 활성화 (위치 저장 없음)")
end

local function getFrameDB(key)
    if not ns.DB then return nil end
    return ns.DB:GetBlizzardFramePosition(key)
end

local function saveFrameDB(key, frame)
    if not ns.DB or not frame then return end

    if isFrameMaximized(frame) then return end
    ns.DB:SaveBlizzardFramePosition(key, frame)
end

local function restoreFramePosition(key, frame, isUiPanel)
    if not frame then return end

    if isFrameMaximized(frame) then return end
    local pos = getFrameDB(key)
    if pos and pos.point then
        pcall(function()
            frame:ClearAllPoints()
            frame:SetPoint(pos.point, UIParent, pos.relativePoint or pos.point, pos.x or 0, pos.y or 0)

            if frame.SetUserPlaced then
                frame:SetUserPlaced(isUiPanel and true or false)
            end
        end)
    elseif isUiPanel and frame.SetUserPlaced then

        pcall(function()
            frame:SetUserPlaced(false)
        end)
    end
end

local dragStopHookedFrames = {}

local function makeFrameMovable(key, frame, isUiPanel)
    if not frame then return end

    local hasSavedPosition = getFrameDB(key) ~= nil

    pcall(function()
        frame:SetMovable(true)
        frame:EnableMouse(true)
        frame:RegisterForDrag("LeftButton")
        frame:SetClampedToScreen(true)

        if frame.SetUserPlaced then
            frame:SetUserPlaced(isUiPanel and hasSavedPosition and true or false)
        end
    end)

    local hasExisting = false
    pcall(function()
        hasExisting = frame:GetScript("OnDragStart") ~= nil
    end)

    if not hasExisting then
        dragStopHookedFrames[key] = frame
        pcall(function()
            frame:SetScript("OnDragStart", function(f)

                if InCombatLockdown() then return end
                if isFrameMaximized(f) then return end
                f:StartMoving()
            end)
            frame:SetScript("OnDragStop", function(f)
                f:StopMovingOrSizing()

                if f.SetUserPlaced then
                    f:SetUserPlaced(isUiPanel and true or false)
                end
                saveFrameDB(key, f)
            end)
        end)
    elseif dragStopHookedFrames[key] ~= frame then
        dragStopHookedFrames[key] = frame
        pcall(function()
            frame:HookScript("OnDragStop", function(f)
                saveFrameDB(key, f)

                if f.SetUserPlaced then
                    f:SetUserPlaced(isUiPanel and true or false)
                end
            end)
        end)
    end
end

local function applyToFrame(entry)
    local frame = entry.getter and entry.getter()
    if not frame then return false end

    if not ns.DB or not ns.DB:IsBlizzardFrameMovable(entry.key) then
        return true
    end

    local isUiPanel = shouldManageAsUIPanel(entry, frame)
    makeFrameMovable(entry.key, frame, isUiPanel)

    if not entry.hookOnShow then
        if not frame:IsShown() then
            restoreFramePosition(entry.key, frame, isUiPanel)
        end
    else
        restoreFramePosition(entry.key, frame, isUiPanel)
    end

    if entry.hookOnShow and not entry._showHooked then
        entry._showHooked = true
        pcall(function()
            frame:HookScript("OnShow", function(f)
                if not ns.DB or not ns.DB:IsBlizzardFrameMovable(entry.key) then return end

                C_Timer.After(0, function()
                    if f and f:IsShown() then restoreFramePosition(entry.key, f, shouldManageAsUIPanel(entry, f)) end
                end)

                C_Timer.After(0.12, function()
                    if f and f:IsShown() then restoreFramePosition(entry.key, f, shouldManageAsUIPanel(entry, f)) end
                end)
            end)
        end)
    end

    return true
end

function BlizzardFrameManager:Apply()
    enableWorldMapDrag()
    for _, entry in ipairs(MANAGED_FRAMES) do
        applyToFrame(entry)
    end
end

function BlizzardFrameManager:ResetPosition(key)
    for _, entry in ipairs(MANAGED_FRAMES) do
        if not key or entry.key == key then
            if ns.DB then
                ns.DB:ResetBlizzardFramePosition(entry.key)
            end
            local frame = entry.getter and entry.getter()
            if frame then
                pcall(function()
                    local isUiPanel = shouldManageAsUIPanel(entry, frame)
                    if frame.SetUserPlaced then frame:SetUserPlaced(false) end
                    if not isUiPanel then
                        frame:ClearAllPoints()
                        frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
                    elseif frame:IsShown() and type(UpdateUIPanelPositions) == "function" then
                        C_Timer.After(0, UpdateUIPanelPositions)
                    end
                end)
            end
        end
    end
end

function BlizzardFrameManager:ResetAll()
    self:ResetPosition(nil)
end

function BlizzardFrameManager:Initialize()
    if self._initialized then return end
    self._initialized = true

    local addonMap = {}
    for _, entry in ipairs(MANAGED_FRAMES) do
        if entry.lazyAddon then
            addonMap[entry.lazyAddon] = addonMap[entry.lazyAddon] or {}
            addonMap[entry.lazyAddon][#addonMap[entry.lazyAddon] + 1] = entry
        end
    end

    local lazyFrame = CreateFrame("Frame")
    lazyFrame:RegisterEvent("ADDON_LOADED")
    lazyFrame:SetScript("OnEvent", function(_, event, loadedName)
        if event ~= "ADDON_LOADED" then return end
        if not ns.DB or not ns.DB:IsBlizzardFrameManagerEnabled() then return end

        enableWorldMapDrag()
        local entries = addonMap[loadedName]
        if entries then
            C_Timer.After(0.3, function()
                for _, entry in ipairs(entries) do
                    applyToFrame(entry)
                    ns.Utils.Debug("[BlizzardFrameManager] ADDON_LOADED 적용: " .. entry.key)
                end
            end)
        end
    end)

    if type(UpdateUIPanelPositions) == "function" then
        local uiPanelDeferPending = false
        hooksecurefunc("UpdateUIPanelPositions", function()
            if not ns.DB or not ns.DB:IsBlizzardFrameManagerEnabled() then return end

            for _, entry in ipairs(MANAGED_FRAMES) do
                local frame = entry.getter and entry.getter()
                if frame and shouldManageAsUIPanel(entry, frame) and ns.DB:IsBlizzardFrameMovable(entry.key) and frame:IsShown() then
                    restoreFramePosition(entry.key, frame, true)
                end
            end

            if not uiPanelDeferPending then
                uiPanelDeferPending = true
                C_Timer.After(0, function()
                    uiPanelDeferPending = false
                    if not ns.DB or not ns.DB:IsBlizzardFrameManagerEnabled() then return end
                    for _, entry in ipairs(MANAGED_FRAMES) do
                        local frame = entry.getter and entry.getter()
                        if frame and shouldManageAsUIPanel(entry, frame) and ns.DB:IsBlizzardFrameMovable(entry.key) and frame:IsShown() then
                            restoreFramePosition(entry.key, frame, true)
                        end
                    end
                end)
            end
        end)
    end

    if type(ShowUIPanel) == "function" then
        pcall(function()
            hooksecurefunc("ShowUIPanel", function(frame)
                if not ns.DB or not ns.DB:IsBlizzardFrameManagerEnabled() then return end
                for _, entry in ipairs(MANAGED_FRAMES) do
                    local f = entry.getter and entry.getter()
                    if f == frame and shouldManageAsUIPanel(entry, f) and ns.DB:IsBlizzardFrameMovable(entry.key) then
                        C_Timer.After(0, function()
                            if frame and frame:IsShown() then restoreFramePosition(entry.key, frame, true) end
                        end)
                        C_Timer.After(0.12, function()
                            if frame and frame:IsShown() then restoreFramePosition(entry.key, frame, true) end
                        end)
                        break
                    end
                end
            end)
        end)
    end

    ns.Utils.Debug("[BlizzardFrameManager] 초기화 완료")
end
