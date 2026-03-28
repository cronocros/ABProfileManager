local _, ns = ...

local BISOverlay = {}
ns.UI.BISOverlay = BISOverlay

local FRAME_W      = 420
local PADDING      = 10
local ROW_H        = 18
local SECTION_H    = 22
local BOSS_H       = 16
local ICON_SIZE    = 14
local TAB_SIZE     = 22
local TABS_H       = TAB_SIZE + 8
local TITLE_H      = 20
local MAX_SCROLL_H = 320
local FONT_PATH    = "Fonts\\2002.TTF"
local FONT_FLAGS   = "OUTLINE"

-- 헤더 총 높이: 제목 + 구분선 + 탭 + 구분선 + 여백
local HEADER_H = TITLE_H + 8 + TABS_H + 10  -- = 68

-- 아이템 품질 색상 (0=회색 ~ 5=주황)
local QUALITY_COLOR = {
    [0] = { 0.61, 0.61, 0.61 },
    [1] = { 1.00, 1.00, 1.00 },
    [2] = { 0.12, 1.00, 0.00 },
    [3] = { 0.00, 0.44, 0.87 },
    [4] = { 0.64, 0.21, 0.93 },
    [5] = { 1.00, 0.50, 0.00 },
}

-- ============================================================
-- Helper: 현재 클래스의 전체 스펙 목록
-- ============================================================

local function getClassSpecs()
    if not UnitClass or not GetNumSpecializationsForClassID
    or not GetSpecializationInfoForClassID then return {} end
    local _, _, classID = UnitClass("player")
    if not classID then return {} end
    local specs = {}
    local numSpecs = GetNumSpecializationsForClassID(classID)
    for i = 1, numSpecs do
        local ok, specID, name, _, icon = pcall(GetSpecializationInfoForClassID, classID, i)
        if ok and specID then
            specs[#specs + 1] = { specID = specID, name = name, icon = icon }
        end
    end
    return specs
end

-- ============================================================
-- Helper: 현재 캐릭터의 specID
-- ============================================================

local function getPlayerSpecID()
    if not GetSpecialization or not GetSpecializationInfo then return nil end
    local specIndex = GetSpecialization()
    if not specIndex then return nil end
    local ok, specID = pcall(GetSpecializationInfo, specIndex)
    if ok and specID then return specID end
    return nil
end

-- ============================================================
-- Helper: BIS 데이터를 던전별로 그룹화
-- ============================================================

local function groupByDungeon(items)
    local dungeons = {}
    local order = {}
    for _, item in ipairs(items) do
        local key = item.dungeon or "?"
        if not dungeons[key] then
            dungeons[key] = {}
            order[#order + 1] = key
        end
        dungeons[key][#dungeons[key] + 1] = item
    end
    return dungeons, order
end

-- ============================================================
-- 프레임 생성
-- ============================================================

function BISOverlay:EnsureFrame()
    if self.frame then return self.frame end

    local frame = CreateFrame("Frame", "ABPMBISOverlay", UIParent, "BackdropTemplate")
    frame:SetFrameStrata("HIGH")
    frame:SetClampedToScreen(true)
    frame:SetSize(FRAME_W, HEADER_H + 60)

    if frame.SetBackdrop then
        frame:SetBackdrop({
            bgFile   = "Interface\\Tooltips\\UI-Tooltip-Background",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true, tileSize = 8, edgeSize = 8,
            insets = { left = 2, right = 2, top = 2, bottom = 2 },
        })
        frame:SetBackdropColor(0.04, 0.05, 0.10, 0.94)
        frame:SetBackdropBorderColor(0.30, 0.30, 0.52, 0.85)
    end

    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", function(f) f:StartMoving() end)
    frame:SetScript("OnDragStop",  function(f) f:StopMovingOrSizing() end)
    frame:SetScript("OnHide",      function(f) f:StopMovingOrSizing() end)

    -- 제목 텍스트
    frame.titleText = frame:CreateFontString(nil, "OVERLAY")
    frame.titleText:SetFont(FONT_PATH, 12, FONT_FLAGS)
    frame.titleText:SetPoint("TOPLEFT", frame, "TOPLEFT", PADDING, -6)
    frame.titleText:SetTextColor(0.85, 0.75, 1.0, 1)
    frame.titleText:SetText(ns.L("bis_overlay_title"))

    -- 제목 구분선
    local sep1 = frame:CreateTexture(nil, "OVERLAY")
    sep1:SetHeight(1)
    sep1:SetPoint("TOPLEFT",  frame, "TOPLEFT",  PADDING,  -(TITLE_H + 5))
    sep1:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -PADDING, -(TITLE_H + 5))
    sep1:SetColorTexture(0.35, 0.35, 0.55, 0.6)

    -- 스펙 탭 영역
    frame.tabsFrame = CreateFrame("Frame", nil, frame)
    frame.tabsFrame:SetPoint("TOPLEFT",  frame, "TOPLEFT",  PADDING,  -(TITLE_H + 8))
    frame.tabsFrame:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -PADDING, -(TITLE_H + 8))
    frame.tabsFrame:SetHeight(TABS_H)
    frame.tabs = {}

    -- 탭 구분선
    local sep2 = frame:CreateTexture(nil, "OVERLAY")
    sep2:SetHeight(1)
    sep2:SetPoint("TOPLEFT",  frame, "TOPLEFT",  PADDING,  -(TITLE_H + 8 + TABS_H + 3))
    sep2:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -PADDING, -(TITLE_H + 8 + TABS_H + 3))
    sep2:SetColorTexture(0.35, 0.35, 0.55, 0.5)

    -- 스크롤 프레임 (마우스 휠 스크롤)
    local scrollTopOffset = HEADER_H
    frame.scrollFrame = CreateFrame("ScrollFrame", nil, frame)
    frame.scrollFrame:SetPoint("TOPLEFT",     frame, "TOPLEFT",     PADDING,  -scrollTopOffset)
    frame.scrollFrame:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -PADDING, PADDING)
    frame.scrollFrame:EnableMouseWheel(true)
    frame.scrollFrame:SetScript("OnMouseWheel", function(sf, delta)
        local cur = sf:GetVerticalScroll()
        local max = sf:GetVerticalScrollRange()
        sf:SetVerticalScroll(math.max(0, math.min(max, cur - delta * 24)))
    end)

    -- 스크롤 자식 (컨텐츠 영역)
    local scrollW = FRAME_W - PADDING * 2
    frame.content = CreateFrame("Frame", nil, frame.scrollFrame)
    frame.content:SetSize(scrollW, 1)
    frame.scrollFrame:SetScrollChild(frame.content)

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
        tab:SetPoint("TOPLEFT", frame.tabsFrame, "TOPLEFT", (i - 1) * (TAB_SIZE + 5), -2)

        -- 탭 배경 (선택 하이라이트)
        tab.bg = tab:CreateTexture(nil, "BACKGROUND")
        tab.bg:SetAllPoints()
        tab.bg:SetColorTexture(0, 0, 0, 0)

        -- 스펙 아이콘
        tab.icon = tab:CreateTexture(nil, "ARTWORK")
        tab.icon:SetAllPoints()
        if spec.icon then
            tab.icon:SetTexture(spec.icon)
            tab.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        end

        -- 선택 테두리 (황금색 테두리)
        tab.glow = tab:CreateTexture(nil, "OVERLAY")
        tab.glow:SetPoint("TOPLEFT",     tab, "TOPLEFT",     -1,  1)
        tab.glow:SetPoint("BOTTOMRIGHT", tab, "BOTTOMRIGHT",  1, -1)
        tab.glow:SetColorTexture(0.9, 0.75, 0.15, 0)

        tab.specID   = spec.specID
        tab.specName = spec.name

        tab:SetScript("OnEnter", function(self2)
            GameTooltip:SetOwner(self2, "ANCHOR_BOTTOM")
            GameTooltip:SetText(spec.name, 1, 1, 1)
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
            tab.glow:SetColorTexture(0.9, 0.75, 0.15, 0.9)
            tab.bg:SetColorTexture(0.9, 0.75, 0.15, 0.18)
        else
            tab.icon:SetDesaturated(true)
            tab.icon:SetAlpha(0.50)
            tab.glow:SetColorTexture(0, 0, 0, 0)
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

    -- 헤더용 배경
    row.bg = row:CreateTexture(nil, "BACKGROUND")
    row.bg:SetAllPoints()
    row.bg:SetColorTexture(0, 0, 0, 0)

    -- 헤더용 좌측 악센트 바
    row.accent = row:CreateTexture(nil, "ARTWORK")
    row.accent:SetWidth(3)
    row.accent:SetPoint("TOPLEFT",    row, "TOPLEFT",    0, 0)
    row.accent:SetPoint("BOTTOMLEFT", row, "BOTTOMLEFT", 0, 0)
    row.accent:SetColorTexture(0, 0, 0, 0)

    -- 아이템 아이콘
    row.icon = row:CreateTexture(nil, "ARTWORK")
    row.icon:SetSize(ICON_SIZE, ICON_SIZE)
    row.icon:SetPoint("LEFT", row, "LEFT", 0, 0)
    row.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    row.icon:Hide()

    -- 라벨
    row.label = row:CreateFontString(nil, "OVERLAY")
    row.label:SetFont(FONT_PATH, 10, FONT_FLAGS)
    row.label:SetPoint("TOPLEFT", row, "TOPLEFT", 0, -1)
    row.label:SetJustifyH("LEFT")
    row.label:SetWidth(200)

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
    row.tooltipRegion:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    frame.rows[index] = row
    return row
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

    -- 기존 행 초기화
    for _, row in ipairs(frame.rows) do
        row:Hide()
        row.bg:SetColorTexture(0, 0, 0, 0)
        row.accent:SetColorTexture(0, 0, 0, 0)
        row.icon:Hide()
    end

    local scrollW  = FRAME_W - PADDING * 2
    local yOffset  = 0
    local rowIndex = 0

    if not bisData or #bisData == 0 then
        rowIndex = rowIndex + 1
        local row = ensureRow(frame, rowIndex)
        row:ClearAllPoints()
        row:SetPoint("TOPLEFT", frame.content, "TOPLEFT", 0, -yOffset)
        row:SetWidth(scrollW)
        row:SetHeight(ROW_H + 4)
        row.label:ClearAllPoints()
        row.label:SetPoint("LEFT", row, "LEFT", 4, 0)
        row.label:SetWidth(scrollW - 8)
        row.label:SetFont(FONT_PATH, 10, FONT_FLAGS)
        row.label:SetTextColor(0.50, 0.50, 0.50, 1)
        row.label:SetText((ns.L("bis_overlay_no_data") or "no data")
            .. " (spec " .. tostring(specID) .. ")")
        row.itemID = nil
        row:Show()
        yOffset = yOffset + ROW_H + 4
    else
        local dungeons, order = groupByDungeon(bisData)

        for _, dungeonName in ipairs(order) do
            -- 던전 헤더 (파란 악센트 + 어두운 배경)
            rowIndex = rowIndex + 1
            local hdr = ensureRow(frame, rowIndex)
            hdr:ClearAllPoints()
            hdr:SetPoint("TOPLEFT", frame.content, "TOPLEFT", 0, -yOffset)
            hdr:SetWidth(scrollW)
            hdr:SetHeight(SECTION_H)
            hdr.bg:SetColorTexture(0.07, 0.10, 0.18, 0.85)
            hdr.accent:SetColorTexture(0.28, 0.72, 1.0, 1.0)
            hdr.label:ClearAllPoints()
            hdr.label:SetPoint("LEFT", hdr, "LEFT", 8, 0)
            hdr.label:SetWidth(scrollW - 12)
            hdr.label:SetFont(FONT_PATH, 11, FONT_FLAGS)
            hdr.label:SetTextColor(0.55, 0.85, 1.0, 1)
            hdr.label:SetText(dungeonName)
            hdr.itemID = nil
            hdr:Show()
            yOffset = yOffset + SECTION_H + 2

            local items = dungeons[dungeonName]
            local prevBoss = nil

            for _, entry in ipairs(items) do
                -- 보스 이름 (황금색)
                if entry.boss ~= prevBoss then
                    prevBoss = entry.boss
                    rowIndex = rowIndex + 1
                    local bRow = ensureRow(frame, rowIndex)
                    bRow:ClearAllPoints()
                    bRow:SetPoint("TOPLEFT", frame.content, "TOPLEFT", 5, -yOffset)
                    bRow:SetWidth(scrollW - 5)
                    bRow:SetHeight(BOSS_H)
                    bRow.label:ClearAllPoints()
                    bRow.label:SetPoint("LEFT", bRow, "LEFT", 0, 0)
                    bRow.label:SetWidth(scrollW - 5)
                    bRow.label:SetFont(FONT_PATH, 10, FONT_FLAGS)
                    bRow.label:SetTextColor(0.95, 0.80, 0.40, 1)
                    bRow.label:SetText("|cffcc9922▸|r " .. (entry.boss or "?"))
                    bRow.itemID = nil
                    bRow:Show()
                    yOffset = yOffset + BOSS_H + 2
                end

                -- 아이템 행 (아이콘 + 품질 색상 이름 + 슬롯 + note 배지)
                rowIndex = rowIndex + 1
                local iRow = ensureRow(frame, rowIndex)
                iRow:ClearAllPoints()
                iRow:SetPoint("TOPLEFT", frame.content, "TOPLEFT", 14, -yOffset)
                iRow:SetWidth(scrollW - 14)
                iRow:SetHeight(ROW_H)
                iRow.itemID = entry.itemID

                -- GetItemInfo (이름, 품질, 텍스처)
                local itemName, quality, texture
                if entry.itemID and entry.itemID > 0 then
                    -- GetItemInfo 반환: name, link, quality, level, minLevel,
                    --   type, subType, stackCount, equipLoc, texture, sellPrice
                    local ok, n, _, q, _, _, _, _, _, _, tex = pcall(GetItemInfo, entry.itemID)
                    if ok and n then
                        itemName = n
                        quality  = q
                        texture  = tex
                    else
                        itemName = "#" .. entry.itemID
                    end
                else
                    itemName = "?"
                end

                -- 아이콘
                if texture then
                    iRow.icon:SetTexture(texture)
                    iRow.icon:SetPoint("LEFT", iRow, "LEFT", 0, 0)
                    iRow.icon:Show()
                else
                    iRow.icon:Hide()
                end

                -- 이름 라벨 위치 (아이콘 유무에 따라)
                local labelX = texture and (ICON_SIZE + 4) or 0
                local labelW = scrollW - 14 - labelX - 2

                iRow.label:ClearAllPoints()
                iRow.label:SetPoint("LEFT", iRow, "LEFT", labelX, 0)
                iRow.label:SetWidth(labelW)
                iRow.label:SetFont(FONT_PATH, 10, FONT_FLAGS)

                local qc = QUALITY_COLOR[quality] or QUALITY_COLOR[1]
                iRow.label:SetTextColor(qc[1], qc[2], qc[3], 1)

                -- note 배지
                local noteStr = ""
                if entry.note == "BIS" then
                    noteStr = " |cffff8800[BIS]|r"
                elseif entry.note == "대체재" then
                    noteStr = " |cff3399ff[대체]|r"
                elseif entry.note == "2순위" then
                    noteStr = " |cff66cc66[2nd]|r"
                elseif entry.note then
                    noteStr = " |cff888888[" .. entry.note .. "]|r"
                end

                local slotStr = entry.slot
                    and ("|cff666666  " .. entry.slot .. "|r")
                    or ""

                iRow.label:SetText(itemName .. slotStr .. noteStr)
                iRow:Show()
                yOffset = yOffset + ROW_H + 2
            end

            yOffset = yOffset + 6  -- 던전 간 여백
        end
    end

    -- 컨텐츠·스크롤·프레임 높이 업데이트
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
