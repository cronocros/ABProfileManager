local _, ns = ...

local ProfessionKnowledgeOverlay = {}
ns.UI.ProfessionKnowledgeOverlay = ProfessionKnowledgeOverlay

local FONT_PATH = UNIT_NAME_FONT or STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF"
local TITLE_SIZE = 15
local ROW_SIZE = 14
local MIN_WIDTH = 220
local MIN_HEIGHT = 54
local PADDING_X = 4
local PADDING_Y = 4

local function applyTextStyle(fontString, size, r, g, b)
    fontString:SetFont(FONT_PATH, size, "OUTLINE")
    fontString:SetTextColor(r, g, b, 1)
    fontString:SetJustifyH("LEFT")
    fontString:SetJustifyV("TOP")
    if fontString.SetWordWrap then
        fontString:SetWordWrap(false)
    end
    if fontString.SetShadowOffset then
        fontString:SetShadowOffset(1, -1)
        fontString:SetShadowColor(0, 0, 0, 0.85)
    end
end

function ProfessionKnowledgeOverlay:Initialize()
    if self.frame then
        return
    end

    local config = ns.DB and ns.DB:GetProfessionKnowledgeOverlayConfig() or ns.Data.Defaults.ui.professionKnowledgeOverlay
    local frame = CreateFrame("Frame", "ABPM_ProfessionKnowledgeOverlay", UIParent)
    frame:SetPoint(config.point or "CENTER", UIParent, config.relativePoint or "CENTER", config.x or 0, config.y or 0)
    frame:SetSize(MIN_WIDTH, MIN_HEIGHT)
    frame:SetFrameStrata("HIGH")
    frame:SetClampedToScreen(true)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", function(currentFrame)
        currentFrame:StartMoving()
    end)
    frame:SetScript("OnDragStop", function(currentFrame)
        currentFrame:StopMovingOrSizing()
        if ns.DB then
            ns.DB:SaveProfessionKnowledgeOverlayPosition(currentFrame)
        end
    end)
    frame:SetScript("OnHide", function(currentFrame)
        currentFrame:StopMovingOrSizing()
    end)

    frame.title = frame:CreateFontString(nil, "OVERLAY")
    frame.title:SetPoint("TOPLEFT", frame, "TOPLEFT", PADDING_X, -PADDING_Y)
    applyTextStyle(frame.title, TITLE_SIZE, 1, 0.86, 0.40)

    self.rows = {}
    self.frame = frame
    frame:Hide()
end

function ProfessionKnowledgeOverlay:EnsureRowCount(count)
    while #self.rows < count do
        local row = self.frame:CreateFontString(nil, "OVERLAY")
        applyTextStyle(row, ROW_SIZE, 0.90, 0.96, 1.00)
        self.rows[#self.rows + 1] = row
    end
end

function ProfessionKnowledgeOverlay:Refresh()
    if not self.frame then
        self:Initialize()
    end

    if not self.frame or not ns.DB or not ns.DB:IsProfessionKnowledgeOverlayEnabled() then
        if self.frame then
            self.frame:Hide()
        end
        return
    end

    local professions = ns.Modules.ProfessionKnowledgeTracker:GetKnownProfessions()
    if #professions == 0 then
        self.frame:Hide()
        return
    end

    self.frame.title:SetText(ns.L("professions_overlay_title"))
    self:EnsureRowCount(#professions)

    local maxWidth = math.ceil(self.frame.title:GetStringWidth() or 0)
    local previous = self.frame.title
    for index, professionEntry in ipairs(professions) do
        local summary = ns.Modules.ProfessionKnowledgeTracker:GetProfessionSummary(professionEntry.key)
        local row = self.rows[index]
        row:ClearAllPoints()
        row:SetPoint("TOPLEFT", previous, "BOTTOMLEFT", 0, -6)
        row:SetText(ns.L(
            "professions_overlay_row",
            ns.Modules.ProfessionKnowledgeTracker:GetProfessionDisplayName(professionEntry),
            summary and summary.weeklyEarned or 0,
            summary and summary.weeklyMax or 0,
            summary and summary.oneTimeEarned or 0,
            summary and summary.oneTimeMax or 0
        ))
        row:Show()
        previous = row
        maxWidth = math.max(maxWidth, math.ceil(row:GetStringWidth() or 0))
    end

    for index = #professions + 1, #self.rows do
        self.rows[index]:Hide()
    end

    local height = PADDING_Y * 2
    height = height + math.ceil(self.frame.title:GetStringHeight() or TITLE_SIZE)
    for index = 1, #professions do
        height = height + 6 + math.ceil(self.rows[index]:GetStringHeight() or ROW_SIZE)
    end

    self.frame:SetSize(math.max(MIN_WIDTH, maxWidth + (PADDING_X * 2)), math.max(MIN_HEIGHT, height))
    self.frame:Show()
end
