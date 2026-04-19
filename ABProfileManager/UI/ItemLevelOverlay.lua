local _, ns = ...

local ItemLevelOverlay = {}
ns.UI.ItemLevelOverlay = ItemLevelOverlay

local FONT_PATH  = UNIT_NAME_FONT or STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF"
local FONT_FLAGS = "OUTLINE"
local FRAME_W    = 448
local TITLE_H    = 22
local TAB_H      = 18
local ROW_H      = 17
local ROW_GAP    = 2
local PADDING    = 6
local CREST_LINE_H = 16
local CREST_VALUE_W = 34

local TAB_GAP    = 2

-- 4열: 단(label) | 클리어보상(drop) | 드랍문장(crest) | 위대한금고(vault)
-- 우측에는 나의 문장을 고정 패널로 1회만 표시한다.
local CREST_PANEL_W = 100
local TABLE_GAP     = 0
local CONTENT_W     = FRAME_W - 8
local TABLE_W       = CONTENT_W - CREST_PANEL_W - TABLE_GAP
local COL_DROP_X    = 80
local COL_CREST_X   = 168
local COL_VAULT_X   = 218

local SCALE_STEP = 0.05
local SCALE_MIN  = 0.50
local SCALE_MAX  = 2.00

local TAB_KEYS = { "overview", "mythicplus", "delves", "raid", "other" }
local DELVE_RESTORED_KEY_CURRENCY_ID = 3028
local DELVE_KEY_FRAGMENT_ITEM_ID = nil
local DELVE_MAP_IDS = { 2395, 2413, 2405, 2437, 1270 }

-- Midnight 시즌 1 Dawncrest 통화 ID — 등급별 보유량 조회용
-- 인게임 확인 결과와 현 시즌 애드온 데이터 기준으로 보정한 값이다.
local CREST_ID_BY_GRADE = {
    adv  = 3383,
    vet  = 3341,
    chmp = 3343,
    hero = 3345,
    myth = 3347,
}

local HEADER_COLOR = { 0.50, 0.58, 0.68 }
local CREST_PANEL_GRADES = { "adv", "vet", "chmp", "hero", "myth" }
local _cachedBountifulDelveNames = nil

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
    adv  = { 0.90, 0.90, 0.90 },  -- 밝은 회색 (모험가)
    vet  = { 0.30, 0.90, 0.30 },  -- 초록 (노련가)
    chmp = { 0.28, 0.68, 1.00 },  -- 파랑 (챔피언)
    hero = { 0.72, 0.35, 1.00 },  -- 보라 (영웅)
    myth = { 1.00, 0.20, 0.20 },  -- 빨강 (신화)
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

-- 등급명에 인라인 색상 적용
local function gradeRankColored(grade, rank, rankMax, showUnknownRank)
    if not grade then return "" end
    local name = ns.L("ilvl_crest_"..grade) or ns.L("ilvl_grade_"..grade) or grade
    if rank and rankMax then
        name = string.format("%s %d/%d", name, rank, rankMax)
    elseif showUnknownRank then
        name = string.format("%s ?/?", name)
    end
    local gc = GRADE_COLORS[grade]
    if not gc then return name end
    return inlineColor(colorHex(gc[1], gc[2], gc[3]), name)
end

-- 클리어 보상: 숫자(흰색, base color) + 등급명(인라인 색상)
local function clearRewardStr(ilvl, grade, rank, rankMax, showUnknownRank)
    if not ilvl then return "" end
    local gp = gradeRankColored(grade, rank, rankMax, showUnknownRank)
    return gp ~= "" and (tostring(ilvl).." "..gp) or tostring(ilvl)
end

-- 위대한 금고: 동일 포맷
local function vaultClearStr(vault, vaultGrade, vaultRank, rankMax, showUnknownRank)
    if not vault then return "-" end
    return clearRewardStr(vault, vaultGrade, vaultRank, rankMax, showUnknownRank)
end

local function getConfig()
    return ns.DB and ns.DB:GetItemLevelOverlayConfig()
        or ns.Data.Defaults.ui.itemLevelOverlay
end

local function setScale(frame, delta)
    local cfg = getConfig()
    if not cfg then return end
    local oldScale = cfg.scale or 1
    local cur = math.max(SCALE_MIN, math.min(SCALE_MAX, oldScale + delta))
    cur = math.floor(cur * 100 + 0.5) / 100
    cfg.scale = cur
    if oldScale ~= cur then
        local left = frame:GetLeft()
        local top = frame:GetTop()
        if left and top then
            frame:SetScale(cur)
            frame:ClearAllPoints()
            frame:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT",
                left * oldScale / cur,
                top * oldScale / cur)
            cfg.anchorMode = "overlay"
            if ns.DB and ns.DB.SaveItemLevelOverlayPosition then
                ns.DB:SaveItemLevelOverlayPosition(frame)
            end
        else
            frame:SetScale(cur)
        end
    end
end

local function applyOverlayPoint(frame, anchorTarget)
    if not frame then
        return
    end

    local config = getConfig()
    local mode = config and config.anchorMode or "mythicplus"

    frame:ClearAllPoints()
    if mode == "mythicplus" and anchorTarget and anchorTarget:IsShown() then
        frame:SetPoint("TOPLEFT", anchorTarget, "TOPRIGHT", 10, 0)
        return
    end

    frame:SetPoint(
        config.point or "CENTER",
        UIParent,
        config.relativePoint or "CENTER",
        config.x or 350,
        config.y or -100
    )
end

-- ============================================================
-- 행 데이터 빌더
-- ============================================================

-- 나의 문장: crestDrop 등급에 해당하는 현재 보유량 조회
local function getMyCount(grade)
    if not grade then return nil end
    local id = CREST_ID_BY_GRADE[grade]
    if not id then return nil end
    local info = C_CurrencyInfo and C_CurrencyInfo.GetCurrencyInfo(id)
    return info and info.quantity
end

local function getCurrencyCount(id)
    if not id then return nil end
    local info = C_CurrencyInfo and C_CurrencyInfo.GetCurrencyInfo(id)
    return info and info.quantity or nil
end

local function getItemCountByID(itemID)
    if not itemID or not C_Item or not C_Item.GetItemCount then
        return nil
    end
    local ok, count = pcall(C_Item.GetItemCount, itemID, false, false, false, false)
    if ok then
        return count
    end
    return nil
end

local function crestCountParts(grade)
    local qty = getMyCount(grade)
    local cc = CREST_COLORS[grade] or { 0.85, 0.85, 0.85 }
    local name = ns.L("ilvl_crest_"..grade) or grade
    local value = qty ~= nil and tostring(qty) or "-"
    return name, value, cc[1], cc[2], cc[3]
end

local function sectionSummaryParts()
    local tbl = ns.Data and ns.Data.ItemLevelTable
    local gradeMax = tbl and tbl.gradeMax
    if not gradeMax then
        return {}
    end

    local parts = {}
    for _, grade in ipairs({ "chmp", "hero", "myth" }) do
        local maxIlvl = gradeMax[grade]
        if maxIlvl then
            local cc = CREST_COLORS[grade] or GRADE_COLORS[grade] or { 0.85, 0.85, 0.85 }
            local hex = colorHex(cc[1], cc[2], cc[3])
            local name = ns.L("ilvl_crest_"..grade) or ns.L("ilvl_grade_"..grade) or grade
            parts[#parts+1] = inlineColor(hex, name) .. " ~" .. tostring(maxIlvl)
        end
    end

    return parts
end

local function sectionSummaryText(label)
    local parts = sectionSummaryParts()
    if #parts == 0 then
        return label
    end
    return tostring(label) .. "  " .. table.concat(parts, "  ")
end

local function mythicPlusSummaryText()
    return sectionSummaryText(ns.L("ilvl_section_mythicplus"))
end

local function getBestEffortBountifulDelveNames()
    if _cachedBountifulDelveNames then
        return _cachedBountifulDelveNames
    end

    local names = {}
    local seen = {}

    local function addName(name)
        if not name or name == "" or seen[name] then
            return
        end
        seen[name] = true
        names[#names + 1] = name
    end

    if C_GossipInfo and C_GossipInfo.GetActiveDelveGossip then
        local active = C_GossipInfo.GetActiveDelveGossip()
        addName(active and active.name)
    end

    if C_AreaPoiInfo and C_AreaPoiInfo.GetDelvesForMap and C_AreaPoiInfo.GetAreaPOIInfo then
        for _, mapID in ipairs(DELVE_MAP_IDS) do
            local delveIds = C_AreaPoiInfo.GetDelvesForMap(mapID)
            if delveIds then
                for _, areaPoiID in ipairs(delveIds) do
                    local ok, info = pcall(C_AreaPoiInfo.GetAreaPOIInfo, mapID, areaPoiID)
                    local atlasName = ok and info and string.lower(tostring(info.atlasName or "")) or ""
                    if atlasName ~= "" and string.find(atlasName, "bountiful", 1, true) then
                        addName(info and info.name)
                    end
                end
            end
        end
    end

    if #names == 0 then
        names[1] = ns.L("ilvl_key_unknown")
    end
    _cachedBountifulDelveNames = names
    return names
end

local function getMyKeyLines()
    local restored = getCurrencyCount(DELVE_RESTORED_KEY_CURRENCY_ID)
    local fragments = DELVE_KEY_FRAGMENT_ITEM_ID and getItemCountByID(DELVE_KEY_FRAGMENT_ITEM_ID) or nil
    local bountifulNames = getBestEffortBountifulDelveNames()
    local titleHex = colorHex(0.68, 0.82, 1.00)
    local entryHex = colorHex(0.92, 0.94, 1.00)
    local valueHex = colorHex(1.00, 0.84, 0.46)
    local lines = {
        inlineColor(titleHex, ns.L("ilvl_key_bountiful")),
    }

    for i = 1, 4 do
        lines[#lines + 1] = string.format("%d. %s", i, inlineColor(entryHex, bountifulNames[i] or "-"))
    end

    lines[#lines + 1] = string.format("%s  %s",
        ns.L("ilvl_key_fragments"),
        inlineColor(valueHex, fragments ~= nil and tostring(fragments) or "-"))
    lines[#lines + 1] = string.format("%s  %s",
        ns.L("ilvl_key_restored"),
        inlineColor(valueHex, restored ~= nil and tostring(restored) or "0"))
    return lines
end

local function formatKeyLevelLabel(keyLevel)
    return ns.L("ilvl_row_key_level", tostring(keyLevel or ""))
end

local function formatDelveTierLabel(tier)
    return ns.L("ilvl_row_delve_tier", tostring(tier or ""))
end

-- 열 헤더: 단 | 클리어보상 | 드랍문장 | 위대한금고
local function colHeader(sourceKey, dropKey, vaultKey, crestKey)
    return {
        isColumnHeader = true,
        label        = ns.L(sourceKey),
        dropStr      = dropKey   and ns.L(dropKey)   or "",
        vaultStr     = vaultKey  and ns.L(vaultKey)  or "",
        crestStr     = crestKey  and ns.L(crestKey)  or "",
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
        dropStr    = clearRewardStr(e.ilvl, e.grade),
        vaultStr   = vaultClearStr(e.vault, e.vaultGrade),
        crestDrop  = e.crestDrop,
        grade      = e.grade,
        vaultGrade = e.vaultGrade,
        highlight  = avgIlvl > 0 and e.ilvl > avgIlvl,
        vaultHL    = e.vault and avgIlvl > 0 and e.vault > avgIlvl or false,
    }
end

local function bountifulKeyRow(avgIlvl)
    local ilvl = 259
    return {
        label      = ns.L("ilvl_delve_bountiful_key"),
        dropStr    = clearRewardStr(ilvl, "hero", 1, 6),
        vaultStr   = "",
        crestDrop  = nil,
        grade      = "hero",
        highlight  = avgIlvl > 0 and ilvl > avgIlvl,
        vaultHL    = false,
    }
end

local function buildOverviewRows(avgIlvl)
    local tbl = ns.Data and ns.Data.ItemLevelTable
    if not tbl then return {} end
    local rows = {}
    local function spacer()
        if #rows > 0 then
            rows[#rows+1] = { isSpacer=true }
        end
    end

    -- 쐐기 (전체: heroic/mythic0 + endOfDungeon)
    if tbl.mythicPlus then
        rows[#rows+1] = { isHeader=true, label=mythicPlusSummaryText() }
        rows[#rows+1] = colHeader("ilvl_col_key", "ilvl_col_drop", "ilvl_col_vault", "ilvl_col_crest")
        for _, key in ipairs({ "heroic", "mythic0" }) do
            local e = tbl.mythicPlus[key]
            if e then rows[#rows+1] = mRow(ns.L(e.labelKey or key), e, avgIlvl) end
        end
        for _, e in ipairs(tbl.mythicPlus.endOfDungeon or {}) do
            rows[#rows+1] = mRow(formatKeyLevelLabel(e.key), e, avgIlvl)
        end
    end

    -- 레이드 (전체)
    if tbl.raid then
        spacer()
        rows[#rows+1] = { isHeader=true, label=sectionSummaryText(ns.L("ilvl_section_raid")) }
        rows[#rows+1] = colHeader("ilvl_col_difficulty", "ilvl_col_drop", "ilvl_col_vault", "ilvl_col_crest")
        for _, key in ipairs({ "normal", "heroic", "mythic" }) do
            local e = tbl.raid[key]
            if e then rows[#rows+1] = raidRow(key, e, avgIlvl) end
        end
    end

    -- 구렁 (최고 단계만)
    if tbl.delves and #tbl.delves > 0 then
        spacer()
        rows[#rows+1] = { isHeader=true, label=sectionSummaryText(ns.L("ilvl_section_delves")) }
        rows[#rows+1] = colHeader("ilvl_col_tier", "ilvl_col_drop", "ilvl_col_vault", "ilvl_col_crest")
        local last = tbl.delves[#tbl.delves]
        rows[#rows+1] = delveRow(formatDelveTierLabel(last.tier), last, avgIlvl)
        rows[#rows+1] = bountifulKeyRow(avgIlvl)
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
    rows[#rows+1] = { isHeader=true, label=sectionSummaryText(ns.L("ilvl_section_delves")) }
    rows[#rows+1] = colHeader("ilvl_col_tier", "ilvl_col_drop", "ilvl_col_vault", "ilvl_col_crest")
    for _, e in ipairs(tbl.delves) do
        rows[#rows+1] = delveRow(formatDelveTierLabel(e.tier), e, avgIlvl)
    end
    rows[#rows+1] = bountifulKeyRow(avgIlvl)
    return rows
end

local function buildMythicPlusRows(avgIlvl)
    local tbl = ns.Data and ns.Data.ItemLevelTable
    if not tbl or not tbl.mythicPlus then return {} end
    local rows = {}
    rows[#rows+1] = { isHeader=true, label=mythicPlusSummaryText() }
    rows[#rows+1] = colHeader("ilvl_col_key", "ilvl_col_drop", "ilvl_col_vault", "ilvl_col_crest")
    for _, key in ipairs({ "heroic", "mythic0" }) do
        local e = tbl.mythicPlus[key]
        if e then rows[#rows+1] = mRow(ns.L(e.labelKey or key), e, avgIlvl) end
    end
    for _, e in ipairs(tbl.mythicPlus.endOfDungeon or {}) do
        rows[#rows+1] = mRow(formatKeyLevelLabel(e.key), e, avgIlvl)
    end
    return rows
end

local function buildRaidRows(avgIlvl)
    local tbl = ns.Data and ns.Data.ItemLevelTable
    if not tbl or not tbl.raid then return {} end
    local rows = {}
    rows[#rows+1] = { isHeader=true, label=sectionSummaryText(ns.L("ilvl_section_raid")) }
    rows[#rows+1] = colHeader("ilvl_col_difficulty", "ilvl_col_drop", "ilvl_col_vault", "ilvl_col_crest")
    for _, key in ipairs({ "normal", "heroic", "mythic" }) do
        local e = tbl.raid[key]
        if e then rows[#rows+1] = raidRow(key, e, avgIlvl) end
    end
    local wb = tbl.worldBoss
    if wb then
        rows[#rows+1] = { isHeader=true, label="" }
        rows[#rows+1] = {
            label     = ns.L("ilvl_world_boss"),
            dropStr   = clearRewardStr(wb.ilvl, wb.grade),
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
    rows[#rows+1] = { isHeader=true, label=sectionSummaryText(ns.L("ilvl_tab_other")) }
    local function spacer()
        if #rows > 0 then
            rows[#rows+1] = { isSpacer=true }
        end
    end

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
    if tbl.pvp then
        spacer()
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
    frame:SetFrameStrata("MEDIUM")
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

    local kf = KeystoneFrame or ChallengesFrame
    applyOverlayPoint(frame, kf)

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
    avgLabel:SetPoint("RIGHT", titleBar, "RIGHT", -66, 0)
    avgLabel:SetText("")
    frame.avgLabel = avgLabel

    local function attachHeaderButtonTooltip(button, titleKey, bodyProvider)
        if not button then
            return
        end
        button:SetScript("OnEnter", function(self2)
            GameTooltip:SetOwner(self2, "ANCHOR_BOTTOM")
            GameTooltip:ClearLines()
            GameTooltip:AddLine(ns.L(titleKey), 1.00, 0.82, 0.44, true)
            local body = type(bodyProvider) == "function" and bodyProvider() or bodyProvider
            if body and body ~= "" then
                GameTooltip:AddLine(body, 0.90, 0.92, 0.98, true)
            end
            GameTooltip:Show()
        end)
        button:SetScript("OnLeave", function()
            GameTooltip:Hide()
        end)
    end

    local toggleBtn = CreateFrame("Button", nil, frame)
    toggleBtn:SetSize(18, 18)
    toggleBtn:SetPoint("RIGHT", titleBar, "RIGHT", -3, 0)
    makeBtnText(toggleBtn, 12, 0.80, 0.80, 1.00)
    toggleBtn:SetText("-")
    attachHeaderButtonTooltip(toggleBtn, "overlay_button_collapse_title", function()
        return ItemLevelOverlay.collapsed and ns.L("overlay_button_collapse_body_collapsed")
            or ns.L("overlay_button_collapse_body_expanded")
    end)
    frame.toggleBtn = toggleBtn

    -- ─── 잠금 버튼 (드래그 잠금/해제) ─────────────────────────
    local lockBtn = CreateFrame("Button", nil, frame)
    lockBtn:SetSize(18, 18)
    lockBtn:SetPoint("RIGHT", toggleBtn, "LEFT", -2, 0)
    lockBtn.label = lockBtn:CreateFontString(nil, "OVERLAY")
    lockBtn.label:SetFont(FONT_PATH, 10, FONT_FLAGS)
    lockBtn.label:SetAllPoints()
    lockBtn.label:SetJustifyH("CENTER")
    lockBtn.label:SetJustifyV("MIDDLE")
    local function updateILLockVisual()
        local locked = ns.DB and ns.DB:IsItemLevelOverlayLocked()
        lockBtn.label:SetText(locked and "L" or "U")
        lockBtn.label:SetTextColor(locked and 1 or 0.70, locked and 0.60 or 0.70, locked and 0.60 or 0.80, 1)
    end
    updateILLockVisual()
    lockBtn:SetScript("OnClick", function()
        if ns.DB then
            ns.DB:SetItemLevelOverlayLocked(not ns.DB:IsItemLevelOverlayLocked())
        end
        updateILLockVisual()
    end)
    attachHeaderButtonTooltip(lockBtn, "overlay_button_lock_title", function()
        return (ns.DB and ns.DB:IsItemLevelOverlayLocked())
            and ns.L("overlay_button_lock_body_locked")
            or ns.L("overlay_button_lock_body_unlocked")
    end)
    frame.lockBtn = lockBtn

    -- ─── 위치 초기화 버튼 ─────────────────────────────────────
    local resetBtn = CreateFrame("Button", nil, frame)
    resetBtn:SetSize(18, 18)
    resetBtn:SetPoint("RIGHT", lockBtn, "LEFT", -2, 0)
    resetBtn.label = resetBtn:CreateFontString(nil, "OVERLAY")
    resetBtn.label:SetFont(FONT_PATH, 10, FONT_FLAGS)
    resetBtn.label:SetAllPoints()
    resetBtn.label:SetJustifyH("CENTER")
    resetBtn.label:SetJustifyV("MIDDLE")
    resetBtn.label:SetText("R")
    resetBtn.label:SetTextColor(0.70, 0.70, 0.80, 1)
    resetBtn:SetScript("OnClick", function()
        local defaults = ns.Data and ns.Data.Defaults and ns.Data.Defaults.ui and ns.Data.Defaults.ui.itemLevelOverlay
        if not defaults then return end
        local config = ns.DB and ns.DB:GetItemLevelOverlayConfig()
        if not config then return end
        config.anchorMode = defaults.anchorMode or "mythicplus"
        config.point = defaults.point
        config.relativePoint = defaults.relativePoint
        config.x = defaults.x
        config.y = defaults.y
        ItemLevelOverlay:Refresh()
    end)
    attachHeaderButtonTooltip(resetBtn, "overlay_button_reset_title", ns.L("overlay_button_reset_body"))
    frame.resetBtn = resetBtn

    -- 탭 행
    local tabRow = CreateFrame("Frame", nil, frame)
    tabRow:SetPoint("TOPLEFT",  titleBar, "BOTTOMLEFT",  0, -2)
    tabRow:SetPoint("TOPRIGHT", titleBar, "BOTTOMRIGHT", 0, -2)
    tabRow:SetHeight(TAB_H + 2)
    frame.tabRow = tabRow

    local tabWidth = math.floor((FRAME_W - 12 - ((#TAB_KEYS - 1) * TAB_GAP)) / #TAB_KEYS)
    local totalTabW = (#TAB_KEYS * tabWidth) + ((#TAB_KEYS - 1) * TAB_GAP)
    local tabStartX = math.max(2, math.floor((FRAME_W - 4 - totalTabW) / 2))
    frame.tabs = {}
    for i, tabKey in ipairs(TAB_KEYS) do
        local btn = CreateFrame("Button", nil, tabRow)
        btn:SetHeight(TAB_H)
        btn:SetWidth(tabWidth)
        if i == 1 then
            btn:SetPoint("TOPLEFT", tabRow, "TOPLEFT", tabStartX, 0)
        else
            btn:SetPoint("LEFT", frame.tabs[i-1], "RIGHT", TAB_GAP, 0)
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

    local crestPanel = CreateFrame("Frame", nil, content, "BackdropTemplate")
    crestPanel:SetWidth(CREST_PANEL_W)
    crestPanel:SetPoint("TOPRIGHT", content, "TOPRIGHT", 0, 0)
    if crestPanel.SetBackdrop then
        crestPanel:SetBackdrop({
            bgFile   = "Interface\\Tooltips\\UI-Tooltip-Background",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true, tileSize = 8, edgeSize = 8,
            insets = { left=2, right=2, top=2, bottom=2 },
        })
        crestPanel:SetBackdropColor(0.08, 0.09, 0.14, 0.92)
        crestPanel:SetBackdropBorderColor(0.26, 0.30, 0.42, 0.75)
    end
    frame.crestPanel = crestPanel

    local crestTitle = makeFS(crestPanel, 13, HEADER_COLOR[1], HEADER_COLOR[2], HEADER_COLOR[3])
    crestTitle:SetPoint("TOPLEFT", crestPanel, "TOPLEFT", 6, -84)
    crestTitle:SetJustifyH("LEFT")
    crestTitle:SetText(ns.L("ilvl_col_my_crest"))
    frame.crestTitle = crestTitle

    frame.crestLines = {}
    for i, _ in ipairs(CREST_PANEL_GRADES) do
        local line = CreateFrame("Frame", nil, crestPanel)
        line:SetSize(CREST_PANEL_W - 10, CREST_LINE_H)
        if i == 1 then
            line:SetPoint("TOPLEFT", crestTitle, "BOTTOMLEFT", 0, -6)
        else
            line:SetPoint("TOPLEFT", frame.crestLines[i-1], "BOTTOMLEFT", 0, -1)
        end
        line.label = makeFS(line, 14, 1, 1, 1)
        line.label:SetPoint("LEFT", line, "LEFT", 0, 0)
        line.label:SetPoint("RIGHT", line, "RIGHT", -CREST_VALUE_W, 0)
        line.label:SetJustifyH("LEFT")

        line.value = makeFS(line, 14, 1, 1, 1)
        line.value:SetPoint("RIGHT", line, "RIGHT", 0, 0)
        line.value:SetWidth(CREST_VALUE_W)
        line.value:SetJustifyH("RIGHT")

        frame.crestLines[i] = line
    end

    local keyDivider = crestPanel:CreateTexture(nil, "ARTWORK")
    keyDivider:SetHeight(1)
    keyDivider:SetPoint("TOPLEFT", frame.crestLines[#frame.crestLines], "BOTTOMLEFT", 0, -6)
    keyDivider:SetPoint("TOPRIGHT", crestPanel, "TOPRIGHT", -6, -6)
    keyDivider:SetColorTexture(0.28, 0.34, 0.46, 0.80)
    frame.keyDivider = keyDivider

    local keyTitle = makeFS(crestPanel, 13, HEADER_COLOR[1], HEADER_COLOR[2], HEADER_COLOR[3])
    keyTitle:SetPoint("TOPLEFT", keyDivider, "BOTTOMLEFT", 0, -6)
    keyTitle:SetJustifyH("LEFT")
    keyTitle:SetText(ns.L("ilvl_col_my_key"))
    frame.keyTitle = keyTitle

    frame.keyLines = {}
    for i = 1, 7 do
        local fontSize = (i >= 2 and i <= 5) and 9 or 10
        local fs = makeFS(crestPanel, fontSize, 1, 1, 1)
        if i == 1 then
            fs:SetPoint("TOPLEFT", keyTitle, "BOTTOMLEFT", 0, -6)
        else
            fs:SetPoint("TOPLEFT", frame.keyLines[i-1], "BOTTOMLEFT", 0, -3)
        end
        fs:SetWidth(CREST_PANEL_W - 10)
        fs:SetJustifyH("LEFT")
        frame.keyLines[i] = fs
    end

    local tableArea = CreateFrame("Frame", nil, content)
    tableArea:SetPoint("TOPLEFT", content, "TOPLEFT", 0, 0)
    tableArea:SetPoint("RIGHT", crestPanel, "LEFT", -TABLE_GAP, 0)
    frame.tableArea = tableArea

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
-- 행 보장 (4열: 단 | 드랍 | 드랍문장 | 위대한금고)
-- ============================================================

function ItemLevelOverlay:EnsureRow(index)
    if not self.frame then return nil end
    self.frame.rows = self.frame.rows or {}
    if self.frame.rows[index] then return self.frame.rows[index] end

    local row = CreateFrame("Frame", nil, self.frame.tableArea or self.frame.content)
    row:SetHeight(ROW_H)

    -- 열1: 소스 (단/난이도)
    row.label = makeFS(row, 11, 0.78, 0.78, 0.90)
    row.label:SetPoint("LEFT", row, "LEFT", 4, 0)
    row.label:SetWidth(COL_DROP_X - 6)
    row.label:SetJustifyH("LEFT")
    if row.label.SetWordWrap then
        row.label:SetWordWrap(false)
    end

    -- 열2: 클리어 보상 (ilvl + 등급 + rank)
    row.drop = makeFS(row, 10, 0.96, 0.86, 0.60)
    row.drop:SetPoint("LEFT", row, "LEFT", COL_DROP_X, 0)
    row.drop:SetWidth(COL_CREST_X - COL_DROP_X - 2)
    row.drop:SetJustifyH("LEFT")
    if row.drop.SetWordWrap then
        row.drop:SetWordWrap(false)
    end

    -- 열3: 드랍 문장
    row.crest = makeFS(row, 10, 0.70, 0.70, 0.80)
    row.crest:SetPoint("LEFT", row, "LEFT", COL_CREST_X, 0)
    row.crest:SetWidth(COL_VAULT_X - COL_CREST_X - 2)
    row.crest:SetJustifyH("LEFT")
    if row.crest.SetWordWrap then
        row.crest:SetWordWrap(false)
    end

    -- 열4: 위대한 금고
    row.vault = makeFS(row, 10, 0.55, 0.85, 0.55)
    row.vault:SetPoint("LEFT", row, "LEFT", COL_VAULT_X, 0)
    row.vault:SetWidth(TABLE_W - COL_VAULT_X - 4)
    row.vault:SetJustifyH("LEFT")
    if row.vault.SetWordWrap then
        row.vault:SetWordWrap(false)
    end

    self.frame.rows[index] = row
    return row
end

function ItemLevelOverlay:InvalidateBountifulDelveNamesCache()
    _cachedBountifulDelveNames = nil
end

function ItemLevelOverlay:BuildContentSignature(avgIlvl)
    local language = ns.DB and ns.DB.GetLanguage and ns.DB:GetLanguage() or "?"
    return table.concat({
        tostring(self.currentTab or "overview"),
        tostring(avgIlvl or 0),
        tostring(language),
    }, ":")
end

function ItemLevelOverlay:RefreshHeader(avgIlvl)
    local frame = self.frame
    if not frame then
        return
    end

    local avgText = (avgIlvl and avgIlvl > 0) and tostring(avgIlvl) or "?"
    frame.avgLabel:SetText(ns.L("ilvl_avg_label", avgText))
    frame.titleText:SetText(ns.L("ilvl_overlay_title"))
    if frame.hintText then
        frame.hintText:SetText(ns.L("ilvl_overlay_hint"))
    end

    for _, btn in ipairs(frame.tabs or {}) do
        local active = btn.tabKey == self.currentTab
        btn:SetText(ns.L("ilvl_tab_" .. btn.tabKey))
        if active then
            btn.bg:SetColorTexture(0.30, 0.30, 0.55, 0.95)
            btn:GetFontString():SetTextColor(1, 1, 1, 1)
        else
            btn.bg:SetColorTexture(0.15, 0.15, 0.25, 0.80)
            btn:GetFontString():SetTextColor(0.70, 0.70, 0.80, 1)
        end
    end
end

function ItemLevelOverlay:RefreshSidePanel()
    local frame = self.frame
    if not frame then
        return
    end

    if frame.crestTitle then
        frame.crestTitle:SetText(ns.L("ilvl_col_my_crest"))
    end
    if frame.keyTitle then
        frame.keyTitle:SetText(ns.L("ilvl_col_my_key"))
    end
    if not frame.crestPanel then
        return
    end

    for i, grade in ipairs(CREST_PANEL_GRADES) do
        local line = frame.crestLines and frame.crestLines[i]
        if line then
            local labelText, valueText, r, g, b = crestCountParts(grade)
            line.label:SetText(labelText)
            line.label:SetTextColor(r, g, b, 1)
            line.value:SetText(valueText)
            line.value:SetTextColor(r, g, b, 1)
        end
    end

    local keyLines = getMyKeyLines()
    for i, fs in ipairs(frame.keyLines or {}) do
        fs:SetText(keyLines[i] or "")
        if i == 1 then
            fs:SetTextColor(0.70, 0.84, 1.00, 1)
        elseif i <= 5 then
            fs:SetTextColor(0.92, 0.94, 1.00, 1)
        else
            fs:SetTextColor(1.00, 0.84, 0.46, 1)
        end
    end

    local crestPanelH = 146 + (#CREST_PANEL_GRADES * (CREST_LINE_H + 2)) + (#(frame.keyLines or {}) * 16)
    frame.crestPanel:SetHeight(crestPanelH)
end

-- ============================================================
-- 탭 선택 / 최소화
-- ============================================================

function ItemLevelOverlay:SelectTab(tabKey)
    self.currentTab = tabKey or "overview"
    local config = ns.DB and ns.DB:GetItemLevelOverlayConfig()
    if config then config.currentTab = self.currentTab end
    self._lastContentSignature = nil
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

function ItemLevelOverlay:RebuildContent(avgIlvl)
    local frame = self.frame
    if not frame then return end

    avgIlvl = avgIlvl or getAverageItemLevel()
    self:RefreshHeader(avgIlvl)

    local rowData = {}
    if     self.currentTab == "overview"   then rowData = buildOverviewRows(avgIlvl)
    elseif self.currentTab == "mythicplus" then rowData = buildMythicPlusRows(avgIlvl)
    elseif self.currentTab == "delves"     then rowData = buildDelveRows(avgIlvl)
    elseif self.currentTab == "raid"       then rowData = buildRaidRows(avgIlvl)
    elseif self.currentTab == "other"      then rowData = buildOtherRows(avgIlvl)
    end

    self:RefreshSidePanel()

    local yOffset = 2
    for i, data in ipairs(rowData) do
        local row = self:EnsureRow(i)
        if not row then break end
        row:ClearAllPoints()
        row:SetPoint("TOPLEFT", frame.tableArea or frame.content, "TOPLEFT", 0, -yOffset)
        row:SetPoint("RIGHT",   frame.tableArea or frame.content, "RIGHT",   0, 0)
        row:Show()

        if data.isSpacer then
            row.label:SetText(""); row.drop:SetText(""); row.vault:SetText("")
            row.crest:SetText("")
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
            row.label:SetWidth(TABLE_W - 10)
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
            if up then
                row.drop:SetTextColor(0.40, 0.94, 0.55, 1)
            else
                row.drop:SetTextColor(1, 1, 1, 1)
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
                    row.vault:SetTextColor(0.82, 0.82, 0.88, 1)
                end
                row.vault:SetText(vs)
            end

            -- 드랍 문장 열 (인라인 색상)
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

    local crestPanelH = frame.crestPanel and frame.crestPanel:GetHeight() or 0
    self.contentHeight = TITLE_H + 4 + (TAB_H + 4) + math.max(yOffset, crestPanelH + 4) + PADDING
    self._lastContentSignature = self:BuildContentSignature(avgIlvl)
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

    local avgIlvl = getAverageItemLevel()
    local contentSignature = self:BuildContentSignature(avgIlvl)
    if self._lastContentSignature ~= contentSignature then
        self:RebuildContent(avgIlvl)
    else
        self:RefreshHeader(avgIlvl)
        self:RefreshSidePanel()
    end
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
                applyOverlayPoint(self.frame, pve)
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
                applyOverlayPoint(self.frame, pve)
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
