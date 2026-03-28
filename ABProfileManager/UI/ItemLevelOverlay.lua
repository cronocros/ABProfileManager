local _, ns = ...

local ItemLevelOverlay = {}
ns.UI.ItemLevelOverlay = ItemLevelOverlay

local FONT_PATH  = UNIT_NAME_FONT or STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF"
local FONT_FLAGS = "OUTLINE"
local FRAME_W    = 380
local TITLE_H    = 22
local TAB_H      = 18
local ROW_H      = 17
local ROW_GAP    = 2
local PADDING    = 6

-- 4열: 단(label) | 클리어보상(drop) | 드랍문장(crest) | 위대한금고(vault)
local COL_DROP_X  = 56   -- 클리어보상 열 시작 (label width=50)
local COL_CREST_X = 144  -- 드랍문장 열 시작 (drop width=86)
local COL_VAULT_X = 212  -- 위대한금고 열 시작 (crest width=66)

local SCALE_STEP = 0.05
local SCALE_MIN  = 0.50
local SCALE_MAX  = 2.00

local TAB_KEYS = { "overview", "mythicplus", "delves", "raid", "other" }

local HEADER_COLOR = { 0.50, 0.58, 0.68 }

local GRADE_COLORS = {
    expl = { 0.62, 0.62, 0.62 },
    adv  = { 0.90, 0.90, 0.90 },
    vet  = { 0.30, 0.90, 0.30 },
    chmp = { 0.28, 0.68, 1.00 },  -- 파랑
    hero = { 0.72, 0.35, 1.00 },  -- 보라
    myth = { 1.00, 0.20, 0.20 },  -- 빨강
}

-- 드랍 문장 색상 (등급 색상과 동일)
local CREST_COLORS = {
    chmp = { 0.28, 0.68, 1.00 },  -- 파랑
    hero = { 0.72, 0.35, 1.00 },  -- 보라
    myth = { 1.00, 0.20, 0.20 },  -- 빨강
}

local function colorHex(r, g, b)
    return string.format("%02X%02X%02X",
        math.floor(r * 255 + 0.5), math.floor(g * 255 + 0.5), math.floor(b * 255 + 0.5))
end

local function inlineColor(hex, text)
    return "|cFF" .. hex .. text .. "|r"
end

-- ============================================================
-- 헬퍼
-- ============================================================

local function getAverageItemLevel()
    if type(GetAverageItemLevel) == "function" then
        return math.floor((GetAverageItemLevel() or 0) + 0.5)
    end
    return 0
end

local function makeFS(parent, size, r, g, b)
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

-- 등급명+rank에 인라인 색상 적용: "|cFFrrggbb챔피 2/6|r"
local function gradeRankColored(grade, rank, rankMax)
    if not grade then return "" end
    local name = ns.L("ilvl_grade_"..grade) or grade
    local rankPart = (rank and rankMax) and (" "..rank.."/"..rankMax) or ""
    local gc = GRADE_COLORS[grade]
    if not gc then return name..rankPart end
    return inlineColor(colorHex(gc[1], gc[2], gc[3]), name..rankPart)
end

-- 클리어 보상: 숫자(흰색, base color) + 등급명(인라인 색상)
local function clearRewardStr(ilvl, grade, rank, rankMax)
    if not ilvl then return "" end
    local gp = gradeRankColored(grade, rank, rankMax)
    return gp ~= "" and (tostring(ilvl).." "..gp) or tostring(ilvl)
end

-- 위대한 금고: 동일 포맷
local function vaultClearStr(vault, vaultGrade, vaultRank, rankMax)
    if not vault then return "-" end
    return clearRewardStr(vault, vaultGrade, vaultRank, rankMax)
end

local function getConfig()
    return ns.DB and ns.DB:GetItemLevelOverlayConfig()
        or ns.Data.Defaults.ui.itemLevelOverlay
end

local function setScale(frame, delta)
    local cfg = getConfig()
    if not cfg then return end
    local cur = cfg.scale or 1
    cur = math.max(SCALE_MIN, math.min(SCALE_MAX, cur + delta))
    cur = math.floor(cur * 100 + 0.5) / 100
    cfg.scale = cur
    frame:SetScale(cur)
end

-- ============================================================
-- 행 데이터 빌더
-- ============================================================

-- 열 헤더: 단 | 클리어보상 | 드랍문장 | 위대한금고
local function colHeader(sourceKey, dropKey, vaultKey, crestKey)
    return {
        isColumnHeader = true,
        label    = ns.L(sourceKey),
        dropStr  = dropKey  and ns.L(dropKey)  or "",
        vaultStr = vaultKey and ns.L(vaultKey) or "",
        crestStr = crestKey and ns.L(crestKey) or "",
    }
end

-- 쐐기/던전 행
local function mRow(label, e, avgIlvl)
    return {
        label      = label,
        dropStr    = clearRewardStr(e.ilvl, e.grade, e.rank, e.rankMax),
        vaultStr   = vaultClearStr(e.vault, e.vaultGrade, e.vaultRank, e.vaultMax),
        crestDrop  = e.crestDrop,
        grade      = e.grade,
        vaultGrade = e.vaultGrade,
        highlight  = avgIlvl > 0 and e.ilvl > avgIlvl,
        vaultHL    = e.vault and avgIlvl > 0 and e.vault > avgIlvl or false,
    }
end

-- 레이드 행 (min~max 범위 + 주간보상)
local function raidRow(key, e, avgIlvl)
    return {
        label      = ns.L(e.labelKey or ("ilvl_raid_"..key)),
        dropStr    = tostring(e.min).."~"..tostring(e.max),
        vaultStr   = e.vault and tostring(e.vault) or "-",
        crestDrop  = e.crestDrop,
        grade      = e.grade,
        vaultGrade = e.vaultGrade,
        highlight  = avgIlvl > 0 and e.max > avgIlvl,
        vaultHL    = e.vault and avgIlvl > 0 and e.vault > avgIlvl or false,
    }
end

-- 구렁 행 (rank 없음)
local function delveRow(label, e, avgIlvl)
    return {
        label      = label,
        dropStr    = clearRewardStr(e.ilvl, e.grade, nil, nil),
        vaultStr   = vaultClearStr(e.vault, e.vaultGrade, nil, nil),
        crestDrop  = e.crestDrop,
        grade      = e.grade,
        vaultGrade = e.vaultGrade,
        highlight  = avgIlvl > 0 and e.ilvl > avgIlvl,
        vaultHL    = e.vault and avgIlvl > 0 and e.vault > avgIlvl or false,
    }
end

local function buildOverviewRows(avgIlvl)
    local tbl = ns.Data and ns.Data.ItemLevelTable
    if not tbl then return {} end
    local rows = {}
    local function spacer() rows[#rows+1] = { isSpacer=true } end

    -- 쐐기 (전체: heroic/mythic0 + endOfDungeon)
    if tbl.mythicPlus then
        rows[#rows+1] = { isHeader=true, label=ns.L("ilvl_section_mythicplus") }
        rows[#rows+1] = colHeader("ilvl_col_key", "ilvl_col_drop", "ilvl_col_vault", "ilvl_col_crest")
        for _, key in ipairs({ "heroic", "mythic0" }) do
            local e = tbl.mythicPlus[key]
            if e then rows[#rows+1] = mRow(ns.L(e.labelKey or key), e, avgIlvl) end
        end
        for _, e in ipairs(tbl.mythicPlus.endOfDungeon or {}) do
            rows[#rows+1] = mRow(tostring(e.key).."단", e, avgIlvl)
        end
    end

    -- 레이드 (전체)
    if tbl.raid then
        spacer()
        rows[#rows+1] = { isHeader=true, label=ns.L("ilvl_section_raid") }
        rows[#rows+1] = colHeader("ilvl_col_difficulty", "ilvl_col_drop", "ilvl_col_vault", "ilvl_col_crest")
        for _, key in ipairs({ "normal", "heroic", "mythic" }) do
            local e = tbl.raid[key]
            if e then rows[#rows+1] = raidRow(key, e, avgIlvl) end
        end
    end

    -- 구렁 (최고 단계만)
    if tbl.delves and #tbl.delves > 0 then
        spacer()
        rows[#rows+1] = { isHeader=true, label=ns.L("ilvl_section_delves") }
        rows[#rows+1] = colHeader("ilvl_col_tier", "ilvl_col_drop", "ilvl_col_vault", "ilvl_col_crest")
        local last = tbl.delves[#tbl.delves]
        rows[#rows+1] = delveRow(tostring(last.tier).."단계", last, avgIlvl)
    end

    -- 제작 (하단)
    if tbl.crafted then
        spacer()
        rows[#rows+1] = { isHeader=true, label=ns.L("ilvl_section_crafted") }
        for _, k in ipairs({ "base", "r5" }) do
            local e = tbl.crafted[k]
            if e then
                rows[#rows+1] = {
                    label     = ns.L(e.labelKey or k),
                    dropStr   = tostring(e.ilvl),
                    vaultStr  = "",
                    crestDrop = nil,
                    grade     = nil,
                    highlight = avgIlvl > 0 and e.ilvl > avgIlvl,
                    vaultHL   = false,
                }
            end
        end
    end

    return rows
end

local function buildDelveRows(avgIlvl)
    local tbl = ns.Data and ns.Data.ItemLevelTable
    if not tbl or not tbl.delves then return {} end
    local rows = {}
    rows[#rows+1] = colHeader("ilvl_col_tier", "ilvl_col_drop", "ilvl_col_vault", "ilvl_col_crest")
    for _, e in ipairs(tbl.delves) do
        rows[#rows+1] = delveRow(tostring(e.tier).."단계", e, avgIlvl)
    end
    return rows
end

local function buildMythicPlusRows(avgIlvl)
    local tbl = ns.Data and ns.Data.ItemLevelTable
    if not tbl or not tbl.mythicPlus then return {} end
    local rows = {}
    rows[#rows+1] = colHeader("ilvl_col_key", "ilvl_col_drop", "ilvl_col_vault", "ilvl_col_crest")
    for _, key in ipairs({ "heroic", "mythic0" }) do
        local e = tbl.mythicPlus[key]
        if e then rows[#rows+1] = mRow(ns.L(e.labelKey or key), e, avgIlvl) end
    end
    for _, e in ipairs(tbl.mythicPlus.endOfDungeon or {}) do
        rows[#rows+1] = mRow(tostring(e.key).."단", e, avgIlvl)
    end
    return rows
end

local function buildRaidRows(avgIlvl)
    local tbl = ns.Data and ns.Data.ItemLevelTable
    if not tbl or not tbl.raid then return {} end
    local rows = {}
    rows[#rows+1] = colHeader("ilvl_col_difficulty", "ilvl_col_drop", nil, "ilvl_col_crest")
    for _, key in ipairs({ "normal", "heroic", "mythic" }) do
        local e = tbl.raid[key]
        if e then rows[#rows+1] = raidRow(key, e, avgIlvl) end
    end
    local wb = tbl.worldBoss
    if wb then
        rows[#rows+1] = { isHeader=true, label="" }
        rows[#rows+1] = {
            label     = ns.L("ilvl_world_boss"),
            dropStr   = clearRewardStr(wb.ilvl, wb.grade, nil, nil),
            vaultStr  = "",
            crestDrop = wb.crestDrop,
            grade     = wb.grade,
            highlight = avgIlvl > 0 and wb.ilvl > avgIlvl,
            vaultHL   = false,
        }
    end
    return rows
end

local function buildOtherRows(avgIlvl)
    local tbl = ns.Data and ns.Data.ItemLevelTable
    if not tbl then return {} end
    local rows = {}
    if tbl.crafted then
        rows[#rows+1] = { isHeader=true, label=ns.L("ilvl_section_crafted") }
        for _, k in ipairs({ "base", "r5" }) do
            local e = tbl.crafted[k]
            if e then
                rows[#rows+1] = {
                    label     = ns.L(e.labelKey or k),
                    dropStr   = tostring(e.ilvl),
                    vaultStr  = "",
                    crestDrop = nil,
                    grade     = nil,
                    highlight = avgIlvl > 0 and e.ilvl > avgIlvl,
                    vaultHL   = false,
                }
            end
        end
    end
    if tbl.pvp then
        rows[#rows+1] = { isHeader=true, label=ns.L("ilvl_section_pvp") }
        for _, k in ipairs({ "honor", "conquest" }) do
            local e = tbl.pvp[k]
            if e then
                rows[#rows+1] = {
                    label     = ns.L(e.labelKey or k),
                    dropStr   = tostring(e.min).."~"..tostring(e.max),
                    vaultStr  = "",
                    crestDrop = nil,
                    grade     = nil,
                    highlight = false,
                    vaultHL   = false,
                }
            end
        end
    end
    return rows
end

-- ============================================================
-- 프레임 생성
-- ============================================================

function ItemLevelOverlay:EnsureFrame()
    if self.frame then return self.frame end

    local config = getConfig()

    local frame = CreateFrame("Frame", "ABPMItemLevelOverlay", UIParent, "BackdropTemplate")
    frame:SetFrameStrata("DIALOG")
    frame:SetClampedToScreen(true)
    frame:SetSize(FRAME_W, TITLE_H + 6)

    if frame.SetBackdrop then
        frame:SetBackdrop({
            bgFile   = "Interface\\Tooltips\\UI-Tooltip-Background",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true, tileSize = 8, edgeSize = 8,
            insets = { left=2, right=2, top=2, bottom=2 },
        })
        frame:SetBackdropColor(0.04, 0.04, 0.06, 0.85)
        frame:SetBackdropBorderColor(0.4, 0.4, 0.5, 0.80)
    end

    local mode = config.anchorMode or "mythicplus"
    if mode == "mythicplus" then
        local kf = KeystoneFrame or ChallengesFrame
        if kf and kf:IsShown() then
            frame:SetPoint("TOPLEFT", kf, "TOPRIGHT", 10, 0)
        else
            frame:SetPoint(config.point or "CENTER", UIParent,
                config.relativePoint or "CENTER", config.x or 350, config.y or -100)
        end
    else
        frame:SetPoint(config.point or "CENTER", UIParent,
            config.relativePoint or "CENTER", config.x or 350, config.y or -100)
    end

    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", function(f)
        if ns.DB and ns.DB:IsItemLevelOverlayLocked() then return end
        f:StartMoving()
    end)
    frame:SetScript("OnDragStop", function(f)
        f:StopMovingOrSizing()
        if ns.DB then
            local cfg = ns.DB:GetItemLevelOverlayConfig()
            if cfg then cfg.anchorMode = "overlay" end
            ns.DB:SaveItemLevelOverlayPosition(f)
        end
    end)

    frame:EnableMouseWheel(true)
    frame:SetScript("OnMouseWheel", function(f, delta)
        setScale(f, delta * SCALE_STEP)
    end)

    -- 타이틀 바
    local titleBar = frame:CreateTexture(nil, "BACKGROUND")
    titleBar:SetColorTexture(0.14, 0.14, 0.22, 0.80)
    titleBar:SetPoint("TOPLEFT",  frame, "TOPLEFT",  2, -2)
    titleBar:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -2, -2)
    titleBar:SetHeight(TITLE_H)

    -- 메인 타이틀
    local titleText = makeFS(frame, 12, 0.85, 0.85, 1.00)
    titleText:SetPoint("LEFT", titleBar, "LEFT", 6, 2)
    titleText:SetText(ns.L("ilvl_overlay_title"))
    frame.titleText = titleText

    -- 스크롤 힌트 (작은 폰트)
    local hintText = makeFS(frame, 9, 0.50, 0.50, 0.60)
    hintText:SetPoint("LEFT", titleText, "RIGHT", 4, 0)
    hintText:SetText(ns.L("ilvl_overlay_hint"))
    frame.hintText = hintText

    local avgLabel = makeFS(frame, 10, 0.70, 0.70, 0.80)
    avgLabel:SetPoint("RIGHT", titleBar, "RIGHT", -24, 0)
    avgLabel:SetText("")
    frame.avgLabel = avgLabel

    local toggleBtn = CreateFrame("Button", nil, frame)
    toggleBtn:SetSize(18, 18)
    toggleBtn:SetPoint("RIGHT", titleBar, "RIGHT", -3, 0)
    makeBtnText(toggleBtn, 12, 0.80, 0.80, 1.00)
    toggleBtn:SetText("-")
    frame.toggleBtn = toggleBtn

    -- 탭 행
    local tabRow = CreateFrame("Frame", nil, frame)
    tabRow:SetPoint("TOPLEFT",  titleBar, "BOTTOMLEFT",  0, -2)
    tabRow:SetPoint("TOPRIGHT", titleBar, "BOTTOMRIGHT", 0, -2)
    tabRow:SetHeight(TAB_H + 2)
    frame.tabRow = tabRow

    local tabW = math.floor((FRAME_W - 4) / #TAB_KEYS) - 2
    frame.tabs = {}
    for i, tabKey in ipairs(TAB_KEYS) do
        local btn = CreateFrame("Button", nil, tabRow)
        btn:SetHeight(TAB_H)
        btn:SetWidth(tabW)
        if i == 1 then
            btn:SetPoint("TOPLEFT", tabRow, "TOPLEFT", 2, 0)
        else
            btn:SetPoint("LEFT", frame.tabs[i-1], "RIGHT", 2, 0)
        end
        local bg = btn:CreateTexture(nil, "BACKGROUND")
        bg:SetAllPoints()
        bg:SetColorTexture(0.15, 0.15, 0.25, 0.80)
        btn.bg = bg
        makeBtnText(btn, 10, 0.70, 0.70, 0.80)
        btn.tabKey = tabKey
        frame.tabs[i] = btn
    end

    local content = CreateFrame("Frame", nil, frame)
    content:SetPoint("TOPLEFT",  tabRow, "BOTTOMLEFT",  2, -2)
    content:SetPoint("RIGHT",    frame,  "RIGHT",       -4, 0)
    frame.content = content

    frame.rows = {}

    toggleBtn:SetScript("OnClick", function() self:ToggleCollapsed() end)
    for _, btn in ipairs(frame.tabs) do
        btn:SetScript("OnClick", function() self:SelectTab(btn.tabKey) end)
    end

    self.frame      = frame
    self.collapsed  = config.collapsed or false
    self.currentTab = config.currentTab or "overview"
    frame:SetScale(config.scale or 1)
    return frame
end

-- ============================================================
-- 행 보장 (4열: 단 | 드랍 | 등급 | 주간)
-- ============================================================

function ItemLevelOverlay:EnsureRow(index)
    if not self.frame then return nil end
    self.frame.rows = self.frame.rows or {}
    if self.frame.rows[index] then return self.frame.rows[index] end

    local row = CreateFrame("Frame", nil, self.frame.content)
    row:SetHeight(ROW_H)

    -- 열1: 소스 (단/난이도)
    row.label = makeFS(row, 11, 0.78, 0.78, 0.90)
    row.label:SetPoint("LEFT", row, "LEFT", 4, 0)
    row.label:SetWidth(COL_DROP_X - 6)
    row.label:SetJustifyH("LEFT")

    -- 열2: 클리어 보상 (ilvl + 등급 + rank)
    row.drop = makeFS(row, 10, 0.96, 0.86, 0.60)
    row.drop:SetPoint("LEFT", row, "LEFT", COL_DROP_X, 0)
    row.drop:SetWidth(COL_CREST_X - COL_DROP_X - 2)
    row.drop:SetJustifyH("LEFT")

    -- 열3: 드랍 문장
    row.crest = makeFS(row, 10, 0.70, 0.70, 0.80)
    row.crest:SetPoint("LEFT", row, "LEFT", COL_CREST_X, 0)
    row.crest:SetWidth(COL_VAULT_X - COL_CREST_X - 2)
    row.crest:SetJustifyH("LEFT")

    -- 열4: 위대한 금고
    row.vault = makeFS(row, 10, 0.55, 0.85, 0.55)
    row.vault:SetPoint("LEFT", row, "LEFT", COL_VAULT_X, 0)
    row.vault:SetWidth(FRAME_W - 4 - COL_VAULT_X)
    row.vault:SetJustifyH("LEFT")

    self.frame.rows[index] = row
    return row
end

-- ============================================================
-- 탭 선택 / 최소화
-- ============================================================

function ItemLevelOverlay:SelectTab(tabKey)
    self.currentTab = tabKey or "overview"
    local config = ns.DB and ns.DB:GetItemLevelOverlayConfig()
    if config then config.currentTab = self.currentTab end
    self:RebuildContent()
end

function ItemLevelOverlay:ToggleCollapsed()
    self.collapsed = not self.collapsed
    local config = ns.DB and ns.DB:GetItemLevelOverlayConfig()
    if config then config.collapsed = self.collapsed end
    self:UpdateLayout()
end

-- ============================================================
-- 컨텐츠 재구성
-- ============================================================

function ItemLevelOverlay:RebuildContent()
    local frame = self.frame
    if not frame then return end

    local avgIlvl = getAverageItemLevel()
    local avgText = avgIlvl > 0 and tostring(avgIlvl) or "?"
    frame.avgLabel:SetText(ns.L("ilvl_avg_label", avgText))
    frame.titleText:SetText(ns.L("ilvl_overlay_title"))
    if frame.hintText then
        frame.hintText:SetText(ns.L("ilvl_overlay_hint"))
    end

    for _, btn in ipairs(frame.tabs or {}) do
        local active = btn.tabKey == self.currentTab
        btn:SetText(ns.L("ilvl_tab_"..btn.tabKey))
        if active then
            btn.bg:SetColorTexture(0.30, 0.30, 0.55, 0.95)
            btn:GetFontString():SetTextColor(1, 1, 1, 1)
        else
            btn.bg:SetColorTexture(0.15, 0.15, 0.25, 0.80)
            btn:GetFontString():SetTextColor(0.70, 0.70, 0.80, 1)
        end
    end

    local rowData = {}
    if     self.currentTab == "overview"   then rowData = buildOverviewRows(avgIlvl)
    elseif self.currentTab == "mythicplus" then rowData = buildMythicPlusRows(avgIlvl)
    elseif self.currentTab == "delves"     then rowData = buildDelveRows(avgIlvl)
    elseif self.currentTab == "raid"       then rowData = buildRaidRows(avgIlvl)
    elseif self.currentTab == "other"      then rowData = buildOtherRows(avgIlvl)
    end

    local yOffset = 2
    for i, data in ipairs(rowData) do
        local row = self:EnsureRow(i)
        if not row then break end
        row:ClearAllPoints()
        row:SetPoint("TOPLEFT", frame.content, "TOPLEFT", 0, -yOffset)
        row:SetPoint("RIGHT",   frame.content, "RIGHT",   0, 0)
        row:Show()

        if data.isSpacer then
            row.label:SetText(""); row.drop:SetText(""); row.vault:SetText(""); row.crest:SetText("")
            row:SetHeight(5)
            yOffset = yOffset + 5

        elseif data.isColumnHeader then
            local cr, cg, cb = HEADER_COLOR[1], HEADER_COLOR[2], HEADER_COLOR[3]
            row.label:SetWidth(COL_DROP_X - 6)
            row.label:SetFont(FONT_PATH, 9, FONT_FLAGS); row.label:SetTextColor(cr,cg,cb,1); row.label:SetText(data.label or "")
            row.drop:SetFont(FONT_PATH, 9, FONT_FLAGS);  row.drop:SetTextColor(cr,cg,cb,1);  row.drop:SetText(data.dropStr or "")
            row.vault:SetFont(FONT_PATH, 9, FONT_FLAGS); row.vault:SetTextColor(cr,cg,cb,1); row.vault:SetText(data.vaultStr or "")
            row.crest:SetFont(FONT_PATH, 9, FONT_FLAGS); row.crest:SetTextColor(cr,cg,cb,1); row.crest:SetText(data.crestStr or "")
            row:SetHeight(ROW_H - 2)
            yOffset = yOffset + (ROW_H - 2) + ROW_GAP + 1

        elseif data.isHeader then
            row.label:SetWidth(FRAME_W - 10)
            row.label:SetFont(FONT_PATH, 10, FONT_FLAGS)
            row.label:SetTextColor(0.65, 0.85, 1.00, 1)
            row.label:SetText(data.label or "")
            row.drop:SetText(""); row.vault:SetText(""); row.crest:SetText("")
            row:SetHeight(ROW_H - 2)
            yOffset = yOffset + (ROW_H - 2) + ROW_GAP

        else
            row.label:SetWidth(COL_DROP_X - 6)
            row.label:SetFont(FONT_PATH, 11, FONT_FLAGS)
            row.drop:SetFont(FONT_PATH, 10, FONT_FLAGS)
            row.vault:SetFont(FONT_PATH, 10, FONT_FLAGS)
            row.crest:SetFont(FONT_PATH, 10, FONT_FLAGS)

            local up = data.highlight
            row.label:SetTextColor(up and 0.95 or 0.68, up and 0.95 or 0.68, up and 0.95 or 0.75, 1)
            row.label:SetText(data.label or "")

            -- 클리어 보상: 숫자는 base color(흰색/녹색), 등급명은 인라인 색상
            -- SetTextColor가 |c 코드 밖의 숫자 색상을 결정
            if up then
                row.drop:SetTextColor(0.40, 0.94, 0.55, 1)  -- 업그레이드 가능: 숫자 녹색
            else
                row.drop:SetTextColor(1, 1, 1, 1)             -- 일반: 숫자 흰색
            end
            row.drop:SetText(data.dropStr or "")

            -- 위대한 금고 열
            local vs = data.vaultStr or ""
            if vs == "" or vs == "-" then
                row.vault:SetTextColor(0.35, 0.35, 0.38, 1)
                row.vault:SetText(vs)
            else
                if data.vaultHL then
                    row.vault:SetTextColor(0.40, 0.94, 0.55, 1)
                else
                    row.vault:SetTextColor(0.82, 0.82, 0.88, 1)  -- 금고 숫자: 약간 밝은 흰색
                end
                row.vault:SetText(vs)
            end

            -- 드랍 문장 열 (인라인 색상으로 전체 표시)
            if data.crestDrop then
                local cc = CREST_COLORS[data.crestDrop] or { 0.70, 0.70, 0.80 }
                local hex = colorHex(cc[1], cc[2], cc[3])
                local crestText = ns.L("ilvl_crest_"..data.crestDrop) or data.crestDrop
                row.crest:SetTextColor(1, 1, 1, 1)
                row.crest:SetText(inlineColor(hex, crestText))
            else
                row.crest:SetTextColor(0.35, 0.35, 0.38, 1)
                row.crest:SetText("")
            end

            row:SetHeight(ROW_H)
            yOffset = yOffset + ROW_H + ROW_GAP
        end
    end

    for i = #rowData + 1, #(frame.rows or {}) do
        frame.rows[i]:Hide()
    end

    self.contentHeight = TITLE_H + 4 + (TAB_H + 4) + yOffset + PADDING
    self:UpdateLayout()
end

-- ============================================================
-- 레이아웃
-- ============================================================

function ItemLevelOverlay:UpdateLayout()
    local frame = self.frame
    if not frame then return end

    if self.collapsed then
        frame:SetHeight(TITLE_H + 6)
        frame.tabRow:Hide()
        frame.content:Hide()
        frame.toggleBtn:SetText("+")
    else
        local h = math.max(self.contentHeight or 120, TITLE_H + TAB_H + 40)
        frame:SetHeight(h)
        frame.tabRow:Show()
        frame.content:Show()
        frame.toggleBtn:SetText("-")
    end
end

-- ============================================================
-- Refresh / Initialize
-- ============================================================

function ItemLevelOverlay:Refresh()
    if not ns.DB or not ns.DB:IsItemLevelOverlayEnabled() then
        if self.frame then self.frame:Hide() end
        return
    end

    -- 파티찾기(PVEFrame)가 열려있을 때만 표시
    local pve = PVEFrame or LFGParentFrame
    if not pve or not pve:IsShown() then
        if self.frame then self.frame:Hide() end
        return
    end

    if not self.frame then self:EnsureFrame() end
    if not self.frame then return end

    self:RebuildContent()
    self.frame:Show()
end

function ItemLevelOverlay:Initialize()
    if self._initialized then return end
    self._initialized = true

    -- PVEFrame (파티찾기) 전용 연동
    local function setupPVEHooks()
        local pve = PVEFrame or LFGParentFrame
        if not pve then return false end

        pve:HookScript("OnShow", function()
            if not ns.DB or not ns.DB:IsItemLevelOverlayEnabled() then return end
            self:EnsureFrame()
            if self.frame then
                self.frame:ClearAllPoints()
                self.frame:SetPoint("TOPLEFT", pve, "TOPRIGHT", 10, 0)
                self:Refresh()
            end
        end)
        pve:HookScript("OnHide", function()
            if self.frame then self.frame:Hide() end
        end)

        -- 이미 열려 있으면 즉시 표시
        if pve:IsShown() and ns.DB and ns.DB:IsItemLevelOverlayEnabled() then
            self:EnsureFrame()
            if self.frame then
                self.frame:ClearAllPoints()
                self.frame:SetPoint("TOPLEFT", pve, "TOPRIGHT", 10, 0)
                self:Refresh()
            end
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
