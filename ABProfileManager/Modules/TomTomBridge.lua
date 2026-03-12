local _, ns = ...

local TomTomBridge = {}
ns.Modules.TomTomBridge = TomTomBridge

local REGION_LOCKED_MAPS = {
    [2405] = true, -- Voidstorm
    [2413] = true, -- Harandar
}

local function removeWaypoint(uid)
    if not uid or type(TomTom) ~= "table" then
        return
    end

    if type(TomTom.IsValidWaypoint) == "function" then
        local ok, valid = pcall(TomTom.IsValidWaypoint, TomTom, uid)
        if ok and valid and type(TomTom.RemoveWaypoint) == "function" then
            pcall(TomTom.RemoveWaypoint, TomTom, uid)
        end
        return
    end

    if type(TomTom.RemoveWaypoint) == "function" then
        pcall(TomTom.RemoveWaypoint, TomTom, uid)
    end
end

function TomTomBridge:Initialize()
    self.lastWaypoint = nil
    self.activeWaypoints = {}
end

function TomTomBridge:IsAvailable()
    return type(TomTom) == "table" and type(TomTom.AddWaypoint) == "function"
end

local function getMapName(mapID)
    mapID = tonumber(mapID)
    if not mapID or not C_Map or type(C_Map.GetMapInfo) ~= "function" then
        return tostring(mapID or "")
    end

    local ok, mapInfo = pcall(C_Map.GetMapInfo, mapID)
    if ok and mapInfo and mapInfo.name and mapInfo.name ~= "" then
        return mapInfo.name
    end

    return tostring(mapID)
end

local function buildMapLineage(mapID)
    local lineage = {}
    local seen = {}
    local currentMapID = tonumber(mapID)
    while currentMapID and not seen[currentMapID] do
        lineage[currentMapID] = true
        seen[currentMapID] = true

        if not C_Map or type(C_Map.GetMapInfo) ~= "function" then
            break
        end

        local ok, mapInfo = pcall(C_Map.GetMapInfo, currentMapID)
        local parentMapID = ok and mapInfo and tonumber(mapInfo.parentMapID) or nil
        if not parentMapID or parentMapID <= 0 then
            break
        end

        currentMapID = parentMapID
    end

    return lineage
end

function TomTomBridge:RequiresCurrentZone(mapID)
    return REGION_LOCKED_MAPS[tonumber(mapID) or 0] and true or false
end

function TomTomBridge:IsPlayerInWaypointRegion(mapID)
    mapID = tonumber(mapID)
    if not mapID then
        return false
    end

    if not self:RequiresCurrentZone(mapID) then
        return true
    end

    if not C_Map or type(C_Map.GetBestMapForUnit) ~= "function" then
        return false
    end

    local ok, playerMapID = pcall(C_Map.GetBestMapForUnit, "player")
    playerMapID = ok and tonumber(playerMapID) or nil
    if not playerMapID then
        return false
    end

    local lineage = buildMapLineage(playerMapID)
    return lineage[mapID] and true or false
end

function TomTomBridge:GetRestrictionMessage(mapID)
    mapID = tonumber(mapID)
    if not self:RequiresCurrentZone(mapID) then
        return nil
    end

    if self:IsPlayerInWaypointRegion(mapID) then
        return nil
    end

    return ns.L("tomtom_waypoint_region_required", getMapName(mapID))
end

function TomTomBridge:ClearTrackedWaypoints()
    if not self:IsAvailable() then
        self.lastWaypoint = nil
        self.activeWaypoints = {}
        return
    end

    for index = #(self.activeWaypoints or {}), 1, -1 do
        local uid = self.activeWaypoints[index]
        if uid then
            removeWaypoint(uid)
        end
    end

    self.lastWaypoint = nil
    self.activeWaypoints = {}
end

function TomTomBridge:AddWaypoint(mapID, x, y, title)
    if not self:IsAvailable() then
        return nil, ns.L("tomtom_missing")
    end

    mapID = tonumber(mapID)
    x = tonumber(x)
    y = tonumber(y)
    if not mapID or not x or not y then
        return nil, ns.L("tomtom_waypoint_unavailable")
    end

    local restrictionMessage = self:GetRestrictionMessage(mapID)
    if restrictionMessage then
        return nil, restrictionMessage
    end

    local previousWaypoints = {}
    for index, uid in ipairs(self.activeWaypoints or {}) do
        previousWaypoints[index] = uid
    end

    local candidateMapIDs = {}
    local seen = {}
    local currentMapID = mapID
    while currentMapID and not seen[currentMapID] do
        candidateMapIDs[#candidateMapIDs + 1] = currentMapID
        seen[currentMapID] = true

        if not C_Map or type(C_Map.GetMapInfo) ~= "function" then
            break
        end

        local ok, mapInfo = pcall(C_Map.GetMapInfo, currentMapID)
        local parentMapID = ok and mapInfo and tonumber(mapInfo.parentMapID) or nil
        if not parentMapID or parentMapID <= 0 then
            break
        end
        currentMapID = parentMapID
    end

    local uid = nil
    for _, candidateMapID in ipairs(candidateMapIDs) do
        local ok, result = pcall(TomTom.AddWaypoint, TomTom, candidateMapID, x / 100, y / 100, {
            title = title or ns.L("professions_overlay_title"),
            from = "ABPM",
            persistent = false,
            minimap = true,
            world = true,
            crazy = true,
            silent = true,
        })
        if ok and result then
            uid = result
            break
        end
    end

    if not uid then
        return nil, ns.L("tomtom_waypoint_unavailable")
    end

    local arrival = TomTom.profile and TomTom.profile.arrow and TomTom.profile.arrow.arrival or 15
    if type(TomTom.ClearCrazyArrowPoint) == "function" then
        pcall(TomTom.ClearCrazyArrowPoint, TomTom, false)
    end
    if type(TomTom.SetCrazyArrow) == "function" then
        pcall(TomTom.SetCrazyArrow, TomTom, uid, arrival, title or ns.L("professions_overlay_title"))
    end

    for _, oldUID in ipairs(previousWaypoints) do
        if oldUID ~= uid then
            removeWaypoint(oldUID)
        end
    end

    self.lastWaypoint = uid
    self.activeWaypoints = { uid }
    return uid
end
