local _, ns = ...

local ItemLevelOverlay = {}
ns.UI.ItemLevelOverlay = ItemLevelOverlay

local FONT_PATH  = UNIT_NAME_FONT or STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF"
local FONT_FLAGS = "OUTLINE"
local FRAME_W    = 472
local TITLE_H    = 22
local TAB_H      = 20
local ROW_H      = 19
local ROW_GAP    = 2
local PADDING    = 6
local CREST_LINE_H = 18
local CREST_VALUE_W = 38

local TAB_GAP    = 2

local CREST_STRIP_H = 44
local CONTENT_W     = FRAME_W - 8
local TABLE_W       = CONTENT_W
local COL_DROP_X    = 102
local COL_CREST_X   = 248
local COL_VAULT_X   = 316

local SCALE_STEP = 0.05
local SCALE_MIN  = 0.50
local SCALE_MAX  = 2.00

local TAB_KEYS = { "overview", "mythicplus", "delves", "raid", "other" }
local DELVE_RESTORED_KEY_CURRENCY_ID = 3028
local DELVE_KEY_FRAGMENT_ITEM_ID = nil
local DELVE_MAP_IDS = { 2512, 2395, 2413, 2405, 2437, 1270 }

local CREST_ID_BY_GRADE = {
    adv  = 3442,
    vet  = 3443,
    chmp = 3444,
    hero = 3445,
    myth = 3446,
}

local HEADER_COLOR = { 0.50, 0.58, 0.68 }
local CREST_PANEL_GRADES = { "adv", "vet", "chmp", "hero", "myth" }
local _cachedBountifulDelveNames = nil
local _bountifulDelveEmptyUntil = 0
local BOUNTIFUL_DELVE_EMPTY_TTL = 10.0

local GRADE_COLORS = {
    expl = { 0.62, 0.62, 0.62 },
    adv  = { 0.90, 0.90, 0.90 },
    vet  = { 0.30, 0.90, 0.30 },
    chmp = { 0.28, 0.68, 1.00 },
    hero = { 0.72, 0.35, 1.00 },
    myth = { 1.00, 0.20, 0.20 },
}

local CREST_COLORS = {
    adv  = { 0.90, 0.90, 0.90 },
    vet  = { 0.30, 0.90, 0.30 },
    chmp = { 0.28, 0.68, 1.00 },
    hero = { 0.72, 0.35, 1.00 },
    myth = { 1.00, 0.20, 0.20 },
}

local function colorHex(r, g, b)
    return string.format("%02X%02X%02X",
        math.floor(r * 255 + 0.5), math.floor(g * 255 + 0.5), math.floor(b * 255 + 0.5))
end

local function inlineColor(hex, text)
    return "|cFF" .. hex .. text .. "|r"
end

local getAverageItemLevel = ns.Utils.GetAverageItemLevel

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

local function clearRewardStr(ilvl, grade, rank, rankMax, showUnknownRank)
    if not ilvl then return "" end
    local gp = gradeRankColored(grade, rank, rankMax, showUnknownRank)
    return gp ~= "" and (tostring(ilvl).." "..gp) or tostring(ilvl)
end

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

    local now = (type(GetTime) == "function" and GetTime()) or nil
    if now and now < _bountifulDelveEmptyUntil then
        return { ns.L("ilvl_key_unknown") }
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
            local delvesOk, delveIds = pcall(C_AreaPoiInfo.GetDelvesForMap, mapID)
            if delvesOk and delveIds then
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
        if now then
            _bountifulDelveEmptyUntil = now + BOUNTIFUL_DELVE_EMPTY_TTL
        end
        return { ns.L("ilvl_key_unknown") }
    end
    _bountifulDelveEmptyUntil = 0
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

local function colHeader(sourceKey, dropKey, vaultKey, crestKey)
    return {
        isColumnHeader = true,
        label        = ns.L(sourceKey),
        dropStr      = dropKey   and ns.L(dropKey)   or "",
        vaultStr     = vaultKey  and ns.L(vaultKey)  or "",
        crestStr     = crestKey  and ns.L(crestKey)  or "",
    }
end

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

    if tbl.raid then
        spacer()
        rows[#rows+1] = { isHeader=true, label=sectionSummaryText(ns.L("ilvl_section_raid")) }
        rows[#rows+1] = colHeader("ilvl_col_difficulty", "ilvl_col_drop", "ilvl_col_vault", "ilvl_col_crest")
        for _, key in ipairs({ "normal", "heroic", "mythic" }) do
            local e = tbl.raid[key]
            if e then rows[#rows+1] = raidRow(key, e, avgIlvl) end
        end
    end

    if tbl.delves and #tbl.delves > 0 then
        spacer()
        rows[#rows+1] = { isHeader=true, label=sectionSummaryText(ns.L("ilvl_section_delves")) }
        rows[#rows+1] = colHeader("ilvl_col_tier", "ilvl_col_drop", "ilvl_col_vault", "ilvl_col_crest")
        local last = tbl.delves[#tbl.delves]
        rows[#rows+1] = delveRow(formatDelveTierLabel(last.tier), last, avgIlvl)
        rows[#rows+1] = bountifulKeyRow(avgIlvl)
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

        local wbEntries = {}
        if wb.ilvl then
            wbEntries[1] = wb
        else
            for _, key in ipairs({ "world", "normal", "heroic", "mythic" }) do
                if wb[key] then wbEntries[#wbEntries+1] = wb[key] end
            end
        end
        if #wbEntries > 0 then
            rows[#rows+1] = { isHeader=true, label="" }
            for _, e in ipairs(wbEntries) do
                rows[#rows+1] = {
                    label     = ns.L(e.labelKey or "ilvl_world_boss"),
                    dropStr   = clearRewardStr(e.ilvl, e.grade),
                    vaultStr  = "",
                    crestDrop = e.crestDrop,
                    grade     = e.grade,
                    highlight = avgIlvl > 0 and (e.ilvl or 0) > avgIlvl,
                    vaultHL   = false,
                }
            end
        end
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

    local titleBar = frame:CreateTexture(nil, "BACKGROUND")
    titleBar:SetColorTexture(0.14, 0.14, 0.22, 0.80)
    titleBar:SetPoint("TOPLEFT",  frame, "TOPLEFT",  2, -2)
    titleBar:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -2, -2)
    titleBar:SetHeight(TITLE_H)

    local titleText = makeFS(frame, 13, 0.85, 0.85, 1.00)
    titleText:SetPoint("LEFT", titleBar, "LEFT", 6, 2)
    titleText:SetText(ns.L("ilvl_overlay_title"))
    frame.titleText = titleText

    local hintText = makeFS(frame, 10, 0.50, 0.50, 0.60)
    hintText:SetPoint("LEFT", titleText, "RIGHT", 4, 0)
    hintText:SetText(ns.L("ilvl_overlay_hint"))
    frame.hintText = hintText

    local avgLabel = makeFS(frame, 11, 0.70, 0.70, 0.80)
    avgLabel:SetPoint("RIGHT", titleBar, "RIGHT", -66, 0)
    avgLabel:SetText("")
    frame.avgLabel = avgLabel

    local function attachHeaderButtonTooltip(button, titleKey, bodyProvider)
        if not button then
            return
        end
        button:SetScript("OnEnter", function(self2)
            local tooltip = ns.UI.Widgets.GetTooltip()
            if not tooltip then
                return
            end

            tooltip:SetOwner(self2, "ANCHOR_BOTTOM")
            tooltip:ClearLines()
            tooltip:AddLine(ns.L(titleKey), 1.00, 0.82, 0.44, true)
            local body = type(bodyProvider) == "function" and bodyProvider() or bodyProvider
            if body and body ~= "" then
                tooltip:AddLine(body, 0.90, 0.92, 0.98, true)
            end
            tooltip:Show()
        end)
        button:SetScript("OnLeave", ns.UI.Widgets.HideTooltip)
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
        makeBtnText(btn, 11, 0.70, 0.70, 0.80)
        btn.tabKey = tabKey
        frame.tabs[i] = btn
    end

    local content = CreateFrame("Frame", nil, frame)
    content:SetPoint("TOPLEFT",  tabRow, "BOTTOMLEFT",   2, -2)
    content:SetPoint("TOPRIGHT", tabRow, "BOTTOMRIGHT", -2, -2)
    content:SetPoint("BOTTOM",   frame,  "BOTTOM",       0, PADDING)
    frame.content = content

    local crestPanel = CreateFrame("Frame", nil, content, "BackdropTemplate")
    crestPanel:SetHeight(CREST_STRIP_H)
    crestPanel:SetPoint("BOTTOMLEFT", content, "BOTTOMLEFT", 0, 0)
    crestPanel:SetPoint("BOTTOMRIGHT", content, "BOTTOMRIGHT", 0, 0)
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

    frame.crestTitle = nil

    local crestCellW = math.floor((CONTENT_W - 12) / #CREST_PANEL_GRADES)
    frame.crestLines = {}
    for i, _ in ipairs(CREST_PANEL_GRADES) do
        local line = CreateFrame("Frame", nil, crestPanel)
        line:SetSize(crestCellW, CREST_LINE_H)
        if i == 1 then
            line:SetPoint("TOPLEFT", crestPanel, "TOPLEFT", 6, -4)
        else
            line:SetPoint("TOPLEFT", frame.crestLines[i-1], "TOPRIGHT", 0, 0)
        end
        line.label = makeFS(line, 12, 1, 1, 1)
        line.label:SetPoint("LEFT", line, "LEFT", 0, 0)
        line.label:SetPoint("RIGHT", line, "RIGHT", -CREST_VALUE_W, 0)
        line.label:SetJustifyH("LEFT")
        if line.label.SetWordWrap then
            line.label:SetWordWrap(false)
        end

        line.value = makeFS(line, 12, 1, 1, 1)
        line.value:SetPoint("RIGHT", line, "RIGHT", -4, 0)
        line.value:SetWidth(CREST_VALUE_W)
        line.value:SetJustifyH("RIGHT")

        frame.crestLines[i] = line
    end

    frame.keyDivider = nil
    frame.keyTitle = nil

    local keySummary = makeFS(crestPanel, 11, 1, 1, 1)
    keySummary:SetPoint("TOPLEFT", crestPanel, "TOPLEFT", 6, -4 - CREST_LINE_H - 2)
    keySummary:SetPoint("TOPRIGHT", crestPanel, "TOPRIGHT", -6, -4 - CREST_LINE_H - 2)
    keySummary:SetJustifyH("LEFT")
    if keySummary.SetWordWrap then
        keySummary:SetWordWrap(false)
    end
    frame.keySummary = keySummary

    local bountifulText = makeFS(crestPanel, 11, 1, 1, 1)
    bountifulText:SetPoint("TOPLEFT", keySummary, "BOTTOMLEFT", 0, -3)
    bountifulText:SetPoint("TOPRIGHT", keySummary, "BOTTOMRIGHT", 0, -3)
    bountifulText:SetJustifyH("LEFT")
    if bountifulText.SetWordWrap then
        bountifulText:SetWordWrap(true)
    end
    if bountifulText.SetMaxLines then
        bountifulText:SetMaxLines(2)
    end
    if bountifulText.SetSpacing then
        bountifulText:SetSpacing(2)
    end
    frame.bountifulText = bountifulText

    frame.keyLines = {}

    crestPanel:EnableMouse(true)
    crestPanel:SetScript("OnEnter", function(panel)
        local lines = frame._keyDetailLines
        if type(lines) ~= "table" or #lines == 0 then return end
        GameTooltip:SetOwner(panel, "ANCHOR_TOP")
        GameTooltip:ClearLines()
        for _, text in ipairs(lines) do
            GameTooltip:AddLine(text, 1, 1, 1, true)
        end
        GameTooltip:Show()
    end)
    crestPanel:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    local tableArea = CreateFrame("Frame", nil, content)
    tableArea:SetPoint("TOPLEFT", content, "TOPLEFT", 0, 0)
    tableArea:SetPoint("TOPRIGHT", content, "TOPRIGHT", 0, 0)
    tableArea:SetPoint("BOTTOM", crestPanel, "TOP", 0, 4)
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

function ItemLevelOverlay:EnsureRow(index)
    if not self.frame then return nil end
    self.frame.rows = self.frame.rows or {}
    if self.frame.rows[index] then return self.frame.rows[index] end

    local row = CreateFrame("Frame", nil, self.frame.tableArea or self.frame.content)
    row:SetHeight(ROW_H)

    row.label = makeFS(row, 13, 0.78, 0.78, 0.90)
    row.label:SetPoint("LEFT", row, "LEFT", 4, 0)
    row.label:SetWidth(COL_DROP_X - 6)
    row.label:SetJustifyH("LEFT")
    if row.label.SetWordWrap then
        row.label:SetWordWrap(false)
    end

    row.drop = makeFS(row, 12, 0.96, 0.86, 0.60)
    row.drop:SetPoint("LEFT", row, "LEFT", COL_DROP_X, 0)
    row.drop:SetWidth(COL_CREST_X - COL_DROP_X - 2)
    row.drop:SetJustifyH("LEFT")
    if row.drop.SetWordWrap then
        row.drop:SetWordWrap(false)
    end

    row.crest = makeFS(row, 12, 0.70, 0.70, 0.80)
    row.crest:SetPoint("LEFT", row, "LEFT", COL_CREST_X, 0)
    row.crest:SetWidth(COL_VAULT_X - COL_CREST_X - 2)
    row.crest:SetJustifyH("LEFT")
    if row.crest.SetWordWrap then
        row.crest:SetWordWrap(false)
    end

    row.vault = makeFS(row, 12, 0.55, 0.85, 0.55)
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
    frame._keyDetailLines = keyLines

    if frame.keySummary then
        local fragments = DELVE_KEY_FRAGMENT_ITEM_ID and getItemCountByID(DELVE_KEY_FRAGMENT_ITEM_ID) or nil
        local restored = getCurrencyCount(DELVE_RESTORED_KEY_CURRENCY_ID)
        local valueHex = colorHex(1.00, 0.84, 0.46)
        local labelHex = colorHex(0.68, 0.82, 1.00)
        local parts = {
            string.format("%s %s", inlineColor(labelHex, ns.L("ilvl_key_restored")),
                inlineColor(valueHex, restored ~= nil and tostring(restored) or "0")),
        }
        if fragments ~= nil then
            parts[#parts + 1] = string.format("%s %s", inlineColor(labelHex, ns.L("ilvl_key_fragments")),
                inlineColor(valueHex, tostring(fragments)))
        end
        frame.keySummary:SetText(table.concat(parts, "   "))
    end

    if frame.bountifulText then
        local names = getBestEffortBountifulDelveNames()
        local labelHex = colorHex(0.68, 0.82, 1.00)
        local nameHex = colorHex(0.92, 0.94, 1.00)
        local shown = {}
        for i = 1, 4 do
            local name = names[i]
            if name and name ~= "" then
                shown[#shown + 1] = inlineColor(nameHex, name)
            end
        end
        if #shown == 0 then
            shown[1] = inlineColor(colorHex(0.55, 0.57, 0.62), ns.L("ilvl_key_unknown"))
        end
        frame.bountifulText:SetText(string.format("%s  %s",
            inlineColor(labelHex, ns.L("ilvl_key_bountiful")),
            table.concat(shown, "  ·  ")))
    end

    local panelHeight = 4 + CREST_LINE_H + 2
    if frame.keySummary then
        local keyHeight = frame.keySummary.GetStringHeight and frame.keySummary:GetStringHeight() or 0
        panelHeight = panelHeight + math.max(tonumber(keyHeight) or 0, 12) + 3
    end
    if frame.bountifulText then
        local bountifulHeight = frame.bountifulText.GetStringHeight and frame.bountifulText:GetStringHeight() or 0
        panelHeight = panelHeight + math.max(tonumber(bountifulHeight) or 0, 12) + 5
    end

    local finalHeight = math.max(CREST_STRIP_H, math.floor(panelHeight + 0.5))
    frame.crestPanel:SetHeight(finalHeight)
    self._sidePanelHeight = finalHeight
end

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
        local rowParent = frame.tableArea or frame.content
        row:SetPoint("TOPLEFT",  rowParent, "TOPLEFT",  0, -yOffset)
        row:SetPoint("TOPRIGHT", rowParent, "TOPRIGHT", 0, -yOffset)
        row:Show()

        if data.isSpacer then
            row.label:SetText(""); row.drop:SetText(""); row.vault:SetText("")
            row.crest:SetText("")
            row:SetHeight(5)
            yOffset = yOffset + 5

        elseif data.isColumnHeader then
            local cr, cg, cb = HEADER_COLOR[1], HEADER_COLOR[2], HEADER_COLOR[3]
            row.label:SetWidth(COL_DROP_X - 6)
            row.label:SetFont(FONT_PATH, 11, FONT_FLAGS); row.label:SetTextColor(cr,cg,cb,1); row.label:SetText(data.label or "")
            row.drop:SetFont(FONT_PATH, 11, FONT_FLAGS);  row.drop:SetTextColor(cr,cg,cb,1);  row.drop:SetText(data.dropStr or "")
            row.vault:SetFont(FONT_PATH, 11, FONT_FLAGS); row.vault:SetTextColor(cr,cg,cb,1); row.vault:SetText(data.vaultStr or "")
            row.crest:SetFont(FONT_PATH, 11, FONT_FLAGS); row.crest:SetTextColor(cr,cg,cb,1); row.crest:SetText(data.crestStr or "")
            row:SetHeight(ROW_H - 2)
            yOffset = yOffset + (ROW_H - 2) + ROW_GAP + 1

        elseif data.isHeader then
            row.label:SetWidth(TABLE_W - 10)
            row.label:SetFont(FONT_PATH, 12, FONT_FLAGS)
            row.label:SetTextColor(0.65, 0.85, 1.00, 1)
            row.label:SetText(data.label or "")
            row.drop:SetText(""); row.vault:SetText(""); row.crest:SetText("")
            row:SetHeight(ROW_H - 2)
            yOffset = yOffset + (ROW_H - 2) + ROW_GAP

        else
            row.label:SetWidth(COL_DROP_X - 6)
            row.label:SetFont(FONT_PATH, 13, FONT_FLAGS)
            row.drop:SetFont(FONT_PATH, 12, FONT_FLAGS)
            row.vault:SetFont(FONT_PATH, 12, FONT_FLAGS)
            row.crest:SetFont(FONT_PATH, 12, FONT_FLAGS)

            local up = data.highlight
            row.label:SetTextColor(up and 0.95 or 0.68, up and 0.95 or 0.68, up and 0.95 or 0.75, 1)
            row.label:SetText(data.label or "")

            if up then
                row.drop:SetTextColor(0.40, 0.94, 0.55, 1)
            else
                row.drop:SetTextColor(1, 1, 1, 1)
            end
            row.drop:SetText(data.dropStr or "")

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
    self._layoutSidePanelHeight = crestPanelH
    self.contentHeight = TITLE_H + 4 + (TAB_H + 4) + yOffset + crestPanelH + 6 + PADDING
    self._lastContentSignature = self:BuildContentSignature(avgIlvl)
    self:UpdateLayout()
end

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

function ItemLevelOverlay:Refresh()
    if not ns.DB or not ns.DB:IsItemLevelOverlayEnabled() then
        if self.frame then self.frame:Hide() end
        return
    end

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
        if self._sidePanelHeight ~= self._layoutSidePanelHeight then
            self:RebuildContent(avgIlvl)
        end
    end
    self.frame:Show()
end

function ItemLevelOverlay:Initialize()
    if self._initialized then return end
    self._initialized = true

    local function setupPVEHooks()
        local pve = PVEFrame or LFGParentFrame
        if not pve then return false end

        pve:HookScript("OnShow", function()
            if not ns.DB or not ns.DB:IsItemLevelOverlayEnabled() then return end
            self:EnsureFrame()
            if self.frame then
                applyOverlayPoint(self.frame, pve)
                pcall(function()
                    self:Refresh()
                end)
            end
        end)
        pve:HookScript("OnHide", function()
            if self.frame then self.frame:Hide() end
        end)

        if pve:IsShown() and ns.DB and ns.DB:IsItemLevelOverlayEnabled() then
            self:EnsureFrame()
            if self.frame then
                applyOverlayPoint(self.frame, pve)
                pcall(function()
                    self:Refresh()
                end)
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
