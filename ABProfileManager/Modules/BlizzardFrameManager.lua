local addonName, ns = ...

ns.Modules = ns.Modules or {}
local BlizzardFrameManager = {}
ns.Modules.BlizzardFrameManager = BlizzardFrameManager

-- 이동 가능하게 만들 블리자드 프레임 목록
-- uiPanel=true: ShowUIPanel 이 OnShow 이후 위치를 덮어쓰므로 C_Timer.After(0) 딜레이 복원
-- lazyAddon: 해당 이름의 애드온이 로드될 때 자동 적용
local MANAGED_FRAMES = {
    {
        key = "WorldMap",
        getter = function() return WorldMapFrame end,
        hookOnShow = true,
    },
    {
        key = "QuestLog",
        getter = function() return QuestLogFrame or QuestMapFrame end,
        hookOnShow = true,
        uiPanel   = true,
        lazyAddon = "Blizzard_QuestLog",
    },
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

local function getFrameDB(key)
    if not ns.DB then return nil end
    return ns.DB:GetBlizzardFramePosition(key)
end

local function saveFrameDB(key, frame)
    if not ns.DB or not frame then return end
    ns.DB:SaveBlizzardFramePosition(key, frame)
end

local function restoreFramePosition(key, frame)
    if not frame then return end
    local pos = getFrameDB(key)
    if pos and pos.point then
        pcall(function()
            frame:ClearAllPoints()
            frame:SetPoint(pos.point, UIParent, pos.relativePoint or pos.point, pos.x or 0, pos.y or 0)
            -- WoW에 사용자 배치 표시: UIPanelLayout이 이 프레임을 재배치하지 않도록
            if frame.SetUserPlaced then
                frame:SetUserPlaced(true)
            end
        end)
    end
end

local function makeFrameMovable(key, frame)
    if not frame then return end

    pcall(function()
        frame:SetMovable(true)
        frame:EnableMouse(true)
        frame:RegisterForDrag("LeftButton")
        frame:SetClampedToScreen(true)
        if frame.SetUserPlaced then
            frame:SetUserPlaced(true)
        end
    end)

    -- OnDragStart: 기존 스크립트 유무에 관계없이 StartMoving 보장
    local hasExisting = false
    pcall(function()
        hasExisting = frame:GetScript("OnDragStart") ~= nil
    end)

    if not hasExisting then
        pcall(function()
            frame:SetScript("OnDragStart", function(f)
                if not InCombatLockdown() then f:StartMoving() end
            end)
            frame:SetScript("OnDragStop", function(f)
                f:StopMovingOrSizing()
                saveFrameDB(key, f)
            end)
        end)
    else
        -- 기존 핸들러가 있어도 StartMoving + 저장을 추가로 걸어둠
        pcall(function()
            frame:HookScript("OnDragStart", function(f)
                if not InCombatLockdown() and not f:IsMoving() then f:StartMoving() end
            end)
            frame:HookScript("OnDragStop", function(f)
                if f:IsMoving() then f:StopMovingOrSizing() end
                saveFrameDB(key, f)
            end)
        end)
    end
end

local function applyToFrame(entry)
    local frame = entry.getter and entry.getter()
    if not frame then return false end

    if not ns.DB or not ns.DB:IsBlizzardFrameMovable(entry.key) then
        return true  -- 프레임은 있지만 비활성화 상태
    end

    makeFrameMovable(entry.key, frame)
    restoreFramePosition(entry.key, frame)

    if entry.hookOnShow and not entry._showHooked then
        entry._showHooked = true
        pcall(function()
            frame:HookScript("OnShow", function(f)
                if not ns.DB or not ns.DB:IsBlizzardFrameMovable(entry.key) then return end
                -- uiPanel 여부에 관계없이 항상 다음 프레임에서 복원
                -- (UIPanelLayout이 Show 이후에도 위치를 덮어쓸 수 있음)
                C_Timer.After(0, function()
                    if f and f:IsShown() then
                        restoreFramePosition(entry.key, f)
                    end
                end)
            end)
        end)
    end

    return true
end

function BlizzardFrameManager:Apply()
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
                    frame:ClearAllPoints()
                    frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
                    if frame.SetUserPlaced then frame:SetUserPlaced(false) end
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

    -- lazyAddon 매핑 구축: addonName → entry 목록
    local addonMap = {}
    for _, entry in ipairs(MANAGED_FRAMES) do
        if entry.lazyAddon then
            addonMap[entry.lazyAddon] = addonMap[entry.lazyAddon] or {}
            addonMap[entry.lazyAddon][#addonMap[entry.lazyAddon] + 1] = entry
        end
    end

    -- ADDON_LOADED 이벤트로 lazy 프레임 적용 (별도 이벤트 프레임)
    local lazyFrame = CreateFrame("Frame")
    lazyFrame:RegisterEvent("ADDON_LOADED")
    lazyFrame:SetScript("OnEvent", function(_, event, loadedName)
        if event ~= "ADDON_LOADED" then return end
        if not ns.DB or not ns.DB:IsBlizzardFrameManagerEnabled() then return end
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

    -- UpdateUIPanelPositions 훅: WoW가 패널 배치를 재계산할 때마다 저장 위치 즉시 복원
    -- (캐릭터창 탭 전환, 인접 패널 닫힘 등으로 인한 강제 재배치 대응)
    -- C_Timer 없이 직접 호출 → 탭 전환 시 깜박임 제거
    if type(UpdateUIPanelPositions) == "function" then
        hooksecurefunc("UpdateUIPanelPositions", function()
            if not ns.DB or not ns.DB:IsBlizzardFrameManagerEnabled() then return end
            for _, entry in ipairs(MANAGED_FRAMES) do
                if ns.DB:IsBlizzardFrameMovable(entry.key) then
                    local frame = entry.getter and entry.getter()
                    if frame and frame:IsShown() then
                        restoreFramePosition(entry.key, frame)
                    end
                end
            end
        end)
    end

    ns.Utils.Debug("[BlizzardFrameManager] 초기화 완료")
end
