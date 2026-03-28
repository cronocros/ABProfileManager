local addonName, ns = ...

ns.Modules = ns.Modules or {}
local BlizzardFrameManager = {}
ns.Modules.BlizzardFrameManager = BlizzardFrameManager

-- 이동 가능하게 만들 블리자드 프레임 목록
--
-- uiPanel=true  : ShowUIPanel / UpdateUIPanelPositions 가 OnShow 이후 위치를 덮어쓰므로
--                 C_Timer.After(0) 딜레이 복원이 필요한 UIPanel 계열 프레임
-- hookOnShow    : OnShow 때마다 저장 위치를 복원할 프레임
-- lazyAddon     : 해당 이름의 애드온이 로드될 때 자동 적용
local MANAGED_FRAMES = {
    -- [제거됨] WorldMapFrame, QuestLogFrame
    -- WorldMapFrame 에 SetMovable/ClearAllPoints/SetUserPlaced 등 어떤 조작을 해도
    -- 내부 QuestMapFrame(퀘스트 목록 패널) 레이아웃이 파괴될 수 있음.
    -- 3차례 수정 시도(ef47cdd, af67ad7, noRestore 플래그) 모두 완전 해결 실패.
    -- QuestLogFrame 도 Midnight 에서 WorldMapFrame 과 결합 가능성으로 함께 제거.
    -- 이동 가능한 월드맵이 필요하면 MoveAnything 등 전용 애드온 사용 권장.
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

-- 프레임이 최대화(전체화면) 상태인지 확인
-- WorldMapFrame 등 IsMaximized API 를 가진 프레임에서 사용
local function isFrameMaximized(frame)
    if frame and frame.IsMaximized then
        local ok, result = pcall(function() return frame:IsMaximized() end)
        if ok and result then return true end
    end
    return false
end

-- WorldMapFrame 드래그 전용 (MANAGED_FRAMES 와 완전 분리)
-- · ClearAllPoints / SetPoint / 위치 저장·복원 일체 없음
-- · SetUserPlaced 는 StopMovingOrSizing 후 즉시 false 로 되돌림
-- · 세션 내 위치는 WoW 의 SetMovable 동작이 자체 보존
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
                -- StopMovingOrSizing 가 암묵적으로 UserPlaced=true 설정
                -- WorldMapFrame 에 남으면 퀘스트 목록 패널 레이아웃 파괴
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
    -- 최대화(전체화면) 상태의 위치는 저장하지 않음
    -- 전체화면 좌표를 저장하면 다음 복원 시 윈도우 모드 레이아웃이 파괴됨
    if isFrameMaximized(frame) then return end
    ns.DB:SaveBlizzardFramePosition(key, frame)
end

local function restoreFramePosition(key, frame, isUiPanel)
    if not frame then return end
    -- 최대화(전체화면) 상태에서는 위치 변경 불가
    if isFrameMaximized(frame) then return end
    local pos = getFrameDB(key)
    if pos and pos.point then
        pcall(function()
            frame:ClearAllPoints()
            frame:SetPoint(pos.point, UIParent, pos.relativePoint or pos.point, pos.x or 0, pos.y or 0)
            -- uiPanel: SetUserPlaced(true) → UIPanelLayout 재배치 방지
            -- 비uiPanel: SetUserPlaced(false) → 이전 드래그에서 남은 UserPlaced 상태 해제
            if frame.SetUserPlaced then
                frame:SetUserPlaced(isUiPanel and true or false)
            end
        end)
    end
end

local function makeFrameMovable(key, frame, isUiPanel)
    if not frame then return end

    pcall(function()
        frame:SetMovable(true)
        frame:EnableMouse(true)
        frame:RegisterForDrag("LeftButton")
        frame:SetClampedToScreen(true)
        -- uiPanel: UserPlaced=true → UIPanelLayout 재배치 방지
        -- 비uiPanel: UserPlaced=false → 이전 세션에서 남은 상태 해제
        if frame.SetUserPlaced then
            frame:SetUserPlaced(isUiPanel and true or false)
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
                -- 최대화(전체화면) 상태에서는 드래그 금지
                if InCombatLockdown() then return end
                if isFrameMaximized(f) then return end
                f:StartMoving()
            end)
            frame:SetScript("OnDragStop", function(f)
                f:StopMovingOrSizing()
                -- StopMovingOrSizing 가 암묵적으로 UserPlaced=true 설정
                -- 비UIPanel 프레임에서 즉시 해제
                if not isUiPanel and f.SetUserPlaced then
                    f:SetUserPlaced(false)
                end
                saveFrameDB(key, f)
            end)
        end)
    else
        -- 기존 핸들러가 이미 StartMoving/StopMovingOrSizing 을 처리하므로
        -- 위치 저장 + UserPlaced 해제만 추가
        pcall(function()
            frame:HookScript("OnDragStop", function(f)
                saveFrameDB(key, f)
                -- StopMovingOrSizing 가 암묵적으로 UserPlaced=true 설정
                -- 비UIPanel 프레임에서 해제
                if not isUiPanel and f.SetUserPlaced then
                    f:SetUserPlaced(false)
                end
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

    makeFrameMovable(entry.key, frame, entry.uiPanel)

    if not entry.hookOnShow then
        if not frame:IsShown() then
            restoreFramePosition(entry.key, frame, entry.uiPanel)
        end
    else
        restoreFramePosition(entry.key, frame, entry.uiPanel)
    end

    if entry.hookOnShow and not entry._showHooked then
        entry._showHooked = true
        pcall(function()
            frame:HookScript("OnShow", function(f)
                if not ns.DB or not ns.DB:IsBlizzardFrameMovable(entry.key) then return end
                -- 즉시 복원 (UIPanelLayout 덮어쓰기 대응)
                C_Timer.After(0, function()
                    if f and f:IsShown() then restoreFramePosition(entry.key, f, entry.uiPanel) end
                end)
                -- 추가 지연 복원: 탭 전환 후 WoW 가 다음 프레임에서 위치를 재설정하는 경우 대응
                C_Timer.After(0.12, function()
                    if f and f:IsShown() then restoreFramePosition(entry.key, f, entry.uiPanel) end
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
        -- WorldMapFrame 수요 로드 감지 (MANAGED_FRAMES 와 분리된 드래그 전용)
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

    -- UpdateUIPanelPositions 훅: WoW 가 패널 배치를 재계산할 때마다 저장 위치 복원
    -- (캐릭터창 탭 전환, 인접 패널 닫힘 등으로 인한 강제 재배치 대응)
    -- uiPanel=true 프레임만 대상
    if type(UpdateUIPanelPositions) == "function" then
        local uiPanelDeferPending = false
        hooksecurefunc("UpdateUIPanelPositions", function()
            if not ns.DB or not ns.DB:IsBlizzardFrameManagerEnabled() then return end
            -- 즉시 복원 (uiPanel=true 프레임만)
            for _, entry in ipairs(MANAGED_FRAMES) do
                if entry.uiPanel and ns.DB:IsBlizzardFrameMovable(entry.key) then
                    local frame = entry.getter and entry.getter()
                    if frame and frame:IsShown() then
                        restoreFramePosition(entry.key, frame, true)
                    end
                end
            end
            -- 단일 deferred 복원 (중복 타이머 방지)
            if not uiPanelDeferPending then
                uiPanelDeferPending = true
                C_Timer.After(0, function()
                    uiPanelDeferPending = false
                    if not ns.DB or not ns.DB:IsBlizzardFrameManagerEnabled() then return end
                    for _, entry in ipairs(MANAGED_FRAMES) do
                        if entry.uiPanel and ns.DB:IsBlizzardFrameMovable(entry.key) then
                            local frame = entry.getter and entry.getter()
                            if frame and frame:IsShown() then
                                restoreFramePosition(entry.key, frame, true)
                            end
                        end
                    end
                end)
            end
        end)
    end

    -- ShowUIPanel 훅: UIPanel 계열 프레임이 탭 전환 시 ShowUIPanel 을 재호출하는 경우 대응
    -- uiPanel=true 프레임만 대상
    if type(ShowUIPanel) == "function" then
        pcall(function()
            hooksecurefunc("ShowUIPanel", function(frame)
                if not ns.DB or not ns.DB:IsBlizzardFrameManagerEnabled() then return end
                for _, entry in ipairs(MANAGED_FRAMES) do
                    if entry.uiPanel then
                        local f = entry.getter and entry.getter()
                        if f == frame and ns.DB:IsBlizzardFrameMovable(entry.key) then
                            C_Timer.After(0, function()
                                if frame and frame:IsShown() then restoreFramePosition(entry.key, frame, true) end
                            end)
                            C_Timer.After(0.12, function()
                                if frame and frame:IsShown() then restoreFramePosition(entry.key, frame, true) end
                            end)
                            break
                        end
                    end
                end
            end)
        end)
    end

    ns.Utils.Debug("[BlizzardFrameManager] 초기화 완료")
end
