local _, ns = ...

local TomTomBridge = {}
ns.Modules.TomTomBridge = TomTomBridge

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
