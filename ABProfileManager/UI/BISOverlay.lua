local _, ns = ...

local BISOverlay = {}
ns.UI.BISOverlay = BISOverlay

-- ============================================================
-- 레이아웃 상수
-- ============================================================

local FRAME_W      = 460
local PADDING      = 10
local ROW_H        = 20
local SECTION_H    = 26
local BOSS_H       = 18
local ICON_SIZE    = 15
local TAB_SIZE     = 24
local TABS_H       = TAB_SIZE + 12   -- 아이콘 + 하단 인디케이터 여백
local TITLE_H      = 26
local MAX_SCROLL_H = 340
local FONT_PATH    = "Fonts\\2002.TTF"
local FONT_FLAGS   = "OUTLINE"

-- 커스텀 스크롤바 치수
local SB_W   = 7    -- 스크롤바 폭
local SB_GAP = 5    -- 스크롤바와 컨텐츠 사이 간격

-- 헤더 총 높이
local HEADER_H  = TITLE_H + 10 + TABS_H + 12  -- = 84

-- 컨텐츠 폭: 스크롤바(+갭+오른쪽 패딩) 제외
local CONTENT_W = FRAME_W - PADDING - (PADDING + SB_W + SB_GAP)  -- = 430

-- 아이템 행 컬럼 레이아웃
local ITEM_INDENT = 16
local ITEM_W      = CONTENT_W - ITEM_INDENT   -- = 414
local COL_ICON    = ICON_SIZE + 5             -- = 20
local COL_NAME    = 210                        -- 아이템 이름 (고정 폭)
local COL_SLOT    = 58                         -- 부위 슬롯
local COL_NOTE    = 52                         -- BIS/대체 배지

-- 아이템 품질 색상
local QC = {
    [0] = { 0.55, 0.55, 0.55 },
    [1] = { 0.85, 0.85, 0.85 },
    [2] = { 0.12, 1.00, 0.00 },
    [3] = { 0.20, 0.65, 1.00 },
    [4] = { 0.80, 0.35, 1.00 },
    [5] = { 1.00, 0.55, 0.00 },
}

-- note 배지 표시 텍스트 (한국어)
local NOTE_TEXT = {
    ["BIS"]  = "|cffffc000최선|r",
    ["대체재"] = "|cff44aaff대체|r",
    ["2순위"] = "|cff55cc5522순|r",
}

-- ============================================================
-- Helper 함수들
-- ============================================================

local function getClassSpecs()
    if not UnitClass or not GetNumSpecializationsForClassID
    or not GetSpecializationInfoForClassID then return {} end
    local _, _, classID = UnitClass("player")
    if not classID then return {} end
    local specs = {}
    local n = GetNumSpecializationsForClassID(classID)
    for i = 1, n do
        local ok, specID, name, _, icon = pcall(GetSpecializationInfoForClassID, classID, i)
        if ok and specID then
            specs[#specs + 1] = { specID = specID, name = name, icon = icon }
        end
    end
    return specs
end

local function getPlayerSpecID()
    if not GetSpecialization or not GetSpecializationInfo then return nil end
    local idx = GetSpecialization()
    if not idx then return nil end
    local ok, specID = pcall(GetSpecializationInfo, idx)
    if ok and specID then return specID end
    return nil
end

local function groupByDungeon(items)
    local dungeons, order = {}, {}
    for _, item in ipairs(items) do
        local k = item.dungeon or "?"
        if not dungeons[k] then dungeons[k] = {}; order[#order + 1] = k end
        dungeons[k][#dungeons[k] + 1] = item
    end
    return dungeons, order
end

-- ============================================================
-- 아이템 정보 로드 이벤트 → 디바운스 재빌드
-- ============================================================

local _rebuildPending = false
local function scheduleRebuild()
    if _rebuildPending then return end
    _rebuildPending = true
    C_Timer.After(0.3, function()
        _rebuildPending = false
        if BISOverlay.frame and BISOverlay.frame:IsShown() then
            pcall(function() BISOverlay:RebuildContent() end)
        end
    end)
end

-- ============================================================
-- 스크롤바 썸 업데이트
-- ============================================================

function BISOverlay:UpdateScrollThumb()
    local frame = self.frame
    if not frame or not frame.scrollBarThumb then return end
    local sf        = frame.scrollFrame
    local contentH  = frame.content:GetHeight()
    local sfH       = math.max(1, sf:GetHeight())
    local trackH    = math.max(1, frame.scrollBarTrack:GetHeight())

    if contentH <= sfH then
        frame.scrollBarThumb:Hide()
        return
    end

    frame.scrollBarThumb:Show()
    local ratio  = sfH / contentH
    local thumbH = math.max(22, trackH * ratio)
    frame.scrollBarThumb:SetHeight(thumbH)

    local scrollRange = math.max(1, sf:GetVerticalScrollRange())
    local scrollPos   = sf:GetVerticalScroll()
    local thumbTravel = trackH - thumbH
    local thumbY      = -(scrollPos / scrollRange * thumbTravel)
    frame.scrollBarThumb:ClearAllPoints()
    frame.scrollBarThumb:SetPoint("TOPRIGHT", frame.scrollBarTrack, "TOPRIGHT", 0, thumbY)
end

-- ============================================================
-- 잠금 버튼 상태 업데이트
-- ============================================================

function BISOverlay:UpdateLockBtn()
    local frame = self.frame
    if not frame or not frame.lockBtn then return end
    local locked = ns.DB and ns.DB:IsBISOverlayLocked()
    if locked then
        frame.lockBtn.bg:SetColorTexture(0.90, 0.75, 0.15, 0.85)
        frame.lockBtn.label:SetTextColor(0.08, 0.05, 0.02, 1)
        frame.lockBtn.label:SetText("잠")
    else
        frame.lockBtn.bg:SetColorTexture(0.12, 0.12, 0.22, 0.75)
        frame.lockBtn.label:SetTextColor(0.55, 0.55, 0.65, 1)
        frame.lockBtn.label:SetText("잠")
    end
end

-- ============================================================
-- 프레임 생성
-- ============================================================

function BISOverlay:EnsureFrame()
    if self.frame then return self.frame end

    local frame = CreateFrame("Frame", "ABPMBISOverlay", UIParent, "BackdropTemplate")
    frame:SetFrameStrata("DIALOG")
    frame:SetFrameLevel(100)
    frame:SetClampedToScreen(true)
    frame:SetSize(FRAME_W, HEADER_H + 60)

    if frame.SetBackdrop then
        frame:SetBackdrop({
            bgFile   = "Interface\\Tooltips\\UI-Tooltip-Background",
            edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
            tile = true, tileSize = 8, edgeSize = 18,
            insets = { left = 5, right = 5, top = 5, bottom = 5 },
        })
        frame:SetBackdropColor(0.03, 0.04, 0.10, 0.96)
        frame:SetBackdropBorderColor(0.50, 0.40, 0.80, 0.90)
    end

    -- 드래그 (잠금 상태 확인)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", function(f)
        if ns.DB and ns.DB:IsBISOverlayLocked() then return end
        f:StartMoving()
    end)
    frame:SetScript("OnDragStop",  function(f) f:StopMovingOrSizing() end)
    frame:SetScript("OnHide",      function(f) f:StopMovingOrSizing() end)

    -- ─── 제목 바 배경 ───────────────────────────────────────
    local titleBar = frame:CreateTexture(nil, "BACKGROUND")
    titleBar:SetHeight(TITLE_H + 14)
    titleBar:SetPoint("TOPLEFT",  frame, "TOPLEFT",  5,  -5)
    titleBar:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -5, -5)
    titleBar:SetColorTexture(0.10, 0.07, 0.22, 0.90)

    -- 제목 텍스트
    frame.titleText = frame:CreateFontString(nil, "OVERLAY")
    frame.titleText:SetFont(FONT_PATH, 13, FONT_FLAGS)
    frame.titleText:SetPoint("TOPLEFT", frame, "TOPLEFT", PADDING + 2, -10)
    frame.titleText:SetTextColor(0.92, 0.82, 1.0, 1)
    frame.titleText:SetText(ns.L("bis_overlay_title"))

    -- M+ 배지
    local mpBadge = frame:CreateFontString(nil, "OVERLAY")
    mpBadge:SetFont(FONT_PATH, 10, FONT_FLAGS)
    mpBadge:SetPoint("LEFT", frame.titleText, "RIGHT", 6, 1)
    mpBadge:SetTextColor(0.20, 0.80, 1.0, 1)
    mpBadge:SetText("M+")

    -- ─── 잠금 버튼 ──────────────────────────────────────────
    local lockBtn = CreateFrame("Button", nil, frame)
    lockBtn:SetSize(18, 18)
    lockBtn:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -PADDING, -9)

    lockBtn.bg = lockBtn:CreateTexture(nil, "BACKGROUND")
    lockBtn.bg:SetAllPoints()
    lockBtn.bg:SetColorTexture(0.12, 0.12, 0.22, 0.75)

    lockBtn.label = lockBtn:CreateFontString(nil, "OVERLAY")
    lockBtn.label:SetFont(FONT_PATH, 9, FONT_FLAGS)
    lockBtn.label:SetAllPoints()
    lockBtn.label:SetJustifyH("CENTER")
    lockBtn.label:SetJustifyV("MIDDLE")
    lockBtn.label:SetText("잠")
    lockBtn.label:SetTextColor(0.55, 0.55, 0.65, 1)

    lockBtn:SetScript("OnClick", function()
        if not ns.DB then return end
        ns.DB:SetBISOverlayLocked(not ns.DB:IsBISOverlayLocked())
        self:UpdateLockBtn()
    end)
    lockBtn:SetScript("OnEnter", function(self2)
        GameTooltip:SetOwner(self2, "ANCHOR_BOTTOM")
        local locked = ns.DB and ns.DB:IsBISOverlayLocked()
        GameTooltip:SetText(locked and "이동 잠금 해제" or "이동 잠금", 1, 1, 1, 1, true)
        GameTooltip:Show()
    end)
    lockBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)
    frame.lockBtn = lockBtn

    -- ─── 구분선 1 ───────────────────────────────────────────
    local sep1 = frame:CreateTexture(nil, "ARTWORK")
    sep1:SetHeight(1)
    sep1:SetPoint("TOPLEFT",  frame, "TOPLEFT",  PADDING,  -(TITLE_H + 10))
    sep1:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -PADDING, -(TITLE_H + 10))
    sep1:SetColorTexture(0.45, 0.35, 0.70, 0.65)

    -- ─── 스펙 탭 영역 ────────────────────────────────────────
    frame.tabsFrame = CreateFrame("Frame", nil, frame)
    frame.tabsFrame:SetPoint("TOPLEFT",  frame, "TOPLEFT",  PADDING,  -(TITLE_H + 12))
    frame.tabsFrame:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -PADDING, -(TITLE_H + 12))
    frame.tabsFrame:SetHeight(TABS_H)
    frame.tabs = {}

    -- ─── 구분선 2 ───────────────────────────────────────────
    local sep2 = frame:CreateTexture(nil, "ARTWORK")
    sep2:SetHeight(1)
    sep2:SetPoint("TOPLEFT",  frame, "TOPLEFT",  PADDING,  -(TITLE_H + 12 + TABS_H + 4))
    sep2:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -PADDING, -(TITLE_H + 12 + TABS_H + 4))
    sep2:SetColorTexture(0.45, 0.35, 0.70, 0.45)

    -- ─── 스크롤 프레임 ──────────────────────────────────────
    frame.scrollFrame = CreateFrame("ScrollFrame", nil, frame)
    frame.scrollFrame:SetPoint("TOPLEFT",     frame, "TOPLEFT",
        PADDING, -HEADER_H)
    frame.scrollFrame:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT",
        -(PADDING + SB_W + SB_GAP), PADDING)
    frame.scrollFrame:EnableMouseWheel(true)
    frame.scrollFrame:SetScript("OnMouseWheel", function(sf, delta)
        local cur = sf:GetVerticalScroll()
        local max = sf:GetVerticalScrollRange()
        sf:SetVerticalScroll(math.max(0, math.min(max, cur - delta * 24)))
        self:UpdateScrollThumb()
    end)
    frame.scrollFrame:SetScript("OnScrollRangeChanged", function()
        self:UpdateScrollThumb()
    end)

    -- ─── 스크롤 자식 ────────────────────────────────────────
    frame.content = CreateFrame("Frame", nil, frame.scrollFrame)
    frame.content:SetSize(CONTENT_W, 1)
    frame.scrollFrame:SetScrollChild(frame.content)

    -- ─── 커스텀 스크롤바 트랙 ───────────────────────────────
    frame.scrollBarTrack = frame:CreateTexture(nil, "ARTWORK")
    frame.scrollBarTrack:SetWidth(SB_W)
    frame.scrollBarTrack:SetPoint("TOPRIGHT",    frame, "TOPRIGHT",    -PADDING, -HEADER_H)
    frame.scrollBarTrack:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -PADDING,  PADDING)
    frame.scrollBarTrack:SetColorTexture(0.05, 0.05, 0.12, 0.85)

    -- 트랙 좌측 미묘한 하이라이트 선
    local sbEdge = frame:CreateTexture(nil, "ARTWORK")
    sbEdge:SetWidth(1)
    sbEdge:SetPoint("TOPRIGHT",    frame.scrollBarTrack, "TOPLEFT",    0, 0)
    sbEdge:SetPoint("BOTTOMRIGHT", frame.scrollBarTrack, "BOTTOMLEFT", 0, 0)
    sbEdge:SetColorTexture(0.30, 0.20, 0.55, 0.60)

    -- ─── 커스텀 스크롤바 썸 ─────────────────────────────────
    frame.scrollBarThumb = CreateFrame("Frame", nil, frame)
    frame.scrollBarThumb:SetWidth(SB_W)
    frame.scrollBarThumb:SetHeight(40)
    frame.scrollBarThumb:SetPoint("TOPRIGHT", frame.scrollBarTrack, "TOPRIGHT", 0, 0)
    frame.scrollBarThumb:Hide()

    local thumbTex = frame.scrollBarThumb:CreateTexture(nil, "ARTWORK")
    thumbTex:SetAllPoints()
    thumbTex:SetColorTexture(0.55, 0.35, 0.88, 0.88)

    -- 썸 드래그
    local _dragging, _dragY, _dragScroll = false, 0, 0
    frame.scrollBarThumb:EnableMouse(true)
    frame.scrollBarThumb:SetScript("OnMouseDown", function(_, button)
        if button ~= "LeftButton" then return end
        _dragging  = true
        _dragY     = select(2, GetCursorPosition()) / UIParent:GetEffectiveScale()
        _dragScroll = frame.scrollFrame:GetVerticalScroll()
    end)
    frame.scrollBarThumb:SetScript("OnMouseUp", function()
        _dragging = false
    end)
    frame.scrollBarThumb:SetScript("OnUpdate", function()
        if not _dragging then return end
        local curY    = select(2, GetCursorPosition()) / UIParent:GetEffectiveScale()
        local dy      = _dragY - curY
        local trackH  = math.max(1, frame.scrollBarTrack:GetHeight())
        local thumbH  = math.max(1, frame.scrollBarThumb:GetHeight())
        local maxS    = frame.scrollFrame:GetVerticalScrollRange()
        local frac    = dy / (trackH - thumbH)
        local newS    = math.max(0, math.min(maxS, _dragScroll + frac * maxS))
        frame.scrollFrame:SetVerticalScroll(newS)
        self:UpdateScrollThumb()
    end)

    -- GET_ITEM_INFO_RECEIVED 이벤트
    local evFrame = CreateFrame("Frame")
    evFrame:RegisterEvent("GET_ITEM_INFO_RECEIVED")
    evFrame:SetScript("OnEvent", function(_, _, _, success)
        if success then scheduleRebuild() end
    end)

    frame.rows = {}
    self.frame = frame
    return frame
end

-- ============================================================
-- 스펙 탭 생성/업데이트
-- ============================================================

function BISOverlay:EnsureTabs()
    local frame = self.frame
    if not frame then return end
    local specs = getClassSpecs()
    if #specs == 0 then return end
    if #frame.tabs == #specs then
        self:UpdateTabHighlight()
        return
    end

    for _, tab in ipairs(frame.tabs) do tab:Hide() end
    frame.tabs = {}

    for i, spec in ipairs(specs) do
        local tab = CreateFrame("Button", nil, frame.tabsFrame)
        tab:SetSize(TAB_SIZE, TAB_SIZE)
        tab:SetPoint("TOPLEFT", frame.tabsFrame, "TOPLEFT", (i - 1) * (TAB_SIZE + 8), 0)

        -- 아이콘
        tab.icon = tab:CreateTexture(nil, "ARTWORK")
        tab.icon:SetAllPoints()
        if spec.icon then
            tab.icon:SetTexture(spec.icon)
            tab.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
        end

        -- 하단 활성 인디케이터 바 (아이콘 바로 아래 2px 선)
        tab.indicator = tab:CreateTexture(nil, "OVERLAY")
        tab.indicator:SetHeight(2)
        tab.indicator:SetPoint("BOTTOMLEFT",  tab, "BOTTOMLEFT",  0, -3)
        tab.indicator:SetPoint("BOTTOMRIGHT", tab, "BOTTOMRIGHT", 0, -3)
        tab.indicator:SetColorTexture(0, 0, 0, 0)

        -- 마우스 오버 하이라이트
        tab.highlight = tab:CreateTexture(nil, "HIGHLIGHT")
        tab.highlight:SetAllPoints()
        tab.highlight:SetColorTexture(1, 1, 1, 0.12)

        tab.specID   = spec.specID
        tab.specName = spec.name

        tab:SetScript("OnEnter", function(self2)
            GameTooltip:SetOwner(self2, "ANCHOR_BOTTOM")
            GameTooltip:SetText(spec.name, 1, 1, 1, 1, true)
            GameTooltip:Show()
        end)
        tab:SetScript("OnLeave", function() GameTooltip:Hide() end)
        tab:SetScript("OnClick", function()
            BISOverlay.selectedSpecID = spec.specID
            BISOverlay:UpdateTabHighlight()
            BISOverlay:RebuildContent()
        end)

        frame.tabs[i] = tab
    end

    self:UpdateTabHighlight()
end

function BISOverlay:UpdateTabHighlight()
    local frame = self.frame
    if not frame then return end
    local activeID = self.selectedSpecID or getPlayerSpecID()
    for _, tab in ipairs(frame.tabs) do
        if tab.specID == activeID then
            tab.icon:SetDesaturated(false)
            tab.icon:SetAlpha(1.0)
            tab.indicator:SetColorTexture(0.20, 0.85, 1.0, 1.0)  -- 밝은 시안
        else
            tab.icon:SetDesaturated(true)
            tab.icon:SetAlpha(0.40)
            tab.indicator:SetColorTexture(0, 0, 0, 0)
        end
    end
end

-- ============================================================
-- 행 생성/재사용
-- ============================================================

local function ensureRow(frame, index)
    if frame.rows[index] then return frame.rows[index] end

    local row = CreateFrame("Frame", nil, frame.content)
    row:SetHeight(ROW_H)

    row.bg = row:CreateTexture(nil, "BACKGROUND")
    row.bg:SetAllPoints()
    row.bg:SetColorTexture(0, 0, 0, 0)

    row.accent = row:CreateTexture(nil, "ARTWORK")
    row.accent:SetWidth(3)
    row.accent:SetPoint("TOPLEFT",    row, "TOPLEFT",    0, 0)
    row.accent:SetPoint("BOTTOMLEFT", row, "BOTTOMLEFT", 0, 0)
    row.accent:SetColorTexture(0, 0, 0, 0)

    row.icon = row:CreateTexture(nil, "ARTWORK")
    row.icon:SetSize(ICON_SIZE, ICON_SIZE)
    row.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    row.icon:Hide()

    row.nameLabel = row:CreateFontString(nil, "OVERLAY")
    row.nameLabel:SetFont(FONT_PATH, 11, FONT_FLAGS)
    row.nameLabel:SetJustifyH("LEFT")
    row.nameLabel:SetJustifyV("MIDDLE")
    row.nameLabel:SetPoint("TOPLEFT", row, "TOPLEFT", 0, -1)
    row.nameLabel:SetWidth(200)

    row.slotLabel = row:CreateFontString(nil, "OVERLAY")
    row.slotLabel:SetFont(FONT_PATH, 10, FONT_FLAGS)
    row.slotLabel:SetJustifyH("CENTER")
    row.slotLabel:SetJustifyV("MIDDLE")
    row.slotLabel:SetWidth(COL_SLOT)
    row.slotLabel:Hide()

    row.noteLabel = row:CreateFontString(nil, "OVERLAY")
    row.noteLabel:SetFont(FONT_PATH, 10, FONT_FLAGS)
    row.noteLabel:SetJustifyH("CENTER")
    row.noteLabel:SetJustifyV("MIDDLE")
    row.noteLabel:SetWidth(COL_NOTE)
    row.noteLabel:Hide()

    row.tooltipRegion = CreateFrame("Frame", nil, row)
    row.tooltipRegion:SetAllPoints(row)
    row.tooltipRegion:EnableMouse(true)
    row.tooltipRegion:SetScript("OnEnter", function(self2)
        if row.itemID and row.itemID > 0 then
            GameTooltip:SetOwner(self2, "ANCHOR_RIGHT")
            GameTooltip:SetItemByID(row.itemID)
            GameTooltip:Show()
        end
    end)
    row.tooltipRegion:SetScript("OnLeave", function() GameTooltip:Hide() end)

    frame.rows[index] = row
    return row
end

local function resetRow(row)
    row.bg:SetColorTexture(0, 0, 0, 0)
    row.accent:SetColorTexture(0, 0, 0, 0)
    row.icon:Hide()
    row.slotLabel:Hide()
    row.noteLabel:Hide()
    row.itemID = nil
end

-- ============================================================
-- 컨텐츠 빌드
-- ============================================================

function BISOverlay:RebuildContent()
    local frame = self.frame
    if not frame then return end

    local specID  = self.selectedSpecID or getPlayerSpecID()
    local bisData = ns.Data and ns.Data.BISItems and ns.Data.BISItems[specID]

    ns.Utils.Debug(string.format("[BISOverlay] specID=%s bisData=%s",
        tostring(specID), bisData and (#bisData .. "개") or "nil"))

    for _, row in ipairs(frame.rows) do
        row:Hide()
        resetRow(row)
    end

    local yOffset  = 0
    local rowIndex = 0

    if not bisData or #bisData == 0 then
        rowIndex = rowIndex + 1
        local row = ensureRow(frame, rowIndex)
        row:ClearAllPoints()
        row:SetPoint("TOPLEFT", frame.content, "TOPLEFT", 0, -yOffset)
        row:SetWidth(CONTENT_W)
        row:SetHeight(ROW_H + 4)
        row.nameLabel:ClearAllPoints()
        row.nameLabel:SetPoint("LEFT", row, "LEFT", 4, 0)
        row.nameLabel:SetWidth(CONTENT_W - 8)
        row.nameLabel:SetFont(FONT_PATH, 11, FONT_FLAGS)
        row.nameLabel:SetTextColor(0.45, 0.45, 0.45, 1)
        row.nameLabel:SetText((ns.L("bis_overlay_no_data") or "no data")
            .. "  (spec " .. tostring(specID) .. ")")
        row:Show()
        yOffset = yOffset + ROW_H + 4
    else
        local dungeons, order = groupByDungeon(bisData)
        local itemRowCount = 0

        for _, dungeonName in ipairs(order) do
            -- ─── 던전 헤더 ───────────────────────────────────
            rowIndex = rowIndex + 1
            local hdr = ensureRow(frame, rowIndex)
            hdr:ClearAllPoints()
            hdr:SetPoint("TOPLEFT", frame.content, "TOPLEFT", 0, -yOffset)
            hdr:SetWidth(CONTENT_W)
            hdr:SetHeight(SECTION_H)
            hdr.bg:SetColorTexture(0.08, 0.11, 0.20, 0.88)
            hdr.accent:SetColorTexture(0.25, 0.70, 1.0, 1.0)
            hdr.nameLabel:ClearAllPoints()
            hdr.nameLabel:SetPoint("LEFT", hdr, "LEFT", 8, 0)
            hdr.nameLabel:SetWidth(CONTENT_W - 12)
            hdr.nameLabel:SetFont(FONT_PATH, 12, FONT_FLAGS)
            hdr.nameLabel:SetTextColor(0.55, 0.88, 1.0, 1)
            hdr.nameLabel:SetText(dungeonName)
            hdr:Show()
            yOffset = yOffset + SECTION_H + 1

            local items = dungeons[dungeonName]
            local prevBoss = nil

            for _, entry in ipairs(items) do
                -- ─── 보스 행 ─────────────────────────────────
                if entry.boss ~= prevBoss then
                    prevBoss = entry.boss
                    rowIndex = rowIndex + 1
                    local bRow = ensureRow(frame, rowIndex)
                    bRow:ClearAllPoints()
                    bRow:SetPoint("TOPLEFT", frame.content, "TOPLEFT", 5, -yOffset)
                    bRow:SetWidth(CONTENT_W - 5)
                    bRow:SetHeight(BOSS_H)
                    bRow.nameLabel:ClearAllPoints()
                    bRow.nameLabel:SetPoint("LEFT", bRow, "LEFT", 0, 0)
                    bRow.nameLabel:SetWidth(CONTENT_W - 5)
                    bRow.nameLabel:SetFont(FONT_PATH, 11, FONT_FLAGS)
                    bRow.nameLabel:SetTextColor(0.98, 0.82, 0.38, 1)
                    bRow.nameLabel:SetText("|cffcc8800> |r" .. (entry.boss or "?"))
                    bRow:Show()
                    yOffset = yOffset + BOSS_H + 2
                end

                -- ─── 아이템 행 ───────────────────────────────
                rowIndex = rowIndex + 1
                itemRowCount = itemRowCount + 1
                local iRow = ensureRow(frame, rowIndex)
                iRow:ClearAllPoints()
                iRow:SetPoint("TOPLEFT", frame.content, "TOPLEFT", ITEM_INDENT, -yOffset)
                iRow:SetWidth(ITEM_W)
                iRow:SetHeight(ROW_H)
                iRow.itemID = entry.itemID

                -- 교번 배경
                if itemRowCount % 2 == 0 then
                    iRow.bg:SetColorTexture(0.06, 0.08, 0.14, 0.55)
                else
                    iRow.bg:SetColorTexture(0.04, 0.05, 0.10, 0.28)
                end

                -- GetItemInfo 조회
                local itemName, quality, texture
                if entry.itemID and entry.itemID > 0 then
                    local ok, n, _, q, _, _, _, _, _, _, tex = pcall(GetItemInfo, entry.itemID)
                    if ok and n then
                        itemName = n
                        quality  = q
                        texture  = tex
                    end
                end

                -- 아이콘
                if texture then
                    iRow.icon:SetTexture(texture)
                    iRow.icon:SetPoint("LEFT", iRow, "LEFT", 0, 0)
                    iRow.icon:Show()
                else
                    iRow.icon:Hide()
                end

                -- 이름 라벨 (아이콘 우측, 고정 폭으로 슬롯 컬럼 위치 보장)
                local nameX = texture and COL_ICON or 0
                local nameW = COL_NAME + (texture and 0 or COL_ICON)
                iRow.nameLabel:ClearAllPoints()
                iRow.nameLabel:SetPoint("LEFT", iRow, "LEFT", nameX, 0)
                iRow.nameLabel:SetWidth(nameW)
                iRow.nameLabel:SetFont(FONT_PATH, 11, FONT_FLAGS)

                if itemName then
                    -- M+ 기준: 최소 에픽(4=보라), 전설(5=주황)은 유지
                    local effectiveQ = math.max(quality or 4, 4)
                    local qc = QC[effectiveQ] or QC[4]
                    iRow.nameLabel:SetTextColor(qc[1], qc[2], qc[3], 1)
                    iRow.nameLabel:SetText(itemName)
                else
                    iRow.nameLabel:SetTextColor(QC[4][1], QC[4][2], QC[4][3], 0.50)
                    iRow.nameLabel:SetText("...")
                end

                -- 슬롯 라벨
                if entry.slot then
                    iRow.slotLabel:ClearAllPoints()
                    iRow.slotLabel:SetPoint("LEFT", iRow, "LEFT", COL_ICON + COL_NAME, 0)
                    iRow.slotLabel:SetWidth(COL_SLOT)
                    iRow.slotLabel:SetFont(FONT_PATH, 10, FONT_FLAGS)
                    iRow.slotLabel:SetTextColor(0.72, 0.72, 0.72, 1)
                    iRow.slotLabel:SetText(entry.slot)
                    iRow.slotLabel:Show()
                end

                -- note 배지
                local noteTxt = NOTE_TEXT[entry.note]
                    or (entry.note and ("|cff888888" .. entry.note .. "|r"))
                if noteTxt then
                    iRow.noteLabel:ClearAllPoints()
                    iRow.noteLabel:SetPoint("LEFT", iRow, "LEFT",
                        COL_ICON + COL_NAME + COL_SLOT, 0)
                    iRow.noteLabel:SetWidth(COL_NOTE)
                    iRow.noteLabel:SetFont(FONT_PATH, 10, FONT_FLAGS)
                    iRow.noteLabel:SetTextColor(1, 1, 1, 1)
                    iRow.noteLabel:SetText(noteTxt)
                    iRow.noteLabel:Show()
                end

                iRow:Show()
                yOffset = yOffset + ROW_H + 1
            end

            yOffset = yOffset + 6
        end
    end

    -- 높이 갱신
    frame.content:SetHeight(math.max(1, yOffset))
    local visH   = math.min(MAX_SCROLL_H, yOffset)
    local totalH = HEADER_H + math.max(20, visH) + PADDING
    frame:SetHeight(totalH)

    -- 스크롤 초기화 및 썸 업데이트 (레이아웃 확정 후)
    frame.scrollFrame:SetVerticalScroll(0)
    C_Timer.After(0, function() self:UpdateScrollThumb() end)
end

-- ============================================================
-- Refresh
-- ============================================================

function BISOverlay:Refresh()
    if not ns.DB or not ns.DB:IsBISOverlayEnabled() then
        if self.frame then self.frame:Hide() end
        return
    end

    local pve = PVEFrame or LFGParentFrame
    if not pve or not pve:IsShown() then
        if self.frame then self.frame:Hide() end
        return
    end

    self:EnsureFrame()
    if not self.frame then return end

    self:EnsureTabs()
    self:UpdateLockBtn()

    self.frame:ClearAllPoints()
    local ilFrame = ns.UI.ItemLevelOverlay and ns.UI.ItemLevelOverlay.frame
    if ilFrame and ilFrame:IsShown() then
        self.frame:SetPoint("TOPLEFT", ilFrame, "TOPRIGHT", 6, 0)
    else
        self.frame:SetPoint("TOPLEFT", pve, "TOPRIGHT", 10, 0)
    end

    local ok, err = pcall(function() self:RebuildContent() end)
    if not ok then
        ns.Utils.Debug("[BISOverlay] RebuildContent 오류: " .. tostring(err))
    end
    self.frame:Show()
end

-- ============================================================
-- Initialize
-- ============================================================

function BISOverlay:Initialize()
    if self._initialized then return end
    self._initialized = true

    local function setupPVEHooks()
        local pve = PVEFrame or LFGParentFrame
        if not pve then return false end

        pve:HookScript("OnShow", function()
            if not ns.DB or not ns.DB:IsBISOverlayEnabled() then return end
            self:Refresh()
        end)
        pve:HookScript("OnHide", function()
            if self.frame then self.frame:Hide() end
        end)

        if pve:IsShown() and ns.DB and ns.DB:IsBISOverlayEnabled() then
            self:Refresh()
        end
        return true
    end

    if not setupPVEHooks() then
        local watchFrame = CreateFrame("Frame")
        watchFrame:RegisterEvent("ADDON_LOADED")
        watchFrame:SetScript("OnEvent", function(f, _, name)
            if name == "Blizzard_LookingForGroup" then
                setupPVEHooks()
                f:UnregisterEvent("ADDON_LOADED")
                f:SetScript("OnEvent", nil)
            end
        end)
    end
end
