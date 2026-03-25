local _, ns = ...

local UtilityPanel = {}
ns.UI.UtilityPanel = UtilityPanel

local function setStatus(message)
    ns:SafeCall(ns.UI.MainWindow, "SetStatus", message)
end

local function on(enabled)
    return enabled and ns.L("state_enabled") or ns.L("state_disabled")
end

-- 2열 그리드 치수 (창 폭 900px, content inset 16*2, box 시작 오프셋 16 = 유효 852px)
local COL_W   = 406   -- 열 폭 (852 - 40gap) / 2 ≈ 406
local COL_GAP = 20    -- 열 사이 간격
local FULL_W  = COL_W * 2 + COL_GAP  -- ~832 (블리자드 박스 전체 폭)
local ROW1_H  = 240   -- 1행 박스 높이 (긴 힌트+2체크 여유)
local ROW2_H  = 210   -- 2행 박스 높이
local BF_H    = 145   -- 블리자드 박스 높이 (힌트+체크+버튼)
local ROW_GAP = 10    -- 행 사이 간격
local cW      = COL_W - 24  -- 컬럼 내부 텍스트 폭 (382)

-- ============================================================
-- 내부 헬퍼
-- ============================================================

local function makeBox(parent, widgets, w, h)
    return widgets.CreatePanelBox(parent, w, h, "")
end

local function makeHint(parent, widgets, anchor, width)
    local hint = widgets.CreateLabel(parent, "", anchor, 0, -8)
    hint:SetWidth(width)
    hint:SetJustifyH("LEFT")
    if hint.SetWordWrap then hint:SetWordWrap(true) end
    return hint
end

local function makeCheck(parent, widgets, anchor, dy)
    local chk = widgets.CreateCheckButton(parent, "")
    chk:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 4, dy or -10)
    return chk
end

local function styleCheck(chk, w)
    if chk and chk.Text then
        chk.Text:SetWidth(w)
        chk.Text:SetJustifyH("LEFT")
        if chk.Text.SetWordWrap then chk.Text:SetWordWrap(true) end
    end
end

-- ============================================================
-- 패널 생성
-- ============================================================

function UtilityPanel:Create(parent)
    local frame = CreateFrame("Frame", nil, parent)
    frame:SetAllPoints()

    local widgets = ns.UI.Widgets

    -- 제목
    local title = widgets.CreateLabel(frame, "", nil, 16, -20, "GameFontHighlightLarge")
    frame.title = title

    -- ═══════════════════════════════════════════════════════════
    -- 1행 좌: 드랍/이벤트 오버레이
    -- ═══════════════════════════════════════════════════════════
    local overlayBox = makeBox(frame, widgets, COL_W, ROW1_H)
    overlayBox:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -14)
    frame.overlayBox = overlayBox

    local ilHint = makeHint(overlayBox, widgets, overlayBox.title, cW)
    frame.ilHint = ilHint

    local ilCheck = makeCheck(overlayBox, widgets, ilHint)
    frame.ilCheck = ilCheck

    local weCheck = makeCheck(overlayBox, widgets, ilCheck)
    frame.weCheck = weCheck

    -- ═══════════════════════════════════════════════════════════
    -- 1행 우: 스탯 오버레이
    -- ═══════════════════════════════════════════════════════════
    local statsBox = makeBox(frame, widgets, COL_W, ROW1_H)
    statsBox:SetPoint("TOPLEFT", title, "BOTTOMLEFT", COL_W + COL_GAP, -14)
    frame.statsBox = statsBox

    local statsHint = makeHint(statsBox, widgets, statsBox.title, cW)
    frame.statsHint = statsHint

    local statsCheck = makeCheck(statsBox, widgets, statsHint)
    frame.statsCheck = statsCheck

    local tankCheck = makeCheck(statsBox, widgets, statsCheck)
    frame.tankCheck = tankCheck

    -- ═══════════════════════════════════════════════════════════
    -- 2행 좌: 전문기술 오버레이
    -- ═══════════════════════════════════════════════════════════
    local profBox = makeBox(frame, widgets, COL_W, ROW2_H)
    profBox:SetPoint("TOPLEFT", overlayBox, "BOTTOMLEFT", 0, -ROW_GAP)
    frame.profBox = profBox

    local profHint = makeHint(profBox, widgets, profBox.title, cW)
    frame.profHint = profHint

    local profCheck = makeCheck(profBox, widgets, profHint)
    frame.profCheck = profCheck

    -- ═══════════════════════════════════════════════════════════
    -- 2행 우: 상점 / 우편
    -- ═══════════════════════════════════════════════════════════
    local shopBox = makeBox(frame, widgets, COL_W, ROW2_H)
    shopBox:SetPoint("TOPLEFT", statsBox, "BOTTOMLEFT", 0, -ROW_GAP)
    frame.shopBox = shopBox

    local shopHint = makeHint(shopBox, widgets, shopBox.title, cW)
    frame.shopHint = shopHint

    local merchantCheck = makeCheck(shopBox, widgets, shopHint)
    frame.merchantCheck = merchantCheck

    local mailCheck = makeCheck(shopBox, widgets, merchantCheck)
    frame.mailCheck = mailCheck

    -- ═══════════════════════════════════════════════════════════
    -- 3행 전체: 블리자드 창 이동 (전체 폭)
    -- ═══════════════════════════════════════════════════════════
    local bfBox = makeBox(frame, widgets, FULL_W, BF_H)
    bfBox:SetPoint("TOPLEFT", profBox, "BOTTOMLEFT", 0, -ROW_GAP)
    frame.bfBox = bfBox

    local bfHint = makeHint(bfBox, widgets, bfBox.title, FULL_W - 24)
    frame.bfHint = bfHint

    local bfCheck = makeCheck(bfBox, widgets, bfHint)
    frame.bfCheck = bfCheck

    local bfResetBtn = widgets.CreateButton(bfBox, "", 160, 24)
    bfResetBtn:SetPoint("TOPLEFT", bfCheck, "BOTTOMLEFT", 4, -10)
    frame.bfResetBtn = bfResetBtn

    -- 체크박스 텍스트 스타일 적용
    for _, pair in ipairs({
        { ilCheck,       cW },
        { weCheck,       cW },
        { statsCheck,    cW },
        { tankCheck,     cW },
        { profCheck,     cW },
        { merchantCheck, cW },
        { mailCheck,     cW },
        { bfCheck,       FULL_W - 24 },
    }) do
        styleCheck(pair[1], pair[2])
    end

    self:BindControls(frame)
    self.frame = frame
    return frame
end

-- ============================================================
-- 이벤트 바인딩
-- ============================================================

function UtilityPanel:BindControls(refs)
    refs.ilCheck:SetScript("OnClick", function(chk)
        ns.DB:SetItemLevelOverlayEnabled(chk:GetChecked())
        ns:RefreshUI()
        setStatus(ns.L("config_saved_item_level_overlay", on(chk:GetChecked())))
    end)

    refs.weCheck:SetScript("OnClick", function(chk)
        ns.DB:SetWorldEventOverlayEnabled(chk:GetChecked())
        ns:RefreshUI()
        setStatus(ns.L("config_saved_world_event_overlay", on(chk:GetChecked())))
    end)

    refs.statsCheck:SetScript("OnClick", function(chk)
        ns.DB:SetStatsOverlayEnabled(chk:GetChecked())
        ns:RefreshUI()
        setStatus(ns.L("config_saved_stats_overlay", on(chk:GetChecked())))
    end)

    refs.tankCheck:SetScript("OnClick", function(chk)
        ns.DB:SetStatsOverlayTankStatsEnabled(chk:GetChecked())
        ns:RefreshUI()
        setStatus(ns.L("config_stats_tank_stats_show"))
    end)

    refs.profCheck:SetScript("OnClick", function(chk)
        ns.DB:SetProfessionKnowledgeOverlayEnabled(chk:GetChecked())
        ns:RefreshUI()
        setStatus(ns.L("config_saved_profession_overlay", on(chk:GetChecked())))
    end)

    refs.merchantCheck:SetScript("OnClick", function(chk)
        ns.DB:SetMerchantHelperEnabled(chk:GetChecked())
        ns:RefreshUI()
        setStatus(ns.L("config_saved_merchant_helper", on(chk:GetChecked())))
    end)

    refs.mailCheck:SetScript("OnClick", function(chk)
        ns.DB:SetMailHistoryEnabled(chk:GetChecked())
        ns:RefreshUI()
        setStatus(ns.L("config_saved_mail_history", on(chk:GetChecked())))
    end)

    refs.bfCheck:SetScript("OnClick", function(chk)
        ns.DB:SetBlizzardFrameManagerEnabled(chk:GetChecked())
        if chk:GetChecked() then
            ns:SafeCall(ns.Modules.BlizzardFrameManager, "Apply")
        end
        ns:RefreshUI()
        setStatus(ns.L("config_saved_blizzard_frames", on(chk:GetChecked())))
    end)

    refs.bfResetBtn:SetScript("OnClick", function()
        ns:SafeCall(ns.Modules.BlizzardFrameManager, "ResetAll")
        setStatus(ns.L("config_blizzard_frames_reset_done"))
    end)
end

-- ============================================================
-- 갱신
-- ============================================================

function UtilityPanel:Refresh()
    local refs = self.frame
    if not refs or not ns.DB then return end

    refs.title:SetText(ns.L("utility_panel_title"))
    ns.UI.Widgets.ApplyFont(refs.title, 14, { domain = "ui" })

    refs.overlayBox.title:SetText(ns.L("utility_section_overlays"))
    refs.ilHint:SetText(ns.L("utility_overlay_hint"))
    refs.ilCheck.Text:SetText(ns.L("config_item_level_overlay_show"))
    refs.weCheck.Text:SetText(ns.L("config_world_event_overlay_show"))
    refs.ilCheck:SetChecked(ns.DB:IsItemLevelOverlayEnabled())
    refs.weCheck:SetChecked(ns.DB:IsWorldEventOverlayEnabled())

    refs.statsBox.title:SetText(ns.L("utility_section_stats_overlay"))
    refs.statsHint:SetText(ns.L("utility_stats_hint"))
    refs.statsCheck.Text:SetText(ns.L("config_stats_overlay_show"))
    refs.tankCheck.Text:SetText(ns.L("config_stats_tank_stats_show"))
    refs.statsCheck:SetChecked(ns.DB:IsStatsOverlayEnabled())
    refs.tankCheck:SetChecked(ns.DB:IsStatsOverlayTankStatsEnabled())

    refs.profBox.title:SetText(ns.L("utility_section_profession_overlay"))
    refs.profHint:SetText(ns.L("utility_profession_hint"))
    refs.profCheck.Text:SetText(ns.L("config_profession_overlay_show"))
    refs.profCheck:SetChecked(ns.DB:IsProfessionKnowledgeOverlayEnabled())

    refs.shopBox.title:SetText(ns.L("utility_section_shop"))
    refs.shopHint:SetText(ns.L("utility_shop_hint"))
    refs.merchantCheck.Text:SetText(ns.L("config_merchant_helper_show"))
    refs.mailCheck.Text:SetText(ns.L("config_mail_history_show"))
    refs.merchantCheck:SetChecked(ns.DB:IsMerchantHelperEnabled())
    refs.mailCheck:SetChecked(ns.DB:IsMailHistoryEnabled())

    refs.bfBox.title:SetText(ns.L("utility_section_blizzard"))
    refs.bfHint:SetText(ns.L("utility_blizzard_hint"))
    refs.bfCheck.Text:SetText(ns.L("config_blizzard_frames_show"))
    refs.bfResetBtn:SetText(ns.L("config_blizzard_frames_reset"))
    refs.bfCheck:SetChecked(ns.DB:IsBlizzardFrameManagerEnabled())
end

function UtilityPanel:Initialize()
    if self._initialized then return end
    self._initialized = true
end
