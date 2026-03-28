local _, ns = ...

local BISOverlay = {}
ns.UI.BISOverlay = BISOverlay

local FRAME_W       = 340
local PADDING       = 8
local ROW_H         = 16
local SECTION_H     = 18
local BOSS_H        = 16
local FONT_PATH     = "Fonts\\2002.TTF"
local FONT_FLAGS    = "OUTLINE"
local TITLE_H       = 22

-- ============================================================
-- 현재 캐릭터의 specID 조회
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
-- BIS 데이터를 던전별로 그룹화
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
    frame:SetSize(FRAME_W, TITLE_H + 6)

    if frame.SetBackdrop then
        frame:SetBackdrop({
            bgFile   = "Interface\\Tooltips\\UI-Tooltip-Background",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true, tileSize = 8, edgeSize = 8,
            insets = { left = 2, right = 2, top = 2, bottom = 2 },
        })
        frame:SetBackdropColor(0.04, 0.04, 0.06, 0.88)
        frame:SetBackdropBorderColor(0.4, 0.4, 0.5, 0.80)
    end

    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", function(f) f:StartMoving() end)
    frame:SetScript("OnDragStop", function(f) f:StopMovingOrSizing() end)
    frame:SetScript("OnHide", function(f) f:StopMovingOrSizing() end)

    -- 제목
    frame.titleText = frame:CreateFontString(nil, "OVERLAY")
    frame.titleText:SetFont(FONT_PATH, 12, FONT_FLAGS)
    frame.titleText:SetPoint("TOPLEFT", frame, "TOPLEFT", PADDING, -PADDING)
    frame.titleText:SetTextColor(0.85, 0.75, 1.0, 1)
    frame.titleText:SetText(ns.L("bis_overlay_title"))

    -- 컨텐츠 영역
    frame.content = CreateFrame("Frame", nil, frame)
    frame.content:SetPoint("TOPLEFT", frame.titleText, "BOTTOMLEFT", 0, -4)
    frame.content:SetPoint("RIGHT", frame, "RIGHT", -PADDING, 0)
    frame.content:SetHeight(1)

    frame.rows = {}
    self.frame = frame
    return frame
end

-- ============================================================
-- 행 생성/재사용
-- ============================================================

local function ensureRow(frame, index)
    if frame.rows[index] then return frame.rows[index] end

    local row = CreateFrame("Frame", nil, frame.content)
    row:SetHeight(ROW_H)
    row:SetPoint("LEFT", frame.content, "LEFT", 0, 0)
    row:SetPoint("RIGHT", frame.content, "RIGHT", 0, 0)

    row.label = row:CreateFontString(nil, "OVERLAY")
    row.label:SetFont(FONT_PATH, 10, FONT_FLAGS)
    row.label:SetPoint("TOPLEFT", row, "TOPLEFT", 0, 0)
    row.label:SetJustifyH("LEFT")
    row.label:SetWidth(FRAME_W - PADDING * 2)

    -- 아이템 툴팁
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

    local specID = getPlayerSpecID()
    local bisData = ns.Data and ns.Data.BISItems and ns.Data.BISItems[specID]

    -- 모든 행 숨기기
    for _, row in ipairs(frame.rows) do
        row:Hide()
    end

    local yOffset = 0
    local rowIndex = 0

    if not bisData or #bisData == 0 then
        -- 데이터 없음
        rowIndex = rowIndex + 1
        local row = ensureRow(frame, rowIndex)
        row:ClearAllPoints()
        row:SetPoint("TOPLEFT", frame.content, "TOPLEFT", 0, -yOffset)
        row:SetHeight(ROW_H)
        row.label:SetFont(FONT_PATH, 10, FONT_FLAGS)
        row.label:SetTextColor(0.5, 0.5, 0.6, 1)
        row.label:SetText(ns.L("bis_overlay_no_data"))
        row.itemID = nil
        row:Show()
        yOffset = yOffset + ROW_H
    else
        local dungeons, order = groupByDungeon(bisData)

        for _, dungeonName in ipairs(order) do
            -- 던전 헤더
            rowIndex = rowIndex + 1
            local hdr = ensureRow(frame, rowIndex)
            hdr:ClearAllPoints()
            hdr:SetPoint("TOPLEFT", frame.content, "TOPLEFT", 0, -yOffset)
            hdr:SetHeight(SECTION_H)
            hdr.label:SetFont(FONT_PATH, 11, FONT_FLAGS)
            hdr.label:SetTextColor(0.55, 0.80, 1.0, 1)
            hdr.label:SetText(dungeonName)
            hdr.itemID = nil
            hdr:Show()
            yOffset = yOffset + SECTION_H + 2

            local items = dungeons[dungeonName]
            local prevBoss = nil

            for _, entry in ipairs(items) do
                -- 보스 이름이 바뀔 때 보스 라벨 삽입
                if entry.boss ~= prevBoss then
                    prevBoss = entry.boss
                    rowIndex = rowIndex + 1
                    local bossRow = ensureRow(frame, rowIndex)
                    bossRow:ClearAllPoints()
                    bossRow:SetPoint("TOPLEFT", frame.content, "TOPLEFT", 6, -yOffset)
                    bossRow:SetHeight(BOSS_H)
                    bossRow.label:SetFont(FONT_PATH, 10, FONT_FLAGS)
                    bossRow.label:SetTextColor(0.90, 0.80, 0.55, 1)
                    bossRow.label:SetText(entry.boss or "?")
                    bossRow.itemID = nil
                    bossRow:Show()
                    yOffset = yOffset + BOSS_H + 1
                end

                -- 아이템 행
                rowIndex = rowIndex + 1
                local itemRow = ensureRow(frame, rowIndex)
                itemRow:ClearAllPoints()
                itemRow:SetPoint("TOPLEFT", frame.content, "TOPLEFT", 14, -yOffset)
                itemRow:SetHeight(ROW_H)
                itemRow.itemID = entry.itemID

                -- 아이템 이름 조회 (캐시에 있으면 즉시, 없으면 ID 표시)
                local itemName
                if entry.itemID and entry.itemID > 0 then
                    local ok, name = pcall(GetItemInfo, entry.itemID)
                    itemName = (ok and name) or ("#" .. entry.itemID)
                else
                    itemName = "?"
                end

                local slotStr = entry.slot and (" (" .. entry.slot .. ")") or ""
                local noteStr = entry.note and ("  " .. entry.note) or ""

                -- note 색상
                local noteColor = "|cff80ff80"
                if entry.note == "BIS" then
                    noteColor = "|cffff8000"
                elseif entry.note == "대체재" or entry.note == "2순위" then
                    noteColor = "|cff40c0ff"
                end

                itemRow.label:SetFont(FONT_PATH, 10, FONT_FLAGS)
                itemRow.label:SetTextColor(0.85, 0.85, 0.90, 1)
                itemRow.label:SetText(itemName .. slotStr .. noteColor .. noteStr .. "|r")
                itemRow:Show()
                yOffset = yOffset + ROW_H + 1
            end

            -- 던전 간 여백
            yOffset = yOffset + 4
        end
    end

    -- 전체 높이 업데이트
    local totalH = TITLE_H + PADDING + yOffset + PADDING
    frame:SetHeight(totalH)
    frame.content:SetHeight(yOffset)
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

    -- ItemLevelOverlay 가 보이면 그 옆에, 아니면 PVEFrame 옆에
    self.frame:ClearAllPoints()
    local ilFrame = ns.UI.ItemLevelOverlay and ns.UI.ItemLevelOverlay.frame
    if ilFrame and ilFrame:IsShown() then
        self.frame:SetPoint("TOPLEFT", ilFrame, "TOPRIGHT", 6, 0)
    else
        self.frame:SetPoint("TOPLEFT", pve, "TOPRIGHT", 10, 0)
    end

    self:RebuildContent()
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

        -- 이미 열려 있으면 즉시 표시
        if pve:IsShown() and ns.DB and ns.DB:IsBISOverlayEnabled() then
            self:Refresh()
        end
        return true
    end

    -- PVEFrame 이 이미 존재하면 즉시 훅, 아니면 demand-load 대기
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
