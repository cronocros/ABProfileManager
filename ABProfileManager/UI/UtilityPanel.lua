local _, ns = ...

local UtilityPanel = {}
ns.UI.UtilityPanel = UtilityPanel

local function setStatus(message)
    ns:SafeCall(ns.UI.MainWindow, "SetStatus", message)
end

local function on(enabled)
    return enabled and ns.L("state_enabled") or ns.L("state_disabled")
end

local COL_W   = 406
local COL_GAP = 20
local FULL_W  = COL_W * 2 + COL_GAP
local ROW1_H  = 264
local ROW2_H  = 210
local BF_H    = 145
local ROW_GAP = 10
local cW      = COL_W - 24

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
    chk:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, dy or -2)
    return chk
end

local function styleCheck(chk, w)
    if chk and chk.Text then
        chk.Text:SetWidth(w)
        chk.Text:SetJustifyH("LEFT")
        if chk.Text.SetWordWrap then chk.Text:SetWordWrap(true) end
        chk.Text:SetTextColor(0.88, 0.88, 0.95, 1)
    end
end

function UtilityPanel:Create(parent)
    if self.frame then
        return self.frame
    end

    local frame = CreateFrame("Frame", nil, parent)
    frame:SetAllPoints()

    local widgets = ns.UI.Widgets

    local title = widgets.CreateLabel(frame, "", nil, 16, -20, "GameFontHighlightLarge")
    frame.title = title

    local overlayBox = makeBox(frame, widgets, COL_W, ROW1_H)
    overlayBox:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -14)
    frame.overlayBox = overlayBox

    local ilHint = makeHint(overlayBox, widgets, overlayBox.title, cW)
    frame.ilHint = ilHint

    local ilCheck = makeCheck(overlayBox, widgets, ilHint)
    frame.ilCheck = ilCheck

    local ilLockCheck = makeCheck(overlayBox, widgets, ilCheck)
    frame.ilLockCheck = ilLockCheck

    local bisCheck = makeCheck(overlayBox, widgets, ilLockCheck)
    frame.bisCheck = bisCheck

    local bisLockCheck = makeCheck(overlayBox, widgets, bisCheck)
    frame.bisLockCheck = bisLockCheck

    local mplusRecordCheck = makeCheck(overlayBox, widgets, bisLockCheck)
    frame.mplusRecordCheck = mplusRecordCheck

    local statsBox = makeBox(frame, widgets, COL_W, ROW1_H)
    statsBox:SetPoint("TOPLEFT", title, "BOTTOMLEFT", COL_W + COL_GAP, -14)
    frame.statsBox = statsBox

    local statsHint = makeHint(statsBox, widgets, statsBox.title, cW)
    frame.statsHint = statsHint

    local statsCheck = makeCheck(statsBox, widgets, statsHint)
    frame.statsCheck = statsCheck

    local tankCheck = makeCheck(statsBox, widgets, statsCheck)
    frame.tankCheck = tankCheck

    local statsLockCheck = makeCheck(statsBox, widgets, tankCheck)
    frame.statsLockCheck = statsLockCheck

    local profBox = makeBox(frame, widgets, COL_W, ROW2_H)
    profBox:SetPoint("TOPLEFT", overlayBox, "BOTTOMLEFT", 0, -ROW_GAP)
    frame.profBox = profBox

    local profHint = makeHint(profBox, widgets, profBox.title, cW)
    frame.profHint = profHint

    local profCheck = makeCheck(profBox, widgets, profHint)
    frame.profCheck = profCheck

    local profLockCheck = makeCheck(profBox, widgets, profCheck)
    frame.profLockCheck = profLockCheck

    local bfBox = makeBox(frame, widgets, FULL_W, BF_H)
    bfBox:SetPoint("TOPLEFT", profBox, "BOTTOMLEFT", 0, -ROW_GAP)
    frame.bfBox = bfBox

    local bfHint = makeHint(bfBox, widgets, bfBox.title, FULL_W - 24)
    frame.bfHint = bfHint

    local bfCheck = makeCheck(bfBox, widgets, bfHint)
    frame.bfCheck = bfCheck

    local bfResetBtn = widgets.CreateButton(bfBox, "", 160, 24)
    bfResetBtn:SetPoint("TOPLEFT", bfCheck, "BOTTOMLEFT", 0, -6)
    frame.bfResetBtn = bfResetBtn

    for _, pair in ipairs({
        { ilCheck,        cW },
        { ilLockCheck,    cW },
        { bisCheck,       cW },
        { bisLockCheck,   cW },
        { mplusRecordCheck, cW },
        { statsCheck,     cW },
        { tankCheck,      cW },
        { statsLockCheck, cW },
        { profCheck,      cW },
        { profLockCheck,  cW },
        { bfCheck,        FULL_W - 24 },
    }) do
        styleCheck(pair[1], pair[2])
    end

    self:BindControls(frame)
    self.frame = frame
    return frame
end

function UtilityPanel:BindControls(refs)
    refs.ilCheck:SetScript("OnClick", function(chk)
        ns.DB:SetItemLevelOverlayEnabled(chk:GetChecked())
        ns:RefreshUI()
        setStatus(ns.L("config_saved_item_level_overlay", on(chk:GetChecked())))
    end)

    refs.ilLockCheck:SetScript("OnClick", function(chk)
        ns.DB:SetItemLevelOverlayLocked(chk:GetChecked())
        ns:RefreshUI()
        setStatus(ns.L("config_saved_item_level_overlay_locked", on(chk:GetChecked())))
    end)

    refs.bisCheck:SetScript("OnClick", function(chk)
        ns.DB:SetBISOverlayEnabled(chk:GetChecked())
        ns:RefreshUI()
        setStatus(ns.L("config_saved_bis_overlay", on(chk:GetChecked())))
    end)

    refs.bisLockCheck:SetScript("OnClick", function(chk)
        ns.DB:SetBISOverlayLocked(chk:GetChecked())
        ns:RefreshUI()
        setStatus(ns.L("config_saved_bis_overlay_locked", on(chk:GetChecked())))
    end)

    refs.mplusRecordCheck:SetScript("OnClick", function(chk)
        ns.DB:SetMythicPlusRecordOverlayEnabled(chk:GetChecked())
        ns:RefreshUI()
        setStatus(ns.L("config_saved_mplus_record_overlay", on(chk:GetChecked())))
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

    refs.statsLockCheck:SetScript("OnClick", function(chk)
        ns.DB:SetStatsOverlayLocked(chk:GetChecked())
        ns:RefreshUI()
        setStatus(ns.L("config_saved_stats_overlay_locked", on(chk:GetChecked())))
    end)

    refs.profCheck:SetScript("OnClick", function(chk)
        ns.DB:SetProfessionKnowledgeOverlayEnabled(chk:GetChecked())
        ns:RefreshUI()
        setStatus(ns.L("config_saved_profession_overlay", on(chk:GetChecked())))
    end)

    refs.profLockCheck:SetScript("OnClick", function(chk)
        ns.DB:SetProfessionKnowledgeOverlayLocked(chk:GetChecked())
        ns:RefreshUI()
        setStatus(ns.L("config_saved_profession_overlay_locked", on(chk:GetChecked())))
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

function UtilityPanel:Refresh()
    local refs = self.frame
    if not refs or not ns.DB then return end

    refs.title:SetText(ns.L("utility_panel_title"))
    ns.UI.Widgets.ApplyFont(refs.title, 14, { domain = "ui" })

    refs.overlayBox.title:SetText(ns.L("utility_section_overlays"))
    refs.ilHint:SetText(ns.L("utility_overlay_hint"))
    refs.ilCheck.Text:SetText(ns.L("config_item_level_overlay_show"))
    refs.ilLockCheck.Text:SetText(ns.L("config_item_level_overlay_lock"))
    refs.bisCheck.Text:SetText(ns.L("config_bis_overlay_show"))
    refs.bisLockCheck.Text:SetText(ns.L("config_bis_overlay_lock"))
    refs.mplusRecordCheck.Text:SetText(ns.L("config_mplus_record_overlay_show"))
    refs.ilCheck:SetChecked(ns.DB:IsItemLevelOverlayEnabled())
    refs.ilLockCheck:SetChecked(ns.DB:IsItemLevelOverlayLocked())
    refs.bisCheck:SetChecked(ns.DB:IsBISOverlayEnabled())
    refs.bisLockCheck:SetChecked(ns.DB:IsBISOverlayLocked())
    refs.mplusRecordCheck:SetChecked(ns.DB:IsMythicPlusRecordOverlayEnabled())

    refs.statsBox.title:SetText(ns.L("utility_section_stats_overlay"))
    refs.statsHint:SetText(ns.L("utility_stats_hint"))
    refs.statsCheck.Text:SetText(ns.L("config_stats_overlay_show"))
    refs.tankCheck.Text:SetText(ns.L("config_stats_tank_stats_show"))
    refs.statsLockCheck.Text:SetText(ns.L("config_stats_overlay_lock"))
    refs.statsCheck:SetChecked(ns.DB:IsStatsOverlayEnabled())
    refs.tankCheck:SetChecked(ns.DB:IsStatsOverlayTankStatsEnabled())
    refs.statsLockCheck:SetChecked(ns.DB:IsStatsOverlayLocked())

    refs.profBox.title:SetText(ns.L("utility_section_profession_overlay"))
    refs.profHint:SetText(ns.L("utility_profession_hint"))
    refs.profCheck.Text:SetText(ns.L("config_profession_overlay_show"))
    refs.profLockCheck.Text:SetText(ns.L("config_profession_overlay_lock"))
    refs.profCheck:SetChecked(ns.DB:IsProfessionKnowledgeOverlayEnabled())
    refs.profLockCheck:SetChecked(ns.DB:IsProfessionKnowledgeOverlayLocked())

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
