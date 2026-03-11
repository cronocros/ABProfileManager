local _, ns = ...

local SilvermoonMapOverlay = {}
ns.UI.SilvermoonMapOverlay = SilvermoonMapOverlay

local FONT_PATH = STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF"
local REFRESH_INTERVAL = 0.25
local CATEGORY_COLORS = {
    service = { 1.00, 0.87, 0.42 },
    travel = { 0.48, 0.92, 1.00 },
    profession = { 0.55, 1.00, 0.78 },
    pvp = { 1.00, 0.44, 0.44 },
    dungeon = { 1.00, 0.64, 0.34 },
    delve = { 0.82, 0.74, 1.00 },
    renown = { 1.00, 0.78, 0.54 },
}

local function getMapCanvasParent()
    if not WorldMapFrame or not WorldMapFrame.ScrollContainer then
        return nil
    end

    return WorldMapFrame.ScrollContainer.Child
        or WorldMapFrame.ScrollContainer.Canvas
        or WorldMapFrame.ScrollContainer
end

local function getPointColor(category)
    local color = CATEGORY_COLORS[category] or CATEGORY_COLORS.service
    return color[1], color[2], color[3]
end

function SilvermoonMapOverlay:Initialize()
    if self.driver then
        return
    end

    local driver = CreateFrame("Frame")
    driver:SetScript("OnUpdate", function(_, elapsed)
        self.elapsed = (self.elapsed or 0) + elapsed
        if self.elapsed < REFRESH_INTERVAL then
            return
        end

        self.elapsed = 0
        self:Refresh()
    end)

    self.driver = driver
end

function SilvermoonMapOverlay:EnsureOverlayFrame()
    local parent = getMapCanvasParent()
    if not parent then
        return nil
    end

    if self.overlayFrame and self.overlayFrame:GetParent() ~= parent then
        self.overlayFrame:SetParent(parent)
        self.overlayFrame:ClearAllPoints()
        self.overlayFrame:SetAllPoints(parent)
        self.overlayFrame:SetFrameLevel(parent:GetFrameLevel() + 20)
        self.lastWidth = nil
        self.lastHeight = nil
    end

    if self.overlayFrame then
        return self.overlayFrame
    end

    local frame = CreateFrame("Frame", nil, parent)
    frame:SetAllPoints(parent)
    frame:SetFrameStrata("DIALOG")
    frame:SetFrameLevel(parent:GetFrameLevel() + 20)
    frame:EnableMouse(false)

    self.overlayFrame = frame
    self.labels = {}
    return frame
end

function SilvermoonMapOverlay:EnsureLabel(index)
    self.labels = self.labels or {}
    if self.labels[index] then
        return self.labels[index]
    end

    local label = self.overlayFrame:CreateFontString(nil, "OVERLAY")
    label:SetJustifyH("CENTER")
    label:SetJustifyV("MIDDLE")
    if label.SetShadowOffset then
        label:SetShadowOffset(2, -2)
        label:SetShadowColor(0, 0, 0, 0.95)
    end
    self.labels[index] = label
    return label
end

function SilvermoonMapOverlay:HideAll()
    if not self.overlayFrame then
        return
    end

    self.overlayFrame:Hide()
    for _, label in ipairs(self.labels or {}) do
        label:Hide()
    end
end

function SilvermoonMapOverlay:LayoutPoints(parent, mapData)
    local width = parent:GetWidth() or 0
    local height = parent:GetHeight() or 0
    if width <= 0 or height <= 0 or not mapData then
        self:HideAll()
        return
    end

    local points = mapData.points or {}
    for index, point in ipairs(points) do
        local label = self:EnsureLabel(index)
        local red, green, blue = getPointColor(point.category)
        label:ClearAllPoints()
        label:SetPoint(
            "CENTER",
            parent,
            "TOPLEFT",
            ((point.x or 0) / 100) * width + (point.offsetX or 0),
            -(((point.y or 0) / 100) * height) + (point.offsetY or 0)
        )
        label:SetFont(FONT_PATH, point.size or 16, point.outline or "THICKOUTLINE")
        label:SetTextColor(red, green, blue, point.alpha or 1)
        label:SetText(ns.L(point.labelKey))
        if point.width then
            label:SetWidth(point.width)
            if label.SetWordWrap then
                label:SetWordWrap(true)
            end
        else
            label:SetWidth(math.max(40, math.ceil(label:GetStringWidth() or 0) + 8))
            if label.SetWordWrap then
                label:SetWordWrap(false)
            end
        end
        label:Show()
    end

    for index = #points + 1, #(self.labels or {}) do
        self.labels[index]:Hide()
    end
end

function SilvermoonMapOverlay:Refresh()
    if not ns.DB or not ns.DB:IsSilvermoonMapOverlayEnabled() then
        self:HideAll()
        return
    end

    if not WorldMapFrame or not WorldMapFrame:IsShown() or type(WorldMapFrame.GetMapID) ~= "function" then
        self:HideAll()
        return
    end

    local data = ns.Data and ns.Data.SilvermoonMapData
    local mapID = WorldMapFrame:GetMapID()
    local mapData = data and data.maps and data.maps[mapID]
    if not mapData then
        self:HideAll()
        return
    end

    local frame = self:EnsureOverlayFrame()
    local parent = getMapCanvasParent()
    if not frame or not parent then
        self:HideAll()
        return
    end

    local width = parent:GetWidth() or 0
    local height = parent:GetHeight() or 0
    local language = ns.DB and ns.DB:GetLanguage() or nil
    if mapID ~= self.currentMapID or width ~= self.lastWidth or height ~= self.lastHeight or language ~= self.lastLanguage then
        self.currentMapID = mapID
        self.lastWidth = width
        self.lastHeight = height
        self.lastLanguage = language
        self:LayoutPoints(parent, mapData)
    end

    frame:Show()
end
