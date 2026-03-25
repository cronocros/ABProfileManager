local _, ns = ...

local WorldEventOverlay = {}
ns.UI.WorldEventOverlay = WorldEventOverlay

local FONT_PATH  = UNIT_NAME_FONT or STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF"
-- 완료 표시: WoW 내장 ReadyCheck 아이콘 (UTF-8 ✓ 는 일부 폰트에서 깨질 수 있음)
local DONE_MARK  = "|TInterface/RAIDFRAME/ReadyCheck-Ready:10:10:0:0|t "

-- TomTom 웨이포인트 추적 (key → uid)
local eventWaypoints = {}

local function addEventWaypoint(event)
    if not (TomTom and type(TomTom.AddWaypoint) == "function") then return nil end
    if not event.x or not event.y or not event.mapID then return nil end
    local title = ns.L(event.labelKey) or event.key
    local uid
    pcall(function()
        uid = TomTom:AddWaypoint(event.mapID, event.x / 100, event.y / 100, {
            title     = title,
            from      = "ABPM_WorldEvent",
            minimap   = true,
            world     = true,
            silent    = true,
            persistent = false,
        })
    end)
    return uid
end

local function removeEventWaypoint(uid)
    if not uid then return end
    if TomTom and type(TomTom.RemoveWaypoint) == "function" then
        pcall(TomTom.RemoveWaypoint, TomTom, uid)
    end
end

local FONT_FLAGS = "OUTLINE"
local FRAME_W      = 230
local REFRESH_INTERVAL = 1  -- 1초마다 갱신
local TITLE_H      = 22
local ROW_H        = 18
local ROW_GAP      = 3
local PADDING      = 6
local COL_NAME_W   = 96   -- 이름 열 (고정 폭)
local COL_STATUS_W = 48   -- 상태 열 ("진행 중" / "다음:")
local COL_TIMER_W  = 62   -- 타이머 열
local SCALE_STEP   = 0.05
local SCALE_MIN    = 0.60
local SCALE_MAX    = 1.80

-- ============================================================
-- 헬퍼
-- ============================================================

local function formatCountdown(secondsLeft)
    if secondsLeft <= 0 then return "" end
    local m = math.floor(secondsLeft / 60)
    local s = secondsLeft % 60
    if m >= 60 then
        local h = math.floor(m / 60)
        m = m % 60
        return string.format("%d시간 %d분", h, m)
    end
    if m > 0 then return string.format("%d분 %d초", m, s) end
    return string.format("%d초", s)
end

local function getEventState(event, serverTime)
    local intervalSecs = (event.interval or 60) * 60
    local durationSecs = (event.duration or 15) * 60
    local offsetSecs   = (event.offset or 0) * 60
    local cycle = (serverTime - offsetSecs) % intervalSecs
    if cycle < 0 then cycle = cycle + intervalSecs end
    if cycle < durationSecs then
        return "active", durationSecs - cycle
    else
        return "waiting", intervalSecs - cycle
    end
end

-- getEventState 이후에 정의 (forward reference 방지)
local function syncWaypoints(events, serverTime)
    for _, event in ipairs(events) do
        if event.x and event.y and event.mapID then
            local state = getEventState(event, serverTime)
            if state == "active" then
                if not eventWaypoints[event.key] then
                    local uid = addEventWaypoint(event)
                    if uid then eventWaypoints[event.key] = uid end
                end
            else
                if eventWaypoints[event.key] then
                    removeEventWaypoint(eventWaypoints[event.key])
                    eventWaypoints[event.key] = nil
                end
            end
        end
    end
end

local function createFS(parent, size, r, g, b)
    local fs = parent:CreateFontString(nil, "OVERLAY")
    fs:SetFont(FONT_PATH, size or 11, FONT_FLAGS)
    if r then fs:SetTextColor(r, g, b, 1) end
    if fs.SetShadowOffset then
        fs:SetShadowOffset(1, -1)
        fs:SetShadowColor(0, 0, 0, 0.9)
    end
    return fs
end

local function makeBtnText(btn, size, r, g, b)
    local fs = btn:CreateFontString(nil, "OVERLAY")
    fs:SetFont(FONT_PATH, size or 11, FONT_FLAGS)
    if r then fs:SetTextColor(r, g, b, 1) end
    if fs.SetShadowOffset then
        fs:SetShadowOffset(1, -1)
        fs:SetShadowColor(0, 0, 0, 0.8)
    end
    fs:SetAllPoints()
    fs:SetJustifyH("CENTER")
    fs:SetJustifyV("MIDDLE")
    btn:SetFontString(fs)
    return fs
end

-- ============================================================
-- 스케일 저장/로드
-- ============================================================

local function getScale()
    local cfg = ns.DB and ns.DB:GetWorldEventOverlayConfig()
    return cfg and cfg.scale or 1
end

local function setScale(frame, delta)
    local cfg = ns.DB and ns.DB:GetWorldEventOverlayConfig()
    if not cfg then return end
    local cur = cfg.scale or 1
    cur = math.max(SCALE_MIN, math.min(SCALE_MAX, cur + delta))
    cur = math.floor(cur * 100 + 0.5) / 100
    cfg.scale = cur
    frame:SetScale(cur)
end

-- ============================================================
-- 프레임 생성
-- ============================================================

function WorldEventOverlay:EnsureFrame()
    if self.frame then return self.frame end

    local config = ns.DB and ns.DB:GetWorldEventOverlayConfig()
        or ns.Data.Defaults.ui.worldEventOverlay

    local frame = CreateFrame("Frame", "ABPMWorldEventOverlay", UIParent, "BackdropTemplate")
    frame:SetFrameStrata("MEDIUM")
    frame:SetClampedToScreen(true)
    frame:SetSize(FRAME_W, TITLE_H + 6)

    -- 완전 투명 배경 (테두리 없음)
    if frame.SetBackdrop then
        frame:SetBackdrop(nil)
    end

    frame:SetPoint(
        config.point or "CENTER", UIParent,
        config.relativePoint or "CENTER",
        config.x or -350, config.y or 200
    )
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", function(f) f:StartMoving() end)
    frame:SetScript("OnDragStop", function(f)
        f:StopMovingOrSizing()
        ns.DB:SaveWorldEventOverlayPosition(f)
    end)

    -- 마우스 휠로 스케일 조정
    frame:EnableMouseWheel(true)
    frame:SetScript("OnMouseWheel", function(f, delta)
        setScale(f, delta * SCALE_STEP)
    end)

    -- 타이틀 바 (완전 투명 — 드래그 영역 앵커용)
    local titleBar = CreateFrame("Frame", nil, frame)
    titleBar:SetPoint("TOPLEFT",  frame, "TOPLEFT",  2, -2)
    titleBar:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -2, -2)
    titleBar:SetHeight(TITLE_H)

    local titleText = createFS(frame, 11, 0.80, 0.90, 1.00)
    titleText:SetPoint("LEFT", titleBar, "LEFT", 6, 0)
    titleText:SetText(ns.L("world_event_overlay_title"))
    frame.titleText = titleText

    local toggleBtn = CreateFrame("Button", nil, frame)
    toggleBtn:SetSize(18, 18)
    toggleBtn:SetPoint("RIGHT", titleBar, "RIGHT", -3, 0)
    makeBtnText(toggleBtn, 12, 0.80, 0.80, 1.00)
    toggleBtn:SetText("-")
    frame.toggleBtn = toggleBtn

    -- 컨텐츠 영역
    local content = CreateFrame("Frame", nil, frame)
    content:SetPoint("TOPLEFT", titleBar, "BOTTOMLEFT", 4, -2)
    content:SetPoint("RIGHT",   frame,    "RIGHT",      -4, 0)
    frame.content = content

    frame.rows = {}

    toggleBtn:SetScript("OnClick", function() self:ToggleCollapsed() end)

    -- OnUpdate 드라이버 (1초 간격, 숨김 상태에서 즉시 스킵)
    frame.elapsed = 0
    frame:SetScript("OnUpdate", function(f, elapsed)
        if not f:IsShown() then f.elapsed = 0; return end
        f.elapsed = (f.elapsed or 0) + elapsed
        if f.elapsed >= REFRESH_INTERVAL then
            f.elapsed = 0
            self:UpdateContent()
        end
    end)

    -- 던전/레이드 진입 시 자동 접힘
    frame:RegisterEvent("PLAYER_ENTERING_WORLD")
    frame:SetScript("OnEvent", function(f, event)
        if event == "PLAYER_ENTERING_WORLD" then
            if type(IsInInstance) == "function" then
                local inInst, instType = IsInInstance()
                if inInst and (instType == "party" or instType == "raid") then
                    if not f._autoHidden then
                        f._autoHidden = true
                        f._wasCollapsed = self.collapsed
                        self.collapsed = true
                        self:UpdateLayout()
                    end
                else
                    if f._autoHidden then
                        f._autoHidden = false
                        self.collapsed = f._wasCollapsed or false
                        self:UpdateLayout()
                        self:UpdateContent()
                    end
                end
            end
        end
    end)

    self.frame = frame
    self.collapsed = config.collapsed or false
    frame:SetScale(config.scale or 1)
    return frame
end

-- ============================================================
-- 행 보장
-- ============================================================

function WorldEventOverlay:EnsureRow(index)
    local frame = self.frame
    if not frame then return nil end
    if frame.rows[index] then return frame.rows[index] end

    local row = CreateFrame("Button", nil, frame.content)
    row:SetHeight(ROW_H)
    row:EnableMouse(true)
    row:RegisterForClicks("LeftButtonUp")

    -- 상태 인디케이터 (점)
    local indicator = row:CreateTexture(nil, "OVERLAY")
    indicator:SetSize(6, 6)
    indicator:SetPoint("LEFT", row, "LEFT", 0, 0)
    row.indicator = indicator

    -- 이벤트 이름 (고정 폭, 인디케이터 우측)
    row.nameText = createFS(row, 10, 0.85, 0.85, 1.00)
    row.nameText:SetPoint("LEFT", row, "LEFT", 10, 0)
    row.nameText:SetWidth(COL_NAME_W)
    row.nameText:SetJustifyH("LEFT")

    -- "다음:" / "진행 중" 고정 폭 컬럼 (이름 열 우측)
    row.statusLabel = createFS(row, 9, 0.65, 0.65, 0.70)
    row.statusLabel:SetPoint("LEFT", row, "LEFT", 10 + COL_NAME_W + 4, 0)
    row.statusLabel:SetWidth(COL_STATUS_W)
    row.statusLabel:SetJustifyH("LEFT")

    -- 타이머 (우측 고정)
    row.timerText = createFS(row, 10, 0.96, 0.86, 0.60)
    row.timerText:SetPoint("RIGHT", row, "RIGHT", -2, 0)
    row.timerText:SetWidth(COL_TIMER_W)
    row.timerText:SetJustifyH("RIGHT")

    -- 마우스 오버: 위치 + 완료 힌트 툴팁
    row:SetScript("OnEnter", function(r)
        local evt = r._event
        if not evt then return end
        local locStr = evt.locationKey and ns.L(evt.locationKey)
        GameTooltip:SetOwner(r, "ANCHOR_TOPRIGHT")
        GameTooltip:ClearLines()
        GameTooltip:AddLine(ns.L(evt.labelKey) or evt.key, 1, 1, 1)
        if locStr and locStr ~= evt.locationKey then
            GameTooltip:AddLine(locStr, 0.80, 0.90, 1.00)
        end
        if r._state == "active" and ns.DB then
            local isDone = ns.DB:IsWorldEventCompleted(evt.key)
            if isDone then
                GameTooltip:AddLine(ns.L("world_event_tooltip_unmark"), 0.65, 0.65, 0.65)
            else
                GameTooltip:AddLine(ns.L("world_event_tooltip_mark_done"), 0.65, 0.65, 0.65)
            end
        end
        GameTooltip:Show()
    end)
    row:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    -- 클릭: 완료/미완료 토글
    row:SetScript("OnClick", function(r)
        local evt = r._event
        if evt and r._state == "active" and ns.DB then
            local done = ns.DB:IsWorldEventCompleted(evt.key)
            ns.DB:SetWorldEventCompleted(evt.key, not done)
            self:UpdateContent()
        end
    end)

    frame.rows[index] = row
    return row
end

-- ============================================================
-- 컨텐츠 갱신
-- ============================================================

function WorldEventOverlay:UpdateContent()
    local frame = self.frame
    if not frame or self.collapsed then return end

    local schedule = ns.Data and ns.Data.WorldEventSchedule
    if not schedule or not schedule.events then return end

    local serverTime = GetServerTime and GetServerTime() or 0
    local events = schedule.events
    local yOffset = 0

    for i, event in ipairs(events) do
        local row = self:EnsureRow(i)
        if not row then break end

        local state, secondsLeft = getEventState(event, serverTime)
        local color = event.color or { 0.80, 0.80, 0.80 }
        local isDone = ns.DB and ns.DB:IsWorldEventCompleted(event.key) or false

        row._event = event
        row._state = state

        row:ClearAllPoints()
        row:SetPoint("TOPLEFT", frame.content, "TOPLEFT", 0, -yOffset)
        row:SetPoint("RIGHT",   frame.content, "RIGHT",   0, 0)
        row:Show()

        local eventName = ns.L(event.labelKey) or event.key
        local timer = formatCountdown(secondsLeft)

        if state == "active" then
            if isDone then
                row.indicator:SetColorTexture(0.30, 0.80, 0.30, 0.50)
                row.nameText:SetTextColor(0.48, 0.48, 0.48, 1)
                row.nameText:SetText(DONE_MARK .. eventName)
                row.statusLabel:SetTextColor(0.35, 0.80, 0.35, 0.80)
                row.statusLabel:SetText(ns.L("world_event_active"))
                row.timerText:SetTextColor(0.40, 0.40, 0.40, 1)
                row.timerText:SetText(timer)
            else
                row.indicator:SetColorTexture(0.30, 1.00, 0.30, 1)
                row.nameText:SetTextColor(color[1], color[2], color[3], 1)
                row.nameText:SetText(eventName)
                row.statusLabel:SetTextColor(0.30, 1.00, 0.30, 1)
                row.statusLabel:SetText(ns.L("world_event_active"))
                row.timerText:SetTextColor(0.30, 1.00, 0.30, 1)
                row.timerText:SetText(timer)
            end
        else
            if isDone then
                row.indicator:SetColorTexture(0.30, 0.65, 0.30, 0.40)
                row.nameText:SetTextColor(0.42, 0.42, 0.42, 1)
                row.nameText:SetText(DONE_MARK .. eventName)
            else
                row.indicator:SetColorTexture(0.50, 0.50, 0.50, 0.80)
                row.nameText:SetTextColor(0.65, 0.65, 0.75, 1)
                row.nameText:SetText(eventName)
            end
            row.statusLabel:SetTextColor(0.55, 0.55, 0.62, 1)
            row.statusLabel:SetText(ns.L("world_event_next_label"))
            row.timerText:SetTextColor(0.55, 0.55, 0.60, 1)
            row.timerText:SetText(timer)
        end

        -- 행 클릭: 완료 수동 토글
        if not row._clickHooked then
            row._clickHooked = true
            row:EnableMouse(true)
            row:SetScript("OnMouseDown", function(r)
                if not ns.DB or not r._event then return end
                local key = r._event.key
                local done = ns.DB:IsWorldEventCompleted(key)
                ns.DB:SetWorldEventCompleted(key, not done)
                self:UpdateContent()
            end)
        end

        yOffset = yOffset + ROW_H + ROW_GAP
    end

    for i = #events + 1, #frame.rows do
        frame.rows[i]:Hide()
    end

    self.contentHeight = TITLE_H + 4 + yOffset + PADDING
    self:UpdateLayout()

    -- TomTom 웨이포인트 동기화 (활성 이벤트 → 자동 추가, 비활성 → 자동 제거)
    syncWaypoints(events, serverTime)
end

-- ============================================================
-- QUEST_TURNED_IN 자동 완료 감지
-- ============================================================

function WorldEventOverlay:OnQuestTurnedIn()
    local schedule = ns.Data and ns.Data.WorldEventSchedule
    if not schedule or not schedule.events or not ns.DB then return end

    local currentMapID = C_Map and C_Map.GetBestMapForUnit and C_Map.GetBestMapForUnit("player")
    if not currentMapID then return end

    local serverTime = GetServerTime and GetServerTime() or 0
    for _, event in ipairs(schedule.events) do
        if event.mapID == currentMapID then
            local state = getEventState(event, serverTime)
            if state == "active" and not ns.DB:IsWorldEventCompleted(event.key) then
                ns.DB:SetWorldEventCompleted(event.key, true)
                if self.frame and self.frame:IsShown() then
                    self:UpdateContent()
                end
            end
        end
    end
end

-- ============================================================
-- 레이아웃 / 최소화
-- ============================================================

function WorldEventOverlay:ToggleCollapsed()
    self.collapsed = not self.collapsed
    local config = ns.DB and ns.DB:GetWorldEventOverlayConfig()
    if config then config.collapsed = self.collapsed end
    self:UpdateLayout()
    if not self.collapsed then self:UpdateContent() end
end

function WorldEventOverlay:UpdateLayout()
    local frame = self.frame
    if not frame then return end

    if self.collapsed then
        frame:SetHeight(TITLE_H + 6)
        frame.content:Hide()
        frame.toggleBtn:SetText("+")
    else
        local h = math.max(self.contentHeight or 120, TITLE_H + 30)
        frame:SetHeight(h)
        frame.content:Show()
        frame.toggleBtn:SetText("-")
    end
end

-- ============================================================
-- Refresh / Initialize
-- ============================================================

function WorldEventOverlay:Refresh()
    if not ns.DB or not ns.DB:IsWorldEventOverlayEnabled() then
        if self.frame then self.frame:Hide() end
        return
    end

    if not self.frame then self:EnsureFrame() end
    if not self.frame then return end

    self:UpdateContent()
    self.frame:Show()
end

function WorldEventOverlay:Initialize()
    if self._initialized then return end
    self._initialized = true
    ns.Utils.Debug("[WorldEventOverlay] 초기화 완료")
end
