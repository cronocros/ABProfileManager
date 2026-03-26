local _, ns = ...

local SilvermoonMapOverlay = {}
ns.UI.SilvermoonMapOverlay = SilvermoonMapOverlay

local FONT_PATH = STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF"
local REFRESH_INTERVAL = 0.5
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
    service = 1.10,
    travel = 1.10,
    profession = 1.28,
    pvp = 1.12,
    dungeon = 1.20,
    delve = 1.18,
    raid = 1.24,
    renown = 1.10,
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
    dense = 1.00,
    normal = 1.06,
}
local LAYOUT_PADDING = 8
local ZOOM_BUCKET_STEP = 0.02
local CANVAS_BUCKET_STEP = 0.02
local CROWD_RADIUS_PERCENT = 7
local MAP_TYPE_DUNGEON = (Enum and Enum.UIMapType and Enum.UIMapType.Dungeon) or 4

local function getMapCanvasParent()
    if not WorldMapFrame or not WorldMapFrame.ScrollContainer then
        return nil
    end

    return WorldMapFrame.ScrollContainer.Child
        or WorldMapFrame.ScrollContainer.Canvas
        or WorldMapFrame.ScrollContainer
end

local function isValidCanvasParent(parent)
    return parent
        and parent.IsShown
        and parent:IsShown()
        and (parent.GetWidth and (parent:GetWidth() or 0) > 0)
        and (parent.GetHeight and (parent:GetHeight() or 0) > 0)
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
    if point.category == "renown" then
        return "renown"
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

local function tryResolveMapID(data, mapID)
    if not mapID or not data or not data.maps then
        return nil, nil
    end

    if data.maps[mapID] then
        return data.maps[mapID], mapID
    end

    if data.aliases and data.aliases[mapID] and data.maps[data.aliases[mapID]] then
        return data.maps[data.aliases[mapID]], data.aliases[mapID]
    end

    return nil, nil
end

local function resolveMapData(mapID)
    local data = ns.Data and ns.Data.SilvermoonMapData
    if not data or not data.maps then
        return nil, nil
    end

    local info = getMapInfo(mapID)
    local mapType = info and tonumber(info.mapType) or nil
    if mapType and mapType >= MAP_TYPE_DUNGEON then
        return nil, nil
    end

    local resolvedData, resolvedMapID = tryResolveMapID(data, mapID)
    if resolvedData then
        return resolvedData, resolvedMapID
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

local function wrapByGroupSizes(text, groupSizes)
    local characters = utf8Chars(text)
    if #characters == 0 then
        return ""
    end

    local lines = {}
    local cursor = 1
    for _, size in ipairs(groupSizes or {}) do
        if cursor > #characters then
            break
        end

        local chunk = {}
        for index = cursor, math.min(#characters, cursor + size - 1) do
            chunk[#chunk + 1] = characters[index]
        end

        if #chunk > 0 then
            lines[#lines + 1] = table.concat(chunk, "")
        end
        cursor = cursor + size
    end

    if cursor <= #characters then
        local chunk = {}
        for index = cursor, #characters do
            chunk[#chunk + 1] = characters[index]
        end
        lines[#lines + 1] = table.concat(chunk, "")
    end

    return table.concat(lines, "\n")
end

local function buildKoreanWrapGroups(characterCount, preferredFirstChunk)
    if characterCount <= 3 then
        return { characterCount }
    end

    if characterCount == 4 then
        return { 2, 2 }
    end

    if characterCount == 5 then
        if preferredFirstChunk == 3 then
            return { 3, 2 }
        end
        return { 2, 3 }
    end

    local groups = {}
    local remaining = characterCount
    while remaining > 0 do
        if remaining <= 3 then
            groups[#groups + 1] = remaining
            break
        end

        if remaining == 4 then
            groups[#groups + 1] = 2
            groups[#groups + 1] = 2
            break
        end

        if remaining == 5 then
            if preferredFirstChunk == 3 or #groups > 0 then
                groups[#groups + 1] = 3
                groups[#groups + 1] = 2
            else
                groups[#groups + 1] = 2
                groups[#groups + 1] = 3
            end
            break
        end

        if (remaining - 3) == 1 then
            groups[#groups + 1] = 2
            remaining = remaining - 2
        else
            groups[#groups + 1] = 3
            remaining = remaining - 3
        end
    end

    return groups
end

local function wrapKoreanSmart(text, point)
    local characters = utf8Chars(text)
    local characterCount = #characters
    if characterCount <= 3 then
        return text
    end

    local preferredFirstChunk = tonumber(point and point.preferredFirstChunk) or 2
    local groups = buildKoreanWrapGroups(characterCount, preferredFirstChunk)
    return wrapByGroupSizes(text, groups)
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

    if point.noWrap or point.manualWrap or string.find(text, "\n", 1, true) then
        return text
    end

    if string.find(text, " ", 1, true) then
        return wrapByWords(text, point.wordsPerLine or 1, point.maxLines or 2)
    end

    if isKoreanLocale() and (point.maxCharsPerLine or point.category == "dungeon" or point.category == "delve" or point.category == "raid") then
        if point.maxCharsPerLine then
            return wrapByChars(text, point.maxCharsPerLine)
        end

        return wrapKoreanSmart(text, point)
    end

    return text
end

local function resolveDisplayText(point)
    local labelName = resolveLabelName(point)
    if point.category == "dungeon" or point.category == "delve" or point.category == "raid" then
        local prefix = ns.L("map_prefix_" .. point.category)
        return string.format("%s\n%s", prefix, labelName)
    end

    return labelName
end

local function hasLineBreak(text)
    return string.find(text or "", "\n", 1, true) ~= nil
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
    label:SetWidth(0)
    if label.SetHeight then
        label:SetHeight(0)
    end
    if label.SetMaxLines then
        label:SetMaxLines(0)
    end
    if label.SetWordWrap then
        label:SetWordWrap(false)
    end
    if label.SetNonSpaceWrap then
        label:SetNonSpaceWrap(false)
    end
    label:SetText(text)

    local naturalWidth = math.ceil(label:GetStringWidth() or 0)
    local naturalHeight = math.ceil(label:GetStringHeight() or 0)
    local multiLine = hasLineBreak(text)
    local wrap = not point.noWrap and not multiLine and (
        point.width
        or string.find(text, " ", 1, true) ~= nil
    )

    local targetWidth = point.width
    if not targetWidth then
        if multiLine then
            targetWidth = math.max(naturalWidth + 28, point.minWidth or 92)
        elseif wrap then
            targetWidth = clamp(
                math.floor((naturalWidth + 18) * (point.widthScale or 0.72)),
                point.minWidth or 74,
                point.maxWidth or 132
            )
        else
            targetWidth = clamp(naturalWidth + 18, point.minWidth or 68, point.maxWidth or 168)
        end
    end

    if multiLine then
        targetWidth = math.max(targetWidth, naturalWidth + 28)
    end

    label:SetWidth(targetWidth)
    if label.SetWordWrap then
        label:SetWordWrap((multiLine or wrap) and true or false)
    end
    if label.SetNonSpaceWrap then
        label:SetNonSpaceWrap((wrap and not multiLine) and true or false)
    end
    label:SetText(text)

    local labelWidth = math.max(targetWidth, math.ceil(label:GetStringWidth() or 0) + 16)
    local labelHeight = math.max(fontSize + 6, naturalHeight, math.ceil(label:GetStringHeight() or 0) + 4)
    if label.SetHeight then
        label:SetHeight(labelHeight)
    end
    return labelWidth, labelHeight
end

local function buildCandidateOffsets(point, labelWidth, labelHeight, crowded)
    local markerRadius = getMarkerRadius(point)
    local verticalPadding = crowded and 7 or 5
    local horizontalPadding = crowded and 10 or 6
    local lateralShift = crowded and math.max(12, labelWidth * 0.12) or math.max(10, labelWidth * 0.08)
    local verticalDistance = markerRadius + (labelHeight / 2) + verticalPadding
    local sideDistance = markerRadius + (labelWidth / 2) + horizontalPadding
    local farVerticalDistance = verticalDistance + math.max(10, labelHeight * 0.72)
    local farSideDistance = sideDistance + math.max(14, labelWidth * 0.20)
    local baseOffsetX = point.offsetX or 0
    local baseOffsetY = point.offsetY or 0

    local above = { x = baseOffsetX, y = baseOffsetY - verticalDistance }
    local below = { x = baseOffsetX, y = baseOffsetY + verticalDistance }
    local right = { x = baseOffsetX + sideDistance, y = baseOffsetY }
    local left = { x = baseOffsetX - sideDistance, y = baseOffsetY }
    local aboveRight = { x = baseOffsetX + lateralShift + horizontalPadding, y = baseOffsetY - verticalDistance }
    local aboveLeft = { x = baseOffsetX - lateralShift - horizontalPadding, y = baseOffsetY - verticalDistance }
    local belowRight = { x = baseOffsetX + lateralShift + horizontalPadding, y = baseOffsetY + verticalDistance }
    local belowLeft = { x = baseOffsetX - lateralShift - horizontalPadding, y = baseOffsetY + verticalDistance }
    local farAbove = { x = baseOffsetX, y = baseOffsetY - farVerticalDistance }
    local farBelow = { x = baseOffsetX, y = baseOffsetY + farVerticalDistance }
    local farRight = { x = baseOffsetX + farSideDistance, y = baseOffsetY }
    local farLeft = { x = baseOffsetX - farSideDistance, y = baseOffsetY }
    local farAboveRight = { x = baseOffsetX + farSideDistance, y = baseOffsetY - farVerticalDistance }
    local farAboveLeft = { x = baseOffsetX - farSideDistance, y = baseOffsetY - farVerticalDistance }
    local farBelowRight = { x = baseOffsetX + farSideDistance, y = baseOffsetY + farVerticalDistance }
    local farBelowLeft = { x = baseOffsetX - farSideDistance, y = baseOffsetY + farVerticalDistance }

    if point.preferBelow then
        return {
            below,
            belowRight,
            belowLeft,
            right,
            left,
            farBelow,
            farBelowRight,
            farBelowLeft,
            above,
            aboveRight,
            aboveLeft,
            farAbove,
            farAboveRight,
            farAboveLeft,
            farRight,
            farLeft,
        }
    end

    return {
        above,
        aboveRight,
        aboveLeft,
        right,
        left,
        farAbove,
        farAboveRight,
        farAboveLeft,
        below,
        belowRight,
        belowLeft,
        farBelow,
        farBelowRight,
        farBelowLeft,
        farRight,
        farLeft,
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
            score = score + 1400
        end
    end

    for _, pointData in ipairs(allPoints or {}) do
        if pointData ~= currentPoint then
            local pointX = ((pointData.x or 0) / 100) * width
            local pointY = ((pointData.y or 0) / 100) * height
            if rectContainsPointRadius(rect, pointX, pointY, getMarkerRadius(pointData)) then
                score = score + 420
            end
        end
    end

    local rectCenterX = (rect.left + rect.right) / 2
    local rectCenterY = (rect.top + rect.bottom) / 2
    score = score + (math.abs(rectCenterX - baseX) * 0.22) + (math.abs(rectCenterY - baseY) * 0.32)

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
    self.lastLayoutKey = nil

    if not self.overlayFrame then
        return
    end

    self.overlayFrame:Hide()
    for _, label in ipairs(self.labels or {}) do
        label:Hide()
    end
end

function SilvermoonMapOverlay:LayoutPoints(parent, mapData)
    if not isValidCanvasParent(parent) or not self.overlayFrame then
        self:HideAll()
        return
    end

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
    local fontOffset = ns.DB and ns.DB.GetTypographyOffset and ns.DB:GetTypographyOffset("mapOverlay") or 0
    for index, entry in ipairs(entries) do
        local point = entry.point
        local label = self:EnsureLabel(index)
        local text = resolveDisplayText(point)
        local red, green, blue = getPointColor(point.category)
        local crowdScale = getCrowdScale(entry.nearbyCount)
        local scale = (point.scale or getPointScale(point.category)) * densityScale * crowdScale * (zoomScale or 1)
        local fontSize = math.max(point.minFontSize or 11, math.floor(((point.size or 14) * scale) + 0.5) + fontOffset)

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

function SilvermoonMapOverlay:RefreshInternal()
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
    if not frame or not isValidCanvasParent(parent) then
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
            filters.renown and "1" or "0",
            filters.dungeons and "1" or "0",
            filters.delves and "1" or "0",
        }, "")
    end
    local _, zoomBucket, canvasBucket = getZoomScaleMultiplier()
    local mapFontOffset = ns.DB and ns.DB.GetTypographyOffset and ns.DB:GetTypographyOffset("mapOverlay") or 0
    local layoutKey = table.concat({
        tostring(currentMapID or 0),
        tostring(resolvedMapID or 0),
        tostring(width),
        tostring(height),
        tostring(language),
        filterSignature,
        tostring(mapFontOffset),
        tostring(zoomBucket or 0),
        tostring(canvasBucket or 0),
    }, ":")

    if layoutKey ~= self.lastLayoutKey then
        self.lastLayoutKey = layoutKey
        self:LayoutPoints(parent, mapData)
    end

    frame:Show()
end

function SilvermoonMapOverlay:Refresh()
    if self.isRefreshing then
        return
    end

    self.isRefreshing = true
    local ok, err = pcall(function()
        self:RefreshInternal()
    end)
    self.isRefreshing = false

    if not ok then
        self:HideAll()
        if ns.Utils and ns.Utils.Debug then
            ns.Utils.Debug("SilvermoonMapOverlay refresh failed: " .. tostring(err))
        end
    end
end
