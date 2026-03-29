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
local ICON_SIZE    = 15
local TAB_SIZE     = 24
local TABS_H       = TAB_SIZE + 12   -- 아이콘 + 하단 인디케이터 여백
local TITLE_H      = 26
local MAX_SCROLL_H = 340
local FONT_PATH    = "Fonts\\2002.TTF"
local FONT_FLAGS   = "OUTLINE"

-- 스케일 조절 (헤더 영역 마우스 휠)
local SCALE_STEP = 0.05
local SCALE_MIN  = 0.50
local SCALE_MAX  = 2.00
local _bisScale  = 1.0

-- 커스텀 스크롤바 치수
local SB_W   = 7    -- 스크롤바 폭
local SB_GAP = 5    -- 스크롤바와 컨텐츠 사이 간격

-- 헤더 총 높이
local HEADER_H  = TITLE_H + 10 + TABS_H + 12  -- = 84

-- 컨텐츠 폭: 스크롤바(+갭+오른쪽 패딩) 제외
local CONTENT_W = FRAME_W - PADDING - (PADDING + SB_W + SB_GAP)  -- = 430

-- 아이템 행 컬럼 레이아웃
local ITEM_INDENT = 10
local ITEM_W      = CONTENT_W - ITEM_INDENT
local COL_ICON    = ICON_SIZE + 5
local COL_NAME    = 216
local COL_SLOT    = 112                        -- 던전 출처
local COL_NOTE    = 54                         -- BIS/대체/3순 배지
local SPEC_PICKER_W = 134
local SPEC_PICKER_BTN_H = 22
local SPEC_PICKER_ROW_H = 20
local SPEC_PICKER_MAX_VISIBLE = 12

-- 아이템 품질 색상
local QC = {
    [0] = { 0.55, 0.55, 0.55 },
    [1] = { 0.85, 0.85, 0.85 },
    [2] = { 0.12, 1.00, 0.00 },
    [3] = { 0.20, 0.65, 1.00 },
    [4] = { 0.80, 0.35, 1.00 },
    [5] = { 1.00, 0.55, 0.00 },
}

local function getSeasonDisplayQuality(itemQuality)
    -- 시즌 M+ 드랍은 구던 원본 품질이 파템이어도 최소 에픽으로 보정해서 보여준다.
    return math.max(itemQuality or 4, 4)
end

local function getQualityColor(itemQuality)
    local effectiveQ = getSeasonDisplayQuality(itemQuality)
    return QC[effectiveQ] or QC[4], effectiveQ
end

local SLOT_ORDER = {
    "무기", "보조장비", "방패", "머리", "목", "어깨", "망토", "가슴",
    "손목", "손", "허리", "다리", "발", "반지", "장신구",
}

local SLOT_SORT_ORDER = {}
for i, slotName in ipairs(SLOT_ORDER) do
    SLOT_SORT_ORDER[slotName] = i
end

local SLOT_LOCALE_KEYS = {
    ["무기"] = "bis_slot_weapon",
    ["보조장비"] = "bis_slot_offhand",
    ["방패"] = "bis_slot_shield",
    ["머리"] = "bis_slot_head",
    ["목"] = "bis_slot_neck",
    ["어깨"] = "bis_slot_shoulders",
    ["망토"] = "bis_slot_cloak",
    ["가슴"] = "bis_slot_chest",
    ["손목"] = "bis_slot_wrist",
    ["손"] = "bis_slot_hands",
    ["허리"] = "bis_slot_waist",
    ["다리"] = "bis_slot_legs",
    ["발"] = "bis_slot_feet",
    ["반지"] = "bis_slot_ring",
    ["장신구"] = "bis_slot_trinket",
}

local DUNGEON_LOCALE_KEYS = {
    ["마법학자의 정원"] = "bis_dungeon_magisters_terrace",
    ["마이사라 동굴"] = "bis_dungeon_maisara_caverns",
    ["공결점 제나스"] = "bis_dungeon_nexus_point_xenas",
    ["윈드러너 첨탑"] = "bis_dungeon_windrunner_spire",
    ["알게타르 아카데미"] = "bis_dungeon_algethar_academy",
    ["삼두정의 권좌"] = "bis_dungeon_seat_of_the_triumvirate",
    ["하늘탑"] = "bis_dungeon_skyreach",
    ["사론의 구덩이"] = "bis_dungeon_pit_of_saron",
}

local NOTE_BADGE_COLOR = {
    bis   = "ffffc000",
    alt   = "ff44aaff",
    third = "ff66cc66",
    rank  = "ff888888",
}

-- 던전 → 모험 안내서 instanceID 매핑 (returning 던전 확인값, Midnight 신규 던전은 미확인)
local DUNGEON_EJ_IDS = {
    ["마법학자의 정원"]   = 585,   -- Magisters' Terrace (TBC)
    ["마이사라 동굴"]     = nil,   -- Midnight 신규 (ID 미확인)
    ["공결점 제나스"]     = nil,   -- Midnight 신규 (ID 미확인)
    ["윈드러너 첨탑"]     = nil,   -- Midnight 신규 (ID 미확인)
    ["알게타르 아카데미"] = 1196,  -- Algeth'ar Academy (DF)
    ["삼두정의 권좌"]     = 1624,  -- Seat of the Triumvirate (Legion)
    ["하늘탑"]            = 1279,  -- Skyreach (WoD)
    ["사론의 구덩이"]     = 285,   -- Pit of Saron (WotLK)
}

-- ============================================================
-- Helper 함수들
-- ============================================================

local function getPlayerClassID()
    if not UnitClass then return nil end
    local _, _, classID = UnitClass("player")
    return classID
end

local function getClassColorRGB(classFile)
    local color = classFile and C_ClassColor and C_ClassColor.GetClassColor and C_ClassColor.GetClassColor(classFile)
    if color then
        return color.r or 0.78, color.g or 0.78, color.b or 0.90
    end
    color = classFile and RAID_CLASS_COLORS and RAID_CLASS_COLORS[classFile]
    if color then
        return color.r or 0.78, color.g or 0.78, color.b or 0.90
    end
    return 0.78, 0.78, 0.90
end

local function getAllSpecs()
    if not GetNumClasses or not GetClassInfo
    or not GetNumSpecializationsForClassID
    or not GetSpecializationInfoForClassID then
        return {}
    end

    local specs = {}
    local playerClassID = getPlayerClassID()
    local numClasses = GetNumClasses() or 0

    for classID = 1, numClasses do
        local className, classFile = GetClassInfo(classID)
        local specCount = GetNumSpecializationsForClassID(classID) or 0
        for specIndex = 1, specCount do
            local ok, specID, specName, _, icon = pcall(
                GetSpecializationInfoForClassID, classID, specIndex
            )
            if ok and specID and specName then
                specs[#specs + 1] = {
                    specID = specID,
                    name = specName,
                    icon = icon,
                    classID = classID,
                    className = className,
                    classFile = classFile,
                    specIndex = specIndex,
                    isPlayerClass = classID == playerClassID,
                }
            end
        end
    end

    table.sort(specs, function(a, b)
        local ap = a.isPlayerClass and 0 or 1
        local bp = b.isPlayerClass and 0 or 1
        if ap ~= bp then
            return ap < bp
        end
        if a.classID ~= b.classID then
            return a.classID < b.classID
        end
        if a.specIndex ~= b.specIndex then
            return a.specIndex < b.specIndex
        end
        return tostring(a.name) < tostring(b.name)
    end)

    return specs
end

local function getSpecInfo(specID)
    if not specID then return nil end
    for _, spec in ipairs(getAllSpecs()) do
        if spec.specID == specID then
            return spec
        end
    end
    return nil
end

local function getClassSpecs()
    local specs = {}
    local classID = getPlayerClassID()
    if not classID then return specs end

    for _, spec in ipairs(getAllSpecs()) do
        if spec.classID == classID then
            specs[#specs + 1] = spec
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

-- 모험 안내서 열기 (safe — pcall 보호)
local function openEncounterJournal(dungeonName)
    local instanceID = dungeonName and DUNGEON_EJ_IDS[dungeonName]
    pcall(function()
        if EncounterJournal then
            if not EncounterJournal:IsShown() then
                if ShowUIPanel then
                    ShowUIPanel(EncounterJournal)
                elseif ToggleEncounterJournal then
                    ToggleEncounterJournal()
                end
            end
            if instanceID then
                C_Timer.After(0.1, function()
                    pcall(EJ_SelectInstance, instanceID)
                end)
            end
        end
    end)
end

local function localizeSlot(slotName)
    local key = slotName and SLOT_LOCALE_KEYS[slotName]
    return key and ns.L(key) or slotName or "?"
end

local function localizeDungeon(dungeonName)
    local key = dungeonName and DUNGEON_LOCALE_KEYS[dungeonName]
    return key and ns.L(key) or dungeonName or "?"
end

local function canonicalNote(note)
    if note == "BIS" then
        return "bis"
    end
    if note == "대체재" or note == "대체" then
        return "alt"
    end
    if note == "2순위" or note == "3순위" then
        return "third"
    end
    return "rank"
end

local function notePriority(note)
    local canonical = canonicalNote(note)
    if canonical == "bis" then return 1 end
    if canonical == "alt" then return 2 end
    if canonical == "third" then return 3 end
    return 4
end

local function noteBadge(kind, index)
    local key
    if kind == "bis" then
        key = "bis_note_bis"
    elseif kind == "alt" then
        key = "bis_note_alt"
    elseif kind == "third" then
        key = "bis_note_third"
    else
        key = nil
    end

    local label = key and ns.L(key) or (index and ns.L("bis_note_rank", index) or "")
    local color = NOTE_BADGE_COLOR[kind] or NOTE_BADGE_COLOR.rank
    return label ~= "" and ("|c" .. color .. label .. "|r") or ""
end

local function notePlain(kind, index)
    if kind == "bis" then
        return ns.L("bis_note_bis")
    end
    if kind == "alt" then
        return ns.L("bis_note_alt")
    end
    if kind == "third" then
        return ns.L("bis_note_third")
    end
    return ns.L("bis_note_rank", index or 4)
end

local function formatSpecSelection(spec)
    if not spec then
        return ns.L("bis_all_specs") or "All Specs"
    end
    local classLabel = spec.className or "?"
    local specLabel = spec.name or ("Spec " .. tostring(spec.specID))
    return classLabel .. "/" .. specLabel
end

local function formatTrackLabel(grade, rank, rankMax)
    if not grade then return "" end
    local label = ns.L("ilvl_crest_" .. grade) or ns.L("ilvl_grade_" .. grade) or grade
    if rank and rankMax then
        return string.format("%s %d/%d", label, rank, rankMax)
    end
    return label
end

local function trackSummary(grades)
    local tbl = ns.Data and ns.Data.ItemLevelTable
    local gradeMax = tbl and tbl.gradeMax
    if not gradeMax then return "" end

    local parts = {}
    for _, grade in ipairs(grades or {}) do
        local maxIlvl = gradeMax[grade]
        if maxIlvl then
            local label = ns.L("ilvl_crest_" .. grade) or ns.L("ilvl_grade_" .. grade) or grade
            parts[#parts + 1] = label .. " ~" .. tostring(maxIlvl)
        end
    end
    return table.concat(parts, ", ")
end

local function getSeasonalMythicPlusSummary(kind)
    local tbl = ns.Data and ns.Data.ItemLevelTable
    local entries = tbl and tbl.mythicPlus and tbl.mythicPlus.endOfDungeon
    if not entries or #entries == 0 then return "" end

    local first = entries[1]
    local last = entries[#entries]
    if kind == "run" then
        return string.format("%d~%d (%s -> %s)",
            first.ilvl or 0,
            last.ilvl or 0,
            formatTrackLabel(first.grade, first.rank, first.rankMax),
            formatTrackLabel(last.grade, last.rank, last.rankMax)
        )
    end

    return string.format("%d~%d (%s -> %s)",
        first.vault or 0,
        last.vault or 0,
        formatTrackLabel(first.vaultGrade, first.vaultRank, first.vaultMax),
        formatTrackLabel(last.vaultGrade, last.vaultRank, last.vaultMax)
    )
end

local function getSeasonalMythicPlusRange()
    local tbl = ns.Data and ns.Data.ItemLevelTable
    local entries = tbl and tbl.mythicPlus and tbl.mythicPlus.endOfDungeon
    if not entries or #entries == 0 then return nil, nil end
    return entries[1].ilvl, entries[#entries].ilvl
end

local function overrideTooltipItemLevelLine(minIlvl, maxIlvl)
    if not minIlvl or not maxIlvl then return end
    local replacement = ns.L("bis_tooltip_item_level_scaled", minIlvl, maxIlvl)
    for i = 2, 12 do
        local fs = _G["GameTooltipTextLeft" .. i]
        local text = fs and fs:GetText()
        if text and (
            text:find("Item Level", 1, true)
            or text:find("아이템 레벨", 1, true)
        ) then
            fs:SetText(replacement)
            fs:SetTextColor(0.38, 0.88, 1.00, 1)
            return
        end
    end
end

local function slotSortValue(slotName)
    return SLOT_SORT_ORDER[slotName] or 999
end

local function groupBySlot(items)
    local slots, order = {}, {}
    for _, item in ipairs(items) do
        local slotName = item.slot or "기타"
        if not slots[slotName] then
            slots[slotName] = {}
            order[#order + 1] = slotName
        end
        slots[slotName][#slots[slotName] + 1] = item
    end

    table.sort(order, function(a, b)
        local av, bv = slotSortValue(a), slotSortValue(b)
        if av ~= bv then
            return av < bv
        end
        return tostring(a) < tostring(b)
    end)

    for _, slotName in ipairs(order) do
        local entries = slots[slotName]
        table.sort(entries, function(a, b)
            local ap, bp = notePriority(a.note), notePriority(b.note)
            if ap ~= bp then
                return ap < bp
            end
            if (a.dungeon or "") ~= (b.dungeon or "") then
                return (a.dungeon or "") < (b.dungeon or "")
            end
            return (a.itemID or 0) < (b.itemID or 0)
        end)

        local altCount = 0
        for _, entry in ipairs(entries) do
            local kind = canonicalNote(entry.note)
            if kind == "bis" then
                entry._displayNoteKind = "bis"
                entry._displayNoteIndex = 1
            else
                altCount = altCount + 1
                if altCount == 1 then
                    entry._displayNoteKind = "alt"
                    entry._displayNoteIndex = 2
                elseif altCount == 2 then
                    entry._displayNoteKind = "third"
                    entry._displayNoteIndex = 3
                else
                    entry._displayNoteKind = "rank"
                    entry._displayNoteIndex = altCount + 1
                end
            end
        end
    end

    return slots, order
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
            BISOverlay._isItemLoadRebuild = true  -- 스크롤 위치 유지
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
-- 접기/펼치기
-- ============================================================

function BISOverlay:ApplyCollapse()
    local frame = self.frame
    if not frame then return end
    if self._collapsed then
        if frame.specPicker then frame.specPicker:Hide() end
        frame.scrollFrame:Hide()
        frame.scrollBarTrack:Hide()
        frame.scrollBarThumb:Hide()
        if frame.collapseBtn then frame.collapseBtn.label:SetText("+") end
        frame:SetHeight(HEADER_H + PADDING)
    else
        frame.scrollFrame:Show()
        frame.scrollBarTrack:Show()
        if frame.collapseBtn then frame.collapseBtn.label:SetText("-") end
        pcall(function() self:RebuildContent() end)
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
    frame:EnableMouseWheel(true)
    frame:RegisterForDrag("LeftButton")
    -- 헤더 영역(스크롤프레임 밖)에서 마우스 휠 → 스케일 조절
    frame:SetScript("OnMouseWheel", function(f, delta)
        _bisScale = math.max(SCALE_MIN, math.min(SCALE_MAX,
            _bisScale + delta * SCALE_STEP))
        _bisScale = math.floor(_bisScale * 100 + 0.5) / 100
        f:SetScale(_bisScale)
    end)
    frame:SetScript("OnDragStart", function(f)
        if ns.DB and ns.DB:IsBISOverlayLocked() then return end
        f:StartMoving()
    end)
    frame:SetScript("OnDragStop",  function(f) f:StopMovingOrSizing() end)
    frame:SetScript("OnHide",      function(f)
        f:StopMovingOrSizing()
        if f.specPicker then f.specPicker:Hide() end
    end)

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

    -- ─── 접기/펼치기 버튼 ────────────────────────────────────
    local collapseBtn = CreateFrame("Button", nil, frame)
    collapseBtn:SetSize(18, 18)
    collapseBtn:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -PADDING, -9)

    collapseBtn.label = collapseBtn:CreateFontString(nil, "OVERLAY")
    collapseBtn.label:SetFont(FONT_PATH, 11, FONT_FLAGS)
    collapseBtn.label:SetAllPoints()
    collapseBtn.label:SetJustifyH("CENTER")
    collapseBtn.label:SetJustifyV("MIDDLE")
    collapseBtn.label:SetText("-")
    collapseBtn.label:SetTextColor(0.70, 0.70, 0.80, 1)

    collapseBtn:SetScript("OnClick", function()
        BISOverlay._collapsed = not BISOverlay._collapsed
        BISOverlay:ApplyCollapse()
    end)
    frame.collapseBtn = collapseBtn

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

    frame.specPickerBtn = CreateFrame("Button", nil, frame.tabsFrame, "BackdropTemplate")
    frame.specPickerBtn:SetSize(SPEC_PICKER_W, SPEC_PICKER_BTN_H)
    frame.specPickerBtn:SetPoint("TOPRIGHT", frame.tabsFrame, "TOPRIGHT", -1, 1)
    if frame.specPickerBtn.SetBackdrop then
        frame.specPickerBtn:SetBackdrop({
            bgFile   = "Interface\\Tooltips\\UI-Tooltip-Background",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true, tileSize = 8, edgeSize = 8,
            insets = { left = 2, right = 2, top = 2, bottom = 2 },
        })
        frame.specPickerBtn:SetBackdropColor(0.07, 0.10, 0.18, 0.97)
        frame.specPickerBtn:SetBackdropBorderColor(0.30, 0.38, 0.56, 0.92)
    end
    frame.specPickerBtn.fill = frame.specPickerBtn:CreateTexture(nil, "BACKGROUND")
    frame.specPickerBtn.fill:SetPoint("TOPLEFT", frame.specPickerBtn, "TOPLEFT", 3, -3)
    frame.specPickerBtn.fill:SetPoint("BOTTOMRIGHT", frame.specPickerBtn, "BOTTOMRIGHT", -3, 3)
    frame.specPickerBtn.fill:SetColorTexture(0.10, 0.14, 0.23, 0.92)
    frame.specPickerBtn.accent = frame.specPickerBtn:CreateTexture(nil, "ARTWORK")
    frame.specPickerBtn.accent:SetWidth(2)
    frame.specPickerBtn.accent:SetPoint("TOPLEFT", frame.specPickerBtn, "TOPLEFT", 4, -4)
    frame.specPickerBtn.accent:SetPoint("BOTTOMLEFT", frame.specPickerBtn, "BOTTOMLEFT", 4, 4)
    frame.specPickerBtn.accent:SetColorTexture(0.34, 0.76, 1.00, 0.85)
    frame.specPickerBtn.icon = frame.specPickerBtn:CreateTexture(nil, "ARTWORK")
    frame.specPickerBtn.icon:SetSize(14, 14)
    frame.specPickerBtn.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    frame.specPickerBtn.icon:SetPoint("LEFT", frame.specPickerBtn, "LEFT", 10, 0)
    frame.specPickerBtn.label = frame.specPickerBtn:CreateFontString(nil, "OVERLAY")
    frame.specPickerBtn.label:SetFont(FONT_PATH, 9, FONT_FLAGS)
    frame.specPickerBtn.label:SetPoint("LEFT", frame.specPickerBtn.icon, "RIGHT", 6, 0)
    frame.specPickerBtn.label:SetPoint("RIGHT", frame.specPickerBtn, "RIGHT", -18, 0)
    frame.specPickerBtn.label:SetJustifyH("LEFT")
    frame.specPickerBtn.label:SetTextColor(0.82, 0.84, 0.94, 1)
    frame.specPickerBtn.arrow = frame.specPickerBtn:CreateFontString(nil, "OVERLAY")
    frame.specPickerBtn.arrow:SetFont(FONT_PATH, 9, FONT_FLAGS)
    frame.specPickerBtn.arrow:SetPoint("RIGHT", frame.specPickerBtn, "RIGHT", -6, 0)
    frame.specPickerBtn.arrow:SetText("v")
    frame.specPickerBtn.arrow:SetTextColor(0.78, 0.80, 0.92, 1)
    frame.specPickerBtn:SetScript("OnEnter", function(self2)
        GameTooltip:SetOwner(self2, "ANCHOR_BOTTOM")
        GameTooltip:SetText(ns.L("bis_all_specs"), 1, 1, 1, 1, true)
        GameTooltip:AddLine(ns.L("bis_all_specs_hint"), 0.70, 0.78, 0.90, true)
        GameTooltip:Show()
    end)
    frame.specPickerBtn:SetScript("OnLeave", function()
        if not (frame.specPicker and frame.specPicker:IsShown()) then
            GameTooltip:Hide()
        end
    end)

    frame.specPicker = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    frame.specPicker:SetFrameStrata("TOOLTIP")
    frame.specPicker:SetFrameLevel(frame:GetFrameLevel() + 20)
    frame.specPicker:SetWidth(SPEC_PICKER_W)
    frame.specPicker:SetClampedToScreen(true)
    frame.specPicker:EnableMouse(true)
    frame.specPicker:EnableMouseWheel(true)
    frame.specPicker:Hide()
    frame.specPicker.rows = {}
    frame.specPicker.items = {}
    frame.specPicker.offset = 0
    if frame.specPicker.SetBackdrop then
        frame.specPicker:SetBackdrop({
            bgFile   = "Interface\\Tooltips\\UI-Tooltip-Background",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true, tileSize = 8, edgeSize = 8,
            insets = { left = 2, right = 2, top = 2, bottom = 2 },
        })
        frame.specPicker:SetBackdropColor(0.04, 0.05, 0.10, 0.97)
        frame.specPicker:SetBackdropBorderColor(0.35, 0.42, 0.60, 0.95)
    end
    frame.specPicker:SetScript("OnMouseWheel", function(self2, delta)
        local total = #self2.items
        local visible = math.min(total, SPEC_PICKER_MAX_VISIBLE)
        if total <= visible then return end
        local maxOffset = total - visible
        self2.offset = math.max(0, math.min(maxOffset, self2.offset - delta))
        BISOverlay:RefreshSpecPickerRows()
    end)

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

local function ensureSpecPickerRow(frame, index)
    local picker = frame.specPicker
    if picker.rows[index] then return picker.rows[index] end

    local row = CreateFrame("Button", nil, picker)
    row:SetHeight(SPEC_PICKER_ROW_H)
    row:SetPoint("TOPLEFT", picker, "TOPLEFT", 4, -((index - 1) * SPEC_PICKER_ROW_H + 4))
    row:SetPoint("RIGHT", picker, "RIGHT", -4, 0)

    row.bg = row:CreateTexture(nil, "BACKGROUND")
    row.bg:SetAllPoints()
    row.bg:SetColorTexture(0, 0, 0, 0)

    local hl = row:CreateTexture(nil, "HIGHLIGHT")
    hl:SetAllPoints()
    hl:SetColorTexture(1, 1, 1, 0.10)

    row.icon = row:CreateTexture(nil, "ARTWORK")
    row.icon:SetSize(15, 15)
    row.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    row.icon:SetPoint("LEFT", row, "LEFT", 4, 0)

    row.label = row:CreateFontString(nil, "OVERLAY")
    row.label:SetFont(FONT_PATH, 10, FONT_FLAGS)
    row.label:SetPoint("LEFT", row.icon, "RIGHT", 6, 0)
    row.label:SetPoint("RIGHT", row, "RIGHT", -48, 0)
    row.label:SetJustifyH("LEFT")
    row.label:SetTextColor(0.90, 0.92, 1.00, 1)

    row.classLabel = row:CreateFontString(nil, "OVERLAY")
    row.classLabel:SetFont(FONT_PATH, 8, FONT_FLAGS)
    row.classLabel:SetPoint("RIGHT", row, "RIGHT", -5, 0)
    row.classLabel:SetJustifyH("RIGHT")

    row.accent = row:CreateTexture(nil, "ARTWORK")
    row.accent:SetWidth(2)
    row.accent:SetPoint("TOPLEFT", row, "TOPLEFT", 0, 0)
    row.accent:SetPoint("BOTTOMLEFT", row, "BOTTOMLEFT", 0, 0)
    row.accent:SetColorTexture(0, 0, 0, 0)

    picker.rows[index] = row
    return row
end

function BISOverlay:RefreshSpecPickerRows()
    local frame = self.frame
    local picker = frame and frame.specPicker
    if not picker then return end

    local items = picker.items or {}
    local total = #items
    local visible = math.min(total, SPEC_PICKER_MAX_VISIBLE)
    local maxOffset = math.max(0, total - visible)
    picker.offset = math.max(0, math.min(maxOffset, picker.offset or 0))
    picker:SetHeight(visible * SPEC_PICKER_ROW_H + 8)

    local activeID = self.selectedSpecID or getPlayerSpecID()

    for i = 1, visible do
        local row = ensureSpecPickerRow(frame, i)
        local spec = items[picker.offset + i]
        row.specID = spec and spec.specID or nil
        row.label:SetText(spec and (spec.name or "") or "")
        if spec and spec.icon then
            row.icon:SetTexture(spec.icon)
            row.icon:Show()
        else
            row.icon:Hide()
        end
        if spec then
            local cr, cg, cb = getClassColorRGB(spec.classFile)
            row.classLabel:SetText(spec.className or "")
            row.classLabel:SetTextColor(cr, cg, cb, 0.92)
            row.classLabel:Show()
        else
            row.classLabel:SetText("")
            row.classLabel:Hide()
        end

        if spec and spec.specID == activeID then
            row.bg:SetColorTexture(0.18, 0.52, 0.78, 0.28)
            row.accent:SetColorTexture(0.34, 0.76, 1.00, 0.95)
        else
            row.bg:SetColorTexture(0, 0, 0, 0)
            row.accent:SetColorTexture(0, 0, 0, 0)
        end

        row:SetScript("OnClick", function(self2)
            if not self2.specID then return end
            BISOverlay.selectedSpecID = self2.specID
            BISOverlay:UpdateTabHighlight()
            if frame.specPicker then frame.specPicker:Hide() end
            BISOverlay:RebuildContent()
        end)
        row:Show()
    end

    for i = visible + 1, #picker.rows do
        picker.rows[i]:Hide()
    end
end

function BISOverlay:UpdateSpecPickerButton()
    local frame = self.frame
    if not frame or not frame.specPickerBtn then return end

    local playerClassID = getPlayerClassID()
    local activeID = self.selectedSpecID or getPlayerSpecID()
    local activeSpec = getSpecInfo(activeID)
    local showingOtherClass = activeSpec and playerClassID and activeSpec.classID ~= playerClassID

    if showingOtherClass then
        frame.specPickerBtn.label:SetText(formatSpecSelection(activeSpec))
        frame.specPickerBtn.label:SetTextColor(0.38, 0.88, 1.00, 1)
        if frame.specPickerBtn.icon and activeSpec and activeSpec.icon then
            frame.specPickerBtn.icon:SetTexture(activeSpec.icon)
            frame.specPickerBtn.icon:Show()
        end
        if frame.specPickerBtn.SetBackdropBorderColor then
            frame.specPickerBtn:SetBackdropBorderColor(0.26, 0.70, 0.96, 0.95)
        end
        if frame.specPickerBtn.fill then
            frame.specPickerBtn.fill:SetColorTexture(0.09, 0.16, 0.25, 0.94)
        end
    else
        frame.specPickerBtn.label:SetText(ns.L("bis_all_specs"))
        frame.specPickerBtn.label:SetTextColor(0.82, 0.84, 0.94, 1)
        local activePlayerSpec = activeSpec or getSpecInfo(getPlayerSpecID())
        if frame.specPickerBtn.icon and activePlayerSpec and activePlayerSpec.icon then
            frame.specPickerBtn.icon:SetTexture(activePlayerSpec.icon)
            frame.specPickerBtn.icon:Show()
        end
        if frame.specPickerBtn.SetBackdropBorderColor then
            frame.specPickerBtn:SetBackdropBorderColor(0.28, 0.35, 0.52, 0.90)
        end
        if frame.specPickerBtn.fill then
            frame.specPickerBtn.fill:SetColorTexture(0.10, 0.14, 0.23, 0.92)
        end
    end

    if frame.specPicker and frame.specPicker:IsShown() then
        self:RefreshSpecPickerRows()
    end
end

function BISOverlay:ToggleSpecPicker()
    local frame = self.frame
    if not frame or not frame.specPicker or not frame.specPickerBtn then return end

    if frame.specPicker:IsShown() then
        frame.specPicker:Hide()
        return
    end

    frame.specPicker.items = getAllSpecs()
    frame.specPicker:ClearAllPoints()
    frame.specPicker:SetPoint("TOPRIGHT", frame.specPickerBtn, "BOTTOMRIGHT", 0, -4)

    local activeID = self.selectedSpecID or getPlayerSpecID()
    local visible = math.min(#frame.specPicker.items, SPEC_PICKER_MAX_VISIBLE)
    local offset = 0
    for i, spec in ipairs(frame.specPicker.items) do
        if spec.specID == activeID then
            offset = math.max(0, math.min(#frame.specPicker.items - visible, i - 2))
            break
        end
    end
    frame.specPicker.offset = offset
    self:RefreshSpecPickerRows()
    frame.specPicker:Show()
    frame.specPicker:Raise()
end

function BISOverlay:EnsureTabs()
    local frame = self.frame
    if not frame then return end
    local specs = getClassSpecs()
    if #specs == 0 then return end
    if #frame.tabs == #specs then
        self:UpdateTabHighlight()
        self:UpdateSpecPickerButton()
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

    if frame.specPickerBtn then
        frame.specPickerBtn:SetScript("OnClick", function()
            BISOverlay:ToggleSpecPicker()
        end)
    end

    self:UpdateTabHighlight()
    self:UpdateSpecPickerButton()
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
    self:UpdateSpecPickerButton()
end

-- ============================================================
-- 행 생성/재사용
-- ============================================================

local function requestItemData(itemID)
    if not itemID or itemID <= 0 then return end
    if C_Item and C_Item.RequestLoadItemDataByID then
        pcall(C_Item.RequestLoadItemDataByID, itemID)
    end
end

local function showSeasonItemTooltip(owner, row)
    if not row or not row.itemID or row.itemID <= 0 then return end

    local entry = row._entry or {}
    local noteKind = row._displayNoteKind or canonicalNote(entry.note)
    local noteIndex = row._displayNoteIndex or 3
    local _, itemLink, quality = GetItemInfo(row.itemID)
    local scaledMinIlvl, scaledMaxIlvl = getSeasonalMythicPlusRange()

    GameTooltip:SetOwner(owner, "ANCHOR_RIGHT")
    GameTooltip:ClearLines()

    local hasBaseTooltip = false

    if itemLink and GameTooltip.SetHyperlink then
        local ok = pcall(GameTooltip.SetHyperlink, GameTooltip, itemLink)
        hasBaseTooltip = ok
    elseif GameTooltip.SetItemByID then
        local ok = pcall(GameTooltip.SetItemByID, GameTooltip, row.itemID)
        hasBaseTooltip = ok
    end

    if not hasBaseTooltip then
        requestItemData(row.itemID)
        local ok, itemName, _, quality = pcall(GetItemInfo, row.itemID)
        local displayName = (ok and itemName) or ("Item #" .. tostring(row.itemID))
        local qc = getQualityColor(quality)
        GameTooltip:AddLine(displayName, qc[1], qc[2], qc[3], 1)
    else
        local nameFS = _G.GameTooltipTextLeft1
        local qc = getQualityColor(quality)
        if nameFS then
            nameFS:SetTextColor(qc[1], qc[2], qc[3], 1)
        end
    end

    overrideTooltipItemLevelLine(scaledMinIlvl, scaledMaxIlvl)

    GameTooltip:AddLine(" ")
    GameTooltip:AddLine(ns.L("bis_tooltip_current_season"), 0.88, 0.70, 1.00, true)
    GameTooltip:AddDoubleLine(ns.L("bis_tooltip_slot"), localizeSlot(entry.slot), 0.70, 0.78, 0.90, 1, 1, 1)
    GameTooltip:AddDoubleLine(ns.L("bis_tooltip_source"), localizeDungeon(entry.dungeon), 0.70, 0.78, 0.90, 1, 1, 1)
    GameTooltip:AddDoubleLine(ns.L("bis_tooltip_rank"), notePlain(noteKind, noteIndex), 0.70, 0.78, 0.90, 1, 1, 1)

    local runTrack = getSeasonalMythicPlusSummary("run")
    if runTrack ~= "" then
        GameTooltip:AddDoubleLine(ns.L("bis_tooltip_end_of_run"), runTrack, 0.70, 0.78, 0.90, 0.82, 0.82, 0.92)
    end
    local vaultTrack = getSeasonalMythicPlusSummary("vault")
    if vaultTrack ~= "" then
        GameTooltip:AddDoubleLine(ns.L("bis_tooltip_vault"), vaultTrack, 0.70, 0.78, 0.90, 0.82, 0.82, 0.92)
    end

    if DUNGEON_EJ_IDS[entry.dungeon or ""] then
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine(ns.L("bis_tooltip_open_journal"), 0.35, 0.85, 1.00, true)
    end
    GameTooltip:Show()
end

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
    row.nameLabel:SetWidth(COL_NAME + COL_ICON)

    row.slotLabel = row:CreateFontString(nil, "OVERLAY")
    row.slotLabel:SetFont(FONT_PATH, 10, FONT_FLAGS)
    row.slotLabel:SetJustifyH("LEFT")
    row.slotLabel:SetJustifyV("MIDDLE")
    row.slotLabel:SetWidth(COL_SLOT)
    row.slotLabel:Hide()

    row.noteLabel = row:CreateFontString(nil, "OVERLAY")
    row.noteLabel:SetFont(FONT_PATH, 10, FONT_FLAGS)
    row.noteLabel:SetJustifyH("CENTER")
    row.noteLabel:SetJustifyV("MIDDLE")
    row.noteLabel:SetWidth(COL_NOTE)
    row.noteLabel:Hide()

    row.tooltipRegion = CreateFrame("Button", nil, row)
    row.tooltipRegion:SetAllPoints(row)
    row.tooltipRegion:EnableMouse(true)
    row.tooltipRegion:RegisterForClicks("LeftButtonUp")
    row.tooltipRegion:SetScript("OnClick", function()
        if row._sectionDungeon then
            openEncounterJournal(row._sectionDungeon)
        elseif row._entry and row._entry.dungeon then
            openEncounterJournal(row._entry.dungeon)
        end
    end)
    row.tooltipRegion:SetScript("OnEnter", function(self2)
        if row._sectionDungeon then
            GameTooltip:SetOwner(self2, "ANCHOR_BOTTOM")
            GameTooltip:SetText(localizeDungeon(row._sectionDungeon), 1, 1, 1, 1, true)
            local hint = DUNGEON_EJ_IDS[row._sectionDungeon or ""]
                and ns.L("bis_tooltip_open_journal")
                or ns.L("bis_tooltip_open_journal_missing")
            GameTooltip:AddLine(hint, 0.70, 0.78, 0.90, true)
            GameTooltip:Show()
        elseif row.itemID and row.itemID > 0 then
            showSeasonItemTooltip(self2, row)
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
    row._entry = nil
    row._sectionDungeon = nil
    row._displayNoteKind = nil
    row._displayNoteIndex = nil
end

-- ============================================================
-- 컨텐츠 빌드
-- ============================================================

function BISOverlay:RebuildContent()
    local frame = self.frame
    if not frame then return end

    -- 스크롤 위치 저장 (아이템 로드 재빌드일 때 복원용)
    local isItemLoadRebuild = self._isItemLoadRebuild
    self._isItemLoadRebuild = false
    local savedScroll = frame.scrollFrame:GetVerticalScroll()

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
        local slots, order = groupBySlot(bisData)
        local itemRowCount = 0

        for _, slotName in ipairs(order) do
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
            hdr.nameLabel:SetText(localizeSlot(slotName))
            hdr._sectionDungeon = nil
            hdr:Show()
            yOffset = yOffset + SECTION_H + 1

            local items = slots[slotName]

            for _, entry in ipairs(items) do
                rowIndex = rowIndex + 1
                itemRowCount = itemRowCount + 1
                local iRow = ensureRow(frame, rowIndex)
                iRow:ClearAllPoints()
                iRow:SetPoint("TOPLEFT", frame.content, "TOPLEFT", ITEM_INDENT, -yOffset)
                iRow:SetWidth(ITEM_W)
                iRow:SetHeight(ROW_H)
                iRow.itemID = entry.itemID
                iRow._entry = entry
                iRow._displayNoteKind = entry._displayNoteKind
                iRow._displayNoteIndex = entry._displayNoteIndex

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
                    else
                        requestItemData(entry.itemID)
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
                    local qc = getQualityColor(quality)
                    iRow.nameLabel:SetTextColor(qc[1], qc[2], qc[3], 1)
                    iRow.nameLabel:SetText(itemName)
                else
                    iRow.nameLabel:SetTextColor(QC[4][1], QC[4][2], QC[4][3], 0.50)
                    iRow.nameLabel:SetText("...")
                end

                -- 던전 출처
                if entry.dungeon then
                    iRow.slotLabel:ClearAllPoints()
                    iRow.slotLabel:SetPoint("LEFT", iRow, "LEFT", COL_ICON + COL_NAME, 0)
                    iRow.slotLabel:SetWidth(COL_SLOT)
                    iRow.slotLabel:SetFont(FONT_PATH, 10, FONT_FLAGS)
                    iRow.slotLabel:SetTextColor(0.72, 0.72, 0.72, 1)
                    iRow.slotLabel:SetText(localizeDungeon(entry.dungeon))
                    iRow.slotLabel:Show()
                end

                -- note 배지
                local noteTxt = noteBadge(entry._displayNoteKind, entry._displayNoteIndex)
                if noteTxt and noteTxt ~= "" then
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

    -- 스크롤 복원(아이템 로드) 또는 초기화(스펙 변경), 썸 업데이트 (레이아웃 확정 후)
    C_Timer.After(0, function()
        if isItemLoadRebuild and savedScroll > 0 then
            local maxScroll = frame.scrollFrame:GetVerticalScrollRange()
            frame.scrollFrame:SetVerticalScroll(math.min(savedScroll, maxScroll))
        else
            frame.scrollFrame:SetVerticalScroll(0)
        end
        self:UpdateScrollThumb()
    end)
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
