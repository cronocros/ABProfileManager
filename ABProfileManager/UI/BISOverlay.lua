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
local TABS_H       = TAB_SIZE + 10
local TITLE_H      = 26
local MAX_SCROLL_H = 340
local FONT_PATH    = "Fonts\\2002.TTF"
local FONT_FLAGS   = "OUTLINE"

-- 제목 + 탭 영역 높이
local HEADER_H  = TITLE_H + 10 + TABS_H + 12  -- = 82

-- 유효 컨텐츠 폭 (스크롤바 공간 확보)
local CONTENT_W = FRAME_W - PADDING * 2 - 28   -- = 412

-- 아이템 행 컬럼 레이아웃
local ITEM_INDENT = 16
local ITEM_W      = CONTENT_W - ITEM_INDENT    -- = 396
local COL_ICON    = ICON_SIZE + 5              -- = 20
local COL_SLOT    = 52
local COL_NOTE    = 50
local COL_NAME    = ITEM_W - COL_ICON - COL_SLOT - COL_NOTE  -- = 274

-- 아이템 품질 색상 (M+ 기준)
local QC = {
    [0] = { 0.55, 0.55, 0.55 },
    [1] = { 0.85, 0.85, 0.85 },
    [2] = { 0.12, 1.00, 0.00 },
    [3] = { 0.20, 0.65, 1.00 },
    [4] = { 0.80, 0.35, 1.00 },
    [5] = { 1.00, 0.55, 0.00 },
}

-- note 배지 텍스트 (색상 포함)
local NOTE_TEXT = {
    ["BIS"]  = "|cffffd000BIS|r",
    ["대체재"] = "|cff44aaffALT|r",
    ["2순위"] = "|cff55dd552nd|r",
}

-- ============================================================
-- Helper: 클래스 스펙 목록
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
-- 아이템 정보 로드 이벤트 -> 디바운스 재빌드
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

    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", function(f) f:StartMoving() end)
    frame:SetScript("OnDragStop",  function(f) f:StopMovingOrSizing() end)
    frame:SetScript("OnHide",      function(f) f:StopMovingOrSizing() end)

    -- 제목 바 배경
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

    -- M+ 배지 텍스트
    local mpBadge = frame:CreateFontString(nil, "OVERLAY")
    mpBadge:SetFont(FONT_PATH, 10, FONT_FLAGS)
    mpBadge:SetPoint("LEFT", frame.titleText, "RIGHT", 8, 1)
    mpBadge:SetTextColor(0.20, 0.80, 1.0, 1)
    mpBadge:SetText("M+")

    -- 구분선 1
    local sep1 = frame:CreateTexture(nil, "ARTWORK")
    sep1:SetHeight(1)
    sep1:SetPoint("TOPLEFT",  frame, "TOPLEFT",  PADDING,  -(TITLE_H + 10))
    sep1:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -PADDING, -(TITLE_H + 10))
    sep1:SetColorTexture(0.45, 0.35, 0.70, 0.65)

    -- 스펙 탭 영역
    frame.tabsFrame = CreateFrame("Frame", nil, frame)
    frame.tabsFrame:SetPoint("TOPLEFT",  frame, "TOPLEFT",  PADDING,  -(TITLE_H + 12))
    frame.tabsFrame:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -PADDING, -(TITLE_H + 12))
    frame.tabsFrame:SetHeight(TABS_H)
    frame.tabs = {}

    -- 구분선 2
    local sep2 = frame:CreateTexture(nil, "ARTWORK")
    sep2:SetHeight(1)
    sep2:SetPoint("TOPLEFT",  frame, "TOPLEFT",  PADDING,  -(TITLE_H + 12 + TABS_H + 4))
    sep2:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -PADDING, -(TITLE_H + 12 + TABS_H + 4))
    sep2:SetColorTexture(0.45, 0.35, 0.70, 0.45)

    -- 스크롤 프레임 (UIPanelScrollFrameTemplate)
    frame.scrollFrame = CreateFrame("ScrollFrame", "ABPMBISOverlayScroll",
        frame, "UIPanelScrollFrameTemplate")
    frame.scrollFrame:SetPoint("TOPLEFT",     frame, "TOPLEFT",     PADDING,   -HEADER_H)
    frame.scrollFrame:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -PADDING,   PADDING)
    frame.scrollFrame:EnableMouseWheel(true)
    frame.scrollFrame:SetScript("OnMouseWheel", function(sf, delta)
        local cur = sf:GetVerticalScroll()
        local max = sf:GetVerticalScrollRange()
        sf:SetVerticalScroll(math.max(0, math.min(max, cur - delta * 24)))
    end)

    -- 스크롤 자식 (컨텐츠)
    frame.content = CreateFrame("Frame", nil, frame.scrollFrame)
    frame.content:SetSize(CONTENT_W, 1)
    frame.scrollFrame:SetScrollChild(frame.content)

    -- GET_ITEM_INFO_RECEIVED 이벤트 처리 (아이콘 지연 로드)
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
        tab:SetPoint("TOPLEFT", frame.tabsFrame, "TOPLEFT", (i - 1) * (TAB_SIZE + 6), -1)

        -- 선택 배경
        tab.bg = tab:CreateTexture(nil, "BACKGROUND")
        tab.bg:SetPoint("TOPLEFT",     tab, "TOPLEFT",     -2,  2)
        tab.bg:SetPoint("BOTTOMRIGHT", tab, "BOTTOMRIGHT",  2, -2)
        tab.bg:SetColorTexture(0, 0, 0, 0)

        -- 스펙 아이콘
        tab.icon = tab:CreateTexture(nil, "ARTWORK")
        tab.icon:SetAllPoints()
        if spec.icon then
            tab.icon:SetTexture(spec.icon)
            tab.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
        end

        -- 황금 테두리 (활성 탭)
        tab.border = tab:CreateTexture(nil, "OVERLAY")
        tab.border:SetPoint("TOPLEFT",     tab, "TOPLEFT",     -2,  2)
        tab.border:SetPoint("BOTTOMRIGHT", tab, "BOTTOMRIGHT",  2, -2)
        tab.border:SetColorTexture(0.90, 0.75, 0.10, 0)

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
            tab.border:SetColorTexture(0.90, 0.75, 0.10, 0.85)
            tab.bg:SetColorTexture(0.90, 0.75, 0.10, 0.20)
        else
            tab.icon:SetDesaturated(true)
            tab.icon:SetAlpha(0.45)
            tab.border:SetColorTexture(0, 0, 0, 0)
            tab.bg:SetColorTexture(0, 0, 0, 0)
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

    -- 배경 (던전 헤더 / 교번 아이템 배경용)
    row.bg = row:CreateTexture(nil, "BACKGROUND")
    row.bg:SetAllPoints()
    row.bg:SetColorTexture(0, 0, 0, 0)

    -- 좌측 악센트 바
    row.accent = row:CreateTexture(nil, "ARTWORK")
    row.accent:SetWidth(3)
    row.accent:SetPoint("TOPLEFT",    row, "TOPLEFT",    0, 0)
    row.accent:SetPoint("BOTTOMLEFT", row, "BOTTOMLEFT", 0, 0)
    row.accent:SetColorTexture(0, 0, 0, 0)

    -- 아이템 아이콘
    row.icon = row:CreateTexture(nil, "ARTWORK")
    row.icon:SetSize(ICON_SIZE, ICON_SIZE)
    row.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    row.icon:Hide()

    -- 메인 라벨 (던전명/보스명/아이템명)
    row.nameLabel = row:CreateFontString(nil, "OVERLAY")
    row.nameLabel:SetFont(FONT_PATH, 11, FONT_FLAGS)
    row.nameLabel:SetJustifyH("LEFT")
    row.nameLabel:SetJustifyV("MIDDLE")
    row.nameLabel:SetPoint("TOPLEFT", row, "TOPLEFT", 0, -1)
    row.nameLabel:SetWidth(200)

    -- 슬롯 라벨
    row.slotLabel = row:CreateFontString(nil, "OVERLAY")
    row.slotLabel:SetFont(FONT_PATH, 10, FONT_FLAGS)
    row.slotLabel:SetJustifyH("CENTER")
    row.slotLabel:SetJustifyV("MIDDLE")
    row.slotLabel:SetWidth(COL_SLOT)
    row.slotLabel:Hide()

    -- note 배지 라벨
    row.noteLabel = row:CreateFontString(nil, "OVERLAY")
    row.noteLabel:SetFont(FONT_PATH, 10, FONT_FLAGS)
    row.noteLabel:SetJustifyH("CENTER")
    row.noteLabel:SetJustifyV("MIDDLE")
    row.noteLabel:SetWidth(COL_NOTE)
    row.noteLabel:Hide()

    -- 툴팁 영역
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

-- ============================================================
-- 행 초기화 헬퍼
-- ============================================================

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
        local itemRowCount = 0  -- 홀짝 배경용

        for _, dungeonName in ipairs(order) do
            -- ─── 던전 헤더 ───────────────────────────────────────
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
                -- ─── 보스 행 ─────────────────────────────────────
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

                -- ─── 아이템 행 ───────────────────────────────────
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
                    iRow.bg:SetColorTexture(0.04, 0.05, 0.10, 0.30)
                end

                -- 아이템 정보 조회 (GetItemInfo: name, _, quality, _, _, _, _, _, _, texture)
                local itemName, quality, texture
                if entry.itemID and entry.itemID > 0 then
                    local ok, n, _, q, _, _, _, _, _, _, tex = pcall(GetItemInfo, entry.itemID)
                    if ok and n then
                        itemName = n
                        quality  = q
                        texture  = tex
                    else
                        -- 아직 캐시 없음 (GET_ITEM_INFO_RECEIVED 대기)
                        itemName = nil
                    end
                end

                -- 아이콘 배치
                if texture then
                    iRow.icon:SetTexture(texture)
                    iRow.icon:SetPoint("LEFT", iRow, "LEFT", 0, 0)
                    iRow.icon:Show()
                else
                    iRow.icon:Hide()
                end

                -- 이름 라벨 (아이콘 우측)
                local nameX = texture and (COL_ICON) or 0
                local nameW  = COL_NAME + (texture and 0 or COL_ICON)
                iRow.nameLabel:ClearAllPoints()
                iRow.nameLabel:SetPoint("LEFT", iRow, "LEFT", nameX, 0)
                iRow.nameLabel:SetWidth(nameW)
                iRow.nameLabel:SetFont(FONT_PATH, 11, FONT_FLAGS)

                if itemName then
                    -- M+ 기준: 최소 에픽(4=보라) 이상으로 표시
                    -- 전설(5=주황)은 그대로, 그 외는 모두 에픽으로 올림
                    local effectiveQ = math.max(quality or 4, 4)
                    local qc = QC[effectiveQ] or QC[4]
                    iRow.nameLabel:SetTextColor(qc[1], qc[2], qc[3], 1)
                    iRow.nameLabel:SetText(itemName)
                else
                    -- 로딩 중: 에픽 색상으로 표시
                    local qc = QC[4]
                    iRow.nameLabel:SetTextColor(qc[1], qc[2], qc[3], 0.55)
                    iRow.nameLabel:SetText("...")
                end

                -- 슬롯 라벨
                if entry.slot then
                    iRow.slotLabel:ClearAllPoints()
                    iRow.slotLabel:SetPoint("LEFT", iRow, "LEFT",
                        COL_ICON + COL_NAME, 0)
                    iRow.slotLabel:SetWidth(COL_SLOT)
                    iRow.slotLabel:SetFont(FONT_PATH, 10, FONT_FLAGS)
                    iRow.slotLabel:SetTextColor(0.70, 0.70, 0.70, 1)
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

            yOffset = yOffset + 6  -- 던전 간 간격
        end
    end

    -- 컨텐츠/프레임 높이 갱신
    frame.content:SetHeight(math.max(1, yOffset))
    local visH   = math.min(MAX_SCROLL_H, yOffset)
    local totalH = HEADER_H + math.max(20, visH) + PADDING
    frame:SetHeight(totalH)
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
