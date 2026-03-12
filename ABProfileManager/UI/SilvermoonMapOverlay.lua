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
    service = 1.08,
    travel = 1.08,
    profession = 1.24,
    pvp = 1.10,
    dungeon = 1.18,
    delve = 1.16,
    raid = 1.22,
    renown = 1.08,
}
local CATEGORY_PRIORITY = {
    raid = 10,
    dungeon = 20,
    delve = 30,
    renown = 40,
    pvp = 50,
    travel = 60,
    profession = 70,
    service = 80,
}
local CATEGORY_MARKER_RADIUS = {
    service = 9,
    travel = 10,
    profession = 8,
    pvp = 10,
    dungeon = 12,
    delve = 12,
    raid = 13,
    renown = 10,
}
local MAP_DENSITY_SCALE = {
    dense = 0.98,
    normal = 1.04,
}
local LAYOUT_PADDING = 8
local ZOOM_BUCKET_STEP = 0.02
local CANVAS_BUCKET_STEP = 0.02
local CROWD_RADIUS_PERCENT = 7

local function getMapCanvasParent()
    if not WorldMapFrame or not WorldMapFrame.ScrollContainer then
        return nil
    end

    return WorldMapFrame.ScrollContainer.Child
        or WorldMapFrame.ScrollContainer.Canvas
        or WorldMapFrame.ScrollContainer
end

local function clamp(value, minValue, maxValue)
    return math.max(minValue, math.min(maxValue, value))
end

local function roundToStep(value, step)
    step = step or 0.01
    if type(value) ~= "number" then
        return nil
    end

    return math.floor((value / step) + 0.5) * step
end

local function getPointColor(category)
    local color = CATEGORY_COLORS[category] or CATEGORY_COLORS.service
    return color[1], color[2], color[3]
end

local function getPointScale(category)
    return CATEGORY_SIZE_SCALE[category] or 1
end

local function getPointPriority(point)
    return point.priority or CATEGORY_PRIORITY[point.category] or 100
end

local function getFilterKey(point)
    if point.category == "travel" then
        return "portals"
    end
    if point.category == "profession" then
        return "professions"
    end
    if point.category == "dungeon" or point.category == "raid" then
        return "dungeons"
    end
    if point.category == "delve" then
        return "delves"
    end

    return "facilities"
end

local function isPointEnabled(point)
    if not ns.DB or not ns.DB.IsSilvermoonMapCategoryEnabled then
        return true
    end

    return ns.DB:IsSilvermoonMapCategoryEnabled(getFilterKey(point))
end

local function getMarkerRadius(point)
    return point.markerRadius or CATEGORY_MARKER_RADIUS[point.category] or 10
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

local function getCanvasScale()
    if not WorldMapFrame then
        return nil
    end

    if type(WorldMapFrame.GetCanvasScale) == "function" then
        local ok, scale = pcall(WorldMapFrame.GetCanvasScale, WorldMapFrame)
        if ok and type(scale) == "number" and scale > 0 then
            return scale
        end
    end

    local scrollContainer = WorldMapFrame.ScrollContainer
    if scrollContainer and type(scrollContainer.GetCanvasScale) == "function" then
        local ok, scale = pcall(scrollContainer.GetCanvasScale, scrollContainer)
        if ok and type(scale) == "number" and scale > 0 then
            return scale
        end
    end

    return nil
end

local function getZoomScaleMultiplier()
    local zoomPercent = getCanvasZoomPercent()
    local canvasScale = getCanvasScale()

    local zoomScale = 1.12
    if type(canvasScale) == "number" and canvasScale > 0 then
        zoomScale = clamp(math.pow(1 / canvasScale, 0.58), 1.00, 1.42)
    elseif type(zoomPercent) == "number" then
        zoomScale = 1.08 + ((1 - zoomPercent) * 0.18)
    end

    local zoomBucket = roundToStep(zoomPercent or 0.5, ZOOM_BUCKET_STEP)
    local canvasBucket = roundToStep(canvasScale or 1, CANVAS_BUCKET_STEP)
    return zoomScale, zoomBucket, canvasBucket
end

local function getMapInfo(mapID)
    if not mapID or not C_Map or type(C_Map.GetMapInfo) ~= "function" then
        return nil
    end

    local ok, info = pcall(C_Map.GetMapInfo, mapID)
    if ok then
        return info
    end

    return nil
end

local function collectMapLineage(mapID)
    local lineage = {}
    local names = {}
    local visited = {}

    while mapID and not visited[mapID] do
        visited[mapID] = true
        lineage[#lineage + 1] = mapID

        local info = getMapInfo(mapID)
        if not info then
            break
        end

        if info.name and info.name ~= "" then
            names[#names + 1] = info.name
        end

        mapID = info.parentMapID
    end

    return lineage, names
end

local function resolveMapData(mapID)
    local data = ns.Data and ns.Data.SilvermoonMapData
    if not data or not data.maps then
        return nil, nil
    end

    if data.maps[mapID] then
        return data.maps[mapID], mapID
    end

    if data.aliases and data.aliases[mapID] and data.maps[data.aliases[mapID]] then
        return data.maps[data.aliases[mapID]], data.aliases[mapID]
    end

    local lineage, names = collectMapLineage(mapID)
    for _, lineageID in ipairs(lineage) do
        if data.maps[lineageID] then
            return data.maps[lineageID], lineageID
        end

        if data.aliases and data.aliases[lineageID] and data.maps[data.aliases[lineageID]] then
            return data.maps[data.aliases[lineageID]], data.aliases[lineageID]
        end
    end

    if data.nameAliases then
        for _, name in ipairs(names) do
            local aliasMapID = data.nameAliases[name]
            if aliasMapID and data.maps[aliasMapID] then
                return data.maps[aliasMapID], aliasMapID
            end
        end
    end

    return nil, nil
end

local function utf8Chars(text)
    local chars = {}
    for character in string.gmatch(tostring(text or ""), "[%z\1-\127\194-\244][\128-\191]*") do
        chars[#chars + 1] = character
    end
    return chars
end

local function wrapByWords(text, wordsPerLine, maxLines)
    wordsPerLine = math.max(1, wordsPerLine or 1)
    local words = {}
    for word in string.gmatch(text or "", "%S+") do
        words[#words + 1] = word
    end

    if #words <= wordsPerLine then
        return text
    end

    local lines = {}
    local line = {}
    for _, word in ipairs(words) do
        line[#line + 1] = word
        if #line >= wordsPerLine then
            lines[#lines + 1] = table.concat(line, " ")
            line = {}
            if maxLines and #lines >= maxLines - 1 then
                break
            end
        end
    end

    if #line > 0 then
        lines[#lines + 1] = table.concat(line, " ")
    elseif #lines * wordsPerLine < #words then
        local remainder = {}
        for index = (#lines * wordsPerLine) + 1, #words do
            remainder[#remainder + 1] = words[index]
        end
        if #remainder > 0 then
            lines[#lines + 1] = table.concat(remainder, " ")
        end
    end

    return table.concat(lines, "\n")
end

local function wrapByChars(text, charsPerLine)
    charsPerLine = math.max(1, charsPerLine or 4)
    local characters = utf8Chars(text)
    if #characters <= charsPerLine then
        return text
    end

    local lines = {}
    local line = {}
    for _, character in ipairs(characters) do
        line[#line + 1] = character
        if #line >= charsPerLine then
            lines[#lines + 1] = table.concat(line, "")
            line = {}
        end
    end

    if #line > 0 then
        lines[#lines + 1] = table.concat(line, "")
    end

    return table.concat(lines, "\n")
end

local function isKoreanLocale()
    return ns.DB and ns.DB:GetLanguage() == ns.Constants.LANGUAGE.KOREAN
end

local function resolveLabelName(point)
    local text = tostring(ns.L(point.labelKey) or "")
    if text == "" then
        return text
    end

    if point.noSpaces then
        text = string.gsub(text, "%s+", "")
    end

    if point.noWrap or string.find(text, "\n", 1, true) then
        return text
    end

    if string.find(text, " ", 1, true) then
        return wrapByWords(text, point.wordsPerLine or 1, point.maxLines or 2)
    end

    if isKoreanLocale() and (point.maxCharsPerLine or point.category == "dungeon" or point.category == "delve" or point.category == "raid") then
        return wrapByChars(text, point.maxCharsPerLine or 3)
    end

    return text
end

local function resolveDisplayText(point)
    local labelName = resolveLabelName(point)
    if point.category == "dungeon" or point.category == "delve" or point.category == "raid" then
        local prefix = ns.L("map_prefix_" .. point.category)
        return string.format("%s:\n%s", prefix, labelName)
    end

    return labelName
end

local function getDensityScale(mapData)
    return MAP_DENSITY_SCALE[mapData and mapData.density or "normal"] or 1
end

local function getNearbyCount(points, point, radiusPercent)
    local nearby = 0
    local radius = radiusPercent or CROWD_RADIUS_PERCENT
    for _, otherPoint in ipairs(points or {}) do
        if otherPoint ~= point then
            local dx = (point.x or 0) - (otherPoint.x or 0)
            local dy = (point.y or 0) - (otherPoint.y or 0)
            if ((dx * dx) + (dy * dy)) <= (radius * radius) then
                nearby = nearby + 1
            end
        end
    end

    return nearby
end

local function getCrowdScale(nearbyCount)
    if nearbyCount >= 4 then
        return 0.94
    end
    if nearbyCount >= 2 then
        return 0.99
    end
    if nearbyCount == 0 then
        return 1.18
    end

    return 1.04
end

local function rectsOverlap(left, right)
    return left.left < right.right
        and left.right > right.left
        and left.top < right.bottom
        and left.bottom > right.top
end

local function buildRect(centerX, centerY, width, height)
    return {
        left = centerX - (width / 2),
        right = centerX + (width / 2),
        top = centerY - (height / 2),
        bottom = centerY + (height / 2),
    }
end

local function rectContainsPointRadius(rect, pointX, pointY, radius)
    local nearestX = clamp(pointX, rect.left, rect.right)
    local nearestY = clamp(pointY, rect.top, rect.bottom)
    local dx = pointX - nearestX
    local dy = pointY - nearestY
    return ((dx * dx) + (dy * dy)) <= ((radius or 0) * (radius or 0))
end

local function measureLabel(label, point, text, fontSize)
    label:SetFont(FONT_PATH, fontSize, point.outline or "THICKOUTLINE")
    label:SetText(text)

    local naturalWidth = math.ceil(label:GetStringWidth() or 0)
    local wrap = not point.noWrap and (
        point.width
        or string.find(text, "\n", 1, true) ~= nil
        or string.find(text, " ", 1, true) ~= nil
    )

    local targetWidth = point.width
    if not targetWidth then
        if wrap then
            targetWidth = clamp(
                math.floor((naturalWidth + 18) * (point.widthScale or 0.72)),
                point.minWidth or 74,
                point.maxWidth or 132
            )
        else
            targetWidth = clamp(naturalWidth + 18, point.minWidth or 68, point.maxWidth or 168)
        end
    end

    label:SetWidth(targetWidth)
    if label.SetWordWrap then
        label:SetWordWrap(wrap and true or false)
    end
    label:SetText(text)

    local labelWidth = targetWidth
    local labelHeight = math.max(fontSize + 4, math.ceil(label:GetStringHeight() or 0))
    return labelWidth, labelHeight
end

local function buildCandidateOffsets(point, labelWidth, labelHeight, crowded)
    local markerRadius = getMarkerRadius(point)
    local verticalPadding = crowded and 7 or 11
    local horizontalPadding = crowded and 10 or 14
    local lateralShift = crowded and math.max(12, labelWidth * 0.12) or math.max(18, labelWidth * 0.16)
    local verticalDistance = markerRadius + (labelHeight / 2) + verticalPadding
    local baseOffsetX = point.offsetX or 0
    local baseOffsetY = point.offsetY or 0

    local above = { x = baseOffsetX, y = baseOffsetY - verticalDistance }
    local below = { x = baseOffsetX, y = baseOffsetY + verticalDistance }
    local aboveRight = { x = baseOffsetX + lateralShift + horizontalPadding, y = baseOffsetY - verticalDistance }
    local aboveLeft = { x = baseOffsetX - lateralShift - horizontalPadding, y = baseOffsetY - verticalDistance }
    local belowRight = { x = baseOffsetX + lateralShift + horizontalPadding, y = baseOffsetY + verticalDistance }
    local belowLeft = { x = baseOffsetX - lateralShift - horizontalPadding, y = baseOffsetY + verticalDistance }

    if point.preferBelow then
        return {
            below,
            belowRight,
            belowLeft,
            above,
            aboveRight,
            aboveLeft,
        }
    end

    return {
        above,
        aboveRight,
        aboveLeft,
        below,
        belowRight,
        belowLeft,
    }
end

local function scoreCandidate(rect, baseX, baseY, placedRects, allPoints, currentPoint, width, height)
    local score = 0

    if rect.left < LAYOUT_PADDING then
        score = score + ((LAYOUT_PADDING - rect.left) * 12)
    end
    if rect.right > (width - LAYOUT_PADDING) then
        score = score + ((rect.right - width + LAYOUT_PADDING) * 12)
    end
    if rect.top < LAYOUT_PADDING then
        score = score + ((LAYOUT_PADDING - rect.top) * 12)
    end
    if rect.bottom > (height - LAYOUT_PADDING) then
        score = score + ((rect.bottom - height + LAYOUT_PADDING) * 12)
    end

    for _, placed in ipairs(placedRects or {}) do
        if rectsOverlap(rect, placed.rect) then
            score = score + 600
        end
    end

    for _, pointData in ipairs(allPoints or {}) do
        if pointData ~= currentPoint then
            local pointX = ((pointData.x or 0) / 100) * width
            local pointY = ((pointData.y or 0) / 100) * height
            if rectContainsPointRadius(rect, pointX, pointY, getMarkerRadius(pointData)) then
                score = score + 220
            end
        end
    end

    local rectCenterX = (rect.left + rect.right) / 2
    local rectCenterY = (rect.top + rect.bottom) / 2
    score = score + (math.abs(rectCenterX - baseX) * 0.35) + (math.abs(rectCenterY - baseY) * 0.55)

    return score
end

function SilvermoonMapOverlay:Initialize()
    if self.driver then
        return
    end

    self.driver = CreateFrame("Frame")
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
        self.lastLayoutKey = nil
        self:Refresh()
    end)

    WorldMapFrame:HookScript("OnHide", function()
        self:SetDriverActive(false)
        self:HideAll()
    end)

    if type(WorldMapFrame.SetMapID) == "function" then
        hooksecurefunc(WorldMapFrame, "SetMapID", function()
            self.lastLayoutKey = nil
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
        self.lastLayoutKey = nil
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

    local zoomScale, zoomBucket, canvasBucket = getZoomScaleMultiplier()
    local densityScale = getDensityScale(mapData)
    local sourcePoints = mapData.points or {}
    local points = {}
    for _, point in ipairs(sourcePoints) do
        if isPointEnabled(point) then
            points[#points + 1] = point
        end
    end
    local entries = {}

    for _, point in ipairs(points) do
        entries[#entries + 1] = {
            point = point,
            nearbyCount = getNearbyCount(points, point, point.crowdRadius or CROWD_RADIUS_PERCENT),
        }
    end

    table.sort(entries, function(left, right)
        local leftPriority = getPointPriority(left.point)
        local rightPriority = getPointPriority(right.point)
        if leftPriority == rightPriority then
            return (left.point.key or "") < (right.point.key or "")
        end
        return leftPriority < rightPriority
    end)

    local placedRects = {}
    for index, entry in ipairs(entries) do
        local point = entry.point
        local label = self:EnsureLabel(index)
        local text = resolveDisplayText(point)
        local red, green, blue = getPointColor(point.category)
        local crowdScale = getCrowdScale(entry.nearbyCount)
        local scale = (point.scale or getPointScale(point.category)) * densityScale * crowdScale * (zoomScale or 1)
        local fontSize = math.max(point.minFontSize or 11, math.floor(((point.size or 14) * scale) + 0.5))

        label:ClearAllPoints()
        label:SetTextColor(red, green, blue, point.alpha or 1)
        if label.SetSpacing then
            label:SetSpacing(point.spacing or 0)
        end

        local labelWidth, labelHeight = measureLabel(label, point, text, fontSize)
        local pointX = ((point.x or 0) / 100) * width
        local pointY = ((point.y or 0) / 100) * height
        local crowded = entry.nearbyCount >= 2
        local candidates = buildCandidateOffsets(point, labelWidth, labelHeight, crowded)
        local bestRect = nil
        local bestOffset = nil
        local bestScore = nil

        for _, candidate in ipairs(candidates) do
            local centerX = pointX + candidate.x
            local centerY = pointY + candidate.y
            local rect = buildRect(centerX, centerY, labelWidth, labelHeight)
            local score = scoreCandidate(rect, pointX, pointY, placedRects, points, point, width, height)
            if not bestScore or score < bestScore then
                bestScore = score
                bestRect = rect
                bestOffset = candidate
            end
        end

        local resolvedOffset = bestOffset or { x = point.offsetX or 0, y = point.offsetY or 0 }
        label:SetPoint("CENTER", parent, "TOPLEFT", pointX + resolvedOffset.x, -(pointY + resolvedOffset.y))
        label:Show()

        placedRects[#placedRects + 1] = {
            rect = bestRect or buildRect(pointX, pointY, labelWidth, labelHeight),
        }
    end

    for index = #entries + 1, #(self.labels or {}) do
        self.labels[index]:Hide()
    end

    self.lastZoomBucket = zoomBucket
    self.lastCanvasBucket = canvasBucket
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

    local currentMapID = WorldMapFrame:GetMapID()
    local mapData, resolvedMapID = resolveMapData(currentMapID)
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
    local language = ns.DB and ns.DB:GetLanguage() or "?"
    local filterSignature = ""
    if ns.DB and ns.DB.GetSilvermoonMapOverlaySettings then
        local filters = ns.DB:GetSilvermoonMapOverlaySettings().filters or {}
        filterSignature = table.concat({
            filters.facilities and "1" or "0",
            filters.portals and "1" or "0",
            filters.professions and "1" or "0",
            filters.dungeons and "1" or "0",
            filters.delves and "1" or "0",
        }, "")
    end
    local _, zoomBucket, canvasBucket = getZoomScaleMultiplier()
    local layoutKey = table.concat({
        tostring(currentMapID or 0),
        tostring(resolvedMapID or 0),
        tostring(width),
        tostring(height),
        tostring(language),
        filterSignature,
        tostring(zoomBucket or 0),
        tostring(canvasBucket or 0),
    }, ":")

    if layoutKey ~= self.lastLayoutKey then
        self.lastLayoutKey = layoutKey
        self:LayoutPoints(parent, mapData)
    end

    frame:Show()
end
