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
    raid = { 1.00, 0.56, 0.30 },
    renown = { 1.00, 0.78, 0.54 },
}
local CATEGORY_SIZE_SCALE = {
    service = 1.12,
    travel = 1.14,
    profession = 1.42,
    pvp = 1.16,
    dungeon = 1.18,
    delve = 1.18,
    raid = 1.22,
    renown = 1.18,
}
local ZOOM_SCALE_MIN = 1.02
local ZOOM_SCALE_MAX = 1.10
local ZOOM_BUCKET_STEP = 0.02

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

local function getPointScale(category)
    return CATEGORY_SIZE_SCALE[category] or 1.2
end

local function roundToStep(value, step)
    step = step or 0.01
    if type(value) ~= "number" then
        return nil
    end

    return math.floor((value / step) + 0.5) * step
end

local function clamp(value, minValue, maxValue)
    return math.max(minValue, math.min(maxValue, value))
end

local function getCanvasZoomPercent()
    if not WorldMapFrame then
        return nil
    end

    if type(WorldMapFrame.GetCanvasZoomPercent) == "function" then
        local ok, percent = pcall(WorldMapFrame.GetCanvasZoomPercent, WorldMapFrame)
        if ok and type(percent) == "number" then
            return clamp(percent, 0, 1)
        end
    end

    local scrollContainer = WorldMapFrame.ScrollContainer
    if scrollContainer and type(scrollContainer.GetCanvasZoomPercent) == "function" then
        local ok, percent = pcall(scrollContainer.GetCanvasZoomPercent, scrollContainer)
        if ok and type(percent) == "number" then
            return clamp(percent, 0, 1)
        end
    end

    return nil
end

local function getZoomScaleMultiplier()
    local zoomPercent = getCanvasZoomPercent()
    if type(zoomPercent) ~= "number" then
        return 1, nil
    end

    return ZOOM_SCALE_MIN + ((ZOOM_SCALE_MAX - ZOOM_SCALE_MIN) * zoomPercent), roundToStep(zoomPercent, ZOOM_BUCKET_STEP)
end

function SilvermoonMapOverlay:Initialize()
    if self.driver then
        return
    end

    local driver = CreateFrame("Frame")
    self.driver = driver
    self:EnsureHooks()
end

function SilvermoonMapOverlay:HandleDriverUpdate(elapsed)
    self.elapsed = (self.elapsed or 0) + elapsed
    if self.elapsed < REFRESH_INTERVAL then
        return
    end

    self.elapsed = 0
    self:Refresh()
end

function SilvermoonMapOverlay:SetDriverActive(active)
    if not self.driver then
        return
    end

    active = active and true or false
    if self.driverActive == active then
        return
    end

    self.driverActive = active
    self.elapsed = 0

    if active then
        self.driver:SetScript("OnUpdate", function(_, elapsed)
            self:HandleDriverUpdate(elapsed)
        end)
    else
        self.driver:SetScript("OnUpdate", nil)
    end
end

function SilvermoonMapOverlay:EnsureHooks()
    if self.hooksReady or not WorldMapFrame then
        return
    end

    WorldMapFrame:HookScript("OnShow", function()
        self.currentMapID = nil
        self.lastWidth = nil
        self.lastHeight = nil
        self:Refresh()
    end)

    WorldMapFrame:HookScript("OnHide", function()
        self:SetDriverActive(false)
        self:HideAll()
    end)

    if type(WorldMapFrame.SetMapID) == "function" then
        hooksecurefunc(WorldMapFrame, "SetMapID", function()
            self.currentMapID = nil
            self.lastWidth = nil
            self.lastHeight = nil
            self:Refresh()
        end)
    end

    self.hooksReady = true
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
        label:SetShadowOffset(3, -3)
        label:SetShadowColor(0, 0, 0, 0.95)
    end
    self.labels[index] = label
    return label
end

function SilvermoonMapOverlay:HideAll()
    self:SetDriverActive(false)

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

    local zoomScale, zoomBucket = getZoomScaleMultiplier()
    self.lastZoomBucket = zoomBucket

    local points = mapData.points or {}
    for index, point in ipairs(points) do
        local label = self:EnsureLabel(index)
        local red, green, blue = getPointColor(point.category)
        local scale = (point.scale or getPointScale(point.category)) * (zoomScale or 1)
        local fontSize = math.max(point.minFontSize or 12, math.floor(((point.size or 16) * scale) + 0.5))
        local text = ns.L(point.labelKey)
        local shouldWrap = point.wrap
        if shouldWrap == nil then
            shouldWrap = type(point.width) == "number" or (type(text) == "string" and string.find(text, "\n", 1, true) ~= nil)
        end

        label:ClearAllPoints()
        label:SetPoint(
            "CENTER",
            parent,
            "TOPLEFT",
            ((point.x or 0) / 100) * width + (point.offsetX or 0),
            -(((point.y or 0) / 100) * height) + (point.offsetY or 0)
        )
        label:SetFont(FONT_PATH, fontSize, point.outline or "THICKOUTLINE")
        label:SetTextColor(red, green, blue, point.alpha or 1)
        if label.SetSpacing then
            label:SetSpacing(point.spacing or 0)
        end
        label:SetText(text)
        if point.width then
            label:SetWidth(point.width)
        else
            label:SetWidth(math.max(68, math.ceil(label:GetStringWidth() or 0) + 18))
        end
        if label.SetWordWrap then
            label:SetWordWrap(shouldWrap and true or false)
        end
        label:Show()
    end

    for index = #points + 1, #(self.labels or {}) do
        self.labels[index]:Hide()
    end
end

function SilvermoonMapOverlay:Refresh()
    self:EnsureHooks()

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

    self:SetDriverActive(true)

    local width = parent:GetWidth() or 0
    local height = parent:GetHeight() or 0
    local language = ns.DB and ns.DB:GetLanguage() or nil
    local _, zoomBucket = getZoomScaleMultiplier()
    if mapID ~= self.currentMapID
        or width ~= self.lastWidth
        or height ~= self.lastHeight
        or language ~= self.lastLanguage
        or zoomBucket ~= self.lastZoomBucket then
        self.currentMapID = mapID
        self.lastWidth = width
        self.lastHeight = height
        self.lastLanguage = language
        self:LayoutPoints(parent, mapData)
    end

    frame:Show()
end
